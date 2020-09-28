public with sharing class FinancialPlanningYearController {

    @AuraEnabled
    public static FinancialPlanningYearTableWrapper getFinancialPlanningYearData(Decimal pageNumber, Decimal pageSize) {

        Integer pSize = (Integer) pageSize;
        Integer pNumber = (Integer) pageNumber;

        Integer offset = (pNumber - 1) * pSize;

        Integer totalRecords = [SELECT COUNT() FROM Financial_Planning_Year__c];
        if (totalRecords == 0) {
            totalRecords = 2;
        }
        Integer recordEnd = pSize * pNumber;
        createCurrentAndFutureYear();
        FinancialPlanningYearTableWrapper planningYearTableWrapper = new FinancialPlanningYearTableWrapper();
        planningYearTableWrapper.pageSize = pSize;
        planningYearTableWrapper.currentYear = getCurrentYear();
        planningYearTableWrapper.nextYear = planningYearTableWrapper.currentYear + 1;
        planningYearTableWrapper.pageNumber = pNumber;
        planningYearTableWrapper.recordStart = offset + 1;
        planningYearTableWrapper.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        planningYearTableWrapper.totalRecords = totalRecords;
        planningYearTableWrapper.financialPlanningYearList = getFinancialPlanningYears(pSize, offset);
        return planningYearTableWrapper;
    }

    @AuraEnabled
    public static List<Financial_Planning_Year__c> getFinancialPlanningYears(Integer pSize, Integer offSet) {
        List<Financial_Planning_Year__c> financialPlanningYears = [
                SELECT  Id,
                        Year__c,
                        Start_Planing_Date__c,
                        End_Planning_Date__c
                FROM    Financial_Planning_Year__c
                ORDER BY Year__c DESC
                LIMIT   :pSize
                OFFSET  :offSet
        ];

        if (!financialPlanningYears.isEmpty()) {
            financialPlanningYears = setDateForPastYear(financialPlanningYears);
        }
        return financialPlanningYears;
    }

    @AuraEnabled
    public static Integer getCurrentYear() {
        return System.Today().year();
    }

    @AuraEnabled
    public static List<Financial_Planning_Year__c> createYearIfEmptyList(Integer currentYear) {
        List<Financial_Planning_Year__c> financialPlanningYears = new List<Financial_Planning_Year__c>();
        Financial_Planning_Year__c futureFinYear = new Financial_Planning_Year__c(Year__c = currentYear+1, Start_Planing_Date__c = null, End_Planning_Date__c = null);
        financialPlanningYears.add(futureFinYear);
        Financial_Planning_Year__c currentFinYear = new Financial_Planning_Year__c(Year__c = currentYear, Start_Planing_Date__c = null, End_Planning_Date__c = null);
        financialPlanningYears.add(currentFinYear);
        insert financialPlanningYears;
        return financialPlanningYears;
    }

    @AuraEnabled
    public static List<Financial_Planning_Year__c> setDateForPastYear(List<Financial_Planning_Year__c> financialPlanningYears) {
        Integer currentYear = System.Today().year();
        List<Financial_Planning_Year__c> financialPlanningYearsForUpdate = new List<Financial_Planning_Year__c>();
        for (Financial_Planning_Year__c financialPlanningYear : financialPlanningYears) {

            if (financialPlanningYear.Year__c < currentYear) {

                if (financialPlanningYear.Start_Planing_Date__c == null) {
                    Date startDate = Date.newInstance((Integer) financialPlanningYear.Year__c, 1, 1);
                    Time startTime = Time.newInstance(0, 0, 0, 0);
                    Datetime startDateTime = Datetime.newInstanceGmt(startDate, startTime);
                    financialPlanningYear.Start_Planing_Date__c = startDateTime;
                }

                if (financialPlanningYear.End_Planning_Date__c == null) {
                    Date endDate = Date.newInstance((Integer) financialPlanningYear.Year__c, 12, 31);
                    Time endTime = Time.newInstance(23, 59, 0, 0);
                    Datetime endDateTime = Datetime.newInstanceGmt(endDate, endTime);
                    financialPlanningYear.End_Planning_Date__c = endDateTime;
                }

                financialPlanningYearsForUpdate.add(financialPlanningYear);
            }
        }

        if (!financialPlanningYearsForUpdate.isEmpty()) {
            update financialPlanningYearsForUpdate;
        }
        return financialPlanningYears;
    }
    @AuraEnabled
    public static Boolean updateFinancialPlanningYear(Financial_Planning_Year__c financialPlanningYear) {
        if (financialPlanningYear != null) {
            if (financialPlanningYear.Start_Planing_Date__c == null) {
                financialPlanningYear.Start_Planing_Date__c = getCurrentDateTime();
            }
            financialPlanningYear.End_Planning_Date__c = null;
            update financialPlanningYear;
            return true;
        }

        return false;
    }

    @AuraEnabled
    public static Boolean endFinancialPlanningYear(Financial_Planning_Year__c financialPlanningYear) {
        if (financialPlanningYear != null) {
            financialPlanningYear.End_Planning_Date__c = getCurrentDateTime();
            update financialPlanningYear;
            return true;
        }

        return false;
    }

    @AuraEnabled
    public static Boolean cancelFinancialPlanningYear(Financial_Planning_Year__c financialPlanningYear) {
        if (financialPlanningYear != null) {
            financialPlanningYear.Start_Planing_Date__c = null;
            update financialPlanningYear;
            return true;
        }

        return false;
    }

    @AuraEnabled
    public static Datetime getCurrentDateTime() {
        Datetime dtNow = Datetime.now();
        String dtNowAsStringInLocalTZ = dtNow.format('yyyy-MM-dd\'T\'HH:mm:ss',UserInfo.getTimeZone().getID());
        dtNowAsStringInLocalTZ += '.000Z';
        dtNowAsStringInLocalTZ = '"'+dtNowAsStringInLocalTZ+'"';
        Datetime dtNowInLocalTZ = (Datetime)JSON.deserialize(dtNowAsStringInLocalTZ, Datetime.class);
        return dtNowInLocalTZ;
    }

    public static void createCurrentAndFutureYear() {
        Integer currentYear = getCurrentYear();
        Integer futureYear = currentYear + 1;
        List<Financial_Planning_Year__c> finPlanningYearsForInsert = new List<Financial_Planning_Year__c>();

        if (checkForSelectedYear(currentYear) == 0) {
            finPlanningYearsForInsert.add(createSelectedYear(currentYear));
        }

        if (checkForSelectedYear(futureYear) == 0) {
            finPlanningYearsForInsert.add(createSelectedYear(futureYear));
        }

        if (!finPlanningYearsForInsert.isEmpty()) {
            insert finPlanningYearsForInsert;
        }
    }

    public static Financial_Planning_Year__c createSelectedYear(Integer selectedYear) {
        Financial_Planning_Year__c currentFinYear = new Financial_Planning_Year__c(Year__c = selectedYear, Start_Planing_Date__c = null, End_Planning_Date__c = null);
        return currentFinYear;
    }


    public static Integer checkForSelectedYear(Integer selectedYear) {
        return [
                SELECT  COUNT()
                FROM    Financial_Planning_Year__c
                WHERE   Year__c = : selectedYear
        ];
    }

    public static void checkForAvailableNextYear(Financial_Planning_Year__c financialPlanningYear) {
        Integer futureYear = getCurrentYear() + 1;
        if (financialPlanningYear.Year__c == getCurrentYear() + 1) {
            insert createSelectedYear(futureYear + 1);
        }
    }



    public class FinancialPlanningYearTableWrapper {
        @AuraEnabled
        public Integer pageSize { get; set; }
        @AuraEnabled
        public Integer currentYear { get; set; }
        @AuraEnabled
        public Integer nextYear { get; set; }
        @AuraEnabled
        public Integer pageNumber { get; set; }
        @AuraEnabled
        public Integer totalRecords { get; set; }
        @AuraEnabled
        public Integer recordStart { get; set; }
        @AuraEnabled
        public Integer recordEnd { get; set; }
        @AuraEnabled
        public List<Financial_Planning_Year__c> financialPlanningYearList { get; set; }
    }
}