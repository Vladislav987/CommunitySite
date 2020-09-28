/**
 * Created by Mychailo Hamdzii on 24.04.2019.
 */

@IsTest
private class MonthlyReportSelectorTest {
    private static final Date TEST_DATE_START = Date.newInstance(1900, 1, 1);
    private static final Date TEST_DATE_END = Date.newInstance(1901, 1, 1);
    private static final String TEST_PERIOD_IN_RANGE_AS_STRING = 'February 1900';
    private static final String TEST_PERIOD_NOT_IN_RANGE_AS_STRING = 'January 1902';
    static MonthlyReportSelector MONTHLY_REPORT_SELECTOR = new MonthlyReportSelector();
    private static final List<User> systemAdministratorUsers = [SELECT Id FROM User WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'System Administrator') AND IsActive = true];

    @TestSetup
    private static void setup() {
        Project__c project = new Project__c();
        project.Name = 'project name';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.Start_date__c = TEST_DATE_START;
        project.End_date__c = TEST_DATE_END;

        insert project;

        Contractor__c contractor = new Contractor__c();
        contractor.Name = 'zdarova';
        contractor.Resource_Type__c = 'SFDC Developer';
        contractor.Resource_Level__c = 'Trainee';
        contractor.Salary__c = 500;

        insert contractor;

        SObjectDomain.isEnabledMap.put(SalaryHistoryTriggerHandler.class.getName(), true);
        SObjectDomain.isEnabledMap.put(ContractorTriggerHandler.class.getName(), true);

        Allocation__c allocationActive = new Allocation__c();
        allocationActive.Project__c = project.Id;
        allocationActive.Contractor__c = contractor.Id;
        allocationActive.Allocation__c = 100;
        allocationActive.Allocation_Type__c = 'Billable';
        allocationActive.Start_date__c = TEST_DATE_START;
        allocationActive.End_date__c = TEST_DATE_END;

        insert allocationActive;

        List<Monthly_Report__c> reports = new List<Monthly_Report__c>();
        Monthly_Report__c report1 = new Monthly_Report__c();
        report1.Contractor__c = allocationActive.Contractor__c;
        report1.Allocation__c = allocationActive.Id;
        report1.Project__c = allocationActive.Project__c;
        report1.Monthly_Report_Start_Date__c = TEST_DATE_START;
        report1.Monthly_Report_End_Date__c = TEST_DATE_END;
        report1.Monthly_Report_Period__c = TEST_PERIOD_IN_RANGE_AS_STRING;

        Monthly_Report__c report2 = new Monthly_Report__c();
        report2.Contractor__c = allocationActive.Contractor__c;
        report2.Allocation__c = allocationActive.Id;
        report2.Project__c = allocationActive.Project__c;
        report2.Monthly_Report_Start_Date__c = TEST_DATE_START;
        report2.Monthly_Report_End_Date__c = TEST_DATE_END;
        report2.Monthly_Report_Period__c = TEST_PERIOD_IN_RANGE_AS_STRING;

        Monthly_Report__c report3 = new Monthly_Report__c();
        report3.Contractor__c = allocationActive.Contractor__c;
        report3.Allocation__c = allocationActive.Id;
        report3.Project__c = allocationActive.Project__c;
        report3.Monthly_Report_Start_Date__c = TEST_DATE_START;
        report3.Monthly_Report_End_Date__c = TEST_DATE_END;
        report3.Monthly_Report_Period__c = TEST_PERIOD_NOT_IN_RANGE_AS_STRING;

        reports.add(report1);
        reports.add(report2);
        reports.add(report3);

        insert reports;
    }

    @IsTest
    private static void getReportsByRangeForAllocationsTestCorrectFlow() {
        List<Allocation__c> allocations = [
            SELECT Id
            FROM Allocation__c
        ];
        Integer numberOfAllocation = [
            SELECT COUNT()
            FROM Monthly_Report__c
            WHERE Allocation__c = :allocations[0].Id
                AND Monthly_Report_Period__c = :TEST_PERIOD_IN_RANGE_AS_STRING
        ];
        Test.startTest();

        List<Monthly_Report__c> reports = MONTHLY_REPORT_SELECTOR.getReportsByRangeForAllocations(allocations, TEST_PERIOD_IN_RANGE_AS_STRING);

        Test.stopTest();
        Integer numberOfAllReports = [
            SELECT COUNT()
            FROM Monthly_Report__c
            WHERE Allocation__c = :allocations[0].Id
        ];
        System.assert(!reports.isEmpty());
        System.assertEquals(numberOfAllocation, reports.size());
        System.assertNotEquals(numberOfAllReports, reports.size());
    }

    @IsTest
    private static void getReportsByRangeForAllocationsTestIncorrectFlow() {
        List<Allocation__c> allocations = [
            SELECT Id
            FROM Allocation__c
        ];
        Test.startTest();

        List<Monthly_Report__c> reports = MONTHLY_REPORT_SELECTOR.getReportsByRangeForAllocations(allocations, TEST_PERIOD_IN_RANGE_AS_STRING);

        Test.stopTest();
        Integer numberOfAllReports = [
            SELECT COUNT()
            FROM Monthly_Report__c
            WHERE Monthly_Report_Period__c = :TEST_PERIOD_IN_RANGE_AS_STRING
        ];
        System.assert(!reports.isEmpty());
        System.assert(numberOfAllReports != null && numberOfAllReports != 0);
    }

    @IsTest
    private static void getReportsByAllocationIdTestCorrectFLow() {
        Allocation__c allocation = [
            SELECT Id
            FROM Allocation__c
            LIMIT 1
        ];
        Integer numberOfAllocation = [
            SELECT COUNT()
            FROM Monthly_Report__c
            WHERE Allocation__c = :allocation.Id
        ];
        Test.startTest();

        List<Monthly_Report__c> reports = MONTHLY_REPORT_SELECTOR.getReportsByAllocationId(allocation.Id);

        Test.stopTest();
        System.assert(!reports.isEmpty());
        System.assertEquals(numberOfAllocation, reports.size());
    }

    @IsTest
    private static void getReportsByAllocationIdTestIncorrectFLow() {
        if (!systemAdministratorUsers.isEmpty()) {
            System.runAs(systemAdministratorUsers[0]) {
                Allocation__c allocation = [
                    SELECT Id
                    FROM Allocation__c
                    LIMIT 1
                ];
                Integer numberOfAllocation = [
                    SELECT COUNT()
                    FROM Monthly_Report__c
                    WHERE Allocation__c = :allocation.Id
                ];
        
                delete allocation;
                Test.startTest();
        
                List<Monthly_Report__c> reports = MONTHLY_REPORT_SELECTOR.getReportsByAllocationId(allocation.Id);
        
                Test.stopTest();
                System.assert(reports.isEmpty());
                System.assertNotEquals(numberOfAllocation, reports.size());
            }
        }
    }

    @IsTest
    private static void getMonthlyReportsTest() {
        List<Monthly_Report__c> mrs = [
                SELECT Id
                FROM Monthly_Report__c
        ];

        Test.startTest();
        List<Monthly_Report__c> reports = MONTHLY_REPORT_SELECTOR.getMonthlyReports(mrs);
        Test.stopTest();

        System.assert(!reports.isEmpty());
        System.assertEquals(mrs.size(), reports.size());
    }

    @IsTest
    private static void getReportsByProjectAndParentProjectIdAndFieldSetTest() {
        Project__c prj = [
                SELECT Id
                FROM Project__c
                LIMIT 1
        ];

        Test.startTest();
        String fieldSet = 'Fields_for_related_list_for_Project';
        List<Monthly_Report__c> reports = MONTHLY_REPORT_SELECTOR.getReportsByProjectAndParentProjectIdAndFieldSet(prj.Id, fieldSet);
        Test.stopTest();

        System.assert(!reports.isEmpty());
    }

}