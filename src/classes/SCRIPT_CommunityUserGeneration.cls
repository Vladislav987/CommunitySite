/**
 * Created by Lambru Dmytro 07.2020
 */

/*### ANONYMOUS APEX EXAMPLE: #################################################*/

    //    Set<Id> contractorIdSet = new Set<Id>{
    //        'a0b1X000002a2zZQAQ',
    //        'a0b1X000002a3A1QAI',
    //        'a0b1X000002a3A6QAI'
    //    };

    /* DEFAULT ATTRIBUTE VALUES */
    /* with database rollback */
    //SCRIPT_CommunityUserGeneration.IS_SAFE_EXECUTION = true;
    /* show additional information in logs */
    //SCRIPT_CommunityUserGeneration.IS_SHOW_ADDITIONAL_INFO = true;
    /* profile name for community user */
    //SCRIPT_CommunityUserGeneration.COMMUNITY_PROFILE_NAME = 'CT_Contractor';


    /* user generation for contractors by IDs */
    //SCRIPT_CommunityUserGeneration.executeUserGeneration(contractorIdSet);
    /* user generation for all valid contractors */
    //SCRIPT_CommunityUserGeneration.executeUserGeneration();

    /* assign managers for contractors by IDs */
    //SCRIPT_CommunityUserGeneration.executeAssignManagers(contractorIdSet);
    /* assign managers for all valid contractors */
    //SCRIPT_CommunityUserGeneration.executeAssignManagers();
/*#############################################################################*/

public class SCRIPT_CommunityUserGeneration {

    /* API PROPERTY */
    public static String COMMUNITY_PROFILE_NAME = 'CT_Contractor';
    public static Boolean IS_SAFE_EXECUTION = true;
    public static Boolean IS_SHOW_ADDITIONAL_INFO = true;


    /* HELPERS */
    private static Map<String, User> usernameToExistingUserMap = new Map<String, User>();
    private static Map<String, User> communityNicknameToExistingUserMap = new Map<String, User>();
    private static Map<String, User> emailPartToExistingUserMap = new Map<String, User>();

    /* CONSTANTS */
    private static final String PREFIX_FAKE = '.uat.fake';
    private static final String CONTRACTOR_RT_DEV_NAME = 'Contractor';
    private static final Set<String> STATION_PICKLIST_API_NAME_SET = new Set<String>{
        'CTDev Cherkasy Office',
        'CTDev Kiev Office',
        'CTDev Lviv Office'
    };

    /* API METHODS */
    public static void executeUserGeneration() {
        Contractor__c[] contractorList = getAllContractorsForGeneration();

        executeUserGeneration(contractorList);
    }

    public static void executeUserGeneration(Set<Id> contractorIdSet) {
        Contractor__c[] contractorList = getContractorsForGenerationByIds(contractorIdSet);

        executeUserGeneration(contractorList);
    }

    public static void executeAssignManagers() {
        Contractor__c[] contractorList = getAllContractorsForAssignManager();

        executeAssignManagers(contractorList);
    }

    public static void executeAssignManagers(Set<Id> contractorIdSet) {
        Contractor__c[] contractorList = getContractorsForAssignManagerByIds(contractorIdSet);

        executeAssignManagers(contractorList);
    }

    /* ############################################################################################################ */
    /* ######################################### LOGIC FOR GENERATION ############################################# */
    /* ############################################################################################################ */

    private static void executeUserGeneration(Contractor__c[] contractorList) {
        displaySelectedContractorInfos(contractorList);
        mapFieldValuesToExistingUser();

        Account[] accountToUpsertList = createPersonAccountsByContractors(contractorList);

        // disable all triggers before DML operation
        SObjectDomain.isEnabled = false;

        upsert accountToUpsertList;

        displayAccountInfos(accountToUpsertList);


        Account[] accountAfterUpsertList = getUpsertedPersonAccounts(accountToUpsertList);
        User[] communityUserList = createCommunityUsersByAccounts(accountAfterUpsertList);

        if (communityUserList.isEmpty()) return;

        // async save
        saveUsers(JSON.serialize(communityUserList), IS_SAFE_EXECUTION);
    }

