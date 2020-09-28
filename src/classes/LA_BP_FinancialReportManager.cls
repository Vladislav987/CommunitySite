public with sharing class LA_BP_FinancialReportManager {


    public static Financial_Report__c getNewFinancialReport(Id costCenterId, Integer year) {
        Financial_Report__c newFinancialReport = new Financial_Report__c();
        newFinancialReport.Cost_Center__c = costCenterId;
        newFinancialReport.StartDate__c = Date.newInstance(year, LA_BP_Constants.JANUARY_MONTH, LA_BP_Constants.FIRST_DAY_OF_MONTH);
        newFinancialReport.EndDate__c = Date.newInstance(year, LA_BP_Constants.DECEMBER_MONTH, LA_BP_Constants.LAST_DAY_OF_DECEMBER);
        newFinancialReport.Status__c = LA_BP_Constants.DRAFT;
        newFinancialReport.Report_Version_Number__c = 0;

        return newFinancialReport;
    }

    public static Financial_Report__c getLastFinancialReport(List<Financial_Report__c> financialReports) {
        Financial_Report__c lastFinancialReport;
        if(financialReports.size() > 0) {
            lastFinancialReport = financialReports[0];
        }

        for(Financial_Report__c finReport : financialReports) {
            if(lastFinancialReport.Report_Version_Number__c < finReport.Report_Version_Number__c) {
                lastFinancialReport = finReport;
            }
        }

        return lastFinancialReport;
    }

    public static List<Financial_Report__c> getFinancialReportsByYear(Integer year, List<Id> costCenterIds, List<String> statuses) {
        Date minDate = Date.newInstance(year, LA_BP_Constants.JANUARY_MONTH, LA_BP_Constants.FIRST_DAY_OF_MONTH);
        Date maxDate = Date.newInstance(year,LA_BP_Constants.DECEMBER_MONTH,LA_BP_Constants.LAST_DAY_OF_DECEMBER);
        List<Financial_Report__c> financialReports = LA_BP_DataSelector.getFinancialReports(costCenterIds, statuses);
        List<Financial_Report__c> filteredReportsByYear = new List<Financial_Report__c>();

        for(Financial_Report__c financialReport : financialReports) {
            if(financialReport.StartDate__c == minDate && financialReport.EndDate__c == maxDate) {
               filteredReportsByYear.add(financialReport);
            }
        }

        return financialReports;
    }
}