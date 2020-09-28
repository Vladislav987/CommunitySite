/**
 * Created by Mychailo Hamdzii on 24.04.2019.
 */
@IsTest
public with sharing class MonthlyReportServiceTest {
    private static final Date TEST_DATE_START = Date.newInstance(1900, 1, 1);
    private static final Date TEST_DATE_END = Date.newInstance(1901, 1, 1);
    private static final Date TEST_DATE_IN_RANGE = Date.newInstance(1900, 2, 2);
    private static final Date TEST_DATE_NOT_IN_RANGE = Date.newInstance(1902, 1, 1);
    private static final Date TEST_SH_END_DATE = Date.parse('01/12/2099');

    private static final String TEST_PERIOD_IN_RANGE = 'February 1900';

    private static final Integer NUMBER_OF_YEARS_FOR_CHOOSE = 2;

    private static final Id ALLOCATION_RECORD_TYPE_PROJECT_ID =
        Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Project').getRecordTypeId();
    private static final Id ALLOCATION_RECORD_TYPE_BOOKING_ID =
        Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Booking').getRecordTypeId();
    static MonthlyReportService MONTHLY_REPORT_SERVICE = new MonthlyReportService();
    private static final Id PROJECT_RECORD_TYPE_COMMERCIAL =
            Schema.Project__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Commercial').getRecordTypeId();
    private static final Id PROJECT_RECORD_TYPE_PARENT_ID =
            Schema.Project__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId();
    private static final Id REPORT_RECORD_TYPE_DETAILED_ID =
            Schema.Monthly_Report__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Monthly_Report_Detailed').getRecordTypeId();
    private static final Id MONTHLY_REPORT_RECORD_TYPE_GENERAL_ID =
            Schema.Monthly_Report__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Monthly_Report_General').getRecordTypeId();
    private static final List<User> systemAdministratorUsers = [SELECT Id FROM User WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'System Administrator') AND IsActive = true];

    @TestSetup
    private static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name='CT_Project Manager'];
        User u = new User(Alias = 'standt', Email='test123987528@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='test123987528@testorg.com');
        insert u;

        Project__c project = new Project__c();
        project.Name = 'project name';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.Start_date__c = TEST_DATE_START;
        project.End_date__c = TEST_DATE_END;
        project.RecordTypeId = PROJECT_RECORD_TYPE_COMMERCIAL;
        project.Project_Manager__c = u.Id;
        project.CurrencyIsoCode = 'USD';

        insert project;

        Contractor__c contractor = new Contractor__c();
        contractor.Name = 'zdarova';
        contractor.Resource_Type__c = 'SFDC Developer';
        contractor.Salary__c = 500;
        contractor.Resource_Level__c = 'Trainee';
        contractor.CurrencyIsoCode = 'RUB';

        insert contractor;
        Allocation__c allocation = new Allocation__c();
        allocation.Project__c = project.Id;
        allocation.Contractor__c = contractor.Id;
        allocation.Allocation__c = 100;
        allocation.Status__c = 'Active';
        allocation.Expected_Rate__c = 11;
        allocation.Allocation_Type__c = 'Billable';
        allocation.Start_date__c = TEST_DATE_START;
        allocation.End_date__c = TEST_DATE_END;
        allocation.RecordTypeId = ALLOCATION_RECORD_TYPE_PROJECT_ID;
        allocation.CurrencyIsoCode = 'EUR';

        insert allocation;

        Salary_History__c salaryHistory = new Salary_History__c();
        salaryHistory.Contractor__c = contractor.Id;
        salaryHistory.Salary__c = 1000;
        salaryHistory.Start_Date__c = TEST_DATE_START.addMonths(-2);
        salaryHistory.End_Date__c = TEST_SH_END_DATE;//Date.today();
        salaryHistory.CurrencyIsoCode = 'USD';
        insert salaryHistory;
    }

    @IsTest
    private static void isAllocationRecordTypeNotProjectCorrectFlow() {
        Project__c project = [
            SELECT Id
            FROM Project__c
            LIMIT 1
        ];
        Allocation__c allocation = [
            SELECT Id, Expected_Rate__c, Expected_Rate_Daily__c, Expected_Rate_Monthly__c
            FROM Allocation__c
            WHERE Project__c = :project.Id
            AND RecordTypeId = :ALLOCATION_RECORD_TYPE_PROJECT_ID
            LIMIT 1
        ];
        Salary_History__c sh = [
                SELECT Id, Contractor__c
                FROM Salary_History__c
                LIMIT 1
        ];
        Test.startTest();

        Boolean isAllocationValid = MONTHLY_REPORT_SERVICE.isRecordValidForProcess(allocation.Id);
        Boolean isProjectValid = MONTHLY_REPORT_SERVICE.isRecordValidForProcess(project.Id);
        Boolean isProjectParen = MONTHLY_REPORT_SERVICE.isProjectParen(allocation.Id);
        MONTHLY_REPORT_SERVICE.sortAllocationWithChangedHours(new List<Allocation__c>{allocation}, new Map<Id, Allocation__c>{allocation.Id => allocation});
        MONTHLY_REPORT_SERVICE.getReportsBySalaryHistoryAndUpdateThem(new List<Salary_History__c>{sh});
        MONTHLY_REPORT_SERVICE.getParentProjectsWithChild(new List<Id>{project.Id});

        Test.stopTest();
        System.assert(isAllocationValid);
        System.assert(isProjectValid);
        System.assert(!isProjectParen);
    }

    @IsTest
    private static void isAllocationRecordTypeNotProjectIncorrectFlow() {
        Project__c project = [
            SELECT Id
            FROM Project__c
            LIMIT 1
        ];
        Contractor__c contractor = [
            SELECT Id
            FROM Contractor__c
            LIMIT 1
        ];
        Allocation__c allocation = new Allocation__c();
        allocation.Project__c = project.Id;
        allocation.Contractor__c = contractor.Id;
        allocation.Allocation__c = 100;
        allocation.Allocation_Type__c = 'Billable';
        allocation.Start_date__c = TEST_DATE_START;
        allocation.End_date__c = TEST_DATE_END;
        allocation.RecordTypeId = ALLOCATION_RECORD_TYPE_BOOKING_ID;

        insert allocation;
        Account acc = new Account(Name = 'acc name 1');

        insert acc;
        Test.startTest();

        Boolean isAllocationValid = MONTHLY_REPORT_SERVICE.isRecordValidForProcess(allocation.Id);
        Boolean isAccountValid = MONTHLY_REPORT_SERVICE.isRecordValidForProcess(acc.Id);

        Test.stopTest();
        System.assert(!isAllocationValid);
        System.assert(!isAccountValid);
    }

    @IsTest
    private static void getMonthsNamesTestCorrectFlow() {
        List<String> monthNames = new List<String>();
        for (PicklistEntry entry : Monthly_Report__c.Month_Names__c.getDescribe().getPicklistValues()) {
            monthNames.add(entry.getLabel());
        }

        Test.startTest();

        List<String> monthNamesFromMethod = MONTHLY_REPORT_SERVICE.getMonthsNames();

        Test.stopTest();
        System.assert(!monthNamesFromMethod.isEmpty());
        System.assert(monthNames.equals(monthNamesFromMethod));
    }

    @IsTest
    private static void getYearsRangeTestCorrectFlow() {
        Project__c project = [
            SELECT Id
            FROM Project__c
            LIMIT 1
        ];
        Test.startTest();

        List<String> years = MONTHLY_REPORT_SERVICE.getYearsRange(project.Id);

        Test.stopTest();
        System.assert(!years.isEmpty());
        System.assertEquals(NUMBER_OF_YEARS_FOR_CHOOSE, years.size());
    }

    @IsTest
    private static void getYearsRangeTestIncorrectFlow() {
        Project__c project = [
            SELECT Id
            FROM Project__c
            LIMIT 1
        ];

        delete project;
        Test.startTest();

        List<String> years = MONTHLY_REPORT_SERVICE.getYearsRange(project.Id);

        Test.stopTest();
        System.assert(years.isEmpty());
    }

