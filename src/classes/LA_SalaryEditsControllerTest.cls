/**
 * Created by Lambru Dmytro on 13.04.2020.
 */
@IsTest
private class LA_SalaryEditsControllerTest {

    private static final Date DEFAULT_DATE = Date.today();
    private static final String DEFAULT_PROJECT_NAME = 'PROJECT_FOR_TEST';
    private static final String DEFAULT_CONTRACTOR_NAME = 'CONTRACTOR_FOR_TEST';
    private static final String DEFAULT_CURRENCY_CODE = 'USD';

    @TestSetup
    static void doSetup() {
        // create Contractors with RT Contractor
        Contractor__c[] contractorList = new Contractor__c[]{};

        for (Integer index = 0; index < 5; index++) {
            Contractor__c contractor = new Contractor__c(
                Name = DEFAULT_CONTRACTOR_NAME + index,
                RecordTypeId = ContractorSelector.RECORD_TYPE_INFO_CONTRACTOR.getRecordTypeId(),
                Resource_Type__c = ContractorSelector.RESOURCE_TYPE_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceTypePicklistKey.SFDC_DEVELOPER),
                Resource_Level__c = ContractorSelector.RESOURCE_LEVEL_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceLevelPicklistKey.TRAINEE),
                Department__c = ContractorSelector.DEPARTMENT_PICKLIST_VALUES_MAP.get(ContractorSelector.DepartmentPicklistKey.SFDC_DEPARTMENT),
                Station__c = ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_KYIV_OFFICE),
                CurrencyIsoCode = DEFAULT_CURRENCY_CODE,
                Joining_Date__c = Date.today()
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