    private static void mapFieldValuesToExistingUser() {

        User [] userList = [
            SELECT
                Name,
                Username,
                Email,
                CommunityNickname
            FROM User
            LIMIT 10000
        ];

        for (User user : userList) {
            usernameToExistingUserMap.put(user.Username, user);
            communityNicknameToExistingUserMap.put(user.CommunityNickname, user);

            String emailPart = getEmailPartFromString(user.Email);
            emailPartToExistingUserMap.put(emailPart, user);
        }

    }

    private static Contractor__c[] getContractorsForGenerationByIds(Set<Id> contractorIdSet) {

        return [
            SELECT
                Name,
                CurrencyIsoCode,
                Email_Address__c,
                (
                    SELECT Id
                    FROM Accounts__r
                    WHERE IsPersonAccount = TRUE
                    LIMIT 1
                )
            FROM Contractor__c
            WHERE Id IN :contractorIdSet
            AND Active__c = TRUE
            AND RecordType.DeveloperName = :CONTRACTOR_RT_DEV_NAME
            AND Station__c IN :STATION_PICKLIST_API_NAME_SET
            AND Email_Address__c <> NULL
            AND Joining_Date__c <> NULL
            AND Joining_Date__c <= THIS_MONTH
            AND (Exit_Date__c = NULL OR Exit_Date__c >= THIS_MONTH)
            LIMIT 1000
        ];
    }

    private static Contractor__c[] getAllContractorsForGeneration() {

        return [
            SELECT
                Name,
                CurrencyIsoCode,
                Email_Address__c,
                (
                    SELECT Id
                    FROM Accounts__r
                    WHERE IsPersonAccount = TRUE
                    LIMIT 1
                )
            FROM Contractor__c
            WHERE Active__c = TRUE
            AND RecordType.DeveloperName = :CONTRACTOR_RT_DEV_NAME
            AND Station__c IN :STATION_PICKLIST_API_NAME_SET
            AND Email_Address__c <> NULL
            AND Joining_Date__c <> NULL
            AND Joining_Date__c <= THIS_MONTH
            AND (Exit_Date__c = NULL OR Exit_Date__c >= THIS_MONTH)
            LIMIT 1000
        ];
    }

    private static Account[] createPersonAccountsByContractors(Contractor__c[] contractorList) {
        Account[] accountToUpsertList = new Account[]{};
        Id personAccountRTId = Schema.Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

        for (Contractor__c contractor : contractorList) {
            Account account;
            Map<String, String> namePartMap = getNamePartsFromContractor(contractor);

            if (contractor.Accounts__r.isEmpty()) {
                account = new Account(
                    RecordTypeId = personAccountRTId,
                    FirstName = namePartMap.get('firstName'),
                    LastName = namePartMap.get('lastName'),
                    Contractor__c = contractor.Id,
                    CurrencyIsoCode = contractor.CurrencyIsoCode,
                    PersonEmail = contractor.Email_Address__c,
                    Active__c = true
                );
            }
            else {
                account = contractor.Accounts__r[0];
                account.FirstName = namePartMap.get('firstName');
                account.LastName = namePartMap.get('lastName');
                account.Contractor__c = contractor.Id;
                account.CurrencyIsoCode = contractor.CurrencyIsoCode;
                account.PersonEmail = contractor.Email_Address__c;
                account.Active__c = true;
            }

            if (isExistUserWithSuchUsername(contractor)) continue;
            if (isExistUserWithSuchEmail(contractor)) continue;
            if (isExistUserWithSuchCommunityNickname(contractor, account)) continue;

            accountToUpsertList.add(account);
        }

        return accountToUpsertList;
    }

    private static Boolean isExistUserWithSuchUsername(Contractor__c contractor) {
        String username = contractor.Email_Address__c + PREFIX_FAKE;

        if (usernameToExistingUserMap.containsKey(username)) {
            User existingUser = usernameToExistingUserMap.get(username);
            displayInfoOfExistingUserForContractor(contractor, existingUser, 'Username');

            return true;
        }

        return false;
    }

    private static Boolean isExistUserWithSuchEmail(Contractor__c contractor) {
        String emailPart = getEmailPartFromString(contractor.Email_Address__c);

        if (emailPartToExistingUserMap.containsKey(emailPart)) {
            User existingUser = emailPartToExistingUserMap.get(emailPart);
            displayInfoOfExistingUserForContractor(contractor, existingUser, 'Email');

            return true;
        }

        return false;
    }

