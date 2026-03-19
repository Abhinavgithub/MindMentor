public with sharing class CalculateTotalScoreAndSummary {
  @AuraEnabled
  public static String getTotalScoreAndSummary(String responseSessionId) {
    // Create inputs
    Map<String, String> responseSession = new Map<String, String>();
    responseSession.put('id', responseSessionId);
    ConnectApi.WrappedValue responseSessionValue = new ConnectApi.WrappedValue();
    responseSessionValue.value = responseSession;
    Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
    inputParams.put('Input:Response_Session_Id', responseSessionValue);

    // Configure invocation parameters
    ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
    executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
    executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
    executeTemplateInput.isPreview = false;
    executeTemplateInput.inputParams = inputParams;

    try {
      if (Test.isRunningTest()) {
        if (responseSessionId == 'ERROR') {
          CalloutException e = new CalloutException();
          e.setMessage('Test Exception');
          throw e;
        }
        return '{"Score": 85, "Summary": "Test Summary"}';
      }

      // Call the service
      ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
        'Calculate_User_Score_and_Summary',
        executeTemplateInput
      );
      ConnectApi.EinsteinLLMGenerationItemOutput response = generationsOutput.generations[0];
      System.debug(response.text);
      return response.text;
    } catch (Exception e) {
      System.debug(e.getMessage());
      throw e;
    }
  }
}
