@IsTest
public with sharing class LA_BP_FinancialReportManagerTest {
    private static final String TEST_NAME = 'TEST_NAME';
    private static final Integer YEAR = 2020;
    private static  List<Business_Unit__c> businessUnits;
    private static  Business_Unit__c businessUnit;
    private static  Financial_Report__c financialReport;
    private static  List<Financial_Report__c> newFinancialReports = new List<Financial_Report__c>();

    @TestSetup
    static void setup() {
        insert LA_BP_TestSetup.getBusinessUnit(TEST_NAME);
    }

    @IsTest
    static void getNewFinancialReportTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        Test.stopTest();

        financialReport = LA_BP_FinancialReportManager.getNewFinancialReport(businessUnit.Id, YEAR);

        Date startDate = Date.newInstance(YEAR, LA_BP_Constants.JANUARY_MONTH, LA_BP_Constants.FIRST_DAY_OF_MONTH);
        Date endDate = Date.newInstance(YEAR, LA_BP_Constants.DECEMBER_MONTH, LA_BP_Constants.LAST_DAY_OF_DECEMBER);

        System.assertEquals(businessUnit.Id, financialReport.Cost_Center__c);
        System.assertEquals(startDate, financialReport.StartDate__c);
        System.assertEquals(endDate, financialReport.EndDate__c);
        System.assertEquals(LA_BP_Constants.DRAFT, financialReport.Status__c);
    }

    @IsTest
    static void getLastFinancialReportTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        Test.stopTest();

        Integer maxVersion = 5;
        Integer version;
        for (version = 1; version <= maxVersion; version++ ) {
            Financial_Report__c newFinancialReport = LA_BP_FinancialReportManager.getNewFinancialReport(businessUnit.Id, YEAR);
            newFinancialReport.Report_Version_Number__c = version;
            newFinancialReports.add(newFinancialReport);
        }


        Financial_Report__c lastFinancialReport = LA_BP_FinancialReportManager.getLastFinancialReport(newFinancialReports);
        System.assertEquals(maxVersion, lastFinancialReport.Report_Version_Number__c);
    }

    @IsTest
    static void getFinancialReportByYearTest() {

        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];

        Integer maxVersion = 5;
        Integer version;
        for (version = 1; version <= maxVersion; version++ ) {
            Financial_Report__c newFinancialReport = LA_BP_FinancialReportManager.getNewFinancialReport(businessUnit.Id, YEAR);
            newFinancialReport.Report_Version_Number__c = version;
            newFinancialReports.add(newFinancialReport);
        }

        insert newFinancialReports;

        List<Financial_Report__c> financialReportsByYear = LA_BP_FinancialReportManager.getFinancialReportsByYear(YEAR,
                        new List<Id>{businessUnit.Id},
                        new List<String>{LA_BP_Constants.DRAFT});
        Test.stopTest();

        System.assertEquals(5, financialReportsByYear.size());

    }
}