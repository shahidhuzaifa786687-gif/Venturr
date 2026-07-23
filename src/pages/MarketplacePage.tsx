import {
  CaretDown,
  MapPin,
  SealCheck,
  ShieldCheck,
  SlidersHorizontal,
} from "@phosphor-icons/react";
import { useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { EmptyState } from "../components/EmptyState";
import { PrimaryTabs } from "../components/PrimaryTabs";
import { ProductCard } from "../components/ProductCard";
import { useApp } from "../context/AppContext";
import { campusZones, listingCategories } from "../data/catalog";
import type { ListingType } from "../types";

const listingTypes: { value: "all" | ListingType; label: string }[] = [
  { value: "all", label: "All" },
  { value: "buy", label: "Buy" },
  { value: "rent", label: "Rent" },
  { value: "free", label: "Free" },
  { value: "wanted", label: "Wanted" },
];

export function MarketplacePage() {
  const { listings, openPost } = useApp();
  const [searchParams] = useSearchParams();
  const [activeType, setActiveType] = useState<"all" | ListingType>("all");
  const [category, setCategory] = useState("all");
  const [price, setPrice] = useState("all");
  const [zone, setZone] = useState("all");
  const [mobileFiltersOpen, setMobileFiltersOpen] = useState(false);
  const [showAll, setShowAll] = useState(false);
  const query = (searchParams.get("q") ?? "").trim().toLocaleLowerCase();

  const filteredListings = useMemo(
    () =>
      listings.filter((listing) => {
        const searchable = [
          listing.title,
          listing.description,
          listing.category,
          listing.pickupZone,
          listing.seller.name,
        ]
          .join(" ")
          .toLocaleLowerCase();
        const matchesQuery = !query || searchable.includes(query);
        const matchesType = activeType === "all" || listing.type === activeType;
        const matchesCategory = category === "all" || listing.category === category;
        const matchesZone = zone === "all" || listing.pickupZone === zone;
        const matchesPrice =
          price === "all" ||
          (price === "under-500" && listing.price <= 500) ||
          (price === "under-2000" && listing.price <= 2000) ||
          (price === "above-2000" && listing.price > 2000);
        return matchesQuery && matchesType && matchesCategory && matchesZone && matchesPrice;
      }),
    [activeType, category, listings, price, query, zone],
  );

  const activeFilterCount = [category, price, zone].filter((value) => value !== "all").length;
  const hasActiveDiscoveryFilter =
    Boolean(query) || activeType !== "all" || activeFilterCount > 0;
  const displayedListings =
    showAll || hasActiveDiscoveryFilter ? filteredListings : filteredListings.slice(0, 4);

  return (
    <main className="page page--marketplace">
      <section className="page-hero" aria-labelledby="marketplace-heading">
        <div>
          <p className="eyebrow">
            <SealCheck size={16} weight="fill" aria-hidden="true" />
            Campus membership required
          </p>
          <h1 id="marketplace-heading">Find what you need on campus.</h1>
          <p>Buy, rent, give away, or request useful things from students nearby.</p>
        </div>
        <div className="hero-trust-note">
          <ShieldCheck size={23} aria-hidden="true" />
          <span>
            <strong>Safer campus handoffs</strong>
            <small>Chat in-app. Meet in busy public spots.</small>
          </span>
        </div>
      </section>

      <PrimaryTabs />

      <section className="market-controls" aria-label="Marketplace filters">
        <div className="type-tabs" role="group" aria-label="Listing type">
          {listingTypes.map((type) => (
            <button
              className={activeType === type.value ? "is-active" : ""}
              key={type.value}
              onClick={() => setActiveType(type.value)}
              type="button"
              aria-pressed={activeType === type.value}
            >
              {type.label}
            </button>
          ))}
        </div>

        <button
          className="mobile-filter-toggle"
          onClick={() => setMobileFiltersOpen((open) => !open)}
          type="button"
          aria-expanded={mobileFiltersOpen}
        >
          <SlidersHorizontal size={18} aria-hidden="true" />
          Filters
          {activeFilterCount ? <span>{activeFilterCount}</span> : null}
        </button>

        <div className={`filter-selects${mobileFiltersOpen ? " is-open" : ""}`}>
          <label>
            <span className="sr-only">Category</span>
            <select value={category} onChange={(event) => setCategory(event.target.value)}>
              <option value="all">Category</option>
              {listingCategories.map((item) => (
                <option value={item} key={item}>{item}</option>
              ))}
            </select>
            <CaretDown size={15} aria-hidden="true" />
          </label>
          <label>
            <span className="sr-only">Price</span>
            <select value={price} onChange={(event) => setPrice(event.target.value)}>
              <option value="all">Price</option>
              <option value="under-500">Under ₹500</option>
              <option value="under-2000">Under ₹2,000</option>
              <option value="above-2000">Above ₹2,000</option>
            </select>
            <CaretDown size={15} aria-hidden="true" />
          </label>
          <label>
            <span className="sr-only">Pickup zone</span>
            <select value={zone} onChange={(event) => setZone(event.target.value)}>
              <option value="all">Pickup zone</option>
              {campusZones.map((item) => (
                <option value={item} key={item}>{item}</option>
              ))}
            </select>
            <MapPin size={15} aria-hidden="true" />
          </label>
        </div>
      </section>

      <section className="results-section" aria-labelledby="market-results-heading">
        <header className="results-header">
          <div>
            <h2 id="market-results-heading">
              {query ? `Results for “${searchParams.get("q")}”` : "Available nearby"}
            </h2>
            <p>{filteredListings.length} campus listing{filteredListings.length === 1 ? "" : "s"}</p>
          </div>
          <span>Newest first</span>
        </header>

        {filteredListings.length ? (
          <div className="product-grid">
            {displayedListings.map((listing) => (
              <ProductCard listing={listing} key={listing.id} />
            ))}
          </div>
        ) : (
          <EmptyState
            title={hasActiveDiscoveryFilter ? "Nothing matches yet" : "No listings yet"}
            body={
              hasActiveDiscoveryFilter
                ? "Try a broader search or clear your filters."
                : "Listings will appear here when verified members publish them."
            }
            actionLabel="Post a wanted listing"
            onAction={() => openPost("item")}
          />
        )}
        {!showAll && !hasActiveDiscoveryFilter && filteredListings.length > 4 ? (
          <button className="load-more-button" type="button" onClick={() => setShowAll(true)}>
            Show all {filteredListings.length} listings
          </button>
        ) : null}
      </section>
    </main>
  );
}
