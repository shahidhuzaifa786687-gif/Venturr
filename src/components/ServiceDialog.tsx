import {
  CalendarCheck,
  CheckCircle,
  Globe,
  MapPin,
  SealCheck,
  ShieldCheck,
  Star,
} from "@phosphor-icons/react";
import { useState, type FormEvent } from "react";
import { useApp } from "../context/AppContext";
import { formatCurrency } from "../lib/format";
import { messageSchema } from "../lib/validation";
import type { ServiceOffer } from "../types";
import { Avatar } from "./Avatar";
import { ModalFrame } from "./ModalFrame";

export function ServiceDialog({
  service,
  onClose,
}: {
  service: ServiceOffer;
  onClose: () => void;
}) {
  const { startServiceConversation } = useApp();
  const [message, setMessage] = useState("");
  const [time, setTime] = useState(service.nextAvailable);
  const [error, setError] = useState("");

  function submitRequest(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const parsed = messageSchema.safeParse(message);
    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? "Add a short note.");
      return;
    }
    startServiceConversation(service, `Preferred time: ${time}. ${parsed.data}`);
    onClose();
  }

  return (
    <ModalFrame labelledBy={`service-title-${service.id}`} onClose={onClose} size="large">
      <div className="service-detail">
        <div className="service-detail__visual">
          <img src={service.image} alt={service.imageAlt} />
          <div className="service-detail__rate">
            <span>From</span>
            <strong>{formatCurrency(service.rate)}</strong>
            <small>per {service.rateUnit}</small>
          </div>
        </div>

        <div className="service-detail__content">
          <p className="eyebrow">{service.category}</p>
          <h2 id={`service-title-${service.id}`}>{service.title}</h2>
          <p className="detail-description">{service.description}</p>

          <div className="service-provider service-provider--large">
            <Avatar student={service.provider} size="large" />
            <span>
              <strong>
                {service.provider.name}
                <SealCheck size={17} weight="fill" aria-label="Verified student" />
              </strong>
              <small>{service.provider.course}</small>
              {service.rating ? (
                <small>
                  <Star size={14} weight="fill" aria-hidden="true" />
                  {service.rating} from {service.completedSessions} completed sessions
                </small>
              ) : null}
            </span>
          </div>

          <ul className="service-detail__facts" aria-label="Service details">
            <li>
              {service.format === "Online" ? <Globe size={18} /> : <MapPin size={18} />}
              {service.format}
            </li>
            <li>
              <CalendarCheck size={18} />
              Next: {service.nextAvailable}
            </li>
            <li>
              <CheckCircle size={18} />
              You remain in control of your own work
            </li>
          </ul>

          <div className="integrity-note">
            <ShieldCheck size={22} aria-hidden="true" />
            <p>
              <strong>Coaching and feedback, not work-for-hire.</strong>
              Providers can explain, review, and collaborate. They cannot complete graded work,
              impersonate a student, or take an assessment.
            </p>
          </div>

          <form className="request-form" onSubmit={submitRequest}>
            <label>
              Preferred time
              <select value={time} onChange={(event) => setTime(event.target.value)}>
                <option>{service.nextAvailable}</option>
                <option>Tomorrow · 5:30 PM</option>
                <option>Saturday · 11:00 AM</option>
              </select>
            </label>
            <label>
              What would you like help with?
              <textarea
                value={message}
                onChange={(event) => setMessage(event.target.value)}
                maxLength={1000}
                rows={3}
                placeholder="Share the topic, your goal, and where you are stuck…"
                required
              />
            </label>
            {error ? <p className="field-error" role="alert">{error}</p> : null}
            <button className="button button--primary button--full" type="submit">
              <CalendarCheck size={19} aria-hidden="true" />
              Request session
            </button>
          </form>
        </div>
      </div>
    </ModalFrame>
  );
}
