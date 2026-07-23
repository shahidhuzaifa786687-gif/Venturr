import {
  CaretDown,
  GraduationCap,
  SealCheck,
  ShieldCheck,
  SlidersHorizontal,
  UsersThree,
} from "@phosphor-icons/react";
import { useMemo, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { EmptyState } from "../components/EmptyState";
import { PrimaryTabs } from "../components/PrimaryTabs";
import { ServiceCard } from "../components/ServiceCard";
import { useApp } from "../context/AppContext";
import { serviceCategories } from "../data/catalog";

export function ServicesPage() {
  const { services, openPost } = useApp();
  const [searchParams] = useSearchParams();
  const [category, setCategory] = useState("all");
  const [format, setFormat] = useState("all");
  const [price, setPrice] = useState("all");
  const [mobileFiltersOpen, setMobileFiltersOpen] = useState(false);
  const query = (searchParams.get("q") ?? "").trim().toLocaleLowerCase();

  const filteredServices = useMemo(
    () =>
      services.filter((service) => {
        const searchable = [
          service.title,
          service.description,
          service.category,
          service.provider.name,
        ]
          .join(" ")
          .toLocaleLowerCase();
        const matchesQuery = !query || searchable.includes(query);
        const matchesCategory = category === "all" || service.category === category;
        const matchesFormat =
          format === "all" ||
          service.format === format ||
          service.format === "Both";
        const matchesPrice =
          price === "all" ||
          (price === "under-300" && service.rate <= 300) ||
          (price === "under-500" && service.rate <= 500) ||
          (price === "above-500" && service.rate > 500);
        return matchesQuery && matchesCategory && matchesFormat && matchesPrice;
      }),
    [category, format, price, query, services],
  );

  const activeFilterCount = [category, format, price].filter((value) => value !== "all").length;

  return (
    <main className="page page--services">
      <section className="page-hero" aria-labelledby="services-heading">
        <div>
          <p className="eyebrow">
            <SealCheck size={16} weight="fill" aria-hidden="true" />
            Student-led help · campus membership required
          </p>
          <h1 id="services-heading">Learn together. Get unstuck.</h1>
          <p>Book tutoring, practical feedback, creative support, and everyday help from verified students.</p>
        </div>
        <button className="button button--primary" type="button" onClick={() => openPost("service")}>
          <UsersThree size={19} aria-hidden="true" />
          Offer a service
        </button>
      </section>

      <PrimaryTabs />

      <div className="integrity-banner">
        <ShieldCheck size={22} aria-hidden="true" />
        <div>
          <strong>Help that keeps the work yours.</strong>
          <span>
            Coaching, feedback, debugging, and collaboration are welcome. Impersonation,
            test-taking, and submitting graded work for someone else are not.
          </span>
        </div>
        <Link to="/safety#academic-integrity">
          Read the standard
        </Link>
      </div>

      <section className="service-controls" aria-label="Service filters">
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
            <GraduationCap size={17} aria-hidden="true" />
            <span className="sr-only">Service category</span>
            <select value={category} onChange={(event) => setCategory(event.target.value)}>
              <option value="all">All categories</option>
              {serviceCategories.map((item) => (
                <option value={item} key={item}>{item}</option>
              ))}
            </select>
            <CaretDown size={15} aria-hidden="true" />
          </label>
          <label>
            <span className="sr-only">Format</span>
            <select value={format} onChange={(event) => setFormat(event.target.value)}>
              <option value="all">Any format</option>
              <option>Online</option>
              <option>On campus</option>
            </select>
            <CaretDown size={15} aria-hidden="true" />
          </label>
          <label>
            <span className="sr-only">Rate</span>
            <select value={price} onChange={(event) => setPrice(event.target.value)}>
              <option value="all">Any rate</option>
              <option value="under-300">Up to ₹300</option>
              <option value="under-500">Up to ₹500</option>
              <option value="above-500">Above ₹500</option>
            </select>
            <CaretDown size={15} aria-hidden="true" />
          </label>
        </div>
      </section>

      <section className="results-section" aria-labelledby="service-results-heading">
        <header className="results-header">
          <div>
            <h2 id="service-results-heading">
              {query ? `Services matching “${searchParams.get("q")}”` : "Student services"}
            </h2>
            <p>{filteredServices.length} available provider{filteredServices.length === 1 ? "" : "s"}</p>
          </div>
          <span>Next available</span>
        </header>

        {filteredServices.length ? (
          <div className="service-grid">
            {filteredServices.map((service) => (
              <ServiceCard service={service} key={service.id} />
            ))}
          </div>
        ) : (
          <EmptyState
            title={query || activeFilterCount ? "No services match" : "No services yet"}
            body={
              query || activeFilterCount
                ? "Try another category or clear your filters."
                : "Service offers will appear here when verified students publish them."
            }
            actionLabel="Offer a service"
            onAction={() => openPost("service")}
          />
        )}
      </section>
    </main>
  );
}
