/**
 * Created by Lambru Dmytro on 21.04.2020.
 * @description Controller for 'ContractorHierarchy' aura component.
 */
public without sharing class LA_ContractorHierarchyController {

    private static final String USER_TAB_LABEL = 'My Hierarchy';
    private static final String USER_TAB_ICON = 'utility:hierarchy';
    private static final String STATION_TAB_ICON = 'utility:groups';

    private static Map<Id, User> idToUserMap = new Map<Id, User>();
    private static Map<Id, User[]> managerIdToSubordinateUsersMap;
    private static Map<String, Account> accountIdToPersonAccountMap = new Map<String, Account>();
    private static Map<Id, ContractorInfo> userIdToContractorInfoStorageMap = new Map<Id, ContractorInfo>();

    /**
     * @description Generates hierarchy parts by the "ManagerId" field and additional stations.
     *
     * @return Response with list with hierarchy for each Contractor.
     */
    @AuraEnabled
    public static LightningResponse getContractorHierarchyParts(Payroll_Component_Configurations__mdt payrollCmpConfig) {
        LightningResponse response = new LightningResponse();

        try {
            createHelperMapsBasedOnUsers();
            ContractorHierarchyPart[] contractorHierarchyPartList = new ContractorHierarchyPart[]{};

            if ( isCurrentUserValidForHierarchy() ) {
                ContractorHierarchyPart contractorHierarchyPartForUser = createContractorHierarchyPartForUser();

                contractorHierarchyPartList.add(contractorHierarchyPartForUser);
            }

            if ( isAdditionalStationsValidForHierarchy(payrollCmpConfig) ) {
                ContractorHierarchyPart[] contractorHierarchyPartByStationList = createContractorHierarchyPartsByStations(payrollCmpConfig.Additional_Available_Stations__c);

                contractorHierarchyPartList.addAll(contractorHierarchyPartByStationList);
            }

            response.setResult(JSON.serialize(contractorHierarchyPartList));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_ContractorHierarchyController.class));
        }

        return response;
    }

    private static Boolean isCurrentUserValidForHierarchy() {
        Id userId = UserInfo.getUserId();

        return (
            idToUserMap.containsKey(userId)
            && Util.isValidIdForSObject(idToUserMap.get(userId).Employee_AccountId__c, AccountSelector.SOBJECT_TYPE)
        );
    }

    private static Boolean isAdditionalStationsValidForHierarchy(Payroll_Component_Configurations__mdt payrollCmpConfig) {

        return (
            payrollCmpConfig != null
            && payrollCmpConfig.Additional_Available_Stations__c != null
            && payrollCmpConfig.Additional_Available_Stations__c.length() > 0
        );
    }

    /**
     * @description Creates helper maps based on all active users with 'Person Account' in the system.
     */
    private static void createHelperMapsBasedOnUsers() {
        idToUserMap.putAll(new UserSelector().getAllActiveUsersWithPersonAccounts());

        if (!idToUserMap.isEmpty()) {
            Set<String> contractorPersonAccountIdSet = new Set<String>();
            managerIdToSubordinateUsersMap = new Map<Id, User[]>();

            for (User userRecord : idToUserMap.values()) {
                contractorPersonAccountIdSet.add(userRecord.Employee_AccountId__c);

                if (!managerIdToSubordinateUsersMap.containsKey(userRecord.ManagerId)) {
                    managerIdToSubordinateUsersMap.put(userRecord.ManagerId, new User[]{});
                }

                managerIdToSubordinateUsersMap.get(userRecord.ManagerId).add(userRecord);
            }

            accountIdToPersonAccountMap.putAll(new AccountSelector().getActualPersonAccountsWithContractorIdAndStationByIds(contractorPersonAccountIdSet));
        }
    }

    /**
    * @description Creates a part with a hierarchy for the user.
    *
    * @return Part with user's contractor hierarchy.
    */
    private static ContractorHierarchyPart createContractorHierarchyPartForUser() {
        ContractorHierarchyPart contractorHierarchyPart = new ContractorHierarchyPart();
        User currentUser = idToUserMap.get(UserInfo.getUserId());

        contractorHierarchyPart.label = USER_TAB_LABEL;
        contractorHierarchyPart.iconName = USER_TAB_ICON;

        if (accountIdToPersonAccountMap.containsKey(currentUser.Employee_AccountId__c)) {
            ContractorInfo contractorInformation = createContractorInfoWithSubordinatesByUser(currentUser);
            contractorHierarchyPart.contractorInfoList = new ContractorInfo[]{contractorInformation};
        }

        return contractorHierarchyPart;
    }

    /**
     * @description Creates a wrapper with information about the Contractor and his subordinates. (Contractor hierarchy)
     *              Participates in recursive calls.
     *
     * @param user User record.
     *
     * @return Wrapper with Contractor information.
     */
    private static ContractorInfo createContractorInfoWithSubordinatesByUser(User user) {
        Account contractorPersonAccount = accountIdToPersonAccountMap.get(user.Employee_AccountId__c);

        ContractorInfo contractorInformation = new ContractorInfo();
        contractorInformation.userId = user.Id;
        contractorInformation.managerId = user.ManagerId;
        contractorInformation.personAccountId = user.Employee_AccountId__c;
        contractorInformation.contractorId = contractorPersonAccount.Contractor__c;
        contractorInformation.contractorName = contractorPersonAccount.Name;
        contractorInformation.subordinateList = createListWithSubordinatesForUser(user.Id);

        return contractorInformation;
    }

    /**
     * @description Creates a list with subordinate wrappers for user.
     *              Participates in recursive calls.
     *
     * @param userId ID of the User.
     *
     * @return List with subordinate wrappers.
     */
    private static ContractorInfo[] createListWithSubordinatesForUser(Id userId) {
        ContractorInfo[] subordinateList = new ContractorInfo[]{};

        if (managerIdToSubordinateUsersMap.containsKey(userId)) {

            for (User subordinateUser : managerIdToSubordinateUsersMap.get(userId)) {

                if (accountIdToPersonAccountMap.containsKey(subordinateUser.Employee_AccountId__c)) {
                    ContractorInfo contractorInformation = createContractorInfoWithSubordinatesByUser(subordinateUser);

                    subordinateList.add(contractorInformation);
                }
            }
        }

        return subordinateList;
    }

    /**
    * @description Creates a part with hierarchy for each station.
    *
    * @param additionalAvailableStations String with additional available stations, e.g. "CTDev Kyiv Office, CTDev Lviv Office, CTDev Cherkasy Office"
    *
    * @return List with contractor hierarchy part for each station.
    */
    private static ContractorHierarchyPart[] createContractorHierarchyPartsByStations(String additionalAvailableStations) {
        ContractorHierarchyPart[] contractorHierarchyPartList = new ContractorHierarchyPart[]{};
        Map<String, ContractorInfo[]> stationToContractorInfosMap = new Map<String, ContractorInfo[]>();
        String[] additionalAvailableStationList = createListFromStringWithAdditionalAvailableStations(additionalAvailableStations);

        for (User user : idToUserMap.values()) {
            Account contractorPersonAccount = accountIdToPersonAccountMap.get(user.Employee_AccountId__c);

            if (contractorPersonAccount != null && additionalAvailableStationList.contains(contractorPersonAccount.Station__c)) {
                ContractorInfo contractorInformation = createContractorInfoWithSubordinatesByUserAndStation(user, contractorPersonAccount.Station__c);

                if (!stationToContractorInfosMap.containsKey(contractorPersonAccount.Station__c)) {
                    stationToContractorInfosMap.put(contractorPersonAccount.Station__c, new ContractorInfo[]{});
                }

                stationToContractorInfosMap.get(contractorPersonAccount.Station__c).add(contractorInformation);
            }
        }

        for (String additionalAvailableStation: additionalAvailableStationList) {
            ContractorHierarchyPart contractorHierarchyPart = new ContractorHierarchyPart();

            contractorHierarchyPart.label = additionalAvailableStation;
            contractorHierarchyPart.iconName = STATION_TAB_ICON;

            if (stationToContractorInfosMap.containsKey(additionalAvailableStation)) {
                contractorHierarchyPart.contractorInfoList = stationToContractorInfosMap.get(additionalAvailableStation);
            }

            contractorHierarchyPartList.add(contractorHierarchyPart);
        }

        return contractorHierarchyPartList;
    }

    /**
     * @description Creates a list from a string with additional available stations.
     *
     * @param additionalAvailableStations String with additional available stations, e.g. "CTDev Kyiv Office, CTDev Lviv Office, CTDev Cherkasy Office"
     *
     * @return List with with additional available stations.
     */
    private static String[] createListFromStringWithAdditionalAvailableStations(String additionalAvailableStations) {
        String[] additionalAvailableStationList = additionalAvailableStations.split(',');

        for (Integer index = 0, listSize = additionalAvailableStationList.size(); index < listSize; index++) {
            additionalAvailableStationList[index] = additionalAvailableStationList[index].trim();
        }

        return additionalAvailableStationList;
    }

    /**
     * @description Creates a wrapper with information about the Contractor and his subordinates. (Contractor hierarchy)
     *              Participates in recursive calls.
     *
     * @param user User record.
     * @param contractorStation String with additional available stations, e.g. "CTDev Kyiv Office, CTDev Lviv Office, CTDev Cherkasy Office".
     *
     * @return Wrapper with Contractor information.
     */
    private static ContractorInfo createContractorInfoWithSubordinatesByUserAndStation(User user, String contractorStation) {
        ContractorInfo contractorInformation = new ContractorInfo();

        if (userIdToContractorInfoStorageMap.containsKey(user.Id)) {
            // get from storage
            contractorInformation = userIdToContractorInfoStorageMap.get(user.Id);
        }
        else {
            Account contractorPersonAccount = accountIdToPersonAccountMap.get(user.Employee_AccountId__c);

            if (contractorPersonAccount.Station__c == contractorStation) {
                // create new and add to the storage
                contractorInformation.userId = user.Id;
                contractorInformation.managerId = user.ManagerId;
                contractorInformation.personAccountId = user.Employee_AccountId__c;
                contractorInformation.contractorId = contractorPersonAccount.Contractor__c;
                contractorInformation.contractorName = contractorPersonAccount.Name;
//                contractorInformation.subordinateList = createListWithSubordinatesByStationForUser(user.Id, contractorPersonAccount.Station__c);

                userIdToContractorInfoStorageMap.put(user.Id, contractorInformation);
            }
        }

        return contractorInformation;
    }

