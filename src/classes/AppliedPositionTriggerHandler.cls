public with sharing class AppliedPositionTriggerHandler {

    public void onBeforeInsert(List<Applied_Position__c> newAppliedPositions){
        new AppliedPositionManagementService().setHiringManager(newAppliedPositions);
    }

}