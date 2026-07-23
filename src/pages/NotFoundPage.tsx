import { ArrowLeft } from "@phosphor-icons/react";
import { Link } from "react-router-dom";

export function NotFoundPage() {
  return (
    <main className="page not-found">
      <p className="eyebrow">404 · Off campus</p>
      <h1>This page is not part of the exchange.</h1>
      <p>Head back to the marketplace and keep browsing nearby.</p>
      <Link className="button button--primary" to="/marketplace">
        <ArrowLeft size={18} />
        Back to marketplace
      </Link>
    </main>
  );
}
