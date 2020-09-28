/**
 * Created by Lambru Dmytro on 10.07.2020.
 */

@IsTest
private class LA_PayrollComponentsControllerTest {

    @TestSetup
    static void doSetup() {
        User newUser = createDummyUser();

        insert newUser;
    }

    @IsTest
    static void test_getCustomMetadata() {
        User dummyUser = [SELECT Id FROM User WHERE FirstName = 'TestFirstName' AND LastName = 'TestLastName'];
        System.assert(dummyUser != null);

        System.runAs(dummyUser) {
            Payroll_Component_Configurations__mdt[] payrollComponentConfigurationsList = LA_PayrollComponentsController.getCustomMetadata();
            System.assert(payrollComponentConfigurationsList != null);
        }
    }

    static User createDummyUser() {
        User currentUser = [
            SELECT TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, ProfileId, LanguageLocaleKey
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        String lastName = 'TestLastName';
        String email = lastName+'@test.com';

        User newUser = new User(
            FirstName = 'TestFirstName',
            LastName = lastName,
            Email = email,
            Username = email,
            ProfileId = currentUser.ProfileId,
            Alias = 'alias123',
            CommunityNickname = 'testnick',
            TimeZoneSidKey = (String)currentUser.TimeZoneSidKey,
            LocaleSidKey = currentUser.LocaleSidKey,
            EmailEncodingKey = currentUser.EmailEncodingKey,
            LanguageLocaleKey = currentUser.LanguageLocaleKey
        );

        return newUser;
    }
}