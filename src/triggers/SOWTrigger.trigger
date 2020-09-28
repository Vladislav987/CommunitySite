/**
 * Created by MaxymMirona on 18.06.2020.
 */

trigger SOWTrigger on SOW__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    List<Triggers_Setting__mdt> tr = [
            SELECT is_Active__c
            FROM Triggers_Setting__mdt
            WHERE DeveloperName = 'SOWTrigger'
    ];

    if (tr.isEmpty() || tr[0].is_Active__c == true) {
        SObjectDomain.triggerHandler(SOWTriggerHandler.class);
    }
}