//    @IsTest
//    private static void createReportsTestCorrectFlowProject() {
//        Project__c project = [
//            SELECT Id
//            FROM Project__c
//            LIMIT 1
//        ];
//        Integer numberOfReportsBefore = [
//            SELECT COUNT()
//            FROM Monthly_Report__c
//            WHERE Project__c = :project.Id
//        ];
//        List<String> months = new List<String>{ String.valueOf(TEST_DATE_IN_RANGE.month()) };
//        List<String> years = new List<String>{ String.valueOf(TEST_DATE_IN_RANGE.year()) };
//        Test.startTest();
//
//        MonthlyReportController.Result result = service.createReports(project.Id, months, years);
//
//        Test.stopTest();
//        Integer numberOfReportsAfter = [
//            SELECT COUNT()
//            FROM Monthly_Report__c
//            WHERE Project__c = :project.Id
//        ];
//        Integer activeAllocationOnProject = [
//            SELECT COUNT()
//            FROM Allocation__c
//            WHERE Project__c = :project.Id
//                AND RecordTypeId = :ALLOCATION_RECORD_TYPE_PROJECT_ID
//        ];
//
//        System.assert(result.isSuccessful);
//        System.assertNotEquals(numberOfReportsBefore, numberOfReportsAfter);
//        System.assertEquals(numberOfReportsAfter, activeAllocationOnProject);
//    }

    @IsTest
    private static void createReportsTestCorrectFlowAllocation() {
        Allocation__c allocation = [
            SELECT Id
            FROM Allocation__c
            LIMIT 1
        ];

        List<String> months = new List<String>();
        months.add(String.valueOf(TEST_DATE_IN_RANGE.month()));
        List<String> years = new List<String>();
        years.add(String.valueOf(TEST_DATE_IN_RANGE.year()));

        Integer numberOfReportsBefore = [
            SELECT COUNT()
            FROM Monthly_Report__c
            WHERE Allocation__c = :allocation.Id
        ];
        Test.startTest();

        MonthlyReportController.Result result = MONTHLY_REPORT_SERVICE.createReports(allocation.Id, months, years);

        Test.stopTest();
        Integer numberOfReportsAfter = [
            SELECT COUNT()
            FROM Monthly_Report__c
            WHERE Allocation__c = :allocation.Id
        ];

        System.assert(result.isSuccessful);
        System.assertNotEquals(numberOfReportsBefore, numberOfReportsAfter);
    }

    @IsTest
    private static void createReportsTestIncorrectFlowProject() {
        Project__c project = [
            SELECT Id
            FROM Project__c
            LIMIT 1
        ];
        Integer numberOfReportsBefore = [
            SELECT COUNT()
            FROM Monthly_Report__c
            WHERE Project__c = :project.Id
        ];
        List<String> months = new List<String>();
        months.add(String.valueOf(TEST_DATE_IN_RANGE.month()));

        List<String> years = new List<String>();
        years.add(String.valueOf(TEST_DATE_IN_RANGE.year()));
        delete project;
        Test.startTest();

        MonthlyReportController.Result result = MONTHLY_REPORT_SERVICE.createReports(project.Id, months, years);

        Test.stopTest();
        Integer numberOfReportsAfter = [
            SELECT COUNT()
            FROM Monthly_Report__c
            WHERE Project__c = :project.Id
        ];

        System.assert(!result.isSuccessful);
        System.assertEquals(numberOfReportsBefore, numberOfReportsAfter);
    }

    @IsTest
    private static void createReportsTestIncorrectFlowAllocation() {
        if (!systemAdministratorUsers.isEmpty()) {
            System.runAs(systemAdministratorUsers[0]) {
                Allocation__c allocation = [
                        SELECT Id
                        FROM Allocation__c
                        LIMIT 1
                ];

                List<String> months = new List<String>();
                months.add(String.valueOf(TEST_DATE_IN_RANGE.month()));
                List<String> years = new List<String>();
                years.add(String.valueOf(TEST_DATE_IN_RANGE.year()));

                Integer numberOfReportsBefore = [
                        SELECT COUNT()
                        FROM Monthly_Report__c
                        WHERE Allocation__c = :allocation.Id
                ];

                delete allocation;
                Test.startTest();

                MonthlyReportController.Result result = MONTHLY_REPORT_SERVICE.createReports(allocation.Id, months, years);

                Test.stopTest();
                Integer numberOfReportsAfter = [
                        SELECT COUNT()
                        FROM Monthly_Report__c
                        WHERE Allocation__c = :allocation.Id
                ];

                System.assert(!result.isSuccessful);
                System.assertEquals(numberOfReportsBefore, numberOfReportsAfter);
            }
        }
    }

    @IsTest
    private static void createReportsTestIncorrectFlowOutOfObjectDateRange() {
        Project__c project = [
            SELECT Id
            FROM Project__c
            LIMIT 1
        ];
        Integer numberOfReportsBefore = [
            SELECT COUNT()
            FROM Monthly_Report__c
            WHERE Project__c = :project.Id
        ];
        List<String> months = new List<String>();
        months.add(String.valueOf(TEST_DATE_NOT_IN_RANGE.month()));

        List<String> years = new List<String>();
        years.add(String.valueOf(TEST_DATE_NOT_IN_RANGE.year()));
        Test.startTest();

        MonthlyReportController.Result result = MONTHLY_REPORT_SERVICE.createReports(project.Id, months, years);

        Test.stopTest();
        Integer numberOfReportsAfter = [
            SELECT COUNT()
            FROM Monthly_Report__c
            WHERE Project__c = :project.Id
        ];

        System.assert(!result.isSuccessful);
        System.assertEquals(numberOfReportsBefore, numberOfReportsAfter);
    }

