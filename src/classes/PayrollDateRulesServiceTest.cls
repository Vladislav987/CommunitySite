/**
 * Created by IlliaLuhovyi on 7/17/2020.
 */

@IsTest
private class PayrollDateRulesServiceTest {

    static PayrollDateRulesService service = new PayrollDateRulesService();

    @TestSetup
    static void doSetup() {
        addUserToPublicGroup('Payroll_CTU_Managers', UserInfo.getUserId());
    }

    @IsTest
    static void test_getBlockingDaysInfoByUserId() {
        Test.startTest();
            PayrollDateRulesService.PayrollBlockingDaysInfo payrollBlockingDaysWrapper = service.getBlockingDaysInfoByUserId(UserInfo.getUserId());
        Test.stopTest();

        System.assertEquals(null, payrollBlockingDaysWrapper.getErrorMessage(), payrollBlockingDaysWrapper.getErrorMessage() + ' Check settings.');
        System.assert(payrollBlockingDaysWrapper.getProjectCompensationDay() != null, 'Value should not bu null. Check settings.');
        System.assert(payrollBlockingDaysWrapper.getPayrollDay() != null, 'Value should not bu null. Check settings.');
        System.assert(payrollBlockingDaysWrapper.getSalarySupplementsDay() != null, 'Value should not bu null. Check settings.');
        System.assert(payrollBlockingDaysWrapper.getSalaryTransitionDay() != null, 'Value should not bu null. Check settings.');
    }

    @IsTest
    static void test_getBlockingDaysInfoByUserRoleId() {
        Test.startTest();
            service.getBlockingDaysInfoByUserRoleId(UserInfo.getUserRoleId());
        Test.stopTest();
    }

    @IsTest
    static void test_getBlockingDaysInfoByUserAndUserRoleIds() {
        Test.startTest();
            service.getBlockingDaysInfoByUserAndUserRoleIds(UserInfo.getUserId(), UserInfo.getUserRoleId());
        Test.stopTest();
    }

    static void addUserToPublicGroup(String groupDevName, Id userId) {
        Group publicGroup = [SELECT Id, (SELECT UserOrGroupId FROM GroupMembers) FROM Group WHERE DeveloperName = :groupDevName];

        for (GroupMember groupMember : publicGroup.GroupMembers) {
            // exit if already exist
            if (groupMember.UserOrGroupId == userId) return;
        }

        insert new GroupMember(
            GroupId = publicGroup.Id,
            UserOrGroupId = userId
        );
    }
}