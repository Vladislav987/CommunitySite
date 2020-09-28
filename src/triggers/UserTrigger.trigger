trigger UserTrigger on User (before insert, after insert) {
    List<Triggers_Setting__mdt> tr = [
            SELECT is_Active__c
            FROM Triggers_Setting__mdt
            WHERE DeveloperName = 'UserTrigger'
    ];

    if (tr.isEmpty() || tr[0].is_Active__c == true) {
        SObjectDomain.triggerHandler(UserTriggerHandler.class);

    }
}