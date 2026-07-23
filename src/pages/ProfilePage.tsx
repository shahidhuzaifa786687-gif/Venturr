import {
  Buildings,
  CalendarBlank,
  Package,
  SealCheck,
  ShieldCheck,
  SignOut,
  UsersThree,
} from "@phosphor-icons/react";
import { useState } from "react";
import { Avatar } from "../components/Avatar";
import { EmptyState } from "../components/EmptyState";
import { ProductCard } from "../components/ProductCard";
import { ServiceCard } from "../components/ServiceCard";
import { useApp } from "../context/AppContext";
import { useAuth } from "../context/AuthContext";

export function ProfilePage() {
  const { listings, services, openPost } = useApp();
  const { signOut, student, user } = useAuth();
  const [tab, setTab] = useState<"items" | "services">("items");
  const myListings = listings.filter((listing) => listing.isMine);
  const myServices = services.filter((service) => service.isMine);

  if (!student) return null;

  return (
    <main className="page page--profile">
      <section className="profile-hero">
        <Avatar student={student} size="large" />
        <div>
          <p className="eyebrow">
            <SealCheck size={16} weight="fill" />
            Campus verification pending
          </p>
          <h1>{student.name}</h1>
          <p>{user?.email ?? student.course}</p>
        </div>
        <dl>
          <div>
            <dt><Buildings size={17} /> Campus</dt>
            <dd>Not connected</dd>
          </div>
          <div>
            <dt><CalendarBlank size={17} /> Member since</dt>
            <dd>{student.joinedYear}</dd>
          </div>
          <div>
            <dt><ShieldCheck size={17} /> Trust</dt>
            <dd>Verification required</dd>
          </div>
        </dl>
        <button className="button button--secondary" type="button" onClick={() => void signOut()}>
          <SignOut size={18} />
          Sign out
        </button>
      </section>

      <div className="secondary-tabs" role="tablist" aria-label="Your posts">
        <button
          className={tab === "items" ? "is-active" : ""}
          onClick={() => setTab("items")}
          type="button"
          role="tab"
          aria-selected={tab === "items"}
        >
          <Package size={19} />
          My listings
          <span>{myListings.length}</span>
        </button>
        <button
          className={tab === "services" ? "is-active" : ""}
          onClick={() => setTab("services")}
          type="button"
          role="tab"
          aria-selected={tab === "services"}
        >
          <UsersThree size={19} />
          My services
          <span>{myServices.length}</span>
        </button>
      </div>

      {tab === "items" ? (
        myListings.length ? (
          <div className="product-grid">
            {myListings.map((listing) => (
              <ProductCard listing={listing} key={listing.id} />
            ))}
          </div>
        ) : (
          <EmptyState
            title="You have not listed anything yet"
            body="Turn unused campus gear into cash, a rental, or a useful giveaway."
            actionLabel="List an item"
            onAction={() => openPost("item")}
          />
        )
      ) : myServices.length ? (
        <div className="service-grid">
          {myServices.map((service) => (
            <ServiceCard service={service} key={service.id} />
          ))}
        </div>
      ) : (
        <EmptyState
          title="You are not offering a service yet"
          body="Share a skill with a clear scope, rate, and academic-integrity boundary."
          actionLabel="Offer a service"
          onAction={() => openPost("service")}
        />
      )}
    </main>
  );
}
