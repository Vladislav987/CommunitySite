/**
 * Created by MaxymMirona on 12.08.2020.
 */

trigger BudgetTransactionTrigger on Budget_transaction__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    List<Triggers_Setting__mdt> tr = [
            SELECT is_Active__c
            FROM Triggers_Setting__mdt
            WHERE DeveloperName = 'BudgetTransactionTrigger'
    ];

    if (tr.isEmpty() || tr[0].is_Active__c == true) {

        SObjectDomain.triggerHandler(BudgetTransactionTriggerHandler.class);
    }
}