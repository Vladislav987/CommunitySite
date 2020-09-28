@IsTest
private class ContractorServiceTest {
    public static final Id CONTRACTOR_RT = Schema.Contractor__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Contractor').getRecordTypeId();
    private static final List<User> systemAdministratorUsers = [SELECT Id FROM User WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'System Administrator') AND IsActive = true];

    @TestSetup
    static void setup(){
        Contractor__c contractor = new Contractor__c();
        contractor.Name = 'RollUp Test';
        contractor.Resource_Type__c = 'Designer';
        contractor.Resource_Level__c = 'Junior';
        contractor.RecordTypeId = CONTRACTOR_RT;
        insert contractor;

        Project__c project = new Project__c();
        project.Name = 'Project';
        project.Contract_type__c = 'Cost+';
        project.Project_type__c = 'Outsource';
        project.Start_date__c = Date.today();
        insert project;

        Allocation__c allocation = new Allocation__c();
        allocation.Status__c = 'Active';
        allocation.Allocation__c = 50;
        allocation.Allocation_Type__c = 'Billable';
        allocation.Start_date__c = Date.today();
        allocation.End_date__c = allocation.Start_date__c.addMonths(2);
        allocation.Project__c = project.Id;
        insert allocation;
    }

    @IsTest
    static void checkRollUpOnUpdateAllocation() {
        List<Contractor__c> contractors = [SELECT Id FROM Contractor__c];
        List<Allocation__c> allocations = [SELECT Id FROM Allocation__c];

        allocations[0].Contractor__c = contractors[0].Id;

        Test.startTest();
        update allocations;
        Test.stopTest();

        List<Contractor__c> contractors2 = [SELECT All_billable_allocations__c,All_Active_Allocations__c, All_billable_allocations_in_2_weeks__c, All_allocations_in_2_weeks__c FROM Contractor__c];
        System.assertEquals(50, contractors2[0].All_billable_allocations__c);
        System.assertEquals(50, contractors2[0].All_Active_Allocations__c);
        System.assertEquals(50, contractors2[0].All_billable_allocations_in_2_weeks__c);
        System.assertEquals(50, contractors2[0].All_allocations_in_2_weeks__c);
    }
    @IsTest
    static void checkRollUpOnUpdateAllocationPeriod() {
        List<Contractor__c> contractors = [SELECT Id FROM Contractor__c];
        List<Allocation__c> allocations = [SELECT Id, Start_date__c FROM Allocation__c];

        allocations[0].Contractor__c = contractors[0].Id;
        update allocations;
        Test.startTest();
        allocations[0].Start_date__c = allocations[0].Start_date__c.addDays(10);
        update allocations;
        Test.stopTest();

        List<Contractor__c> contractors2 = [SELECT All_billable_allocations__c,All_active_allocations__c, All_billable_allocations_in_2_weeks__c, All_allocations_in_2_weeks__c FROM Contractor__c];
        System.assertEquals(0, contractors2[0].All_billable_allocations__c);
        System.assertEquals(0, contractors2[0].All_active_allocations__c);
        System.assertEquals(50, contractors2[0].All_billable_allocations_in_2_weeks__c);
        System.assertEquals(50, contractors2[0].All_allocations_in_2_weeks__c);
    }
    @IsTest
    static void checkRollUpOnDeleteAllocation() {
        if (!systemAdministratorUsers.isEmpty()) {
            System.runAs(systemAdministratorUsers[0]) {
                List<Contractor__c> contractors = [SELECT Id FROM Contractor__c];
                List<Allocation__c> allocations = [SELECT Id FROM Allocation__c];
        
                allocations[0].Contractor__c = contractors[0].Id;
                update allocations;
                Test.startTest();
                delete allocations;
                Test.stopTest();
        
                List<Contractor__c> contractors2 = [SELECT All_billable_allocations__c,All_active_allocations__c, All_billable_allocations_in_2_weeks__c, All_allocations_in_2_weeks__c FROM Contractor__c];
                System.assertEquals(0, contractors2[0].All_billable_allocations__c);
                System.assertEquals(0, contractors2[0].All_active_allocations__c);
                System.assertEquals(0, contractors2[0].All_billable_allocations_in_2_weeks__c);
                System.assertEquals(0, contractors2[0].All_allocations_in_2_weeks__c);
            }
        }
    }
    @IsTest
    static void checkRollUpAddAnotherAllocation() {
        List<Contractor__c> contractors = [SELECT Id FROM Contractor__c];
        List<Allocation__c> allocations = [SELECT Id FROM Allocation__c];
        List<Project__c> projects = [SELECT Id FROM Project__c];

        allocations[0].Contractor__c = contractors[0].Id;
        update allocations;
        Test.startTest();
        Allocation__c allocation = new Allocation__c();
        allocation.Status__c = 'Active';
        allocation.Allocation__c = 50;
        allocation.Allocation_Type__c = 'Shadow';
        allocation.Start_date__c = Date.today().addDays(10);
        allocation.End_date__c = allocation.Start_date__c.addMonths(2);
        allocation.Contractor__c = contractors[0].Id;
        allocation.Project__c = projects[0].Id;
        allocation.Overrun_Type__c = 'Contractural agreement';
        allocation.Comments_for_Shadow_Type__c = 'test';
        
        insert allocation;

        Test.stopTest();

        List<Contractor__c> contractors2 = [SELECT All_billable_allocations__c,All_active_allocations__c, All_billable_allocations_in_2_weeks__c, All_allocations_in_2_weeks__c FROM Contractor__c];
        System.assertEquals(50, contractors2[0].All_billable_allocations__c);
        System.assertEquals(50, contractors2[0].All_active_allocations__c);
        System.assertEquals(50, contractors2[0].All_billable_allocations_in_2_weeks__c);
        System.assertEquals(100, contractors2[0].All_allocations_in_2_weeks__c);
    }
    @IsTest
    static void checkRollUpAddRejectedAnotherAllocation() {
        List<Contractor__c> contractors = [SELECT Id FROM Contractor__c];
        List<Allocation__c> allocations = [SELECT Id FROM Allocation__c];
        List<Project__c> projects = [SELECT Id FROM Project__c];

        allocations[0].Contractor__c = contractors[0].Id;
        update allocations;
        Test.startTest();
        Allocation__c allocation = new Allocation__c();
        allocation.Status__c = 'Rejected';
        allocation.Allocation__c = 50;
        allocation.Allocation_Type__c = 'Billable';
        allocation.Start_date__c = Date.today();
        allocation.End_date__c = allocation.Start_date__c.addMonths(2);
        allocation.Contractor__c = contractors[0].Id;
        allocation.Project__c = projects[0].Id;

        insert allocation;

        Test.stopTest();

        List<Contractor__c> contractors2 = [SELECT All_billable_allocations__c,All_active_allocations__c, All_billable_allocations_in_2_weeks__c, All_allocations_in_2_weeks__c FROM Contractor__c];
        System.assertEquals(50, contractors2[0].All_billable_allocations__c);
        System.assertEquals(50, contractors2[0].All_active_allocations__c);
        System.assertEquals(50, contractors2[0].All_billable_allocations_in_2_weeks__c);
        System.assertEquals(50, contractors2[0].All_allocations_in_2_weeks__c);
    }
        @IsTest
    static void checkTotalPlanHoursAfterInsertReports(){
        Contractor__c contractor = [SELECT Id FROM Contractor__c LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        List<Monthly_Report__c> reports = new List<Monthly_Report__c>();


        for (Integer i = 0; i < 100; i++){
            Monthly_Report__c report = new Monthly_Report__c();
            report.Contractor__c = contractor.Id;
            report.Project__c = project.Id;
            report.Monthly_Report_Start_Date__c = Date.today().toStartOfMonth().addMonths(-1);
            report.Monthly_Report_End_Date__c = report.Monthly_Report_Start_Date__c.addMonths(-1).addDays(-1);
            report.Fact_hours__c = i;
            reports.add(report);
        }

        Test.startTest();
        insert reports;
        Test.stopTest();

        Contractor__c contractorAfterInsertReports = [SELECT Id, FacHoursLastMonth__c FROM Contractor__c LIMIT 1];
        System.assertEquals(4950, contractorAfterInsertReports.FacHoursLastMonth__c);


    }
    @IsTest
    static void checkTotalPlanHoursAfterUpdateReports(){

        Contractor__c contractor = [SELECT Id FROM Contractor__c LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        List<Monthly_Report__c> reports = new List<Monthly_Report__c>();


        for (Integer i = 0; i < 100; i++){
            Monthly_Report__c report = new Monthly_Report__c();
            report.Contractor__c = contractor.Id;
            report.Project__c = project.Id;
            report.Monthly_Report_Start_Date__c = Date.today().toStartOfMonth().addMonths(-1);
            report.Monthly_Report_End_Date__c = report.Monthly_Report_Start_Date__c.addMonths(-1).addDays(-1);
            report.Fact_hours__c = i;
            reports.add(report);
        }
        insert reports;

        Test.startTest();
        for (Monthly_Report__c report: reports){
            report.Monthly_Report_Start_Date__c = Date.today().toStartOfMonth().addMonths(2);
            report.Monthly_Report_End_Date__c = report.Monthly_Report_Start_Date__c.addMonths(1).addDays(-1);
        }
        update reports;

        Test.stopTest();

        Contractor__c contractorAfterUpdateReports = [SELECT Id, FacHoursLastMonth__c FROM Contractor__c LIMIT 1];
        System.assertEquals(0, contractorAfterUpdateReports.FacHoursLastMonth__c);

    }

}