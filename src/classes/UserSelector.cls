/**
 * Created by Lambru Dmytro on 07.05.2020.
 */

public inherited sharing class UserSelector extends SObjectSelector {

    private static final Integer SOQL_LIMIT_MID = 25000;

    public static final Schema.SObjectType SOBJECT_TYPE = Schema.User.SObjectType;
    // Fields
    public static final Schema.SObjectField FIELD_MANAGER_ID = Schema.User.ManagerId;
    public static final Schema.SObjectField FIELD_EMPLOYEE_ACCOUNT_ID = Schema.User.Employee_AccountId__c;
    public static final Schema.SObjectField FIELD_IS_ACTIVE = Schema.User.IsActive;

    public static final Map<RolePicklistKey, String> ROLE_PICKLIST_VALUES_MAP = new Map<RolePicklistKey, String>{
            RolePicklistKey.PROJECT_MANAGER => 'Project Manager',
            RolePicklistKey.SFDM => 'SFDM'
    };

    public enum RolePicklistKey { PROJECT_MANAGER, SFDM }

    protected override SObjectType getSObjectType() {
        return SOBJECT_TYPE;
    }

    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {

        return new Map<String, SObjectQueryBuilder.RollupOperation>{
                'Id' => null
        };
    }

    /**
     * @author Dmytro Lambru
     * @description Getting all active users who have a person account.
     *
     * @return List with User records.
     */
    public User[] getAllActiveUsersWithPersonAccounts() {

        String soql = queryBuilder
                .registerField('Id')
                .registerField('Name')
                .registerField(FIELD_MANAGER_ID.getDescribe().getName())
                .registerField(FIELD_EMPLOYEE_ACCOUNT_ID.getDescribe().getName())
                .addWhere(FIELD_IS_ACTIVE.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, 'true')
                .addWhere(FIELD_EMPLOYEE_ACCOUNT_ID.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null')
                .registerOther('ORDER BY Name ASC')
                .registerLimit(SOQL_LIMIT_MID)
                .toString();

        return Database.query(soql);
    }

    /**
     * @description [ICRM-590] Merge from QA sandbox to Alex sandbox by Dmytro Lambru.
     *              Method not used.
     *
     * @param usersIds --
     *
     * @return --
     */
    public List<User> getUsersWithLastEditingRule(List<Id> usersIds) {

        String soql = queryBuilder
            .registerField('UserRole.Name')
            .registerSubquery('Monthly_Report_Editing_Rules__r', new List<String>{'Allow_Late_Report_Editing__c'})
            .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':usersIds')
            .registerOther('ORDER BY CreatedDate DESC NULLS LAST')
            .registerLimit(SOQL_LIMIT_MID)
            .toString();

        return Database.query(soql);
    }
}