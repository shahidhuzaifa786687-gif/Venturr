# Legacy Prototype Audit

Status: historical reference for the pre-React prototype.  
Scope: the root HTML, CSS, JavaScript, page copies, assets, and local development files that existed before the redesign.

## Product proposition

The prototype presents a campus-local student marketplace where students can browse, search, list, and discuss secondhand items. Its durable idea is:

> Help verified students exchange useful items with nearby peers and arrange a safe campus handoff.

The implementation also mixes in services and a conventional multi-seller cart. Those are not part of the same transaction flow:

- Marketplace inventory is one-off sale, rental, free, or wanted inventory.
- Services need a separate top-level experience with provider, availability, booking, and completion states.
- A peer-to-peer offer, chat, reservation, and handoff flow should replace the pretend store checkout.

The legacy tree used conflicting working names. **Venturr** is now the confirmed
product name; rentals remain an explicit launch-scope decision.

## Existing flows and health

| Flow | Legacy state | Migration disposition |
| --- | --- | --- |
| Landing and discovery | Functional demo with unsupported seller/rating claims | Rebuild with real or clearly labeled data |
| Search, category filter, sort | Works only in the current document | Preserve behavior; move state to URL-backed filters |
| Listing detail | Native dialog opens; seller email is exposed | Rebuild as an accessible route or sheet with private chat |
| Saved cart | Breaks after reload because demo listing IDs change | Replace with saved items and offers |
| Checkout | Clears local data and reports a fake order | Remove |
| Create listing | Browser-only persistence; photo quota failures are uncaught | Rebuild against authenticated Supabase data and Storage |
| Login | Any name/email is accepted without verification | Replace with Supabase Auth and campus membership |
| Messaging | Saves only in the sender's browser | Replace with participant-scoped conversations |
| Mobile navigation | Hamburger opens an empty navigation region | Replace with a real responsive app shell |
| Secondary pages | Duplicate inconsistent subsets of the homepage | Replace with one React route tree |

## Critical implementation defects

1. `app.js` has a function named `escapeHTML()` that leaves `<`, `>`, and quotes unchanged. User-controlled values are then interpolated into `innerHTML`. A listing or profile can therefore execute stored script. The production app must use React's normal text rendering and must not use `dangerouslySetInnerHTML` for user content.
2. Demo listing IDs are regenerated on every page load. Cart entries saved in localStorage point to missing records after refresh or navigation.
3. Listing image paths are document-relative. They resolve under `/pages/` and break on the copied marketplace page.
4. `pages/sell.html` has no toast container. Publishing or clearing a listing persists data and then throws.
5. The mobile menu is empty. On the dedicated sell/about pages, desktop links disappear at the mobile breakpoint without a replacement.
6. Listing ownership is inferred from `!isDemo`, not an authenticated user ID. Any non-demo record in the browser is considered owned.
7. "Newest first" has no timestamp logic. Messages never reach a recipient. Checkout never creates an order or reservation.
8. LocalStorage records are not schema-validated, and writes do not handle quota errors.
9. The canonical URL is `https://example.com/`, README/TODO content is stale, and there is no package manifest, lockfile, CI, linting, or test suite.

## Security and privacy risks

- The broken escaping path is a persistent XSS vulnerability once listings become shared data.
- The demo login provides neither authentication nor authorization.
- Names, email addresses, listing photos, contact details, carts, and messages persist indefinitely in localStorage and are available to any same-origin script.
- Seller email and free-form location are rendered publicly in the listing dialog.
- File inputs accept any `image/*` without authoritative byte, type, size, or pixel limits.
- There are no row-level policies, server validation, abuse limits, reports, blocks, moderation states, or privileged-action audit records.
- There is no Content Security Policy or application-owned security-header configuration.
- Dorm/room-level location and direct contact fields would create avoidable student-safety risk.

No secret-like credentials were found in the legacy tree. That does not reduce the need for a strict environment-variable boundary in the replacement.

## Accessibility and responsive issues

- No skip link or reduced-motion treatment.
- Inputs and selects suppress the native outline without a strong focus-visible replacement.
- The cart drawer is not a modal dialog, does not manage focus, and does not close with Escape.
- The product dialog has no visible close button or explicit accessible title relationship.
- Quantity controls are 26px square and lack descriptive labels.
- The entire results grid is an `aria-live` region, which can make search typing excessively noisy.
- Decorative emoji are not consistently hidden from assistive technology.
- Forms rely only on native validation and provide no persistent inline recovery guidance.
- The header is crowded at intermediate widths; the mobile menu contains no destinations.
- Animation owns the same `transform` property as the mobile card scaling rule, so the intended scale is not applied.

Known contrast failures in the final CSS cascade include cyan prices, destructive controls, the benefit strip, and footer navigation. Several combinations are below 3:1; the footer brand text is effectively invisible.

The replacement targets WCAG 2.2 AA and requires keyboard, screen-reader, zoom, reduced-motion, and narrow-device verification rather than visual inspection alone.

## Design and asset findings

The legacy UI combines two overlapping themes: a dark navy/purple base and a later light override. Its rounded cards, pills, gradients, glows, floating stock images, and generic hero treatment read as a soft SaaS template rather than the approved clean industrial direction.

The binary assets total roughly 15 MiB. Problems include:

- Product imagery does not match the listing text.
- Full-size stock assets are delivered into small card slots.
- Both brand logos are opaque 1254px square images with embedded wordmarks.
- `hero-bg.jpg` duplicates `freephotocc-workspace-1280538.jpg` byte for byte.
- The unused campus hero depicts school-age students rather than a university setting.
- Asset licenses and provenance are undocumented.
- The Three.js viewer, GLB model, Amazon toolbar CSS, 3D styles, and several category/icon definitions are dead code.

The original logos and imagery were excluded from the working tree after the
audit. Recover them from Git history only if future brand or provenance work
requires them.

## Why a clean migration is required

Incrementally attaching Supabase to the current JavaScript would turn local-only defects into cross-user security and integrity defects. The replacement should preserve product requirements, not DOM-generation code.

The approved React/Vite architecture provides:

- One responsive route and component tree instead of copied HTML pages.
- Safe text rendering by default.
- Testable state, forms, dialogs, error boundaries, and responsive navigation.
- A typed data-access boundary for Supabase.
- Hashed static assets and a straightforward Vercel deployment.
- A clean separation between marketplace items and the Services top-level tab.

The legacy localStorage keys may be recognized only by an explicit, validated, opt-in migration tool. They must never be treated as trusted ownership or authorization evidence.

## Preservation notes

- The ANSI-colored merge-conflict artifact, Three.js viewer, GLB model,
  duplicated hero imagery, obsolete Python launcher, stale editor config, and
  unused CSS were removed from the working tree.
- The original prototype remains recoverable from Git history. Do not copy its
  unsafe rendering logic into the current app.
