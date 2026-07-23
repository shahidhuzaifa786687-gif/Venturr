import {
  BookmarkSimple,
  CalendarBlank,
  Globe,
  MapPin,
  SealCheck,
  Star,
} from "@phosphor-icons/react";
import { useState } from "react";
import { useApp } from "../context/AppContext";
import { formatCurrency } from "../lib/format";
import type { ServiceOffer } from "../types";
import { ServiceDialog } from "./ServiceDialog";
import { VisuallyHidden } from "./VisuallyHidden";

export function ServiceCard({ service }: { service: ServiceOffer }) {
  const [detailsOpen, setDetailsOpen] = useState(false);
  const { savedServiceIds, toggleSavedService } = useApp();
  const saved = savedServiceIds.has(service.id);

  return (
    <>
      <article className="service-card">
        <div className="service-card__media">
          <button type="button" onClick={() => setDetailsOpen(true)} aria-label={`View ${service.title}`}>
            <img src={service.image} alt={service.imageAlt} />
          </button>
          <span>{service.category}</span>
          <button
            className={`save-button${saved ? " is-saved" : ""}`}
            type="button"
            onClick={() => toggleSavedService(service.id)}
            aria-pressed={saved}
          >
            <VisuallyHidden>{saved ? "Remove from saved" : "Save"} {service.title}</VisuallyHidden>
            <BookmarkSimple size={21} weight={saved ? "fill" : "regular"} aria-hidden="true" />
          </button>
        </div>

        <div className="service-card__body">
          <p className="eyebrow">{service.category}</p>
          <h3 className="card-heading">
            <button className="service-card__title" type="button" onClick={() => setDetailsOpen(true)}>
              {service.title}
            </button>
          </h3>
          <p className="service-card__description">{service.description}</p>
          <div className="service-card__facts">
            <span>
              {service.format === "Online" ? <Globe size={16} /> : <MapPin size={16} />}
              {service.format}
            </span>
            <span>
              <CalendarBlank size={16} />
              {service.nextAvailable}
            </span>
          </div>
        </div>

        <footer className="service-card__footer">
          <div className="service-provider">
            <span className="service-provider__initials">{service.provider.initials}</span>
            <span>
              <strong>
                {service.provider.name}
                <SealCheck size={15} weight="fill" aria-label="Verified student" />
              </strong>
              {service.rating ? (
                <small>
                  <Star size={14} weight="fill" aria-hidden="true" />
                  {service.rating} · {service.completedSessions} sessions
                </small>
              ) : (
                <small>New provider</small>
              )}
            </span>
          </div>
          <div className="service-card__request">
            <strong>
              {formatCurrency(service.rate)}
              <small> / {service.rateUnit}</small>
            </strong>
            <button className="button button--secondary button--small" type="button" onClick={() => setDetailsOpen(true)}>
              Request
            </button>
          </div>
        </footer>
      </article>

      {detailsOpen ? (
        <ServiceDialog service={service} onClose={() => setDetailsOpen(false)} />
      ) : null}
    </>
  );
}
