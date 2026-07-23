import { ChatCircle, MapPin, SealCheck } from "@phosphor-icons/react";
import { Link } from "react-router-dom";

export function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="trust-strip">
        <span>
          <SealCheck size={22} weight="fill" aria-hidden="true" />
          <strong>Verified community</strong>
          <small>Campus membership is checked.</small>
        </span>
        <span>
          <MapPin size={22} aria-hidden="true" />
          <strong>Public pickup zones</strong>
          <small>Meet where campus stays busy.</small>
        </span>
        <span>
          <ChatCircle size={22} aria-hidden="true" />
          <strong>In-app communication</strong>
          <small>Keep offers and plans in Venturr.</small>
        </span>
      </div>
      <div className="footer-meta">
        <span>
          <strong>Venturr</strong> · student-first campus exchange
        </span>
        <nav aria-label="Legal and safety">
          <Link to="/safety">Safety</Link>
          <Link to="/privacy">Privacy</Link>
          <Link to="/terms">Terms</Link>
        </nav>
      </div>
    </footer>
  );
}
