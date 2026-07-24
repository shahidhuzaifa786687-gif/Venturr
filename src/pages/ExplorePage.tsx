import {
  ArrowRight,
  ChatCircle,
  LockKey,
  MapPin,
  Package,
  ShieldCheck,
  UsersThree,
} from "@phosphor-icons/react";
import { Link } from "react-router-dom";
import { useTheme } from "../hooks/useTheme";

const exchangeSteps = [
  {
    icon: Package,
    title: "Discover",
    body: "Find one-off items in Marketplace or repeatable help in Services.",
  },
  {
    icon: ShieldCheck,
    title: "Save or offer",
    body: "Shortlist something useful, then make one clear offer or request.",
  },
  {
    icon: ChatCircle,
    title: "Chat in-app",
    body: "Keep negotiation and meetup planning inside the protected thread.",
  },
  {
    icon: MapPin,
    title: "Meet and confirm",
    body: "Use a configured public campus zone, then confirm and review.",
  },
];

export function ExplorePage() {
  const { theme, toggleTheme } = useTheme();

  return (
    <div className="explore-page">
      <a className="skip-link" href="#explore-main">Skip to product tour</a>
      <header className="public-header">
        <Link className="wordmark" to="/" aria-label="Venturr home">Venturr</Link>
        <nav aria-label="Account">
          <Link to="/">Sign in</Link>
          <Link className="button button--primary button--small" to="/?mode=signup">
            Create account
          </Link>
          <button
            className="theme-toggle"
            type="button"
            onClick={toggleTheme}
            aria-label={`Switch to ${theme === "light" ? "dark" : "light"} mode`}
          >
            {theme === "light" ? "Dark" : "Light"}
          </button>
        </nav>
      </header>

      <main id="explore-main" className="explore-main">
        <section className="explore-hero">
          <p className="eyebrow">A quick look before you join</p>
          <h1>See how the campus exchange fits together.</h1>
          <p>
            Explore the product flow without exposing student profiles, listings,
            services, or conversations. Real campus content stays behind sign-in.
          </p>
          <div className="explore-hero__actions">
            <Link className="button button--primary" to="/?mode=signup&next=/marketplace">
              Join your campus
              <ArrowRight size={18} weight="bold" aria-hidden="true" />
            </Link>
            <Link className="button button--secondary" to="/">I already have an account</Link>
          </div>
        </section>

        <section className="explore-flow" aria-labelledby="explore-flow-heading">
          <header>
            <p className="eyebrow">The core flow</p>
            <h2 id="explore-flow-heading">From discovery to a safer handoff.</h2>
          </header>
          <div>
            {exchangeSteps.map(({ icon: Icon, title, body }, index) => (
              <article key={title}>
                <span>{String(index + 1).padStart(2, "0")}</span>
                <Icon size={24} aria-hidden="true" />
                <h3>{title}</h3>
                <p>{body}</p>
              </article>
            ))}
          </div>
        </section>

        <section className="explore-domains" aria-label="Venturr product areas">
          <article>
            <Package size={26} aria-hidden="true" />
            <p className="eyebrow">Marketplace</p>
            <h2>Items stay one-off and local.</h2>
            <p>Sale, rental, free, and wanted listings use campus pickup zones.</p>
            <Link to="/?mode=signup&next=/marketplace">
              Sign in to view listings <LockKey size={16} aria-hidden="true" />
            </Link>
          </article>
          <article>
            <UsersThree size={26} aria-hidden="true" />
            <p className="eyebrow">Services</p>
            <h2>Student help keeps clear boundaries.</h2>
            <p>Coaching, feedback, debugging, and practical help stay separate from item trade.</p>
            <Link to="/?mode=signup&next=/services">
              Sign in to view services <LockKey size={16} aria-hidden="true" />
            </Link>
          </article>
        </section>
      </main>
    </div>
  );
}
