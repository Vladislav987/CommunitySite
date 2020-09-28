@IsTest
private class LW_ContractorOvertimesControllerTest {

    @TestSetup static void setup() {
        Contractor__c contractor = ContractorTestDataFactory.createDefaultPortalContractor();

        Payroll_Component__c payrollComponent = new Payroll_Component__c(
            Contractor__c = contractor.Id,
            RecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_OVERTIME.getRecordTypeId(),
            StartDate__c = Date.newInstance(2000, 1,1),
            Approval_Status__c = 'Approved'
        );

        insert payrollComponent;

        Project__c project1 = new Project__c(
            Contract_type__c = 'Fixed cost',
            Project_type__c = 'Outsource',
            Start_date__c = Date.newInstance(2000, 1,1)
        );

        Project__c project2 = new Project__c(
            Contract_type__c = 'Fixed cost',
            Project_type__c = 'Outsource',
            Start_date__c = Date.newInstance(2000, 1,1)
        );

        insert new Project__c[]{ project1, project2};

        Allocation__c allocation1 = new Allocation__c(
            Allocation__c = 50,
            Project__c = project1.Id,
            Allocation_Type__c = 'Billable',
            Start_date__c = Date.newInstance(2000, 1,1),
            End_date__c = Date.newInstance(2000, 1,1)
        );

        Allocation__c allocation2 = new Allocation__c(
            Allocation__c = 50,
            Project__c = project2.Id,
            Allocation_Type__c = 'Billable',
            Start_date__c = Date.newInstance(2000, 1,1),
            End_date__c = Date.newInstance(2000, 1,1)
        );

        insert new Allocation__c[]{ allocation1, allocation2};

        Monthly_Report__c monthlyReport1 = new Monthly_Report__c(
            Contractor__c = contractor.Id,
            Monthly_Report_Period__c = 'January 2000',
            Project__c = project1.Id,
            Allocation__c = allocation1.Id,
            Fact_hours__c = 10,
            Monthly_Report_Start_Date__c = Date.newInstance(1999, 12,1)
        );

        Monthly_Report__c monthlyReport2 = new Monthly_Report__c(
            Contractor__c = contractor.Id,
            Monthly_Report_Period__c = 'January 2000',
            Project__c = project2.Id,
            Allocation__c = allocation2.Id,
            Fact_hours__c = 10,
            Monthly_Report_Start_Date__c = Date.newInstance(1999, 12,1)
        );

        Monthly_Report__c monthlyReport3 = new Monthly_Report__c(
            Contractor__c = contractor.Id,
            Monthly_Report_Period__c = 'January 2000',
            Project__c = project2.Id,
            Allocation__c = allocation2.Id,
            Fact_hours__c = 10,
            Monthly_Report_Start_Date__c = Date.newInstance(1999, 12,1)
        );

        insert new Monthly_Report__c[]{ monthlyReport1, monthlyReport2, monthlyReport3};
    }

    @IsTest static void test_getOvertimes() {
        User portalUser = [SELECT Employee_AccountId__c FROM User WHERE Name = :ContractorTestDataFactory.DEFAULT_CONTRACTOR_NAME][0];

        Test.startTest();

            System.runAs(portalUser) {
                Map<Integer, Map<String, LW_ContractorOvertimesController.OvertimeWrapper>> overtimeWrapperByMonthByYear = LW_ContractorOvertimesController.getOvertimes();
                System.assert(!overtimeWrapperByMonthByYear.isEmpty());
            }
        Test.stopTest();
    }
}