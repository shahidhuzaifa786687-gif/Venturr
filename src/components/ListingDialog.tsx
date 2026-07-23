import {
  CalendarBlank,
  ChatCircle,
  Handshake,
  MapPin,
  SealCheck,
  ShieldCheck,
} from "@phosphor-icons/react";
import { useMemo, useState, type FormEvent } from "react";
import { useApp } from "../context/AppContext";
import { formatCurrency, formatListingPrice } from "../lib/format";
import { offerSchema } from "../lib/validation";
import type { Listing } from "../types";
import { Avatar } from "./Avatar";
import { ModalFrame } from "./ModalFrame";

export function ListingDialog({
  listing,
  onClose,
}: {
  listing: Listing;
  onClose: () => void;
}) {
  const { startListingConversation } = useApp();
  const [amount, setAmount] = useState(listing.type === "free" ? "0" : String(listing.price));
  const [note, setNote] = useState("");
  const [error, setError] = useState("");
  const actionLabel = useMemo(() => {
    if (listing.type === "wanted") return "Tell them you have one";
    if (listing.type === "free") return "Request item";
    if (listing.type === "rent") return "Request rental";
    return "Send offer";
  }, [listing.type]);

  function submitOffer(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const parsed = offerSchema.safeParse({ amount, note });
    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? "Check your offer.");
      return;
    }

    const body =
      listing.type === "free" || listing.type === "wanted"
        ? parsed.data.note
        : `${actionLabel}: ${formatCurrency(parsed.data.amount)}. ${parsed.data.note}`;
    startListingConversation(listing, body);
    onClose();
  }

  return (
    <ModalFrame labelledBy={`listing-title-${listing.id}`} onClose={onClose} size="large">
      <div className="detail-layout">
        <div className="detail-media">
          <img src={listing.image} alt={listing.imageAlt} />
          <span className={`listing-type listing-type--${listing.type}`}>
            {listing.type === "buy"
              ? "For sale"
              : listing.type === "rent"
                ? "For rent"
                : listing.type === "free"
                  ? "Free"
                  : "Wanted"}
          </span>
        </div>

        <div className="detail-content">
          <header className="detail-header">
            <div>
              <p className="eyebrow">{listing.category}</p>
              <h2 id={`listing-title-${listing.id}`}>{listing.title}</h2>
            </div>
            <strong>{formatListingPrice(listing.type, listing.price, listing.priceUnit)}</strong>
          </header>

          <p className="detail-description">{listing.description}</p>

          <dl className="detail-facts">
            <div>
              <dt>Condition</dt>
              <dd>{listing.condition}</dd>
            </div>
            <div>
              <dt>Pickup</dt>
              <dd>
                <MapPin size={16} aria-hidden="true" />
                {listing.pickupZone}
              </dd>
            </div>
            {listing.availableFrom ? (
              <div>
                <dt>Available</dt>
                <dd>
                  <CalendarBlank size={16} aria-hidden="true" />
                  {new Intl.DateTimeFormat("en-IN", {
                    day: "numeric",
                    month: "short",
                  }).format(new Date(listing.availableFrom))}
                </dd>
              </div>
            ) : null}
            <div>
              <dt>Price</dt>
              <dd>{listing.negotiable ? "Negotiable" : "Firm"}</dd>
            </div>
          </dl>

          <div className="seller-panel">
            <Avatar student={listing.seller} size="large" />
            <div>
              <strong>
                {listing.seller.name}
                <SealCheck size={17} weight="fill" aria-label="Verified student" />
              </strong>
              <span>{listing.seller.course}</span>
              <small>Member since {listing.seller.joinedYear}</small>
            </div>
          </div>

          <div className="safety-note">
            <ShieldCheck size={21} aria-hidden="true" />
            <p>
              <strong>Meet in a public campus zone.</strong>
              Keep plans and payment confirmation inside Venturr.
            </p>
          </div>

          <form className="offer-form" onSubmit={submitOffer}>
            {listing.type !== "free" && listing.type !== "wanted" ? (
              <label>
                Your offer
                <span className="money-input">
                  <span aria-hidden="true">₹</span>
                  <input
                    value={amount}
                    onChange={(event) => setAmount(event.target.value)}
                    type="number"
                    inputMode="numeric"
                    min="0"
                    max="1000000"
                    required
                  />
                </span>
              </label>
            ) : null}
            <label>
              Message
              <textarea
                value={note}
                onChange={(event) => setNote(event.target.value)}
                maxLength={500}
                rows={3}
                placeholder={
                  listing.type === "wanted"
                    ? "Describe what you have and when you can meet…"
                    : "Ask about condition, availability, or pickup…"
                }
                required
              />
            </label>
            {error ? <p className="field-error" role="alert">{error}</p> : null}
            <button className="button button--primary button--full" type="submit">
              {listing.type === "wanted" ? (
                <ChatCircle size={19} aria-hidden="true" />
              ) : (
                <Handshake size={19} aria-hidden="true" />
              )}
              {actionLabel}
            </button>
          </form>
        </div>
      </div>
    </ModalFrame>
  );
}
