# MindMentor

> An AI-powered mental wellness application built on Salesforce Experience Cloud, helping users develop self-awareness through guided assessments and intelligent insights.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Salesforce API](https://img.shields.io/badge/Salesforce%20API-v63.0-blue.svg)](https://developer.salesforce.com)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Data Model](#data-model)
- [AI Integration](#ai-integration)
- [Prerequisites](#prerequisites)
- [Setup & Deployment](#setup--deployment)
- [Development Workflow](#development-workflow)
- [Project Structure](#project-structure)
- [Security Model](#security-model)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

MindMentor is an open-source Salesforce Experience Cloud (LWR) application that guides users through mental wellness assessments and surfaces AI-generated insights about their emotional health. It uses Einstein Prompt Templates and the Agentforce AI platform to analyze assessment responses and provide personalized, empathetic feedback — without storing any clinical or medical data.

---

## Features

### Mental Health Assessment
A multi-step questionnaire wizard that walks users through a scored wellness assessment. Supports multiple question types: Multiple Choice, Yes/No, Multiple Select, and free-text responses. Sessions are tracked end-to-end from start to completion.

### AI-Powered Score & Summary
When a session is completed, a Salesforce trigger automatically invokes an Einstein Prompt Template (`Calculate_User_Score_and_Summary`) to calculate a wellness score and generate a plain-language summary based on the user's responses.

### Wellness Insights
A dedicated component displays AI-generated insights from the user's latest completed assessment. Insights are categorized by domain (e.g., sleep, stress, mood) and severity (high/medium/low), powered by the `Generate_Wellness_Insights` Einstein Prompt Template.

### Agentforce AI Agent
An Agentforce agent is available to engage users in supportive conversations and retrieve their session history. The `AgentUtilities` Apex class provides the agent's data layer, returning session history as structured JSON for agent context.

### Branded Experience Site
A fully themed Salesforce Experience Cloud LWR site with personalized welcome page, MindMentor brand components, and a consistent warm design system across all pages.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│              Experience Cloud (LWR Site)             │
│                                                     │
│   ┌──────────┐  ┌──────────────┐  ┌─────────────┐  │
│   │ welcome  │  │questionnaire │  │wellnessInsights│ │
│   └──────────┘  └──────┬───────┘  └──────┬──────┘  │
└──────────────────────── │ ────────────────│─────────┘
                          │ @AuraEnabled    │ @AuraEnabled
              ┌───────────▼────────────┐  ┌─▼──────────────────┐
              │ QuestionnaireController│  │WellnessInsightsCtrl │
              └───────────┬────────────┘  └─┬──────────────────┘
                          │                  │
              ┌───────────▼────────────┐  ┌─▼──────────────────┐
              │  MM_Response_Session__c│  │WellnessInsightsService│
              │  (afterUpdate trigger) │  └─┬──────────────────┘
              └───────────┬────────────┘    │
                          │                  │
              ┌───────────▼────────────┐     │
              │ ResponseSessionService │     │
              └───────────┬────────────┘     │
                          │ Einstein LLM      │ Einstein LLM
              ┌───────────▼────────────────┐ │
              │  Calculate_User_Score_     │ │
              │  and_Summary (Prompt Tmpl) │ │
              └────────────────────────────┘ │
                                ┌────────────▼──────────────┐
                                │  Generate_Wellness_Insights│
                                │  (Prompt Template)         │
                                └───────────────────────────┘
```

**Stack:**
| Layer | Technology |
|---|---|
| Site runtime | Salesforce Experience Cloud (LWR) |
| Frontend | Lightning Web Components (LWC) |
| Backend | Apex (API v63.0) |
| AI | Einstein Prompt Templates via `ConnectApi.EinsteinLLM` |
| AI Agent | Agentforce |
| Logging | [Nebula Logger](https://github.com/jongpie/NebulaLogger) |

---

## Data Model

All custom objects use the `MM_` prefix.

```
MM_Questionnaire__c
│   MM_Is_Active__c (Boolean)
│
├── MM_Question__c
│   │   MM_Question_Text__c, MM_Type__c (Multiple Choice | Yes/No | Multiple Select | Text)
│   │   MM_Order__c, MM_Weight__c, MM_Is_Crisis__c
│   │
│   └── MM_Question_Option__c
│           MM_Option_Text__c, MM_Score__c
│
└── Scoring_Rule__c
        MM_Min_Score__c, MM_Max_Score__c, MM_Summary__c, MM_Action__c

MM_Response_Session__c          (linked to Contact via MM_User__c)
│   MM_Status__c (In Progress | Completed)
│   MM_Score__c, MM_Summary__c, MM_Start_Time__c, MM_End_Time__c
│
├── MM_User_Response__c          (single-select and text answers)
│       MM_Question__c, MM_Selected_Option__c, MM_Response_Text__c
│
└── MM_User_Response_Options__c  (multi-select answers — one record per option)
        MM_Question__c, MM_Selected_Option__c
```

**User identity:** Community users are resolved via `User.ContactId`. All queries use `userId → contactId` before accessing session data.

---

## AI Integration

MindMentor uses two Einstein Prompt Templates, both called via `ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate()` with `applicationName = 'PromptBuilderPreview'`.

| Prompt Template | Trigger | Output |
|---|---|---|
| `Calculate_User_Score_and_Summary` | `MM_Response_Session__c` afterUpdate (status → Completed) | `{"Score": <int>, "Summary": "<text>"}` |
| `Generate_Wellness_Insights` | `WellnessInsightsController.getLatestWellnessInsights()` | `{"insights": [{category, insight, severity, icon}], ...}` |

**Test context:** Both templates gate all callouts behind `Test.isRunningTest()`. Passing `'ERROR'` as the session ID in tests triggers the exception path; any other value returns mock data. No HTTP mock setup is required.

---

## Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf` v2+)
- [Node.js](https://nodejs.org/) v18+
- A Salesforce Developer Org or Scratch Org with:
  - Experience Cloud enabled
  - Einstein generative AI / Prompt Builder enabled
  - Agentforce enabled
- [Nebula Logger](https://github.com/jongpie/NebulaLogger) deployed to your org (required dependency)

---

## Setup & Deployment

### 1. Clone the repository

```bash
git clone https://github.com/Abhinavgithub/MindMentor.git
cd MindMentor
```

### 2. Install Node dependencies

```bash
npm install
```

### 3. Authenticate with your org

```bash
sf org login web --alias mindmentor-dev
sf config set target-org mindmentor-dev
```

### 4. Deploy Nebula Logger

Follow the [Nebula Logger installation guide](https://github.com/jongpie/NebulaLogger#installing-nebula-logger) before deploying MindMentor.

### 5. Deploy MindMentor

```bash
# Deploy everything
sf project deploy start --source-dir force-app

# Or deploy with tests
sf project deploy start --source-dir force-app --test-level RunLocalTests
```

### 6. Post-deployment configuration

1. **Experience Cloud site** — Create an LWR Experience Cloud site and add the LWC components to the relevant pages.
2. **Assign permission sets** — Grant the `Mind Mentor Community User` profile access to the Experience Cloud site.
3. **Prompt Templates** — Create and activate the two Einstein Prompt Templates (`Calculate_User_Score_and_Summary` and `Generate_Wellness_Insights`) in Prompt Builder. Ensure they are connected to the correct input fields.
4. **Agentforce agent** — Configure the Agentforce agent and connect `AgentUtilities.getResponseSession` as a data action.
5. **Questionnaire data** — Insert at least one active `MM_Questionnaire__c` record with associated `MM_Question__c` and `MM_Question_Option__c` records.

---

## Development Workflow

### Deploy a single component

```bash
sf project deploy start --source-dir force-app/main/default/lwc/questionnaire
sf project deploy start --source-dir force-app/main/default/classes/MindMentor/WellnessInsightsService.cls
```

### Run Apex tests

```bash
# All tests
sf apex run test --test-level RunLocalTests --output-dir .

# Single test class
sf apex run test --class-names WellnessInsightsServiceTest --output-dir .

# Single test method
sf apex run test --tests CalculateTotalScoreAndSummaryTest.testReturnsCannedJsonInTestContext --output-dir .
```

### Lint

```bash
# Lint LWC JavaScript
npm run lint

# Lint + auto-fix CSS/HTML/JS formatting
npm run prettier
```

### Open org in browser

```bash
sf org open
```

---

## Project Structure

```
force-app/main/default/
├── classes/MindMentor/
│   ├── QuestionnaireController.cls        # @AuraEnabled methods for questionnaire LWC
│   ├── WellnessInsightsController.cls     # @AuraEnabled method for insights LWC
│   ├── WellnessInsightsService.cls        # Calls Generate_Wellness_Insights prompt template
│   ├── CalculateTotalScoreAndSummary.cls  # Calls Calculate_User_Score_and_Summary prompt template
│   ├── ResponseSessionService.cls         # Called by trigger on session completion
│   ├── AgentUtilities.cls                 # Data layer for Agentforce agent
│   ├── TriggerHandler.cls                 # Base handler class (virtual)
│   └── ResponseSessionTriggerHandler.cls  # Wires afterUpdate to ResponseSessionService
├── triggers/
│   └── ResponseSessionTrigger.trigger     # One trigger on MM_Response_Session__c
├── lwc/
│   ├── questionnaire/                     # Multi-step assessment wizard
│   ├── wellnessInsights/                  # AI insights display
│   ├── welcome/                           # Personalized landing page
│   ├── mindMentorBranding/               # Site header/branding component
│   └── lwrLogoutButton/                   # Logout button for LWR site
└── objects/
    ├── MM_Questionnaire__c/
    ├── MM_Question__c/
    ├── MM_Question_Option__c/
    ├── MM_Response_Session__c/
    ├── MM_User_Response__c/
    ├── MM_User_Response_Options__c/
    └── Scoring_Rule__c/
```

### Trigger pattern

All triggers follow the one-trigger-per-object, handler-class pattern:

```
ResponseSessionTrigger
  → ResponseSessionTriggerHandler.run()
    → ResponseSessionService.updateTotalScoreAndSummary()
      → CalculateTotalScoreAndSummary (Einstein Prompt Template call)
```

---

## Security Model

- All Apex classes are declared `public with sharing`.
- All SOQL uses `Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE)` — no inline string concatenation with user-controlled input.
- All DML uses `Database.insert/update/delete(..., AccessLevel.USER_MODE)`.
- Sharing rules and FLS are enforced at the database level on every operation.

---

## Contributing

Contributions are welcome! MindMentor is an open-source project and we appreciate bug reports, feature suggestions, and pull requests.

### Getting started

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature-name`
3. Make your changes and write/update tests
4. Run `npm run prettier` and `npm run lint` — fix any issues
5. Deploy to your dev org and verify end-to-end
6. Commit using the convention: `feat:`, `fix:`, `refactor:`, `docs:` prefixes
7. Push and open a pull request against `main`

### Guidelines

- Follow the one-trigger-per-object, handler-class pattern for any new triggers.
- All new Apex must use `with sharing` and `AccessLevel.USER_MODE` for SOQL/DML.
- Use `Logger.info()` / `Logger.error()` from Nebula Logger and always call `Logger.saveLog()` in a `finally` block.
- LWC templates targeting this LWR site must use `lwc:if` for conditionals and `for:each`/`for:item` for iteration (`lwc:elseif` and `lwc:for` are not supported in this LWR version).
- Keep all user-facing strings in Custom Labels.

---

## License

This project is licensed under the [MIT License](LICENSE).
