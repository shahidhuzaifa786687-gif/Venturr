import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter } from "react-router-dom";
import { beforeEach, vi } from "vitest";
import { App } from "./App";
import { AppProvider } from "./context/AppContext";
import {
  AuthStateProvider,
  type AuthContextValue,
} from "./context/AuthContext";

const authState: AuthContextValue = {
  configured: false,
  configurationError: null,
  googleEnabled: false,
  loading: false,
  accountLoading: false,
  accountError: null,
  session: null,
  user: null,
  profile: null,
  membership: null,
  campuses: [],
  student: null,
  signIn: vi.fn(),
  signInWithGoogle: vi.fn(),
  signUp: vi.fn(),
  claimCampusFromEmail: vi.fn(),
  requestCampusMembership: vi.fn(),
  completeOnboarding: vi.fn(),
  updateProfile: vi.fn(),
  refreshAccount: vi.fn(),
  signOut: vi.fn(),
};

beforeEach(() => {
  authState.configured = false;
  authState.session = null;
  authState.profile = null;
  authState.membership = null;
  authState.campuses = [];
  vi.clearAllMocks();
});

function renderRoute(route: string, authenticated = false, onboarded = true) {
  authState.user = authenticated
    ? ({
        id: "test-user",
        email: "student@campus.test",
        created_at: "2026-07-23T00:00:00.000Z",
        app_metadata: {},
        user_metadata: {},
        aud: "authenticated",
      } as AuthContextValue["user"])
    : null;
  authState.student = authenticated
    ? {
        id: "test-user",
        name: "Test Student",
        initials: "TS",
        course: "Campus profile not completed",
        verified: false,
        joinedYear: 2026,
      }
    : null;
  authState.profile = authenticated
    ? {
        userId: "test-user",
        displayName: "Test Student",
        avatarPath: null,
        preferredCampusId: "10000000-0000-4000-8000-000000000001",
        course: "Computer Science",
        graduationYear: 2027,
        bio: "",
        onboardingCompletedAt: onboarded ? "2026-07-23T00:00:00.000Z" : null,
      }
    : null;
  authState.membership = authenticated
    ? {
        id: "20000000-0000-4000-8000-000000000001",
        campusId: "10000000-0000-4000-8000-000000000001",
        status: "verified",
        verificationMethod: "college_email",
        verifiedAt: "2026-07-23T00:00:00.000Z",
        expiresAt: "2027-07-23T00:00:00.000Z",
        campus: {
          id: "10000000-0000-4000-8000-000000000001",
          name: "Test Campus",
          slug: "test-campus",
          city: "Test City",
        },
      }
    : null;

  return render(
    <MemoryRouter initialEntries={[route]}>
      <AuthStateProvider value={authState}>
        <AppProvider>
          <App />
        </AppProvider>
      </AuthStateProvider>
    </MemoryRouter>,
  );
}

describe("Venturr authentication entry", () => {
  it("opens on the sign-in landing page", () => {
    renderRoute("/");

    expect(
      screen.getByRole("heading", {
        name: "Useful things and useful skills, closer than you think.",
      }),
    ).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Continue to Venturr" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Sign in securely" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /Continue with Google/ })).toBeDisabled();
    expect(screen.getByRole("link", { name: "Explore" })).toHaveAttribute("href", "/explore");
  });

  it("switches to account creation without navigating away", async () => {
    const user = userEvent.setup();
    renderRoute("/");

    await user.click(screen.getByRole("tab", { name: "Create account" }));

    expect(
      screen.getByRole("heading", { name: "Create your student account" }),
    ).toBeInTheDocument();
    expect(screen.getByLabelText("Full name")).toBeInTheDocument();
  });

  it("shows a confirmation notice after a successful signup", async () => {
    const user = userEvent.setup();
    authState.configured = true;
    vi.mocked(authState.signUp).mockResolvedValue({
      needsEmailConfirmation: true,
    });
    renderRoute("/");

    await user.click(screen.getByRole("tab", { name: "Create account" }));
    await user.type(screen.getByLabelText("Full name"), "Test Student");
    await user.type(screen.getByLabelText("College email"), "student@campus.test");
    await user.type(screen.getByLabelText("Password"), "StrongPassword!");
    await user.click(
      screen.getByRole("checkbox", {
        name: "I agree to the Terms, Privacy notice, and campus safety rules.",
      }),
    );
    await user.click(screen.getByRole("button", { name: "Create account" }));

    expect(
      await screen.findByRole("status"),
    ).toHaveTextContent("Check your college inbox to confirm your email");
    expect(authState.signUp).toHaveBeenCalledWith({
      displayName: "Test Student",
      email: "student@campus.test",
      password: "StrongPassword!",
      acceptedTerms: true,
    });
    expect(screen.getByLabelText("Full name")).toHaveValue("");
    expect(screen.getByLabelText("College email")).toHaveValue("");
  });

  it("offers a public product tour without exposing marketplace content", () => {
    renderRoute("/explore");

    expect(
      screen.getByRole("heading", { name: "See how the campus exchange fits together." }),
    ).toBeInTheDocument();
    expect(
      screen.getByText(/Explore the product flow without exposing/),
    ).toHaveTextContent("Real campus content stays behind sign-in.");
    expect(screen.queryByText("Ergonomic study chair")).not.toBeInTheDocument();
  });
});

describe("empty authenticated product routes", () => {
  it("requires onboarding before opening product routes", async () => {
    renderRoute("/marketplace", true, false);

    expect(
      await screen.findByRole("heading", { name: "Complete your campus profile" }),
    ).toBeInTheDocument();
    expect(screen.queryByRole("heading", { name: "Find what you need on campus." }))
      .not.toBeInTheDocument();
  });

  it("contains no bundled marketplace or service fixtures", () => {
    renderRoute("/marketplace", true);

    expect(
      screen.getByRole("heading", { name: "Find what you need on campus." }),
    ).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "No listings yet" })).toBeInTheDocument();
    expect(screen.queryByText("Ergonomic study chair")).not.toBeInTheDocument();
    expect(screen.queryByText("Calculus concept tutoring")).not.toBeInTheDocument();
  });

  it("keeps services empty and separate from marketplace items", () => {
    renderRoute("/services", true);

    expect(
      screen.getByRole("heading", { name: "Learn together. Get unstuck." }),
    ).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "No services yet" })).toBeInTheDocument();
    expect(screen.queryByText("Student laptop")).not.toBeInTheDocument();
  });

  it("edits and saves the owner profile", async () => {
    const user = userEvent.setup();
    renderRoute("/profile", true);

    await user.click(screen.getByRole("button", { name: "Edit profile" }));
    await user.click(screen.getByRole("button", { name: "Save profile" }));

    expect(authState.updateProfile).toHaveBeenCalledWith({
      displayName: "Test Student",
      course: "Computer Science",
      graduationYear: 2027,
      bio: "",
    });
    expect(await screen.findByRole("status")).toHaveTextContent(
      "Your profile has been updated.",
    );
  });
});

describe("theme control", () => {
  it("switches between light and dark mode from the landing page", async () => {
    const user = userEvent.setup();
    renderRoute("/");

    await user.click(screen.getByRole("button", { name: "Switch to dark mode" }));
    expect(document.documentElement).toHaveAttribute("data-theme", "dark");
    expect(
      screen.getByRole("button", { name: "Switch to light mode" }),
    ).toBeInTheDocument();
  });
});
