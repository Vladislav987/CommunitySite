@IsTest
public with sharing class ContractorFactHoursCalculateBatchTest {
    public static final Id CONTRACTOR_RT = Schema.Contractor__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Contractor').getRecordTypeId();

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

        List<Monthly_Report__c> reports = new List<Monthly_Report__c>();
        for (Integer i = 0; i < 50; i++){
            Monthly_Report__c report = new Monthly_Report__c();
            report.Contractor__c = contractor.Id;
            report.Project__c = project.Id;
            report.Monthly_Report_Start_Date__c = Date.today().toStartOfMonth().addMonths(-1);
            report.Monthly_Report_End_Date__c = report.Monthly_Report_Start_Date__c.addMonths(-1).addDays(-1);
            report.Fact_hours__c = i;
            reports.add(report);
        }
        insert reports;
    }
    @IsTest
    static void tryToRunBatch(){
        Contractor__c contractor = [SELECT Id FROM Contractor__c LIMIT 1];
        contractor.FacHoursLastMonth__c = 0;
        update contractor;

        Test.startTest();

        Database.executeBatch(new ContractorFactHoursCalculateBatch(), 100);

        Test.stopTest();

        Contractor__c contractorAfterInsertReports = [SELECT Id, FacHoursLastMonth__c FROM Contractor__c LIMIT 1];
        System.assertEquals(1225, contractorAfterInsertReports.FacHoursLastMonth__c);


    }

}