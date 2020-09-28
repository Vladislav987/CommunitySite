trigger BudgetTransactionItemTrigger on Budget_transaction_item__c (after insert, after update, after delete, after undelete, before insert, before update, before delete) {

    List<Triggers_Setting__mdt> tr = [SELECT is_Active__c
                                      FROM Triggers_Setting__mdt
                                      WHERE DeveloperName = 'BudgetTransactionItemTrigger'];

    if (tr.isEmpty() || tr[0].is_Active__c == true) {

        SObjectDomain.triggerHandler(BudgetTransactionItemTriggerHandler.class);
    }
}