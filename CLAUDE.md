# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Deploy to Org
```bash
# Deploy all metadata
sf project deploy start --source-dir force-app

# Deploy a single file or folder
sf project deploy start --source-dir force-app/main/default/classes/MindMentor/QuestionnaireController.cls

# Run Apex tests after deploy
sf project deploy start --source-dir force-app --test-level RunLocalTests
```

### Run Apex Tests
```bash
# Run all tests
sf apex run test --test-level RunLocalTests --output-dir .

# Run a single test class
sf apex run test --class-names CalculateTotalScoreAndSummaryTest --output-dir .

# Run a specific test method
sf apex run test --tests CalculateTotalScoreAndSummaryTest.testReturnsCannedJsonInTestContext --output-dir .
```

### Org Management
```bash
# Check current org
sf org display

# Open org in browser
sf org open
```

## Architecture

MindMentor is a Salesforce Experience Cloud (LWR) mental wellness application. Users complete questionnaires, and AI-powered analysis generates wellness insights.

### Data Model
Custom objects follow the `MM_` prefix convention:
- **`MM_Questionnaire__c`** — container for a set of questions (has `MM_Is_Active__c` flag)
- **`MM_Question__c`** — individual questions with type (`Multiple Choice`, `Yes/No`, `Multiple Select`, `Text`), order, weight, and crisis flags
- **`MM_Question_Option__c`** — answer choices for a question
- **`MM_Response_Session__c`** — a user's assessment attempt; tracks `MM_Status__c` (`In Progress` / `Completed`), score, and summary; linked to Contact via `MM_User__c`
- **`MM_User_Response__c`** — single-select or text responses (one per question per session)
- **`MM_User_Response_Options__c`** — multi-select responses (one per selected option per question per session)
- **`Scoring_Rule__c`** — score range bands linked to a Questionnaire, with summary text and action recommendations

User identity: Community users are identified by `User.ContactId`. All queries resolve `userId → contactId` before accessing session data.

### Apex Layer
All Apex classes use `with sharing` and `AccessLevel.USER_MODE` / `Database.queryWithBinds()` for all DML/SOQL to enforce CRUD, FLS, and sharing rules.

- **`QuestionnaireController`** — `@AuraEnabled` methods for the questionnaire LWC: `getSession`, `getQuestions`, `createUserResponse`, `getSessionResponses`, `completeSession`. Uses `System.Label.MM_Max_Questions` (Custom Label) to cap question count.
- **`ResponseSessionService`** — called by the trigger handler on session `afterUpdate`; when status transitions to `Completed`, invokes `CalculateTotalScoreAndSummary` and writes score/summary back.
- **`CalculateTotalScoreAndSummary`** — calls the `Calculate_User_Score_and_Summary` Einstein Prompt Template via `ConnectApi.EinsteinLLM`; returns `{"Score": <int>, "Summary": "<text>"}`.
- **`WellnessInsightsController`** — `@AuraEnabled` method `getLatestWellnessInsights`; finds the user's latest completed session and delegates to `WellnessInsightsService`.
- **`WellnessInsightsService`** — calls the `Generate_Wellness_Insights` Einstein Prompt Template; falls back to stored score/summary if the AI call fails; strips markdown code fences from the LLM response before returning JSON.
- **`AgentUtilities`** — utility used by Agentforce agents; `getResponseSession(userId)` returns the user's session history as JSON for agent context.
- **`TriggerHandler`** — base virtual class for the handler pattern; subclasses override `beforeInsert`, `afterUpdate`, etc.
- **`ResponseSessionTriggerHandler`** — extends `TriggerHandler`; wires the `afterUpdate` event to `ResponseSessionService`.

### Trigger Pattern
`ResponseSessionTrigger` (on `MM_Response_Session__c`) → `ResponseSessionTriggerHandler.run()` → `ResponseSessionService.updateTotalScoreAndSummary()`. All triggers follow this one-trigger-per-object, handler-class pattern.

### LWC Layer (Experience Cloud / LWR site)
- **`questionnaire`** — multi-step questionnaire wizard. Manages question navigation, per-question answer caching in `selectedAnswers` map, and calls Apex on each Next/Submit. Hardcoded test `userId` on line 80 (`questionnaire.js:80`) must be removed before production use.
- **`wellnessInsights`** — displays AI-generated insights from the latest completed session; handles loading, no-data, fallback (score+summary), and error states; uses Custom Labels for all user-facing strings.
- **`welcome`**, **`mindMentorBranding`**, **`lwrLogoutButton`** — site chrome components.

### AI Integration
Both AI flows use `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate()` with `applicationName = 'PromptBuilderPreview'`. In test contexts, `Test.isRunningTest()` gates all callouts — passing `'ERROR'` as the session ID triggers the exception path, any other value returns mock data.

### Security Conventions
- All classes declared `public with sharing`.
- All SOQL uses `Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE)` — never inline string concatenation with user input.
- All DML uses `Database.insert/update/delete(..., AccessLevel.USER_MODE)`.

### Logging
Uses [Nebula Logger](https://github.com/jongpie/NebulaLogger) (`Logger.info()`, `Logger.error()`) throughout. Always call `Logger.saveLog()` in a `finally` block after logging (or it won't persist).

### Test Conventions
- Tests use `@TestSetup` for shared data and `System.runAs(testUser)` to simulate community users.
- The community profile name used in tests is `'Mind Mentor Community User'`.
- `ConnectApi` callouts are bypassed via `Test.isRunningTest()` checks inside the service classes themselves (no need for mock HTTP callout setup).