    private static Boolean isExistUserWithSuchCommunityNickname(Contractor__c contractor, Account account) {
        String communityNickname = getCommunityNicknameByAccount(account);

        if (communityNicknameToExistingUserMap.containsKey(communityNickname)) {
            User existingUser = communityNicknameToExistingUserMap.get(communityNickname);
            displayInfoOfExistingUserForContractor(contractor, existingUser, 'CommunityNickname');

            return true;
        }

        return false;
    }

    /**
     * @description Gets part from email, e.g. dmytro.lambru@ctdev.io.invalid => dmytro.lambru@ctdev
     * @param userEmail --
     *
     * @return --
     */
    private static String getEmailPartFromString(String userEmail) {
        String[] emailPartList = userEmail.split('@');

        String firstPart = emailPartList[0];
        String secondPart = emailPartList[1];

        Integer secondPartEndingPosition = secondPart.length() >= 4
            ? 3
            : secondPart.length();

        return String.valueOf(firstPart + '@' + secondPart.substring(0, secondPartEndingPosition));
    }

    private static Map<String, String> getNamePartsFromContractor(Contractor__c contractor) {
        String firstName = '';
        String lastName;
        String[] namePartList = contractor.Name.split(' ');

        if (namePartList.size() > 1) {
            firstName = namePartList[0];
            namePartList.remove(0);
            lastName = String.join(namePartList, ' ');
        }
        else {
            lastName = namePartList[0];
        }

        return new Map<String, String>{
            'firstName' => firstName,
            'lastName' => lastName
        };
    }

    private static Account[] getUpsertedPersonAccounts(Account[] personAccountList) {

        return [
            SELECT
                FirstName,
                LastName,
                CurrencyIsoCode,
                PersonEmail,
                PersonContactId
            FROM Account
            WHERE Id IN :personAccountList
        ];
    }

    private static User[] createCommunityUsersByAccounts(Account[] personAccountList) {
        User[] userList = new User[]{};
        Id ctContractorProfileId = [SELECT Id FROM Profile WHERE Name = :COMMUNITY_PROFILE_NAME].Id;

        for (Account account : personAccountList) {
            String fakeEmail = account.PersonEmail + PREFIX_FAKE;

            User communityUser = new User(
                ProfileId = ctContractorProfileId,
                Employee_AccountId__c = account.Id,
                ContactId = account.PersonContactId,
                FirstName = account.FirstName,
                LastName = account.LastName,
                CurrencyIsoCode = account.CurrencyIsoCode,
                Username = fakeEmail,
                Email = fakeEmail,
                Alias = getAliasByAccount(account),
                CommunityNickname = getCommunityNicknameByAccount(account),
                TimeZoneSidKey = 'Europe/Helsinki',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                IsActive = true
            );

            userList.add(communityUser);
        }

        return userList;
    }

    private static String getAliasByAccount(Account account) {
        String firstPart = account.FirstName != null && account.FirstName.length() >= 1
            ? account.FirstName.substring(0, 1)
            : '';

        Integer lastNameEndingPosition = account.LastName.length() >= 6
            ? 5
            : account.LastName.length();

        String alias = String.valueOf(firstPart + account.LastName.deleteWhitespace().substring(0, lastNameEndingPosition));

        return alias.toLowerCase();
    }

    /**
     * @description TODO: unique symbols
     *
     * @param account --
     *
     * @return --
     */
    private static String getCommunityNicknameByAccount(Account account) {
        final Integer USER_NICKNAME_MAX_SIZE = 40;

        String nickName = account.FirstName != null ? account.FirstName : '';
        nickName += account.LastName;
        nickName = nickName.deleteWhitespace().replace('@', '').replace('-', '').replace('+', '').replace('_', '');
        nickName += PREFIX_FAKE;

        return nickName.length() > USER_NICKNAME_MAX_SIZE ? nickName.substring(0, USER_NICKNAME_MAX_SIZE) : nickName;
    }

