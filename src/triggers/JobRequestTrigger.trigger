trigger JobRequestTrigger on Job_Request__c (after update) {

    JobRequestTriggerHandler handler = new JobRequestTriggerHandler();

    if (Trigger.isAfter){
        if (Trigger.isUpdate){
            handler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }
    }

}