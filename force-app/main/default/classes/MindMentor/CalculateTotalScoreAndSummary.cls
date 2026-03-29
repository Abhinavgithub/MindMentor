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
    Logger.info('Input Params of the prompt template: ' + inputParams);

    // Configure invocation parameters
    ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
    executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
    executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
    executeTemplateInput.isPreview = false;
    executeTemplateInput.inputParams = inputParams;

    try {
      if (Test.isRunningTest()) {
        Logger.info('Running in test context');
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
      Logger.info('Response of the prompt template: ' + response.text);
      return response.text;
    } catch (Exception ex) {
      Logger.error('Error calling Einstein Prompt Template: ' + ex);
      throw e;
    } finally {
      Logger.saveLog();
    }
  }
}
