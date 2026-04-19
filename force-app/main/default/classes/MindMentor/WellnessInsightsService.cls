/**
 * @description Service class for generating wellness insights using GenAI Prompt Template.
 * Uses with sharing to enforce record-level security and sharing rules.
 */
public with sharing class WellnessInsightsService {
  /**
   * @description Generates wellness insights for a given response session using AI.
   * Falls back to score and summary if the prompt template fails.
   * @param responseSessionId The Id of the MM_Response_Session__c record
   * @return JSON string containing insights or fallback data
   * @throws AuraHandledException if the operation fails
   */
  @AuraEnabled
  public static String getWellnessInsights(String responseSessionId) {
    if (String.isBlank(responseSessionId)) {
      throw new AuraHandledException('Response Session Id is required.');
    }

    try {
      // Create inputs for the prompt template
      Map<String, String> responseSession = new Map<String, String>();
      responseSession.put('id', responseSessionId);
      ConnectApi.WrappedValue responseSessionValue = new ConnectApi.WrappedValue();
      responseSessionValue.value = responseSession;
      Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
      inputParams.put('Input:Response_Session_Id', responseSessionValue);

      Logger.info('Wellness Insights - Input Params: ' + inputParams);

      // Configure invocation parameters
      ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
      executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
      executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
      executeTemplateInput.isPreview = false;
      executeTemplateInput.inputParams = inputParams;

      // Handle test context
      if (Test.isRunningTest()) {
        Logger.info('Running in test context for Wellness Insights');
        if (responseSessionId == 'ERROR') {
          CalloutException e = new CalloutException();
          e.setMessage('Test Exception');
          throw e;
        }
        return getMockInsightsResponse();
      }

      // Call the prompt template
      ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
        'Generate_Wellness_Insights',
        executeTemplateInput
      );

      ConnectApi.EinsteinLLMGenerationItemOutput response = generationsOutput.generations[0];
      Logger.info('Wellness Insights - Prompt Response: ' + response.text);

      // Strip markdown code fence markers if present
      String cleanedResponse = stripMarkdownCodeFence(response.text);
      Logger.info('Wellness Insights - Cleaned Response: ' + cleanedResponse);

      return cleanedResponse;
    } catch (Exception e) {
      Logger.error(
        'Error calling Wellness Insights Prompt Template: ' + e.getMessage()
      );

      // Fallback: Return score and summary from the session
      try {
        return getFallbackInsights(responseSessionId);
      } catch (Exception fallbackException) {
        Logger.error(
          'Error generating fallback insights: ' +
          fallbackException.getMessage()
        );
        throw new AuraHandledException(
          'Unable to generate insights: ' + e.getMessage()
        );
      }
    } finally {
      Logger.saveLog();
    }
  }

  /**
   * @description Generates fallback insights using score and summary from the session.
   * @param responseSessionId The Id of the MM_Response_Session__c record
   * @return JSON string with fallback data
   */
  private static String getFallbackInsights(String responseSessionId) {
    Map<String, Object> bindVars = new Map<String, Object>{
      'sessionId' => responseSessionId
    };

    List<MM_Response_Session__c> sessions = Database.queryWithBinds(
      'SELECT MM_Total_Score__c, MM_Summary__c FROM MM_Response_Session__c WHERE Id = :sessionId LIMIT 1',
      bindVars,
      AccessLevel.USER_MODE
    );

    if (sessions.isEmpty()) {
      throw new AuraHandledException('Session not found.');
    }

    MM_Response_Session__c session = sessions[0];

    // Create a simple fallback response structure
    Map<String, Object> fallbackResponse = new Map<String, Object>{
      'insights' => new List<Object>(),
      'fallbackScore' => session.MM_Total_Score__c,
      'fallbackSummary' => session.MM_Summary__c,
      'usedFallback' => true
    };

    Logger.info('Using fallback insights: ' + fallbackResponse);
    return JSON.serialize(fallbackResponse);
  }

  /**
   * @description Strips markdown code fence markers from the response text.
   * Removes ```json, ```, and any leading/trailing whitespace.
   * @param responseText The raw response text from the GenAI model
   * @return Cleaned JSON string without markdown formatting
   */
  private static String stripMarkdownCodeFence(String responseText) {
    if (String.isBlank(responseText)) {
      return responseText;
    }

    String cleaned = responseText.trim();

    // Remove opening markdown fence (```json or ```)
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7); // Remove '```json'
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3); // Remove '```'
    }

    // Remove closing markdown fence (```)
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length() - 3);
    }

    // Trim any remaining whitespace
    return cleaned.trim();
  }

  /**
   * @description Returns mock insights response for testing.
   * @return JSON string with mock insights
   */
  private static String getMockInsightsResponse() {
    Map<String, Object> mockResponse = new Map<String, Object>{
      'insights' => new List<Object>{
        new Map<String, String>{
          'category' => 'Depression',
          'insight' => 'Establish a daily routine with regular sleep and wake times.',
          'icon' => 'utility:favorite',
          'severity' => 'high'
        },
        new Map<String, String>{
          'category' => 'Anxiety',
          'insight' => 'Practice deep breathing exercises for 5 minutes when overwhelmed.',
          'icon' => 'utility:warning',
          'severity' => 'medium'
        },
        new Map<String, String>{
          'category' => 'Stress',
          'insight' => 'Schedule 15 minutes daily for activities you enjoy.',
          'icon' => 'utility:help',
          'severity' => 'low'
        }
      },
      'fallbackScore' => 75,
      'fallbackSummary' => 'Test Summary - Your responses indicate moderate levels of stress and anxiety.'
    };

    return JSON.serialize(mockResponse);
  }
}
