import {
  ArrowRight,
  Buildings,
  CheckCircle,
  EnvelopeSimple,
  IdentificationCard,
  ShieldCheck,
  SignOut,
} from "@phosphor-icons/react";
import { useEffect, useRef, useState, type FormEvent } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { consumeAuthReturnPath } from "../lib/authNavigation";
import { onboardingSchema } from "../lib/validation";

export function OnboardingPage() {
  const {
    accountError,
    campuses,
    claimCampusFromEmail,
    completeOnboarding,
    loading,
    membership,
    profile,
    requestCampusMembership,
    signOut,
    user,
  } = useAuth();
  const navigate = useNavigate();
  const detectionStarted = useRef(false);
  const [selectedCampusId, setSelectedCampusId] = useState(membership?.campusId ?? "");
  const [detectingCampus, setDetectingCampus] = useState(false);
  const [detectionComplete, setDetectionComplete] = useState(Boolean(membership));
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState("");
  const [messageIsError, setMessageIsError] = useState(false);

  useEffect(() => {
    if (membership?.campusId) {
      setSelectedCampusId(membership.campusId);
      setDetectionComplete(true);
    }
  }, [membership?.campusId]);

  useEffect(() => {
    if (
      loading ||
      accountError ||
      membership ||
      !user?.email_confirmed_at ||
      detectionStarted.current
    ) {
      return;
    }

    detectionStarted.current = true;
    setDetectingCampus(true);
    void claimCampusFromEmail()
      .then((claimed) => {
        if (claimed) {
          setSelectedCampusId(claimed.campusId);
          setMessageIsError(false);
          setMessage(`${claimed.campus.name} was matched from your verified college email.`);
        }
      })
      .catch(() => {
        setMessageIsError(true);
        setMessage("We could not check your college email just now. Choose a campus below.");
      })
      .finally(() => {
        setDetectingCampus(false);
        setDetectionComplete(true);
      });
  }, [
    accountError,
    claimCampusFromEmail,
    loading,
    membership,
    user?.email_confirmed_at,
  ]);

  if (!loading && !user) return <Navigate to="/" replace />;
  if (!loading && profile?.onboardingCompletedAt) {
    return <Navigate to={consumeAuthReturnPath()} replace />;
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setMessage("");
    const formData = new FormData(event.currentTarget);
    const parsed = onboardingSchema.safeParse({
      campusId: selectedCampusId,
      displayName: formData.get("displayName"),
      course: formData.get("course"),
      graduationYear: formData.get("graduationYear"),
      bio: formData.get("bio"),
    });

    if (!parsed.success) {
      setMessageIsError(true);
      setMessage(parsed.error.issues[0]?.message ?? "Check your profile details.");
      return;
    }

    setSubmitting(true);
    try {
      if (!membership || membership.campusId !== parsed.data.campusId) {
        await requestCampusMembership(parsed.data.campusId);
      }
      await completeOnboarding(parsed.data);
      navigate(consumeAuthReturnPath(), { replace: true });
    } catch {
      setMessageIsError(true);
      setMessage("We could not finish setup. Check your details and try again.");
    } finally {
      setSubmitting(false);
    }
  }

  const currentYear = new Date().getFullYear();
  const defaultName =
    profile?.displayName ||
    (typeof user?.user_metadata.display_name === "string"
      ? user.user_metadata.display_name
      : "");

  return (
    <div className="onboarding-page">
      <a className="skip-link" href="#onboarding-form">Skip to profile setup</a>
      <header className="onboarding-header">
        <span className="wordmark">Venturr</span>
        <button type="button" onClick={() => void signOut()}>
          <SignOut size={18} aria-hidden="true" />
          Sign out
        </button>
      </header>

      <main className="onboarding-layout">
        <aside className="onboarding-progress" aria-label="Onboarding progress">
          <p className="eyebrow">Campus access setup</p>
          <h1>Set up the account students will see.</h1>
          <ol>
            <li className="is-complete">
              <CheckCircle size={22} weight="fill" aria-hidden="true" />
              <span><strong>Account verified</strong><small>{user?.email}</small></span>
            </li>
            <li className={membership ? "is-complete" : "is-current"}>
              <Buildings size={22} aria-hidden="true" />
              <span><strong>Campus membership</strong><small>Matched securely from college email</small></span>
            </li>
            <li className="is-current">
              <IdentificationCard size={22} aria-hidden="true" />
              <span><strong>Student profile</strong><small>Only public-safe details</small></span>
            </li>
          </ol>
          <div className="onboarding-trust">
            <ShieldCheck size={21} aria-hidden="true" />
            <p>
              Your email stays private. Other students see your display name,
              campus, course, and trust status.
            </p>
          </div>
        </aside>

        <section className="onboarding-card" aria-labelledby="onboarding-heading">
          <div className="onboarding-card__heading">
            <p className="eyebrow">About you</p>
            <h2 id="onboarding-heading">Complete your campus profile</h2>
            <p>Venturr uses the exact domain of your confirmed email to find your campus.</p>
          </div>

          {accountError ? (
            <div className="auth-message auth-message--error" role="alert">{accountError}</div>
          ) : null}

          <div className="campus-match" aria-live="polite">
            <EnvelopeSimple size={22} aria-hidden="true" />
            <div>
              <strong>
                {detectingCampus
                  ? "Checking your college email..."
                  : membership?.status === "verified"
                    ? "College email verified"
                    : membership
                      ? "College ID review requested"
                      : "No campus match yet"}
              </strong>
              <span>
                {membership
                  ? `${membership.campus.name}${membership.campus.city ? `, ${membership.campus.city}` : ""}`
                  : "Choose your campus to create a private review request."}
              </span>
            </div>
          </div>

          <form id="onboarding-form" className="profile-form" onSubmit={submit} noValidate>
            {!membership && detectionComplete ? (
              <label className="field field--full">
                Campus
                <select
                  value={selectedCampusId}
                  onChange={(event) => setSelectedCampusId(event.target.value)}
                  required
                >
                  <option value="">Choose your campus</option>
                  {campuses.map((campus) => (
                    <option key={campus.id} value={campus.id}>
                      {campus.name}{campus.city ? ` - ${campus.city}` : ""}
                    </option>
                  ))}
                </select>
                <small>
                  If the email domain is not registered, this creates a pending
                  college ID review. No ID image is collected in the browser.
                </small>
              </label>
            ) : null}

            <label className="field">
              Display name
              <input
                name="displayName"
                type="text"
                autoComplete="name"
                defaultValue={defaultName}
                maxLength={60}
                required
              />
            </label>

            <label className="field">
              Course or program
              <input
                name="course"
                type="text"
                autoComplete="organization-title"
                defaultValue={profile?.course ?? ""}
                maxLength={100}
                placeholder="B.Tech Computer Science"
                required
              />
            </label>

            <label className="field">
              Graduation year
              <input
                name="graduationYear"
                type="number"
                inputMode="numeric"
                min={currentYear - 8}
                max={currentYear + 10}
                defaultValue={profile?.graduationYear ?? currentYear + 2}
                required
              />
            </label>

            <label className="field field--full">
              Short bio <span>(optional)</span>
              <textarea
                name="bio"
                rows={4}
                maxLength={320}
                defaultValue={profile?.bio ?? ""}
                placeholder="What you study, make, repair, teach, or look for on campus."
              />
            </label>

            {message ? (
              <div
                className={`auth-message ${
                  messageIsError ? "auth-message--error" : "auth-message--success"
                } field--full`}
                role={messageIsError ? "alert" : "status"}
              >
                {message}
              </div>
            ) : null}

            <button
              className="button button--primary field--full onboarding-submit"
              type="submit"
              disabled={submitting || detectingCampus || Boolean(accountError)}
            >
              {submitting ? "Saving your profile..." : "Finish setup"}
              {!submitting ? <ArrowRight size={18} weight="bold" aria-hidden="true" /> : null}
            </button>
          </form>
        </section>
      </main>
    </div>
  );
}
