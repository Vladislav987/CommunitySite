trigger SalaryHistoryTrigger on Salary_History__c (before update, after update, before insert, after insert) {

    List<Triggers_Setting__mdt> tr = [SELECT is_Active__c
                                      FROM Triggers_Setting__mdt
                                      WHERE DeveloperName = 'SalaryHistoryTrigger'];

    if (tr.isEmpty() || tr[0].is_Active__c == true) {
        SObjectDomain.triggerHandler(SalaryHistoryTriggerHandler.class);
    }
}