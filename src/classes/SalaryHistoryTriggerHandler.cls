public with sharing class SalaryHistoryTriggerHandler extends SObjectDomain{
    SalaryHistoryService salaryHistoryService = new SalaryHistoryService();

    public override void onBeforeInsert() {
        salaryHistoryService.validateAndCreate((List<Salary_History__c>) this.records);
    }
    public override void onAfterInsert() {
        salaryHistoryService.updatePreviousAndCreateNew((List<Salary_History__c>) this.records);
    }
    public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
        salaryHistoryService.checkSalaryAndUpdateReports((List<Salary_History__c>) this.records, (Map<Id, Salary_History__c>) existingRecords);
    }
    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        salaryHistoryService.validateUpdatedRecords((List<Salary_History__c>) this.records, (Map<Id, Salary_History__c>) existingRecords);
    }
}