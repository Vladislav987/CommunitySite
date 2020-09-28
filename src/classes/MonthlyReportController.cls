/**
 * Created by Mychailo Hamdzii on 16.04.2019.
 */

public without sharing class MonthlyReportController {
    static MonthlyReportService monthlyReportService = new MonthlyReportService();
    static AllocationSelector allocationSelector = new AllocationSelector();
    static LA_MonthlyReportCreatorService monthlyReportCreatorService = new LA_MonthlyReportCreatorService();
    static ProjectSelector projectSelector = new ProjectSelector();

    @AuraEnabled
    public static ModalInfo getInitData(Id recordId) {
        if (String.isBlank(recordId)) {

            throw new AuraHandledException('Not valid recordId arrived'); //TODO: change to custom label if needed, or make as const
        }

        if (!monthlyReportService.isRecordValidForProcess(recordId)) {

            throw new AuraHandledException('You can generate reports only on Allocation with recordType Project');
        }

        /*if (monthlyReportService.isProjectParen(recordId)) {
            throw new AuraHandledException('You can not generate reports on Allocation with Project Record Type \'Parent\'');
        }*/

        return new ModalInfo(monthlyReportService.getMonthsNames(), monthlyReportService.getYearsRange(recordId), Date.today());
    }

    @AuraEnabled
    public static Map<String, List<SObject>> getMatrix(Id recordId){
        Map<String, List<SObject>> result = new Map<String, List<SObject>>();

        if (String.isBlank(recordId)) {
            throw new AuraHandledException('Not valid recordId arrived');
        }

        if (!monthlyReportService.isRecordValidForProcess(recordId)) {
            throw new AuraHandledException('You can generate reports only on Allocation with recordType Project');
        }

        //Project__c project = projectSelector.getWithChildren(recordId);
        Project__c project = [SELECT Id, Name FROM Project__c WHERE Id = :recordId];

        List<Allocation__c> allocations = allocationSelector.getCurrentWithStatusActiveAndFinishedByProjectId(recordId);

        if (allocations.isEmpty()) {
            throw new AuraHandledException('No matching allocations found');
        }

        /*if (project.Projects__r.isEmpty()) {
            result.put('projects', new List<SObject>{project});
        } else {
            result.put('parentProject', new List<SObject>{project});
            result.put('projects', project.Projects__r);
            result.get('projects').add(project);
        }*/

        result.put('projects', new List<SObject>{project});
        result.put('allocations', allocations);

        return result;
    }

    @AuraEnabled
    public static RelatedListInfo getRelatedListInitData(Id projectId){
        if (String.isBlank(projectId)) {

            throw new AuraHandledException('Not valid recordId arrived'); //TODO: change to custom label if needed, or make as const
        }

        return new RelatedListInfo(monthlyReportService.getMonthsNames(),
                                   monthlyReportService.getYearsRange(projectId),
                                   Date.today(),
                                   monthlyReportService.getReportsForRelatedList(projectId));
    }

    @AuraEnabled
    public static Result createReport(List<String> mapIds, String projectId, String month, String year){

        //TODO change name for "mapIds" to more clear name
        if (mapIds == null || mapIds.isEmpty()) {
            throw new AuraHandledException('Sorry, but you have to select Projects or Allocations');
        }
        if (month == 'choose one...' || year == 'choose one...') {
            throw new AuraHandledException('Sorry, but you have to select period of report');
        }
        if (String.isBlank(projectId)){
            throw new AuraHandledException('Sorry, wrong data arrived');
        }

        return monthlyReportService.createReports(new Set<String>(mapIds), projectId, month, year);
    }
//    @AuraEnabled
//    public static Result testGenerate( String allocationsIds, String projectId, String month, String year, List<Date> dates){
//        List<String> allocationIds = allocationsIds.split(',');
//        if (allocationIds == null || allocationIds.isEmpty()) {
//            throw new AuraHandledException('Sorry, but you have to select Allocations');
//        }
//        if (month == 'choose one...' || year == 'choose one...') {
//            throw new AuraHandledException('Sorry, but you have to select period of report');
//        }
//        if (String.isBlank(projectId)){
//            throw new AuraHandledException('Sorry, wrong data arrived');
//        }
//        System.debug('allocationIds---> ' + allocationIds);
//        System.debug('projectId---> ' + projectId);
//        System.debug('month---> ' + month);
//        System.debug('year---> ' + year);
//        System.debug('dates---> ' + dates);
//        return monthlyReportCreatorService.createReportsFromComponent(new Set<String>(allocationIds), projectId, month, year, dates);
//    }
//    @AuraEnabled
//    public static Result getInformationAboutReports(List<String> mapIds, String projectId, String month, String year){
//
//        //TODO change name for "mapIds" to more clear name
//        if (mapIds == null || mapIds.isEmpty()) {
//            throw new AuraHandledException('Sorry, but you have to select Projects or Allocations');
//        }
//        if (month == 'choose one...' || year == 'choose one...') {
//            throw new AuraHandledException('Sorry, but you have to select period of report');
//        }
//        if (String.isBlank(projectId)){
//            throw new AuraHandledException('Sorry, wrong data arrived');
//        }
//
//
//        return monthlyReportService.createReports(new Set<String>(mapIds), projectId, month, year);
//    }

    @AuraEnabled
    public static Result tryToGenerateReport(Id recordId, List<String> months, List<String> years) {
        if(String.isBlank(recordId) || months.isEmpty() || years.isEmpty()) {

            return new Result(false, 'wrong data arrived');
        }

        return monthlyReportService.createReports(recordId, months, years);
    }

    @AuraEnabled
    public static String updateReports(List<Monthly_Report__c> recordsList){

        if (recordsList == null || recordsList.isEmpty()) {
            throw new AuraHandledException('Sorry, but you have to select Project');
        }

        return monthlyReportService.updateReportsFromRelatedList(recordsList);
    }

//    @AuraEnabled
//    public static InfoAboutReportAndAllocation getInfoAboutAllocations(List<String> allocationsIds, String projectId, String month, String year) {
//        if (allocationsIds == null || allocationsIds.isEmpty()) {
//            throw new AuraHandledException('Sorry, but you have to select Allocations');
//        }
//        if (month == 'choose one...' || year == 'choose one...') {
//            throw new AuraHandledException('Sorry, but you have to select period of report');
//        }
//        if (String.isBlank(projectId)) {
//            throw new AuraHandledException('Sorry, wrong data arrived');
//        }
//
//        return monthlyReportService.getInfoAboutReports(allocationsIds, projectId, month, year);
//    }

    public class ModalInfo {
        @AuraEnabled
        public List<String> months { get; set; }
        @AuraEnabled
        public List<String> years { get; set; }
        @AuraEnabled
        public Date today { get; set; }
        public ModalInfo(List<String> months, List<String> years, Date today) {
            this.months = months;
            this.years = years;
            this.today = today;
        }
    }

    public class RelatedListInfo {
        @AuraEnabled
        public List<String> months { get; set; }
        @AuraEnabled
        public List<String> years { get; set; }
        @AuraEnabled
        public Date today { get; set; }
        @AuraEnabled
        public MonthlyReportService.DataTableWrapper dataTable { get; set; }
        public RelatedListInfo(List<String> months,
                               List<String> years,
                               Date today,
                               MonthlyReportService.DataTableWrapper dataTable) {
            this.months = months;
            this.years = years;
            this.today = today;
            this.dataTable = dataTable;
        }
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

//    public class InfoAboutReportAndAllocation{
//        @AuraEnabled
//        public List<Allocation__c> withoutReports = new List<Allocation__c>();
//        @AuraEnabled
//        public List<Allocation__c> withOneReport = new List<Allocation__c>();
//        @AuraEnabled
//        public List<Allocation__c> withMultipleReports = new List<Allocation__c>();
//    }
}