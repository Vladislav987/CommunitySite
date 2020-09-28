@IsTest
public with sharing class AppliedPositionManagementServiceTest {

    @TestSetup
    public static void setupData() {

        List<Job_Request__c> jobRequests = new List<Job_Request__c>();
        Contractor__c contractor = new Contractor__c(RecordTypeId= Schema.Contractor__c.SObjectType.getDescribe().
                                        getRecordTypeInfosByDeveloperName().get('Candidate').getRecordTypeId());
        insert contractor;

        for (Integer i = 0; i < 3; i++) {
            jobRequests.add(new Job_Request__c(OwnerId = UserInfo.getUserId(), Resource_Type__c = 'Android Developer',
                    Project_Description__c = 'test', Job_Responsibilities__c = 'testdata', Requirements__c = 'test',
                    Technologies__c = 'test'));
        }
        insert jobRequests;

        List<Applied_Position__c> appliedPositions = new List<Applied_Position__c>();
        for (Job_Request__c jobRequest : jobRequests) {
            for (Integer i = 0; i < 3; i++) {
                appliedPositions.add(new Applied_Position__c(Candidate__c = contractor.Id, Job_Request__c = jobRequest.Id));
            }
        }
        insert appliedPositions;
    }

    @IsTest
    public static void testInsert(){
        List<Applied_Position__c> assignedCandidates = [SELECT Id FROM Applied_Position__c WHERE Hiring_Manager__c != NULL];
        System.assertEquals(9, assignedCandidates.size());
    }

    @IsTest
    public static void testUpdate(){
        User user = [
                SELECT Username, LastName, Email, Alias, CommunityNickname, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, ProfileId,
                        LanguageLocaleKey
                FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        user.Id = null;
        user.Username = 'testNickName@gmail.com';
        user.CommunityNickname = user.Username;
        insert user;
        Test.startTest();
        List<Job_Request__c> jobRequests = [SELECT OwnerId FROM Job_Request__c];
        for (Job_Request__c jobRequest : jobRequests){
            jobRequest.OwnerId = user.Id;
        }
        update jobRequests;
        Test.stopTest();
        List<Applied_Position__c> appliedPositions = [SELECT Hiring_Manager__c FROM Applied_Position__c];
        for (Applied_Position__c appliedPosition : appliedPositions) {
            System.assertEquals(appliedPosition.Hiring_Manager__c, user.Id);
        }
    }

}