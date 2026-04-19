# Wellness Insights Feature Implementation Plan

## Overview

Create a wellness insights Lightning Web Component that displays 3 personalized wellness insights based on the user's latest completed questionnaire responses. The insights are generated using a GenAI Flex Prompt Template that analyzes user responses categorized by mental health domains (Depression, Anxiety, Stress, etc.).

## Feature Requirements

### Functional Requirements

1. Display 3 actionable wellness insights to users
2. Insights should be personalized based on their questionnaire responses
3. Use AI to generate contextually relevant recommendations
4. Show insights with appropriate icons and formatting
5. Handle error scenarios gracefully with fallback mechanisms
6. Support responsive design for different screen sizes

### Technical Requirements

1. Use Salesforce GenAI Flex Prompt Templates for insight generation
2. Implement proper separation of concerns (Service layer, Controller, LWC)
3. Follow Salesforce security best practices (USER_MODE, with sharing)
4. Include comprehensive error handling and logging
5. Write unit tests for all Apex classes
6. Write Jest tests for the Lightning Web Component

## Architecture

### Component Layer (LWC)

- **wellnessInsights.js** - Main component logic
- **wellnessInsights.html** - Component template
- **wellnessInsights.css** - Component styling
- **wellnessInsights.test.js** - Jest unit tests

### Controller Layer (Apex)

- **WellnessInsightsController.cls** - @AuraEnabled methods for LWC
- **WellnessInsightsControllerTest.cls** - Unit tests

### Service Layer (Apex)

- **WellnessInsightsService.cls** - Business logic and GenAI integration
- **WellnessInsightsServiceTest.cls** - Unit tests

### AI Layer

- **Generate_Wellness_Insights.genAiPromptTemplate-meta.xml** - GenAI prompt template

### Configuration

- **CustomLabels.labels-meta.xml** - Externalized text for i18n support

## Implementation Details

### 1. GenAI Prompt Template (Generate_Wellness_Insights)

**Purpose**: Analyzes user responses and generates 3 actionable wellness insights

**Input Parameters**:

- `Response_Session_Id` - ID of the completed MM_Response_Session\_\_c record

**Prompt Design**:

```
You are a mental health expert AI analyzing a user's mental health assessment responses.

TASK:
Analyze the user's responses from their latest completed assessment session and generate exactly 3 actionable wellness insights.

INSIGHT GENERATION RULES:
- Generate ONE actionable insight per selected category
- Each insight must be:
  * Action-oriented (tell the user what to DO)
  * Specific and concrete (avoid vague advice)
  * Supportive and encouraging in tone
  * Based on the actual responses provided
  * EXACTLY 1 sentence only (maximum 20 words)
  * No compound sentences - keep it simple and direct
- Focus on practical steps the user can take immediately

SEVERITY ASSESSMENT:
For each insight, determine the severity level based on:
- Response patterns indicating distress level
- Score values in that category (higher scores = higher severity)
- Clinical urgency indicators in the responses
- Severity levels: "high", "medium", "low"
  * high: Immediate attention needed, significant distress indicators
  * medium: Notable concerns, moderate intervention suggested
  * low: Minor issues, general wellness improvement

OUTPUT FORMAT:
Return ONLY valid JSON (no markdown):
{
  "insights": [
    {
      "category": "Depression|Anxiety|Stress|Basic|General",
      "insight": "Action-oriented recommendation (1 sentence, max 20 words)",
      "icon": "utility:favorite|utility:warning|utility:help",
      "severity": "high|medium|low"
    }
  ],
  "fallbackScore": <total_score>,
  "fallbackSummary": "<summary_text>"
}
```

**Key Features**:

- Groups user responses by MM_Category\_\_c field
- Analyzes patterns across questions in each category
- Generates personalized, actionable recommendations (1 sentence, max 20 words)
- Assesses severity level for each insight (high, medium, low)
- Provides fallback score and summary for error scenarios
- Returns pure JSON output (no markdown code fences)

### 2. Service Layer (WellnessInsightsService.cls)

**Purpose**: Handles GenAI integration and business logic

**Key Methods**:

#### `getWellnessInsights(String responseSessionId)`

- Validates input parameters
- Constructs GenAI prompt template input
- Calls ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate()
- Strips markdown code fences from response
- Returns clean JSON string
- Handles errors with fallback mechanism
- Includes comprehensive logging

#### `stripMarkdownCodeFence(String responseText)`

- Removes ```json opening markers
- Removes ``` closing markers
- Trims whitespace
- Handles edge cases (blank input, partial markers)