//    @IsTest
//    private static void createReportsTestCorrectFlowProjectReportExist() {
//        Project__c project = [
//            SELECT Id
//            FROM Project__c
//            LIMIT 1
//        ];
//        Allocation__c allocation = [
//            SELECT Id
//            FROM Allocation__c
//            WHERE Project__c = :project.Id
//            LIMIT 1
//        ];
//
//        Monthly_Report__c report = new Monthly_Report__c();
//        report.Project__c = project.Id;
//        report.Allocation__c = allocation.Id;
//        report.Monthly_Report_Period__c = TEST_PERIOD_IN_RANGE;
//
//        insert report;
//
//        Integer numberOfReportsBefore = [
//            SELECT COUNT()
//            FROM Monthly_Report__c
//            WHERE Project__c = :project.Id
//        ];
//
//        List<String> months = new List<String>{ String.valueOf(TEST_DATE_IN_RANGE.month()) };
//        List<String> years = new List<String>{ String.valueOf(TEST_DATE_IN_RANGE.year()) };
//        Test.startTest();
//
//        MonthlyReportController.Result result = service.createReports(project.Id, months, years);
//
//        Test.stopTest();
//        Integer numberOfReportsAfter = [
//            SELECT COUNT()
//            FROM Monthly_Report__c
//            WHERE Project__c = :project.Id
//        ];
//
//        System.assert(!result.isSuccessful);
//        System.assertEquals(numberOfReportsBefore, numberOfReportsAfter);
//    }

