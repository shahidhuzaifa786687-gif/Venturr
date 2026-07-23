export function LegalPage({ type }: { type: "privacy" | "terms" }) {
  const privacy = type === "privacy";
  return (
    <main className="page page--legal">
      <article>
        <p className="eyebrow">Venturr policy preview</p>
        <h1>{privacy ? "Privacy principles" : "Community terms"}</h1>
        <p className="legal-lede">
          {privacy
            ? "A production launch needs a jurisdiction-reviewed policy. These are the product commitments the implementation is designed around."
            : "A production launch needs counsel-reviewed terms. These are the plain-language rules the product currently enforces."}
        </p>
        {privacy ? (
          <>
            <h2>Collect less</h2>
            <p>
              Public profiles contain only display identity, campus affiliation, trust signals,
              and user-chosen content. Email and verification evidence are not public listing fields.
            </p>
            <h2>Keep access scoped</h2>
            <p>
              Marketplace data is campus-scoped. Conversations are visible only to participants.
              Reports, blocks, verification records, and moderation evidence are private.
            </p>
            <h2>Give students control</h2>
            <p>
              Production should support export, correction, account deletion, listing expiry,
              and documented retention for messages, reports, and verification evidence.
            </p>
          </>
        ) : (
          <>
            <h2>Trade honestly</h2>
            <p>
              Describe real condition, defects, price, availability, and rental terms. Do not list
              prohibited, stolen, unsafe, or counterfeit items.
            </p>
            <h2>Respect academic integrity</h2>
            <p>
              Services may coach, explain, review, or collaborate within course rules. They may not
              impersonate, complete assessments, or submit work for another student.
            </p>
            <h2>Use safety tools</h2>
            <p>
              Venturr may restrict accounts, remove content, preserve audit evidence, and cooperate
              with campus safety or lawful requests where appropriate.
            </p>
          </>
        )}
      </article>
    </main>
  );
}
