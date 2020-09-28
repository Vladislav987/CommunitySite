/**
 * Created by Lambru Dmytro on 10.04.2020.
 */

public inherited sharing class AccountSelector extends SObjectSelector {

    private static final Integer SOQL_LIMIT_10K = 10000;
    private static final Integer SOQL_LIMIT_MID = 25000;
    private static final Integer SOQL_LIMIT_MAX = 50000;


    public static final Schema.SObjectType SOBJECT_TYPE = Schema.Account.SObjectType;

    // Record Types (RT)
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_PERSON_ACCOUNT;

    // Setting the Record Types (RT)
    static {
        Map<String, RecordTypeInfo> apiNameToRecordTypeInfoMap = SOBJECT_TYPE.getDescribe().getRecordTypeInfosByDeveloperName();

        RECORD_TYPE_INFO_PERSON_ACCOUNT = apiNameToRecordTypeInfoMap.get('PersonAccount');
    }

    // Fields
    public static final Schema.SObjectField FIELD_IS_PERSON_ACCOUNT = Schema.Account.IsPersonAccount;
    public static final Schema.SObjectField FIELD_CONTRACTOR = Schema.Account.Contractor__c;
    public static final Schema.SObjectField FIELD_STATION = Schema.Account.Station__c;
    public static final Schema.SObjectField FIELD_RECORD_TYPE_ID = Schema.Account.RecordTypeId;
    public static final Schema.SObjectField FIELD_ACTIVE = Schema.Account.Active__c;
    public static final Schema.SObjectField FIELD_EXIT_DATE = Schema.Account.Exit_Date__c;

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
     * @description To get actual person accounts by their IDs.
     *
     * @param personAccountIdSet Set with Person Account IDs.
     *
     * @return List with Person Accounts.
     */
    public Account[] getActualPersonAccountsByIds(Set<String> personAccountIdSet) {
        String soql = queryBuilder
            .registerField('Id')
            .registerField(FIELD_CONTRACTOR.getDescribe().getName())
            .addWhere(FIELD_IS_PERSON_ACCOUNT.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, 'true')
            .addWhere(FIELD_ACTIVE.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, 'true')
            .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':personAccountIdSet')
            .addWhere('Contractor__r.Joining_Date__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null')
            .registerOther('AND (Contractor__r.Exit_Date__c = NULL OR Contractor__r.Exit_Date__c >= LAST_MONTH)')
            .registerLimit(SOQL_LIMIT_10K)
            .toString();

        return Database.query(soql);
    }

    /**
     * @author Alexander Bogomaz
     * @description To get person accounts by their ContractorIDs.
     *
     * @param contractorsIds Set with Contractor IDs.
     *
     * @return List with Person Accounts.
     */
    public Account[] getPersonAccountsByContractorIds(Set<Id> contractorsIds) {
        String soql = queryBuilder
                .registerField('Id')
                .registerField('Contractor__r.Id')
                .registerField(FIELD_CONTRACTOR.getDescribe().getName())
                .addWhere(FIELD_IS_PERSON_ACCOUNT.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, 'true')
                .addWhere(FIELD_ACTIVE.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, 'true')
                .addWhere('Contractor__r.Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':contractorsIds')
                .registerLimit(SOQL_LIMIT_10K)
                .toString();

        return Database.query(soql);
    }

    /**
     * @author Dmytro Lambru
     * @description To get actual person accounts for contractors by their IDs.
     *
     * @param contractorIdSet Set with Contractor's ID.
     *
     * @return List with Person Accounts.
     */
    public Account[] getActualPersonAccountsByContractorIds(Set<Id> contractorIdSet) {
        String soql = queryBuilder
            .registerField('Id')
            .registerField(FIELD_CONTRACTOR.getDescribe().getName())
            .registerField('Contractor__r.Joining_Date__c')
            .addWhere(FIELD_IS_PERSON_ACCOUNT.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, 'true')
            .addWhere(FIELD_ACTIVE.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, 'true')
            .addWhere(FIELD_CONTRACTOR.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':contractorIdSet')
            .addWhere('Contractor__r.Joining_Date__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null')
            .registerOther('AND (Contractor__r.Exit_Date__c = NULL OR Contractor__r.Exit_Date__c >= LAST_MONTH)')
            .registerLimit(SOQL_LIMIT_MID)
            .toString();

        return Database.query(soql);
    }

    /**
     * @author Dmytro Lambru
     * @description To get person accounts with Contractor ID and Station by their IDs.
     *
     * @param contractorPersonAccountIdSet Set with person account IDs.
     *
     * @return List with Person Account records.
     */
    public Account[] getActualPersonAccountsWithContractorIdAndStationByIds(Set<String> contractorPersonAccountIdSet) {
        String soql = queryBuilder
            .registerField('Id')
            .registerField('Name')
            .registerField(FIELD_CONTRACTOR.getDescribe().getName())
            .registerField(FIELD_STATION.getDescribe().getName())
            .addWhere(FIELD_IS_PERSON_ACCOUNT.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, 'true')
            .addWhere(FIELD_ACTIVE.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, 'true')
            .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':contractorPersonAccountIdSet')
            .addWhere('Contractor__r.Joining_Date__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null')
            .registerOther('AND (Contractor__r.Exit_Date__c = NULL OR Contractor__r.Exit_Date__c >= LAST_MONTH)')
            .registerLimit(SOQL_LIMIT_MID)
            .toString();

        return Database.query(soql);
    }

    public List<Account> getActivePersonAccountsWithRelatedUsers(List<Id> contractorsIds) {
        String soql = queryBuilder
                .registerField('Id')
                .registerField('Name')
                .registerField(FIELD_CONTRACTOR.getDescribe().getName())
                .registerSubquery('Users', new List<String>{
                        'Name',
                        'ManagerId',
                        'Employee_AccountId__c'
                })
                .addWhere(FIELD_IS_PERSON_ACCOUNT.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, 'true')
                .addWhere(FIELD_ACTIVE.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, 'true')
                .addWhere(FIELD_CONTRACTOR.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':contractorsIds')
                .registerOther('AND (Contractor__r.Exit_Date__c = NULL OR Contractor__r.Exit_Date__c >= LAST_MONTH)')
                .registerLimit(SOQL_LIMIT_MID)
                .toString();

        return Database.query(soql);
    }

    public List<Account> getPersonAccountWithConditions(String conditionStr, Set<String> accountIdSet) {

        String soql = queryBuilder
            .registerField('Id')
            .registerField('Name')
            .registerField('Contractor__c')
            .registerField('Resource_Type__c')
            .registerField('Station__c')
            .registerField('Contractor__r.Joining_Date__c')
            .registerField('Contractor__r.Exit_Date__c')
            .registerField('Contractor__r.Department__c')
            .addWhere(FIELD_IS_PERSON_ACCOUNT.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, 'true')
            .addWhere(FIELD_ACTIVE.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, 'true')
            .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':accountIdSet')
            .addWhere('Contractor__r.Joining_Date__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null')
            .registerOther('AND (Contractor__r.Exit_Date__c = NULL OR Contractor__r.Exit_Date__c >= THIS_MONTH) ' + conditionStr)
            .toString();

        return Database.query(soql);
    }
}