import { BookmarkSimple, Package, UsersThree } from "@phosphor-icons/react";
import { useState } from "react";
import { EmptyState } from "../components/EmptyState";
import { ProductCard } from "../components/ProductCard";
import { ServiceCard } from "../components/ServiceCard";
import { useApp } from "../context/AppContext";

export function SavedPage() {
  const {
    listings,
    services,
    savedListingIds,
    savedServiceIds,
  } = useApp();
  const [tab, setTab] = useState<"items" | "services">("items");
  const savedListings = listings.filter((listing) => savedListingIds.has(listing.id));
  const savedServices = services.filter((service) => savedServiceIds.has(service.id));

  return (
    <main className="page page--saved">
      <section className="simple-hero">
        <p className="eyebrow">
          <BookmarkSimple size={16} weight="fill" />
          Your shortlist
        </p>
        <h1>Saved for later.</h1>
        <p>Keep useful items and providers together while you decide.</p>
      </section>

      <div className="secondary-tabs" role="tablist" aria-label="Saved content">
        <button
          className={tab === "items" ? "is-active" : ""}
          onClick={() => setTab("items")}
          type="button"
          role="tab"
          aria-selected={tab === "items"}
        >
          <Package size={19} />
          Items
          <span>{savedListings.length}</span>
        </button>
        <button
          className={tab === "services" ? "is-active" : ""}
          onClick={() => setTab("services")}
          type="button"
          role="tab"
          aria-selected={tab === "services"}
        >
          <UsersThree size={19} />
          Services
          <span>{savedServices.length}</span>
        </button>
      </div>

      {tab === "items" ? (
        savedListings.length ? (
          <div className="product-grid">
            {savedListings.map((listing) => (
              <ProductCard listing={listing} key={listing.id} />
            ))}
          </div>
        ) : (
          <EmptyState
            title="No saved items yet"
            body="Tap the bookmark on a listing to build a shortlist."
          />
        )
      ) : savedServices.length ? (
        <div className="service-grid">
          {savedServices.map((service) => (
            <ServiceCard service={service} key={service.id} />
          ))}
        </div>
      ) : (
        <EmptyState
          title="No saved services yet"
          body="Save a provider when you want to compare schedules or rates."
        />
      )}
    </main>
  );
}