            accountList.add(account);
        }

        insert accountList;

        Set<String> profileNames = new Set<String>{'CT_Project Manager', 'CT_Department Manager'};
        Set<String> userRoles = new Set<String>{'Project Manager', 'SFDM'};
        User[] userList = new User[]{};

        Profile[] profiles = [SELECT Id FROM Profile WHERE Name IN : profileNames];
        UserRole[] users = [SELECT Id FROM UserRole WHERE Name IN : userRoles];

        User user1 = new User(Alias = 'standard', Email = 'standarttestuserorg@testorg.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                Employee_AccountId__c = accountList[0].Id,
                UserRole = users[0],
                LocaleSidKey = 'en_US', ProfileId = profiles[0].Id,
                TimeZoneSidKey = 'America/Los_Angeles', Username = 'standarttestuserorg@testorg.com');

        userList.add(user1);

        User user2 = new User(Alias = 'standard', Email = 'standarttestuserorg1@testorg.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                Employee_AccountId__c = accountList[1].Id,
                UserRole = users[1],
                LocaleSidKey = 'en_US', ProfileId = profiles[1].Id,
                TimeZoneSidKey = 'America/Los_Angeles', Username = 'standarttestuserorg1@testorg.com');

        userList.add(user2);

        insert userList;

        // create Project
        Project__c project = new Project__c();
        project.Name = DEFAULT_PROJECT_NAME;
        project.Contract_type__c = ProjectSelector.CONTRACT_TYPE_PICKLIST_VALUES_MAP.get(ProjectSelector.ContractTypePicklistKey.FIXED_COST);
        project.Project_type__c = ProjectSelector.PROJECT_TYPE_PICKLIST_VALUES_MAP.get(ProjectSelector.ProjectTypePicklistKey.OUTSTAFF);
        project.Project_Manager__c = userList[0].Id;
        project.OwnerId = userList[0].Id;
        project.Start_date__c = DEFAULT_DATE;
        project.End_date__c = Util.dateToEndOfMonth(DEFAULT_DATE);

        insert project;

        // create Allocations with Contractors for Project
        Allocation__c[] allocationList = new Allocation__c[]{};

        for (Contractor__c contractor : contractorList) {
            Allocation__c allocation = new Allocation__c();
            allocation.RecordTypeId = AllocationSelector.RECORD_TYPE_INFO_PROJECT.getRecordTypeId();
            allocation.Allocation_Type__c = AllocationSelector.ALLOCATION_TYPE_PICKLIST_VALUES_MAP.get(AllocationSelector.AllocationTypePicklistKey.BILLABLE);
            allocation.Allocation__c = 100;
            allocation.Project__c = project.Id;
            allocation.Contractor__c = contractor.Id;
            allocation.Start_date__c = DEFAULT_DATE;
            allocation.End_date__c = Util.dateToEndOfMonth(DEFAULT_DATE);

            allocationList.add(allocation);
        }

        insert allocationList;
    }

    @IsTest
    static void testGetCmpConfigForBonuses() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME LIMIT 1];
        User projectManager = [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
                AND Username = 'standarttestuserorg@testorg.com'
                LIMIT 1
        ];

        Test.startTest();
        Model.LightningResponse response;

        System.runAs(projectManager) {
            response = LA_SalaryEditsController.getCmpConfig(project.Id);
        }
        Test.stopTest();

        LA_SalaryEditsService.ComponentConfig componentConfig = (LA_SalaryEditsService.ComponentConfig) JSON.deserialize(response.data, LA_SalaryEditsService.ComponentConfig.class);

        System.assert(!componentConfig.currencyDropdownOptionList.isEmpty(), 'The list should not be empty!');
        System.assert(!componentConfig.monthDropdownOptionList.isEmpty(), 'The list should not be empty!');
        System.assert(!componentConfig.yearDropdownOptionList.isEmpty(), 'The list should not be empty!');
    }

    @IsTest
    static void testGetCmpConfigForBonuses_no_access() {
        Project__c project = [SELECT Id, OwnerId FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME LIMIT 1];

        User anotherUser = [
            SELECT Id
            FROM User
            WHERE IsActive = TRUE
            AND Profile.Name = 'System Administrator'
            AND Id <> :UserInfo.getUserId()
            LIMIT 1
        ];

        Test.startTest();
            System.runAs(anotherUser) {
                Model.LightningResponse response = LA_SalaryEditsController.getCmpConfig(project.Id);

                System.assert(response.success == false, 'The response should not be successful for the non-owner of the record!');
                System.assert(response.code == 401, 'The error code should be 401 for the non-owner of the record');
            }
        Test.stopTest();
    }

    @IsTest
    static void testGetContractorsForPeriod() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME LIMIT 1];
        User projectManager = [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
                AND Username = 'standarttestuserorg@testorg.com'
                LIMIT 1
        ];

        Test.startTest();
        Model.LightningResponse response;

        System.runAs(projectManager) {
            response = LA_SalaryEditsController.getContractorsForPeriod(project.Id, DEFAULT_DATE.month(), DEFAULT_DATE.addYears(1).year());
        }
        Test.stopTest();

        System.debug(response);

        LA_SalaryEditsService.ContractorInfo[] contractorInfoList = (LA_SalaryEditsService.ContractorInfo[]) JSON.deserialize(response.data, LA_SalaryEditsService.ContractorInfo[].class);

        System.assert(contractorInfoList.size() == 5, 'The list size should be 5!');
    }

    @IsTest
    static void testGetContractorsForPeriod_WithExitUser() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME LIMIT 1];
        Contractor__c contractor = [SELECT Exit_Date__c FROM Contractor__c LIMIT 1];
        User projectManager = [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
                AND Username = 'standarttestuserorg@testorg.com'
                LIMIT 1
        ];

        contractor.Exit_Date__c = Date.newInstance(2010, 6, 6);

        update contractor;

        Test.startTest();
        Model.LightningResponse response;

        System.runAs(projectManager) {
            response = LA_SalaryEditsController.getContractorsForPeriod(project.Id, DEFAULT_DATE.month(), DEFAULT_DATE.addYears(1).year());
        }
        Test.stopTest();

        LA_SalaryEditsService.ContractorInfo[] contractorInfoList = (LA_SalaryEditsService.ContractorInfo[]) JSON.deserialize(response.data, LA_SalaryEditsService.ContractorInfo[].class);

        System.assert(contractorInfoList.size() == 4, 'The list size should be 4!');
    }

    @IsTest
    static void testGetContractorsForPeriodForReimbursement() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME LIMIT 1];
        User projectManager = [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
                AND Username = 'standarttestuserorg@testorg.com'
                LIMIT 1
        ];

        Test.startTest();
        Model.LightningResponse response;
        System.runAs(projectManager) {

            response = LA_SalaryEditsController.getContractorsForPeriodForReimbursement(project.Id, DEFAULT_DATE.month(), DEFAULT_DATE.addYears(1).year());
        }
        Test.stopTest();

        LA_SalaryEditsService.ContractorInfo[] contractorInfoList = (LA_SalaryEditsService.ContractorInfo[]) JSON.deserialize(response.data, LA_SalaryEditsService.ContractorInfo[].class);

        System.assert(contractorInfoList.size() == 5, 'The list size should be 5!');
    }

    @IsTest
    static void testGetContractorsForPeriodForReimbursement_WithExitUser() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME LIMIT 1];
        Contractor__c contractor = [SELECT Exit_Date__c FROM Contractor__c LIMIT 1];
        User projectManager = [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
                AND Username = 'standarttestuserorg@testorg.com'
                LIMIT 1
        ];

        contractor.Exit_Date__c = Date.newInstance(2010, 5, 6);

        update contractor;

        Test.startTest();
        Model.LightningResponse response;
        System.runAs(projectManager) {

            response = LA_SalaryEditsController.getContractorsForPeriod(project.Id, DEFAULT_DATE.month(), DEFAULT_DATE.addYears(1).year());
        }
        Test.stopTest();

        LA_SalaryEditsService.ContractorInfo[] contractorInfoList = (LA_SalaryEditsService.ContractorInfo[]) JSON.deserialize(response.data, LA_SalaryEditsService.ContractorInfo[].class);

        System.assert(contractorInfoList.size() == 4, 'The list size should be 4!');
    }

    @IsTest
    static void testGetContractorsForPeriod_no_access() {
        Project__c project = [SELECT Id, OwnerId FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME LIMIT 1];

        User anotherUser = [
            SELECT Id
            FROM User
            WHERE IsActive = TRUE
            AND Profile.Name = 'System Administrator'
            AND Id <> :UserInfo.getUserId()
            LIMIT 1
        ];

        Test.startTest();
        System.runAs(anotherUser) {
            Model.LightningResponse response = LA_SalaryEditsController.getContractorsForPeriod(project.Id, DEFAULT_DATE.month(), DEFAULT_DATE.addYears(1).year());

            System.assert(response.success == false, 'The response should not be successful for the non-owner of the record!');
            System.assert(response.code == 401, 'The error code should be 401 for the non-owner of the record');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGenerateBonuses_isSelected() {
        final String REASON_DESCRIPTION = 'Reason description here';
        final Integer AMOUNT = 1000;

        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME LIMIT 1];
        CurrencyType randomCurrencyType = [SELECT IsoCode FROM CurrencyType WHERE IsActive = TRUE LIMIT 1];
        User projectManager = [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
                AND Username = 'standarttestuserorg@testorg.com'
                LIMIT 1
        ];

        // get a list with information about contractors
        Model.LightningResponse getContractorsForPeriod_response;
        System.runAs(projectManager) {
            getContractorsForPeriod_response = LA_SalaryEditsController.getContractorsForPeriod(project.Id, DEFAULT_DATE.month(), DEFAULT_DATE.addYears(1).year());
        }
        LA_SalaryEditsService.ContractorInfo[] contractorInfoList = (LA_SalaryEditsService.ContractorInfo[]) JSON.deserialize(getContractorsForPeriod_response.data, LA_SalaryEditsService.ContractorInfo[].class);

        System.assert(contractorInfoList.size() == 5, 'The list size should be 5!');

        // emulate the changes that were made in the Aura component for some Contractors
        LA_SalaryEditsService.ContractorInfo[] selectedContractorInfoList = new LA_SalaryEditsService.ContractorInfo[]{};

        for (Integer index = 0, partSize = (contractorInfoList.size() - 2); index < partSize; index++) {
            contractorInfoList[index].isSelected = true;
            contractorInfoList[index].currencyType = randomCurrencyType.IsoCode;
            contractorInfoList[index].currencyAmount = AMOUNT;
            contractorInfoList[index].reasonDescription = REASON_DESCRIPTION;

            selectedContractorInfoList.add(contractorInfoList[index]);
        }

        Test.startTest();
        Model.LightningResponse generateBonuses_response;
            System.runAs(projectManager) {
                generateBonuses_response = LA_SalaryEditsController.generateBonuses(project.Id, JSON.serialize(selectedContractorInfoList));
            }
        Test.stopTest();

        // for each Contractor, 1 “Budget_transaction” and 1 “Payroll_Component” record must be created
        Map<Id, Budget_transaction__c> budgetTransactionIdToRecordMap = new Map<Id, Budget_transaction__c>([
            SELECT Id, RecordTypeId, Project__c, Expense_type__c, Expense_type_details__c, Comments__c, CurrencyIsoCode, Amount__c
            FROM Budget_transaction__c
        ]);

        Payroll_Component__c[] payrollComponentList = [
            SELECT Id, RecordTypeId, Project__c, Contractor__c, Account__c, Budget_transaction__c, Approval_Status__c, CurrencyIsoCode, SumType__c, Sum__c, StartDate__c, EndDate__c
            FROM Payroll_Component__c
        ];

        // check data for “Budget_transaction” records
        for (Budget_transaction__c budgetTransaction : budgetTransactionIdToRecordMap.values()) {
            System.assertEquals(project.Id, budgetTransaction.Project__c);
            System.assertEquals(REASON_DESCRIPTION, budgetTransaction.Comments__c);
            System.assert(budgetTransaction.CurrencyIsoCode == randomCurrencyType.IsoCode);
            System.assert(budgetTransaction.Amount__c == AMOUNT);
            System.assertEquals(
                BudgetTransactionSelector.RECORD_TYPE_INFO_INCLUDED_EXPENSE.getRecordTypeId(),
                budgetTransaction.RecordTypeId,
                'Record Type must be "Included expense" for Contractor with not selected "isIncludedToInvoice"'
            );
            System.assertEquals(
                BudgetTransactionSelector.EXPENSE_TYPE_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypePicklistKey.BONUS),
                budgetTransaction.Expense_type__c
            );
            System.assertEquals(
                BudgetTransactionSelector.EXPENSE_TYPE_DETAILS_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypeDetailsPicklistKey.OTHER),
                budgetTransaction.Expense_type_details__c
            );
        }

        // check data for “Payroll_Component” records
        Date today = System.today();
        Date payrollStartDate = (today.day() < 20) ? today.toStartOfMonth() : today.toStartOfMonth().addMonths(1);
        String waitingForApprovalStatus = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
        String IncrementSumType = PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.SumTypePicklistKey.INCREMENT);

        for (Payroll_Component__c payrollComponent : payrollComponentList) {
            System.assertEquals(project.Id, payrollComponent.Project__c);
            System.assert(payrollComponent.Approval_Status__c == waitingForApprovalStatus, 'The Payroll_component must be with Approval_Status = "Waiting For Approval"');
            System.assert(payrollComponent.CurrencyIsoCode == randomCurrencyType.IsoCode);
            System.assert(payrollComponent.SumType__c == IncrementSumType);
            System.assert(payrollComponent.Sum__c == AMOUNT);
            System.assert(String.isNotBlank(payrollComponent.Contractor__c), 'The Payroll_component must have the Contractor ID.');
            System.assert(String.isNotBlank(payrollComponent.Account__c), 'The Payroll_component must have the Personal Account ID of the Contractor.');
            System.assert(payrollComponent.StartDate__c == payrollStartDate, 'The date should be on the 1 day of the current or next month if today is greater than 19.');
            System.assert(payrollComponent.EndDate__c == payrollStartDate, 'The date should be on the 1 day of the current or next month if today is greater than 19.');
            System.assertEquals(
                PayrollComponentSelector.RECORD_TYPE_INFO_BONUS.getRecordTypeId(),
                payrollComponent.RecordTypeId
            );
        }
    }

    @IsTest
    static void testGenerateBonuses_isSelected_isIncludedToInvoice() {
        final String REASON_DESCRIPTION = 'Reason description here';
        final Integer AMOUNT = 1000;

        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME LIMIT 1];
        CurrencyType randomCurrencyType = [SELECT IsoCode FROM CurrencyType WHERE IsActive = TRUE LIMIT 1];
        User projectManager = [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
                AND Username = 'standarttestuserorg@testorg.com'
                LIMIT 1
        ];

        Model.LightningResponse getContractorsForPeriod_response;

        System.runAs(projectManager) {
            getContractorsForPeriod_response = LA_SalaryEditsController.getContractorsForPeriod(project.Id, DEFAULT_DATE.month(), DEFAULT_DATE.addYears(1).year());
        }
        LA_SalaryEditsService.ContractorInfo[] contractorInfoList = (LA_SalaryEditsService.ContractorInfo[]) JSON.deserialize(getContractorsForPeriod_response.data, LA_SalaryEditsService.ContractorInfo[].class);

        System.assert(contractorInfoList.size() == 5, 'The list size should be 5!');

        // emulate the changes that were made in the Aura component for some Contractors
        LA_SalaryEditsService.ContractorInfo[] selectedContractorInfoList = new LA_SalaryEditsService.ContractorInfo[]{};

        for (Integer index = 0, partSize = (contractorInfoList.size() - 2); index < partSize; index++) {
            contractorInfoList[index].isSelected = true;
            contractorInfoList[index].isIncludedToInvoice = true;
            contractorInfoList[index].currencyType = randomCurrencyType.IsoCode;
            contractorInfoList[index].currencyAmount = 1000;
            contractorInfoList[index].reasonDescription = REASON_DESCRIPTION;

            selectedContractorInfoList.add(contractorInfoList[index]);
        }

        Test.startTest();
        Model.LightningResponse generateBonuses_response;

        System.runAs(projectManager) {
            generateBonuses_response = LA_SalaryEditsController.generateBonuses(project.Id, JSON.serialize(selectedContractorInfoList));
        }
        Test.stopTest();

        assertSuccessLightningResponse(generateBonuses_response);

        // for each Contractor, 1 “Budget_transaction” and 1 “Payroll_Component” record must be created
        Budget_transaction__c[] budgetTransactionList = [
            SELECT Id, RecordTypeId, Project__c, Expense_type__c, Expense_type_details__c, Comments__c, CurrencyIsoCode, Amount__c
            FROM Budget_transaction__c
        ];

        // check data for “Budget_transaction” records
        for (Budget_transaction__c budgetTransaction : budgetTransactionList) {
            System.assertEquals(project.Id, budgetTransaction.Project__c);
            System.assertEquals(REASON_DESCRIPTION, budgetTransaction.Comments__c);
            System.assert(budgetTransaction.CurrencyIsoCode == randomCurrencyType.IsoCode);
            System.assert(budgetTransaction.Amount__c == AMOUNT);
            System.assertEquals(
                BudgetTransactionSelector.RECORD_TYPE_INFO_REIMBURSABLE_EXPENSE.getRecordTypeId(),
                budgetTransaction.RecordTypeId,
                'Record Type must be "Reimbursable expense" for Contractor with selected "isIncludedToInvoice"'
            );
            System.assertEquals(
                BudgetTransactionSelector.EXPENSE_TYPE_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypePicklistKey.BONUS),
                budgetTransaction.Expense_type__c
            );
            System.assertEquals(
                BudgetTransactionSelector.EXPENSE_TYPE_DETAILS_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypeDetailsPicklistKey.OTHER),
                budgetTransaction.Expense_type_details__c
            );
        }
    }

    @IsTest
    static void testGetContractorCurrAndName() {
        String contractorName = DEFAULT_CONTRACTOR_NAME + 1;
        Contractor__c contractor = [ SELECT Id FROM Contractor__c WHERE Name = :contractorName LIMIT 1 ];
        User projectManager = [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
                AND Username = 'standarttestuserorg@testorg.com'
                LIMIT 1
        ];

        Test.startTest();
        Model.LightningResponse response;

        System.runAs(projectManager) {
            response = LA_SalaryEditsController.getContractorById(contractor.Id);
        }
        Test.stopTest();

        Contractor__c[] contractorList = (Contractor__c[]) JSON.deserialize(response.data, Contractor__c[].class);

        System.assert(!contractorList.isEmpty(), 'The list should not be empty!');
        System.assert(String.isNotBlank(contractorList[0].CurrencyIsoCode), 'CurrencyIsoCode should not be blank!');
    }

    @IsTest
    static void testGetConversionRate() {
        User projectManager = [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
                AND Username = 'standarttestuserorg@testorg.com'
                LIMIT 1
        ];

        Test.startTest();
        Model.LightningResponse response;

        System.runAs(projectManager) {
            response = LA_SalaryEditsController.getConversionRate();
        }
        Test.stopTest();

        DatedConversionRate[] datedConversionRates = (DatedConversionRate[]) JSON.deserialize(response.data, DatedConversionRate[].class);

        System.assert(!datedConversionRates.isEmpty(), 'The list should not be empty!');
    }

    @IsTest
    static void testGetContractorTravelRequests() {
        String contractorName = DEFAULT_CONTRACTOR_NAME + 1;
        Contractor__c contractor = [ SELECT Id FROM Contractor__c WHERE Name = :contractorName LIMIT 1 ];
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME LIMIT 1];
        User projectManager = [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
                AND Username = 'standarttestuserorg@testorg.com'
                LIMIT 1
        ];

        Test.startTest();
        Model.LightningResponse response;

        System.runAs(projectManager) {
            response = LA_SalaryEditsController.getContractorTravelRequests(contractor.Id, project.Id);
        }
        Test.stopTest();

        assertSuccessLightningResponse(response);
    }

    @IsTest
    static void testGenerateReimbursement_isNotIncludedToInvoice() {
        final String DEFAULT_REASON = 'Default Reason';
        final String DEFAULT_COMMENT = 'Default Comment';
        final String DEFAULT_FILE_NAME = 'Default File';
        final String DEFAULT_FILE_DATA = 'Default File Data';
        final Integer DEFAULT_AMOUNT = 100;

        String contractorName = DEFAULT_CONTRACTOR_NAME + 1;
        Contractor__c contractor = [ SELECT Id, Name FROM Contractor__c WHERE Name = :contractorName ];
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME LIMIT 1];
        User projectManager = [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
                AND Username = 'standarttestuserorg@testorg.com'
                LIMIT 1
        ];

        LA_SalaryEditsService.PayrollComponentInfo payrollComponentInfo = new LA_SalaryEditsService.PayrollComponentInfo();

        payrollComponentInfo.contractorName = contractor.Name;
        payrollComponentInfo.contractorId = contractor.Id;
        payrollComponentInfo.reason = DEFAULT_REASON;
        payrollComponentInfo.amount = DEFAULT_AMOUNT;
        payrollComponentInfo.invoice = false;
        payrollComponentInfo.currencyIsoCode = DEFAULT_CURRENCY_CODE;

        LA_SalaryEditsService.PayrollComponentItemInfo[] payrollComponentItemInfos = new LA_SalaryEditsService.PayrollComponentItemInfo[]{};
        LA_SalaryEditsService.AttachmentsInfo[] attachmentsInfos = new LA_SalaryEditsService.AttachmentsInfo[]{};

        for(Integer i = 0; i < 3; i++) {
            LA_SalaryEditsService.PayrollComponentItemInfo payrollComponentItemInfo = new LA_SalaryEditsService.PayrollComponentItemInfo();
            payrollComponentItemInfo.amount = 50;
            payrollComponentItemInfo.currencyIsoCode = DEFAULT_CURRENCY_CODE;
            payrollComponentItemInfo.comment = DEFAULT_COMMENT;

            payrollComponentItemInfos.add(payrollComponentItemInfo);

            LA_SalaryEditsService.AttachmentsInfo attachmentsInfo = new LA_SalaryEditsService.AttachmentsInfo();
            attachmentsInfo.fileData = DEFAULT_FILE_DATA;
            attachmentsInfo.fileName = DEFAULT_FILE_NAME;

            attachmentsInfos.add(attachmentsInfo);
        }

        Test.startTest();
        Model.LightningResponse generateReimbursement_response;

        System.runAs(projectManager) {
            generateReimbursement_response = LA_SalaryEditsController.generateReimbursement(project.Id, JSON.serialize(payrollComponentInfo), JSON.serialize(payrollComponentItemInfos), JSON.serialize(attachmentsInfos));
        }
        Test.stopTest();

        assertSuccessLightningResponse(generateReimbursement_response);

        // for each Contractor, 1 “Budget_transaction” and 1 “Payroll_Component” record must be created
        Map<Id, Budget_transaction__c> budgetTransactionIdToRecordMap = new Map<Id, Budget_transaction__c>([
                SELECT Id, RecordTypeId, Project__c, Expense_type__c, Expense_type_details__c, Comments__c, CurrencyIsoCode, Amount__c
                FROM Budget_transaction__c
        ]);

        Payroll_Component__c[] payrollComponentList = [
                SELECT Id, RecordTypeId, Project__c, Contractor__c, Account__c, Budget_transaction__c, Approval_Status__c, CurrencyIsoCode, SumType__c, Sum__c, StartDate__c, EndDate__c
                FROM Payroll_Component__c
        ];

        // check data for “Budget_transaction” records
        for (Budget_transaction__c budgetTransaction : budgetTransactionIdToRecordMap.values()) {
            System.assertEquals(project.Id, budgetTransaction.Project__c);
            System.assertEquals(DEFAULT_REASON, budgetTransaction.Comments__c);
            System.assert(budgetTransaction.CurrencyIsoCode == DEFAULT_CURRENCY_CODE);
            System.assert(budgetTransaction.Amount__c == DEFAULT_AMOUNT);
            System.assertEquals(
                    BudgetTransactionSelector.RECORD_TYPE_INFO_INCLUDED_EXPENSE.getRecordTypeId(),
                    budgetTransaction.RecordTypeId,
                    'Record Type must be "Included expense" for Contractor with not selected "isIncludedToInvoice"'
            );
            System.assertEquals(
                    BudgetTransactionSelector.EXPENSE_TYPE_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypePicklistKey.REIMBURSEMENT),
                    budgetTransaction.Expense_type__c
            );
            System.assertEquals(
                    BudgetTransactionSelector.EXPENSE_TYPE_DETAILS_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypeDetailsPicklistKey.OTHER),
                    budgetTransaction.Expense_type_details__c
            );
        }

        // check data for “Payroll_Component” records
        Date today = System.today();
        Date payrollStartDate = (today.day() < 20) ? today.toStartOfMonth() : today.toStartOfMonth().addMonths(1);
        String waitingForApprovalStatus = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
        String IncrementSumType = PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.SumTypePicklistKey.INCREMENT);

        for (Payroll_Component__c payrollComponent : payrollComponentList) {
            System.assertEquals(project.Id, payrollComponent.Project__c);
            System.assert(payrollComponent.Approval_Status__c == waitingForApprovalStatus, 'The Payroll_component must be with Approval_Status = "Waiting For Approval"');
            System.assert(payrollComponent.CurrencyIsoCode == DEFAULT_CURRENCY_CODE);
            System.assert(payrollComponent.SumType__c == IncrementSumType);
            System.assert(payrollComponent.Sum__c == DEFAULT_AMOUNT);
            System.assert(String.isNotBlank(payrollComponent.Contractor__c), 'The Payroll_component must have the Contractor ID.');
            System.assert(String.isNotBlank(payrollComponent.Account__c), 'The Payroll_component must have the Personal Account ID of the Contractor.');
            System.assert(payrollComponent.StartDate__c == payrollStartDate, 'The date should be on the 1 day of the current or next month if today is greater than 19.');
            System.assert(payrollComponent.EndDate__c == payrollStartDate, 'The date should be on the 1 day of the current or next month if today is greater than 19.');
            System.assertEquals(
                    PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId(),
                    payrollComponent.RecordTypeId
            );
        }
    }

    @IsTest
    static void testGenerateReimbursement_isIncluded() {
        final String DEFAULT_REASON = 'Default Reason';
        final String DEFAULT_COMMENT = 'Default Comment';
        final String DEFAULT_FILE_NAME = 'Default File';
        final String DEFAULT_FILE_DATA = 'Default File Data';
        final Integer DEFAULT_AMOUNT = 100;

        String contractorName = DEFAULT_CONTRACTOR_NAME + 1;
        Contractor__c contractor = [ SELECT Id, Name FROM Contractor__c WHERE Name = :contractorName ];
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME LIMIT 1];
        User projectManager = [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
                AND Username = 'standarttestuserorg@testorg.com'
                LIMIT 1
        ];

        LA_SalaryEditsService.PayrollComponentInfo payrollComponentInfo = new LA_SalaryEditsService.PayrollComponentInfo();

        payrollComponentInfo.contractorName = contractor.Name;
        payrollComponentInfo.contractorId = contractor.Id;
        payrollComponentInfo.reason = DEFAULT_REASON;
        payrollComponentInfo.amount = DEFAULT_AMOUNT;
        payrollComponentInfo.invoice = false;
        payrollComponentInfo.currencyIsoCode = DEFAULT_CURRENCY_CODE;

        LA_SalaryEditsService.PayrollComponentItemInfo[] payrollComponentItemInfos = new LA_SalaryEditsService.PayrollComponentItemInfo[]{};
        LA_SalaryEditsService.AttachmentsInfo[] attachmentsInfos = new LA_SalaryEditsService.AttachmentsInfo[]{};

        for(Integer i = 0; i < 3; i++) {
            LA_SalaryEditsService.PayrollComponentItemInfo payrollComponentItemInfo = new LA_SalaryEditsService.PayrollComponentItemInfo();
            payrollComponentItemInfo.amount = 50;
            payrollComponentItemInfo.currencyIsoCode = DEFAULT_CURRENCY_CODE;
            payrollComponentItemInfo.comment = DEFAULT_COMMENT;

            payrollComponentItemInfos.add(payrollComponentItemInfo);

            LA_SalaryEditsService.AttachmentsInfo attachmentsInfo = new LA_SalaryEditsService.AttachmentsInfo();
            attachmentsInfo.fileData = DEFAULT_FILE_DATA;
            attachmentsInfo.fileName = DEFAULT_FILE_NAME;

            attachmentsInfos.add(attachmentsInfo);
        }

        Test.startTest();
        Model.LightningResponse generateReimbursement_response;

        System.runAs(projectManager) {
            generateReimbursement_response = LA_SalaryEditsController.generateReimbursement(project.Id, JSON.serialize(payrollComponentInfo), JSON.serialize(payrollComponentItemInfos), JSON.serialize(attachmentsInfos));
        }
        Test.stopTest();

        assertSuccessLightningResponse(generateReimbursement_response);

        // for each Contractor, 1 “Budget_transaction” and 1 “Payroll_Component” record must be created
        Map<Id, Budget_transaction__c> budgetTransactionIdToRecordMap = new Map<Id, Budget_transaction__c>([
                SELECT Id, RecordTypeId, Project__c, Expense_type__c, Expense_type_details__c, Comments__c, CurrencyIsoCode, Amount__c
                FROM Budget_transaction__c
        ]);

        Payroll_Component__c[] payrollComponentList = [
                SELECT Id, RecordTypeId, Project__c, Contractor__c, Account__c, Budget_transaction__c, Approval_Status__c, CurrencyIsoCode, SumType__c, Sum__c, StartDate__c, EndDate__c
                FROM Payroll_Component__c
        ];

        // check data for “Budget_transaction” records
        for (Budget_transaction__c budgetTransaction : budgetTransactionIdToRecordMap.values()) {
            System.assertEquals(project.Id, budgetTransaction.Project__c);
            System.assertEquals(DEFAULT_REASON, budgetTransaction.Comments__c);
            System.assert(budgetTransaction.CurrencyIsoCode == DEFAULT_CURRENCY_CODE);
            System.assert(budgetTransaction.Amount__c == DEFAULT_AMOUNT);
            System.assertEquals(
                    BudgetTransactionSelector.RECORD_TYPE_INFO_INCLUDED_EXPENSE.getRecordTypeId(),
                    budgetTransaction.RecordTypeId,
                    'Record Type must be "Included expense" for Contractor with not selected "isIncludedToInvoice"'
            );
            System.assertEquals(
                    BudgetTransactionSelector.EXPENSE_TYPE_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypePicklistKey.REIMBURSEMENT),
                    budgetTransaction.Expense_type__c
            );
            System.assertEquals(
                    BudgetTransactionSelector.EXPENSE_TYPE_DETAILS_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypeDetailsPicklistKey.OTHER),
                    budgetTransaction.Expense_type_details__c
            );
        }

        // check data for “Payroll_Component” records
        Date today = System.today();
        Date payrollStartDate = (today.day() < 20) ? today.toStartOfMonth() : today.toStartOfMonth().addMonths(1);
        String waitingForApprovalStatus = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
        String IncrementSumType = PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.SumTypePicklistKey.INCREMENT);

        for (Payroll_Component__c payrollComponent : payrollComponentList) {
            System.assertEquals(project.Id, payrollComponent.Project__c);
            System.assert(payrollComponent.Approval_Status__c == waitingForApprovalStatus, 'The Payroll_component must be with Approval_Status = "Waiting For Approval"');
            System.assert(payrollComponent.CurrencyIsoCode == DEFAULT_CURRENCY_CODE);
            System.assert(payrollComponent.SumType__c == IncrementSumType);
            System.assert(payrollComponent.Sum__c == DEFAULT_AMOUNT);
            System.assert(String.isNotBlank(payrollComponent.Contractor__c), 'The Payroll_component must have the Contractor ID.');
            System.assert(String.isNotBlank(payrollComponent.Account__c), 'The Payroll_component must have the Personal Account ID of the Contractor.');
            System.assert(payrollComponent.StartDate__c == payrollStartDate, 'The date should be on the 1 day of the current or next month if today is greater than 19.');
            System.assert(payrollComponent.EndDate__c == payrollStartDate, 'The date should be on the 1 day of the current or next month if today is greater than 19.');
            System.assertEquals(
                    PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId(),
                    payrollComponent.RecordTypeId
            );
        }
    }

    @IsTest
    static void testGenerateReimbursement_withTravel() {
        final String DEFAULT_REASON = 'Default Reason';
        final String DEFAULT_COMMENT = 'Default Comment';
        final String DEFAULT_FILE_NAME = 'Default File';
        final String DEFAULT_FILE_DATA = 'Default File Data';
        final Integer DEFAULT_AMOUNT = 100;

        String contractorName = DEFAULT_CONTRACTOR_NAME + 1;
        Contractor__c contractor = [ SELECT Id, Name FROM Contractor__c WHERE Name = :contractorName ];
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME LIMIT 1];
        User projectManager = [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
                AND Username = 'standarttestuserorg@testorg.com'
                LIMIT 1
        ];

        Budget_transaction__c budgetTransaction = new Budget_transaction__c();

        budgetTransaction.Project__c = project.Id;

        insert budgetTransaction;

        Travel_request__c travelRequest = new Travel_request__c();

        travelRequest.Budget_transaction__c = budgetTransaction.Id;

        insert travelRequest;


        LA_SalaryEditsService.PayrollComponentInfo payrollComponentInfo = new LA_SalaryEditsService.PayrollComponentInfo();

        payrollComponentInfo.contractorName = contractor.Name;
        payrollComponentInfo.contractorId = contractor.Id;
        payrollComponentInfo.reason = DEFAULT_REASON;
        payrollComponentInfo.amount = DEFAULT_AMOUNT;
        payrollComponentInfo.invoice = true;
        payrollComponentInfo.currencyIsoCode = DEFAULT_CURRENCY_CODE;
        payrollComponentInfo.travel = travelRequest.Id;
        payrollComponentInfo.budgetTransactionId = travelRequest.Budget_transaction__c;

        LA_SalaryEditsService.PayrollComponentItemInfo[] payrollComponentItemInfos = new LA_SalaryEditsService.PayrollComponentItemInfo[]{};
        LA_SalaryEditsService.AttachmentsInfo[] attachmentsInfos = new LA_SalaryEditsService.AttachmentsInfo[]{};

        for(Integer i = 0; i < 3; i++) {
            LA_SalaryEditsService.PayrollComponentItemInfo payrollComponentItemInfo = new LA_SalaryEditsService.PayrollComponentItemInfo();
            payrollComponentItemInfo.amount = 50;
            payrollComponentItemInfo.currencyIsoCode = DEFAULT_CURRENCY_CODE;
            payrollComponentItemInfo.comment = DEFAULT_COMMENT;

            payrollComponentItemInfos.add(payrollComponentItemInfo);

            LA_SalaryEditsService.AttachmentsInfo attachmentsInfo = new LA_SalaryEditsService.AttachmentsInfo();
            attachmentsInfo.fileData = DEFAULT_FILE_DATA;
            attachmentsInfo.fileName = DEFAULT_FILE_NAME;

            attachmentsInfos.add(attachmentsInfo);
        }

        Test.startTest();
        Model.LightningResponse generateReimbursement_response;

        System.runAs(projectManager) {
            generateReimbursement_response = LA_SalaryEditsController.generateReimbursement(project.Id, JSON.serialize(payrollComponentInfo), JSON.serialize(payrollComponentItemInfos), JSON.serialize(attachmentsInfos));
        }
        Test.stopTest();

        assertSuccessLightningResponse(generateReimbursement_response);

        Budget_transaction_item__c[] budgetTransactionItemList = [
                SELECT Id, Budget_transaction__c, Total_Amount__c
                FROM Budget_transaction_item__c
        ];

        for (Budget_transaction_item__c budgetTransactionItem : budgetTransactionItemList) {
            System.assertEquals(payrollComponentInfo.budgetTransactionId, budgetTransactionItem.Budget_transaction__c);
            System.assert(budgetTransactionItem.Total_Amount__c == DEFAULT_AMOUNT);
        }
    }

    static void assertSuccessLightningResponse(Model.LightningResponse response) {
        System.assert(response.success, 'Response must be successful. RESPONSE: ' + JSON.serializePretty(response));
    }
}