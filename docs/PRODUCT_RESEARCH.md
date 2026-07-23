# Venturr Product Research

**Research date:** 23 July 2026  
**Product:** Venturr student campus marketplace  
**Purpose:** Document the evidence, assumptions, and product decisions behind the rebuild  
**Status:** Product direction for implementation; not legal, financial, or regulatory advice

## Executive conclusion

Venturr should not become a general ecommerce store with a student-themed skin. Its strongest product is a verified, campus-local exchange where students can sell, rent, give away, or request useful items from nearby peers, then make an offer, chat, inspect the item, and complete a safe in-person handoff.

The core value is the combination of:

1. **Relevance:** inventory that matches student life, course cycles, move-in, move-out, and short-term needs.
2. **Proximity:** exchanges measured in a walk across campus rather than shipping distance.
3. **Affordability:** used goods, short-term rentals, giveaways, and side-income.
4. **Trust:** verified campus membership, private communication, visible reputation, safe handoffs, and enforceable community rules.
5. **Liquidity:** enough useful supply and active buyers in one campus at the same time.

The rebuild should therefore replace the current cart-and-checkout metaphor with a local-deal flow:

> Discover → Save or make an offer → Chat → Agree on a public campus handoff → Inspect → Pay or exchange → Confirm → Review

Rentals are a meaningful differentiator, but they require a complete lifecycle rather than a price suffix. Student services are also valuable, but they require scheduling, completion, integrity, payment, and dispute rules that differ substantially from goods. For that reason, **Marketplace and Services must be separate product surfaces and domain models**.

## Evidence and interpretation policy

This document distinguishes evidence types so that marketing claims are not presented as independent market facts.

| Label | Evidence type | How it is used |
|---|---|---|
| **[P] Primary/public evidence** | Government statistics, regulator data, or a disclosed large-sample survey | Supports market conditions, risk, and broad behavior |
| **[C] Commissioned research** | Research commissioned or published by an interested company, with methodology disclosed | Directional evidence; sample and sponsor limitations are noted |
| **[V] Vendor self-report** | A product's own usage number, feature page, policy, or launch claim | Competitive signal only; not independently validated |
| **[I] Product inference** | A recommendation derived from the evidence and Venturr's intended position | A hypothesis to validate through product analytics and campus research |
| **[R] Repository observation** | Direct inspection of the existing Venturr repository | Describes the starting product, not the wider market |

No competitor's landing-page statistic should be copied into Venturr marketing without independent verification. Likewise, proposed KPI targets should be set from pilot baselines instead of invented industry benchmarks.

## What must remain from the current idea

The current repository establishes a clear underlying idea even though its implementation is a prototype.

### Core to preserve

- A student-first marketplace.
- Campus-local discovery and pickup.
- Students earning money from unused items or useful skills.
- Affordable access to textbooks, electronics, fashion, dorm items, and other campus essentials.
- Fast photo listings, search, filters, and direct buyer-seller contact.
- A friendly, accessible web experience that works well on mobile.

### What the existing prototype gets wrong

The current implementation is browser-only HTML, CSS, and JavaScript. Listings, user details, photos, cart state, and messages are stored in `localStorage`. The “message” action saves a message in the sender's own browser and does not deliver it to a seller. Login has no password or real identity verification. Checkout clears a demo cart without creating a transaction. [R]

The legacy repository used conflicting working names; **Venturr** is now the
confirmed brand. The old product copy also claimed verified sellers, hundreds
of sellers, and a 4.9 rating although no backend evidence existed. [R]

The cart, item quantities, and multi-seller checkout model a retail store. Campus resale inventory is generally unique, negotiated, collected from different people, and handed over offline. Current campus products instead converge on save, message, offer, inspect, exchange, and review flows. [V][I]

The prototype also lacks condition, transaction type, offers, favorites, campus tenancy, listing state, conversation delivery, notifications, reporting, blocking, verified reviews, expiry, and moderation. [R]

Most importantly, the current `escapeHTML()` function does not escape `<`, `>`, or quotation marks, while user-controlled listing and profile values are interpolated into `innerHTML`. This creates a stored cross-site scripting path and confirms that the prototype should not be carried into production as application logic. [R]

## Market evidence

### Campus exchange has a real, recurring supply loop

Fizz co-founder Teddy Solomon told TechCrunch that the marketplace had generated more than 50,000 listings and 150,000 direct messages across 240 college campuses in 2024. Fizz separately attributed its marketplace behavior to verified communities, walkable pickup, and student-relevant inventory such as dorm furniture, clothes, bikes, and textbooks. These are vendor-provided figures, not audited results, but they are the clearest published campus-marketplace usage signal found in this review. [V]

The supply loop is structurally tied to campus life:

- Graduating and moving students need to dispose of usable goods quickly.
- Incoming students need the same goods at low cost.
- Course changes create repeated textbook and calculator demand.
- Events create short-duration demand for clothes, equipment, and services.
- Dorm constraints make ownership temporary and storage costly.

Current campus products repeatedly position “move-out instead of throw-out” and “furnish without buying new” as their central job to be done. [V] The repetition does not prove each startup has traction, but it does show a consistent market thesis.

### Student spending is large but value-sensitive

