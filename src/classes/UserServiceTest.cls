@IsTest
private class UserServiceTest {
    @IsTest
    static void checkCreatingReportRuleForUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name='CT_Project Manager'];
        User u = new User(Alias = 'standt', Email='test123987528@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='test123987528@testorg.com');

        Test.startTest();

        insert u;

        Test.stopTest();

        User user = [SELECT Id, (SELECT Id, Allow_Late_Report_Editing__c FROM Monthly_Report_Editing_Rules__r) FROM User WHERE Id = :u.Id];
        System.assertEquals(1, user.Monthly_Report_Editing_Rules__r.size());
        System.assertEquals(false, user.Monthly_Report_Editing_Rules__r[0].Allow_Late_Report_Editing__c);
    }
}