//    /**
//     * @description Creates a list with subordinate wrappers for user.
//     *              Participates in recursive calls.
//     *
//     * @param userId ID of the User.
//     * @param contractorStation String with additional available stations, e.g. "CTDev Kyiv Office, CTDev Lviv Office, CTDev Cherkasy Office".
//     *
//     * @return List with subordinate wrappers.
//     */
//    private static ContractorInfo[] createListWithSubordinatesByStationForUser(Id userId, String contractorStation) {
//        ContractorInfo[] subordinateList = new ContractorInfo[]{};
//
//        if (managerIdToSubordinateUsersMap.containsKey(userId)) {
//
//            for (User subordinateUser : managerIdToSubordinateUsersMap.get(userId)) {
//                Account contractorPersonAccount = accountIdToPersonAccountMap.get(subordinateUser.Employee_AccountId__c);
//
//                if (contractorPersonAccount != null && contractorPersonAccount.Station__c == contractorStation) {
//                    ContractorInfo contractorInformation = createContractorInfoWithSubordinatesByUserAndStation(subordinateUser, contractorPersonAccount.Station__c);
//
//                    subordinateList.add(contractorInformation);
//                }
//            }
//        }
//
//        return subordinateList;
//    }

    /**
    * @description Wrapper for contractor hierarchy part.
    */
    public class ContractorHierarchyPart {

        public String id;
        public String label;
        public String iconName;
        public ContractorInfo[] contractorInfoList = new ContractorInfo[]{};

        {
            this.id = String.valueOf(Crypto.getRandomLong());
        }
    }

    /**
     * @description Wrapper with information about Contractor and his subordinates.
     */
    public class ContractorInfo {

        public Id userId;
        public Id managerId;
        public Id personAccountId;
        public Id contractorId;
        public String contractorName;
        public Boolean isSelected = false;
        public Boolean isAllSubordinatesSelected = false;
        public Boolean isAccordionOpen = false;
        public ContractorInfo[] subordinateList = new ContractorInfo[]{};
    }

    /**
     * @description Wrapper for sending a response to a Lightning component
     */
    public class LightningResponse extends Model.LightningResponse {

        /* For success response with JSON data  */
        public void setResult(String data) {
            this.data = data;
            this.success = true;
        }

        /* For error response - set message */
        public void setError(String message) {
            this.message = message;
            this.success = false;
        }
    }
}