The National Retail Federation's 2025 U.S. back-to-college survey forecast $88.8 billion of total spending and an average of $1,325.85 per college student/family. The largest categories were electronics, dorm or apartment furnishings, clothing, food, and personal care. NRF also reported families using used or refurbished goods to manage costs. The survey covered 7,581 consumers and was fielded 1–7 July 2025. [P]

Deloitte's 2026 global Gen Z and Millennial Survey found cost of living was the top concern for the fifth consecutive year. Fifty-five percent of Gen Z respondents said their finances had delayed a major life decision. The survey covered 22,595 respondents across 44 countries and was fielded from 24 November 2025 to 15 January 2026. It is not a campus marketplace survey, but it supports affordability and side-income as durable needs rather than promotional angles. [P]

**Product implication:** lead with “get what campus life needs for less” and “turn unused items into money,” not generic startup or ecommerce language. [I]

### Secondhand shopping is social and discovery-led

ThredUp and GlobalData's 2025 resale study reported that 39% of younger-generation shoppers had made a secondhand apparel purchase through a social-commerce platform in the prior twelve months. It also reported that 48% of consumers said personalization, better search, and discovery made secondhand shopping as easy as shopping new. The research included 3,034 U.S. adults and was commissioned by a resale company, so it is directional rather than neutral. [C]

Meta's March 2026 Marketplace update emphasized one-click listing drafts from photos, suggested local prices, availability replies, listing history, and seller ratings. This is a current product signal from a very large general marketplace: reducing seller effort and making reputation visible remain active competitive priorities. [V]

**Product implication:** Venturr should be photo-first, searchable, saveable, conversational, and reputation-aware. AI assistance may reduce listing friction later, but it should not displace basic data quality or user control. [I]

### Trust is part of the product, not a badge

Federal Trade Commission data for 2025 showed $2.1 billion in reported losses from scams that began on social media. Nearly 30% of people who reported losing money to a scam said it started on social media, and shopping scams were the most reported social-media scam type. [P]

Student verification reduces the anonymous-stranger problem but does not prove honesty, item ownership, condition, or payment. Fizz's January 2026 privacy policy explicitly states that no verification system is foolproof and uses several affiliation methods: school email, school Google/Microsoft OAuth, or enrollment evidence. [V]

**Product implication:** “campus verified” must mean only “campus affiliation verified.” Trust should also include transaction-backed reputation, reports and blocks, private contact details, safe meetup guidance, and observable enforcement. [I]

## Student behavior and UX consequences

### Mobile and camera first

Current campus products consistently describe a listing flow as “snap, price, post” in 30–60 seconds. [V] A responsive web app or PWA is an appropriate initial surface, but its interaction model should feel native on a phone:

- Camera-first image selection.
- One-column mobile feed with fast-loading thumbnails.
- Thumb-reachable primary actions.
- Bottom navigation for Discover, Search, Post, Inbox, and Profile.
- Draft preservation on connection loss or accidental navigation.
- Minimal data transfer and optimized images.

### Chat before commitment

Campus items are one-off, condition-sensitive, and negotiable. Buyers commonly need to ask whether an item is still available, confirm defects, negotiate price, and coordinate a handoff. Fizz's reported messaging volume and the repeated competitor pattern support chat as the transactional center. [V]

The primary action should therefore be **Make offer** or **Message**, not **Add to cart**. Useful quick prompts include:

- “Is this still available?”
- “Would you accept ₹___?”
- “Can you share a photo of the damage?”
- “Can we meet at the library at 4:00?”

### Campus rhythm matters

The interface should surface seasonal collections and prompts:

- Move-in essentials.
- Graduating soon / move-out sale.
- New semester textbooks.
- Exam-season calculators and equipment.
- Formal and event wear.
- Monsoon or winter needs where locally relevant.

Listings should expire or request reconfirmation so the feed does not become a graveyard of unavailable items. [I]

### Location should be useful without being invasive

Campus proximity is valuable, but exact room or home location creates avoidable safety risk. Cards should use a coarse, configured zone such as Main Library, North Gate, Hostel District, or Engineering Block. Exact handoff details should be shared only in a conversation after both parties agree. [I]

DormShare specifically advises students to keep room numbers private and meet in a public, well-lit campus area. OfferUp's current safe-meetup guidance prioritizes public locations, lighting, surveillance, accessibility, and in-app scheduling. [V]

### Student search is more specific than retail search

Useful student search dimensions include:

- Course code, department, and semester.
- Textbook edition and ISBN.
- Campus and pickup zone.
- Item condition.
- Sale, rent, free, or wanted.
- Rental price unit and availability.
- Compatible device/model.
- Hostel/dorm fit and appliance restrictions where configured.

Loot's current positioning makes course-code search a first-class feature, which is a good student-specific pattern even though the product was still launching in 2026. [V]

### Avoid notification overload

Deloitte reported that 58% of Gen Z respondents experienced digital fatigue from constant alerts, tool switching, and multiple platforms. [P] Venturr should default to high-value transactional notifications—new message, offer, accepted request, upcoming return—and make promotional alerts opt-in.

## Competitive landscape

The table below describes current positioning. Except where noted, it is not evidence of adoption.

