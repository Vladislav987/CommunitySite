/**
 * Created by IlliaLuhovyi on 6/23/2020.
 */

@IsTest
private class PayrollComponentTest {

    @TestSetup
    static void setup() {
        Contractor__c[] contractorList = new Contractor__c[]{};

        for (Integer index = 0; index < 5; index++) {
            Contractor__c contractor = new Contractor__c();
            contractor.Name = 'Contractor ' + index;
            contractor.Resource_Type__c = ContractorSelector.RESOURCE_TYPE_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceTypePicklistKey.SFDC_DEVELOPER);
            contractor.Resource_Level__c = ContractorSelector.RESOURCE_LEVEL_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceLevelPicklistKey.TRAINEE);
            contractor.Department__c = ContractorSelector.DEPARTMENT_PICKLIST_VALUES_MAP.get(ContractorSelector.DepartmentPicklistKey.SFDC_DEPARTMENT);
            contractor.Station__c = ContractorSelector.STATION_PICKLIST_VALUES_MAP.get(ContractorSelector.StationPicklistKey.CTDEV_KYIV_OFFICE);
            contractor.CurrencyIsoCode = 'USD';
            contractor.Joining_Date__c = Date.today();
            contractorList.add(contractor);
        }

        insert contractorList;

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

        Project__c project = new Project__c();
        project.Name = 'Project';
        project.CurrencyIsoCode = 'USD';
        project.Contract_type__c = ProjectSelector.CONTRACT_TYPE_PICKLIST_VALUES_MAP.get(ProjectSelector.ContractTypePicklistKey.FIXED_COST);
        project.Project_type__c = ProjectSelector.PROJECT_TYPE_PICKLIST_VALUES_MAP.get(ProjectSelector.ProjectTypePicklistKey.OUTSTAFF);
        project.Project_Manager__c = userList[0].Id;
        project.OwnerId = userList[0].Id;
        project.Start_date__c = System.today();
        project.End_date__c = System.today();

        insert project;

        Budget_transaction__c budgetTransaction = new Budget_transaction__c();
        budgetTransaction.Project__c = project.Id;
        budgetTransaction.RecordTypeId = BudgetTransactionSelector.RECORD_TYPE_INFO_REIMBURSABLE_EXPENSE.getRecordTypeId();
        budgetTransaction.CurrencyIsoCode = 'USD';

        insert budgetTransaction;

        Travel_request__c travelRequest = new Travel_request__c();
        travelRequest.Budget_transaction__c = budgetTransaction.Id;
        travelRequest.Country__c = TravelRequestSelector.COUNTRY_PICKLIST_VALUES_MAP.get(TravelRequestSelector.CountryPicklistKey.UKRAINE);
        travelRequest.City__c = TravelRequestSelector.CITY_PICKLIST_VALUES_MAP.get(TravelRequestSelector.CityPicklistKey.KYIV);
        travelRequest.Start_Date__c = System.today();
        travelRequest.End_Date__c = System.today();

        insert travelRequest;

        Payroll_Component__c[] payrollComponents = new Payroll_Component__c[]{};

        for(Integer i = 0; i < 200; i++) {
            Payroll_Component__c payrollComponent = new Payroll_Component__c();
            payrollComponent.Sum__c = 100;
            payrollComponent.CurrencyIsoCode = 'USD';
            payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
            payrollComponent.Account__c = accountList[0].Id;
            payrollComponent.Budget_transaction__c = budgetTransaction.Id;
            payrollComponent.Approver__c = userList[0].Id;
            payrollComponent.OwnerId = userList[0].Id;
            payrollComponent.RecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId();
            payrollComponent.Travel_request__c = travelRequest.Id;
            payrollComponent.Project__c = project.Id;
            payrollComponents.add(payrollComponent);
        }

        for(Integer i = 0; i < 200; i++) {
            Payroll_Component__c payrollComponentWithoutTravelAndBudget = new Payroll_Component__c();
            payrollComponentWithoutTravelAndBudget.Sum__c = 200;
            payrollComponentWithoutTravelAndBudget.CurrencyIsoCode = 'USD';
            payrollComponentWithoutTravelAndBudget.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
            payrollComponentWithoutTravelAndBudget.Account__c = accountList[0].Id;
            payrollComponentWithoutTravelAndBudget.Approver__c = userList[0].Id;
            payrollComponentWithoutTravelAndBudget.OwnerId = userList[0].Id;
            payrollComponentWithoutTravelAndBudget.RecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId();
            payrollComponentWithoutTravelAndBudget.Project__c = project.Id;
            payrollComponents.add(payrollComponentWithoutTravelAndBudget);
        }

        for(Integer i = 0; i < 200; i++) {
            Payroll_Component__c payrollComponentWithoutTravelAndBudgetForBonus = new Payroll_Component__c();
            payrollComponentWithoutTravelAndBudgetForBonus.Sum__c = 300;
            payrollComponentWithoutTravelAndBudgetForBonus.CurrencyIsoCode = 'USD';
            payrollComponentWithoutTravelAndBudgetForBonus.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
            payrollComponentWithoutTravelAndBudgetForBonus.Account__c = accountList[0].Id;
            payrollComponentWithoutTravelAndBudgetForBonus.Contractor__c = contractorList[0].Id;
            payrollComponentWithoutTravelAndBudgetForBonus.Approver__c = userList[0].Id;
            payrollComponentWithoutTravelAndBudgetForBonus.OwnerId = userList[0].Id;
            payrollComponentWithoutTravelAndBudgetForBonus.RecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_BONUS.getRecordTypeId();
            payrollComponentWithoutTravelAndBudgetForBonus.Project__c = project.Id;
            payrollComponents.add(payrollComponentWithoutTravelAndBudgetForBonus);
        }

        insert payrollComponents;
    }

    @IsTest
    static void testCreateBudgetTransactionItemForReimbursement() {
        Payroll_Component__c[] payrollComponents = [SELECT Id, Budget_transaction__c, Approval_Status__c, CurrencyIsoCode, Sum__c, RecordTypeId, Reimbursment__c, Travel_request__c, Project__c FROM Payroll_Component__c WHERE Travel_request__c != NULL AND RecordTypeId = :PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId() LIMIT 200];

        Id budgetTransactionId;

        for(Payroll_Component__c payrollComponent: payrollComponents) {
            budgetTransactionId = payrollComponent.Budget_transaction__c;
            payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
            payrollComponent.Reimbursment__c = PayrollComponentSelector.REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ReimbursementTypePicklistKey.REIMBURSABLE);
        }

        update payrollComponents;

        Budget_transaction_item__c[] budgetTransactionItems = [SELECT Id, Budget_transaction__c, Payroll_Component__c FROM Budget_transaction_item__c LIMIT 200];
        System.assert(!budgetTransactionItems.isEmpty(), 'List should not be empty');

        for(Budget_transaction_item__c budgetTransactionItem: budgetTransactionItems) {
            System.assert(String.isNotBlank(budgetTransactionItem.Payroll_Component__c), 'Payroll_Component__c should not be blank');
            System.assertEquals(budgetTransactionItem.Budget_transaction__c, budgetTransactionId);
        }
    }

    @IsTest
    static void testCreateBudgetTransactionWithTravelForReimbursement() {
        Budget_transaction__c budgetTransaction = [SELECT RecordTypeId FROM Budget_transaction__c LIMIT 1];
        Payroll_Component__c[] payrollComponents = [SELECT Id, Budget_transaction__c, Approval_Status__c, CurrencyIsoCode, Sum__c, RecordTypeId, Reimbursment__c, Travel_request__c, Project__c FROM Payroll_Component__c WHERE Travel_request__c != NULL AND RecordTypeId = :PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId() LIMIT 200];
        budgetTransaction.RecordTypeId = BudgetTransactionSelector.RECORD_TYPE_INFO_INCLUDED_EXPENSE.getRecordTypeId();
        Set<Id> payrollComponentIds = new Set<Id>();
        Set<Id> budgetTransactionIds = new Set<Id>();

        for(Payroll_Component__c payrollComponent: payrollComponents) {
            payrollComponentIds.add(payrollComponent.Id);
            payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
            payrollComponent.Reimbursment__c = PayrollComponentSelector.REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ReimbursementTypePicklistKey.REIMBURSABLE);
        }

        SObject[] recordToUpdate = new SObject[]{};

        recordToUpdate.add(budgetTransaction);
        recordToUpdate.addAll(payrollComponents);

        update recordToUpdate;

        Payroll_Component__c[] updatedPayrollComponents = [SELECT Budget_transaction__c, Sum__c, Project__c FROM Payroll_Component__c WHERE Id IN :payrollComponentIds LIMIT 200];
        Id projectId;
        Decimal sum;

        for(Payroll_Component__c payrollComponent: updatedPayrollComponents) {
            budgetTransactionIds.add(payrollComponent.Budget_transaction__c);
            projectId = payrollComponent.Project__c;
            sum = payrollComponent.Sum__c;
        }

        Budget_transaction__c[] newBudgetTransactions = [SELECT Id, Amount__c, RecordTypeId, Project__c FROM Budget_transaction__c WHERE Id IN :budgetTransactionIds LIMIT 200];

        for(Budget_transaction__c newBudgetTransaction: newBudgetTransactions) {
            System.assertEquals(BudgetTransactionSelector.RECORD_TYPE_INFO_INCLUDED_EXPENSE.getRecordTypeId(), newBudgetTransaction.RecordTypeId);
            System.assertEquals(projectId, newBudgetTransaction.Project__c);
            System.assertEquals(sum, newBudgetTransaction.Amount__c);
        }

    }

    @IsTest
    static void testCreateBudgetTransactionItemForReimbursement_WithAnotherCurrency() {
        Budget_transaction__c budgetTransaction =  [SELECT CurrencyIsoCode, Amount__c FROM Budget_transaction__c LIMIT 1];
        Payroll_Component__c[] payrollComponents = [SELECT Id, Budget_transaction__c, Approval_Status__c, CurrencyIsoCode, Sum__c, RecordTypeId, Travel_request__c, Reimbursment__c, Project__c FROM Payroll_Component__c WHERE Travel_request__c != NULL AND RecordTypeId = :PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId() LIMIT 200];
        Id budgetTransactionId;
        Decimal sum;

        for(Payroll_Component__c payrollComponent: payrollComponents) {
            payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
            payrollComponent.Reimbursment__c = PayrollComponentSelector.REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ReimbursementTypePicklistKey.REIMBURSABLE);
            budgetTransactionId = payrollComponent.Budget_transaction__c;
            sum = payrollComponent.Sum__c;
        }

        budgetTransaction.CurrencyIsoCode = 'UAH';
        SObject[] recordToUpdate = new SObject[]{};

        recordToUpdate.add(budgetTransaction);
        recordToUpdate.addAll(payrollComponents);

        update recordToUpdate;

        Budget_transaction_item__c[] budgetTransactionItems = [SELECT Id, Amount__c, Budget_transaction__c, Payroll_Component__c FROM Budget_transaction_item__c LIMIT 200];
        System.assert(!budgetTransactionItems.isEmpty(), 'List should not be empty');

        for(Budget_transaction_item__c budgetTransactionItem: budgetTransactionItems) {
            System.assert(String.isNotBlank(budgetTransactionItem.Payroll_Component__c), 'Payroll_Component__c should not be blank');
            System.assertEquals(budgetTransactionItem.Budget_transaction__c, budgetTransactionId);
            System.assert(sum != budgetTransaction.Amount__c, 'Amount of Budget_Transaction_item__c should not be equal to Sum of Payroll_Component__c');
        }
    }

    @IsTest
    static void testCreateBudgetTransactionForReimbursement() {
        Payroll_Component__c[] payrollComponents = [SELECT Id, Budget_transaction__c, Approval_Status__c, CurrencyIsoCode, Sum__c, RecordTypeId, Travel_request__c, Reimbursment__c, Project__c FROM Payroll_Component__c WHERE Travel_request__c = NULL AND RecordTypeId = :PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId() LIMIT 200];
        Set<Id> payrollComponentIds = new Set<Id>();
        Set<Id> budgetTransactionIds = new Set<Id>();

        for(Payroll_Component__c payrollComponent: payrollComponents) {
            payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
            payrollComponent.Reimbursment__c = PayrollComponentSelector.REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ReimbursementTypePicklistKey.NOT_REIMBURSABLE);
            payrollComponentIds.add(payrollComponent.Id);
        }

        update payrollComponents;


        Payroll_Component__c[] updatedPayrollComponents = [SELECT Id, Budget_transaction__c, Sum__c, Project__c FROM Payroll_Component__c WHERE Id IN :payrollComponentIds LIMIT 200];
        Id projectId;
        Decimal sum;

        for(Payroll_Component__c payrollComponent: updatedPayrollComponents) {
            budgetTransactionIds.add(payrollComponent.Budget_transaction__c);
            projectId = payrollComponent.Project__c;
            sum = payrollComponent.Sum__c;
        }

        Budget_transaction__c[] budgetTransactions = [SELECT Amount__c, RecordTypeId, Project__c, Id FROM Budget_transaction__c WHERE Id IN :budgetTransactionIds LIMIT 200];

        for(Budget_transaction__c budgetTransaction: budgetTransactions) {
            System.assertEquals(BudgetTransactionSelector.RECORD_TYPE_INFO_INCLUDED_EXPENSE.getRecordTypeId(), budgetTransaction.RecordTypeId);
            System.assertEquals(projectId, budgetTransaction.Project__c);
            System.assertEquals(sum, budgetTransaction.Amount__c);
        }

    }

    @IsTest
    static void testCreateBudgetTransactionForReimbursement_WithAnotherCurrency() {
        Project__c project =  [SELECT Id, CurrencyIsoCode FROM Project__c LIMIT 1];
        Payroll_Component__c[] payrollComponents = [SELECT Id, Budget_transaction__c, Approval_Status__c, CurrencyIsoCode, Sum__c, RecordTypeId, Travel_request__c, Reimbursment__c, Project__c FROM Payroll_Component__c WHERE Travel_request__c = NULL AND RecordTypeId = :PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId() LIMIT 200];
        Set<Id> payrollComponentIds = new Set<Id>();

        for(Payroll_Component__c payrollComponent: payrollComponents) {
            payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
            payrollComponent.Reimbursment__c = PayrollComponentSelector.REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ReimbursementTypePicklistKey.NOT_REIMBURSABLE);
            payrollComponentIds.add(payrollComponent.Id);
        }

        project.CurrencyIsoCode = 'UAH';
        SObject[] recordToUpdate = new SObject[]{};

        recordToUpdate.add(project);
        recordToUpdate.addAll(payrollComponents);

        update recordToUpdate;


        Payroll_Component__c[] updatedPayrollComponents = [SELECT Id, Budget_transaction__c, Project__c, Sum__c FROM Payroll_Component__c WHERE Id IN :payrollComponentIds LIMIT 200];
        Set<Id> budgetTransactionIds = new Set<Id>();
        Id projectId;
        Decimal sum;

        for(Payroll_Component__c payrollComponent: updatedPayrollComponents) {
            budgetTransactionIds.add(payrollComponent.Budget_transaction__c);
            projectId = payrollComponent.Project__c;
            sum = payrollComponent.Sum__c;
        }

        Budget_transaction__c[] budgetTransactions = [SELECT Amount__c, RecordTypeId, Project__c, Id FROM Budget_transaction__c WHERE Id IN :budgetTransactionIds LIMIT 200];


        for(Budget_transaction__c budgetTransaction: budgetTransactions) {
            System.assertEquals(BudgetTransactionSelector.RECORD_TYPE_INFO_INCLUDED_EXPENSE.getRecordTypeId(), budgetTransaction.RecordTypeId);
            System.assertEquals(projectId, budgetTransaction.Project__c);
            System.assert(sum != budgetTransaction.Amount__c, 'Amount of Budget_Transaction_item__c should not be equal to Sum of Payroll_Component__c');
        }

    }

    @IsTest
    static void testCreateBudgetTransactionForBonuses() {
        Payroll_Component__c[] payrollComponents = [SELECT Id, Budget_transaction__c, Approval_Status__c, CurrencyIsoCode, Sum__c, RecordTypeId, Travel_request__c, Reimbursment__c, Project__c FROM Payroll_Component__c  WHERE Travel_request__c = NULL AND RecordTypeId = :PayrollComponentSelector.RECORD_TYPE_INFO_BONUS.getRecordTypeId() LIMIT 200];
        Set<Id> payrollComponentIds = new Set<Id>();

        for(Payroll_Component__c payrollComponent: payrollComponents) {
            payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
            payrollComponent.Reimbursment__c = PayrollComponentSelector.REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ReimbursementTypePicklistKey.NOT_REIMBURSABLE);
            payrollComponentIds.add(payrollComponent.Id);
        }

        update payrollComponents;

        Payroll_Component__c[] updatedPayrollComponents = [SELECT Id, Budget_transaction__c, Project__c, Sum__c FROM Payroll_Component__c WHERE Id IN :payrollComponentIds LIMIT 200];
        Set<Id> budgetTransactionIds = new Set<Id>();
        Id projectId;
        Decimal sum;

        for(Payroll_Component__c payrollComponent: updatedPayrollComponents) {
            budgetTransactionIds.add(payrollComponent.Budget_transaction__c);
            projectId = payrollComponent.Project__c;
            sum = payrollComponent.Sum__c;
        }

        Budget_transaction__c[] budgetTransactions = [SELECT Amount__c, RecordTypeId, Project__c, Id FROM Budget_transaction__c WHERE Id IN :budgetTransactionIds LIMIT 200];

        for(Budget_transaction__c budgetTransaction: budgetTransactions) {
            System.assertEquals(BudgetTransactionSelector.RECORD_TYPE_INFO_INCLUDED_EXPENSE.getRecordTypeId(), budgetTransaction.RecordTypeId);
            System.assertEquals(projectId, budgetTransaction.Project__c);
            System.assertEquals(sum, budgetTransaction.Amount__c);
        }
    }

    @IsTest
    static void testMoveComponentToNextApproveLevel() {
        User user = [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE
                AND Username = 'standarttestuserorg@testorg.com'
                LIMIT 1
        ];
        Payroll_Component__c[] payrollComponents = [SELECT Id, Budget_transaction__c, Approval_Status__c, CurrencyIsoCode, Sum__c, Approver__c, RecordTypeId, Reimbursment__c, Travel_request__c, Project__c FROM Payroll_Component__c WHERE Travel_request__c != NULL AND RecordTypeId = :PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId() LIMIT 200];
        Set<Id> payrollComponentIds = new Set<Id>();
        Id approverId;

        for(Payroll_Component__c payrollComponent: payrollComponents) {
            payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_MANAGER_APPROVAL);
            payrollComponent.Reimbursment__c = PayrollComponentSelector.REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ReimbursementTypePicklistKey.NOT_REIMBURSABLE);
            payrollComponentIds.add(payrollComponent.Id);
            approverId = payrollComponent.Approver__c;
        }

        System.runAs(user) {
            update payrollComponents;
        }

        Payroll_Component__c[] updatedPayrollComponents = [SELECT Budget_transaction__c, Approver__c FROM Payroll_Component__c WHERE Id IN :payrollComponentIds LIMIT 200];

        for(Payroll_Component__c payrollComponent: updatedPayrollComponents) {
            System.assert(String.isNotEmpty(payrollComponent.Approver__c), 'Approver should be not empty');
            System.assert(payrollComponent.Approver__c != approverId, 'Approver must be different');
        }
    }
}