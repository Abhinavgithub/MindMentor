trigger ResponseSessionTrigger on MM_Response_Session__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  ResponseSessionTriggerHandler handler = new ResponseSessionTriggerHandler();
  handler.run();
}
