/**
 * Created by IlliaLuhovyi on 7/17/2020.
 */

public inherited sharing class PayrollDateRulesService {

    private final String ERROR_MSG = 'Payroll_Date_Rules__mdt is empty.';

    private Set<Id> userOrGroupIdSet = new Set<Id>();

    public PayrollBlockingDaysInfo getBlockingDaysInfoByUserId(Id userId) {
        userOrGroupIdSet.add(userId);

        return getBlockingDaysInfo();
    }

    public PayrollBlockingDaysInfo getBlockingDaysInfoByUserRoleId(Id roleId) {
        userOrGroupIdSet.addAll(getGroupIdsByUserRoleId(roleId));

        return getBlockingDaysInfo();
    }

    public PayrollBlockingDaysInfo getBlockingDaysInfoByUserAndUserRoleIds(Id userId, Id roleId) {
        userOrGroupIdSet.add(userId);
        userOrGroupIdSet.addAll(getGroupIdsByUserRoleId(roleId));

        return getBlockingDaysInfo();
    }

    private PayrollBlockingDaysInfo getBlockingDaysInfo() {
        Payroll_Date_Rules__mdt[] payrollDateRulesList = getPayrollDateRules();

        if ( !payrollDateRulesList.isEmpty() ) {
            return new PayrollBlockingDaysInfo(payrollDateRulesList[0]);
        }

        return new PayrollBlockingDaysInfo().setErrorMessage(ERROR_MSG);
    }

    private Payroll_Date_Rules__mdt[] getPayrollDateRules() {

        return [
            SELECT
                Project_Compensation_Blocking_Day__c,
                Salary_Supplements_Blocking_Day__c,
                Salary_Transition_Day__c,
                Payroll_Blocking_Day__c
            FROM Payroll_Date_Rules__mdt
            WHERE Public_group__c IN :getPublicGroupDevNames()
            ORDER BY Order__c
            LIMIT 1
        ];
    }

    private Set<Id> getGroupIdsByUserRoleId(Id userRoleId) {
        Map<Id, Group> groupMap = new Map<Id, Group>([
            SELECT Id
            FROM Group
            WHERE RelatedId = :userRoleId
            LIMIT 1000
        ]);

        return groupMap.keySet();
    }

    private Set<String> getPublicGroupDevNames() {
        Set<String> groupDevNameSet = new Set<String>();

        GroupMember[] groupMemberList = [
                SELECT Group.DeveloperName
                FROM GroupMember
                WHERE UserOrGroupId = :userOrGroupIdSet
                LIMIT 1000
        ];

        for (GroupMember groupMember : groupMemberList) {
            groupDevNameSet.add(groupMember.Group.DeveloperName);
        }

        return groupDevNameSet;
    }

    public class PayrollBlockingDaysInfo {

        private Decimal projectCompensationDay;
        private Decimal salarySupplementsDay;
        private Decimal salaryTransitionDay;
        private Decimal payrollDay;
        private String errorMessage;
        private Boolean isSuccess = true;

        public PayrollBlockingDaysInfo() {}

        public PayrollBlockingDaysInfo(Payroll_Date_Rules__mdt dateRules) {
            this.projectCompensationDay = dateRules.Project_Compensation_Blocking_Day__c;
            this.salarySupplementsDay = dateRules.Salary_Supplements_Blocking_Day__c;
            this.salaryTransitionDay = dateRules.Salary_Transition_Day__c;
            this.payrollDay = dateRules.Payroll_Blocking_Day__c;
        }

        public Boolean isAvailable() {
            return this.isSuccess;
        }

        public PayrollBlockingDaysInfo setErrorMessage(String errorMessage) {
            this.isSuccess = false;
            this.errorMessage = errorMessage;

            return this;
        }

        public String getErrorMessage() {
            return this.errorMessage;
        }

        public Decimal getProjectCompensationDay() {
            return this.projectCompensationDay;
        }

        public Decimal getSalarySupplementsDay() {
            return this.salarySupplementsDay;
        }

        public Decimal getSalaryTransitionDay() {
            return this.salaryTransitionDay;
        }

        public Decimal getPayrollDay() {
            return this.payrollDay;
        }
    }
}