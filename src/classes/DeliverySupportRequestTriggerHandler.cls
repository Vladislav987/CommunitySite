public without sharing class DeliverySupportRequestTriggerHandler extends SObjectDomain{
    DeliverySupportRequestService deliverySupportRequestService =  new DeliverySupportRequestService();

    public override void onAfterInsert(){
        deliverySupportRequestService.sendEmailsForUsersByCriteria(this.records);
    }

    public override void onBeforeInsert(){
        deliverySupportRequestService.assignUser(this.records);
    }
}