| Product | Current signal | Relevant pattern | Evidence |
|---|---|---|---|
| **Fizz Marketplace** | Official 2024 self-report of 50,000+ listings and 150,000 DMs across 240 campuses | Verified campus communities, hyperlocal inventory, chat-led deals | [V], strongest published usage signal |
| **Facebook Marketplace** | Large general local marketplace; 2026 AI listing and seller-summary updates | Fast listing, local price guidance, availability replies, visible seller history | [V], large incumbent product signal |
| **5C Exchange** | Student-only open beta for the Claremont Colleges; terms updated June 2025 | In-app chat, public handoff, verified ratings, donation, reporting, sustainability | [V] |
| **DormShare** | 2026 beta | For Sale, Free, Wanted, dorm sales, direct messages, room-number privacy | [V] |
| **Loot** | McMaster launch advertised for fall 2026 | Sell, rent, trade, course-code search, annual reverification, ratings, free/Pro tiers | [V], pre-launch positioning |
| **Rumie** | Vendor claims institution deployments and network scale | University SSO, campus branding, rentals, protection, institution sales | [V], self-reported |
| **CampusXchange** | India-facing “launching soon” marketplace | Seniors-to-freshers loop, safe zones, institutional email or college-ID verification, zero commission | [V], pre-launch positioning |
| **Campus+** | Services marketplace advertised for Q3 2026 launch | Scheduling, protected payment claim, two-sided ratings, service fees, academic-integrity rule | [V], pre-launch positioning |

### Competitive conclusion

The basic feature set is easy to copy. Numerous products already promise verified students, chat, and safe campus pickup. Venturr cannot differentiate merely through a modern listing grid.

Its defensible operating advantages should be:

- Dense launch execution at each campus.
- A complete and understandable rental lifecycle.
- Trust and moderation that visibly work.
- Better course-, hostel-, and semester-aware discovery.
- Fast supply activation during move-out and move-in.
- Localized India-ready identity and payment assumptions where applicable.
- Honest product claims backed by live data.

## Product architecture decision: Marketplace and Services are separate

The existing prototype places tutoring beside books and electronics as one category. This is superficially simple but creates confusing and unsafe workflows.

### Marketplace

Marketplace covers a physical or transferable item:

- For sale.
- For rent.
- Free.
- Wanted.
- Barter may be added later.

Its core entities are listing, item condition, offer, conversation, handoff, payment acknowledgement, rental period, and review.

### Services

Services covers time-bound work performed by a person:

- Tutoring or coaching.
- Moving help.
- Photography or videography.
- Design or technical help.
- Repair or setup help.
- Event assistance.

Its core entities are service profile, availability, scope, quote, booking, cancellation, work completion, payout, dispute, and service review.

### Why they must not share one flow

| Marketplace item | Student service |
|---|---|
| One-off inventory | Repeatable availability |
| Condition and ownership matter | Scope and provider capability matter |
| Pickup and return | Appointment and completion |
| Item price or rental rate | Hourly, fixed, or quoted fee |
| Buyer/seller review | Client/provider review |
| Damage/late-return dispute | Quality/no-show/scope dispute |
| Item prohibited-goods policy | Work eligibility, safety, licensing, and integrity policy |

Profiles may share identity and campus membership, but reputation should show separate Marketplace and Services histories. A good textbook seller is not automatically a proven tutor, and a good photographer is not automatically a reliable rental borrower. [I]

## Marketplace product decisions

### MVP transaction types

1. **For sale**
2. **For rent**
3. **Free**
4. **Wanted**

Wanted posts improve demand visibility and help cold-start supply. DormShare currently treats Wanted as a first-class feed state, demonstrating the pattern. [V]

### Initial categories

- Electronics and accessories.
- Textbooks and course materials.
- Dorm, hostel, furniture, and appliances.
- Cycles and commute.
- Fashion, uniforms, and formal wear.
- Sports, hobbies, and equipment.
- Other approved campus essentials.

Food, cosmetics, medicines, tickets, accommodation, and regulated goods should not be casually added. Each introduces hygiene, counterfeit, scalping, licensing, legal, or fraud concerns requiring a separate policy review. [I]

### Listing requirements

- Transaction type.
- Title and structured category.
- Multiple processed photos.
- Price and negotiability.
- Rental price unit where applicable.
- Condition: new, like new, good, fair, for parts.
- Plain-language defect disclosure.
- Age or purchase period where useful.
- Campus and approximate pickup zone.
- Course code, edition, or compatibility fields where relevant.
- Availability.
- Expiry date.
- Ownership declaration and community-rule acknowledgement.

### Listing lifecycle

`draft → active → reserved → completed/sold/rented → archived`

Additional moderation states:

`pending_review`, `hidden`, `removed`, and `appealed`

Rental listings also need `checked_out`, `return_due`, `overdue`, `return_review`, and `disputed`.

### Discovery

- Campus-scoped feed by default.
- Search with category, condition, type, price, and zone filters.
- Course-code and textbook metadata search.
- Newest, closest-zone, price, and relevance sorts.
- Saved items.
- Saved searches and optional alerts.
- Recently viewed items.
- Seasonal collections driven by real inventory.

