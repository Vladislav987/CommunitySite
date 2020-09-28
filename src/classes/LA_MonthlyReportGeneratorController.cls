/**
 * Created by Ponomarov Vladyslav on 04.05.2020.
 */

public without sharing class LA_MonthlyReportGeneratorController {
    static MonthlyReportService monthlyReportService = new MonthlyReportService();
    static LA_MonthlyReportCreatorService la_MonthlyReportCreatorService = new LA_MonthlyReportCreatorService();
    static AllocationSelector allocationSelector = new AllocationSelector();


    @AuraEnabled
    public static List<Allocation__c> getInitAllocations(Id recordId){
        if (String.isBlank(recordId)) {
            throw new AuraHandledException('Not valid recordId arrived');
        }

        if (!monthlyReportService.isRecordValidForProcess(recordId)) {
            throw new AuraHandledException('You can generate reports only on Allocation with recordType Project');
        }

        List<Allocation__c> allocations = allocationSelector.getCurrentWithStatusActiveAndFinishedByProjectId(recordId);

        if (allocations.isEmpty()) {
            throw new AuraHandledException('No matching allocations found');
        }

        return allocations;
    }

    @AuraEnabled
    public static InfoAboutReportAndAllocation getInfoAboutAllocations(List<String> allocationsIds, String projectId, String month, String year) {
        if (allocationsIds == null || allocationsIds.isEmpty()) {
            throw new AuraHandledException('Sorry, but you have to select Allocations');
        }
        if (month == 'choose one...' || year == 'choose one...') {
            throw new AuraHandledException('Sorry, but you have to select period of report');
        }
        if (String.isBlank(projectId)) {
            throw new AuraHandledException('Sorry, wrong data arrived');
        }

        return la_MonthlyReportCreatorService.getInfoAboutReports(allocationsIds, projectId, month, year);
    }

    public class InfoAboutReportAndAllocation{
        @AuraEnabled
        public List<Allocation__c> withoutReports = new List<Allocation__c>();
        @AuraEnabled
        public List<Allocation__c> withOneReport = new List<Allocation__c>();
        @AuraEnabled
        public List<Allocation__c> withMultipleReports = new List<Allocation__c>();
        @AuraEnabled
        public List<Allocation__c> withBudgetTransactions = new List<Allocation__c>();
    }

    @AuraEnabled
    public static Result generateReports( String allocationsIds, String projectId, String month, String year, List<Date> dates){
        List<String> allocationIds = allocationsIds.split(',');
        if (allocationIds == null || allocationIds.isEmpty()) {
            throw new AuraHandledException('Sorry, but you have to select Allocations');
        }
        if (month == 'choose one...' || year == 'choose one...') {
            throw new AuraHandledException('Sorry, but you have to select period of report');
        }
        if (String.isBlank(projectId)){
            throw new AuraHandledException('Sorry, wrong data arrived');
        }
        System.debug('allocationIds---> ' + allocationIds);
        System.debug('projectId---> ' + projectId);
        System.debug('month---> ' + month);
        System.debug('year---> ' + year);
        System.debug('dates---> ' + dates);
        return la_MonthlyReportCreatorService.createReportsFromComponent(new Set<String>(allocationIds), projectId, month, year, dates);
    }

    public class Result {
        @AuraEnabled
        public Boolean isSuccessful { get; set; }
        @AuraEnabled
        public String message { get; set; }
        public Result(Boolean isSuccessful, String message) {
            this.isSuccessful = isSuccessful;
            this.message = message;
        }
    }


}