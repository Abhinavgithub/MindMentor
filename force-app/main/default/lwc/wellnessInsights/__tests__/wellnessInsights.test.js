import { createElement } from "lwc";
import WellnessInsights from "c/wellnessInsights";
import getLatestWellnessInsights from "@salesforce/apex/WellnessInsightsController.getLatestWellnessInsights";

// Mock Apex method
jest.mock(
  "@salesforce/apex/WellnessInsightsController.getLatestWellnessInsights",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

describe("c-wellness-insights", () => {
  afterEach(() => {
    // Clear DOM after each test
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    // Clear all mocks
    jest.clearAllMocks();
  });

  it("displays loading state initially", () => {
    const element = createElement("c-wellness-insights", {
      is: WellnessInsights
    });

    // Mock the Apex call to not resolve immediately
    getLatestWellnessInsights.mockReturnValue(new Promise(() => {}));

    document.body.appendChild(element);

    // Query for loading spinner
    const spinner = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner).not.toBeNull();
  });

  it("displays wellness insights when data is loaded", async () => {
    const mockData = {
      insights: [
        {
          category: "Depression",
          insight: "Consider establishing a daily routine.",
          icon: "utility:favorite"
        },
        {
          category: "Anxiety",
          insight: "Practice deep breathing exercises.",
          icon: "utility:warning"
        },
        {
          category: "Stress",
          insight: "Schedule time for activities you enjoy.",
          icon: "utility:help"
        }
      ],
      fallbackScore: 75,
      fallbackSummary: "Test summary"
    };

    getLatestWellnessInsights.mockResolvedValue(JSON.stringify(mockData));

    const element = createElement("c-wellness-insights", {
      is: WellnessInsights
    });
    document.body.appendChild(element);

    // Wait for async operations
    await Promise.resolve();
    await Promise.resolve();

    // Query for insight cards
    const insightCards = element.shadowRoot.querySelectorAll(".insight-card");
    expect(insightCards.length).toBe(3);

    // Verify first insight content
    const firstCard = insightCards[0];
    const categoryHeading = firstCard.querySelector(".slds-text-heading_small");
    expect(categoryHeading.textContent).toBe("Depression");

    const insightText = firstCard.querySelector(".insight-text");
    expect(insightText.textContent).toBe(
      "Consider establishing a daily routine."
    );
  });

  it("displays no data message when no completed sessions exist", async () => {
    getLatestWellnessInsights.mockResolvedValue(null);

    const element = createElement("c-wellness-insights", {
      is: WellnessInsights
    });
    document.body.appendChild(element);

    // Wait for async operations
    await Promise.resolve();
    await Promise.resolve();

    // Query for no data message
    const noDataText = element.shadowRoot.querySelector(
      ".slds-text-body_regular"
    );
    expect(noDataText).not.toBeNull();
    expect(noDataText.textContent).toContain(
      "Please complete your mental health assessment"
    );
  });

  it("displays error message when Apex call fails", async () => {
    const mockError = {
      body: { message: "Test error message" },
      ok: false,
      status: 400,
      statusText: "Bad Request"
    };

    getLatestWellnessInsights.mockRejectedValue(mockError);

    const element = createElement("c-wellness-insights", {
      is: WellnessInsights
    });
    document.body.appendChild(element);

    // Wait for async operations
    await Promise.resolve();
    await Promise.resolve();

    // Query for error message
    const errorIcon = element.shadowRoot.querySelector(
      'lightning-icon[icon-name="utility:error"]'
    );
    expect(errorIcon).not.toBeNull();

    const errorText = element.shadowRoot.querySelector(
      ".slds-text-body_regular"
    );
    expect(errorText.textContent).toBe("Test error message");
  });

  it("displays fallback when AI prompt fails", async () => {
    const mockFallbackData = {
      insights: [],
      fallbackScore: 85,
      fallbackSummary: "Fallback summary text",
      usedFallback: true
    };

    getLatestWellnessInsights.mockResolvedValue(
      JSON.stringify(mockFallbackData)
    );

    const element = createElement("c-wellness-insights", {
      is: WellnessInsights
    });
    document.body.appendChild(element);

    // Wait for async operations
    await Promise.resolve();
    await Promise.resolve();

    // Query for fallback box
    const fallbackBox = element.shadowRoot.querySelector(".slds-theme_warning");
    expect(fallbackBox).not.toBeNull();

    // Verify fallback score
    const scoreText = fallbackBox.textContent;
    expect(scoreText).toContain("85");
    expect(scoreText).toContain("Fallback summary text");
  });

  it("renders correct icons for each category", async () => {
    const mockData = {
      insights: [
        {
          category: "Depression",
          insight: "Test insight",
          icon: "utility:favorite"
        },
        {
          category: "Anxiety",
          insight: "Test insight",
          icon: "utility:warning"
        },
        {
          category: "Stress",
          insight: "Test insight",
          icon: "utility:help"
        }
      ],
      fallbackScore: 75,
      fallbackSummary: "Test summary"
    };

    getLatestWellnessInsights.mockResolvedValue(JSON.stringify(mockData));

    const element = createElement("c-wellness-insights", {
      is: WellnessInsights
    });
    document.body.appendChild(element);

    // Wait for async operations
    await Promise.resolve();
    await Promise.resolve();

    // Query for icons
    const icons = element.shadowRoot.querySelectorAll(
      ".insight-icon lightning-icon"
    );

    // Note: In Jest, we check the parent element that has the class
    const iconElements = element.shadowRoot.querySelectorAll(
      "lightning-icon.insight-icon"
    );
    expect(iconElements.length).toBe(3);
  });

  it("handles empty insights array gracefully", async () => {
    const mockData = {
      insights: [],
      fallbackScore: 50,
      fallbackSummary: "Test summary",
      usedFallback: false
    };

    getLatestWellnessInsights.mockResolvedValue(JSON.stringify(mockData));

    const element = createElement("c-wellness-insights", {
      is: WellnessInsights
    });
    document.body.appendChild(element);

    // Wait for async operations
    await Promise.resolve();
    await Promise.resolve();

    // Should not display any insight cards
    const insightCards = element.shadowRoot.querySelectorAll(".insight-card");
    expect(insightCards.length).toBe(0);
  });

  it("displays header with correct title", () => {
    const element = createElement("c-wellness-insights", {
      is: WellnessInsights
    });

    getLatestWellnessInsights.mockReturnValue(new Promise(() => {}));

    document.body.appendChild(element);

    // Query for header
    const header = element.shadowRoot.querySelector(
      ".slds-text-heading_medium"
    );
    expect(header.textContent).toContain("Wellness Insights");
  });
});
