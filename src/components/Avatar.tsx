import type { StudentSummary } from "../types";

export function Avatar({
  student,
  size = "medium",
}: {
  student: StudentSummary;
  size?: "small" | "medium" | "large";
}) {
  return (
    <span
      className={`avatar avatar--${size}`}
      aria-label={`${student.name}, ${student.verified ? "verified student" : "student"}`}
      title={student.name}
    >
      {student.initials}
    </span>
  );
}