Recommendation systems should not be required for MVP. Search quality, category coverage, and inventory freshness will matter more during campus cold start. [I]

## Rental-specific product requirements

Rentals should be a first-class mode, not a sale listing whose description says “₹100/day.”

### Commercial terms

- Hour, day, week, or semester rate.
- Minimum and maximum duration.
- Availability calendar.
- Security deposit or protection terms, if legally and operationally supported.
- Cancellation, extension, late-return, loss, and damage rules shown before request.
- Included accessories and replacement values.

### Request and approval

- Requested start and return times.
- Borrower message or intended-use note.
- Owner approval, decline, or counterproposal.
- Clear total price calculation.
- Conflict prevention against overlapping accepted rentals.

### Handoff

- Suggested public campus location.
- Pickup appointment.
- Check-out condition checklist and timestamped photos.
- Included-accessory confirmation.
- Matching one-time handoff code.
- Borrower acknowledgement.

### Active rental

- Due-date and return reminders.
- Extension request and owner approval.
- In-app record of changed terms.
- Simple safety/support route.

### Return

- Matching return code.
- Return-condition photos.
- Owner acceptance or time-limited issue report.
- Deposit/protection release only through the chosen payment partner and documented workflow.
- Transaction-backed ratings for both owner and borrower.

### Dispute readiness

- Preserve listing version, accepted terms, messages, handoff records, condition evidence, and timestamps.
- Restrict evidence access to the involved users and authorized moderators.
- Define response times and possible outcomes before launch.
- Never imply Venturr guarantees reimbursement without a funded and contractually valid protection program.

No feature should be called “escrow,” “insured,” “guaranteed,” or “protected” merely because a database records a payment state. Those terms should be used only when an appropriate regulated provider and contract actually support them. [I]

## Services and academic-integrity boundaries

Services should launch after the core Marketplace is stable.

### Generally supportable service examples

- Concept tutoring and exam preparation that does not involve active exam assistance.
- Language practice.
- Moving and lifting help.
- Photography, videography, and event assistance.
- Graphic design and portfolio feedback.
- Device setup, troubleshooting, and basic repair.
- Sports coaching where appropriate.

### Prohibited or review-required services

- Writing or completing assignments, essays, projects, lab work, or examinations for another student.
- Impersonation, credential sharing, attendance fraud, or circumventing proctoring.
- Sale of leaked exams, answer keys, restricted course content, or stolen intellectual property.
- Services that promise grades or admissions outcomes.
- Unsafe transport, medical, legal, financial, security, or licensed trade work without the required authorization.
- Sexual services, controlled substances, weapons, harassment, or exploitation.

Campus+ publicly states that essay writing and assignment completion are not permitted, which is a useful minimum competitive boundary, though Venturr must create its own precise rules and enforcement process. [V]

### Services need dedicated controls

- Provider eligibility and any required KYC through a payment provider.
- Scope, deliverables, rate, duration, and cancellation terms.
- Availability and booking.
- No-show and completion confirmation.
- Separate client/provider reviews.
- Integrity-report reason and evidence handling.
- Category-specific safety rules.
- Tax and payout notices appropriate to the launch jurisdiction.

## Trust, safety, and moderation

### Verification model

Recommended layered verification:

1. Email ownership or institution OAuth.
2. Institution-domain mapping to a campus.
3. Periodic reverification.
4. Privacy-minimized manual fallback where institutional email is unavailable.
5. Additional payment-provider identity checks only when payouts require them.

The badge should read **Campus verified** with an explanation such as “Institution affiliation verified on [month/year]. Venturr does not guarantee identity, conduct, or item quality.”

For India, do not hardcode `.edu`. Support institution-specific domains, `.ac.in`, `.edu.in`, and approved domain aliases. College-ID or enrollment evidence should be used only as a controlled fallback, stored privately, accessed by a minimal reviewer set, and deleted on a defined schedule. [I]

### Reputation

- Reviews only after a confirmed exchange, return, or service completion.
- Show rating count beside the average.
- Separate seller, buyer/borrower, and service histories.
- Show completed exchange count and account age.
- Consider response rate and cancellation/no-show history without exposing sensitive detail.
- Do not permit arbitrary unverified testimonials.
- Detect reciprocal-review and account-ring abuse.

### Communication safety

- Keep email and phone private by default.
- Allow report and block from the conversation.
- Warn on suspicious payment links, verification-code requests, gift cards, urgency, overpayment, and pressure to leave the platform.
- Rate-limit new-account messaging.
- Limit unsolicited links and repeated copy-paste outreach.
- Give users a downloadable or visible transaction record without exposing other private conversations.

### Handoff safety

- Curate campus-approved or clearly public meetup zones.
- Encourage daylight, populated, well-lit, accessible locations.
- Let a user share a handoff plan with a trusted contact.
- Remind the buyer to inspect before paying.
- Never reveal a dorm room or home address publicly.
- Provide an urgent-safety route distinct from ordinary customer support.

### Prohibited-items policy

Before launch, publish a clear policy covering at least:

- Weapons and dangerous goods.
- Alcohol, tobacco, vaping products, and controlled substances.
- Medicines and medical devices.
- Stolen goods and counterfeit products.
- Recalled products.
- Personal data, credentials, accounts, and access cards.
- Adult content or services.
- Animals.
- Academic cheating materials.
- Tickets where institution rules or anti-scalping requirements apply.
- Food and hygiene-sensitive goods.