#### `getFallbackInsights(String responseSessionId)`

- Queries MM_Response_Session\_\_c for score and summary
- Returns structured JSON with fallback flag
- Used when GenAI call fails

#### `getMockInsightsResponse()`

- Provides mock data for test execution
- Returns properly structured JSON response
- **Includes severity field** for each insight (high, medium, low)
- **Shortened insight text** (1 sentence format)

**Security**: `with sharing` for record-level security enforcement

### 3. Controller Layer (WellnessInsightsController.cls)

**Purpose**: Bridge between LWC and Service layer

**Key Method**:

#### `getLatestWellnessInsights()`

- Marked as `@AuraEnabled(cacheable=false)` for fresh data
- Queries latest completed MM_Response_Session\_\_c for current user
- Filters by `MM_Status__c = 'Completed'`
- Uses `ORDER BY CreatedDate DESC LIMIT 1`
- Calls WellnessInsightsService.getWellnessInsights()
- Returns JSON string to LWC
- Throws AuraHandledException on errors

**Security**: `with sharing` for SOQL query security

### 4. Lightning Web Component (wellnessInsights)

**Purpose**: User interface for displaying insights

**Key Features**:

#### JavaScript (wellnessInsights.js)

- Imports `getLatestWellnessInsights` from Apex controller
- Uses async/await pattern for data loading
- Parses JSON response using `JSON.parse()`
- **Maps insights with severity field** (defaults to 'medium' if missing)
- Handles loading, error, and success states
- Supports fallback display when AI insights unavailable
- Implements error handling with user-friendly messages

#### HTML Template (wellnessInsights.html)

- Card-based layout using `lightning-card`
- **Bold and larger header** (font-weight: 700, font-size: 1.5rem)
- **Component-scoped loading spinner** (no page-center positioning)
- Shows error message with `lightning-formatted-text`
- Iterates over insights using `template for:each`
- Displays insight cards with **severity-based color coding** via data attributes
- Shows fallback score and summary when applicable
- Responsive design with proper spacing

#### CSS (wellnessInsights.css)

