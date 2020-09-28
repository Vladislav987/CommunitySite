/**
 * Created by Lambru Dmytro on 11.07.2020.
 */
@IsTest
public inherited sharing class ContractorTestDataFactory {
    public static Date DEFAULT_DATE = Date.newInstance(2020, 1, 1);
    private static final String CORPORATE_CURRENCY_ISO_CODE = [SELECT IsoCode FROM CurrencyType WHERE IsCorporate = TRUE LIMIT 1].IsoCode;

    public static final String DEFAULT_MANAGER_NAME = 'MANAGER';
    public static final String DEFAULT_PM_NAME = 'PROJECT_MANAGER';
    public static final String DEFAULT_TEAM_LEADER_NAME = 'TEAM_LEADER';
    public static final String DEFAULT_CONTRACTOR_NAME = 'CONTRACTOR';
    private static final String DEFAULT_CONTRACTOR_EMAIL = 'only.for.test@gmail.com';
    private static final String EXTERNAL_APP_USER = 'External Apps User';

    public static Contractor__c createDefaultPlatformContractor(Id profileId) {
        Contractor__c contractor = createDefaultContractor();
        insert contractor;

        createPersonAccAndPlatformUserForContractors(profileId, new Contractor__c[]{ contractor });

        return contractor;
    }

    public static Contractor__c createDefaultPortalContractor() {
        Contractor__c contractor = createDefaultContractor();
        insert contractor;

        createPersonAccAndCommUserForContractors(new Contractor__c[]{ contractor });

        return contractor;
    }

    public static Contractor__c[] createDefaultPortalContractors(Integer count) {
        Contractor__c[] contractorList = createDefaultContractors(count);
        insert contractorList;

        createPersonAccAndCommUserForContractors(contractorList);

        return contractorList;
    }

    public static void createPortalContractorsForOvertimes() {
        Contractor__c[] contractorList = createContractorsForOvertimes();
        insert contractorList;

        createPersonAccAndCommUserForContractors(contractorList);

        Test.startTest();
            createDefaultCustomHierarchy();
        Test.stopTest();
    }

    public static void createPortalContractorsForHierarchy() {
        Contractor__c[] contractorList = createContractorsForHierarchy();
        insert contractorList;

        createPersonAccAndCommUserForContractors(contractorList);

        Test.startTest();
            createDefaultCustomHierarchy();
        Test.stopTest();
    }

    public static void createPortalContractorsForSalaryChangeRequest() {
        Contractor__c[] contractorList = createContractorsForHierarchy();
        insert contractorList;

        createPersonAccAndCommUserForContractors(contractorList);

    }

    public static void createPortalContractorsForPayslipGeneration() {
        Contractor__c[] contractorList = createContractorsForPayslipGeneration();
        insert contractorList;

        createPersonAccAndCommUserForContractors(contractorList);
    }

    public static void createPortalContractorWithDatesForPayslipGeneration(Date joiningDate, Date exitDate) {
        Contractor__c contractor = createContractorWithCertainDatesForPayslipGeneration(joiningDate, exitDate);
        insert contractor;

        createPersonAccAndCommUserForContractors(new Contractor__c[]{ contractor });
    }

    public static void createPortalContractorsForMasOrIndividualGenerate() {
        Contractor__c[] contractorList = createContractorsForForMasOrIndividualGenerate();
        insert contractorList;

        createPersonAccAndCommUserForContractors(contractorList);
    }

    /*##################################################*/
    /*################# HELPER METHODS #################*/
    /*##################################################*/

    static void createPersonAccAndCommUserForContractors(Contractor__c[] contractorList) {
        Account[] accountList = createPersonAccounts(contractorList);
        insert accountList;

        User[] userList = createCommunityUsers(accountList);
        insert userList;
    }

    static void createPersonAccAndPlatformUserForContractors(Id profileId, Contractor__c[] contractorList) {
        Account[] accountList = createPersonAccounts(contractorList);
        insert accountList;

        User[] userList = createPlatformUsers(accountList, profileId);
        insert userList;
    }

    @Future
    public static void createDefaultCustomHierarchy() {
        Map<String, User> userLastNameToRecordMap = new Map<String, User>();

        User[] userList = [
            SELECT
                LastName,
                ManagerId
            FROM User
            WHERE LastName LIKE :DEFAULT_MANAGER_NAME + '%'
            OR LastName LIKE :DEFAULT_PM_NAME + '%'
            OR LastName LIKE :DEFAULT_TEAM_LEADER_NAME + '%'
            OR LastName LIKE :DEFAULT_CONTRACTOR_NAME + '%'
        ];

        for (User user : userList) {
            userLastNameToRecordMap.put(user.LastName, user);
        }

        // Creating a custom hierarchy
        User manager_1 = userLastNameToRecordMap.get(DEFAULT_MANAGER_NAME + '1');
        User manager_2 = userLastNameToRecordMap.get(DEFAULT_MANAGER_NAME + '2');

        // sets managers as manager for the project managers
        User projectManager_1 = userLastNameToRecordMap.get(DEFAULT_PM_NAME + '1');
        projectManager_1.ManagerId = manager_1.Id;
        User projectManager_2 = userLastNameToRecordMap.get(DEFAULT_PM_NAME + '2');
        projectManager_2.ManagerId = manager_2.Id;

        // sets PMs as manager for the team leaders
        User teamLeader_1 = userLastNameToRecordMap.get(DEFAULT_TEAM_LEADER_NAME + '1');
        teamLeader_1.ManagerId = projectManager_1.Id;
        User teamLeader_2 = userLastNameToRecordMap.get(DEFAULT_TEAM_LEADER_NAME + '2');
        teamLeader_2.ManagerId = projectManager_2.Id;

        // sets team leaders as manager for the contractors
        User contractor_1 = userLastNameToRecordMap.get(DEFAULT_CONTRACTOR_NAME + '1');
        contractor_1.ManagerId = teamLeader_1.Id;
        User contractor_2 = userLastNameToRecordMap.get(DEFAULT_CONTRACTOR_NAME + '2');
        contractor_2.ManagerId = teamLeader_1.Id;

        User contractor_3 = userLastNameToRecordMap.get(DEFAULT_CONTRACTOR_NAME + '3');
        contractor_3.ManagerId = teamLeader_2.Id;
        User contractor_4 = userLastNameToRecordMap.get(DEFAULT_CONTRACTOR_NAME + '4');
        contractor_4.ManagerId = teamLeader_2.Id;

        update userList;
    }

    static Account[] createPersonAccounts(Contractor__c[] contractorList){
        List<Account> personAccountList = new List<Account>();
        Id personAccRTId = AccountSelector.RECORD_TYPE_INFO_PERSON_ACCOUNT.getRecordTypeId();

        for (Contractor__c contractor: contractorList){
            Account account = new Account(
                LastName = contractor.Name,
                RecordTypeId = personAccRTId,
                Contractor__c = contractor.Id,
                PersonEmail = contractor.Personal_email__c
            );

            personAccountList.add(account);
        }

        return personAccountList;
    }

    static User[] createCommunityUsers(Account[] accountList) {
        User[] communityUserList = new List<User>();
        Account[] accWithPersonContactIdList = [SELECT PersonEmail, FirstName, LastName, PersonContactId FROM Account WHERE Id = :accountList];
        Profile[] profiles = [SELECT Id FROM Profile WHERE Name = :EXTERNAL_APP_USER];

        for (Account account: accWithPersonContactIdList) {
            User user = new User(
                ProfileId = profiles[0].Id,
                IsActive = true,
                ContactId = account.PersonContactId,
                Employee_AccountId__c = account.Id,
                FirstName = account.FirstName,
                LastName = account.LastName,
                Email = account.PersonEmail,
                Username= account.PersonContactId + '@gmail.com',
                Alias = '' + Integer.valueOf((Math.random() * 8)),
                EmailEncodingKey='UTF-8',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                CommunityNickname = account.PersonContactId,
                TimeZoneSidKey='America/Chicago'
            );

            communityUserList.add(user);
        }

        return communityUserList;
    }

    static User[] createPlatformUsers(Account[] accountList, Id profileId) {
        User[] communityUserList = new List<User>();
        Id orgId = UserInfo.getOrganizationId();

        for (Account account: accountList) {
            User user = new User(
                    ProfileId = profileId,
                    IsActive = true,
                    Employee_AccountId__c = account.Id,
                    FirstName = account.FirstName,
                    LastName = account.LastName,
                    Email = account.PersonEmail,
                    Username= account.PersonContactId + String.valueOf(orgId) + Integer.valueOf((Math.random() * 10000)) +'@gmail.com',
                    Alias = '' + Integer.valueOf((Math.random() * 8)),
                    EmailEncodingKey='UTF-8',
                    LanguageLocaleKey='en_US',
                    LocaleSidKey='en_US',
                    CommunityNickname = account.PersonContactId,
                    TimeZoneSidKey='America/Chicago'
            );

            communityUserList.add(user);
        }

        return communityUserList;
    }

    static Contractor__c createDefaultContractor() {
        Contractor__c contractor = new Contractor__c(
            Name = DEFAULT_CONTRACTOR_NAME,
            Personal_email__c = DEFAULT_CONTRACTOR_EMAIL,
            RecordTypeId = ContractorSelector.RECORD_TYPE_INFO_CONTRACTOR.getRecordTypeId(),
            Resource_Type__c = ContractorSelector.RESOURCE_TYPE_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceTypePicklistKey.SFDC_DEVELOPER),
            Resource_Level__c = ContractorSelector.RESOURCE_LEVEL_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceLevelPicklistKey.TRAINEE),
            Station__c = ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_KYIV_OFFICE),
            Salary__c = 1000,
            Joining_Date__c = DEFAULT_DATE
        );

        return contractor;
    }

    static Contractor__c[] createDefaultContractors(Integer count) {
        Contractor__c[] contractorList = new Contractor__c[]{};
        Id contractorRTId = ContractorSelector.RECORD_TYPE_INFO_CONTRACTOR.getRecordTypeId();
        String resourceLevelTrainee = ContractorSelector.RESOURCE_LEVEL_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceLevelPicklistKey.TRAINEE);
        String stationKievOffice = ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_KYIV_OFFICE);
        String resourceTypeSFDev = ContractorSelector.RESOURCE_TYPE_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceTypePicklistKey.SFDC_DEVELOPER);


        for (Integer index = 0; index < count; index++) {

            Contractor__c contractor = new Contractor__c(
                Name = DEFAULT_CONTRACTOR_NAME + index,
                Personal_email__c = index + DEFAULT_CONTRACTOR_EMAIL,
                RecordTypeId = contractorRTId,
                Resource_Type__c = resourceTypeSFDev,
                Resource_Level__c = resourceLevelTrainee,
                Station__c = stationKievOffice,
                Salary__c = 1000,
                Joining_Date__c = DEFAULT_DATE
            );

            contractorList.add(contractor);
        }

        return contractorList;
    }

    static Contractor__c[] createContractorsForOvertimes() {
        Contractor__c[] contractorList = new Contractor__c[]{};
        Id recordTypeIdContractor = ContractorSelector.RECORD_TYPE_INFO_CONTRACTOR.getRecordTypeId();
        String resourceTypeSfdcDeveloper = ContractorSelector.RESOURCE_TYPE_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceTypePicklistKey.SFDC_DEVELOPER);
        String resourceLevelTrainee = ContractorSelector.RESOURCE_LEVEL_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceLevelPicklistKey.TRAINEE);
        String stationCtdevKievOffice = ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_KYIV_OFFICE);
        String departmentSfdcDepartment = ContractorSelector.DEPARTMENT_PICKLIST_VALUES_MAP.get(ContractorSelector.DepartmentPicklistKey.SFDC_DEPARTMENT);
        String subDepartmentSfdcPmo = ContractorSelector.SUB_DEPARTMENT_PICKLIST_VALUES_MAP.get(ContractorSelector.SubDepartmentPicklistKey.SFDC_PMO);
        String subDepartmentSfdcDevelopment = ContractorSelector.SUB_DEPARTMENT_PICKLIST_VALUES_MAP.get(ContractorSelector.SubDepartmentPicklistKey.SFDC_DEVELOPMENT);
        String subDepartmentSfdcConsulting = ContractorSelector.SUB_DEPARTMENT_PICKLIST_VALUES_MAP.get(ContractorSelector.SubDepartmentPicklistKey.SFDC_CONSULTING);

        for (Integer index = 0; index < 10; index++) {
            Contractor__c contractor = new Contractor__c(
                RecordTypeId = recordTypeIdContractor,
                Name = DEFAULT_CONTRACTOR_NAME + index,
                CurrencyIsoCode = CORPORATE_CURRENCY_ISO_CODE,
                Personal_email__c = index + DEFAULT_CONTRACTOR_EMAIL,
                Station__c = stationCtdevKievOffice,
                Resource_Type__c = resourceTypeSfdcDeveloper,
                Resource_Level__c = resourceLevelTrainee,
                Salary__c = 1000,
                Department__c = null,
                Sub_Department__c = null,
                Joining_Date__c = DEFAULT_DATE,
                Exit_Date__c = null
            );

            contractorList.add(contractor);
        }

        // sets specific names and field values for Contractors to create a hierarchy
        setNewFieldValuesForContractor(contractorList[0], DEFAULT_MANAGER_NAME + '1', departmentSfdcDepartment, null);
        setNewFieldValuesForContractor(contractorList[1], DEFAULT_MANAGER_NAME + '2', departmentSfdcDepartment, null);

        setNewFieldValuesForContractor(contractorList[2], DEFAULT_PM_NAME + '1', departmentSfdcDepartment, subDepartmentSfdcPmo);
        setNewFieldValuesForContractor(contractorList[3], DEFAULT_PM_NAME + '2', departmentSfdcDepartment, subDepartmentSfdcPmo);

        setNewFieldValuesForContractor(contractorList[4], DEFAULT_TEAM_LEADER_NAME + '1', departmentSfdcDepartment, subDepartmentSfdcDevelopment);
        setNewFieldValuesForContractor(contractorList[5], DEFAULT_TEAM_LEADER_NAME + '2', departmentSfdcDepartment, subDepartmentSfdcDevelopment);

        setNewFieldValuesForContractor(contractorList[6], DEFAULT_CONTRACTOR_NAME + '1', departmentSfdcDepartment, subDepartmentSfdcDevelopment);
        setNewFieldValuesForContractor(contractorList[7], DEFAULT_CONTRACTOR_NAME + '2', departmentSfdcDepartment, subDepartmentSfdcConsulting);
        setNewFieldValuesForContractor(contractorList[8], DEFAULT_CONTRACTOR_NAME + '3', departmentSfdcDepartment, subDepartmentSfdcDevelopment);
        setNewFieldValuesForContractor(contractorList[9], DEFAULT_CONTRACTOR_NAME + '4', departmentSfdcDepartment, subDepartmentSfdcConsulting);

        return contractorList;
    }

    static void setNewFieldValuesForContractor(Contractor__c contractor, String name, String department, String subDepartment) {
        contractor.Name = name;
        contractor.Department__c = department;
        contractor.Sub_Department__c = subDepartment;
    }

    static Contractor__c[] createContractorsForHierarchy() {
        Contractor__c[] contractorList = new Contractor__c[]{};
        Id recordTypeIdContractor = ContractorSelector.RECORD_TYPE_INFO_CONTRACTOR.getRecordTypeId();
        String resourceTypeSfdcDeveloper = ContractorSelector.RESOURCE_TYPE_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceTypePicklistKey.SFDC_DEVELOPER);
        String resourceLevelTrainee = ContractorSelector.RESOURCE_LEVEL_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceLevelPicklistKey.TRAINEE);
        String stationKyivOffice = ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_KYIV_OFFICE);
        String stationLvivOffice = ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_LVIV_OFFICE);
        String stationCherkasyOffice = ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_CHERKASY_OFFICE);

        for (Integer index = 0; index < 10; index++) {
            Contractor__c contractor = new Contractor__c(
                Name = DEFAULT_CONTRACTOR_NAME + index,
                Personal_email__c = index + DEFAULT_CONTRACTOR_EMAIL,
                RecordTypeId = recordTypeIdContractor,
                Resource_Type__c = resourceTypeSfdcDeveloper,
                Resource_Level__c = resourceLevelTrainee,
                Station__c = stationKyivOffice,
                Joining_Date__c = DEFAULT_DATE
            );

            contractorList.add(contractor);
        }

        // sets specific values for contractors to create a hierarchy
        contractorList[0].Name = DEFAULT_MANAGER_NAME + '1';
        contractorList[1].Name = DEFAULT_MANAGER_NAME + '2';
        contractorList[2].Name = DEFAULT_PM_NAME + '1';
        contractorList[3].Name = DEFAULT_PM_NAME + '2';
        contractorList[4].Name = DEFAULT_TEAM_LEADER_NAME + '1';
        contractorList[5].Name = DEFAULT_TEAM_LEADER_NAME + '2';
        contractorList[6].Name = DEFAULT_CONTRACTOR_NAME + '1';
        contractorList[6].Station__c = stationLvivOffice;
        contractorList[7].Name = DEFAULT_CONTRACTOR_NAME + '2';
        contractorList[7].Station__c = stationLvivOffice;
        contractorList[8].Name = DEFAULT_CONTRACTOR_NAME + '3';
        contractorList[8].Station__c = stationCherkasyOffice;
        contractorList[9].Name = DEFAULT_CONTRACTOR_NAME + '4';
        contractorList[9].Station__c = stationCherkasyOffice;

        return contractorList;
    }

    static Contractor__c[] createContractorsForPayslipGeneration() {
        Contractor__c[] contractorList = new Contractor__c[]{};
        Id contractorRTId = ContractorSelector.RECORD_TYPE_INFO_CONTRACTOR.getRecordTypeId();
        String resourceLevelTrainee = ContractorSelector.RESOURCE_LEVEL_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceLevelPicklistKey.TRAINEE);
        String stationKievOffice = ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_KYIV_OFFICE);
        String[] resourceTypePicklistValueList = ContractorSelector.RESOURCE_TYPE_PICKLIST_VALUES_MAP.values();
        Integer listSizeOfResourceType = resourceTypePicklistValueList.size();

        for (Integer index = 0; index < 10; index++) {
            Integer randomNumber = Integer.valueOf((Math.random() * listSizeOfResourceType));
            String randomResourceTypePicklistValue = resourceTypePicklistValueList[randomNumber];

            Contractor__c contractor = new Contractor__c(
                Name = DEFAULT_CONTRACTOR_NAME + index,
                Personal_email__c = index + DEFAULT_CONTRACTOR_EMAIL,
                RecordTypeId = contractorRTId,
                Resource_Type__c = randomResourceTypePicklistValue,
                Resource_Level__c = resourceLevelTrainee,
                Station__c = stationKievOffice,
                CurrencyIsoCode = CORPORATE_CURRENCY_ISO_CODE,
                Salary__c = 3000,
                Joining_Date__c = DEFAULT_DATE,
                Exit_Date__c = null
            );

            contractorList.add(contractor);
        }

        return contractorList;
    }

    static Contractor__c createContractorWithCertainDatesForPayslipGeneration(Date joiningDate, Date exitDate) {
        String[] resourceTypePicklistValueList = ContractorSelector.RESOURCE_TYPE_PICKLIST_VALUES_MAP.values();

        Contractor__c contractor = new Contractor__c(
            Name = DEFAULT_CONTRACTOR_NAME + '_ON_DATE',
            Personal_email__c = DEFAULT_CONTRACTOR_EMAIL,
            RecordTypeId = ContractorSelector.RECORD_TYPE_INFO_CONTRACTOR.getRecordTypeId(),
            Resource_Type__c = resourceTypePicklistValueList[0],
            Resource_Level__c = ContractorSelector.RESOURCE_LEVEL_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceLevelPicklistKey.TRAINEE),
            Station__c = ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_KYIV_OFFICE),
            CurrencyIsoCode = CORPORATE_CURRENCY_ISO_CODE,
            Salary__c = 5000,
            Joining_Date__c = joiningDate,
            Exit_Date__c = exitDate
        );

        return contractor;
    }

    static Contractor__c[] createContractorsForForMasOrIndividualGenerate() {
        // create Contractors with RT Contractor
        Contractor__c[] contractorList = new Contractor__c[]{};
        Id contractorRTId = ContractorSelector.RECORD_TYPE_INFO_CONTRACTOR.getRecordTypeId();
        String resourceTypeSfdcDeveloper = ContractorSelector.RESOURCE_TYPE_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceTypePicklistKey.SFDC_DEVELOPER);
        String resourceLevelTrainee = ContractorSelector.RESOURCE_LEVEL_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceLevelPicklistKey.TRAINEE);
        String contractorStation = ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_KYIV_OFFICE);
        String contractorDepartment =ContractorSelector.DEPARTMENT_PICKLIST_VALUES_MAP.get(ContractorSelector.DepartmentPicklistKey.SFDC_DEPARTMENT);

        for (Integer index = 0; index < 10; index++) {

            Contractor__c contractor = new Contractor__c(
                Name = DEFAULT_CONTRACTOR_NAME + index,
                Personal_email__c = DEFAULT_CONTRACTOR_EMAIL,
                RecordTypeId = contractorRTId,
                Resource_Type__c = resourceTypeSfdcDeveloper,
                Resource_Level__c = resourceLevelTrainee,
                Station__c = contractorStation,
                Department__c = contractorDepartment,
                Joining_Date__c = DEFAULT_DATE
            );

            contractorList.add(contractor);
        }

        // sets specific names for contractors to create a hierarchy
        contractorList[0].Name = DEFAULT_MANAGER_NAME + '1';
        contractorList[0].Station__c = ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_NEW_YORK_OFFICE);
        contractorList[1].Name = DEFAULT_MANAGER_NAME + '2';
        contractorList[2].Name = DEFAULT_PM_NAME + '1';
        contractorList[3].Name = DEFAULT_PM_NAME + '2';
        contractorList[4].Name = DEFAULT_TEAM_LEADER_NAME + '1';
        contractorList[5].Name = DEFAULT_TEAM_LEADER_NAME + '2';
        contractorList[6].Name = DEFAULT_CONTRACTOR_NAME + '1';
        contractorList[7].Name = DEFAULT_CONTRACTOR_NAME + '2';
        contractorList[8].Name = DEFAULT_CONTRACTOR_NAME + '3';
        contractorList[9].Name = DEFAULT_CONTRACTOR_NAME + '4';

        return contractorList;
    }
}