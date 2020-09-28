/**
 * Created by ArtemShevchenko on 17.11.2019.
 */

@IsTest
private class SharingButtonControllerTest {
    @TestSetup
    static void setup() {
        Contractor__c contractor = new Contractor__c();
        contractor.Name = 'TEST_CONTRACTOR_FOR_SHARE';
        contractor.Resource_Type__c = 'Account Manager';
        contractor.Resource_Level__c = 'Junior';
        UserRole role = new UserRole(DeveloperName = 'TestRole', Name = 'Test Role');
        insert role;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'CT_Resource Manager'];
        User user = new User(Alias = 'standard', Email = 'standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = profile.Id,
                UserRoleId = role.Id,
                TimeZoneSidKey = 'America/Los_Angeles', Username = 'standardusertest@testorg.com');
        insert user;

        User userOwner = new User(Alias = 'standt', Email = 'standarduserowner@testorg.com',
                EmailEncodingKey = 'UTF-8', LastName = 'TestingOwner', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles', Username = 'standardusertestowner@testorg.com');
        insert userOwner;
        System.runAs(userOwner) {
            insert contractor;
        }

    }
    @IsTest
    static void SharingButtonTest() {
        User userOwner = [SELECT Id, Name FROM User WHERE LastName = 'TestingOwner' LIMIT 1];
        User user = [SELECT Id, Name FROM User WHERE LastName = 'Testing' LIMIT 1];
        Contractor__c contractor = [SELECT Id FROM Contractor__c LIMIT 1];
        Test.startTest();
        System.runAs(userOwner) {

            List<String> usersNamesBeforeSharing = SharingButtonController.getEntitiesNamesForSharing('Users');
            System.assert(usersNamesBeforeSharing.contains('Testing'));
            System.assertEquals(0, [SELECT Id FROM Contractor__Share WHERE UserOrGroupId =: user.Id].size());

            SharingButtonController.shareWithEntities(new List<String>{user.Name}, 'Users', contractor.Id, 'Read');

            List<String> groupsNames = SharingButtonController.getEntitiesNamesForSharing('Groups');

            SharingButtonController.shareWithEntities(new List<String>{groupsNames[0]}, 'Groups', contractor.Id, 'Read');
            System.assertEquals(3, [SELECT Id FROM Contractor__Share].size());

            List<String> rolesNames = SharingButtonController.getEntitiesNamesForSharing('Roles');
            SharingButtonController.shareWithEntities(new List<String>{'Test Role'}, 'Roles', contractor.Id, 'Read');
            System.assertEquals(3, [SELECT Id FROM Contractor__Share].size());

            System.assert(groupsNames.size() > 0);
            System.assert(rolesNames.size() > 0);
            System.assertEquals('TEST_CONTRACTOR_FOR_SHARE', [SELECT Id, Parent.Name, UserOrGroup.Name FROM Contractor__Share WHERE UserOrGroupId =: user.Id LIMIT 1].Parent.Name);
            System.assertEquals(1, [SELECT Id FROM Contractor__Share WHERE UserOrGroupId =: user.Id].size());
         }
        Test.stopTest();
    }
}