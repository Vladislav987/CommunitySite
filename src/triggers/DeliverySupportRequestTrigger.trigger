trigger DeliverySupportRequestTrigger on Delivery_Support_Request__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    SObjectDomain.triggerHandler(DeliverySupportRequestTriggerHandler.class);
}