### Moderation operations

- Report a listing, profile, message, review, rental, or service.
- Structured reasons plus optional evidence.
- Triage by severity and time sensitivity.
- Moderator audit trail.
- Progressive warnings, restrictions, suspensions, and bans.
- Appeals separated from the original decision where feasible.
- Campus-specific context without giving student moderators unrestricted access to identity, private messages, or sensitive evidence.
- Published response expectations and emergency limitations.

Fizz describes a combination of central trust-and-safety staff, trained campus moderators, automated screening, reporting, blocking, and progressive sanctions. This is a vendor description, not an instruction to copy its governance model, but it shows that verification without ongoing moderation is not considered sufficient by a scaled campus platform. [V]

## Security and privacy implications

This document is product research, not the full security design, but several requirements follow directly from the marketplace model.

### Supabase authorization

- Enable Row Level Security and explicit grants on every exposed table and view.
- Derive campus access from a verified membership row, never from an arbitrary client-supplied campus ID.
- Restrict listing mutation to its owner or authorized moderation action.
- Restrict conversations, offers, and messages to participants.
- Restrict rental evidence and disputes to involved users and authorized staff.
- Allow a review only for an eligible completed transaction.
- Keep reports and enforcement records private.
- Audit privileged actions.
- Test cross-user and cross-campus denial paths.

Supabase documentation states that grants determine which roles can reach an object while RLS determines which rows those roles can reach, and recommends both controls for exposed objects. [V]

Elevated Supabase secret/service-role keys bypass RLS and must never be exposed to a browser. [V]

### User-uploaded media

- Validate file signatures rather than trusting extensions or browser MIME labels.
- Cap dimensions, count, and file size.
- Decode and re-encode supported images.
- Strip EXIF and location metadata.
- Generate safe thumbnails.
- Use owner-scoped Storage policies.
- Keep identity/evidence uploads in private buckets.
- Use short-lived access where private review is needed.
- Scan or reject unsupported document formats.

### Application controls

- Never interpolate untrusted HTML.
- Use framework text rendering and narrowly reviewed sanitization only when rich text is required.
- Apply a restrictive Content Security Policy and standard security headers.
- Protect state-changing requests against cross-site request forgery where applicable.
- Rate-limit authentication, verification, listing creation, offers, messages, and reports.
- Add bot challenges based on risk.
- Avoid account-enumeration responses.
- Keep secrets server-side.
- Log security-relevant events without logging messages, identity documents, payment credentials, or tokens unnecessarily.

### Data minimization

Collect only what the product needs. Public profiles should not reveal institutional email, phone number, exact residence, legal identity document, payment identifier, or date of birth.

Define retention for:

- Failed verification evidence.
- Deleted accounts and listings.
- Messages.
- Dispute evidence.
- Moderation logs.
- Security logs.
- Backups.

Deletion must account for legitimate fraud, dispute, and legal-retention needs without silently keeping all data forever.

## India and localization

The repository currently hardcodes USD examples. If India is the initial market, Venturr should use INR while keeping currency, tax copy, campus structure, and payment options configurable.

### Payments

NPCI recorded 23.2 billion UPI transactions in May 2026, making UPI a baseline payment behavior in India. [P] For an offline MVP, buyers and sellers may agree on UPI or cash after inspection.

Safety requirements:

- Do not treat a screenshot as payment confirmation.
- Tell recipients to verify funds in their actual payment app or bank.
- Never ask for a UPI PIN or one-time password.
- Do not store bank, card, UPI PIN, or authentication credentials.
- Use a suitable regulated payment provider for platform-collected payments and payouts.
- Do not promise reversibility, escrow, or protection without the provider and operating process to support it.

### Campus identity

Indian institutional domains are inconsistent. Model `institutions`, `approved_domains`, `campuses`, and `memberships` rather than parsing `.edu`. Support aliases and manual review. Reverify at a suitable interval and handle alumni or staff eligibility explicitly.

### Local campus vocabulary

Campus configuration should support:

- Hostel, PG, residence hall, dorm, block, gate, canteen, and department terminology.
- Multiple campuses under one institution.
- English plus future local-language copy.
- Local date, time, phone, and currency formatting.
- Low-bandwidth image behavior and installable PWA use.

### Digital Personal Data Protection framework

India notified the Digital Personal Data Protection Rules, 2025 on 14 November 2025 with phased implementation. Government summaries emphasize clear standalone consent notices, purpose limitation, data minimization, security safeguards, storage limitation, accountability, and breach communication. [P]

For an India launch, obtain qualified legal review and design for:

- Clear purpose-specific notices.
- Valid consent where required.
- Access, correction, deletion, and grievance workflows.
- Reasonable security safeguards.
- Data-breach detection and communication.
- Processor/vendor contracts.
- Cross-border processing implications.
- Child/minor handling.

Until a dedicated minors-compliance design is reviewed, an 18+ eligibility rule is the lower-risk product assumption for Marketplace transactions and Services. This is a product risk recommendation, not a legal conclusion. [I]