//    @IsTest
//    private static void createReportsTestIncorrectFlowAllocationReportExist() {
//        Project__c project = [
//            SELECT Id
//            FROM Project__c
//            LIMIT 1
//        ];
//        Allocation__c allocation = [
//            SELECT
//                Id, Contractor__c
//            FROM Allocation__c
//            WHERE Project__c = :project.Id
//            LIMIT 1
//        ];
//
//        Monthly_Report__c report = new Monthly_Report__c();
//        report.Project__c = project.Id;
//        report.Allocation__c = allocation.Id;
////        report.Monthly_Report_Period__c = TEST_PERIOD_IN_RANGE;
//        report.Monthly_Report_Start_Date__c = TEST_DATE_START;
//        report.Monthly_Report_End_Date__c = TEST_DATE_START.addMonths(1);
//        report.Contractor__c = allocation.Contractor__c;
//
//        insert report;
//        List<String> months = new List<String>();
//        months.add(String.valueOf(TEST_DATE_IN_RANGE.month()));
//        List<String> years = new List<String>();
//        years.add(String.valueOf(TEST_DATE_IN_RANGE.year()));
//
//        Integer numberOfReportsBefore = [
//            SELECT COUNT()
//            FROM Monthly_Report__c
//            WHERE Allocation__c = :allocation.Id
//        ];
//        Test.startTest();
//
//        MonthlyReportController.Result result = service.createReports(allocation.Id, months, years);
//
//        Test.stopTest();
//        Integer numberOfReportsAfter = [
//            SELECT COUNT()
//            FROM Monthly_Report__c
//            WHERE Allocation__c = :allocation.Id
//        ];
//
//        System.assert(!result.isSuccessful);
//        System.assertEquals(numberOfReportsBefore, numberOfReportsAfter);
//    }

    @IsTest
    private static void createReportsTestIncorrectFlowAllocationSelectedPeriodOutOfRange() {
        Project__c project = [
            SELECT Id
            FROM Project__c
            LIMIT 1
        ];
        Allocation__c allocation = [
            SELECT
                Id
            FROM Allocation__c
            WHERE Project__c = :project.Id
            LIMIT 1
        ];

        List<String> months = new List<String>{ String.valueOf(TEST_DATE_NOT_IN_RANGE.month()) };
        List<String> years = new List<String>{ String.valueOf(TEST_DATE_NOT_IN_RANGE.year()) };

        Integer numberOfReportsBefore = [
            SELECT COUNT()
            FROM Monthly_Report__c
            WHERE Allocation__c = :allocation.Id
        ];
        Test.startTest();

        MonthlyReportController.Result result = MONTHLY_REPORT_SERVICE.createReports(allocation.Id, months, years);

        Test.stopTest();
        Integer numberOfReportsAfter = [
            SELECT COUNT()
            FROM Monthly_Report__c
            WHERE Allocation__c = :allocation.Id
        ];

        System.assert(!result.isSuccessful);
        System.assertEquals(numberOfReportsBefore, numberOfReportsAfter);
    }
    @isTest
    private static void createReportsTestAndChangeFactHours() {
        Project__c project = [
                SELECT Id
                FROM Project__c
                LIMIT 1
        ];
        Allocation__c allocation = [
                SELECT Id
                FROM Allocation__c
                WHERE Project__c = :project.Id
                LIMIT 1
        ];
        Contractor__c contractor = [
                SELECT Id
                FROM Contractor__c
                LIMIT 1
        ];

        Monthly_Report__c report = new Monthly_Report__c();
        report.Project__c = project.Id;
        report.Allocation__c = allocation.Id;
        report.Monthly_Report_Period__c = TEST_PERIOD_IN_RANGE;
        report.Contractor__c = contractor.Id;
        report.Monthly_Report_Start_Date__c = Date.newInstance(1990,2,1);
        report.Monthly_Report_End_Date__c = Date.newInstance(1990,2,28);
        report.CurrencyIsoCode = 'USD';
        insert report;

        report.Fact_hours__c = 60.00;
        update report;

        Monthly_Report__c monthlyReport =[
                SELECT Id,
                        Hourly_cost__c,
                        Monthly_revenueNew__c,
                        Company_monthly_cost_without_overhead__c,
                        Company_monthly_cost_with_overhead__c
                FROM Monthly_Report__c
        ];

        List<Monthly_Report__c> lstMRs = MONTHLY_REPORT_SERVICE.generateReportsDetailRecordType(new List<Monthly_Report__c>{report},
                new Map<Id, List<Project__c>>{project.Id => new List<Project__c>{project}});

        System.assert(!lstMRs.isEmpty());
        System.assert(monthlyReport.Company_monthly_cost_with_overhead__c != null);
        System.assert(monthlyReport.Company_monthly_cost_without_overhead__c != null);
        System.assert(monthlyReport.Monthly_revenueNew__c != null);
        System.assert(monthlyReport.Hourly_cost__c != null);
    }

    @isTest
    private static void changeCurrencyInReport(){
        Project__c project = [
                SELECT Id
                FROM Project__c
                LIMIT 1
        ];
        Allocation__c allocation = [
                SELECT Id
                FROM Allocation__c
                WHERE Project__c = :project.Id
                LIMIT 1
        ];
        Contractor__c contractor = [
                SELECT Id
                FROM Contractor__c
                LIMIT 1
        ];

        Monthly_Report__c report = new Monthly_Report__c();
        report.Project__c = project.Id;
        report.Allocation__c = allocation.Id;
        report.Monthly_Report_Period__c = TEST_PERIOD_IN_RANGE;
        report.Monthly_Report_Start_Date__c = Date.newInstance(1990,2,1);
        report.Monthly_Report_End_Date__c = Date.newInstance(1990,2,28);
        report.Contractor__c = contractor.Id;
        report.CurrencyIsoCode = 'USD';
        insert report;

        report.Fact_hours__c = 60.00;
        update report;
        report.CurrencyIsoCode = 'EUR';
        update report;
    }

    @isTest
    private static void matrixTest(){
        Project__c project = new Project__c();
        project.Name = 'Test Parent';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.Start_date__c = TEST_DATE_START.addYears(-1);
        project.End_date__c = TEST_DATE_END.addYears(1);
        project.RecordTypeId = PROJECT_RECORD_TYPE_PARENT_ID;
        project.CurrencyIsoCode = 'USD';

        insert project;

        Project__c project1 = new Project__c();
        project1.Name = 'Child project name';
        project1.Project_type__c = 'Outsource';
        project1.Contract_type__c = 'Fixed cost';
        project1.Start_date__c = TEST_DATE_START.addYears(-1);
        project1.End_date__c = TEST_DATE_END.addYears(1);
        project1.RecordTypeId = PROJECT_RECORD_TYPE_COMMERCIAL;
        project1.CurrencyIsoCode = 'USD';
        project1.Parent_Project__c = project.Id;

        insert project1;
        Contractor__c contractor = [SELECT Id FROM Contractor__c][0];

        Allocation__c allocation = new Allocation__c();
        allocation.Project__c = project.Id;
        allocation.Contractor__c = contractor.Id;
        allocation.Allocation__c = 100;
        allocation.Expected_Rate__c = 11;
        allocation.Allocation_Type__c = 'Billable';
        allocation.Start_date__c = TEST_DATE_START.addYears(-1);
        allocation.End_date__c = TEST_DATE_END.addYears(10);
        allocation.RecordTypeId = ALLOCATION_RECORD_TYPE_PROJECT_ID;
        allocation.CurrencyIsoCode = 'EUR';

        insert allocation;

        Test.startTest();

        List<String> allocationIds = new List<String>{allocation.Id};
        MonthlyReportController.createReport(allocationIds, project.Id, 'January', '1900');
        MonthlyReportController.createReport(allocationIds, project.Id, 'February', '1900');

        Test.stopTest();
        List<Monthly_Report__c> reports = [SELECT Id, Project__r.Name, Monthly_Report_Period__c, Monthly_Report_General__c, Fact_hours__c FROM Monthly_Report__c WHERE RecordTypeId = :MONTHLY_REPORT_RECORD_TYPE_GENERAL_ID];

        System.assertEquals(2, reports.size());
    }
}