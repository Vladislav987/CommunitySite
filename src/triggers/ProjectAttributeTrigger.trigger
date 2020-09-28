/**
 * Created by MaxymMirona on 10.08.2020.
 */

trigger ProjectAttributeTrigger on Project_attribute__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    List<Triggers_Setting__mdt> tr = [
            SELECT is_Active__c
            FROM Triggers_Setting__mdt
            WHERE DeveloperName = 'ProjectAttributeTrigger'
    ];

    if (tr.isEmpty() || tr[0].is_Active__c == true) {
        SObjectDomain.triggerHandler(ProjectAttributeTriggerHandler.class);
    }
}