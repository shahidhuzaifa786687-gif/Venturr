import { useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { consumeAuthReturnPath } from "../lib/authNavigation";

export function AuthCallbackPage() {
  const { accountError, loading, profile, user } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (loading || accountError) return;
    if (!user) {
      navigate("/", { replace: true });
      return;
    }
    navigate(
      profile?.onboardingCompletedAt ? consumeAuthReturnPath() : "/onboarding",
      { replace: true },
    );
  }, [accountError, loading, navigate, profile?.onboardingCompletedAt, user]);

  return (
    <main className="route-loader" aria-live="polite">
      <span className="route-loader__mark" aria-hidden="true">V</span>
      {accountError ? (
        <>
          <p>{accountError}</p>
          <Link className="button button--secondary" to="/">Return to sign in</Link>
        </>
      ) : (
        <p>Confirming your Venturr session...</p>
      )}
    </main>
  );
}
