trigger AppliedPositionTrigger on Applied_Position__c (before insert) {
    AppliedPositionTriggerHandler handler = new AppliedPositionTriggerHandler();

    if (Trigger.isBefore){
        if (Trigger.isInsert){
            handler.onBeforeInsert(Trigger.new);
        }
    }
}