- **Header styling**: Bold (font-weight: 700) and larger (1.5rem)
- **Component-relative positioning**: Loading spinner contained within component
- **Severity-based color coding**:
  - High severity: Red border (#c23934) and red icon
  - Medium severity: Orange border (#fe9339) and orange icon
  - Low severity: Green border (#04844b) and green icon
- Custom styling for insight cards with gradient backgrounds
- Icon styling and positioning
- Responsive layout adjustments
- Smooth hover effects with transform and shadow
- Consistent spacing and typography
- Staggered fade-in animations for cards

#### Jest Tests (wellnessInsights.test.js)

- Tests component initialization
- Verifies successful data loading
- Tests error handling scenarios
- Validates DOM element rendering
- Checks insight card display
- Verifies fallback functionality

### 5. Custom Labels

Created 5 custom labels for externalized text:

1. **WellnessInsights_Title** - "Your Wellness Insights"
2. **WellnessInsights_Loading** - "Loading your insights..."
3. **WellnessInsights_Error** - "Unable to load insights"
4. **WellnessInsights_NoInsights** - "No insights available"
5. **WellnessInsights_Fallback** - "Based on your score: {0} - {1}"

**Purpose**: Support internationalization and easy text updates

### 6. Testing Strategy

#### Apex Tests

- **WellnessInsightsServiceTest.cls**:
  - Tests GenAI integration with mock responses
  - Tests fallback mechanism
  - Tests error handling
  - Tests markdown stripping functionality
  - Achieves >75% code coverage

- **WellnessInsightsControllerTest.cls**:
  - Tests SOQL query logic
  - Tests integration with service layer
  - Tests error scenarios
  - Tests user context filtering
  - Achieves >75% code coverage

#### Jest Tests

- **wellnessInsights.test.js**:
  - Tests component rendering
  - Tests wire adapter functionality
  - Tests error state display
  - Tests insight card rendering
  - Validates DOM structure

## Data Model

### Objects Used

#### MM_Response_Session\_\_c

- **Fields**:
  - `MM_User__c` - Lookup to User
  - `MM_Status__c` - "In Progress" | "Completed"
  - `MM_Total_Score__c` - Calculated score
  - `MM_Summary__c` - AI-generated summary
  - `MM_Start_Time__c` - Session start timestamp
  - `MM_End_Time__c` - Session completion timestamp

#### MM_User_Response\_\_c

- **Fields**:
  - `MM_Response_Session__c` - Master-Detail to Response Session
  - `MM_Question__c` - Lookup to Question
  - `MM_Question_Text__c` - Formula field
  - `MM_Selected_Option__c` - Lookup to Question Option
  - `MM_Option_Text__c` - Formula field
  - `MM_Answer_Text__c` - Text response
  - `MM_Score__c` - Response score

#### MM_Question\_\_c

- **Fields**:
  - `MM_Category__c` - "Depression" | "Anxiety" | "Stress" | "Basic" | "General"
  - `MM_QuestionText__c` - Question text
  - `MM_Type__c` - "Single Choice" | "Multiple Choice" | "Text"
  - `MM_Order__c` - Display order

## Implementation Steps

### Phase 1: GenAI Prompt Template Setup

1. ✅ Create Generate_Wellness_Insights.genAiPromptTemplate-meta.xml
2. ✅ Define input parameters (Response_Session_Id)
3. ✅ Write prompt instructions for insight generation
4. ✅ Test prompt output format (JSON structure)
5. ✅ Remove unsupported responseFormat property
6. ✅ Fix version identifier format
7. ✅ Deploy to org

### Phase 2: Service Layer Implementation

1. ✅ Create WellnessInsightsService.cls
2. ✅ Implement getWellnessInsights() method
3. ✅ Add ConnectApi.EinsteinLLM integration
4. ✅ Implement getFallbackInsights() method
5. ✅ Add stripMarkdownCodeFence() helper method
6. ✅ Add comprehensive logging with Logger
7. ✅ Create WellnessInsightsServiceTest.cls
8. ✅ Write test cases for all methods
9. ✅ Deploy and verify

### Phase 3: Controller Layer Implementation

1. ✅ Create WellnessInsightsController.cls
2. ✅ Implement getLatestWellnessInsights() method
3. ✅ Add SOQL query for latest completed session
4. ✅ Create WellnessInsightsControllerTest.cls
5. ✅ Write test cases for controller methods
6. ✅ Deploy and verify

### Phase 4: Lightning Web Component

1. ✅ Create wellnessInsights component folder
2. ✅ Implement wellnessInsights.js with @wire decorator
3. ✅ Create wellnessInsights.html template
4. ✅ Add wellnessInsights.css styling
5. ✅ Create custom labels
6. ✅ Import custom labels in component
7. ✅ Add error handling and loading states
8. ✅ Deploy and test in org

### Phase 5: Testing

1. ✅ Write Jest tests for LWC
2. ✅ Verify Apex test coverage (>75%)
3. ✅ Test end-to-end functionality
4. ✅ Test error scenarios
5. ✅ Fix JSON parsing error (markdown stripping)
6. ✅ Verify in production-like environment

### Phase 6: Deployment

1. ✅ Deploy GenAI prompt template
2. ✅ Deploy Apex classes and tests
3. ✅ Deploy Lightning Web Component
4. ✅ Deploy custom labels
5. ✅ Verify all components in target org
6. ✅ Run smoke tests

## UI/UX Enhancements (v1.1.0)

### Enhancement 1: Shortened Insight Text

**Requirement**: Insights should be concise and within 1 sentence only

**Implementation**:

- Updated GenAI prompt template to specify "EXACTLY 1 sentence only (maximum 20 words)"
- Added instruction: "No compound sentences - keep it simple and direct"
- Updated mock responses to match the new format

### Enhancement 2: Severity-Based Color Coding

**Requirement**: Add color coding based on how critical the insight is

**Implementation**:

- Added `severity` field to GenAI output (values: "high", "medium", "low")
- GenAI prompt assesses severity based on:
  - Response patterns indicating distress level
  - Score values in that category
  - Clinical urgency indicators
- Color mapping:
  - **High Severity**: Red (#c23934) - Immediate attention needed
  - **Medium Severity**: Orange (#fe9339) - Notable concerns
  - **Low Severity**: Green (#04844b) - Minor issues, wellness improvement
- CSS applies colors to both border-left and icon based on `data-severity` attribute
- JavaScript ensures severity field exists (defaults to 'medium')

### Enhancement 3: Component-Scoped Spinner

**Requirement**: Spinner should be shown only within the wellness insights component, not page center

**Implementation**:

- Added `wellness-insights-container` class with `position: relative`
- Added `loading-container` class to loading state div
- Spinner now displays within component boundaries only
- Minimum height set to 200px for consistent loading UX

### Enhancement 4: Bold and Larger Header

**Requirement**: Make "Wellness Insights" header bolder and increase font size

**Implementation**:

- Changed header class from `slds-text-heading_medium` to `slds-text-heading_large`
- Added custom `header-title` CSS class
- Applied font-weight: 700 (bold) and font-size: 1.5rem
- Maintains icon integration in header

## Known Issues and Resolutions

### Issue 1: responseFormat Not Supported

**Problem**: API version 63.0 doesn't support responseFormat property in GenAI templates

**Resolution**: Removed responseFormat from both prompt templates and relied on prompt instructions for JSON formatting

### Issue 2: Invalid Version Identifier

**Problem**: Version identifier contained spaces and invalid characters

**Resolution**: Used base64-encoded string without spaces: `YjR4cWxsN2pkZmxqc2Rma2pzZGZqa3NkZmprc2Q=_1`

### Issue 3: JSON Parsing Error

**Problem**: GenAI model wrapped JSON output in markdown code fences (`json ... `)

**Resolution**: Added `stripMarkdownCodeFence()` method in service layer to clean response before returning to LWC

### Issue 4: Missing Return Statement

**Problem**: AgentUtilities.cls had a method without a return statement

**Resolution**: Added appropriate return statement to fix compilation error

## Security Considerations

1. **Record-Level Security**: All classes use `with sharing` keyword
2. **User Mode Queries**: SOQL queries use `AccessLevel.USER_MODE`
3. **Input Validation**: All methods validate input parameters
4. **Error Handling**: Sensitive information not exposed in error messages
5. **Logging**: Logger used for debugging without exposing user data
6. **Custom Labels**: No hardcoded text in components

## Performance Considerations

1. **Caching**: Controller method marked `cacheable=false` for fresh insights
2. **Query Optimization**: Single query for latest completed session
3. **Bulkification**: Not applicable (single-record processing)
4. **GenAI Timeout**: Handled with try-catch and fallback mechanism
5. **Loading State**: User sees spinner during GenAI processing

## Future Enhancements

1. **Caching**: Implement platform cache for GenAI responses
2. **Personalization**: Add user preferences for insight types
3. **History**: Show previous insights with timestamp
4. **Actions**: Allow users to mark insights as "helpful" or "not helpful"
5. **Recommendations**: Link to specific resources or exercises
6. **Notifications**: Send insights via email or push notifications
7. **Analytics**: Track which insights are most helpful
8. **A/B Testing**: Test different prompt variations

## Maintenance Notes

1. **Prompt Updates**: Modify GenAI template for better insight quality
2. **Icon Updates**: Add new SLDS icons as categories expand
3. **Label Updates**: Update custom labels for better UX
4. **Test Data**: Maintain realistic test data for accurate testing
5. **Logging**: Review logs regularly for error patterns
6. **API Version**: Update API version when new features available

## Documentation References

- [Salesforce GenAI Documentation](https://developer.salesforce.com/docs/platform/einstein/guide/einstein-prompt-templates.html)
- [Lightning Web Components Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
- [ConnectApi.EinsteinLLM](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_ConnectAPI_EinsteinLLM.htm)
- [Jest Testing for LWC](https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.testing)

## Deployment Checklist

- [x] GenAI Prompt Template deployed
- [x] Apex Service class deployed
- [x] Apex Controller class deployed
- [x] Test classes deployed with >75% coverage
- [x] Lightning Web Component deployed
- [x] Custom labels deployed
- [x] Component added to Experience Cloud page
- [x] End-to-end testing completed
- [x] JSON parsing error fixed
- [x] Production deployment verified

## Success Metrics

1. **User Engagement**: Track how many users view insights
2. **Insight Quality**: Monitor user feedback on helpfulness
3. **Error Rate**: Ensure <5% error rate in production
4. **Performance**: GenAI response time <3 seconds
5. **Coverage**: Maintain >75% Apex test coverage

## Version History

### Version 1.1.0 (April 19, 2026)

- ✅ Shortened insight text to 1 sentence (max 20 words)
- ✅ Added severity-based color coding (high/medium/low)
- ✅ Fixed spinner positioning to component scope
- ✅ Enhanced header styling (bold, larger font)

### Version 1.0.0 (April 19, 2026)

- ✅ Initial release with GenAI-powered insights
- ✅ Complete LWC implementation with Apex backend
- ✅ Comprehensive error handling and fallback mechanism
- ✅ JSON parsing fix for markdown code fences

---

**Last Updated**: April 19, 2026  
**Status**: ✅ Completed and Deployed  
**Version**: 1.1.0
