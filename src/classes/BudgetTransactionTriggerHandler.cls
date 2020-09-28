/**
 * Created by MaxymMirona on 12.08.2020.
 */

public with sharing class BudgetTransactionTriggerHandler extends SObjectDomain {

    BudgetTransactionService budgetTransactionServiceObject = new BudgetTransactionService();
    User currentUser = Util.CURRENT_USER;

    public override void onBeforeInsert() {
        Boolean passedValidation = currentUser.Skip_validation_rules__c ? true : budgetTransactionServiceObject.validateBudgetTransactions((List<Budget_transaction__c>)this.records);

        if (passedValidation) {

        }
    }

    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        Boolean passedValidation = currentUser.Skip_validation_rules__c ? true : budgetTransactionServiceObject.validateBudgetTransactions((Map<Id, Budget_transaction__c>)existingRecords, (List<Budget_transaction__c>)this.records);

        if (passedValidation) {

        }
    }

}