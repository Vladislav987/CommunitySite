public without sharing class MonthlyReportHandler extends SObjectDomain {

    MonthlyReportService monthlyReportService = new MonthlyReportService();
    User currentUser = [SELECT Id, Skip_validation_rules__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

    public override void onAfterInsert(){
        monthlyReportService.checkContractorsAndUpdateThem((List<Monthly_Report__c>) this.records);
    }

    public override void onBeforeUpdate(Map<Id, SObject> existingRecords){
        Boolean passedValidation = currentUser.Skip_validation_rules__c ? true : monthlyReportService.checkAndValidatePlanHours((List<Monthly_Report__c>) this.records, (Map<Id, Monthly_Report__c>) existingRecords);
        if (passedValidation) {
            monthlyReportService.recalculateFieldByCurrency((List<Monthly_Report__c>) this.records, (Map<Id, Monthly_Report__c>) existingRecords);
        }
    }

    public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
        Boolean passedValidation = currentUser.Skip_validation_rules__c ? true : monthlyReportService.validateMonthlyReports((Map<Id, Monthly_Report__c>)existingRecords, (List<Monthly_Report__c>) this.records);

        if (passedValidation) {
            monthlyReportService.sortReportByFactHoursAndFillFields((List<Monthly_Report__c>) this.records, (Map<Id, Monthly_Report__c>) existingRecords);
        }

    }

    public override void onAfterDelete() {
        monthlyReportService.checkContractorsAndUpdateThem((List<Monthly_Report__c>) this.records);
    }

    public override void onAfterUnDelete() {
        monthlyReportService.checkContractorsAndUpdateThem((List<Monthly_Report__c>) this.records);
    }
}