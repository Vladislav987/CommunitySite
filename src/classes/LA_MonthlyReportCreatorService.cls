public without sharing class LA_MonthlyReportCreatorService {
    private static final SObjectField MONTH_NAMES = Schema.Monthly_Report__c.Month_Names__c;
    private static MonthlyReportService MONTHLY_REPORT_SERVICE = new MonthlyReportService();


    AllocationSelector allocationSelector = new AllocationSelector();
    private static final String CODE_DEFAULT = 'UA';
    private static final Id MONTHLY_REPORT_RECORD_TYPE_USUAL_ID =
            Schema.Monthly_Report__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Monthly_Report_Usual').getRecordTypeId();


    private static Map<String, String> mapStationByCode {
        get {
            if (mapStationByCode == null) {
                mapStationByCode = getMapStationByCode();
            }

            return mapStationByCode;
        }

        private set;
    }

    public LA_MonthlyReportGeneratorController.InfoAboutReportAndAllocation getInfoAboutReports(List<String> allocationIds, Id mainProjectId, String month, String year) {
        String period = month + ' ' + year;
        List<Allocation__c> allocations = [
                SELECT Id,
                        Name, Contractor__r.Name,
                        Expected_Rate_Daily__c,
                        CurrencyIsoCode,
                        Allocation_Type__c, (SELECT Id, Budget_transaction_item__c FROM Monthly_Reports__r WHERE Project__c = :mainProjectId AND Monthly_Report_Period__c = :period)
                FROM Allocation__c
                WHERE Id IN :allocationIds
        ];
        LA_MonthlyReportGeneratorController.InfoAboutReportAndAllocation result = new LA_MonthlyReportGeneratorController.InfoAboutReportAndAllocation();

        for (Allocation__c allocation : allocations) {
            if (allocation.Monthly_Reports__r.size() == 0) {
                result.withoutReports.add(allocation);
            } else if (allocation.Monthly_Reports__r.size() == 1) {
                if (allocation.Monthly_Reports__r[0].Budget_transaction_item__c != null) {
                    result.withBudgetTransactions.add(allocation);
                } else {
                    result.withOneReport.add(allocation);
                }
            } else {
                result.withMultipleReports.add(allocation);
            }
        }
        return result;
    }

    public LA_MonthlyReportGeneratorController.Result createReportsFromComponent(Set<String> allocationIds, Id mainProjectId, String month, String year, List<Date> dates) {
        List<Monthly_Report__c> monthlyReports = new List<Monthly_Report__c>();
        String period = month + ' ' + year;
        List<Allocation__c> allocations = allocationSelector.getWithDataByIds(allocationIds);
        List<Monthly_Report__c> oldMonthlyReports = [SELECT Id FROM Monthly_Report__c WHERE Allocation__c IN :allocationIds AND Monthly_Report_Period__c = :period AND Project__c = :mainProjectId];
        delete oldMonthlyReports;

        BusinessHours bHours = [SELECT Id FROM BusinessHours WHERE Name = :System.Label.Business_Hours_for_MR];
        User user = [SELECT Id, UserRole.Name, (SELECT Allow_Late_Report_Editing__c FROM Monthly_Report_Editing_Rules__r ORDER BY CreatedDate DESC) FROM User WHERE Id = :UserInfo.getUserId()];

        Date firstDayOfMonth = convertPeriodToDateFormat(period);
        Integer days = MONTHLY_REPORT_SERVICE.getReportBlockingDayForUser();
        Boolean blockPlanHours = (Date.today() > firstDayOfMonth.addDays(days))
                && (user.Monthly_Report_Editing_Rules__r.isEmpty() || !user.Monthly_Report_Editing_Rules__r[0].Allow_Late_Report_Editing__c);
        dates.add(firstDayOfMonth.addMonths(1).addDays(-1));

        Map<String, Map<Date, Holiday>> mapCodeByHolidays = getMapCodeByHolidays(getListHolidays(firstDayOfMonth, firstDayOfMonth.addMonths(1)));
        Integer workingDay = 0;
        Decimal planHours = 0;
        for (Allocation__c allocation : allocations) {
            Date startDayPeriod = firstDayOfMonth;
            String code;
            Map<Date, Holiday> mapHolidays = new Map<Date, Holiday>();
            if (!blockPlanHours) {
                code = mapStationByCode.containsKey(allocation.Contractor__r.Station__c) ?
                        mapStationByCode.get(allocation.Contractor__r.Station__c) : CODE_DEFAULT;

                mapHolidays = mapCodeByHolidays.containsKey(code) ?
                        mapCodeByHolidays.get(code) : new Map<Date, Holiday>();

            }

            for (Date endDayPeriod : dates) {

                if (!blockPlanHours) {
                    workingDay = getNoOfBusinessDaysBetweenDates(bHours, mapHolidays, startDayPeriod, endDayPeriod);
                    planHours = (workingDay * 8) * allocation.Allocation__c / 100;

                }

                Monthly_Report__c report = new Monthly_Report__c();
                report.Contractor__c = allocation.Contractor__c;
                report.Allocation__c = allocation.Id;
                report.Project__c = mainProjectId;
                report.Plan_hours__c = planHours;
                report.CurrencyIsoCode = allocation.Project__r.Account__r.CurrencyIsoCode;
                report.Monthly_Report_Period__c = period;
                report.Monthly_Report_Start_Date__c = startDayPeriod;
                report.Monthly_Report_End_Date__c = endDayPeriod;
                report.RecordTypeId = MONTHLY_REPORT_RECORD_TYPE_USUAL_ID;

                monthlyReports.add(report);

                if (endDayPeriod != endDayPeriod.toStartOfMonth().addMonths(1).addDays(-1)) {
                    startDayPeriod = endDayPeriod.addDays(1);

                } else {
                    startDayPeriod = endDayPeriod;

                }
            }
        }

        if (!monthlyReports.isEmpty()) {
            insert monthlyReports;

        } else {
            return new LA_MonthlyReportGeneratorController.Result(false, 'There is no reports to insert');

        }

        return new LA_MonthlyReportGeneratorController.Result(true, 'Report was successfully created');
    }

    private Date convertPeriodToDateFormat(String periodAsString) {
        Integer year = Integer.valueOf(periodAsString.split(' ').get(1));
        Integer month = convertMonthNameIntoNo(periodAsString.split(' ').get(0));
        Date dateFormat = Date.newInstance(year, month, 1);

        return dateFormat;
    }

    private Integer convertMonthNameIntoNo(String monthName) {
        Integer i = 1;
        for (PicklistEntry entry : MONTH_NAMES.getDescribe().getPicklistValues()) {
            if (entry.getLabel() == monthName) {

                return i;
            }

            i++;
        }

        return null;
    }
    private Map<String, Map<Date, Holiday>> getMapCodeByHolidays(List<Holiday> lstHolidays) {
        Map<String, Map<Date, Holiday>> mapCodeByHolidays = new Map<String, Map<Date, Holiday>>();
        for (Holiday hol : lstHolidays) {
            String code = hol.Name.substring(0, 2);
            if (!mapCodeByHolidays.containsKey(code)) {
                mapCodeByHolidays.put(code, new Map<Date, Holiday>());
            }
            mapCodeByHolidays.get(code).put(hol.ActivityDate, hol);
        }
        return mapCodeByHolidays;
    }

    private List<Holiday> getListHolidays(Date dtStart, Date dtEnd) {
        return [
                SELECT Id, Name, ActivityDate
                FROM Holiday
                WHERE ActivityDate >= :dtStart AND ActivityDate <= :dtEnd
        ];
    }
    private static Map<String, String> getMapStationByCode() {
        Map<String, String> mapStationByCode = new Map<String, String>();
        for (Station_by_Country_prefix__mdt scp : [
                SELECT Id, Country_prefix__c, Station__c
                FROM Station_by_Country_prefix__mdt
        ]) {
            mapStationByCode.put(scp.Station__c, scp.Country_prefix__c);
        }
        return mapStationByCode;
    }
    public Integer getNoOfBusinessDaysBetweenDates(BusinessHours bHours, Map<Date, Holiday> mapHolidays, Date startDay, Date endDay) {
        Integer count = 0;

        Date startDate = startDay;
        Date endDate = endDay;

        System.debug('@@@ mapHolidays: ' + mapHolidays);
        while (startDate <= endDate) {
            if (BusinessHours.isWithin(bHours.Id, startDate) && !mapHolidays.containsKey(startDate)) {
                count++;
            }
            startDate = startDate.addDays(1);
        }
        System.debug('@@@ count: ' + count);

        return count;
    }
}
