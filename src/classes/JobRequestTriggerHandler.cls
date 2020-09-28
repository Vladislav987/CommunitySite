public with sharing class JobRequestTriggerHandler {

    public void onAfterUpdate(Map<Id, Job_Request__c> newJobRequestsByIds, Map<Id, Job_Request__c> oldJobRequestsByIds){
        new AppliedPositionManagementService().updateHiringManagers(newJobRequestsByIds, oldJobRequestsByIds);
    }

}