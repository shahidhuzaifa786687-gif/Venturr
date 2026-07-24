import type { Session, User } from "@supabase/supabase-js";
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { z } from "zod";
import { isAccountBootstrapPending } from "../lib/authLoading";
import {
  googleAuthEnabled,
  isSupabaseConfigured,
  supabase,
  supabaseConfigurationError,
} from "../lib/supabase";
import type {
  CampusMembership,
  CampusSummary,
  MembershipStatus,
  StudentSummary,
  UserProfile,
  VerificationMethod,
} from "../types";

interface SignUpInput {
  displayName: string;
  email: string;
  password: string;
}

export interface ProfileInput {
  displayName: string;
  course: string;
  graduationYear: number;
  bio: string;
}

export interface AuthContextValue {
  configured: boolean;
  configurationError: string | null;
  googleEnabled: boolean;
  loading: boolean;
  accountLoading: boolean;
  accountError: string | null;
  session: Session | null;
  user: User | null;
  profile: UserProfile | null;
  membership: CampusMembership | null;
  campuses: CampusSummary[];
  student: StudentSummary | null;
  signIn: (email: string, password: string) => Promise<void>;
  signInWithGoogle: () => Promise<void>;
  signUp: (input: SignUpInput) => Promise<{ needsEmailConfirmation: boolean }>;
  claimCampusFromEmail: () => Promise<CampusMembership | null>;
  requestCampusMembership: (campusId: string) => Promise<void>;
  completeOnboarding: (input: ProfileInput) => Promise<void>;
  updateProfile: (input: ProfileInput) => Promise<void>;
  refreshAccount: () => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const profileRowSchema = z.object({
  user_id: z.string().uuid(),
  display_name: z.string(),
  avatar_path: z.string().nullable(),
  preferred_campus_id: z.string().uuid().nullable(),
  course: z.string().nullable(),
  graduation_year: z.number().int().nullable(),
  bio: z.string().nullable(),
  onboarding_completed_at: z.string().nullable(),
});

const campusRowSchema = z.object({
  id: z.string().uuid(),
  slug: z.string(),
  name: z.string(),
  city: z.string().nullable(),
});

const membershipRowSchema = z.object({
  id: z.string().uuid(),
  campus_id: z.string().uuid(),
  status: z.enum(["pending", "verified", "rejected", "suspended", "expired"]),
  verification_method: z
    .enum(["college_email", "college_id_review", "manual_review"])
    .nullable(),
  verified_at: z.string().nullable(),
  expires_at: z.string().nullable(),
});

const claimedMembershipSchema = membershipRowSchema.extend({
  campus_name: z.string(),
  campus_slug: z.string(),
  campus_city: z.string().nullable(),
});

function displayNameFor(user: User): string {
  const metadataName = user.user_metadata.display_name;
  if (typeof metadataName === "string" && metadataName.trim()) {
    return metadataName.trim().slice(0, 60);
  }

  const emailName = user.email?.split("@")[0]?.replace(/[._-]+/g, " ").trim();
  return emailName || "Student";
}

function initialsFor(name: string): string {
  const initials = name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join("");
  return initials || "ST";
}

function toCampus(row: z.infer<typeof campusRowSchema>): CampusSummary {
  return {
    id: row.id,
    slug: row.slug,
    name: row.name,
    city: row.city,
  };
}

function toMembership(
  row: z.infer<typeof membershipRowSchema>,
  campus: CampusSummary,
): CampusMembership {
  return {
    id: row.id,
    campusId: row.campus_id,
    status: row.status as MembershipStatus,
    verificationMethod: row.verification_method as VerificationMethod | null,
    verifiedAt: row.verified_at,
    expiresAt: row.expires_at,
    campus,
  };
}

function toProfile(row: z.infer<typeof profileRowSchema>): UserProfile {
  return {
    userId: row.user_id,
    displayName: row.display_name,
    avatarPath: row.avatar_path,
    preferredCampusId: row.preferred_campus_id,
    course: row.course ?? "",
    graduationYear: row.graduation_year,
    bio: row.bio ?? "",
    onboardingCompletedAt: row.onboarding_completed_at,
  };
}

function genericAccountError(error: unknown): string {
  if (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    error.code === "42703"
  ) {
    return "The account onboarding migration has not been applied to this Supabase environment.";
  }
  return "We could not load your campus account. Try again in a moment.";
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [authLoading, setAuthLoading] = useState(true);
  const [accountLoading, setAccountLoading] = useState(false);
  const [accountUserId, setAccountUserId] = useState<string | null>(null);
  const [accountError, setAccountError] = useState<string | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [memberships, setMemberships] = useState<CampusMembership[]>([]);
  const [campuses, setCampuses] = useState<CampusSummary[]>([]);

  useEffect(() => {
    if (!supabase) {
      setAuthLoading(false);
      return;
    }

    let active = true;
    void supabase.auth.getSession().then(({ data }) => {
      if (!active) return;
      setSession(data.session);
      setAuthLoading(false);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      if (!active) return;
      setSession(nextSession);
      setAuthLoading(false);
      if (!nextSession) {
        setProfile(null);
        setMemberships([]);
        setAccountUserId(null);
        setAccountError(null);
      }
    });

    return () => {
      active = false;
      subscription.unsubscribe();
    };
  }, []);

  const refreshAccount = useCallback(async () => {
    if (!supabase || !session?.user) {
      setProfile(null);
      setMemberships([]);
      setCampuses([]);
      setAccountUserId(null);
      return;
    }

    const userId = session.user.id;
    setAccountLoading(true);
    setAccountError(null);

    try {
      const { data: currentAuth, error: sessionError } =
        await supabase.auth.getSession();
      if (sessionError || currentAuth.session?.user.id !== userId) {
        throw sessionError ?? new Error("The authenticated session changed.");
      }

      const [profileResult, membershipResult, campusResult] = await Promise.all([
        supabase
          .from("profiles")
          .select(
            "user_id,display_name,avatar_path,preferred_campus_id,course,graduation_year,bio,onboarding_completed_at",
          )
          .eq("user_id", userId)
          .single(),
        supabase
          .from("campus_memberships")
          .select(
            "id,campus_id,status,verification_method,verified_at,expires_at",
          )
          .eq("user_id", userId),
        supabase
          .from("campuses")
          .select("id,slug,name,city")
          .eq("is_active", true)
          .order("name"),
      ]);

      if (profileResult.error) throw profileResult.error;
      if (membershipResult.error) throw membershipResult.error;
      if (campusResult.error) throw campusResult.error;

      const parsedProfile = profileRowSchema.parse(profileResult.data);
      const parsedCampuses = z.array(campusRowSchema).parse(campusResult.data).map(toCampus);
      const campusById = new Map(parsedCampuses.map((campus) => [campus.id, campus]));
      const parsedMemberships = z
        .array(membershipRowSchema)
        .parse(membershipResult.data)
        .flatMap((row) => {
          const campus = campusById.get(row.campus_id);
          return campus ? [toMembership(row, campus)] : [];
        });

      setProfile(toProfile(parsedProfile));
      setCampuses(parsedCampuses);
      setMemberships(parsedMemberships);
      setAccountUserId(userId);
    } catch (error) {
      setProfile(null);
      setMemberships([]);
      setAccountError(genericAccountError(error));
      setAccountUserId(userId);
    } finally {
      setAccountLoading(false);
    }
  }, [session?.user.id]);

  useEffect(() => {
    if (!session?.user) return;
    void refreshAccount();
  }, [refreshAccount, session?.user]);

  const signIn = useCallback(async (email: string, password: string) => {
    if (!supabase) throw new Error("Supabase is not configured.");
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
  }, []);

  const signInWithGoogle = useCallback(async () => {
    if (!supabase) throw new Error("Supabase is not configured.");
    if (!googleAuthEnabled) throw new Error("Google sign-in is not enabled.");

    const { error } = await supabase.auth.signInWithOAuth({
      provider: "google",
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
        queryParams: {
          prompt: "select_account",
        },
      },
    });
    if (error) throw error;
  }, []);

