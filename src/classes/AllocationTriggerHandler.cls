/**
 * Created by Dmytro Ardashov on 24.04.2019.
 */

public without sharing class AllocationTriggerHandler extends SObjectDomain {

    private AllocationRateCountService rateService = new AllocationRateCountService();
    private AllocationProjectDescriptionService projectDescriptionService = new AllocationProjectDescriptionService();
    private AllocationService allocationService = new AllocationService();
    private ApproveServiceForAllocation approveServiceForAllocation = new ApproveServiceForAllocation();
    public static User currentUser = Util.CURRENT_USER;

    public override void onBeforeInsert() {

        allocationService.fillAllocationFields((List<Allocation__c>) this.records);
        rateService.prepareRecordsForInsert((List<Allocation__c>) Trigger.new);
    }

    public override void onAfterInsert() {
        Boolean passedValidation = currentUser.Skip_validation_rules__c ? true : allocationService.validateForSingleAllocationOfSomeTypeForProject((List<Allocation__c>) Trigger.new);

        if (passedValidation) {
            approveServiceForAllocation.fillApproverManagerField((List<Allocation__c>) this.records);
            approveServiceForAllocation.checkForFilledApproverField((List<Allocation__c>) this.records);
            projectDescriptionService.setProjectDescription((List<Allocation__c>) this.records);
            allocationService.sortAllocationForRollUp((List<Allocation__c>) this.records);

            System.enqueueJob(new RollupSummaryServiceQueue(this.records));
        }
    }

    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        Boolean passedValidation = currentUser.Skip_validation_rules__c ? true : allocationService.validateForFilledContractorInApprovalProcess((List<Allocation__c>) this.records);

        if (passedValidation || currentUser.Skip_validation_rules__c) {
            rateService.prepareRecordsForUpdate((List<Allocation__c>) this.records, (Map<Id, Allocation__c>) existingRecords);
        }
    }

    public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
        Boolean passedValidation = currentUser.Skip_validation_rules__c ? true : allocationService.validateAllocations((Map<Id, Allocation__c>) existingRecords, (List<Allocation__c>) this.records);

        if (passedValidation) {
            approveServiceForAllocation.fillApproverManagerField((Map<Id, Allocation__c>) existingRecords, (List<Allocation__c>) this.records);
            allocationService.sortNeededRecords((List<Allocation__c>) this.records, (Map<Id, Allocation__c>) existingRecords);

            System.enqueueJob(new RollupSummaryServiceQueue(this.records, existingRecords.values()));
        }
    }


    public override void onBeforeDelete() {
        if (!currentUser.Skip_validation_rules__c) {
            allocationService.checkAllocationsForPossibilityToDelete((List<Allocation__c>) this.records);
        }
    }

    public override void onAfterDelete() {
        allocationService.sortAllocationForRollUp((List<Allocation__c>) this.records);

        System.enqueueJob(new RollupSummaryServiceQueue(this.records));
    }

    public override void onAfterUnDelete() {
        Boolean passedValidation = currentUser.Skip_validation_rules__c ? true : allocationService.validateForSingleAllocationOfSomeTypeForProject((List<Allocation__c>) this.records);

        if (passedValidation) {
            allocationService.sortAllocationForRollUp((List<Allocation__c>) this.records);

            System.enqueueJob(new RollupSummaryServiceQueue(this.records));
        }
    }
}