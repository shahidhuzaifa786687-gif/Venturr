import { Route, Routes } from "react-router-dom";
import { AppShell } from "./components/AppShell";
import { OnboardedRoute } from "./components/OnboardedRoute";
import { ProtectedRoute } from "./components/ProtectedRoute";
import { AuthCallbackPage } from "./pages/AuthCallbackPage";
import { AuthPage } from "./pages/AuthPage";
import { ExplorePage } from "./pages/ExplorePage";
import { InboxPage } from "./pages/InboxPage";
import { LegalPage } from "./pages/LegalPage";
import { MarketplacePage } from "./pages/MarketplacePage";
import { NotFoundPage } from "./pages/NotFoundPage";
import { OnboardingPage } from "./pages/OnboardingPage";
import { ProfilePage } from "./pages/ProfilePage";
import { SafetyPage } from "./pages/SafetyPage";
import { SavedPage } from "./pages/SavedPage";
import { ServicesPage } from "./pages/ServicesPage";

export function App() {
  return (
    <Routes>
      <Route path="/" element={<AuthPage />} />
      <Route path="/explore" element={<ExplorePage />} />
      <Route path="/auth/callback" element={<AuthCallbackPage />} />
      <Route path="/safety" element={<SafetyPage />} />
      <Route path="/privacy" element={<LegalPage type="privacy" />} />
      <Route path="/terms" element={<LegalPage type="terms" />} />
      <Route element={<ProtectedRoute />}>
        <Route path="/onboarding" element={<OnboardingPage />} />
        <Route element={<OnboardedRoute />}>
          <Route element={<AppShell />}>
            <Route path="/marketplace" element={<MarketplacePage />} />
            <Route path="/services" element={<ServicesPage />} />
            <Route path="/saved" element={<SavedPage />} />
            <Route path="/inbox" element={<InboxPage />} />
            <Route path="/profile" element={<ProfilePage />} />
          </Route>
        </Route>
      </Route>
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}