  const signUp = useCallback(async ({ displayName, email, password }: SignUpInput) => {
    if (!supabase) throw new Error("Supabase is not configured.");
    const emailRedirectTo = `${window.location.origin}/auth/callback`;
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        emailRedirectTo,
        data: {
          display_name: displayName,
        },
      },
    });
    if (error) throw error;
    return { needsEmailConfirmation: data.session === null };
  }, []);

  const claimCampusFromEmail = useCallback(async () => {
    if (!supabase) throw new Error("Supabase is not configured.");
    const { data, error } = await supabase.rpc("claim_campus_from_verified_email");
    if (error) throw error;

    const parsed = z.array(claimedMembershipSchema).parse(data);
    await refreshAccount();
    const row = parsed[0];
    if (!row) return null;

    return toMembership(row, {
      id: row.campus_id,
      name: row.campus_name,
      slug: row.campus_slug,
      city: row.campus_city,
    });
  }, [refreshAccount]);

  const requestCampusMembership = useCallback(
    async (campusId: string) => {
      if (!supabase) throw new Error("Supabase is not configured.");
      const { error } = await supabase.rpc("request_campus_membership", {
        p_campus_id: campusId,
      });
      if (error) throw error;
      await refreshAccount();
    },
    [refreshAccount],
  );

  const completeOnboarding = useCallback(
    async (input: ProfileInput) => {
      if (!supabase) throw new Error("Supabase is not configured.");
      const { error } = await supabase.rpc("complete_my_onboarding", {
        p_display_name: input.displayName,
        p_course: input.course,
        p_graduation_year: input.graduationYear,
        p_bio: input.bio,
      });
      if (error) throw error;
      await refreshAccount();
    },
    [refreshAccount],
  );

  const updateProfile = useCallback(
    async (input: ProfileInput) => {
      if (!supabase) throw new Error("Supabase is not configured.");
      const { error } = await supabase.rpc("save_my_profile", {
        p_display_name: input.displayName,
        p_course: input.course,
        p_graduation_year: input.graduationYear,
        p_bio: input.bio,
      });
      if (error) throw error;
      await refreshAccount();
    },
    [refreshAccount],
  );

  const signOut = useCallback(async () => {
    if (!supabase) return;
    const { error } = await supabase.auth.signOut({ scope: "local" });
    if (error) throw error;
  }, []);

  const membership = useMemo(() => {
    if (!memberships.length) return null;
    return (
      memberships.find((item) => item.campusId === profile?.preferredCampusId) ??
      memberships.find((item) => item.status === "verified") ??
      memberships[0] ??
      null
    );
  }, [memberships, profile?.preferredCampusId]);

  const student = useMemo<StudentSummary | null>(() => {
    if (!session?.user) return null;
    const name = profile?.displayName || displayNameFor(session.user);
    const joinedYear = new Date(session.user.created_at).getFullYear();
    return {
      id: session.user.id,
      name,
      initials: initialsFor(name),
      course: profile?.course || "Campus profile not completed",
      verified: membership?.status === "verified",
      joinedYear: Number.isFinite(joinedYear) ? joinedYear : new Date().getFullYear(),
      ...(membership
        ? {
            campusName: membership.campus.name,
            membershipStatus: membership.status,
          }
        : {}),
    };
  }, [membership, profile, session]);

  const loading = isAccountBootstrapPending(
    authLoading,
    session?.user.id ?? null,
    accountUserId,
  );

  const value = useMemo<AuthContextValue>(
    () => ({
      configured: isSupabaseConfigured,
      configurationError: supabaseConfigurationError,
      googleEnabled: googleAuthEnabled,
      loading,
      accountLoading,
      accountError,
      session,
      user: session?.user ?? null,
      profile,
      membership,
      campuses,
      student,
      signIn,
      signInWithGoogle,
      signUp,
      claimCampusFromEmail,
      requestCampusMembership,
      completeOnboarding,
      updateProfile,
      refreshAccount,
      signOut,
    }),
    [
      accountError,
      accountLoading,
      campuses,
      claimCampusFromEmail,
      completeOnboarding,
      loading,
      membership,
      profile,
      refreshAccount,
      requestCampusMembership,
      session,
      signIn,
      signInWithGoogle,
      signOut,
      signUp,
      student,
      updateProfile,
    ],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function AuthStateProvider({
  children,
  value,
}: {
  children: ReactNode;
  value: AuthContextValue;
}) {
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth must be used inside AuthProvider.");
  return context;
}
