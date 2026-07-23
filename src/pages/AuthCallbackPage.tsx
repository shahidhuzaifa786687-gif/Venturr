import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export function AuthCallbackPage() {
  const { loading, user } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (loading) return;
    navigate(user ? "/marketplace" : "/", { replace: true });
  }, [loading, navigate, user]);

  return (
    <main className="route-loader" aria-live="polite">
      <span className="route-loader__mark" aria-hidden="true">V</span>
      <p>Confirming your Venturr session…</p>
    </main>
  );
}
