@IsTest
private class AllocationRollUpForContractorBatchTest {
    public static final Id CONTRACTOR_RT = Schema.Contractor__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Contractor').getRecordTypeId();

    @TestSetup
    static void setup(){
        SObjectDomain.isEnabled = false;

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


        Allocation__c allocationActive = new Allocation__c();
        allocationActive.Status__c = 'Active';
        allocationActive.Allocation__c = 50;
        allocationActive.Allocation_Type__c = 'Billable';
        allocationActive.Start_date__c = Date.today();
        allocationActive.End_date__c = allocationActive.Start_date__c.addMonths(2);
        allocationActive.Contractor__c = contractor.Id;
        allocationActive.Project__c = project.Id;
        insert allocationActive;

        Allocation__c allocationRejected = new Allocation__c();
        allocationRejected.Status__c = 'Rejected';
        allocationRejected.Allocation__c = 50;
        allocationRejected.Allocation_Type__c = 'Billable';
        allocationRejected.Start_date__c = Date.today();
        allocationRejected.End_date__c = allocationRejected.Start_date__c.addMonths(2);
        allocationRejected.Contractor__c = contractor.Id;
        allocationRejected.Project__c = project.Id;

        insert allocationRejected;

        Allocation__c allocationActiveInTwoWeek = new Allocation__c();
        allocationActiveInTwoWeek.Status__c = 'Active';
        allocationActiveInTwoWeek.Allocation__c = 50;
        allocationActiveInTwoWeek.Allocation_Type__c = 'Shadow';
        allocationActiveInTwoWeek.Start_date__c = Date.today().addDays(12);
        allocationActiveInTwoWeek.End_date__c = allocationActiveInTwoWeek.Start_date__c.addMonths(2);
        allocationActiveInTwoWeek.Contractor__c = contractor.Id;
        allocationActiveInTwoWeek.Project__c = project.Id;
        allocationActiveInTwoWeek.Overrun_Type__c = 'Contractural agreement';
        allocationActiveInTwoWeek.Comments_for_Shadow_Type__c = 'test';
        
        insert allocationActiveInTwoWeek;

        SObjectDomain.isEnabled = true;

    }
    @IsTest
    static void checkBatchWork() {
        List<Contractor__c> contractors = [SELECT Id, All_allocations_in_2_weeks__c, All_billable_allocations_in_2_weeks__c, All_active_allocations__c, All_billable_allocations__c FROM Contractor__c];
        System.assertEquals(null, contractors[0].All_billable_allocations__c);
        System.assertEquals(null, contractors[0].All_active_allocations__c);
        System.assertEquals(null, contractors[0].All_billable_allocations_in_2_weeks__c);
        System.assertEquals(null, contractors[0].All_allocations_in_2_weeks__c);

        System.Test.startTest();

        AllocationRollUpForContractorBatch b = new AllocationRollUpForContractorBatch();
        database.executebatch(b, 200);

        System.Test.stopTest();

        List<Contractor__c> contractors2 = [SELECT Id, All_allocations_in_2_weeks__c, All_billable_allocations_in_2_weeks__c, All_active_allocations__c, All_billable_allocations__c FROM Contractor__c];
        System.assertEquals(50, contractors2[0].All_billable_allocations__c);
        System.assertEquals(50, contractors2[0].All_active_allocations__c);
        System.assertEquals(50, contractors2[0].All_billable_allocations_in_2_weeks__c);
        System.assertEquals(100, contractors2[0].All_allocations_in_2_weeks__c);

    }
}