    /**
     * @description future - to avoid exception below:
     * CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY:
     * CTPHARMA.UserProcess: execution of AfterInsert caused by: System.DmlException: Update failed.
     * First exception on row 0 with id 0051X000004OG8fQAG;
     * first error: MIXED_DML_OPERATION, DML operation on setup object is not permitted after you have updated a non-setup object (or vice versa): User, original object: Account: [] (CTPHARMA)
     *
     * @param jsonCommunityUserList --
     * @param isSafeExecution --
     */
    @Future
    private static void saveUsers(String jsonCommunityUserList, Boolean isSafeExecution) {
        // set database save point for rollback all operations
        Savepoint savepoint = Database.setSavepoint();
        User[] communityUserList = (User[]) JSON.deserialize(jsonCommunityUserList, User[].class);


        // disable all triggers before DML operation
        SObjectDomain.isEnabled = false;

        // Cancel email notification on DML operation
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.emailHeader.triggerUserEmail = false;

        Database.SaveResult[] saveResultList = Database.insert(communityUserList, dmlOptions);

        displaySaveResultInfo(saveResultList);
        displayCommunityUserInfos(communityUserList);

        if (isSafeExecution) {
            // rollback to savepoint
            Database.rollback(savepoint);
        }
    }

    private static void displaySelectedContractorInfos(Contractor__c[] contractorList) {
        if (!IS_SHOW_ADDITIONAL_INFO) return;

        System.debug('### SELECTED CONTRACTORS ' + contractorList.size() + ': #################################################################');

        for (Contractor__c contractor : contractorList) {
            System.debug('=== CONTRACTOR INFO ===');
            System.debug('ID: ' + contractor.Id);
            System.debug('Name: ' + contractor.Name);
            System.debug('Email_Address__c: ' + contractor.Email_Address__c);
            System.debug('==========================================================================================');
        }

        System.debug('##########################################################################################');
    }

    private static void displayAccountInfos(Account[] accountList) {
        if (!IS_SHOW_ADDITIONAL_INFO) return;

        System.debug('### CREATED ACCOUNTS ' + accountList.size() + ': #################################################################');

        for (Account account : accountList) {
            System.debug('=== ACCOUNT INFO ===');
            System.debug('ID: ' + account.Id);
            System.debug('FirstName: ' + account.FirstName);
            System.debug('LastName: ' + account.LastName);
            System.debug('PersonEmail: ' + account.PersonEmail);
            System.debug('==========================================================================================');
        }

        System.debug('##########################################################################################');
    }

    private static void displayInfoOfExistingUserForContractor(Contractor__c contractor, User existingUser, String fieldName) {
        if (!IS_SHOW_ADDITIONAL_INFO) return;

        System.debug('##########################################################################################');
        System.debug('User already exists for contractor with such "' + fieldName + '" below:');

        System.debug('=== CONTRACTOR INFO ===');
        System.debug('ID: ' + contractor.Id);
        System.debug('Name: ' + contractor.Name);
        System.debug('Email_Address__c: ' + contractor.Email_Address__c);

        System.debug('==========================================================================================');

        System.debug('=== USER INFO ===');
        System.debug('ID: ' + existingUser.Id);
        System.debug('Name: ' + existingUser.Name);
        System.debug('Username: ' + existingUser.Username);
        System.debug('Email: ' + existingUser.Email);
        System.debug('CommunityNickname: ' + existingUser.CommunityNickname);

        System.debug('##########################################################################################');
    }

    private static void displaySaveResultInfo(Database.SaveResult[] saveResultList) {
        System.debug('### SAVE RESULTS: #########################################################################');

        for (Database.SaveResult sr : saveResultList) {

            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted User. ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors
                for (Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred:');
                    System.debug('STATUS CODE: ' + err.getStatusCode() + ' | MESSAGE: ' + err.getMessage());
                    System.debug('User fields that affected this error: ' + err.getFields());
                }
            }

            System.debug('==========================================================================================');
        }

