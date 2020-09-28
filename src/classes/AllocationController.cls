public without sharing class AllocationController {

    public static AllocationService allocationService = new AllocationService();

    @AuraEnabled
    public static RelatedListInfo getRelatedListInitData(Id projectId) {

        if (String.isBlank(projectId)) {
            throw new AuraHandledException('Not valid recordId arrived'); //TODO: change to custom label if needed, or make as const
        }

        return new RelatedListInfo(allocationService.getStatuses(),
                allocationService.getTypes(),
                allocationService.getAllocationsForRelatedList(projectId));
    }

    @AuraEnabled
    public static MatrixInfo getMatrixAllocationAndContractorsInitData(Id projectId){
        if (String.isBlank(projectId)) {
            throw new AuraHandledException('Not valid recordId arrived'); //TODO: change to custom label if needed, or make as const
        }

        return new MatrixInfo(allocationService.getStatusesWithoutExcluded(),
                allocationService.getTypesWithoutExcluded(),
                allocationService.getChildAndParentProjectsWithAllocationsByParentProjectId(projectId));
    }

    @AuraEnabled
    public static String upsertAndApproveAllocations(List<Object> allocations){
        String upsertResults = '';
        String approveResults = '';

        List<Allocation__c> parsedAllocations = allocationService.parseAllocations(allocations);

        upsertResults = allocationService.upsertAllocationsBaseOnAnotherRandomAllocation(parsedAllocations, true);

        if (String.isEmpty(upsertResults)) {
            approveResults = allocationService.approveAllocations(parsedAllocations);
        }

        return String.isEmpty(upsertResults) ? String.isEmpty(approveResults) ? 'Success' : approveResults : upsertResults;
    }

    @AuraEnabled
    public static String getRelationshipFieldApiNameFromAllocationsMapping(Id sObjectId){
        String sObjectName = sObjectId.getSobjectType().getDescribe().getName();

        return allocationService.getRelationshipFieldForSObject(sObjectName);
    }

    @AuraEnabled
    public static String upsertAllocationsBaseOnRandomAllocation(List<Object> allocations){
        List<Allocation__c> parsedAllocations = allocationService.parseAllocations(allocations);

        String upsertResults = allocationService.upsertAllocationsBaseOnAnotherRandomAllocation(parsedAllocations, false);

        return String.isEmpty(upsertResults) ? 'Success' : upsertResults;
    }

    @AuraEnabled
    public static String createNullableAllocation(Id projectId, Allocation__c allocation, String allocationType, String overrunType){
        if (projectId != null && allocation.Id != null && !String.isEmpty(allocationType)) {
            return allocationService.insertNullableAllocation(projectId, allocation, allocationType, overrunType);
        }
        return 'Empty Project Id or Allocation';
    }

    @AuraEnabled
    public static String deleteNullableAllocation(Allocation__c allocation){

        if (allocation != null) {
            Database.DeleteResult result = Database.delete(allocation);
            return result.isSuccess() ? 'Success' : result.getErrors()[0].getMessage();
        }

        return 'Empty Allocation';
    }

    @AuraEnabled
    public static List<String> getOverrunTypes(){
        return allocationService.getOverrunTypes();
    }

    @AuraEnabled
    public static Map<Id, String> getAllocationRecordTypes(){
        return allocationService.getAllocationRecordTypes();
    }

    public class RelatedListInfo {
        @AuraEnabled
        public List<String> statuses { get; set; }
        @AuraEnabled
        public List<String> types { get; set; }
        @AuraEnabled
        public AllocationService.DataTableWrapper dataTable { get; set; }
        public RelatedListInfo(List<String> statuses,
                List<String> types,
                AllocationService.DataTableWrapper dataTable) {
            this.statuses = statuses;
            this.types = types;
            this.dataTable = dataTable;
        }
    }

    public class MatrixInfo {
        @AuraEnabled
        public List<String> statuses { get; set; }
        @AuraEnabled
        public List<String> types { get; set; }
        @AuraEnabled
        public AllocationService.MatrixAllocationAndContractorsData matrixData { get; set; }
        public MatrixInfo(List<String> statuses,
                List<String> types,
                AllocationService.MatrixAllocationAndContractorsData matrixData) {
            this.statuses = statuses;
            this.types = types;
            this.matrixData = matrixData;
        }
    }
}