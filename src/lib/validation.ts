import { z } from "zod";

const listingTypes = ["buy", "rent", "free", "wanted"] as const;
const listingCategories = [
  "Electronics",
  "Books & notes",
  "Dorm & home",
  "Fashion",
  "Cycles & commute",
  "Sports & hobbies",
] as const;
const conditions = ["New", "Like new", "Good", "Fair"] as const;
const priceUnits = ["day", "week", "month"] as const;
const serviceCategories = [
  "Tutoring",
  "Tech & debugging",
  "Design & portfolio",
  "Language practice",
  "Events & media",
  "Everyday help",
] as const;
const serviceRateUnits = ["hour", "session", "project"] as const;
const formats = ["Online", "On campus", "Both"] as const;

const plainText = (min: number, max: number) =>
  z
    .string()
    .trim()
    .min(min)
    .max(max)
    .refine((value) => !/[<>]/.test(value), {
      message: "Angle brackets are not allowed.",
    });

export const itemPostSchema = z
  .object({
    title: plainText(4, 80),
    description: plainText(20, 800),
    type: z.enum(listingTypes),
    category: z.enum(listingCategories),
    condition: z.enum(conditions),
    price: z.coerce.number().int().min(0).max(1_000_000),
    priceUnit: z.enum(priceUnits).optional(),
    pickupZone: plainText(2, 80),
    negotiable: z.boolean(),
    image: z.string().url().optional(),
  })
  .superRefine((value, context) => {
    if (value.type === "rent" && !value.priceUnit) {
      context.addIssue({
        code: "custom",
        path: ["priceUnit"],
        message: "Choose a rental billing period.",
      });
    }
    if (value.type === "free" && value.price !== 0) {
      context.addIssue({
        code: "custom",
        path: ["price"],
        message: "Free listings must have a zero price.",
      });
    }
  });

export const servicePostSchema = z.object({
  title: plainText(6, 90),
  description: plainText(30, 1_000),
  category: z.enum(serviceCategories),
  rate: z.coerce.number().int().min(0).max(100_000),
  rateUnit: z.enum(serviceRateUnits),
  format: z.enum(formats),
  nextAvailable: plainText(4, 80),
  integrityConfirmed: z.literal(true, {
    error: "Confirm the academic-integrity boundary before posting.",
  }),
  image: z.string().url().optional(),
});

export const messageSchema = plainText(1, 1_000);

export const offerSchema = z.object({
  amount: z.coerce.number().int().min(0).max(1_000_000),
  note: plainText(1, 500),
});

export const imageFileSchema = z
  .instanceof(File)
  .refine(
    (file) => ["image/jpeg", "image/png", "image/webp"].includes(file.type),
    "Use a JPEG, PNG, or WebP image.",
  )
  .refine((file) => file.size <= 5 * 1024 * 1024, "Images must be 5 MB or smaller.");

const email = z
  .string()
  .trim()
  .email("Enter a valid campus email.")
  .max(254, "Email is too long.");

const password = z
  .string()
  .min(10, "Use at least 10 characters.")
  .max(128, "Password is too long.");

const currentYear = new Date().getFullYear();

const profileFields = {
  displayName: plainText(2, 60),
  course: plainText(2, 100),
  graduationYear: z.coerce
    .number()
    .int()
    .min(currentYear - 8, "Choose a valid graduation year.")
    .max(currentYear + 10, "Choose a valid graduation year."),
  bio: z
    .string()
    .trim()
    .max(320, "Keep your bio to 320 characters or fewer.")
    .refine((value) => !/[<>]/.test(value), {
      message: "Angle brackets are not allowed.",
    }),
};

export const signInSchema = z.object({
  email,
  password,
});

export const signUpSchema = z.object({
  displayName: plainText(2, 60),
  email,
  password,
  acceptedTerms: z.literal(true, {
    error: "Accept the terms and privacy notice to continue.",
  }),
});

export const profileSchema = z.object(profileFields);

export const onboardingSchema = z.object({
  ...profileFields,
  campusId: z.string().uuid("Choose a campus to continue."),
});
