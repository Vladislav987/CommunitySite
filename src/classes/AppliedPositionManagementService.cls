public without sharing class AppliedPositionManagementService {

    public void setHiringManager(List<Applied_Position__c> newAppliedPositions) {
        Set<Id> jobRequestIds = this.getJobRequestIds(newAppliedPositions);
        Map<Id, Job_Request__c> jobRequestsByIds = this.getJobRequests(jobRequestIds);

        for (Applied_Position__c appliedPosition : newAppliedPositions) {
            appliedPosition.Hiring_Manager__c = jobRequestsByIds.get(appliedPosition.Job_Request__c).OwnerId;
        }
    }

    private Set<Id> getJobRequestIds(List<Applied_Position__c> appliedPositions) {
        Set<Id> jobRequestIds = new Set<Id>();
        for (Applied_Position__c appliedPosition : appliedPositions) {
            jobRequestIds.add(appliedPosition.Job_Request__c);
        }
        return jobRequestIds;
    }

    private Map<Id, Job_Request__c> getJobRequests(Set<Id> appliedPositions) {
        return new Map<Id, Job_Request__c>([SELECT OwnerId FROM Job_Request__c WHERE Id IN :appliedPositions]);
    }

    public void updateHiringManagers(Map<Id, Job_Request__c> newJobRequestsByIds, Map<Id, Job_Request__c> oldJobRequestsByIds) {
        Map <Id, Job_Request__c> JRByIdsWithChangedOwner = this.getJRByIdsWithChangedOwner(newJobRequestsByIds, oldJobRequestsByIds);
        List<Applied_Position__c> appliedPositions = this.getappliedPositionsByJR(JRByIdsWithChangedOwner.keySet());

        for (Applied_Position__c appliedPosition : appliedPositions) {
            appliedPosition.Hiring_Manager__c = JRByIdsWithChangedOwner.get(appliedPosition.Job_Request__c).OwnerId;
        }

        update appliedPositions;

    }

    private Map <Id, Job_Request__c> getJRByIdsWithChangedOwner(Map<Id, Job_Request__c> newJobRequestsByIds, Map<Id, Job_Request__c> oldJobRequestsByIds) {
        Map <Id, Job_Request__c> JRByIdsWithChangedOwner = new Map <Id, Job_Request__c>();
        for (Id id : newJobRequestsByIds.keySet()) {
            if (newJobRequestsByIds.get(id).OwnerId != oldJobRequestsByIds.get(id).OwnerId) {
                JRByIdsWithChangedOwner.put(id, newJobRequestsByIds.get(id));
            }
        }
        return JRByIdsWithChangedOwner;
    }

    private List<Applied_Position__c> getappliedPositionsByJR(Set<Id> jobRequestsIds) {
        return [SELECT Hiring_Manager__c, Job_Request__c FROM Applied_Position__c WHERE Job_Request__c IN :jobRequestsIds];
    }

}