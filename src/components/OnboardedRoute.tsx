import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export function OnboardedRoute() {
  const { accountError, loading, profile, user } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <main className="route-loader" aria-live="polite">
        <span className="route-loader__mark" aria-hidden="true">V</span>
        <p>Loading your campus membership...</p>
      </main>
    );
  }

  if (!user) {
    return <Navigate to="/" replace state={{ from: location.pathname }} />;
  }

  if (accountError || !profile?.onboardingCompletedAt) {
    return <Navigate to="/onboarding" replace />;
  }

  return <Outlet />;
}
