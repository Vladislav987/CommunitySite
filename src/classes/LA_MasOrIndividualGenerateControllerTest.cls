/**
 * Created by Kropinova Mariya on 23.04.2020.
 */
@IsTest
public with sharing class LA_MasOrIndividualGenerateControllerTest {

    public static final Map<DepartmentPicklistKey, String> DEPARTMENT_PICKLIST_API_NAME_MAP = new Map<DepartmentPicklistKey, String>{
            DepartmentPicklistKey.CTDEV_KYIV_OFFICE => 'SFDC_Department_Kyiv',
            DepartmentPicklistKey.CTDEV_CHERKASY_OFFICE => 'SFDC_Department_Cherkasy'
    };

    public static final Map<SubDepartmentPicklistKey, String> SUB_DEPARTMENT_PICKLIST_API_NAME_MAP = new Map<SubDepartmentPicklistKey, String>{
            SubDepartmentPicklistKey.CTDEV_KYIV_OFFICE_iOS => 'SFDC_Department_Sub_iOS_Kyiv',
            SubDepartmentPicklistKey.CTDEV_KYIV_OFFICE_E_T => 'E_T_Sub_Delevopment_Kyiv'
    };

    public static final Map<MasterLabelPicklistKey, String> MASTER_LABEL_PICKLIST_NAME_MAP = new Map<MasterLabelPicklistKey, String>{
            MasterLabelPicklistKey.MASTER_LABEL_KYIV_OFFICE => 'SFDC Department Kyiv',
            MasterLabelPicklistKey.MASTER_LABEL_CHERKASY_OFFICE => 'SFDC Department Cherkasy',
            MasterLabelPicklistKey.MASTER_LABEL_KYIV_OFFICE_iOS => 'SFDC Department Sub iOS Kyiv',
            MasterLabelPicklistKey.MASTER_LABEL_KYIV_OFFICE_E_T => 'E&T Sub Delevopment Kyiv'
    };

    public enum DepartmentPicklistKey { CTDEV_KYIV_OFFICE,  CTDEV_CHERKASY_OFFICE }
    public enum SubDepartmentPicklistKey { CTDEV_KYIV_OFFICE_iOS,  CTDEV_KYIV_OFFICE_E_T }
    public enum MasterLabelPicklistKey { MASTER_LABEL_KYIV_OFFICE,  MASTER_LABEL_CHERKASY_OFFICE, MASTER_LABEL_KYIV_OFFICE_iOS, MASTER_LABEL_KYIV_OFFICE_E_T }

    @TestSetup
    static void doSetup() {
        ContractorTestDataFactory.createPortalContractorsForMasOrIndividualGenerate();
    }

    @IsTest
    private static void getIndividualPersonalAccountTest() {
        Payroll_Component_Configurations__mdt payrollCmpConfig = createPayrollComponentConfiguration();
        List<String> mustBeInSubordinates = new List<String> {
            ContractorTestDataFactory.DEFAULT_TEAM_LEADER_NAME + '1',
            ContractorTestDataFactory.DEFAULT_CONTRACTOR_NAME + '1',
            ContractorTestDataFactory.DEFAULT_CONTRACTOR_NAME + '2'
        };

        List<String> mustBeInSubordinatesByStations = new List<String> {
            ContractorTestDataFactory.DEFAULT_TEAM_LEADER_NAME + '2',
            ContractorTestDataFactory.DEFAULT_CONTRACTOR_NAME + '3',
            ContractorTestDataFactory.DEFAULT_CONTRACTOR_NAME + '4',
            ContractorTestDataFactory.DEFAULT_PM_NAME + '1',
            ContractorTestDataFactory.DEFAULT_PM_NAME + '2',
            ContractorTestDataFactory.DEFAULT_MANAGER_NAME + '2'
        };

        User manager_1 = [SELECT Id FROM User WHERE LastName = :ContractorTestDataFactory.DEFAULT_TEAM_LEADER_NAME + '1' LIMIT 1];

        Test.startTest();

            System.runAs(manager_1) {
                Model.LightningResponse response1 = LA_MasOrIndividualGenerateController.getIndividualPersonalAccount(ContractorTestDataFactory.DEFAULT_CONTRACTOR_NAME + '1', payrollCmpConfig);
                System.assert(response1.success, 'Response must be successful');

                // All subordinates has been found without restriction by Station
                LA_MasOrIndividualGenerateController.ContractorAccountInfo[] contractorAccountHierarchyConfig = LA_MasOrIndividualGenerateController.contractorAccountHierarchyConfig;
                System.assert(contractorAccountHierarchyConfig.size() > 0, 'List must be with elements');
                //check if contains all subordinates without restriction by Station
                validateUserHierarchy(contractorAccountHierarchyConfig, mustBeInSubordinates);

                // All subordinates has been found with restriction by Station
                LA_MasOrIndividualGenerateController.ContractorAccountInfo[] contractorAccountHierarchyConfigsByStation = LA_MasOrIndividualGenerateController.contractorAccountHierarchyConfigsByStation;
                System.assert(contractorAccountHierarchyConfigsByStation.size() > 0, 'List must be with elements');
                validateUserHierarchy(contractorAccountHierarchyConfigsByStation, mustBeInSubordinatesByStations);

                // All subordinates has been found by Station with condition DEFAULT_CONTRACTOR_NAME + '1'
                LA_MasOrIndividualGenerateController.ContractorAccountInfo[] contractorAccountInfo = (LA_MasOrIndividualGenerateController.ContractorAccountInfo[]) JSON.deserialize(response1.data, LA_MasOrIndividualGenerateController.ContractorAccountInfo[].class);
                System.assert(contractorAccountInfo.size() > 0, 'List must be with elements');

            }
        Test.stopTest();
    }

    @IsTest
    private static void getMassPersonalAccountEmptyConditionTest() {
        Payroll_Component_Configurations__mdt payrollCmpConfig = createPayrollComponentConfiguration();
        createMasFiltersComponentConfiguration();

        List<String> mustBeInSubordinatesByStationsEmptyCond = new List<String> {
            ContractorTestDataFactory.DEFAULT_TEAM_LEADER_NAME + '1',
            ContractorTestDataFactory.DEFAULT_TEAM_LEADER_NAME + '2',
            ContractorTestDataFactory.DEFAULT_CONTRACTOR_NAME + '1',
            ContractorTestDataFactory.DEFAULT_CONTRACTOR_NAME + '2',
            ContractorTestDataFactory.DEFAULT_CONTRACTOR_NAME + '3',
            ContractorTestDataFactory.DEFAULT_CONTRACTOR_NAME + '4',
            ContractorTestDataFactory.DEFAULT_PM_NAME + '1',
            ContractorTestDataFactory.DEFAULT_PM_NAME + '2',
            ContractorTestDataFactory.DEFAULT_MANAGER_NAME + '2'
        };

        User manager_1 = [SELECT Id FROM User WHERE LastName = :ContractorTestDataFactory.DEFAULT_TEAM_LEADER_NAME + '1' LIMIT 1];
        List<String> queryConditionArr = new  List<String>();

        Test.startTest();

            System.runAs(manager_1) {
                // All subordinates has been found with restriction by Station and empty queryConditionArr
                Model.LightningResponse response = LA_MasOrIndividualGenerateController.getMassPersonalAccount(queryConditionArr, payrollCmpConfig);
                System.assert(response.success, 'Response must be successful');

                // All subordinates has been found with restriction by Station without condition
                List<Account> subordinateAccountList = LA_MasOrIndividualGenerateController.subordinateAccountIdToPersonAccountMap.values();
                System.assert(subordinateAccountList.size() > 0, 'List must be with elements');

                // Amount all subordinates has been found by Station with empty condition should be equals amount all subordinates has been found by Station without empty condition
                LA_MasOrIndividualGenerateController.ContractorAccountInfo[] contractorAccountInfoList = (LA_MasOrIndividualGenerateController.ContractorAccountInfo[]) JSON.deserialize(response.data, LA_MasOrIndividualGenerateController.ContractorAccountInfo[].class);
                System.assertEquals(contractorAccountInfoList.size(), subordinateAccountList.size());
                validateUserHierarchy(contractorAccountInfoList, mustBeInSubordinatesByStationsEmptyCond);
            }
        Test.stopTest();
    }

    @IsTest
    private static void getMassPersonalAccountWithConditionTest() {
        Payroll_Component_Configurations__mdt payrollCmpConfig = createPayrollComponentConfiguration();
        createMasFiltersComponentConfiguration();

        User manager_1 = [SELECT Id FROM User WHERE LastName = :ContractorTestDataFactory.DEFAULT_TEAM_LEADER_NAME + '1' LIMIT 1];

        List<String> queryConditionArr = new  List<String> {
                DEPARTMENT_PICKLIST_API_NAME_MAP.get(DepartmentPicklistKey.CTDEV_KYIV_OFFICE),
                SUB_DEPARTMENT_PICKLIST_API_NAME_MAP.get(SubDepartmentPicklistKey.CTDEV_KYIV_OFFICE_IOS)
        };

        Test.startTest();

            System.runAs(manager_1) {
                Model.LightningResponse response = LA_MasOrIndividualGenerateController.getMassPersonalAccount(queryConditionArr, payrollCmpConfig);
                System.assert(response.success, 'Response must be successful');

                // All subordinates has been found with restriction by Station without condition
                List<Account> subordinateAccountList = LA_MasOrIndividualGenerateController.subordinateAccountIdToPersonAccountMap.values();
                System.assert(subordinateAccountList.size() > 0, 'List must be with elements');

                // All subordinates has been found with restriction by Station and queryConditionArr
                LA_MasOrIndividualGenerateController.ContractorAccountInfo[] contractorAccountInfoList = (LA_MasOrIndividualGenerateController.ContractorAccountInfo[]) JSON.deserialize(response.data, LA_MasOrIndividualGenerateController.ContractorAccountInfo[].class);
                System.assert(contractorAccountInfoList.size() > 0, 'List must be with elements');
            }
        Test.stopTest();
    }

    @IsTest
    private static void getPayRollCmpConfigFieldsTest() {
        Payroll_Component_Configurations__mdt payrollConfig = createPayrollComponentConfigurationForLayout();
        List<Payroll_Component_Configuration_Field__mdt> payrollConfigFieldsList = createPayrollConfigFieldsListConfigurationForLayout();

        Test.startTest();
            Model.LightningResponse response = LA_MasOrIndividualGenerateController.getPayRollCmpConfigFields(payrollConfig, payrollConfigFieldsList);
            LA_MasOrIndividualGenerateController.LayoutConfig layoutData = (LA_MasOrIndividualGenerateController.LayoutConfig) JSON.deserialize(response.data, LA_MasOrIndividualGenerateController.LayoutConfig.class);

            System.assertEquals('Generate bonuses', layoutData.buttonName);
            System.assertEquals('Bonus', layoutData.recordType);
            System.assertEquals('Recurrent_Bonus', layoutData.recordTypeRecurrent);
            System.assertEquals('lightning:input', layoutData.componentConfigList[0].cmpName);
            System.assertEquals(false,  layoutData.componentConfigList[0].isRecurrent);
            System.assertEquals(false,  layoutData.componentConfigList[0].isHidden);
        Test.stopTest();
    }

    @IsTest
    public static void createPayrollDataTest() {
        String payrollDataToInsert = generateLayoutData();

        Test.startTest();
            Model.LightningResponse response = LA_MasOrIndividualGenerateController.createPayrollData(payrollDataToInsert);
            System.assert(response.success, 'Response must be successful');
        Test.stopTest();
    }

    @IsTest
    public static void getDropdownCategoriesTest() {
        createMasFiltersComponentConfiguration();

        Test.startTest();
            Model.LightningResponse response = LA_MasOrIndividualGenerateController.getDropdownCategories();
            System.assert(response.success, 'Response must be successful');
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

    static List<Payroll_Mass_Planning_Filters__mdt> createMasFiltersComponentConfiguration() {
        List<Payroll_Mass_Planning_Filters__mdt> massFilters = new List<Payroll_Mass_Planning_Filters__mdt>();

        String[] developerNamePicklistValueList = new String[] {
            DEPARTMENT_PICKLIST_API_NAME_MAP.get(DepartmentPicklistKey.CTDEV_KYIV_OFFICE),
            DEPARTMENT_PICKLIST_API_NAME_MAP.get(DepartmentPicklistKey.CTDEV_CHERKASY_OFFICE),
            SUB_DEPARTMENT_PICKLIST_API_NAME_MAP.get(SubDepartmentPicklistKey.CTDEV_KYIV_OFFICE_iOS),
            SUB_DEPARTMENT_PICKLIST_API_NAME_MAP.get(SubDepartmentPicklistKey.CTDEV_KYIV_OFFICE_E_T)
        };

        String[] masterLabelPicklistValueList = new String[] {
                MASTER_LABEL_PICKLIST_NAME_MAP.get(MasterLabelPicklistKey.MASTER_LABEL_KYIV_OFFICE),
                MASTER_LABEL_PICKLIST_NAME_MAP.get(MasterLabelPicklistKey.MASTER_LABEL_CHERKASY_OFFICE),
                MASTER_LABEL_PICKLIST_NAME_MAP.get(MasterLabelPicklistKey.MASTER_LABEL_KYIV_OFFICE_iOS),
                MASTER_LABEL_PICKLIST_NAME_MAP.get(MasterLabelPicklistKey.MASTER_LABEL_KYIV_OFFICE_E_T)
        };

        String[] sOQLConditionsPicklistValueList = new String[] {
            'isPersonAccount = true AND Contractor__r.Station__c = \'CTDev Cherkasy Office\' AND Contractor__r.Department__c = \'SFDC Department\'',
            'isPersonAccount = true AND Contractor__r.Station__c = \'CTDev Kiev Office\' AND Contractor__r.Department__c = \'SFDC Department\'',
            'isPersonAccount = true AND Contractor__r.Station__c = \'CTDev Kiev Office\' AND Contractor__r.Department__c = \'SFDC Department\' AND Contractor__r.Sub_Department__c = \'iOS\'',
            'isPersonAccount = true AND Contractor__r.Station__c = \'CTDev Kiev Office\' AND Contractor__r.Department__c = \'Enterprise & Technology\' AND Contractor__r.Sub_Department__c = \'Development\''

        };

        String[] categoryPicklistValueList = new String[] {
            'Department',
            'Sub-Department'
        };

        for (Integer i = 0; i < 4; i++) {

            massFilters.add(new Payroll_Mass_Planning_Filters__mdt (
                DeveloperName = developerNamePicklistValueList[i],
                MasterLabel = masterLabelPicklistValueList[i],
                SOQL_Conditions__c = sOQLConditionsPicklistValueList[i]
            ));
        }

        massFilters[0].Category__c = categoryPicklistValueList[0];
        massFilters[1].Category__c = categoryPicklistValueList[0];
        massFilters[2].Category__c = categoryPicklistValueList[1];
        massFilters[3].Category__c = categoryPicklistValueList[1];

        return massFilters;
    }

    static Payroll_Component_Configurations__mdt createPayrollComponentConfigurationForLayout() {

        return new Payroll_Component_Configurations__mdt(
                Allow_recurrence__c = true, Generate_Button_Title__c = 'Generate bonuses',
                RecordType__c = 'Bonus', RecordType_recurrent__c = 'Recurrent_Bonus'
        );
    }

    static List<Payroll_Component_Configuration_Field__mdt> createPayrollConfigFieldsListConfigurationForLayout() {
        List<Payroll_Component_Configuration_Field__mdt> payrollConfigFieldsList = new List<Payroll_Component_Configuration_Field__mdt>();
        Payroll_Component_Configurations__mdt payrollConfig = createPayrollComponentConfigurationForLayout();

        payrollConfigFieldsList.add( new Payroll_Component_Configuration_Field__mdt(
                Field_API_Name__c = 'StartDate__c', Is_Hidden__c = false, Order__c = 4,
                Payroll_Component_Configurations__c = payrollConfig.Id, Recurrent_Only__c = false,
                Required__c = true, Title__c = 'Bonus start date'
        ));
        payrollConfigFieldsList.add( new Payroll_Component_Configuration_Field__mdt(
                Field_API_Name__c = 'CurrencyIsoCode', Is_Hidden__c = false, Order__c = 2,
                Payroll_Component_Configurations__c = payrollConfig.Id, Recurrent_Only__c = false,
                Required__c = true, Title__c = 'Currency'
        ));
        payrollConfigFieldsList.add( new Payroll_Component_Configuration_Field__mdt(
                DefaultValue__c = 'Increment',
                Field_API_Name__c = 'SumType__c', Is_Hidden__c = true, Order__c = 6,
                Payroll_Component_Configurations__c = payrollConfig.Id, Recurrent_Only__c = false,
                Required__c = false, Title__c = 'Sum Type'
        ));
        payrollConfigFieldsList.add( new Payroll_Component_Configuration_Field__mdt(
                Field_API_Name__c = 'Reason__c', Is_Hidden__c = false, Order__c = 3,
                Payroll_Component_Configurations__c = payrollConfig.Id, Recurrent_Only__c = false,
                Required__c = true, Title__c = 'Reason'
        ));
        payrollConfigFieldsList.add( new Payroll_Component_Configuration_Field__mdt(
                Field_API_Name__c = 'Sum__c', Is_Hidden__c = false, Order__c = 1,
                Payroll_Component_Configurations__c = payrollConfig.Id, Recurrent_Only__c = false,
                Required__c = true, Title__c = 'Sum'
        ));
        payrollConfigFieldsList.add( new Payroll_Component_Configuration_Field__mdt(
                Field_API_Name__c = 'EndDate__c', Is_Hidden__c = false, Order__c = 5,
                Payroll_Component_Configurations__c = payrollConfig.Id, Recurrent_Only__c = true,
                Required__c = true, Title__c = 'Bonus end date'
        ));

        return payrollConfigFieldsList;
    }

    static String generateLayoutData() {
        LA_MasOrIndividualGenerateController.GenerateLayoutData generateLayoutData = new LA_MasOrIndividualGenerateController.GenerateLayoutData();
        LA_MasOrIndividualGenerateController.ContractorAccountInfo[] contractorAccountInfo;

        Payroll_Component_Configurations__mdt payrollCmpConfig = createPayrollComponentConfiguration();
        User manager_1 = [SELECT Id FROM User WHERE LastName = :ContractorTestDataFactory.DEFAULT_TEAM_LEADER_NAME + '1' LIMIT 1];

        System.runAs(manager_1) {
            Model.LightningResponse response = LA_MasOrIndividualGenerateController.getIndividualPersonalAccount(ContractorTestDataFactory.DEFAULT_CONTRACTOR_NAME + '1', payrollCmpConfig);

            // All subordinates has been found by Station with condition DEFAULT_CONTRACTOR_NAME + '1'
           contractorAccountInfo = (LA_MasOrIndividualGenerateController.ContractorAccountInfo[]) JSON.deserialize(response.data, LA_MasOrIndividualGenerateController.ContractorAccountInfo[].class);
        }

        generateLayoutData.contractorAccountInfo = contractorAccountInfo;
        generateLayoutData.recordTypeAPIName = 'Bonus';

        generateLayoutData.dataForm.add(new LA_MasOrIndividualGenerateController.DataPayrollCmp('false', 'Recurrent__c', 'checkbox'));
        generateLayoutData.dataForm.add(new LA_MasOrIndividualGenerateController.DataPayrollCmp('33', 'Sum__c', 'number'));
        generateLayoutData.dataForm.add(new LA_MasOrIndividualGenerateController.DataPayrollCmp('USD', 'CurrencyIsoCode', 'string'));
        generateLayoutData.dataForm.add(new LA_MasOrIndividualGenerateController.DataPayrollCmp('33', 'Reason__c', 'text'));
        generateLayoutData.dataForm.add(new LA_MasOrIndividualGenerateController.DataPayrollCmp('2020-07-15', 'StartDate__c', 'date'));
        generateLayoutData.dataForm.add(new LA_MasOrIndividualGenerateController.DataPayrollCmp('Increment', 'SumType__c', 'string'));

        return JSON.serialize(generateLayoutData);
    }

    static void validateUserHierarchy(LA_MasOrIndividualGenerateController.ContractorAccountInfo[] contractorInfoList, List<String> mustBeInSubordinates) {

        List<String> allNames = new List<String>();
        for ( Integer i = 0; i < contractorInfoList.size(); i++) {
            allNames.add(contractorInfoList[i].accountName);
        }
        for ( Integer j = 0; j < mustBeInSubordinates.size(); j++) {
            System.assert(allNames.contains(mustBeInSubordinates[j]), 'The name must contain the default name of the ' + mustBeInSubordinates[j]);
        }
    }

}