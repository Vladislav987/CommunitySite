public without sharing class LA_MassTransferOfAllocationsController {

    static AllocationService allocationService = new AllocationService();

    @AuraEnabled
    public static AllocationService.DataTableWrapper getProjects(Id opportunityId){
        if (String.isBlank(opportunityId)) {

            throw new AuraHandledException('Not valid opportunityId arrived');
        }

        try {
            return allocationService.getDataForMassTransfer(opportunityId);
        }  catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void transferAllocations(Id sowId, Id opportunityId, List<Allocation__c> allocations, Boolean isRejectUnselected){
        if (String.isBlank(sowId)
                ||String.isBlank(opportunityId)
                || allocations.isEmpty()
                || isRejectUnselected == null) {

            throw new AuraHandledException('Not valid data arrived');
        }
        try {

            allocationService.transferAllocations(sowId, opportunityId, allocations, isRejectUnselected);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}