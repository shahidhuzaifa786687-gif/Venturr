import { X } from "@phosphor-icons/react";
import { useEffect, useRef, type ReactNode } from "react";
import { VisuallyHidden } from "./VisuallyHidden";

interface ModalFrameProps {
  children: ReactNode;
  labelledBy: string;
  onClose: () => void;
  size?: "standard" | "large";
}

export function ModalFrame({
  children,
  labelledBy,
  onClose,
  size = "standard",
}: ModalFrameProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return undefined;
    dialog.showModal();
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = previousOverflow;
      if (dialog.open) dialog.close();
    };
  }, []);

  return (
    <dialog
      ref={dialogRef}
      className={`modal modal--${size}`}
      aria-labelledby={labelledBy}
      onCancel={(event) => {
        event.preventDefault();
        onClose();
      }}
      onClick={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
    >
      <div className="modal-surface">
        <button className="modal-close" type="button" onClick={onClose}>
          <VisuallyHidden>Close dialog</VisuallyHidden>
          <X size={21} aria-hidden="true" />
        </button>
        {children}
      </div>
    </dialog>
  );
}
