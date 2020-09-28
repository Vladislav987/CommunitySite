/**
 * Created by Lambru Dmytro on 22.07.2020.
 */
public without sharing class Util_ContractorHierarchy {

    private static Map<Id, User> ID_TO_USER_MAP;
    private static Map<Id, User[]> MANAGER_ID_TO_SUBORDINATE_USERS_MAP;
    private static Map<String, Account> ID_TO_ACCOUNT_MAP;

    static {
        createHelperMapsBasedOnUsers();
    }

    public static ContractorHierarchyInfo getInfo() {
        return new ContractorHierarchyInfo();
    }

    /**
     * @description Creates helper maps based on all active users with 'Person Account' in the system.
     */
    private static void createHelperMapsBasedOnUsers() {
        Set<String> contractorPersonAccountIdSet = new Set<String>();
        ID_TO_USER_MAP = new Map<Id, User>( getActiveUsersWithPersonAccountId() );
        MANAGER_ID_TO_SUBORDINATE_USERS_MAP = new Map<Id, User[]>();

        for (User userRecord : ID_TO_USER_MAP.values()) {
            contractorPersonAccountIdSet.add(userRecord.Employee_AccountId__c);

            if (String.isNotBlank(userRecord.ManagerId)) {

                if (!MANAGER_ID_TO_SUBORDINATE_USERS_MAP.containsKey(userRecord.ManagerId)) {
                    MANAGER_ID_TO_SUBORDINATE_USERS_MAP.put(userRecord.ManagerId, new User[]{});
                }

                MANAGER_ID_TO_SUBORDINATE_USERS_MAP.get(userRecord.ManagerId).add(userRecord);
            }
        }

        ID_TO_ACCOUNT_MAP = new Map<String, Account>( getActivePersonAccountsByIds(contractorPersonAccountIdSet) );
    }

    private static User[] getActiveUsersWithPersonAccountId() {

        return [
            SELECT
                Id,
                ManagerId,
                Employee_AccountId__c
            FROM User
            WHERE IsActive = TRUE
            AND Employee_AccountId__c <> NULL
            LIMIT 10000
        ];
    }

    private static Account[] getActivePersonAccountsByIds(Set<String> contractorPersonAccountIdSet) {

        return [
            SELECT
                Id,
                Contractor__c,
                Station__c
            FROM Account
            WHERE Id IN :contractorPersonAccountIdSet
            AND IsPersonAccount = TRUE
            AND Active__c = TRUE
            LIMIT 10000
        ];
    }

    public class ContractorHierarchyInfo {

        public Map<Id, User> idToUserMap { public get; private set; }
        public Map<Id, User[]> managerIdToSubordinateUsersMap { public get; private set; }
        public Map<String, Account> idToAccountMap { public get; private set; }

        public Set<Id> subordinateUserIdSet { public get; private set; }
        public Set<Id> subordinateAccountIdSet { public get; private set; }
        public Set<Id> subordinateContractorIdSet { public get; private set; }

        {
            this.idToUserMap = ID_TO_USER_MAP;
            this.managerIdToSubordinateUsersMap = MANAGER_ID_TO_SUBORDINATE_USERS_MAP;
            this.idToAccountMap = ID_TO_ACCOUNT_MAP;
        }

        public ContractorHierarchyInfo updateSubordinatesByUserId(Id userId) {
            this.clearSubordinates();
            this.addSubordinatesByUserId(userId);

            return this;
        }

        public ContractorHierarchyInfo updateSubordinatesByAdditionalStations(String additionalStations) {
            this.clearSubordinates();
            this.addSubordinatesByAdditionalStations(additionalStations);

            return this;
        }

        public ContractorHierarchyInfo updateSubordinatesByUserIdAndAdditionalStations(Id userId, String additionalStations) {
            this.clearSubordinates();
            this.addSubordinatesByUserId(userId);
            this.addSubordinatesByAdditionalStations(additionalStations);

            return this;
        }

        private void clearSubordinates() {
            this.subordinateUserIdSet = new Set<Id>();
            this.subordinateAccountIdSet = new Set<Id>();
            this.subordinateContractorIdSet = new Set<Id>();
        }

        private void addSubordinatesByUserId(Id userId) {

            if ( managerIdToSubordinateUsersMap.containsKey(userId) ) {

                for (User user : managerIdToSubordinateUsersMap.get(userId)) {
                    Account account = idToAccountMap.get(user.Employee_AccountId__c);

                    if (account != null) {
                        subordinateUserIdSet.add(user.Id);
                        subordinateAccountIdSet.add(account.Id);
                        subordinateContractorIdSet.add(account.Contractor__c);

                        addSubordinatesByUserId(user.Id);
                    }
                }
            }
        }

        private void addSubordinatesByAdditionalStations(String additionalStations) {

            if (additionalStations != null) {
                String[] additionalStationList = this.createListFromStringWithAdditionalStations(additionalStations);

                for (User user : this.idToUserMap.values()) {
                    Account account = idToAccountMap.get(user.Employee_AccountId__c);

                    if (account != null && additionalStationList.contains(account.Station__c)) {
                        subordinateUserIdSet.add(user.Id);
                        subordinateAccountIdSet.add(account.Id);
                        subordinateContractorIdSet.add(account.Contractor__c);
                    }
                }
            }
        }

        /**
         * @description Creates a list from a string with additional available stations.
         *
         * @param additionalStations String with additional available stations, e.g. "CTDev Kyiv Office, CTDev Lviv Office, CTDev Cherkasy Office"
         *
         * @return List with with additional available stations.
         */
        private String[] createListFromStringWithAdditionalStations(String additionalStations) {
            String[] additionalAvailableStationList = additionalStations.split(',');

            for (Integer index = 0, listSize = additionalAvailableStationList.size(); index < listSize; index++) {
                additionalAvailableStationList[index] = additionalAvailableStationList[index].trim();
            }

            return additionalAvailableStationList;
        }
    }
}