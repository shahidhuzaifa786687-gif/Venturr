import { useEffect } from "react";
import { Outlet, useLocation } from "react-router-dom";
import { useTheme } from "../hooks/useTheme";
import { Header } from "./Header";
import { MobileNav } from "./MobileNav";
import { PostDialog } from "./PostDialog";
import { SiteFooter } from "./SiteFooter";
import { Toast } from "./Toast";

export function AppShell() {
  const { theme, toggleTheme } = useTheme();
  const { pathname } = useLocation();

  useEffect(() => {
    const titles: Record<string, string> = {
      "/marketplace": "Marketplace — Venturr",
      "/services": "Services — Venturr",
      "/saved": "Saved — Venturr",
      "/inbox": "Inbox — Venturr",
      "/profile": "Profile — Venturr",
    };
    document.title = titles[pathname] ?? "Venturr — Your campus exchange";
  }, [pathname]);

  return (
    <div className="app-shell">
      <Header theme={theme} onToggleTheme={toggleTheme} />
      <div id="main-content" tabIndex={-1}>
        <Outlet />
      </div>
      <SiteFooter />
      <MobileNav />
      <PostDialog />
      <Toast />
    </div>
  );
}
