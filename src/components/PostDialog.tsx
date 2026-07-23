import {
  Camera,
  CheckCircle,
  Package,
  ShieldCheck,
  UploadSimple,
  UsersThree,
} from "@phosphor-icons/react";
import { useEffect, useState, type ChangeEvent, type FormEvent } from "react";
import { useApp } from "../context/AppContext";
import { campusZones, listingCategories, serviceCategories } from "../data/catalog";
import {
  imageFileSchema,
  itemPostSchema,
  servicePostSchema,
} from "../lib/validation";
import { ModalFrame } from "./ModalFrame";

type ErrorMap = Record<string, string>;

function issueMap(issues: { path: PropertyKey[]; message: string }[]): ErrorMap {
  return Object.fromEntries(
    issues.map((issue) => [String(issue.path[0] ?? "form"), issue.message]),
  );
}

export function PostDialog() {
  const { postKind, closePost, addListing, addService } = useApp();
  const [errors, setErrors] = useState<ErrorMap>({});
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [listingType, setListingType] = useState("buy");

  useEffect(
    () => () => {
      if (previewUrl?.startsWith("blob:")) URL.revokeObjectURL(previewUrl);
    },
    [previewUrl],
  );

  if (!postKind) return null;

  function chooseImage(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;
    const result = imageFileSchema.safeParse(file);
    if (!result.success) {
      setErrors((current) => ({ ...current, image: result.error.issues[0]?.message ?? "Invalid image." }));
      event.target.value = "";
      return;
    }
    if (previewUrl?.startsWith("blob:")) URL.revokeObjectURL(previewUrl);
    setPreviewUrl(URL.createObjectURL(file));
    setErrors((current) => ({ ...current, image: "" }));
  }

  function submitItem(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    const priceUnitValue = String(formData.get("priceUnit") ?? "");
    const raw = {
      title: formData.get("title"),
      description: formData.get("description"),
      type: formData.get("type"),
      category: formData.get("category"),
      condition: formData.get("condition"),
      price: listingType === "free" ? 0 : formData.get("price"),
      ...(priceUnitValue ? { priceUnit: priceUnitValue } : {}),
      pickupZone: formData.get("pickupZone"),
      negotiable: formData.get("negotiable") === "on",
      ...(previewUrl ? { image: previewUrl } : {}),
    };
    const parsed = itemPostSchema.safeParse(raw);
    if (!parsed.success) {
      setErrors(issueMap(parsed.error.issues));
      return;
    }
    addListing(parsed.data);
  }

  function submitService(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    const raw = {
      title: formData.get("title"),
      description: formData.get("description"),
      category: formData.get("category"),
      rate: formData.get("rate"),
      rateUnit: formData.get("rateUnit"),
      format: formData.get("format"),
      nextAvailable: formData.get("nextAvailable"),
      integrityConfirmed: formData.get("integrityConfirmed") === "on",
      ...(previewUrl ? { image: previewUrl } : {}),
    };
    const parsed = servicePostSchema.safeParse(raw);
    if (!parsed.success) {
      setErrors(issueMap(parsed.error.issues));
      return;
    }
    addService(parsed.data);
  }

  return (
    <ModalFrame
      labelledBy="post-dialog-title"
      onClose={closePost}
      size="large"
    >
      <div className="post-dialog">
        <header className="post-dialog__header">
          <span className="post-dialog__icon" aria-hidden="true">
            {postKind === "item" ? <Package size={24} /> : <UsersThree size={24} />}
          </span>
          <div>
            <p className="eyebrow">{postKind === "item" ? "Marketplace" : "Student services"}</p>
            <h2 id="post-dialog-title">
              {postKind === "item" ? "List an item" : "Offer a service"}
            </h2>
            <p>
              {postKind === "item"
                ? "Add the details students need to decide quickly."
                : "Set a clear scope, rate, format, and first available time."}
            </p>
          </div>
        </header>

        <form
          className="post-form"
          onSubmit={postKind === "item" ? submitItem : submitService}
          noValidate
        >
          <div className="post-form__main">
            <label className="field field--full">
              {postKind === "item" ? "Title" : "Service title"}
              <input
                name="title"
                maxLength={postKind === "item" ? 80 : 90}
                placeholder={
                  postKind === "item"
                    ? "e.g. Scientific calculator"
                    : "e.g. Calculus concept tutoring"
                }
                aria-invalid={Boolean(errors.title)}
                required
              />
              {errors.title ? <span className="field-error">{errors.title}</span> : null}
            </label>

            {postKind === "item" ? (
              <>
                <fieldset className="field field--full">
                  <legend>Listing type</legend>
                  <div className="segmented-input segmented-input--four">
                    {[
                      ["buy", "Sell"],
                      ["rent", "Rent"],
                      ["free", "Free"],
                      ["wanted", "Wanted"],
                    ].map(([value, label]) => (
                      <label key={value}>
                        <input
                          checked={listingType === value}
                          name="type"
                          onChange={() => setListingType(value!)}
                          type="radio"
                          value={value}
                        />
                        <span>{label}</span>
                      </label>
                    ))}
                  </div>
                </fieldset>

                <label className="field">
                  Category
                  <select name="category" defaultValue="Electronics">
                    {listingCategories.map((category) => (
                      <option key={category}>{category}</option>
                    ))}
                  </select>
                </label>
                <label className="field">
                  Condition
                  <select name="condition" defaultValue="Good">
                    <option>New</option>
                    <option>Like new</option>
                    <option>Good</option>
                    <option>Fair</option>
                  </select>
                </label>
              </>
            ) : (
              <>
                <label className="field">
                  Category
                  <select name="category" defaultValue="Tutoring">
                    {serviceCategories.map((category) => (
                      <option key={category}>{category}</option>
                    ))}
                  </select>
                </label>
                <label className="field">
                  Session format
                  <select name="format" defaultValue="Both">
                    <option>Online</option>
                    <option>On campus</option>
                    <option>Both</option>
                  </select>
                </label>
              </>
            )}

            <label className="field field--full">
              Description
              <textarea
                name="description"
                maxLength={postKind === "item" ? 800 : 1000}
                rows={4}
                placeholder={
                  postKind === "item"
                    ? "Condition, what is included, and any defects…"
                    : "What you can help with, what the student should bring, and what they will leave with…"
                }
                aria-invalid={Boolean(errors.description)}
                required
              />
              <small>
                Keep it specific. Contact details and exact room locations stay private.
              </small>
              {errors.description ? (
                <span className="field-error">{errors.description}</span>
              ) : null}
            </label>

            <label className="field">
              {postKind === "item" && listingType === "wanted" ? "Budget" : "Price"}
              <span className="money-input">
                <span aria-hidden="true">₹</span>
                <input
                  disabled={postKind === "item" && listingType === "free"}
                  name={postKind === "item" ? "price" : "rate"}
                  type="number"
                  inputMode="numeric"
                  min="0"
                  max={postKind === "item" ? 1000000 : 100000}
                  defaultValue={postKind === "item" && listingType === "free" ? "0" : ""}
                  placeholder="0"
                  required
                />
              </span>
              {errors.price || errors.rate ? (
                <span className="field-error">{errors.price || errors.rate}</span>
              ) : null}
            </label>

            {postKind === "item" ? (
              listingType === "rent" ? (
                <label className="field">
                  Billing period
                  <select name="priceUnit" defaultValue="week">
                    <option value="day">Per day</option>
                    <option value="week">Per week</option>
                    <option value="month">Per month</option>
                  </select>
                  {errors.priceUnit ? (
                    <span className="field-error">{errors.priceUnit}</span>
                  ) : null}
                </label>
              ) : (
                <label className="field">
                  Public pickup zone
                  <select name="pickupZone" defaultValue="" disabled={!campusZones.length}>
                    {!campusZones.length ? <option value="">No campus zones configured</option> : null}
                    {campusZones.map((zone) => (
                      <option key={zone}>{zone}</option>
                    ))}
                  </select>
                </label>
              )
            ) : (
              <label className="field">
                Rate unit
                <select name="rateUnit" defaultValue="hour">
                  <option value="hour">Per hour</option>
                  <option value="session">Per session</option>
                  <option value="project">Per scoped project</option>
                </select>
              </label>
            )}

            {postKind === "item" && listingType === "rent" ? (
              <label className="field">
                Public pickup zone
                <select name="pickupZone" defaultValue="" disabled={!campusZones.length}>
                  {!campusZones.length ? <option value="">No campus zones configured</option> : null}
                  {campusZones.map((zone) => (
                    <option key={zone}>{zone}</option>
                  ))}
                </select>
              </label>
            ) : null}

            {postKind === "service" ? (
              <label className="field">
                First available time
                <input
                  name="nextAvailable"
                  maxLength={80}
                  placeholder="e.g. Friday · 5:00 PM"
                  required
                />
                {errors.nextAvailable ? (
                  <span className="field-error">{errors.nextAvailable}</span>
                ) : null}
              </label>
            ) : null}

            {postKind === "item" ? (
              <label className="check-field field--full">
                <input name="negotiable" type="checkbox" defaultChecked />
                <span>
                  <strong>Open to reasonable offers</strong>
                  <small>Students can include a price when they message.</small>
                </span>
              </label>
            ) : (
              <label className="check-field check-field--integrity field--full">
                <input name="integrityConfirmed" type="checkbox" required />
                <ShieldCheck size={21} aria-hidden="true" />
                <span>
                  <strong>I will coach, explain, review, or collaborate—not impersonate.</strong>
                  <small>
                    No completing graded work, sitting assessments, or submitting work for someone.
                  </small>
                  {errors.integrityConfirmed ? (
                    <span className="field-error">{errors.integrityConfirmed}</span>
                  ) : null}
                </span>
              </label>
            )}
          </div>

          <aside className="post-form__media">
            <label className={`upload-zone${previewUrl ? " has-preview" : ""}`}>
              {previewUrl ? (
                <img src={previewUrl} alt="Selected upload preview" />
              ) : (
                <>
                  <span>
                    <Camera size={28} aria-hidden="true" />
                  </span>
                  <strong>{postKind === "item" ? "Add a clear photo" : "Add a profile or work photo"}</strong>
                  <small>JPEG, PNG, or WebP · max 5 MB</small>
                  <em>
                    <UploadSimple size={17} aria-hidden="true" />
                    Choose image
                  </em>
                </>
              )}
              <input
                name="imageFile"
                type="file"
                accept="image/jpeg,image/png,image/webp"
                onChange={chooseImage}
              />
            </label>
            {errors.image ? <span className="field-error">{errors.image}</span> : null}
            <div className="post-form__tip">
              <CheckCircle size={20} weight="fill" aria-hidden="true" />
              <p>
                {postKind === "item"
                  ? "Use natural light and show the real condition. Avoid screenshots or stock photos."
                  : "Use a clear photo that helps students understand who or what they are booking."}
              </p>
            </div>
          </aside>

          <footer className="post-form__footer">
            <button className="button button--secondary" type="button" onClick={closePost}>
              Save draft
            </button>
            <button className="button button--primary" type="submit">
              {postKind === "item" ? <Package size={19} /> : <UsersThree size={19} />}
              {postKind === "item" ? "Publish listing" : "Publish service"}
            </button>
          </footer>
        </form>
      </div>
    </ModalFrame>
  );
}
