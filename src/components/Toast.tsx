import { CheckCircle, X } from "@phosphor-icons/react";
import { useEffect } from "react";
import { useApp } from "../context/AppContext";
import { VisuallyHidden } from "./VisuallyHidden";

export function Toast() {
  const { toast, dismissToast } = useApp();

  useEffect(() => {
    if (!toast) return undefined;
    const timer = window.setTimeout(dismissToast, 4200);
    return () => window.clearTimeout(timer);
  }, [dismissToast, toast]);

  if (!toast) return null;

  return (
    <div className="toast" role="status" aria-live="polite">
      <CheckCircle size={20} weight="fill" aria-hidden="true" />
      <span>{toast.message}</span>
      <button className="icon-button icon-button--quiet" onClick={dismissToast} type="button">
        <VisuallyHidden>Dismiss notification</VisuallyHidden>
        <X size={18} aria-hidden="true" />
      </button>
    </div>
  );
}
