import {
  ChatCircle,
  Info,
  PaperPlaneTilt,
  SealCheck,
  ShieldCheck,
} from "@phosphor-icons/react";
import { useEffect, useMemo, useState, type FormEvent } from "react";
import { Avatar } from "../components/Avatar";
import { useApp } from "../context/AppContext";
import { formatChatTime } from "../lib/format";
import { messageSchema } from "../lib/validation";

export function InboxPage() {
  const { conversations, sendMessage, markConversationRead } = useApp();
  const [selectedId, setSelectedId] = useState(conversations[0]?.id ?? "");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  const sortedConversations = useMemo(
    () =>
      [...conversations].sort(
        (a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime(),
      ),
    [conversations],
  );
  const selected =
    sortedConversations.find((conversation) => conversation.id === selectedId) ??
    sortedConversations[0];

  useEffect(() => {
    if (selected) markConversationRead(selected.id);
  }, [markConversationRead, selected]);

  function submitMessage(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!selected) return;
    const parsed = messageSchema.safeParse(message);
    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? "Add a message.");
      return;
    }
    sendMessage(selected.id, parsed.data);
    setMessage("");
    setError("");
  }

  return (
    <main className="page page--inbox">
      <section className="simple-hero simple-hero--compact">
        <p className="eyebrow">
          <ChatCircle size={16} weight="fill" />
          In-app communication
        </p>
        <h1>Inbox</h1>
        <p>Keep offers, service requests, and meetup plans in one protected thread.</p>
      </section>

      <div className="inbox-layout">
        <aside className="conversation-list" aria-label="Conversations">
          <header>
            <h2>Messages</h2>
            <span>{conversations.filter((conversation) => conversation.unread).length} unread</span>
          </header>
          {sortedConversations.map((conversation) => (
            <button
              className={`${selected?.id === conversation.id ? "is-active" : ""}${
                conversation.unread ? " is-unread" : ""
              }`}
              key={conversation.id}
              onClick={() => setSelectedId(conversation.id)}
              type="button"
            >
              <Avatar student={conversation.participant} size="medium" />
              <span>
                <strong>{conversation.title}</strong>
                <small>{conversation.participant.name} · {conversation.subtitle}</small>
                <em>
                  {conversation.messages.at(-1)?.body ?? "Start the conversation"}
                </em>
              </span>
              <time dateTime={conversation.updatedAt}>{formatChatTime(conversation.updatedAt)}</time>
            </button>
          ))}
        </aside>

        {selected ? (
          <section className="chat-panel" aria-labelledby="chat-title">
            <header className="chat-panel__header">
              <Avatar student={selected.participant} size="medium" />
              <div>
                <h2 id="chat-title">{selected.title}</h2>
                <p>
                  {selected.participant.name}
                  <SealCheck size={15} weight="fill" aria-label="Verified student" />
                  <span aria-hidden="true">·</span>
                  {selected.subtitle}
                </p>
              </div>
              <button className="icon-button" type="button" aria-label="Conversation details">
                <Info size={20} />
              </button>
            </header>

            <div className="chat-safety-note">
              <ShieldCheck size={18} />
              <span>Never share one-time codes. Verify payment in your own payment app.</span>
            </div>

            <div className="messages" aria-live="polite">
              {selected.messages.map((item) => (
                <div className={`message message--${item.sender}`} key={item.id}>
                  <p>{item.body}</p>
                  <time dateTime={item.sentAt}>{formatChatTime(item.sentAt)}</time>
                </div>
              ))}
            </div>

            <form className="message-composer" onSubmit={submitMessage}>
              <label className="sr-only" htmlFor="message-input">Write a message</label>
              <textarea
                id="message-input"
                value={message}
                onChange={(event) => setMessage(event.target.value)}
                rows={1}
                maxLength={1000}
                placeholder="Write a message…"
              />
              <button className="button button--primary" type="submit">
                <PaperPlaneTilt size={18} weight="fill" />
                <span>Send</span>
              </button>
              {error ? <p className="field-error" role="alert">{error}</p> : null}
            </form>
          </section>
        ) : (
          <section className="chat-panel chat-panel--empty">
            <ChatCircle size={32} />
            <h2>No conversations yet</h2>
            <p>Make an offer or request a service to start one.</p>
          </section>
        )}
      </div>
    </main>
  );
}