        System.debug('##########################################################################################');
    }

    private static void displayCommunityUserInfos(User[] userList) {
        if (!IS_SHOW_ADDITIONAL_INFO) return;

        System.debug('### CREATED USERS ' + userList.size() + ': ################################################################');

        for (User user : userList) {
            System.debug('=== USER INFO ===');
            System.debug('ID: ' + user.Id);
            System.debug('FirstName: ' + user.FirstName);
            System.debug('LastName: ' + user.LastName);
            System.debug('CommunityNickname: ' + user.CommunityNickname);
            System.debug('Alias: ' + user.Alias);
            System.debug('Email: ' + user.Email);
            System.debug('==========================================================================================');
        }

        System.debug('##########################################################################################');
    }

    /* ############################################################################################################ */
    /* ####################################### LOGIC FOR MANAGER ID ASSIGN ######################################## */
    /* ############################################################################################################ */

    private static void executeAssignManagers(Contractor__c[] contractorList) {
        // set database save point for rollback all operations
        Savepoint savepoint = Database.setSavepoint();

        User[] contractorUserToUpdateList = assignManagersToContractorUsers(contractorList);
        Database.SaveResult[] saveResultList = Database.update(contractorUserToUpdateList);

        displayUpdateResultInfoAfterAssignManagers(saveResultList, contractorUserToUpdateList);

        if (IS_SAFE_EXECUTION) {
            // rollback to savepoint
            Database.rollback(savepoint);
        }
    }

    private static User[] assignManagersToContractorUsers(Contractor__c[] contractorList) {
        User[] contractorUserToUpdateList = new User[]{};
        Map<Id, User> contractorIdToUserMap = getContractorIdToUser();

        for (Contractor__c contractor : contractorList) {
            User contractorUser = contractorIdToUserMap.get(contractor.Id);
            User managerUser = contractorIdToUserMap.get(contractor.Reports_To__c);

            if ( contractorUser == null ) {
                displayContractorInfoForNotFoundContractorUser(contractor);
                continue;
            }

            if ( managerUser == null ) {
                displayContractorInfoForNotFoundManagerUser(contractor, contractorUser);
                continue;
            }

            if ( String.isNotBlank(contractorUser.ManagerId) ) {
                displayContractorInfoWithAssignedManager(contractor, contractorUser, managerUser);
                continue;
            }

            contractorUser.ManagerId = managerUser.Id;
            contractorUserToUpdateList.add(contractorUser);
        }

        return contractorUserToUpdateList;
    }

    private static Map<Id, User> getContractorIdToUser() {
        User[] userList = getValidUsers();
        Map<Id, Account> idToAccountMap = mapIdToPersonAccountsForUsers(userList);

        return mapContractorIdToUser(userList, idToAccountMap);
    }

    private static User[] getValidUsers() {

        return [
            SELECT
                Name,
                ManagerId,
                Employee_AccountId__c
            FROM User
            WHERE IsActive = TRUE
            AND Employee_AccountId__c <> NULL
            LIMIT 10000
        ];
    }

    private static Map<Id, Account> mapIdToPersonAccountsForUsers(User[] userList) {
        Set<String> personAccountIdSet = new Set<String>();

        for (User user : userList) {
            personAccountIdSet.add(user.Employee_AccountId__c);
        }

        return new Map<Id, Account>([
            SELECT
                Contractor__c
            FROM Account
            WHERE Id IN :personAccountIdSet
            AND Active__c = TRUE
            AND IsPersonAccount = TRUE
            AND Contractor__c <> NULL
            LIMIT 10000
        ]);
    }

    private static Map<Id, User> mapContractorIdToUser(User[] userList, Map<Id, Account> idToAccountMap) {
        Map<Id, User> contractorIdToUserMap = new Map<Id, User>();

        for (User user : userList) {
            Account account = idToAccountMap.get(user.Employee_AccountId__c);

            contractorIdToUserMap.put(account.Contractor__c, user);
        }

        return contractorIdToUserMap;
    }

    private static Contractor__c[] getAllContractorsForAssignManager() {

         return [
            SELECT
                Name,
                Reports_To__c
            FROM Contractor__c
            WHERE RecordType.DeveloperName = :CONTRACTOR_RT_DEV_NAME
            AND Active__c = TRUE
            AND Reports_To__c <> NULL
            AND Station__c IN :STATION_PICKLIST_API_NAME_SET
            AND Email_Address__c <> NULL
            AND Joining_Date__c <> NULL
            AND Joining_Date__c <= THIS_MONTH
            AND (Exit_Date__c = NULL OR Exit_Date__c >= THIS_MONTH)
            LIMIT 10000
        ];
    }

    private static Contractor__c[] getContractorsForAssignManagerByIds(Set<Id> contractorIdSet) {

         return [
            SELECT
                Name,
                Reports_To__c
            FROM Contractor__c
            WHERE Id IN :contractorIdSet
            AND RecordType.DeveloperName = :CONTRACTOR_RT_DEV_NAME
            AND Active__c = TRUE
            AND Reports_To__c <> NULL
            AND Station__c IN :STATION_PICKLIST_API_NAME_SET
            AND Email_Address__c <> NULL
            AND Joining_Date__c <> NULL
            AND Joining_Date__c <= THIS_MONTH
            AND (Exit_Date__c = NULL OR Exit_Date__c >= THIS_MONTH)
            LIMIT 10000
        ];
    }

    private static void displayContractorInfoForNotFoundContractorUser(Contractor__c contractor) {
        if (!IS_SHOW_ADDITIONAL_INFO) return;

        System.debug('### USER FOR CONTRACTOR NOT FOUND: ####################################');

        System.debug('=== CONTRACTOR INFO ===');
        System.debug('ID: ' + contractor.Id);
        System.debug('Name: ' + contractor.Name);
        System.debug('Reports_To__c: ' + contractor.Reports_To__c);

        System.debug('##########################################################################################');
    }

    private static void displayContractorInfoForNotFoundManagerUser(Contractor__c contractor, User contractorUser) {
        if (!IS_SHOW_ADDITIONAL_INFO) return;

        System.debug('### MANAGER USER FOR CONTRACTOR NOT FOUND: ####################################');

        System.debug('=== CONTRACTOR INFO ===');
        System.debug('ID: ' + contractor.Id);
        System.debug('Name: ' + contractor.Name);
        System.debug('Reports_To__c: ' + contractor.Reports_To__c);
        System.debug('==========================================================================================');
        System.debug('=== CONTRACTOR USER INFO ===');
        System.debug('ID: ' + contractorUser.Id);
        System.debug('Name: ' + contractorUser.Name);
        System.debug('ManagerId: ' + contractorUser.ManagerId);

        System.debug('##########################################################################################');
    }

    private static void displayContractorInfoWithAssignedManager(Contractor__c contractor, User contractorUser, User managerUser) {
        if (!IS_SHOW_ADDITIONAL_INFO) return;

        System.debug('### CONTRACTOR USER ALREADY ASSIGNED TO THE MANAGER: #####################################');

        System.debug('=== CONTRACTOR INFO ===');
        System.debug('ID: ' + contractor.Id);
        System.debug('Name: ' + contractor.Name);
        System.debug('Reports_To__c: ' + contractor.Reports_To__c);
        System.debug('==========================================================================================');

        System.debug('=== CONTRACTOR USER INFO ===');
        System.debug('ID: ' + contractorUser.Id);
        System.debug('Name: ' + contractorUser.Name);
        System.debug('ManagerId: ' + contractorUser.ManagerId);
        System.debug('==========================================================================================');

        System.debug('=== MANAGER USER INFO ===');
        System.debug('ID: ' + managerUser.Id);
        System.debug('Name: ' + managerUser.Name);

        System.debug('##########################################################################################');
    }

    private static void displayUpdateResultInfoAfterAssignManagers(Database.SaveResult[] saveResultList, User[] contractorUserList) {
        Map<Id, User> idToUserMap = new Map<Id, User>(contractorUserList);

        System.debug('### UPDATE RESULTS AFTER ASSIGN MANAGERS: ################################################################');

        for (Database.SaveResult sr : saveResultList) {

            if (sr.isSuccess()) {
                User contractorUser = idToUserMap.get(sr.getId());
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully updated User:');
                System.debug('ID: ' + contractorUser.Id);
                System.debug('Name: ' + contractorUser.Name);
                System.debug('ManagerId: ' + contractorUser.ManagerId);
            }
            else {
                // Operation failed, so get all errors
                System.debug('Update failed. The following error has occurred:');
                for (Database.Error err : sr.getErrors()) {
                    System.debug('STATUS CODE: ' + err.getStatusCode() + ' | MESSAGE: ' + err.getMessage());
                    System.debug('User fields that affected this error: ' + err.getFields());
                }
            }

            System.debug('==========================================================================================');
        }

        System.debug('##########################################################################################');
    }
}