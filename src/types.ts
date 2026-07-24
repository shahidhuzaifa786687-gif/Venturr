export type ListingType = "buy" | "rent" | "free" | "wanted";

export type ListingCategory =
  | "Electronics"
  | "Books & notes"
  | "Dorm & home"
  | "Fashion"
  | "Cycles & commute"
  | "Sports & hobbies";

export type Condition = "New" | "Like new" | "Good" | "Fair";

export type CampusZone = string;

export type MembershipStatus =
  | "pending"
  | "verified"
  | "rejected"
  | "suspended"
  | "expired";

export type VerificationMethod =
  | "college_email"
  | "college_id_review"
  | "manual_review";

export interface CampusSummary {
  id: string;
  slug: string;
  name: string;
  city: string | null;
}

export interface CampusMembership {
  id: string;
  campusId: string;
  status: MembershipStatus;
  verificationMethod: VerificationMethod | null;
  verifiedAt: string | null;
  expiresAt: string | null;
  campus: CampusSummary;
}

export interface UserProfile {
  userId: string;
  displayName: string;
  avatarPath: string | null;
  preferredCampusId: string | null;
  course: string;
  graduationYear: number | null;
  bio: string;
  onboardingCompletedAt: string | null;
}

export interface StudentSummary {
  id: string;
  name: string;
  initials: string;
  course: string;
  verified: boolean;
  joinedYear: number;
  campusName?: string;
  membershipStatus?: MembershipStatus;
}

export interface Listing {
  id: string;
  type: ListingType;
  category: ListingCategory;
  title: string;
  description: string;
  price: number;
  priceUnit?: "day" | "week" | "month" | undefined;
  condition: Condition;
  pickupZone: CampusZone;
  image: string;
  imageAlt: string;
  seller: StudentSummary;
  createdAt: string;
  negotiable: boolean;
  availableFrom?: string;
  isMine?: boolean;
}

export type ServiceCategory =
  | "Tutoring"
  | "Tech & debugging"
  | "Design & portfolio"
  | "Language practice"
  | "Events & media"
  | "Everyday help";

export interface ServiceOffer {
  id: string;
  category: ServiceCategory;
  title: string;
  description: string;
  rate: number;
  rateUnit: "hour" | "session" | "project";
  format: "Online" | "On campus" | "Both";
  nextAvailable: string;
  image: string;
  imageAlt: string;
  provider: StudentSummary;
  completedSessions: number;
  rating?: number;
  isMine?: boolean;
}

export interface ChatMessage {
  id: string;
  sender: "me" | "them";
  body: string;
  sentAt: string;
}

export interface Conversation {
  id: string;
  title: string;
  subtitle: string;
  participant: StudentSummary;
  contextType: "listing" | "service";
  contextId: string;
  updatedAt: string;
  unread: boolean;
  messages: ChatMessage[];
}

export interface ItemPostInput {
  title: string;
  description: string;
  type: ListingType;
  category: ListingCategory;
  condition: Condition;
  price: number;
  priceUnit?: "day" | "week" | "month" | undefined;
  pickupZone: CampusZone;
  negotiable: boolean;
  image?: string | undefined;
}

export interface ServicePostInput {
  title: string;
  description: string;
  category: ServiceCategory;
  rate: number;
  rateUnit: "hour" | "session" | "project";
  format: "Online" | "On campus" | "Both";
  nextAvailable: string;
  integrityConfirmed: boolean;
  image?: string | undefined;
}
