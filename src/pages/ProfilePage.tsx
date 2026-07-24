import {
  Buildings,
  CalendarBlank,
  FloppyDisk,
  GraduationCap,
  Package,
  PencilSimple,
  SealCheck,
  ShieldCheck,
  SignOut,
  UsersThree,
  X,
} from "@phosphor-icons/react";
import { useState, type FormEvent } from "react";
import { Avatar } from "../components/Avatar";
import { EmptyState } from "../components/EmptyState";
import { ProductCard } from "../components/ProductCard";
import { ServiceCard } from "../components/ServiceCard";
import { useApp } from "../context/AppContext";
import { useAuth } from "../context/AuthContext";
import { profileSchema } from "../lib/validation";

export function ProfilePage() {
  const { listings, services, openPost } = useApp();
  const { membership, profile, signOut, student, updateProfile, user } = useAuth();
  const [tab, setTab] = useState<"items" | "services">("items");
  const [editing, setEditing] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState("");
  const [messageIsError, setMessageIsError] = useState(false);
  const myListings = listings.filter((listing) => listing.isMine);
  const myServices = services.filter((service) => service.isMine);

  if (!student || !profile) return null;

  async function saveProfile(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setMessage("");
    const formData = new FormData(event.currentTarget);
    const parsed = profileSchema.safeParse({
      displayName: formData.get("displayName"),
      course: formData.get("course"),
      graduationYear: formData.get("graduationYear"),
      bio: formData.get("bio"),
    });
    if (!parsed.success) {
      setMessageIsError(true);
      setMessage(parsed.error.issues[0]?.message ?? "Check your profile details.");
      return;
    }

    setSubmitting(true);
    try {
      await updateProfile(parsed.data);
      setEditing(false);
      setMessageIsError(false);
      setMessage("Your profile has been updated.");
    } catch {
      setMessageIsError(true);
      setMessage("We could not update your profile. Try again.");
    } finally {
      setSubmitting(false);
    }
  }

  const membershipLabel =
    membership?.status === "verified"
      ? "Verified college member"
      : membership?.status === "pending"
        ? "College ID review pending"
        : "Campus verification required";

  return (
    <main className="page page--profile">
      <section className="profile-hero">
        <Avatar student={student} size="large" />
        <div>
          <p className="eyebrow">
            <SealCheck size={16} weight="fill" />
            {membershipLabel}
          </p>
          <h1>{student.name}</h1>
          <p>{profile.course}</p>
        </div>
        <dl>
          <div>
            <dt><Buildings size={17} /> Campus</dt>
            <dd>{membership?.campus.name ?? "Not connected"}</dd>
          </div>
          <div>
            <dt><CalendarBlank size={17} /> Member since</dt>
            <dd>{student.joinedYear}</dd>
          </div>
          <div>
            <dt><ShieldCheck size={17} /> Trust</dt>
            <dd>{membership?.status === "verified" ? "College email verified" : "Review pending"}</dd>
          </div>
        </dl>
        <div className="profile-hero__actions">
          <button
            className="button button--secondary"
            type="button"
            onClick={() => {
              setEditing((current) => !current);
              setMessage("");
            }}
          >
            {editing ? <X size={18} /> : <PencilSimple size={18} />}
            {editing ? "Cancel" : "Edit profile"}
          </button>
          <button className="button button--secondary" type="button" onClick={() => void signOut()}>
            <SignOut size={18} />
            Sign out
          </button>
        </div>
      </section>

      {editing ? (
        <section className="profile-editor" aria-labelledby="profile-editor-heading">
          <header>
            <p className="eyebrow"><GraduationCap size={16} /> Public profile</p>
            <h2 id="profile-editor-heading">Edit your profile</h2>
            <p>Your email remains private and cannot be changed from this screen.</p>
          </header>
          <form className="profile-form" onSubmit={saveProfile} noValidate>
            <label className="field">
              Display name
              <input
                name="displayName"
                type="text"
                defaultValue={profile.displayName}
                maxLength={60}
                required
              />
            </label>
            <label className="field">
              Course or program
              <input
                name="course"
                type="text"
                defaultValue={profile.course}
                maxLength={100}
                required
              />
            </label>
            <label className="field">
              Graduation year
              <input
                name="graduationYear"
                type="number"
                defaultValue={profile.graduationYear ?? new Date().getFullYear()}
                min={new Date().getFullYear() - 8}
                max={new Date().getFullYear() + 10}
                required
              />
            </label>
            <label className="field">
              College email
              <input type="email" value={user?.email ?? ""} disabled readOnly />
            </label>
            <label className="field field--full">
              Short bio
              <textarea
                name="bio"
                rows={4}
                defaultValue={profile.bio}
                maxLength={320}
              />
            </label>
            <button
              className="button button--primary field--full"
              type="submit"
              disabled={submitting}
            >
              <FloppyDisk size={18} aria-hidden="true" />
              {submitting ? "Saving..." : "Save profile"}
            </button>
          </form>
        </section>
      ) : profile.bio ? (
        <section className="profile-about" aria-labelledby="profile-about-heading">
          <p className="eyebrow">About</p>
          <h2 id="profile-about-heading">A little more about {student.name.split(/\s+/)[0]}</h2>
          <p>{profile.bio}</p>
        </section>
      ) : null}

      {message ? (
        <div
          className={`auth-message ${messageIsError ? "auth-message--error" : "auth-message--success"}`}
          role={messageIsError ? "alert" : "status"}
        >
          {message}
        </div>
      ) : null}

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
