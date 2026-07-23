import {
  itemPostSchema,
  messageSchema,
  servicePostSchema,
  signInSchema,
  signUpSchema,
} from "./validation";

describe("input validation", () => {
  it("rejects markup in user-authored text", () => {
    expect(messageSchema.safeParse("<img src=x onerror=alert(1)>").success).toBe(false);
  });

  it("requires a billing period for rentals", () => {
    const result = itemPostSchema.safeParse({
      title: "Graphing calculator",
      description: "Clean calculator with a new battery and protective case.",
      type: "rent",
      category: "Electronics",
      condition: "Good",
      price: 100,
      pickupZone: "Campus commons",
      negotiable: true,
    });

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues.some((issue) => issue.path[0] === "priceUnit")).toBe(true);
    }
  });

  it("requires service providers to accept the integrity boundary", () => {
    const result = servicePostSchema.safeParse({
      title: "Calculus concept coaching",
      description: "I help students understand concepts and practice their own solutions.",
      category: "Tutoring",
      rate: 300,
      rateUnit: "hour",
      format: "On campus",
      nextAvailable: "Friday at 5 PM",
      integrityConfirmed: false,
    });

    expect(result.success).toBe(false);
  });

  it("requires strong account-creation inputs and terms acceptance", () => {
    const result = signUpSchema.safeParse({
      displayName: "A",
      email: "not-an-email",
      password: "short",
      acceptedTerms: false,
    });

    expect(result.success).toBe(false);
  });

  it("accepts a valid sign-in boundary", () => {
    expect(
      signInSchema.safeParse({
        email: "student@campus.test",
        password: "a-long-test-password",
      }).success,
    ).toBe(true);
  });
});
