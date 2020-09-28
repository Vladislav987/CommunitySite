/**
 * Created by Lambru Dmytro on 23.07.2020.
 */
@IsTest
private class Util_ContractorHierarchyTest {
    static String MSG_MAP_NOT_EMPTY = 'Map should not be empty.';

    @TestSetup
    static void doSetup() {
        ContractorTestDataFactory.createPortalContractorsForHierarchy();
    }

    @IsTest
    static void test_getInfo() {
        Util_ContractorHierarchy.ContractorHierarchyInfo contractorHierarchyInfo = Util_ContractorHierarchy.getInfo();

        System.assert(!contractorHierarchyInfo.idToUserMap.isEmpty(), MSG_MAP_NOT_EMPTY);
        System.assert(!contractorHierarchyInfo.managerIdToSubordinateUsersMap.isEmpty(), MSG_MAP_NOT_EMPTY);
        System.assert(!contractorHierarchyInfo.idToAccountMap.isEmpty(), MSG_MAP_NOT_EMPTY);
    }

    @IsTest
    static void test_wrapper_updateSubordinatesByUserId() {
        User manager_1 = [SELECT Id FROM User WHERE LastName = :ContractorTestDataFactory.DEFAULT_MANAGER_NAME + '1' LIMIT 1];

        System.runAs(manager_1) {
            Util_ContractorHierarchy.ContractorHierarchyInfo contractorHierarchyInfo
                = Util_ContractorHierarchy.getInfo().updateSubordinatesByUserId(UserInfo.getUserId());

            System.assert(!contractorHierarchyInfo.subordinateUserIdSet.isEmpty(), MSG_MAP_NOT_EMPTY);
            System.assert(!contractorHierarchyInfo.subordinateAccountIdSet.isEmpty(), MSG_MAP_NOT_EMPTY);
            System.assert(!contractorHierarchyInfo.subordinateContractorIdSet.isEmpty(), MSG_MAP_NOT_EMPTY);
        }
    }

    @IsTest
    static void test_wrapper_updateSubordinatesByAdditionalStations() {
        String contractorAdditionalStations = getContractorAdditionalStations();
        User manager_1 = [SELECT Id FROM User WHERE LastName = :ContractorTestDataFactory.DEFAULT_MANAGER_NAME + '1' LIMIT 1];

        System.runAs(manager_1) {
            Util_ContractorHierarchy.ContractorHierarchyInfo contractorHierarchyInfo
                = Util_ContractorHierarchy.getInfo().updateSubordinatesByAdditionalStations(contractorAdditionalStations);

            System.assert(!contractorHierarchyInfo.subordinateUserIdSet.isEmpty(), MSG_MAP_NOT_EMPTY);
            System.assert(!contractorHierarchyInfo.subordinateAccountIdSet.isEmpty(), MSG_MAP_NOT_EMPTY);
            System.assert(!contractorHierarchyInfo.subordinateContractorIdSet.isEmpty(), MSG_MAP_NOT_EMPTY);
        }
    }

    @IsTest
    static void test_wrapper_updateSubordinatesByUserIdAndAdditionalStations() {
        String contractorAdditionalStations = getContractorAdditionalStations();
        User manager_1 = [SELECT Id FROM User WHERE LastName = :ContractorTestDataFactory.DEFAULT_MANAGER_NAME + '1' LIMIT 1];

        System.runAs(manager_1) {
            Util_ContractorHierarchy.ContractorHierarchyInfo contractorHierarchyInfo
                = Util_ContractorHierarchy.getInfo().updateSubordinatesByUserIdAndAdditionalStations(UserInfo.getUserId(), contractorAdditionalStations);

            System.assert(!contractorHierarchyInfo.subordinateUserIdSet.isEmpty(), MSG_MAP_NOT_EMPTY);
            System.assert(!contractorHierarchyInfo.subordinateAccountIdSet.isEmpty(), MSG_MAP_NOT_EMPTY);
            System.assert(!contractorHierarchyInfo.subordinateContractorIdSet.isEmpty(), MSG_MAP_NOT_EMPTY);
        }
    }

    static String getContractorAdditionalStations() {
        String[] contractorAdditionalStationList = new String[]{
            ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_KYIV_OFFICE),
            ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_LVIV_OFFICE),
            ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_CHERKASY_OFFICE)
        };

        // e.g. 'CTDev Kyiv Office, CTDev Lviv Office, CTDev Cherkasy Office'
       return String.join(contractorAdditionalStationList, ',');
    }
}