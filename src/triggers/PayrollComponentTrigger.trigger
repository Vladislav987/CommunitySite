/**
 * Created by IlliaLuhovyi on 6/22/2020.
 */

trigger PayrollComponentTrigger on Payroll_Component__c (after update, before update) {
    List<Triggers_Setting__mdt> tr = [
            SELECT is_Active__c
            FROM Triggers_Setting__mdt
            WHERE DeveloperName = 'PayrollComponentTrigger'];

    if (tr.isEmpty() || tr[0].is_Active__c == true) {
        SObjectDomain.triggerHandler(PayrollComponentTriggerHandler.class);
    }
}