/**
 * Created by MaxymMirona on 17.03.2020.
 */
@IsTest
public without sharing class BudgetTransactionControllerTest {
    private static final Date TEST_DATE_START = Date.newInstance(2015, 1, 1);
    private static final Date TEST_DATE_END = Date.newInstance(2020, 1, 1);
    private static final Integer TEST_MONTH_NUMBER = 4;
    public static final Id INVOICE_BUDGET_TRANSACTION_RECORD_TYPE_ID = Schema.Budget_transaction__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Invoice').getRecordTypeId();
    private static final Id PROJECT_ALLOCATION_RECORD_TYPE =
            Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Project').getRecordTypeId();
    BudgetTransactionService budgetTransactionServiceObject = new BudgetTransactionService();

    @TestSetup
    private static void setup() {
        Project__c project = new Project__c();
        project.Name = 'project name';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.Start_date__c = TEST_DATE_START;
        project.End_date__c = TEST_DATE_END;

        insert project;

        List<Contractor__c> contractors = new List<Contractor__c>();

        for (Integer i = 0; i < 2; ++i){
            Contractor__c contractor = new Contractor__c();

            contractor.Name = 'Test Contractor' + i;

            contractors.add(contractor);
        }

        insert contractors;

        List<Allocation__c> allocations = new List<Allocation__c>();

        for (Integer i = 0; i < 2; ++i){
            Allocation__c allocation = new Allocation__c();

            allocation.Billed_as__c = contractors[0].Id;
            allocation.Contractor__c = contractors[i].Id;
            allocation.Project__c = project.Id;
            allocation.Allocation__c = 12;
            allocation.Start_date__c = TEST_DATE_END.addMonths(-3);
            allocation.End_date__c = TEST_DATE_END.addMonths(-2);
            allocation.Expected_Rate__c = 15;
            allocation.Allocation_Type__c = 'Billable';

            allocations.add(allocation);
        }

        insert allocations;


        List<Monthly_Report__c> monthlyReports = new List<Monthly_Report__c>();

        for (Integer i = 0; i < 2; ++i){
            Monthly_Report__c report = new Monthly_Report__c();

            report.Project__c = project.Id;
            report.Monthly_Report_Start_Date__c = TEST_DATE_START.addMonths(2);
            report.Monthly_Report_End_Date__c = TEST_DATE_START.addMonths(-2);
            report.Allocation__c = allocations[i].Id;
            report.Fact_hours__c = 12;

            monthlyReports.add(report);
        }

        insert monthlyReports;

        Budget_transaction__c budgetTransaction = new Budget_transaction__c();
        budgetTransaction.Project__c = project.Id;
        budgetTransaction.Invoiced_on__c = Date.newInstance(project.Start_date__c.year(), TEST_MONTH_NUMBER, 1);
        budgetTransaction.RecordTypeId = INVOICE_BUDGET_TRANSACTION_RECORD_TYPE_ID;
        budgetTransaction.Status__c = 'Draft';

        insert budgetTransaction;
    }

    @IsTest
    private static void getInitDataForModalTestCorrectFlow(){

        List<Project__c> projects = [SELECT id FROM Project__c];

        if (!projects.isEmpty()) {

            Test.startTest();
            BudgetTransactionController.ModalInfo result = BudgetTransactionController.getInitDataForModal(projects[0].Id, true);
            Test.stopTest();

            System.assertEquals(2, result.years.size());
        }
    }

    @IsTest
    private static void generateBudgetTransactionItemTestCorrectFlow(){
        List<Project__c> projects = [SELECT id, (SELECT Id FROM Monthly_Reports__r) FROM Project__c];
        List<Budget_transaction__c> budgetTransactions = [SELECT id FROM Budget_transaction__c];

        if (!projects.isEmpty() && !budgetTransactions.isEmpty()) {
            if (!projects[0].Monthly_Reports__r.isEmpty()) {
                String inputObjectString = '{"Id" : "' + projects[0].Monthly_Reports__r[0].Id + '", "BudgetTransactionId" : "' + budgetTransactions[0].Id + '"}';
                List<Object> inputObjects = new List<Object>{
                        JSON.deserializeUntyped(inputObjectString)
                };

                Test.startTest();
                String result = BudgetTransactionController.generateBudgetTransaction(projects[0].Id, inputObjects, true).resultMessage;
                Test.stopTest();

                System.assertEquals('Successfully created 1 Budget Transaction Item!', result);
            }
        }
    }

    @IsTest
    private static void recalculateBudgetTransactionChangedFactHoursTestCorrectFlow(){
        List<Project__c> projects = [SELECT id, (SELECT Id, Fact_hours__c FROM Monthly_Reports__r) FROM Project__c];
        List<Budget_transaction__c> budgetTransactions = [SELECT id FROM Budget_transaction__c];

        if (!projects.isEmpty() && !budgetTransactions.isEmpty()) {
            if (!projects[0].Monthly_Reports__r.isEmpty()) {
                String inputObjectString = '{"Id" : "' + projects[0].Monthly_Reports__r[0].Id + '", "BudgetTransactionId" : "' + budgetTransactions[0].Id + '"}';
                List<Object> inputObjects = new List<Object>{
                        JSON.deserializeUntyped(inputObjectString)
                };

                Test.startTest();
                BudgetTransactionController.generateBudgetTransaction(projects[0].Id, inputObjects, true);

                update new Monthly_Report__c(Id = projects[0].Monthly_Reports__r[0].Id, Fact_hours__c = projects[0].Monthly_Reports__r[0].Fact_hours__c + 1);

                String result = BudgetTransactionController.recalculateBudgetTransaction(budgetTransactions[0].Id).resultMessage;
                Test.stopTest();

                System.assertEquals('Successfully updated 1 Budget Transaction Item!', result);
            }
        }
    }

    @IsTest
    private static void generateBudgetTransactionItemWithExistingItemTestCorrectFlow(){
        List<Project__c> projects = [SELECT id, (SELECT Id, Allocation__r.Billed_as__c FROM Monthly_Reports__r) FROM Project__c];
        List<Budget_transaction__c> budgetTransactions = [SELECT id FROM Budget_transaction__c];


        if (!projects.isEmpty() && !budgetTransactions.isEmpty()) {
            if (!projects[0].Monthly_Reports__r.isEmpty()) {

                String inputObjectString = '{"Id" : "' + projects[0].Monthly_Reports__r[0].Id + '", "BudgetTransactionId" : "' + budgetTransactions[0].Id + '"}';
                String inputObjectString2 = '{"Id" : "' + projects[0].Monthly_Reports__r[1].Id + '", "BudgetTransactionId" : "' + budgetTransactions[0].Id + '"}';
                List<Object> inputObjects = new List<Object>{
                        JSON.deserializeUntyped(inputObjectString)
                };
                List<Object> inputObjects2 = new List<Object>{
                        JSON.deserializeUntyped(inputObjectString2)
                };

                Test.startTest();
                BudgetTransactionController.generateBudgetTransaction(projects[0].Id, inputObjects, true);
                String result = BudgetTransactionController.generateBudgetTransaction(projects[0].Id, inputObjects2, true).resultMessage;
                Test.stopTest();

                System.assertEquals('Successfully updated 1 Budget Transaction Item!', result);
            }
        }
    }

    @IsTest
    private static void generateBudgetTransactionWithBudgetTransactionAndItemsTestCorrectFlow(){
        List<Project__c> projects = [SELECT Id, (SELECT Id FROM Monthly_Reports__r) FROM Project__c];

        if (!projects.isEmpty()) {
            if (!projects[0].Monthly_Reports__r.isEmpty()) {
                String inputObjectString = '{"Id" : "' + projects[0].Monthly_Reports__r[0].Id + '", "BudgetTransactionId" : "New"}';
                List<Object> inputObjects = new List<Object>{
                        JSON.deserializeUntyped(inputObjectString)
                };

                Test.startTest();
                String result = BudgetTransactionController.generateBudgetTransaction(projects[0].Id, inputObjects, true).resultMessage;
                Test.stopTest();

                System.assertEquals('Successfully created 1 Budget Transaction and 1 Budget Transaction Item!', result);
            }
        }
    }

    @IsTest
    private static void generateBudgetTransactionWithBudgetTransactionAndItemsTestIncorrectFlow(){
        List<Project__c> projects = [SELECT id, (SELECT Id FROM Monthly_Reports__r) FROM Project__c];

        if (!projects.isEmpty()) {
            if (!projects[0].Monthly_Reports__r.isEmpty()) {
                String inputObjectString = '{"Id" : "' + projects[0].Id + '", "BudgetTransactionId" : "New"}';
                List<Object> inputObjects = new List<Object>{
                        JSON.deserializeUntyped(inputObjectString)
                };

                Test.startTest();
                String result = BudgetTransactionController.generateBudgetTransaction(projects[0].Id, inputObjects, true).resultMessage;
                Test.stopTest();

                System.assertEquals(BudgetTransactionService.INVALID_MONTHLY_REPORT_ID, result);
            }
        }
    }

    @IsTest
    private static void recalculateBudgetTransactionNewBudgetTransactionItemTestCorrectFlow(){
        List<Project__c> projects = [SELECT id, (SELECT Id, Allocation__r.Billed_as__c, Allocation__r.Expected_Rate__c, Allocation__c FROM Monthly_Reports__r) FROM Project__c];
        List<Budget_transaction__c> budgetTransactions = [SELECT id FROM Budget_transaction__c];


        if (!projects.isEmpty() && !budgetTransactions.isEmpty()) {
            if (!projects[0].Monthly_Reports__r.isEmpty()) {

                String inputObjectString = '{"Id" : "' + projects[0].Monthly_Reports__r[0].Id + '", "BudgetTransactionId" : "' + budgetTransactions[0].Id + '"}';
                String inputObjectString2 = '{"Id" : "' + projects[0].Monthly_Reports__r[1].Id + '", "BudgetTransactionId" : "' + budgetTransactions[0].Id + '"}';
                List<Object> inputObjects = new List<Object>{
                        JSON.deserializeUntyped(inputObjectString),
                        JSON.deserializeUntyped(inputObjectString2)
                };

                Test.startTest();
                BudgetTransactionController.generateBudgetTransaction(projects[0].Id, inputObjects, true);

                Allocation__c changedAllocation = new Allocation__c(
                        Id = projects[0].Monthly_Reports__r[1].Allocation__c,
                        CurrencyIsoCode = 'CAD'
                );

                update changedAllocation;

                String result = BudgetTransactionController.recalculateBudgetTransaction(budgetTransactions[0].Id).resultMessage;
                Test.stopTest();

                System.assertEquals('Successfully created 1 and updated 1 Budget Transaction Items', result);
            }
        }
    }

    @IsTest
    private static void recalculateBudgetTransactionUpdateAndDeleteBudgetTransactionItemTestCorrectFlow(){
        List<Project__c> projects = [SELECT id, (SELECT Id, Allocation__r.Billed_as__c, Allocation__r.Expected_Rate__c, Allocation__c FROM Monthly_Reports__r) FROM Project__c];
        List<Budget_transaction__c> budgetTransactions = [SELECT id FROM Budget_transaction__c];
        List<Contractor__c> contractors = [SELECT Id FROM Contractor__c];


        if (!projects.isEmpty() && !budgetTransactions.isEmpty()) {
            if (!projects[0].Monthly_Reports__r.isEmpty()) {

                String inputObjectString = '{"Id" : "' + projects[0].Monthly_Reports__r[0].Id + '", "BudgetTransactionId" : "' + budgetTransactions[0].Id + '"}';
                String inputObjectString2 = '{"Id" : "' + projects[0].Monthly_Reports__r[1].Id + '", "BudgetTransactionId" : "' + budgetTransactions[0].Id + '"}';
                List<Object> inputObjects = new List<Object>{
                        JSON.deserializeUntyped(inputObjectString),
                        JSON.deserializeUntyped(inputObjectString2)
                };

                Test.startTest();

                Allocation__c changedAllocation = new Allocation__c(
                        Id = projects[0].Monthly_Reports__r[1].Allocation__c,
                        Billed_as__c = projects[0].Monthly_Reports__r[1].Allocation__r.Billed_as__c == contractors[0].Id ? contractors[1].Id : contractors[0].Id
                );

                update changedAllocation;

                BudgetTransactionController.generateBudgetTransaction(projects[0].Id, inputObjects, true);

                changedAllocation.Billed_as__c = changedAllocation.Billed_as__c == contractors[0].Id ? contractors[1].Id : contractors[0].Id;

                update changedAllocation;

                String result = BudgetTransactionController.recalculateBudgetTransaction(budgetTransactions[0].Id).resultMessage;
                Test.stopTest();

                System.assertEquals('Successfully updated 2 Budget Transaction Items!', result);
            }
        }
    }

}