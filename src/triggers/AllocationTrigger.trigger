/**
 * Created by Dmytro Ardashov on 24.04.2019.
 */

trigger AllocationTrigger on Allocation__c (after insert, after update, after delete, after undelete, before insert, before update, before delete) {
	
    List<Triggers_Setting__mdt> tr = [SELECT is_Active__c
                                      FROM Triggers_Setting__mdt
                                      WHERE DeveloperName = 'AllocationTrigger'];

    if (tr.isEmpty() || tr[0].is_Active__c == true) {
        SObjectDomain.triggerHandler(AllocationTriggerHandler.class);
    }
}