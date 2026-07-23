import {
  BookmarkSimple,
  MapPin,
  SealCheck,
  Tag,
} from "@phosphor-icons/react";
import { useState } from "react";
import { useApp } from "../context/AppContext";
import { formatListingPrice, formatRelativeTime } from "../lib/format";
import type { Listing } from "../types";
import { ListingDialog } from "./ListingDialog";
import { VisuallyHidden } from "./VisuallyHidden";

const typeLabels: Record<Listing["type"], string> = {
  buy: "For sale",
  rent: "Rent",
  free: "Free",
  wanted: "Wanted",
};

export function ProductCard({ listing }: { listing: Listing }) {
  const [detailsOpen, setDetailsOpen] = useState(false);
  const { savedListingIds, toggleSavedListing } = useApp();
  const saved = savedListingIds.has(listing.id);

  return (
    <>
      <article className="product-card">
        <div className="product-card__media">
          <button
            className="product-card__image-button"
            type="button"
            onClick={() => setDetailsOpen(true)}
            aria-label={`View ${listing.title}`}
          >
            <img src={listing.image} alt={listing.imageAlt} />
          </button>
          <span className={`listing-type listing-type--${listing.type}`}>
            {typeLabels[listing.type]}
          </span>
          <button
            className={`save-button${saved ? " is-saved" : ""}`}
            type="button"
            onClick={() => toggleSavedListing(listing.id)}
            aria-pressed={saved}
          >
            <VisuallyHidden>{saved ? "Remove from saved" : "Save"} {listing.title}</VisuallyHidden>
            <BookmarkSimple size={21} weight={saved ? "fill" : "regular"} aria-hidden="true" />
          </button>
        </div>

        <div className="product-card__body">
          <div className="product-card__price">
            {formatListingPrice(listing.type, listing.price, listing.priceUnit)}
          </div>
          <h3 className="card-heading">
            <button
              className="product-card__title"
              type="button"
              onClick={() => setDetailsOpen(true)}
            >
              {listing.title}
            </button>
          </h3>
          <p className="product-card__condition">{listing.condition}</p>
          <p className="product-card__location">
            <MapPin size={15} aria-hidden="true" />
            {listing.pickupZone}
          </p>
        </div>

        <footer className="product-card__footer">
          <span className="seller-inline">
            <SealCheck size={17} weight="fill" aria-hidden="true" />
            {listing.seller.name}
            <span aria-hidden="true">·</span>
            {formatRelativeTime(listing.createdAt)}
          </span>
          <button className="button button--secondary button--small" onClick={() => setDetailsOpen(true)}>
            <Tag size={16} aria-hidden="true" />
            {listing.type === "wanted" ? "Respond" : listing.type === "free" ? "Request" : "Make offer"}
          </button>
        </footer>
      </article>

      {detailsOpen ? (
        <ListingDialog listing={listing} onClose={() => setDetailsOpen(false)} />
      ) : null}
    </>
  );
}
