public with sharing class MonthlyReportUpdateBatch implements Database.Batchable<TimeEntryWrapper.TimeEntry>, Database.Stateful {

    private String reportPeriod;
    private List<TimeEntryWrapper.TimeEntry> timeEntries;
    private Map<Decimal, Map<Decimal, Monthly_Report__c>> reportMap;
    private Set<Monthly_Report__c> reportsToUpdate;


    public MonthlyReportUpdateBatch(List<TimeEntryWrapper.TimeEntry> timeEntries, String reportPeriod) {
        this.timeEntries = timeEntries;
        this.reportPeriod = reportPeriod;
        this.reportsToUpdate = new Set<Monthly_Report__c>();
        this.initReportMap();
    }

    public Iterable<TimeEntryWrapper.TimeEntry> start(Database.BatchableContext param1) {
        return timeEntries;
    }

    public void execute(Database.BatchableContext context, List<TimeEntryWrapper.TimeEntry> entries) {
        for (TimeEntryWrapper.TimeEntry timeEntry : entries) {
            Decimal redmineProjectId = timeEntry.getProjectId();
            Decimal redmineUserId = timeEntry.getUserId();

            if (isMonthlyReportExists(redmineProjectId, redmineUserId)) {
                Monthly_Report__c report = reportMap.get(redmineProjectId).get(redmineUserId);
                report.Fact_hours__c += timeEntry.getHours();

                reportsToUpdate.add(report);
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        update new List<Monthly_Report__c>(reportsToUpdate);
    }

    private void initReportMap() {
        reportMap = new Map<Decimal, Map<Decimal, Monthly_Report__c>>();

        for (Monthly_Report__c report : [
                SELECT Id
                        , Fact_hours__c
                        , Project__r.Redmine_ID__c
                        , Contractor__r.Redmine_ID__c
                        , Monthly_Report_Period__c
                FROM Monthly_Report__c
                WHERE Monthly_Report_Period__c = :this.reportPeriod
                AND Project__r.Redmine_ID__c != NULL
                AND Contractor__r.Redmine_ID__c != NULL
        ]) {
            Decimal projectRedmineId = report.Project__r.Redmine_ID__c;
            Decimal contractorRedmineId = report.Contractor__r.Redmine_ID__c;
            report.Fact_hours__c = 0;

            if (reportMap.keySet().contains(projectRedmineId)) {
                Map<Decimal, Monthly_Report__c> reportsByProject = reportMap.get(projectRedmineId);
                reportsByProject.put(contractorRedmineId, report);
            } else {
                Map<Decimal, Monthly_Report__c> reportsByProject = new Map<Decimal, Monthly_Report__c>();
                reportsByProject.put(contractorRedmineId, report);
                reportMap.put(projectRedmineId, reportsByProject);
            }
        }
    }

    private Boolean isMonthlyReportExists(Decimal redmineProjectId, Decimal redmineUserId) {
        return reportMap.get(redmineProjectId) != null && reportMap.get(redmineProjectId).get(redmineUserId) != null;
    }
}