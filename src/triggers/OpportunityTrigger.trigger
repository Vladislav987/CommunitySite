/**
 * Created by MaxymMirona on 15.04.2020.
 */

trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    List<Triggers_Setting__mdt> tr = [
            SELECT is_Active__c
            FROM Triggers_Setting__mdt
            WHERE DeveloperName = 'OpportunityTrigger'
    ];

    if (tr.isEmpty() || tr[0].is_Active__c == true) {
        SObjectDomain.triggerHandler(OpportunityTriggerHandler.class);
    }
}