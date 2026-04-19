import { LightningElement, track } from "lwc";
import getLatestWellnessInsights from "@salesforce/apex/WellnessInsightsController.getLatestWellnessInsights";
import wellnessInsights from "@salesforce/label/c.WellnessInsights";
import noDataMessage from "@salesforce/label/c.WellnessInsights_NoData";
import errorMessage from "@salesforce/label/c.WellnessInsights_Error";
import loadingMessage from "@salesforce/label/c.WellnessInsights_Loading";
import fallbackTitle from "@salesforce/label/c.WellnessInsights_Fallback";

export default class WellnessInsights extends LightningElement {
  @track insights = [];
  @track isLoading = true;
  @track error = null;
  @track noData = false;
  @track usedFallback = false;
  @track fallbackScore = null;
  @track fallbackSummary = null;

  label = {
    insights: wellnessInsights,
    noData: noDataMessage,
    error: errorMessage,
    loading: loadingMessage,
    fallback: fallbackTitle
  };

  connectedCallback() {
    this.loadWellnessInsights();
  }

  /**
   * Load wellness insights from Apex
   */
  async loadWellnessInsights() {
    try {
      this.isLoading = true;
      this.error = null;
      this.noData = false;

      const result = await getLatestWellnessInsights();

      if (!result) {
        // No completed sessions found
        this.noData = true;
        this.isLoading = false;
        return;
      }

      // Parse the JSON response
      const data = JSON.parse(result);

      // Check if fallback was used
      if (data.usedFallback) {
        this.usedFallback = true;
        this.fallbackScore = data.fallbackScore;
        this.fallbackSummary = data.fallbackSummary;
        this.insights = [];
      } else {
        // Ensure insights have severity field (default to medium if missing)
        this.insights = (data.insights || []).map((insight) => ({
          ...insight,
          severity: insight.severity || "medium"
        }));
        this.fallbackScore = data.fallbackScore;
        this.fallbackSummary = data.fallbackSummary;
        this.usedFallback = false;
      }

      this.isLoading = false;
    } catch (err) {
      console.error("Error loading wellness insights:", err);
      this.error = err.body?.message || err.message || this.label.error;
      this.isLoading = false;
    }
  }

  /**
   * Getters for template
   */
  get hasInsights() {
    return this.insights && this.insights.length > 0;
  }

  get showFallback() {
    return (
      this.usedFallback &&
      (this.fallbackScore !== null || this.fallbackSummary !== null)
    );
  }

  get showError() {
    return this.error !== null;
  }

  get showNoData() {
    return this.noData && !this.isLoading && !this.error;
  }

  get showContent() {
    return !this.isLoading && !this.error && !this.noData;
  }
}
