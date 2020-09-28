trigger MonthlyReportTrigger on Monthly_Report__c (before insert, before update, before delete, after insert, after update, after delete) {

    List<Triggers_Setting__mdt> tr = [SELECT is_Active__c
                                      FROM Triggers_Setting__mdt
                                      WHERE DeveloperName = 'MonthlyReportTrigger'];

    if (tr.isEmpty() || tr[0].is_Active__c == true) {

        SObjectDomain.triggerHandler(MonthlyReportHandler.class);
    }
}