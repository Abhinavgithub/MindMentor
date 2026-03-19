public with sharing virtual class TriggerHandler {
  @TestVisible
  protected List<SObject> triggerNew;
  @TestVisible
  protected List<SObject> triggerOld;
  @TestVisible
  protected Map<Id, SObject> triggerNewMap;
  @TestVisible
  protected Map<Id, SObject> triggerOldMap;
  @TestVisible
  protected Boolean isExecuting;
  @TestVisible
  protected Integer triggerSize;
  @TestVIsible
  System.TriggerOperation context;

  public TriggerHandler() {
    triggerNew = Trigger.new;
    triggerOld = Trigger.old;
    triggerNewMap = Trigger.newMap;
    triggerOldMap = Trigger.oldMap;
    isExecuting = false;
    triggerSize = Trigger.size;
    context = Trigger.operationType;
  }

  public void run() {
    if (context != null) {
      switch on context {
        when BEFORE_INSERT {
          beforeInsert();
        }
        when BEFORE_UPDATE {
          beforeUpdate();
        }
        when BEFORE_DELETE {
          beforeDelete();
        }
        when AFTER_INSERT {
          afterInsert();
        }
        when AFTER_UPDATE {
          afterUpdate();
        }
        when AFTER_DELETE {
          afterDelete();
        }
        when AFTER_UNDELETE {
          afterUndelete();
        }
      }
    }
  }

  @TestVisible
  protected virtual void beforeInsert() {
  }
  @TestVisible
  protected virtual void beforeUpdate() {
  }
  @TestVisible
  protected virtual void beforeDelete() {
  }
  @TestVisible
  protected virtual void afterInsert() {
  }
  @TestVisible
  protected virtual void afterUpdate() {
  }
  @TestVisible
  protected virtual void afterDelete() {
  }
  @TestVisible
  protected virtual void afterUndelete() {
  }
}
