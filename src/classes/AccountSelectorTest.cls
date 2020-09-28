/**
 * Created by Lambru Dmytro on 15.04.2020.
 */
@IsTest
private class AccountSelectorTest {

    private static final String DEFAULT_CONTRACTOR_NAME = 'CONTRACTOR_FOR_TEST';
    private static AccountSelector accSelector = new AccountSelector();

    @TestSetup
    private static void doSetup() {
        Contractor__c[] contractorList = new Contractor__c[]{};
        Date joiningDate = System.today().addMonths(-1);

        // create Contractors with RT Contractor
        for (Integer index = 0; index < 5; index++) {
            Contractor__c contractor = new Contractor__c(
                Name = DEFAULT_CONTRACTOR_NAME + index,
                RecordTypeId = ContractorSelector.RECORD_TYPE_INFO_CONTRACTOR.getRecordTypeId(),
                Resource_Type__c = ContractorSelector.RESOURCE_TYPE_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceTypePicklistKey.SFDC_DEVELOPER),
                Resource_Level__c = ContractorSelector.RESOURCE_LEVEL_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceLevelPicklistKey.TRAINEE),
                Joining_Date__c = joiningDate
            );

            contractorList.add(contractor);
        }

        insert contractorList;

        // create Person Accounts for Contractors
        Account[] accountList = new Account[]{};

        for (Contractor__c contractor : contractorList) {
            Account account = new Account();
            account.RecordTypeId = AccountSelector.RECORD_TYPE_INFO_PERSON_ACCOUNT.getRecordTypeId();
            account.LastName = contractor.Name;
            account.Contractor__c = contractor.Id;
            account.Active__c = true;
            account.Exit_Date__c = null;
            accountList.add(account);
        }

        insert accountList;
    }

    @IsTest
    static void test_getActualPersonAccountsByContractorIds() {
        Map<Id, Contractor__c> idToContractorMap = new Map<Id, Contractor__c>([SELECT Id FROM Contractor__c]);

        Test.startTest();
            Account[] personAccountList = accSelector.getActualPersonAccountsByContractorIds(idToContractorMap.keySet());
        Test.stopTest();

        System.assertEquals(5, personAccountList.size(), 'The account list size must be 5 for 5 Contractors');
    }

    @IsTest
    static void test_getActualPersonAccountsByIds() {
        Map<Id, Account> idToAccountMap = new Map<Id, Account>([SELECT Id FROM Account]);
        Set<String> accountIdSet = (Set<String>)JSON.deserialize(JSON.serialize(idToAccountMap.keySet()), Set<String>.class);

        Test.startTest();
            Account[] personAccountList = accSelector.getActualPersonAccountsByIds(accountIdSet);
        Test.stopTest();

        System.assertEquals(5, personAccountList.size(), 'The account list size must be 5 for 5 Contractors');
    }

    @IsTest
    static void test_getPersonAccountsWithContractorIdAndStationByIds() {
        Map<Id, Account> idToAccountMap = new Map<Id, Account>([SELECT Id FROM Account]);
        Set<String> accountIdSet = (Set<String>)JSON.deserialize(JSON.serialize(idToAccountMap.keySet()), Set<String>.class);

        Test.startTest();
            Account[] personAccountList = accSelector.getActualPersonAccountsWithContractorIdAndStationByIds(accountIdSet);
        Test.stopTest();

        System.assertEquals(5, personAccountList.size(), 'The account list size must be 5 for 5 Contractors');
    }

    @IsTest
    static void test_getActivePersonAccountsWithRelatedUsers() {
        Map<Id, Contractor__c> idToContractorMap = new Map<Id, Contractor__c>([SELECT Id FROM Contractor__c]);
        Id[] contractorIdList = new List<Id>(idToContractorMap.keySet());

        Test.startTest();
            Account[] personAccountList = accSelector.getActivePersonAccountsWithRelatedUsers(contractorIdList);
        Test.stopTest();

        System.assertEquals(5, personAccountList.size(), 'The account list size must be 5 for 5 Contractors');
    }

    @IsTest
    static void test_getPersonAccountWithConditions() {
        Map<Id, Account> idToAccountMap = new Map<Id, Account>([SELECT Id FROM Account]);
        Set<String> accountIdSet = (Set<String>)JSON.deserialize(JSON.serialize(idToAccountMap.keySet()), Set<String>.class);

        Test.startTest();
            Account[] personAccountList = accSelector.getPersonAccountWithConditions('ORDER BY Name ASC', accountIdSet);
        Test.stopTest();

        System.assertEquals(5, personAccountList.size(), 'The account list size must be 5 for 5 Contractors');
    }
}