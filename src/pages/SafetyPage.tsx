import {
  ChatCircle,
  Eye,
  Flag,
  GraduationCap,
  HandPalm,
  MapPin,
  ShieldCheck,
} from "@phosphor-icons/react";

const safetyCards = [
  {
    icon: MapPin,
    title: "Meet where campus is busy",
    body: "Use the listed public pickup zones during active hours. Do not share room numbers or live location.",
  },
  {
    icon: Eye,
    title: "Inspect before you pay",
    body: "Check the item, serial details, and included accessories. Verify payments in your own payment app.",
  },
  {
    icon: ChatCircle,
    title: "Keep the conversation here",
    body: "In-app chat creates a useful record and avoids exposing your personal contact details.",
  },
  {
    icon: HandPalm,
    title: "Never share verification codes",
    body: "Venturr will never ask for an OTP, password, card PIN, or remote access to confirm a deal.",
  },
  {
    icon: Flag,
    title: "Report early",
    body: "Report suspicious listings, pressure tactics, prohibited items, harassment, or academic-integrity violations.",
  },
];

export function SafetyPage() {
  return (
    <main className="page page--safety">
      <section className="simple-hero">
        <p className="eyebrow">
          <ShieldCheck size={16} weight="fill" />
          Safety centre
        </p>
        <h1>Good exchanges need clear boundaries.</h1>
        <p>Practical rules for safer handoffs, honest services, and respectful campus trade.</p>
      </section>

      <section className="safety-grid" aria-label="Marketplace safety">
        {safetyCards.map(({ icon: Icon, title, body }) => (
          <article key={title}>
            <Icon size={25} aria-hidden="true" />
            <h2>{title}</h2>
            <p>{body}</p>
          </article>
        ))}
      </section>

      <section className="integrity-section" id="academic-integrity">
        <div>
          <p className="eyebrow">
            <GraduationCap size={16} />
            Academic services
          </p>
          <h2>Help someone learn—never replace their work.</h2>
          <p>
            Venturr services can include tutoring, study planning, feedback, explanation,
            debugging, proofreading guidance, and project collaboration where the course allows it.
          </p>
        </div>
        <div className="integrity-columns">
          <article>
            <h3>Allowed</h3>
            <ul>
              <li>Explain concepts and examples</li>
              <li>Review a student’s own draft</li>
              <li>Pair-debug code and teach a process</li>
              <li>Practice language or presentation skills</li>
              <li>Plan milestones and study routines</li>
            </ul>
          </article>
          <article>
            <h3>Not allowed</h3>
            <ul>
              <li>Complete or submit graded work</li>
              <li>Take a test or attend as another person</li>
              <li>Sell answer keys or leaked material</li>
              <li>Hide unauthorized collaboration</li>
              <li>Promise grades or bypass course rules</li>
            </ul>
          </article>
        </div>
      </section>
    </main>
  );
}
