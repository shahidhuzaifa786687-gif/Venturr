import type {
  CampusZone,
  ListingCategory,
  ServiceCategory,
} from "../types";

export const listingCategories: ListingCategory[] = [
  "Electronics",
  "Books & notes",
  "Dorm & home",
  "Fashion",
  "Cycles & commute",
  "Sports & hobbies",
];

export const serviceCategories: ServiceCategory[] = [
  "Tutoring",
  "Tech & debugging",
  "Design & portfolio",
  "Language practice",
  "Events & media",
  "Everyday help",
];

/**
 * Pickup zones are campus-owned database records. Keeping this empty prevents
 * the browser bundle from implying that fictional locations are real.
 */
export const campusZones: CampusZone[] = [];
