public with sharing class ResponseSessionService {
  @AuraEnabled
  public static void updateTotalScoreAndSummary(
    List<MM_Response_Session__c> responseSessions,
    Map<Id, MM_Response_Session__c> oldResponseSessions
  ) {
    if (responseSessions == null || responseSessions.isEmpty()) {
      return;
    }

    Set<Id> responseSessionIds = new Set<Id>();
    List<MM_Response_Session__c> sessionsToUpdate = new List<MM_Response_Session__c>();

    for (MM_Response_Session__c responseSession : responseSessions) {
      Boolean isCompleted = responseSession.MM_Status__c == 'Completed';
      Boolean isStatusChanged = true;
      
      if (oldResponseSessions != null && oldResponseSessions.containsKey(responseSession.Id)) {
        isStatusChanged = responseSession.MM_Status__c != oldResponseSessions.get(responseSession.Id).MM_Status__c;
      }

      if (isCompleted && isStatusChanged) {
        responseSessionIds.add(responseSession.Id);
      }
    }

    if (responseSessionIds.isEmpty()) {
      return;
    }

    for (Id responseSessionId : responseSessionIds) {
      String totalScoreAndSummary = CalculateTotalScoreAndSummary.getTotalScoreAndSummary(
        responseSessionId
      );

      if (String.isNotBlank(totalScoreAndSummary)) {
        ResponseSessionWrapper wrapper = (ResponseSessionWrapper) JSON.deserialize(
          totalScoreAndSummary,
          ResponseSessionWrapper.class
        );

        sessionsToUpdate.add(
          new MM_Response_Session__c(
            Id = responseSessionId,
            MM_Total_Score__c = wrapper.Score,
            MM_Summary__c = wrapper.Summary
          )
        );
      }
    }

    if (!sessionsToUpdate.isEmpty()) {
      update sessionsToUpdate;
    }
  }

  public class ResponseSessionWrapper {
    @AuraEnabled
    public Integer Score { get; set; }
    @AuraEnabled
    public String Summary { get; set; }
  }
}
