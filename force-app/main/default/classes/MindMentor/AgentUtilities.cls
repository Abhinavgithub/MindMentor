public with sharing class AgentUtilities {
  public static string getResponseSession(string userId) {
    List<MM_Response_Session__c> responseSession = new List<MM_Response_Session__c>();
    responseSession = [
      SELECT
        Id,
        (
          SELECT MM_Question_Text__c, MM_Selected_Option__r.MM_Option_Text__c
          FROM User_Responses__r
        ),
        (
          SELECT
            MM_Question__r.MM_QuestionText__c,
            MM_Question_Option__r.MM_Option_Text__c
          FROM User_Response_Options__r
        )
      FROM MM_Response_Session__c
      WHERE MM_User__c = :userId
      WITH USER_MODE
      ORDER BY createdDate DESC
    ];
    return JSON.serialize(responseSession);
  }
}
