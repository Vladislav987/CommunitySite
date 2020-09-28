@IsTest
private class LA_MassTransferControllerTest {
    public static final Id NEW_RESOURCE_REQUEST_ALLOCATION_RECORD_TYPE_ID = Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('New_resource_Request').getRecordTypeId();
    public static final Id BOOKING_REQUEST_ALLOCATION_RECORD_TYPE_ID = Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Booking').getRecordTypeId();
    public static final Id SOW_SOW_RECORD_TYPE_ID = Schema.SOW__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('SOW').getRecordTypeId();


    @TestSetup
    private static void initData(){
        Profile p = [SELECT Id FROM Profile WHERE Name='CT_Project Manager'];
        User u = new User(Alias = 'standt', Email='test123987528@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='test123987528@testorg.com');

        insert u;

        Account account = new Account();
        account.Name = 'Salesforce';
        insert account;

        Opportunity opportunity = new Opportunity();
        opportunity.Name = 'Test_Name';
        opportunity.CloseDate = Date.today().addMonths(5);
        opportunity.StageName = 'Qualification';
        opportunity.Key_practice__c = 'Salesforce';
        opportunity.AccountId = account.Id;
        opportunity.Direct_Indirect__c = 'Direct';
        opportunity.Type = 'Existing Business';
        opportunity.Description = 'for test';
        opportunity.Engagement_Type__c = 'Fixed cost';
        insert opportunity;

        MSA__c msa = new MSA__c();
        msa.Name = 'For test';
        msa.Account__c = account.Id;
        insert msa;

        SOW__c sow = new SOW__c();
        sow.RecordTypeId  = SOW_SOW_RECORD_TYPE_ID;
        sow.Name  = 'Test SOW';
        sow.Start_Date__c = Date.today().addMonths(-7);
        sow.End_Date__c = Date.today().addMonths(7);
        sow.Total_Cost__c = 1000;
        sow.Contract_Identifier__c = 'identifier';
        sow.MSA__c = msa.Id;
        sow.Opportunity__c =  opportunity.Id;
        insert sow;

        Project__c project = new Project__c();
        project.Name = 'Ford';
        project.Contract_type__c = 'Fixed cost';
        project.Project_type__c = 'Outsource';
        project.Start_date__c = Date.today();
        project.Project_Manager__c = u.Id;
        project.Department__c = 'SFDC Department';
        insert project;

        Allocation__c allocation = new Allocation__c();
        allocation.Opportunity__c = opportunity.Id;
        allocation.Allocation__c = 20;
        allocation.Status__c = 'Active';
        allocation.Start_date__c = Date.today().addMonths(-1);
        allocation.End_date__c = Date.today().addMonths(1);
        allocation.Resource_Level__c = 'Middle';
        allocation.Resource_Type__c = 'Designer';
        allocation.RecordTypeId = BOOKING_REQUEST_ALLOCATION_RECORD_TYPE_ID;
        insert allocation;
    }
    @IsTest
    private static void checkInitMethod(){
        List<Opportunity> opportunity = [SELECT Id FROM Opportunity];
        List<Allocation__c> allocations = [SELECT Id FROM Allocation__c];
        List<Project__c> projects = [SELECT Id FROM Project__c];
        List<SOW__c> sows = [SELECT Id FROM SOW__c];
        AllocationService.DataTableWrapper data = LA_MassTransferOfAllocationsController.getProjects(opportunity[0].Id);
        System.assert(data.sows.isEmpty());

        Test.startTest();
        allocations[0].Status__c = 'New';
        sows[0].Project__c = projects[0].Id;
        sows[0].Status__c = 'Signed';
        update allocations;
        update sows;

        AllocationService.DataTableWrapper dataAfterUpdate = LA_MassTransferOfAllocationsController.getProjects(opportunity[0].Id);
        System.assert(!dataAfterUpdate.sows.isEmpty());

        delete projects;
        Test.stopTest();

        AllocationService.DataTableWrapper dataAfterDelete = LA_MassTransferOfAllocationsController.getProjects(opportunity[0].Id);

        System.assert(dataAfterDelete.sows.isEmpty());
    }

    @IsTest
    private static void checkTransferButton(){
        List<Opportunity> opportunity = [SELECT Id FROM Opportunity];
        List<Allocation__c> allocations = [SELECT Id FROM Allocation__c];
        List<Project__c> projects = [SELECT Id, Project_Manager__c FROM Project__c];
        List<SOW__c> sows = [SELECT Id, Project__c FROM SOW__c];
        sows[0].Project__c = projects[0].Id;
        allocations[0].Status__c = 'New';
        update sows;
        update allocations;

        Test.startTest();
        LA_MassTransferOfAllocationsController.transferAllocations(sows[0].Id, opportunity[0].Id, allocations, false);

        Test.stopTest();
        List<Allocation__c> allocationsAfterTest = [SELECT Id, RecordTypeId, Status__c, Is_Opportunity__c, Opportunity__c, OwnerId, Project__c FROM Allocation__c];

        System.assertEquals(NEW_RESOURCE_REQUEST_ALLOCATION_RECORD_TYPE_ID, allocationsAfterTest[0].RecordTypeId);
        System.assertEquals('New', allocationsAfterTest[0].Status__c);
        System.assertEquals(false, allocationsAfterTest[0].Is_Opportunity__c);
        System.assertEquals(null, allocationsAfterTest[0].Opportunity__c);
        System.assertEquals(projects[0].Id, allocationsAfterTest[0].Project__c);
        System.assertEquals(projects[0].Project_Manager__c, allocationsAfterTest[0].OwnerId);
    }
    @IsTest
    private static void incorrectFlow(){

        try{
            AllocationService.DataTableWrapper dataAfterDelete = LA_MassTransferOfAllocationsController.getProjects(null);
        }catch (AuraHandledException e){
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        try{
            LA_MassTransferOfAllocationsController.transferAllocations(null, null, null, false);
        }catch (AuraHandledException e){
            System.assertEquals('Script-thrown exception', e.getMessage());
        }

    }

}