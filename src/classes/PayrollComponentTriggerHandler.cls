/**
 * Created by IlliaLuhovyi on 6/23/2020.
 */

public without sharing class PayrollComponentTriggerHandler extends SObjectDomain {
    PayrollComponentService service = new PayrollComponentService();

    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        service.setRejectionReason((Map<Id, Payroll_Component__c>)Trigger.newMap, (Map<Id, Payroll_Component__c>)existingRecords);
        service.checkRecordIsReimbursable((Map<Id, Payroll_Component__c>)Trigger.newMap);
    }

    public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
        service.handleComponentAfterUpdateForReimbursement((Map<Id, Payroll_Component__c>)Trigger.newMap, (Map<Id, Payroll_Component__c>)existingRecords);
        service.createBudgetTransactionForBonuses((Map<Id, Payroll_Component__c>)Trigger.newMap, (Map<Id, Payroll_Component__c>)existingRecords);
        service.moveComponentToNextApproveLevel((Map<Id, Payroll_Component__c>)Trigger.newMap, (Map<Id, Payroll_Component__c>)existingRecords);
    }
}