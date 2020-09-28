/**
 * Created by Mychailo Hamdzii on 24.04.2019.
 */
@IsTest
public with sharing class MonthlyReportControllerTest {
    private static final Date TEST_DATE_START = Date.newInstance(1900, 1, 1);
    private static final Date TEST_DATE_END = Date.today();
    private static final Date TEST_DATE_IN_RANGE = Date.today().addMonths(1);
    private static final String AURA_HANDLED_EXCEPTION_TYPE_NAME = 'System.AuraHandledException';
    private static final Id ALLOCATION_RECORD_TYPE_PROJECT_ID =
        Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Project').getRecordTypeId();
    private static final Id ALLOCATION_RECORD_TYPE_BOOKING_ID =
        Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Booking').getRecordTypeId();

    @TestSetup
    private static void setup() {
        Project__c project = new Project__c();
        project.Name = 'project name';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.Start_date__c = TEST_DATE_START;
        project.End_date__c = TEST_DATE_END;

        insert project;

        Contractor__c contractor1 = new Contractor__c();
        contractor1.Name = 'zdarova';
        contractor1.Resource_Type__c = 'SFDC Developer';
        contractor1.Resource_Level__c = 'Trainee';

        insert contractor1;

        Contractor__c contractor2 = new Contractor__c();
        contractor2.Name = 'zdarova2';
        contractor2.Resource_Type__c = 'SFDC Developer';
        contractor2.Resource_Level__c = 'Trainee';

        insert contractor2;

        List<Allocation__c> allocations = new List<Allocation__c>();
        Allocation__c allocation1 = new Allocation__c();
        allocation1.Project__c = project.Id;
        allocation1.Status__c = 'Active';
        allocation1.Contractor__c = contractor1.Id;
        allocation1.Allocation__c = 100;
        allocation1.Allocation_Type__c = 'Billable';
        allocation1.Start_date__c = TEST_DATE_START;
        allocation1.End_date__c = TEST_DATE_END;
        allocation1.RecordTypeId = ALLOCATION_RECORD_TYPE_PROJECT_ID;

        Allocation__c allocation2 = new Allocation__c();
        allocation2.Project__c = project.Id;
        allocation2.Contractor__c = contractor2.Id;
        allocation2.Status__c = 'Active';
        allocation2.Allocation__c = 100;
        allocation2.Allocation_Type__c = 'Billable';
        allocation2.Start_date__c = TEST_DATE_START;
        allocation2.End_date__c = TEST_DATE_END;
        allocation2.RecordTypeId = ALLOCATION_RECORD_TYPE_BOOKING_ID;

        allocations.add(allocation1);
        allocations.add(allocation2);

        insert allocations;

        List<Monthly_Report__c> monthly_reports = new List<Monthly_Report__c>();

        Monthly_Report__c monthly_report1 = new Monthly_Report__c();
        monthly_report1.Project__c = project.Id;
        monthly_report1.Contractor__c = contractor1.Id;
        monthly_report1.Fact_hours__c = 25;
        monthly_report1.Monthly_Report_Start_Date__c = system.today();

        Monthly_Report__c monthly_report2 = new Monthly_Report__c();
        monthly_report2.Project__c = project.Id;
        monthly_report2.Contractor__c = contractor2.Id;
        monthly_report2.Fact_hours__c = 35;
        monthly_report2.Monthly_Report_Start_Date__c = system.today();

        Monthly_Report__c monthly_report3 = new Monthly_Report__c();
        monthly_report3.Project__c = project.Id;
        monthly_report3.Contractor__c = contractor1.Id;
        monthly_report3.Fact_hours__c = 45;
        monthly_report3.Monthly_Report_Start_Date__c = system.today();

        monthly_reports.add(monthly_report1);
        monthly_reports.add(monthly_report2);
        monthly_reports.add(monthly_report3);

        insert monthly_reports;
    }

    @IsTest
    private static void getInitDataTestCorrectFlow() {
        Project__c project = [
            SELECT Id
            FROM Project__c
            LIMIT 1
        ];
        Test.startTest();

        MonthlyReportController.ModalInfo info = MonthlyReportController.getInitData(project.Id);

        Test.stopTest();
        System.assertEquals(String.valueOf(TEST_DATE_START.year()), info.years[0]);
    }

    @isTest
    private static void getMatrix(){
        Project__c project = [
                SELECT Id
                FROM Project__c
                LIMIT 1
        ];

        Test.startTest();

        MonthlyReportController.getMatrix(project.Id);

        Test.stopTest();
    }

    @isTest
    private static void getRelatedListInitData(){
        List<Project__c> project = [
                SELECT Id
                FROM Project__c
        ];
        if (!project.isEmpty()) {

            Test.startTest();

            MonthlyReportController.RelatedListInfo relatedlistdata = MonthlyReportController.getRelatedListInitData(project[0].Id);

            Test.stopTest();
            system.assertEquals(relatedlistdata.dataTable.recordsList.size(), 3);
        }
    }

    @IsTest
    private static void getRelatedListInitDataTestIncorrectFlowEmptyId() {
        Account acc = new Account(Name = 'acc name 1');

        String exceptionTypeName;
        Test.startTest();

        try {
            MonthlyReportController.RelatedListInfo relatedlistdata = MonthlyReportController.getRelatedListInitData(acc.Id);
        } catch (Exception e) {
            exceptionTypeName = e.getTypeName();
        }

        Test.stopTest();
        System.assertEquals(AURA_HANDLED_EXCEPTION_TYPE_NAME, exceptionTypeName);
    }

    /*@IsTest
    private static void getRelatedListInitDataTestIncorrectFlowBadRecordType() {
        Project__c project = [
                SELECT Id
                FROM Project__c
                LIMIT 1
        ];
        Allocation__c allocation = [
                SELECT Id
                FROM Allocation__c
                WHERE Project__c = :project.Id
                AND RecordTypeId = :ALLOCATION_RECORD_TYPE_BOOKING_ID
        ];
        String exceptionTypeName;
        Test.startTest();

        try {
            MonthlyReportController.RelatedListInfo relatedlistdata = MonthlyReportController.getRelatedListInitData(allocation.Id);
        } catch (Exception e) {
            exceptionTypeName = e.getTypeName();
        }

        Test.stopTest();
        System.assertEquals(AURA_HANDLED_EXCEPTION_TYPE_NAME, exceptionTypeName);
    }*/

    @isTest
    private static void updateReports(){
        List<Monthly_Report__c> reports = [
                SELECT Id, Fact_hours__c
                FROM Monthly_Report__c
        ];
        Double facthours = 50;
        if (!reports.isEmpty()) {
            for (Monthly_Report__c report : reports){
                report.Fact_hours__c = facthours;
            }
            Test.startTest();

            MonthlyReportController.updateReports(reports);

            Test.stopTest();
            reports = [
                    SELECT Id, Fact_hours__c
                    FROM Monthly_Report__c
            ];
            system.assertEquals(reports[0].Fact_hours__c, facthours);
        }
    }

    @isTest
    private static void updateReportsTestIncorrectFlowEmptyList(){
        List<Monthly_Report__c> reports = new List<Monthly_Report__c>();
        String exceptionTypeName;

        Test.startTest();
        try {
            MonthlyReportController.updateReports(reports);
        }
        catch (Exception e) {
            exceptionTypeName = e.getTypeName();
        }

        Test.stopTest();
        System.assertEquals(AURA_HANDLED_EXCEPTION_TYPE_NAME, exceptionTypeName);
    }

    @IsTest
    private static void getInitDataTestIncorrectFlowEmptyId() {
        Account acc = new Account(Name = 'acc name 1');

        String exceptionTypeName;
        Test.startTest();

        try {
            MonthlyReportController.ModalInfo info = MonthlyReportController.getInitData(acc.Id);
        } catch (Exception e) {
            exceptionTypeName = e.getTypeName();
        }

        Test.stopTest();
        System.assertEquals(AURA_HANDLED_EXCEPTION_TYPE_NAME, exceptionTypeName);
    }

    @IsTest
    private static void getInitDataTestIncorrectFlowBadRecordType() {
        Project__c project = [
            SELECT Id
            FROM Project__c
            LIMIT 1
        ];
        Allocation__c allocation = [
            SELECT Id
            FROM Allocation__c
            WHERE Project__c = :project.Id
            AND RecordTypeId = :ALLOCATION_RECORD_TYPE_BOOKING_ID
        ];
        String exceptionTypeName;
        Test.startTest();

        try {
            MonthlyReportController.ModalInfo info = MonthlyReportController.getInitData(allocation.Id);
        } catch (Exception e) {
            exceptionTypeName = e.getTypeName();
        }

        Test.stopTest();
        System.assertEquals(AURA_HANDLED_EXCEPTION_TYPE_NAME, exceptionTypeName);
    }

//    @IsTest
//    private static void tryToGenerateReportCorrectFlow() {
//        Project__c project = [
//            SELECT Id
//            FROM Project__c
//            LIMIT 1
//        ];
//        Integer numOfAllocationWithProjectRecordType = [
//            SELECT COUNT()
//            FROM Allocation__c
//            WHERE Project__c = :project.Id
//            AND RecordTypeId = :ALLOCATION_RECORD_TYPE_PROJECT_ID
//        ];
//        Integer numOfMonthlyReportsBefore = [
//            SELECT COUNT()
//            FROM Monthly_Report__c
//            WHERE Project__c = :project.Id
//        ];
//        List<String> months = new List<String>{ String.valueOf(TEST_DATE_IN_RANGE.month()) };
//        List<String> years = new List<String>{ String.valueOf(TEST_DATE_IN_RANGE.year()) };
//        Test.startTest();
//
//        MonthlyReportController.Result result = MonthlyReportController.tryToGenerateReport(project.Id, months, years);
//
//        Test.stopTest();
//        Integer numOfMonthlyReportsAfter = [
//            SELECT COUNT()
//            FROM Monthly_Report__c
//            WHERE Project__c = :project.Id
//        ];
//
//        System.assert(result.isSuccessful);
//        System.assertNotEquals(numOfMonthlyReportsBefore, numOfMonthlyReportsAfter);
//        System.assertEquals(numOfAllocationWithProjectRecordType, numOfMonthlyReportsAfter);
//    }

    @IsTest
    private static void tryToGenerateReportIncorrectFlow() {
        Project__c project = [
            SELECT Id
            FROM Project__c
            LIMIT 1
        ];
        List<String> months = new List<String>();
        List<String> years = new List<String>{
            String.valueOf(TEST_DATE_IN_RANGE.year())
        };
        MonthlyReportController.Result result;
        Test.startTest();

        result = MonthlyReportController.tryToGenerateReport(project.Id, months, years);

        Test.stopTest();
        System.assert(!result.isSuccessful);
    }
}