### India commerce behavior

Google and Deloitte's April 2026 India commerce outlook forecasts the country's 220 million digitally native Gen Z consumers contributing nearly 45% of ecommerce spend by 2030. It also emphasizes demand for digital discovery combined with tactile in-person assurance. This is sponsored forecasting, not campus-specific evidence, but online discovery plus physical inspection is especially aligned with Venturr's handoff model. [C]

## Monetization

### Principle

Liquidity comes before extraction. A new campus marketplace needs enough useful listings and responsive users before fees can create value.

### Recommended sequence

1. Keep verification, browsing, ordinary listings, saves, chat, offers, and offline exchange free.
2. Establish healthy campus supply and repeat behavior.
3. Test clearly labeled optional promotion.
4. Add fees only where Venturr provides measurable transaction or protection value.
5. Explore institution funding after demonstrating waste reduction, affordability, or engagement.

### Possible revenue streams

- Optional listing bump or featured placement.
- Pro storefront and inventory tools for high-volume student sellers/renters.
- Fee on genuinely protected in-app payments or rental protection.
- Institution-sponsored move-out and reuse programs.
- Institution-branded deployment and SSO.
- Relevant, clearly labeled local sponsorships.
- Later service-booking fees.

### Avoid at launch

- Mandatory listing fees.
- Buyer subscriptions required for ordinary access.
- Hidden ranking payments.
- Unlabeled native advertising.
- A transaction fee on a handoff Venturr does not process or protect.
- Selling personal data.
- Sustainability claims based on invented carbon values.

Campus+ currently advertises an 8% Services fee, a 6% Pro fee, and a subscription; Loot advertises free listings with Pro limits. These are competitor pricing experiments, not validated benchmarks for Venturr. [V]

## Launch strategy

### Launch campus by campus

Marketplace network effects are local. A large waitlist distributed across many campuses can still produce empty feeds. Launch should be judged at the campus and category level.

### Seed supply before inviting broad demand

Potential supply partners:

- Graduating students.
- Hostel and residence groups.
- Student clubs and societies.
- Sustainability offices.
- International student groups.
- Department and course groups.
- Campus bookstores or approved local shops.
- Move-out donation programs.

### Use existing channels as distribution

Students already use WhatsApp, Instagram, Discord, Telegram, GroupMe, club lists, and physical noticeboards depending on campus. Venturr should generate clean share links and QR codes so those channels route users to a structured, current listing rather than asking a campus to change behavior all at once. [I]

### Campus ambassador responsibilities

Ambassadors can support:

- Supply seeding.
- On-campus demos.
- Feedback collection.
- Verified meetup-zone mapping.
- Local vocabulary and category tuning.
- Community education.

They should not receive unrestricted identity, private-message, payment, or enforcement access.

### Launch gates

Do not invent a universal “500 users” threshold. Open a campus when there is:

- Identifiable seed supply in core categories.
- A working verification path.
- Configured public meetup zones.
- Moderation and urgent-safety coverage.
- Tested cross-campus access isolation.
- A feedback/support owner.
- Evidence that prospective buyers are looking for the seeded inventory.

Exact numeric gates should be set from the first pilot and revised from observed conversion. [I]

## KPIs

### North-star candidate

**Confirmed successful exchanges per weekly activated campus user**

This measures delivered value while preserving the campus denominator. Confirmations should use a handoff/completion mechanism rather than a self-reported button alone.

### Liquidity

- Active listings by campus, type, and category.
- Wanted posts with at least one relevant response.
- Percentage of listings receiving a first qualified message.
- Median time to first qualified message.
- Median time from listing to reserve and completion.
- Supply-demand coverage by category and price band.
- Stale and expired listing rate.

### Activation and retention

- Verification completion.
- First browse, save, message, offer, and listing.
- Time to first value.
- Weekly active verified users by campus.
- Repeat buyer, seller, owner, and borrower rate.
- Cohort retention by campus and semester phase.

### Transaction quality

- Offer acceptance.
- Reserved-to-completed conversion.
- Cancellation and no-show rate.
- Listing accuracy/condition complaint rate.
- Rating participation and distribution.

### Rentals

- Request-to-approval conversion.
- Utilization by item and category.
- On-time return rate.
- Extension rate.
- Late, damage, and dispute rate.
- Repeat borrower and owner rate.

### Trust and safety

- Reports per 1,000 active users and per 1,000 completed exchanges.
- Block rate.
- Time to acknowledge and resolve reports by severity.
- Repeat-offender rate.
- Fraud-loss incidents and amount.
- Suspicious-message intervention rate.
- Cross-campus access-control test failures: target must always be zero.

### Services, when launched

- Quote-to-booking conversion.
- Booking completion.
- No-show/cancellation rate.
- Repeat client/provider rate.
- Integrity reports.
- Disputes and refunds.

### Monetization, when launched

- Paid-feature conversion.
- Revenue per active campus.
- Payment/protection attachment.
- Promotion lift without degrading organic discovery.
- Contribution margin after support, payment, fraud, and dispute costs.

Metrics must be segmented by campus. Global averages can hide an empty or unsafe campus behind a healthy one.

## Phased roadmap

### Phase 0 — Foundation and pilot preparation

