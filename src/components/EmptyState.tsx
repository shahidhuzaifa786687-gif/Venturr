import { MagnifyingGlass, Plus } from "@phosphor-icons/react";

export function EmptyState({
  title,
  body,
  actionLabel,
  onAction,
}: {
  title: string;
  body: string;
  actionLabel?: string;
  onAction?: () => void;
}) {
  return (
    <div className="empty-state">
      <span aria-hidden="true">
        <MagnifyingGlass size={28} />
      </span>
      <h2>{title}</h2>
      <p>{body}</p>
      {actionLabel && onAction ? (
        <button className="button button--primary" onClick={onAction} type="button">
          <Plus size={18} />
          {actionLabel}
        </button>
      ) : null}
    </div>
  );
}
