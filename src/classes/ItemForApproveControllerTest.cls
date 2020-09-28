/**
 * Created by ArtemShevchenko on 08.11.2019.
 *
 * update: added logic which takes the name Approve Process from Metadata(Approval Assigner Settings) instead of hard code
 */

@IsTest
private class ItemForApproveControllerTest {
    private static final Id ALLOCATION_NEW_RESOURCE_REQUEST_RT =
            Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('New_resource_Request').getRecordTypeId();
    private static final Id PROJECT_RECORD_TYPE_COMMERCIAL =
            Schema.Project__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Commercial').getRecordTypeId();



    @TestSetup
    private static void setup() {
        String approveName = getApproveProcessNameFromMetadata();
        Profile projectManager = [SELECT Id FROM Profile WHERE Name='CT_Project Manager'];
        Profile managerProfile = [SELECT Id FROM Profile WHERE Name='CT_Delivery Head'];

        User managerUser = new User(Alias = 'testAd63', Email='adminUser62211@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = managerProfile.Id, IsActive = true,
                TimeZoneSidKey='America/Los_Angeles', UserName='testAdmin9317@testorg.com');

        insert managerUser;

        User u = new User(Alias = 'ndPM7812', Email='test879123456@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', IsActive = true,
                LocaleSidKey='en_US', ProfileId = projectManager.Id, ManagerId = managerUser.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='test123987528@testorg.com');
        insert u;


        Project__c project = new Project__c();
        project.Name = 'project name';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.Start_date__c = Date.today().addMonths(-5);
        project.End_date__c = Date.today().addMonths(5);
        project.RecordTypeId = PROJECT_RECORD_TYPE_COMMERCIAL;
        project.Project_Manager__c = u.Id;
        project.CurrencyIsoCode = 'USD';

        insert project;

        Contractor__c contractor = new Contractor__c();
        contractor.Name = 'Test';

        insert contractor;

        Allocation__c allocation = new Allocation__c(
            CreatedById = u.Id,
            OwnerId  = u.Id,
            Allocation_Type__c = 'Billable',
            Project__c = project.Id,
            Allocation__c = 50,
            Start_date__c = Date.today().addMonths(-1),
            End_date__c = Date.today().addMonths(1),
            Status__c = 'New',
            RecordTypeId = ALLOCATION_NEW_RESOURCE_REQUEST_RT,
            Approver_Manager__c = managerUser.Id
        );
        insert allocation;

        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval.');
        req.getNextApproverIds();
        req.setNextApproverIds(new Id[]{
                managerUser.Id
        });
        req.setObjectId(allocation.Id);
        req.setSubmitterId(u.Id);
        req.setProcessDefinitionNameOrId(approveName);
        req.setSkipEntryCriteria(true);

        Approval.ProcessResult processResults = Approval.process(req);
        System.assert(processResults.isSuccess());

    }
    @IsTest
    public static void initDataTest(){
        ProcessInstanceWorkitem processInstanceWorkitem = [SELECT Id, OriginalActorId FROM ProcessInstanceWorkitem LIMIT 1];
        User user = [SELECT Id FROM User WHERE Id = : processInstanceWorkitem.OriginalActorId LIMIT 1];
        System.runAs(user){
            ItemForApproveController.DataTableWrapper wrapper = ItemForApproveController.initData('Allocation__c');
            System.assertEquals(1, wrapper.recordsList.size());
            System.assertEquals(true, (wrapper.fieldsList.size() > 3));
        }
    }
    @IsTest
    public static void approveTest() {
        Allocation__c allocation = [SELECT Id FROM Allocation__c LIMIT 1];
        Contractor__c contractor = [SELECT Id FROM Contractor__c LIMIT 1];
        ProcessInstance processInstances = [SELECT Id,TargetObjectId,Status FROM ProcessInstance WHERE TargetObjectId = :allocation.Id LIMIT 1];
        System.assertEquals('Pending', processInstances.Status);
        List<SObject> objects = new List<SObject>();
        objects.add(allocation);
        ItemForApproveController.approveByTargetId(objects);

        allocation.Contractor__c = contractor.Id;
        update allocation;

        ItemForApproveController.approveRecords(new List<ProcessInstance>{
                processInstances
        }); // first Approver

        ItemForApproveController.approveRecords(new List<ProcessInstance>{
                processInstances
        }); // second Approver
        System.assertEquals('Approved', [SELECT Id,TargetObjectId,Status FROM ProcessInstance WHERE TargetObjectId = :allocation.Id LIMIT 1].Status);

    }
    @IsTest
    public static void rejectTest() {
        Allocation__c allocation = [SELECT Id FROM Allocation__c LIMIT 1];
        ProcessInstance processInstances = [SELECT Id,TargetObjectId,Status FROM ProcessInstance WHERE TargetObjectId = :allocation.Id LIMIT 1];
        System.assertEquals('Pending', processInstances.Status);
        Test.startTest();
        ItemForApproveController.rejectRecords(new List<ProcessInstance>{
                processInstances
        });
        System.assertEquals('Rejected', [SELECT Id,TargetObjectId,Status FROM ProcessInstance WHERE TargetObjectId = :allocation.Id LIMIT 1].Status);
        Test.stopTest();
    }
    @IsTest
    public static void getRecordsForApproveTest() {
        ProcessInstanceWorkitem processInstanceWorkitem = [SELECT Id, OriginalActorId FROM ProcessInstanceWorkitem LIMIT 1];
        User user = [SELECT Id FROM User WHERE Id = : processInstanceWorkitem.OriginalActorId LIMIT 1];
        System.runAs(user) {
            List<ProcessInstance> processInstances = ItemForApproveController.getRecordsForApprove();
            System.assertEquals(1, processInstances.size());
        }
    }
    private static String getApproveProcessNameFromMetadata() {
        String approveProcess = [
                SELECT Approver_Process_API_Name__c
                FROM Approval_Assigner_Settings__mdt
                WHERE DeveloperName = 'New_Allocation_Approvers'
        ].Approver_Process_API_Name__c;

        if (String.isEmpty(approveProcess)) {

            throw new NotFoundProcessException('Didn`t find Approve process for tests in Approval Assigner Settings custom metadata(New Allocation Approvers)');
        }

        return approveProcess;
    }

    class NotFoundProcessException extends Exception {
    }
}