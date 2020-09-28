public without sharing class ContractorTriggerHandler extends SObjectDomain {
    SalaryHistoryService salaryHistoryService = new SalaryHistoryService();
    ContractorService contractorService = new ContractorService();

    public override void onAfterInsert() {
        salaryHistoryService.createRecords((List<Contractor__c>) this.records);
    }
    public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
        contractorService.checkFieldSalaryAndUpdateSalaryHistory((List<Contractor__c>) this.records, (Map<Id, Contractor__c>) existingRecords);
    }
    public override void onBeforeUpdate(Map<Id, SObject> existingRecords){
        contractorService.checkSalaryForNull((List<Contractor__c>) this.records, (Map<Id, Contractor__c>) existingRecords);
    }
}