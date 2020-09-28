/**
 * Created by Lambru Dmytro on 23.04.2020.
 */

@IsTest
private class LA_ContractorHierarchyControllerTest {

    @TestSetup
    static void doSetup() {
        ContractorTestDataFactory.createPortalContractorsForHierarchy();
    }

    @IsTest
    static void testGetContractorHierarchy() {
        Payroll_Component_Configurations__mdt payrollCmpConfig = createPayrollComponentConfiguration();

        User manager_1 = [SELECT Id FROM User WHERE LastName = :ContractorTestDataFactory.DEFAULT_MANAGER_NAME + '1' LIMIT 1];
        User manager_2 = [SELECT Id FROM User WHERE LastName = :ContractorTestDataFactory.DEFAULT_MANAGER_NAME + '2' LIMIT 1];

        Test.startTest();
            System.runAs(manager_1) {
                Model.LightningResponse response = LA_ContractorHierarchyController.getContractorHierarchyParts(payrollCmpConfig);

                System.assert(response.success, 'Response must be successful');

                LA_ContractorHierarchyController.ContractorHierarchyPart[] contractorHierarchyPartList = (LA_ContractorHierarchyController.ContractorHierarchyPart[]) JSON.deserialize(response.data, LA_ContractorHierarchyController.ContractorHierarchyPart[].class);

                System.assert(contractorHierarchyPartList.size() > 0, 'List must be with elements');

                validateCurrentUserHierarchy(contractorHierarchyPartList[0].contractorInfoList);
                validateContractorHierarchyParts(contractorHierarchyPartList);
            }

            System.runAs(manager_2) {
                Model.LightningResponse response = LA_ContractorHierarchyController.getContractorHierarchyParts(payrollCmpConfig);

                System.assert(response.success, 'Response must be successful');

                LA_ContractorHierarchyController.ContractorHierarchyPart[] contractorHierarchyPartList = (LA_ContractorHierarchyController.ContractorHierarchyPart[]) JSON.deserialize(response.data, LA_ContractorHierarchyController.ContractorHierarchyPart[].class);

                System.assert(contractorHierarchyPartList.size() > 0, 'List must be with elements');

                validateCurrentUserHierarchy(contractorHierarchyPartList[0].contractorInfoList);
                validateContractorHierarchyParts(contractorHierarchyPartList);
            }
        Test.stopTest();
    }

    static Payroll_Component_Configurations__mdt createPayrollComponentConfiguration() {
        String[] stationPicklistValueList = new String[]{
            ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_KYIV_OFFICE),
            ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_LVIV_OFFICE),
            ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_CHERKASY_OFFICE)
        };

        return new Payroll_Component_Configurations__mdt(
            // e.g. Additional_Available_Stations__c = "CTDev Kyiv Office, CTDev Lviv Office, CTDev Cherkasy Office"
            Additional_Available_Stations__c = stationPicklistValueList.toString().removeStart('(').removeEnd(')')
        );
    }

    static void validateCurrentUserHierarchy(LA_ContractorHierarchyController.ContractorInfo[] contractorInfoList) {

        for (LA_ContractorHierarchyController.ContractorInfo managerContractorInfo : contractorInfoList) {
            System.assert(managerContractorInfo.contractorName.contains(ContractorTestDataFactory.DEFAULT_MANAGER_NAME), 'The name must contain the default name of the manager');

            for (LA_ContractorHierarchyController.ContractorInfo pmContractorInfo : managerContractorInfo.subordinateList) {
                System.assert(pmContractorInfo.contractorName.contains(ContractorTestDataFactory.DEFAULT_PM_NAME), 'The name must contain the default name of the PM');

                for (LA_ContractorHierarchyController.ContractorInfo teamLeaderContractorInfo : pmContractorInfo.subordinateList) {
                    System.assert(teamLeaderContractorInfo.contractorName.contains(ContractorTestDataFactory.DEFAULT_TEAM_LEADER_NAME), 'The name must contain the default name of the team leader');

                    for (LA_ContractorHierarchyController.ContractorInfo contractorInfo : teamLeaderContractorInfo.subordinateList) {
                        System.assert(contractorInfo.contractorName.contains(ContractorTestDataFactory.DEFAULT_CONTRACTOR_NAME), 'The name must contain the default name of the contractor');
                    }
                }
            }
        }
    }

    static void validateContractorHierarchyParts(LA_ContractorHierarchyController.ContractorHierarchyPart[] contractorHierarchyPartList) {

        for (LA_ContractorHierarchyController.ContractorHierarchyPart contractorHierarchyPart : contractorHierarchyPartList) {
            System.assert(String.isNotBlank(contractorHierarchyPart.id));
            System.assert(String.isNotBlank(contractorHierarchyPart.iconName));
            System.assert(String.isNotBlank(contractorHierarchyPart.label));
            System.assert(contractorHierarchyPart.contractorInfoList.size() > 0, 'The list must have items. PART LIST: ' + JSON.serializePretty(contractorHierarchyPartList));
        }
    }
}