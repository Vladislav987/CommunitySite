/**
 * Created by Lambru Dmytro on 07.05.2020.
 */

@IsTest
private class UserSelectorTest {

    private static final String DEFAULT_CONTRACTOR_NAME = 'CONTRACTOR';
    private static UserSelector userSelector = new UserSelector();

    @IsTest
    static void testGetAllActiveUsersWithPersonAccounts() {
        ContractorTestDataFactory.createDefaultPortalContractors(10);
        User[] userWithPersonAccountList = userSelector.getAllActiveUsersWithPersonAccounts();

        Integer userCount = 0;
        for (User userWithPersonAccount : userWithPersonAccountList) {

            if (userWithPersonAccount.Name.contains(DEFAULT_CONTRACTOR_NAME)) {
                userCount++;
            }
        }

        System.assertEquals(10, userCount);
    }
}