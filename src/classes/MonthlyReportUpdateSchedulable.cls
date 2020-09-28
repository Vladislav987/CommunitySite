public with sharing class MonthlyReportUpdateSchedulable implements Schedulable {

    public static final String REPORT_PERIOD_MONTH_FORMAT = 'MMMMM YYYY';
    public static final String REDMINE_REST_API_DATE_FORMAT = 'yyyy-MM-dd';

    public void execute(SchedulableContext context) {
        Date d = Date.today();
        d = d.addMonths(-1);
        Map<String, String> params = new Map<String, String>();
        params.put('reportPeriod', DateUtils.getMonth(d, REPORT_PERIOD_MONTH_FORMAT));
        params.put('fromDate', DateUtils.getFirstDayOfMonth(d, REDMINE_REST_API_DATE_FORMAT));
        params.put('toDate', DateUtils.getLastDayOfMonth(d, REDMINE_REST_API_DATE_FORMAT));

        System.enqueueJob(new MonthlyReportUpdateQueueable(params));
    }
}