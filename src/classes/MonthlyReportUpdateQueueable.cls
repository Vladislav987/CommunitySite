public with sharing class MonthlyReportUpdateQueueable implements Queueable, Database.AllowsCallouts {

    List<TimeEntryWrapper.TimeEntry> fetchedTimeEntries;
    Map<String, String> params;

    public MonthlyReportUpdateQueueable(Map<String, String> params) {
        this.params = params;
    }

    public MonthlyReportUpdateQueueable(List<TimeEntryWrapper.TimeEntry> fetchedTimeEntries, Map<String, String> params) {
        this(params);
        this.fetchedTimeEntries = fetchedTimeEntries;
    }

    public void execute(QueueableContext context) {
        RedmineRequestService service = new RedmineRequestService();
        service.fetchTimeEntriesForPeriod(this.fetchedTimeEntries, this.params);
    }
}