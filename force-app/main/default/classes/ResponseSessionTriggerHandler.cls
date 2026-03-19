public with sharing class ResponseSessionTriggerHandler extends TriggerHandler {
  public override void afterUpdate() {
    ResponseSessionService.updateTotalScoreAndSummary(
      (List<MM_Response_Session__c>) triggerNew,
      (Map<Id, MM_Response_Session__c>) triggerOldMap
    );
  }
}
