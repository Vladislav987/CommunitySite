/**
 * Created by Kropinova Mariya on 16.04.2020.
 */

public without sharing class LA_MasOrIndividualGenerateController {

    private static final String LABEL_IS_RECURRENT = 'Is Recurrent';
    private static final String LIGHTNING_INPUT_NAME = 'lightning:input';
    private static final String UTIL_DYNAMIC_PICKLIST_NAME = 'c:Util_DynamicPicklist';

    private static LightningResponse response = new LightningResponse();
    private static Map<Id, User> userIdToRecord= new Map<Id, User>();
    private static Map<String, Account> accountIdToPersonAccountMap = new Map<String, Account>();
    private static Map<Id, ContractorAccountInfo> userIdToContractorAccountInfoStorageMap = new Map<Id, ContractorAccountInfo>();
    private static Map<Id, User[]> managerIdToSubordinateUsersMap = new  Map<Id,  User[]>();
    private static Map<String, SObjectField> fieldNameToSObjectField = PayrollComponentSelector.SOBJECT_TYPE.getDescribe().fields.getMap();
    @TestVisible
    private static Map<String, Account> subordinateAccountIdToPersonAccountMap = new  Map<String, Account>();
    @TestVisible
    private static List<ContractorAccountInfo> contractorAccountHierarchyConfig = new List<ContractorAccountInfo>();
    @TestVisible
    private static List<ContractorAccountInfo> contractorAccountHierarchyConfigsByStation = new List<ContractorAccountInfo>();

    private static final Map<DisplayType, String> CMP_NAME_VALUES_MAP = new Map<DisplayType, String> {
            DisplayType.STRING => LIGHTNING_INPUT_NAME,
            DisplayType.BOOLEAN => LIGHTNING_INPUT_NAME,
            DisplayType.CURRENCY => LIGHTNING_INPUT_NAME,
            DisplayType.DATE => LIGHTNING_INPUT_NAME,
            DisplayType.PICKLIST => UTIL_DYNAMIC_PICKLIST_NAME
    };

    private final static Map<DisplayType, String> FIELD_TYPE_TO_CMP_MAP = new Map<DisplayType, String> {
            DisplayType.BOOLEAN => 'checkbox',
            DisplayType.CURRENCY => 'number',
            DisplayType.DATE => 'date',
            DisplayType.PICKLIST => 'string'
    };

    private final static Map<DisplayType, String> ATTRIBUTE_DATA_TYPE_MAP = new Map<DisplayType, String> {
            DisplayType.REFERENCE => 'reference',
            DisplayType.STRING => 'string',
            DisplayType.BOOLEAN => 'boolean',
            DisplayType.PICKLIST => 'array',
            DisplayType.DATE => 'date'
    };

    private static List<ContractorAccountInfo> findContractors(String searchKeyWord, List<ContractorAccountInfo> contractorAccountHierarchyConfigsAll) {
        List<ContractorAccountInfo> foundContractorAccountHierarchyConfigs = new List<ContractorAccountInfo>();
        Map<Id, ContractorAccountInfo> idToContractorAccountInfoMap = mapIdToContractorAccountInfo(contractorAccountHierarchyConfigsAll);
        Set<String> personAccountIdSet = (Set<String>) JSON.deserialize(JSON.serialize(idToContractorAccountInfoMap.keySet()), Set<String>.class);
        String query = buildString(searchKeyWord);

        List<Account> accountsByCondition = new AccountSelector().getPersonAccountWithConditions(query, personAccountIdSet);

        for (Account accByCondition : accountsByCondition) {
            foundContractorAccountHierarchyConfigs.add(idToContractorAccountInfoMap.get(accByCondition.Id));
        }

        return foundContractorAccountHierarchyConfigs;
    }

    private static  Map<Id, ContractorAccountInfo> mapIdToContractorAccountInfo(List<ContractorAccountInfo> contractorAccountHierarchyConfigsByStation) {
        Map<Id, ContractorAccountInfo> contractorAccountHierarchyConfigsByStationMap = new Map<Id, ContractorAccountInfo>();

        if (!contractorAccountHierarchyConfigsByStation.isEmpty()) {

            for (ContractorAccountInfo contractorAccountInfo : contractorAccountHierarchyConfigsByStation) {
                contractorAccountHierarchyConfigsByStationMap.put(contractorAccountInfo.Id, contractorAccountInfo);
            }
        }

        return contractorAccountHierarchyConfigsByStationMap;
    }

    private static String buildString(String searchKeyWord) {
        String searchKey = String.escapeSingleQuotes(searchKeyWord + '%');
        String query = '';

        if (searchKeyWord == NULL || String.isBlank(searchKeyWord)) {
            query = ' ORDER BY CreatedDate DESC LIMIT 5';
        }
        else {
            query = ' AND Name LIKE \'' + searchKey + '\'' +
                    ' ORDER BY Name ASC LIMIT 5';
        }

        return query;
    }

    private static void createConfigCheckBox(LayoutConfig data) {
        Payroll_Component_Configuration_Field__mdt configCheckBox = new Payroll_Component_Configuration_Field__mdt();

        configCheckBox.Title__c = LABEL_IS_RECURRENT;
        configCheckBox.Field_API_Name__c = PayrollComponentSelector.DESCRIBE_FIELD_RESULT_RECURRENT.getName();
        configCheckBox.Required__c = false;
        configCheckBox.Recurrent_Only__c = false;
        configCheckBox.Is_Hidden__c = false;
        configCheckBox.Order__c = 0;

        createLayoutData(configCheckBox, data);
    }

    private static void createLayoutData(Payroll_Component_Configuration_Field__mdt obj, LayoutConfig data) {
        PayRollFields layoutData = new PayRollFields(obj);

        if (!layoutData.attributeList.isEmpty() && layoutData.cmpName != null) {
            data.componentConfigList.add(layoutData);
        }
    }

    private static List<Attribute> createAttributes(Payroll_Component_Configuration_Field__mdt payRollCmpConfigObj, DisplayType fieldType, Integer maxLengthString) {

        List<Attribute> attributes = new List<Attribute>();

        if (fieldType == DisplayType.BOOLEAN ) {
            attributes = createAttributesForBoolean(payRollCmpConfigObj, fieldType);
        }
        else if (fieldType == DisplayType.STRING ) {
            attributes = createAttributesForString(payRollCmpConfigObj, maxLengthString);
        }
        else if (fieldType == DisplayType.CURRENCY ) {
            attributes = createAttributesForCurrency(payRollCmpConfigObj, fieldType);
        }
        else if (fieldType == DisplayType.DATE ) {
            attributes = createAttributesForDate(payRollCmpConfigObj, fieldType);
        }
        else if (fieldType == DisplayType.PICKLIST) {
            Model.PicklistOption[] picklistValues = getPicklistValues(payRollCmpConfigObj.Field_API_Name__c, payRollCmpConfigObj.DefaultValue__c);
            String picklistOptions = JSON.serialize(picklistValues);
            attributes = createAttributesForPickList(payRollCmpConfigObj, fieldType, picklistOptions);
        }

        if (payRollCmpConfigObj.Recurrent_Only__c) {
            attributes = addAttributesForRecurrent(attributes);
        }

        return attributes;
    }

    private static List<Attribute> createAttributesForBoolean(Payroll_Component_Configuration_Field__mdt payRollCmpConfigObj, DisplayType fieldType) {

        List<Attribute> attributes = new List<Attribute>();

        String fieldLabel = payRollCmpConfigObj.Title__c;
        String fieldAPIName = payRollCmpConfigObj.Field_API_Name__c;
        String cmpType = FIELD_TYPE_TO_CMP_MAP.get(fieldType);

        attributes.add(new Attribute('label', fieldLabel, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.add(new Attribute('type', cmpType, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.add(new Attribute('aura:id', 'field', ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.add(new Attribute('checked', 'false', ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.BOOLEAN)));
        attributes.add(new Attribute('onchange', 'c.handleCheck', ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.REFERENCE)));
        attributes.add(new Attribute('name', fieldAPIName, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));

        return attributes;
    }

    private static List<Attribute> createAttributesForString(Payroll_Component_Configuration_Field__mdt payRollCmpConfigObj, Integer maxLengthString) {

        List<Attribute> attributes = new List<Attribute>();

        String fieldAPIName = payRollCmpConfigObj.Field_API_Name__c;
        String isRequired = JSON.serialize(payRollCmpConfigObj.Required__c);
        String maxLengthStr = String.valueOf(maxLengthString);
        String fieldLabel = payRollCmpConfigObj.Title__c + ' (required text field with a maximum length of ' + maxLengthStr + ' )';

        attributes.add(new Attribute('label', fieldLabel, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.add(new Attribute('aura:id', 'field', ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.add(new Attribute('required', isRequired, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.BOOLEAN)));
        attributes.add(new Attribute('name', fieldAPIName, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.add(new Attribute('maxlength', maxLengthStr, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));

        return attributes;
    }

    private static List<Attribute> createAttributesForCurrency(Payroll_Component_Configuration_Field__mdt payRollCmpConfigObj, DisplayType fieldType) {

        List<Attribute> attributes = new List<Attribute>();

        String fieldLabel = payRollCmpConfigObj.Title__c;
        String fieldAPIName = payRollCmpConfigObj.Field_API_Name__c;
        String isRequired = JSON.serialize(payRollCmpConfigObj.Required__c);
        String cmpType = FIELD_TYPE_TO_CMP_MAP.get(fieldType);

        attributes.add(new Attribute('label', fieldLabel, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.add(new Attribute('type', cmpType, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.add(new Attribute('aura:id', 'field', ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.add(new Attribute('step', '0.01', ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.add(new Attribute('required', isRequired, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.BOOLEAN)));
        attributes.add(new Attribute('name', fieldAPIName, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));

        return attributes;
    }

    private static List<Attribute> createAttributesForDate(Payroll_Component_Configuration_Field__mdt payRollCmpConfigObj, DisplayType fieldType) {

        List<Attribute> attributes = new List<Attribute>();

        String fieldLabel = payRollCmpConfigObj.Title__c;
        String fieldAPIName = payRollCmpConfigObj.Field_API_Name__c;
        String isRequired = JSON.serialize(payRollCmpConfigObj.Required__c);
        String cmpType = FIELD_TYPE_TO_CMP_MAP.get(fieldType);

        attributes.add(new Attribute('label', fieldLabel, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.add(new Attribute('type', cmpType, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.DATE)));
        attributes.add(new Attribute('aura:id', 'field', ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.add(new Attribute('required', isRequired, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.BOOLEAN)));
        attributes.add(new Attribute('name', fieldAPIName, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));

        return attributes;
    }

    private static List<Attribute> createAttributesForPickList(Payroll_Component_Configuration_Field__mdt payRollCmpConfigObj, DisplayType fieldType, String picklistOptions) {

        List<Attribute> attributes = new List<Attribute>();

        String fieldLabel = payRollCmpConfigObj.Title__c;
        String fieldAPIName = payRollCmpConfigObj.Field_API_Name__c;
        String isRequired = JSON.serialize(payRollCmpConfigObj.Required__c);
        String cmpType = FIELD_TYPE_TO_CMP_MAP.get(fieldType);

        attributes.add(new Attribute('label', fieldLabel, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.add(new Attribute('aura:id', 'field', ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.add(new Attribute('options', picklistOptions, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.PICKLIST)));
        attributes.add(new Attribute('type', cmpType, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.add(new Attribute('required', isRequired, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.BOOLEAN)));
        attributes.add(new Attribute('name', fieldAPIName, ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));

        return attributes;
    }

    private static List<Attribute> addAttributesForRecurrent(List<Attribute> addedAttributes) {

        List<Attribute> attributes = new List<Attribute>();

        attributes.add(new Attribute('class', 'slds-hide', ATTRIBUTE_DATA_TYPE_MAP.get(DisplayType.STRING)));
        attributes.addAll(addedAttributes);
        return attributes;
    }

    private static DisplayType getFieldType(String fieldAPIName) {
        SObjectField sObjectField = fieldNameToSObjectField.get(fieldAPIName);

        return sObjectField == null ? null : sObjectField.getDescribe().getType();
    }

    private static List<Schema.PicklistEntry> getPicklistEntryList(String fieldAPIName) {
        SObjectField sObjectField = fieldNameToSObjectField.get(fieldAPIName);

        return sObjectField == null ? null : sObjectField.getDescribe().picklistValues;
    }

    private static Integer getMaxLengthString(String fieldAPIName) {
        SObjectField sObjectField = fieldNameToSObjectField.get(fieldAPIName);

        return sObjectField == null ? null : sObjectField.getDescribe().getLength();
    }

    private static Model.PicklistOption[] getPicklistValues(String fieldAPIName, String defaultValue) {
        Model.PicklistOption[] optionList = new Model.PicklistOption[]{};
        List<Schema.PicklistEntry> picklistEntryList = getPicklistEntryList(fieldAPIName);

        for (Schema.PicklistEntry picklistEntry : picklistEntryList) {
            Model.PicklistOption option = new Model.PicklistOption();

            option.optionLabel = picklistEntry.value;
            option.optionApiName = picklistEntry.value;

            if (defaultValue != null) {
                option.isSelected =  defaultValue == picklistEntry.value;
            } else {
                option.isSelected = picklistEntry.defaultValue;
            }

            optionList.add(option);
        }

        return optionList;
    }

    private static List<Payroll_Component__c> fillPayrollData(GenerateLayoutData generateLayoutData) {

        List<Payroll_Component__c> payrollRecordsList = new List<Payroll_Component__c>();
        Map<String, RecordTypeInfo> apiNameToRecordTypeInfoMap = Schema.Payroll_Component__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        Id RecordTypeId = apiNameToRecordTypeInfoMap.get(generateLayoutData.recordTypeAPIName).getRecordTypeId();
        String approvalStatusApproved = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);

        for (ContractorAccountInfo accountInfo: generateLayoutData.contractorAccountInfo) {
            Payroll_Component__c payrollNew = new Payroll_Component__c();

            payrollNew.Account__c = accountInfo.personAccountId;
            payrollNew.Contractor__c = accountInfo.contractorId;
            payrollNew.RecordTypeId = RecordTypeId;
            payrollNew.Approval_Status__c = approvalStatusApproved;

            for (DataPayrollCmp payroll : generateLayoutData.dataForm) {

                if (payroll.type.equals(FIELD_TYPE_TO_CMP_MAP.get(DisplayType.BOOLEAN))) {
                    Boolean result = Boolean.valueOf(payroll.value);
                    payrollNew.put(payroll.fieldApiName, result);
                }
                else if(payroll.type.equals(FIELD_TYPE_TO_CMP_MAP.get(DisplayType.CURRENCY))) {
                    Decimal result = Decimal.valueOf(payroll.value);
                    payrollNew.put(payroll.fieldApiName, result);
                }
                else if(payroll.type.equals(FIELD_TYPE_TO_CMP_MAP.get(DisplayType.DATE))) {
                    Date result = Date.valueOf(payroll.value);
                    payrollNew.put(payroll.fieldApiName, result);
                }
                else {
                    payrollNew.put(payroll.fieldApiName, payroll.value);
                }
            }

            payrollRecordsList.add(payrollNew);
        }
        return payrollRecordsList;
    }

    private static void getContractorAndSubordinatesIdsByUserId() {

        Id currentUserId = UserInfo.getUserId();

        userIdToRecord = getAllActiveUsersWithEmployeeAccountId();

        createHelperMapsForSubordinatesGenerationBasedOnUsers(userIdToRecord, managerIdToSubordinateUsersMap, accountIdToPersonAccountMap);

        // add user's Contractor ID
        if (userIdToRecord.containsKey(currentUserId)) {
            User currentUser = userIdToRecord.get(currentUserId);
            Account contractorPersonAccount = accountIdToPersonAccountMap.get(currentUser.Employee_AccountId__c);
            subordinateAccountIdToPersonAccountMap.put(contractorPersonAccount.Id, contractorPersonAccount);

            //TODO: ???
            ContractorAccountInfo contractorAccountInformation = createContractorInfoWithSubordinatesByUser(currentUser);
            contractorAccountHierarchyConfig.add(contractorAccountInformation);
        }

        addSubordinateIdsToSetByUserId(currentUserId, subordinateAccountIdToPersonAccountMap, managerIdToSubordinateUsersMap, accountIdToPersonAccountMap);
    }

    @TestVisible
    private static void getContractorAndSubordinatesIdsByUserId_REMAKE(String additionalConditions) {

        Id currentUserId = UserInfo.getUserId();

        userIdToRecord = getAllActiveUsersWithEmployeeAccountId();

        createHelperMapsForSubordinatesGenerationBasedOnUsers_REMAKE(userIdToRecord, managerIdToSubordinateUsersMap, accountIdToPersonAccountMap, additionalConditions);

        // add user's Contractor ID
        if (userIdToRecord.containsKey(currentUserId)) {
            User currentUser = userIdToRecord.get(currentUserId);
            Account contractorPersonAccount = accountIdToPersonAccountMap.get(currentUser.Employee_AccountId__c);

            if (contractorPersonAccount != null) {
                subordinateAccountIdToPersonAccountMap.put(contractorPersonAccount.Id, contractorPersonAccount);
            }

        }

        addSubordinateIdsToSetByUserId_REMAKE(currentUserId, subordinateAccountIdToPersonAccountMap, managerIdToSubordinateUsersMap, accountIdToPersonAccountMap);

    }

    /**
   * @description Gets all active users with existing Person Account.
   *
   * @return Map with key: User ID | value: User record
   */
    private static Map<Id, User> getAllActiveUsersWithEmployeeAccountId() {

        return new Map<Id, User>([
                SELECT Id,
                        Name,
                        ManagerId,
                        Employee_AccountId__c
                FROM User
                WHERE IsActive = TRUE
                AND Employee_AccountId__c <> NULL
                LIMIT 10000
        ]);
    }

    /**
    * @description Creates helper maps based on all active users with 'Person Account' in the system.
    */
    private static void createHelperMapsForSubordinatesGenerationBasedOnUsers(Map<Id, User> userIdToRecord, Map<Id, User[]> managerIdToSubordinateUsersMap, Map<String, Account> accountIdToPersonAccountMap) {

        if (!userIdToRecord.isEmpty()) {
            Set<String> contractorPersonAccountIdSet = new Set<String>();

            for (User userRecord : userIdToRecord.values()) {
                contractorPersonAccountIdSet.add(userRecord.Employee_AccountId__c);

                if (String.isBlank(userRecord.ManagerId)) continue;

                if (!managerIdToSubordinateUsersMap.containsKey(userRecord.ManagerId)) {
                    managerIdToSubordinateUsersMap.put(userRecord.ManagerId, new User[]{});
                }

                managerIdToSubordinateUsersMap.get(userRecord.ManagerId).add(userRecord);
            }

            accountIdToPersonAccountMap.putAll([
                    SELECT Id, Contractor__c, Name, Resource_Type__c, Station__c, Contractor__r.Joining_Date__c, Contractor__r.Exit_Date__c, Contractor__r.Department__c
                    FROM Account
                    WHERE Id IN :contractorPersonAccountIdSet
                    AND IsPersonAccount = TRUE
                    AND  (Contractor__r.Exit_Date__c = NULL OR Contractor__r.Exit_Date__c >= THIS_MONTH)
                    LIMIT 10000
            ]);
        }
    }

    /**
    * @description Creates helper maps based on all active users with 'Person Account' in the system.
    */
    //TODO: REMAKE ME
    private static void createHelperMapsForSubordinatesGenerationBasedOnUsers_REMAKE(Map<Id, User> userIdToRecord,
                                                                                    Map<Id, User[]> managerIdToSubordinateUsersMap,
                                                                                    Map<String, Account> accountIdToPersonAccountMap,
                                                                                    String additionalConditions) {

        if (!userIdToRecord.isEmpty()) {
            Set<String> contractorPersonAccountIdSet = new Set<String>();

            for (User userRecord : userIdToRecord.values()) {
                contractorPersonAccountIdSet.add(userRecord.Employee_AccountId__c);

                if (String.isBlank(userRecord.ManagerId)) continue;

                if (!managerIdToSubordinateUsersMap.containsKey(userRecord.ManagerId)) {
                    managerIdToSubordinateUsersMap.put(userRecord.ManagerId, new User[]{});
                }

                managerIdToSubordinateUsersMap.get(userRecord.ManagerId).add(userRecord);
            }

           accountIdToPersonAccountMap.putAll([
                SELECT Id, Contractor__c, Name, Resource_Type__c, Station__c, Contractor__r.Joining_Date__c, Contractor__r.Exit_Date__c, Contractor__r.Department__c
                FROM Account
                WHERE Id IN :contractorPersonAccountIdSet
                AND IsPersonAccount = TRUE
                AND  (Contractor__r.Exit_Date__c = NULL OR Contractor__r.Exit_Date__c >= THIS_MONTH)
                LIMIT 10000
            ]);
        }
    }

    //TODO: Rename methods to its logic
    private static void addSubordinateIdsToSetByUserId(Id userId, Map<String, Account> subordinateAccountIdToPersonAccountMap, Map<Id, User[]> managerIdToSubordinateUsersMap, Map<String, Account> accountIdToPersonAccountMap) {

        if (!managerIdToSubordinateUsersMap.containsKey(userId)) return;

        for (User subordinateUser : managerIdToSubordinateUsersMap.get(userId)) {
            Account contractorPersonAccount = accountIdToPersonAccountMap.get(subordinateUser.Employee_AccountId__c);

            if (contractorPersonAccount == null) continue;

            subordinateAccountIdToPersonAccountMap.put(contractorPersonAccount.Id, contractorPersonAccount);
            ContractorAccountInfo contractorAccountInformation = createContractorInfoWithSubordinatesByUser(subordinateUser);
            contractorAccountHierarchyConfig.add(contractorAccountInformation);

            addSubordinateIdsToSetByUserId(subordinateUser.Id, subordinateAccountIdToPersonAccountMap, managerIdToSubordinateUsersMap, accountIdToPersonAccountMap);
        }

    }

    //TODO: REMAKE ME
    private static void addSubordinateIdsToSetByUserId_REMAKE(Id userId, Map<String, Account> subordinateAccountIdToPersonAccountMap, Map<Id, User[]> managerIdToSubordinateUsersMap, Map<String, Account> accountIdToPersonAccountMap) {

        if (!managerIdToSubordinateUsersMap.containsKey(userId)) return;

        for (User subordinateUser : managerIdToSubordinateUsersMap.get(userId)) {
            Account contractorPersonAccount = accountIdToPersonAccountMap.get(subordinateUser.Employee_AccountId__c);

            if (contractorPersonAccount == null) continue;

            subordinateAccountIdToPersonAccountMap.put(contractorPersonAccount.Id, contractorPersonAccount);

            addSubordinateIdsToSetByUserId_REMAKE(subordinateUser.Id, subordinateAccountIdToPersonAccountMap, managerIdToSubordinateUsersMap, accountIdToPersonAccountMap);
        }
    }

    private static void getContractorAccountHierarchyConfigsByStation_REMAKE(Payroll_Component_Configurations__mdt payrollCmpConfig) {

        if (
            payrollCmpConfig != null
            && payrollCmpConfig.Additional_Available_Stations__c != null
            && payrollCmpConfig.Additional_Available_Stations__c.length() > 0
        ) {
            String[] additionalAvailableStationList = createListFromStringWithAdditionalAvailableStations(payrollCmpConfig.Additional_Available_Stations__c);
            createContractorAccountHierarchyConfigsByStations_REMAKE(additionalAvailableStationList);
        }
    }

    private static List<ContractorAccountInfo> getContractorAccountHierarchyConfigsByStation(Payroll_Component_Configurations__mdt payrollCmpConfig) {
        List<ContractorAccountInfo> contractorAccountHierarchyConfigsByStation = new List<ContractorAccountInfo>();

        if (
            payrollCmpConfig != null
            && payrollCmpConfig.Additional_Available_Stations__c != null
            && payrollCmpConfig.Additional_Available_Stations__c.length() > 0
        ) {
            String[] additionalAvailableStationList = createListFromStringWithAdditionalAvailableStations(payrollCmpConfig.Additional_Available_Stations__c);
            contractorAccountHierarchyConfigsByStation = createContractorAccountHierarchyConfigsByStations(additionalAvailableStationList);
        }

        return contractorAccountHierarchyConfigsByStation;
    }

    /**
    * @description Creates a list from a string with additional available stations.
    *
    * @param additionalAvailableStation String with additional available stations, e.g. "CTDev Kyiv Office, CTDev Lviv Office, CTDev Cherkasy Office"
    *
    * @return List with with additional available stations.
    */
    private static String[] createListFromStringWithAdditionalAvailableStations(String additionalAvailableStation) {
        String[] additionalAvailableStationList = additionalAvailableStation.split(',');

        for (Integer index = 0, listSize = additionalAvailableStationList.size(); index < listSize; index++) {
            additionalAvailableStationList[index] = additionalAvailableStationList[index].trim();
        }

        return additionalAvailableStationList;
    }

    /**
    * @description Creates a config with hierarchy for each station.
    *
    * @param additionalAvailableStationList List with with additional available stations.
    *
    * @return List with contractor hierarchy config for each station.
    */
    private static ContractorAccountInfo[] createContractorAccountHierarchyConfigsByStations(String[] additionalAvailableStationList) {
        List<ContractorAccountInfo> contractorAccountHierarchyConfigByStations = new List<ContractorAccountInfo>();

        for (User user : userIdToRecord.values()) {
            Account contractorAccountPersonAccount = accountIdToPersonAccountMap.get(user.Employee_AccountId__c);

            if (contractorAccountPersonAccount != null && additionalAvailableStationList.contains(contractorAccountPersonAccount.Station__c)) {

                if (!subordinateAccountIdToPersonAccountMap.containsKey(contractorAccountPersonAccount.Id)) {
                    Account contractorPersonAccount = accountIdToPersonAccountMap.get(user.Employee_AccountId__c);
                    subordinateAccountIdToPersonAccountMap.put(contractorPersonAccount.Id, contractorPersonAccount);

                    //TODO: ???
                    ContractorAccountInfo contractorAccountInformation = createContractorInfoWithSubordinatesByUser(user);
                    contractorAccountHierarchyConfigByStations.add(contractorAccountInformation);
                }
            }
        }

        return contractorAccountHierarchyConfigByStations;
    }

    private static void createContractorAccountHierarchyConfigsByStations_REMAKE(String[] additionalAvailableStationList) {

        for (User user : userIdToRecord.values()) {
            Account contractorAccountPersonAccount = accountIdToPersonAccountMap.get(user.Employee_AccountId__c);

            if (contractorAccountPersonAccount != null && additionalAvailableStationList.contains(contractorAccountPersonAccount.Station__c)) {

                if (!subordinateAccountIdToPersonAccountMap.containsKey(contractorAccountPersonAccount.Id)) {
                    Account contractorPersonAccount = accountIdToPersonAccountMap.get(user.Employee_AccountId__c);
                    subordinateAccountIdToPersonAccountMap.put(contractorPersonAccount.Id, contractorPersonAccount);

                }
            }
        }
    }

    /**
     * @description Creates a wrapper with information about the Contractor and his subordinates. (Contractor hierarchy)
     *              Participates in recursive calls.
     *
     * @param user User record.
     *
     * @return Wrapper with Contractor information.
     */
    private static ContractorAccountInfo createContractorInfoWithSubordinatesByUser(User user) {
        ContractorAccountInfo contractorAccountInformation = new ContractorAccountInfo();

        if (userIdToContractorAccountInfoStorageMap.containsKey(user.Id)) {
            contractorAccountInformation = userIdToContractorAccountInfoStorageMap.get(user.Id);
        }
        else {
            Account contractorPersonAccount = subordinateAccountIdToPersonAccountMap.get(user.Employee_AccountId__c);
            contractorAccountInformation.Id = user.Employee_AccountId__c;
            contractorAccountInformation.userId = user.Id;
            contractorAccountInformation.managerId = user.ManagerId;
            contractorAccountInformation.personAccountId = user.Employee_AccountId__c;
            contractorAccountInformation.contractorId = contractorPersonAccount.Contractor__c;
            contractorAccountInformation.accountName = contractorPersonAccount.Name;
            contractorAccountInformation.resourceType = contractorPersonAccount.Resource_Type__c;
            contractorAccountInformation.joiningDate = contractorPersonAccount.Contractor__r.Joining_Date__c;
            contractorAccountInformation.exitDate = contractorPersonAccount.Contractor__r.Exit_Date__c;
            contractorAccountInformation.isSelected = true;

            userIdToContractorAccountInfoStorageMap.put(user.Id, contractorAccountInformation);
        }

        return contractorAccountInformation;
    }

    @AuraEnabled
    public static LightningResponse getIndividualPersonalAccount(String searchKeyWord, Payroll_Component_Configurations__mdt payrollCmpConfigObj) {
        List<ContractorAccountInfo> contractorAccountHierarchyConfigsAll = new List<ContractorAccountInfo>();

        try {
            getContractorAndSubordinatesIdsByUserId();
            contractorAccountHierarchyConfigsAll.addAll(contractorAccountHierarchyConfig);

            contractorAccountHierarchyConfigsByStation = getContractorAccountHierarchyConfigsByStation(payrollCmpConfigObj);
            contractorAccountHierarchyConfigsAll.addAll(contractorAccountHierarchyConfigsByStation);

            List<ContractorAccountInfo> foundContractorAccountHierarchyConfigs = findContractors(searchKeyWord, contractorAccountHierarchyConfigsAll);

            response.setResult(JSON.serialize(foundContractorAccountHierarchyConfigs));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_ContractorHierarchyController.class));
        }

        return response;
    }

    @AuraEnabled
    public static LightningResponse getMassPersonalAccount(List<String> queryConditionArr, Payroll_Component_Configurations__mdt payrollCmpConfigObj) {
        List<ContractorAccountInfo> contractorAccountHierarchyConfigsAll = new List<ContractorAccountInfo>();

        List<Payroll_Mass_Planning_Filters__mdt> masFilters;

        try {

            String conditionString = '';
            if (!queryConditionArr.isEmpty()) {

                masFilters = [
                        SELECT
                                SOQL_Conditions__c, Category__c
                        FROM Payroll_Mass_Planning_Filters__mdt
                        WHERE (Category__c = 'Department' OR Category__c = 'Sub-Department')
                        AND DeveloperName IN :queryConditionArr
                ];

                for (Payroll_Mass_Planning_Filters__mdt soqlConditions : masFilters) {
                    conditionString += ' AND '+ soqlConditions.SOQL_Conditions__c;
                }
            }

            getContractorAndSubordinatesIdsByUserId_REMAKE(conditionString);
            getContractorAccountHierarchyConfigsByStation_REMAKE(payrollCmpConfigObj);

            // soql with ids
            Account[] foundAccountList = new AccountSelector().getPersonAccountWithConditions(conditionString, subordinateAccountIdToPersonAccountMap.keySet());
            Map<Id, Account> idToFoundAccountMap = new Map<Id, Account>(foundAccountList);

            // form list with existing after soql
            Map<String, User> accountIdToUserMap = new Map<String, User>();
            for (User user : userIdToRecord.values()) {
                accountIdToUserMap.put(user.Employee_AccountId__c, user);
            }

            for (Account account : subordinateAccountIdToPersonAccountMap.values()) {

                if (idToFoundAccountMap.containsKey(account.Id)) {
                    User subordinateUsr = accountIdToUserMap.get(account.Id);

                    ContractorAccountInfo contractorAccountInformation = createContractorInfoWithSubordinatesByUser(subordinateUsr);
                    contractorAccountHierarchyConfigsAll.add(contractorAccountInformation);
                }
            }

            response.setResult(JSON.serialize(contractorAccountHierarchyConfigsAll));
        }
        catch (QueryException exc) {
            response.setError(Util.trackException(true, exc, LA_ContractorHierarchyController.class));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_ContractorHierarchyController.class));
        }

        return response;
    }

    @AuraEnabled
    public static LightningResponse getPayRollCmpConfigFields(Payroll_Component_Configurations__mdt  payRollCmpConfigObj,
            List<Payroll_Component_Configuration_Field__mdt> payRollCmpConfigFields) {
        try {
            LayoutConfig data = new LayoutConfig(payRollCmpConfigObj);

            if (payRollCmpConfigObj.Allow_recurrence__c == true) {
                createConfigCheckBox(data);
            }

            for (Payroll_Component_Configuration_Field__mdt obj : payRollCmpConfigFields) {
                createLayoutData(obj, data);
            }
            data.componentConfigList.sort();

            response.setResult(JSON.serialize(data));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_ContractorHierarchyController.class));
        }

        return response;
    }

    @AuraEnabled
    public static LightningResponse createPayrollData(String jsonGenerateLayoutData) {

        try {
            GenerateLayoutData generateLayoutData = (GenerateLayoutData) JSON.deserialize(jsonGenerateLayoutData, GenerateLayoutData.class);

            List<Payroll_Component__c> payrollRecordsList = fillPayrollData(generateLayoutData);
            insert payrollRecordsList;

            response.success = true;
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_ContractorHierarchyController.class));
        }

        return response;
    }

    @AuraEnabled
    public static LightningResponse getDropdownCategories() {
        DropdownConfigs dropdownConfigs = new DropdownConfigs();

        try {
            List<Payroll_Mass_Planning_Filters__mdt> department = [
                    SELECT MasterLabel, DeveloperName, Title__c
                    FROM Payroll_Mass_Planning_Filters__mdt
                    WHERE Category__c = 'Department'
            ];

            List<Payroll_Mass_Planning_Filters__mdt> subDepartment =  [
                    SELECT MasterLabel, DeveloperName, Title__c
                    FROM Payroll_Mass_Planning_Filters__mdt
                    WHERE Category__c = 'Sub-Department'
            ];

            dropdownConfigs.department = new DropdownConfig(department);
            dropdownConfigs.subDepartment = new DropdownConfig(subDepartment);

            response.setResult(JSON.serialize(dropdownConfigs));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_ContractorHierarchyController.class));
        }

        return response;
    }

    public class GenerateLayoutData {

        public  List<DataPayrollCmp> dataForm = new List<DataPayrollCmp>();
        public  List<ContractorAccountInfo> contractorAccountInfo { get; set; }
        public  String recordTypeAPIName { get; set; }

    }

    public class DataPayrollCmp {

        @AuraEnabled public  String value { get; set; }
        @AuraEnabled public  String fieldApiName { get; set; }
        @AuraEnabled public  String type { get; set; }

        public DataPayrollCmp(String value, String fieldApiName, String type) {
            this.value = value;
            this.fieldApiName = fieldApiName;
            this.type = type;
        }
    }

    public class ContractorAccountInfo {

        public Id Id;
        public Id userId;
        public Id managerId;
        public Id personAccountId;
        public Id contractorId;
        public String accountName;
        public String resourceType;
        public Date joiningDate;
        public Date exitDate;
        public Boolean isSelected;
    }

    public class DropdownConfigs {
        @AuraEnabled public DropdownConfig department;
        @AuraEnabled public DropdownConfig subDepartment;
    }

    public class DropdownConfig {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String optionList { get; set; }

        public DropdownConfig(List<Payroll_Mass_Planning_Filters__mdt> category) {
            this.label = category[0].Title__c;
            this.optionList = JSON.serialize(createCategoriesOptions(category));
        }

        public Model.PicklistOption[] createCategoriesOptions(List<Payroll_Mass_Planning_Filters__mdt> category) {
            Model.PicklistOption[] optionList = new Model.PicklistOption[]{};
            Model.PicklistOption optionDefault = new Model.PicklistOption();

            optionDefault.optionLabel = 'All';
            optionDefault.isSelected = true;
            optionList.add(optionDefault);

            for (Payroll_Mass_Planning_Filters__mdt filter : category) {
                Model.PicklistOption option = new Model.PicklistOption();

                option.optionLabel = filter.MasterLabel;
                option.optionApiName = filter.DeveloperName;
                option.isSelected = false;

                optionList.add(option);
            }

            return optionList;
        }
    }

    public class LayoutConfig {

        @AuraEnabled public  String buttonName { get; set; }
        @AuraEnabled public  String recordType { get; set; }
        @AuraEnabled public  String recordTypeRecurrent { get; set; }
        @AuraEnabled public  Date salaryTransitionDate { get; set; }
        @AuraEnabled public  Date salarySupplementsBlockingDate { get; set; }
        @AuraEnabled public List<PayRollFields> componentConfigList = new List<PayRollFields>();

        public LayoutConfig(Payroll_Component_Configurations__mdt payRollCmpConfigObj) {
            Date dateNow = Date.valueOf(System.now());
            PayrollDateRulesService.PayrollBlockingDaysInfo payrollBlockingDaysInfo = new PayrollDateRulesService().getBlockingDaysInfoByUserAndUserRoleIds(
                UserInfo.getUserId(),
                UserInfo.getUserRoleId()
            );

            this.recordType = payRollCmpConfigObj.RecordType__c;
            this.recordTypeRecurrent = payRollCmpConfigObj.RecordType_recurrent__c;
            this.buttonName = payRollCmpConfigObj.Generate_Button_Title__c;
            this.salarySupplementsBlockingDate = setSalarySupplementsDateByUser(dateNow, payrollBlockingDaysInfo);
            this.salaryTransitionDate = setSalaryTransitionDateByUser(dateNow, payrollBlockingDaysInfo);
        }

        private Date setSalarySupplementsDateByUser(Date dateNow, PayrollDateRulesService.PayrollBlockingDaysInfo payrollBlockingDaysInfo) {
            // set default value
            Date salarySupplementsDate =  Date.newInstance(dateNow.year(), dateNow.month(), 24);

            // leave the default if no setting is assigned to the current user
            if ( !payrollBlockingDaysInfo.isAvailable() || payrollBlockingDaysInfo.getSalarySupplementsDay() == null) return salarySupplementsDate;

            return Date.newInstance(dateNow.year(), dateNow.month(), (Integer)payrollBlockingDaysInfo.getSalarySupplementsDay());
        }

        private Date setSalaryTransitionDateByUser(Date dateNow, PayrollDateRulesService.PayrollBlockingDaysInfo payrollBlockingDaysInfo) {
            // set default value
            Date salaryTransitionDate =  Date.newInstance(dateNow.year(), dateNow.month(), 20);

            // leave the default if no setting is assigned to the current user
            if ( !payrollBlockingDaysInfo.isAvailable() || payrollBlockingDaysInfo.getSalaryTransitionDay() == null) return salaryTransitionDate;

            return Date.newInstance(dateNow.year(), dateNow.month(), (Integer)payrollBlockingDaysInfo.getSalaryTransitionDay());
        }
    }

    public class PayRollFields implements Comparable {

        @AuraEnabled public  String cmpName { get; set; }
        @AuraEnabled public  Boolean isRecurrent { get; set; }
        @AuraEnabled public  Boolean isHidden { get; set; }
        @AuraEnabled public  Integer order { get; set; }
        @AuraEnabled public  List<Attribute> attributeList { get; set; }

        public PayRollFields(Payroll_Component_Configuration_Field__mdt payRollCmpConfigObj) {
            DisplayType fieldType = getFieldType(payRollCmpConfigObj.Field_API_Name__c);
            Integer maxLengthString = getMaxLengthString(payRollCmpConfigObj.Field_API_Name__c);

            if (fieldType == null) {
                return;
            }

            attributeList = createAttributes(payRollCmpConfigObj, fieldType, maxLengthString);

            if (attributeList != null && !attributeList.isEmpty()) {
                this.cmpName = CMP_NAME_VALUES_MAP.get(fieldType);
                this.isRecurrent = payRollCmpConfigObj.Recurrent_Only__c;
                this.isHidden = payRollCmpConfigObj.Is_Hidden__c;
                this.order = Integer.valueOf(payRollCmpConfigObj.Order__c);
            }
        }

        public Integer compareTo(Object objToCompare) {

            if (order == null && ((PayRollFields)objToCompare).order == null) {
                return 0;
            }
            else if (order == null && ((PayRollFields)objToCompare).order != null) {
                return -1;
            }
            else if (order != null && ((PayRollFields)objToCompare).order == null) {
                return 1;
            }
            else if (order > ((PayRollFields)objToCompare).order) {
                return 1;
            } else if (order < ((PayRollFields)objToCompare).order) {
                return -1;
            }

            return 0;
        }
    }

    public class Attribute {

        public String name;
        public String value;
        public String type;

        public Attribute(String name, String value, String type) {
            this.name = name;
            this.value = value;
            this.type = type;
        }
    }

    public class LightningResponse extends Model.LightningResponse {

        /* For success response with JSON data  */
        public void setResult(String data) {
            this.data = data;
            this.success = true;
        }

        /* For error response with message */
        public void setError(String message) {
            this.message = message;
            this.success = false;
        }
    }

}