- Standardize the confirmed Venturr name, positioning, and brand language.
- Establish Supabase schema, migrations, RLS, Storage policies, and test fixtures.
- Implement institution/campus/domain configuration.
- Define eligibility, privacy, community, prohibited-items, reporting, and retention policies.
- Configure safe meetup zones.
- Build moderation and support access.
- Recruit one pilot campus and seed suppliers.

**Exit condition:** security boundaries, verification, moderation, and pilot operations are testable before public listings.

### Phase 1 — Campus Marketplace MVP

- Campus verification and profile.
- For Sale, Free, and Wanted.
- Photo listings with condition and zones.
- Search, filters, favorites, and share links.
- Make offer and real-time conversation.
- Reserve, complete, archive, and verified reviews.
- Reports, blocks, moderation queue, and audit trail.
- Transactional notifications.
- Responsive PWA.

**Exit condition:** pilot users can complete safe, traceable exchanges and the team can measure liquidity and incidents.

### Phase 2 — Liquidity and trust

- Saved searches and alerts.
- Course-code/ISBN discovery.
- Listing expiry and availability prompts.
- Better reputation and response indicators.
- Handoff confirmation code.
- Campus collections and seasonal activation.
- Anti-spam and risk rules based on pilot behavior.
- Ambassador tooling with least privilege.

**Exit condition:** repeat use and completion improve without unacceptable stale inventory, spam, or report load.

### Phase 3 — Rentals

- Rental terms and price units.
- Availability and conflict prevention.
- Request/approval/counterproposal.
- Condition evidence and handoff/return codes.
- Reminders, extensions, late states, and disputes.
- Separate borrower/owner reputation.
- Payment/protection integration only if contractually ready.

**Exit condition:** on-time returns and manageable dispute rates demonstrate that the operational model works.

### Phase 4 — Services

- Separate Services navigation and schema.
- Provider profiles and category eligibility.
- Scope, quote, availability, booking, and cancellation.
- Completion and two-sided service reviews.
- Integrity and category safety reporting.
- Provider payout/KYC through an appropriate partner.

**Exit condition:** Services can be operated safely without weakening Marketplace trust or confusing reputation.

### Phase 5 — Sustainable monetization and expansion

- Optional boosts and Pro tooling.
- Institution-sponsored programs and SSO.
- Protected payments where viable.
- Campus expansion playbook.
- Carefully evaluated cross-campus discovery.
- AI listing assistance and price guidance using adequate local data.

**Exit condition:** monetization improves unit economics without materially reducing listings, completion, trust, or fairness.

## Research limitations

- Broad Gen Z research is not identical to college-student marketplace research.
- U.S. back-to-college and FTC data may not generalize fully to India.
- India commerce forecasts cover wider ecommerce, not student resale.
- ThredUp research is commissioned by a resale company.
- Fizz usage numbers and all competitor product claims are self-reported.
- Several campus competitors reviewed were beta, pre-launch, or waitlist products as of 23 July 2026.
- Landing pages show product positioning, not retention, transaction quality, safety outcomes, or business viability.
- No direct interviews or quantitative survey of Venturr's intended campuses were available.

Recommended follow-up research:

1. Interview incoming students, final-year students, hostel residents, and student sellers at the first target campus.
2. Observe how listings and negotiations currently happen in campus WhatsApp/Instagram groups.
3. Test the proposed offer, handoff, and rental-return flows with clickable prototypes.
4. Map campus email/domain and identity edge cases.
5. Validate prohibited-item and academic-integrity rules with the institution.
6. Establish pilot baselines before setting numeric targets.

## Dated bibliography

### Primary and public evidence

