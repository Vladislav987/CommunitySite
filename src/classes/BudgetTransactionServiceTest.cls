/**
 * Created by MaxymMirona on 12.08.2020.
 */
@IsTest
public with sharing class BudgetTransactionServiceTest {
    private static final Date TEST_DATE_START = System.today().addMonths(-2);
    private static final Date TEST_DATE_END = System.today().addMonths(2);
    private static final User PM = [SELECT Id FROM User WHERE Profile.Name = 'CT_Project Manager' AND IsActive = TRUE LIMIT 1];

    @TestSetup
    private static void setup() {
        if (PM != null) {
            System.runAs(PM) {
                Project__c project = new Project__c();
                project.Name = 'project name';
                project.Project_type__c = 'Outsource';
                project.Contract_type__c = 'Fixed cost';
                project.Start_date__c = TEST_DATE_START;
                project.End_date__c = TEST_DATE_END;

                insert project;

                Budget_transaction__c budgetTransaction = new Budget_transaction__c();
                budgetTransaction.Status__c = 'Draft';
                budgetTransaction.Project__c = project.Id;

                insert budgetTransaction;
            }
        }
    }

    @IsTest
    private static void validateBudgetTransactionsTestCorrectFlow(){
        List<Budget_transaction__c> budgetTransactions = [SELECT Id, Status__c FROM Budget_transaction__c];

        if (!budgetTransactions.isEmpty() && PM != null) {
            System.runAs(PM) {
                budgetTransactions[0].Status__c = 'Paid';
                String result = '';

                Test.startTest();
                try {
                    update budgetTransactions;
                } catch (Exception e) {
                    if (e.getTypeName() == System.DmlException.class.toString()) {
                        result = ((System.DmlException)e).getDmlMessage(0);
                    }
                }
                Test.stopTest();

                System.assertEquals(BudgetTransactionService.INVALID_STATUS_FOR_PROJECT_MANAGER_ERROR, result);
            }
        }
    }

}