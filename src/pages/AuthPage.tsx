import {
  ArrowRight,
  Compass,
  Eye,
  EyeSlash,
  GoogleLogo,
  GraduationCap,
  Moon,
  ShieldCheck,
  Storefront,
  Sun,
  UsersThree,
} from "@phosphor-icons/react";
import { useEffect, useState, type FormEvent } from "react";
import { Link, Navigate, useLocation, useSearchParams } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { useTheme } from "../hooks/useTheme";
import {
  readAuthReturnPath,
  rememberAuthReturnPath,
} from "../lib/authNavigation";
import { signInSchema, signUpSchema } from "../lib/validation";

type AuthMode = "signin" | "signup";

function getAuthErrorCode(error: unknown): string | null {
  if (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    typeof error.code === "string"
  ) {
    return error.code;
  }
  return null;
}

export function AuthPage() {
  const {
    configured,
    configurationError,
    googleEnabled,
    loading,
    profile,
    signIn,
    signInWithGoogle,
    signUp,
    user,
  } = useAuth();
  const { theme, toggleTheme } = useTheme();
  const [searchParams, setSearchParams] = useSearchParams();
  const location = useLocation();
  const mode: AuthMode = searchParams.get("mode") === "signup" ? "signup" : "signin";
  const [passwordVisible, setPasswordVisible] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");

  useEffect(() => {
    document.title = `${mode === "signup" ? "Create account" : "Sign in"} - Venturr`;
  }, [mode]);

  useEffect(() => {
    const stateDestination =
      typeof location.state === "object" &&
      location.state !== null &&
      "from" in location.state
        ? location.state.from
        : null;
    rememberAuthReturnPath(stateDestination ?? searchParams.get("next"));
  }, [location.state, searchParams]);

  if (!loading && user) {
    return (
      <Navigate
        to={profile?.onboardingCompletedAt ? readAuthReturnPath() : "/onboarding"}
        replace
      />
    );
  }

  function changeMode(nextMode: AuthMode) {
    setError("");
    setNotice("");
    setPasswordVisible(false);
    const next = searchParams.get("next");
    const params = new URLSearchParams();
    if (nextMode === "signup") params.set("mode", "signup");
    if (next) params.set("next", next);
    setSearchParams(params);
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setNotice("");
    const form = event.currentTarget;

    if (!configured) {
      setError(
        configurationError ??
          "Add the public Supabase URL and publishable key to enable authentication.",
      );
      return;
    }

    const formData = new FormData(form);
    const email = String(formData.get("email") ?? "");
    const password = String(formData.get("password") ?? "");
    setSubmitting(true);
    try {
      if (mode === "signin") {
        const parsed = signInSchema.safeParse({ email, password });
        if (!parsed.success) {
          setError(parsed.error.issues[0]?.message ?? "Check the form and try again.");
          return;
        }
        await signIn(parsed.data.email, parsed.data.password);
      } else {
        const parsed = signUpSchema.safeParse({
          displayName: formData.get("displayName"),
          email,
          password,
          acceptedTerms: formData.get("acceptedTerms") === "on",
        });
        if (!parsed.success) {
          setError(parsed.error.issues[0]?.message ?? "Check the form and try again.");
          return;
        }
        const result = await signUp(parsed.data);
        if (result.needsEmailConfirmation) {
          form.reset();
          setNotice(
            "Check your college inbox to confirm your email. We will match your campus during setup.",
          );
        }
      }
    } catch (authError) {
      if (mode === "signin" && getAuthErrorCode(authError) === "email_not_confirmed") {
        setError("Confirm your email before signing in.");
        return;
      }
      setError(
        mode === "signin"
          ? "We could not sign you in. Check your details and try again."
          : "We could not create the account. Check the details or try signing in.",
      );
    } finally {
      setSubmitting(false);
    }
  }

  async function continueWithGoogle() {
    if (!googleEnabled) return;
    setError("");
    setSubmitting(true);
    try {
      await signInWithGoogle();
    } catch {
      setError("Google sign-in could not start. Use your college email instead.");
      setSubmitting(false);
    }
  }

  return (
    <div className="auth-page">
      <a className="skip-link" href="#auth-form">Skip to authentication</a>
      <header className="auth-header">
        <Link className="wordmark" to="/" aria-label="Venturr home">Venturr</Link>
        <div>
          <Link to="/explore">Explore</Link>
          <Link to="/safety">Safety</Link>
          <button
            className="theme-toggle"
            type="button"
            onClick={toggleTheme}
            aria-label={`Switch to ${theme === "light" ? "dark" : "light"} mode`}
          >
            {theme === "light" ? <Sun size={18} /> : <Moon size={18} />}
          </button>
        </div>
      </header>

      <main className="auth-layout">
        <section className="auth-story" aria-labelledby="auth-story-heading">
          <div>
            <p className="eyebrow">The campus exchange, organised.</p>
            <h1 id="auth-story-heading">Useful things and useful skills, closer than you think.</h1>
            <p className="auth-story__lead">
              Buy, rent, give away, request, tutor, or get unstuck inside one
              student-first campus network.
            </p>
            <Link className="auth-explore-link" to="/explore">
              <Compass size={18} aria-hidden="true" />
              Explore how Venturr works
              <ArrowRight size={16} weight="bold" aria-hidden="true" />
            </Link>
          </div>

          <div className="auth-principles" aria-label="How Venturr works">
            <article>
              <span><ShieldCheck size={22} aria-hidden="true" /></span>
              <div>
                <h2>Campus access first</h2>
                <p>Membership and campus affiliation are checked before participation.</p>
              </div>
            </article>
            <article>
              <span><Storefront size={22} aria-hidden="true" /></span>
              <div>
                <h2>Marketplace without the clutter</h2>
                <p>One-off items stay separate from repeatable student services.</p>
              </div>
            </article>
            <article>
              <span><UsersThree size={22} aria-hidden="true" /></span>
              <div>
                <h2>Help that keeps the work yours</h2>
                <p>Tutoring, feedback, and collaboration - not academic impersonation.</p>
              </div>
            </article>
          </div>

          <div className="auth-story__footer">
            <GraduationCap size={20} aria-hidden="true" />
            <span>Built for real campus communities, not anonymous classifieds.</span>
          </div>
        </section>

        <section className="auth-panel" aria-labelledby="auth-panel-heading">
          <div className="auth-panel__topline">
            <span>{mode === "signin" ? "Welcome back" : "Join your campus"}</span>
            <span>Secure access</span>
          </div>

          <div className="auth-tabs" role="tablist" aria-label="Authentication mode">
            <button
              className={mode === "signin" ? "is-active" : ""}
              type="button"
              role="tab"
              aria-selected={mode === "signin"}
              onClick={() => changeMode("signin")}
            >
              Sign in
            </button>
            <button
              className={mode === "signup" ? "is-active" : ""}
              type="button"
              role="tab"
              aria-selected={mode === "signup"}
              onClick={() => changeMode("signup")}
            >
              Create account
            </button>
          </div>

          <div className="auth-panel__intro">
            <h2 id="auth-panel-heading">
              {mode === "signin" ? "Continue to Venturr" : "Create your student account"}
            </h2>
            <p>
              {mode === "signin"
                ? "Use the email connected to your campus membership."
                : "Start with an email you can verify through your institution."}
            </p>
          </div>

          {!configured ? (
            <div className="auth-config-note" role="status">
              {configurationError ??
                "Authentication is ready for Supabase configuration. Add the two public environment values from .env.example."}
            </div>
          ) : null}

          <button
            className="auth-provider-button"
            type="button"
            onClick={() => void continueWithGoogle()}
            disabled={!googleEnabled || submitting}
            aria-describedby={!googleEnabled ? "google-auth-status" : undefined}
          >
            <GoogleLogo size={20} weight="bold" aria-hidden="true" />
            Continue with Google
            {!googleEnabled ? <span>Coming soon</span> : null}
          </button>
          {!googleEnabled ? (
            <p className="auth-provider-note" id="google-auth-status">
              Google Workspace sign-in is prepared but intentionally locked for now.
            </p>
          ) : null}

          <div className="auth-divider"><span>or use your college email</span></div>

          <form className="auth-form" id="auth-form" onSubmit={submit} noValidate>
            {mode === "signup" ? (
              <label className="field">
                Full name
                <input
                  name="displayName"
                  type="text"
                  autoComplete="name"
                  maxLength={60}
                  placeholder="Your name"
                  required
                />
              </label>
            ) : null}

            <label className="field">
              College email
              <input
                name="email"
                type="email"
                inputMode="email"
                autoComplete="email"
                maxLength={254}
                placeholder="you@university.edu"
                required
              />
            </label>

            <label className="field">
              Password
              <span className="password-input">
                <input
                  name="password"
                  type={passwordVisible ? "text" : "password"}
                  autoComplete={mode === "signin" ? "current-password" : "new-password"}
                  minLength={10}
                  maxLength={128}
                  placeholder={mode === "signin" ? "Enter your password" : "At least 10 characters"}
                  required
                />
                <button
                  type="button"
                  onClick={() => setPasswordVisible((visible) => !visible)}
                  aria-label={passwordVisible ? "Hide password" : "Show password"}
                >
                  {passwordVisible ? <EyeSlash size={19} /> : <Eye size={19} />}
                </button>
              </span>
            </label>

            {mode === "signup" ? (
              <label className="check-field auth-terms">
                <input name="acceptedTerms" type="checkbox" required />
                <span>
                  I agree to the <Link to="/terms">Terms</Link>,{" "}
                  <Link to="/privacy">Privacy notice</Link>, and campus safety rules.
                </span>
              </label>
            ) : null}

            {error ? <div className="auth-message auth-message--error" role="alert">{error}</div> : null}
            {notice ? (
              <div className="auth-message auth-message--success" role="status">
                {notice}
                {import.meta.env.DEV &&
                import.meta.env.VITE_SUPABASE_URL === "http://127.0.0.1:54321" ? (
                  <>
                    {" "}
                    <a href="http://127.0.0.1:54324" target="_blank" rel="noreferrer">
                      Open the local inbox.
                    </a>
                  </>
                ) : null}
              </div>
            ) : null}

            <button
              className="button button--primary button--full auth-submit"
              type="submit"
              disabled={submitting}
            >
              {submitting
                ? "Please wait..."
                : mode === "signin"
                  ? "Sign in securely"
                  : "Create account"}
              {!submitting ? <ArrowRight size={18} weight="bold" aria-hidden="true" /> : null}
            </button>
          </form>

          <p className="auth-switch">
            {mode === "signin" ? "New to Venturr?" : "Already have an account?"}{" "}
            <button type="button" onClick={() => changeMode(mode === "signin" ? "signup" : "signin")}>
              {mode === "signin" ? "Create an account" : "Sign in"}
            </button>
          </p>
        </section>
      </main>

      <footer className="auth-footer">
        <span>Venturr - student-first campus exchange</span>
        <nav aria-label="Legal">
          <Link to="/privacy">Privacy</Link>
          <Link to="/terms">Terms</Link>
        </nav>
      </footer>
    </div>
  );
}