1. **National Retail Federation.** “Back-to-School Season Begins Early for Majority of Shoppers.” Published **15 July 2025**. Survey fielded 1–7 July 2025, n=7,581. [https://nrf.com/media-center/press-releases/back-to-school-season-begins-early-for-majority-of-shoppers](https://nrf.com/media-center/press-releases/back-to-school-season-begins-early-for-majority-of-shoppers)
2. **Deloitte Global.** “Deloitte Global's 15th annual Gen Z and Millennial Survey.” Published **13 May 2026**. Survey fielded 24 November 2025–15 January 2026, n=22,595 across 44 countries. [https://www.deloitte.com/global/en/about/press-room/deloitte-2026-gen-z-and-millennial-survey.html](https://www.deloitte.com/global/en/about/press-room/deloitte-2026-gen-z-and-millennial-survey.html)
3. **U.S. Federal Trade Commission.** “New FTC Data Show People Have Lost Billions to Social Media Scams.” Published **27 April 2026**, reporting 2025 Consumer Sentinel data. [https://www.ftc.gov/news-events/news/press-releases/2026/04/new-ftc-data-show-people-have-lost-billions-social-media-scams](https://www.ftc.gov/news-events/news/press-releases/2026/04/new-ftc-data-show-people-have-lost-billions-social-media-scams)
4. **National Payments Corporation of India.** “UPI Product Statistics.” **May 2026 data**; page accessed 23 July 2026. [https://www.npci.org.in/product/upi/product-statistics](https://www.npci.org.in/product/upi/product-statistics)
5. **Government of India, Press Information Bureau / Ministry of Electronics and Information Technology.** “Government notifies DPDP Rules to empower citizens and protect privacy.” Published **14 November 2025**. [https://www.pib.gov.in/PressReleasePage.aspx?PRID=2190014&lang=2&reg=48](https://www.pib.gov.in/PressReleasePage.aspx?PRID=2190014&lang=2&reg=48)
6. **Ministry of Electronics and Information Technology.** “Digital Personal Data Protection Rules 2025.” Rules published **14 November 2025**; corrigendum published 16 December 2025. [https://www.meity.gov.in/documents/act-and-policies/digital-personal-data-protection-rules-2025-gDOxUjMtQWa](https://www.meity.gov.in/documents/act-and-policies/digital-personal-data-protection-rules-2025-gDOxUjMtQWa)

### Commissioned research

7. **ThredUp / GlobalData.** “ThredUp's 13th Resale Report.” Published **19 March 2025**. Consumer survey n=3,034 U.S. adults; commissioned by ThredUp. [https://ir.thredup.com/news-releases/news-release-details/thredups-13th-resale-report-shows-online-resale-saw-accelerated/](https://ir.thredup.com/news-releases/news-release-details/thredups-13th-resale-report-shows-online-resale-saw-accelerated/)
8. **Google / Deloitte.** “$250B by 2030: The four forces shaping the future of India's e-commerce.” Published **April 2026**; underlying report dated 7 April 2026. Sponsored industry forecast, not campus-specific. [https://business.google.com/in/think/future-of-marketing/e-commerce-retail-future-india/](https://business.google.com/in/think/future-of-marketing/e-commerce-retail-future-india/)

### Independent reporting of vendor claims

9. **TechCrunch.** Amanda Silberling, “Fizz, the anonymous Gen Z social app, adds a marketplace for college students.” Published **3 July 2024**. Usage figures in the article were supplied by Fizz co-founder Teddy Solomon and remain vendor claims. [https://techcrunch.com/2024/07/03/fizz-the-anonymous-gen-z-social-app-adds-a-marketplace-for-college-students/](https://techcrunch.com/2024/07/03/fizz-the-anonymous-gen-z-social-app-adds-a-marketplace-for-college-students/)

### Vendor reports, policies, and product pages

10. **Fizz.** “Privacy Policy.” Updated **15 January 2026**. [https://fizz.social/legal/privacy](https://fizz.social/legal/privacy)
11. **Fizz.** “Safety” and community-moderation materials. Undated living pages, accessed **23 July 2026**. Vendor description of moderation operations. [https://fizz.social/Safety](https://fizz.social/Safety)
12. **Meta.** “Facebook Marketplace's New Meta AI Tools Make Selling Faster and Easier.” Published **March 2026**. [https://about.fb.com/news/2026/03/facebook-marketplace-new-meta-ai-tools-make-selling-faster-and-easier/](https://about.fb.com/news/2026/03/facebook-marketplace-new-meta-ai-tools-make-selling-faster-and-easier/)
13. **OfferUp.** “About Community MeetUp Spots.” Updated **16 May 2025**. [https://help.offerup.com/hc/en-us/articles/360032335691-About-Community-MeetUp-Spots](https://help.offerup.com/hc/en-us/articles/360032335691-About-Community-MeetUp-Spots)
14. **5C Exchange.** Product page, accessed **23 July 2026**; Terms last updated June 2025. [https://5cexchange.com/](https://5cexchange.com/)
15. **DormShare.** Product and safety page, accessed **23 July 2026**. Site marked 2026 beta. [https://www.usedormshare.com/](https://www.usedormshare.com/)
16. **Loot.** Product page, accessed **23 July 2026**. Page advertised a McMaster fall 2026 launch. [https://lootapp.ca/](https://lootapp.ca/)
17. **Rumie.** Product page, accessed **23 July 2026**. Usage and institution claims are vendor-reported. [https://www.rumieapp.com/](https://www.rumieapp.com/)
18. **CampusXchange.** India product/waitlist page, accessed **23 July 2026**. Pre-launch positioning. [https://www.campusxchange.in/](https://www.campusxchange.in/)
19. **Campus+.** Services product/waitlist page, accessed **23 July 2026**. Page advertised a Q3 2026 launch. [https://joincampusplus.app/](https://joincampusplus.app/)
20. **Supabase.** “Securing your API.” Undated living documentation, accessed **23 July 2026**. [https://supabase.com/docs/guides/api/securing-your-api](https://supabase.com/docs/guides/api/securing-your-api)
21. **Supabase.** “Understanding API keys.” Undated living documentation, accessed **23 July 2026**. [https://supabase.com/docs/guides/getting-started/api-keys](https://supabase.com/docs/guides/getting-started/api-keys)
22. **Supabase.** “Storage Access Control.” Undated living documentation, accessed **23 July 2026**. [https://supabase.com/docs/guides/storage/security/access-control](https://supabase.com/docs/guides/storage/security/access-control)

### Internal evidence

23. **Venturr repository.** Existing `README.md`, `index.html`, pages, `app.js`, and `styles.css`, inspected **23 July 2026**. Repository observations are limited to the starting prototype and do not constitute market evidence.
