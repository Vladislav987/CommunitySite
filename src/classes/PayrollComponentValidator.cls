/**
 * Created by IlliaLuhovyi on 8/6/2020.
 */

public inherited sharing class PayrollComponentValidator {

    private final String WAITING_FOR_APPROVAL_STATUS = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
    private final String WAITING_FOR_MANAGER_APPROVAL_STATUS = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_MANAGER_APPROVAL);
    private final String APPROVED_STATUS = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
    private final String REJECTED_STATUS = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.REJECTED);
    private final Id REIMBURSEMENT_RECORD_TYPE_ID = PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId();
    private final Id BONUS_RECORD_TYPE_ID = PayrollComponentSelector.RECORD_TYPE_INFO_BONUS.getRecordTypeId();


    public Boolean isValidPCWithRTReimbursement(Payroll_Component__c payrollComponent) {
        return payrollComponent.RecordTypeId == REIMBURSEMENT_RECORD_TYPE_ID
                && payrollComponent.Travel_request__c != null
                && payrollComponent.Project__c != null;
    }

    public Boolean isValidPCWithRTReimbursementWithoutTravelRequest(Payroll_Component__c payrollComponent) {
        return payrollComponent.RecordTypeId == REIMBURSEMENT_RECORD_TYPE_ID
                && payrollComponent.Project__c != null;
    }

    public Boolean isValidPCWithRTBonus(Payroll_Component__c payrollComponent) {
        return payrollComponent.RecordTypeId == BONUS_RECORD_TYPE_ID
                && payrollComponent.Travel_request__c == null
                && payrollComponent.Budget_transaction__c == null
                && payrollComponent.Project__c != null
                && payrollComponent.Contractor__c != null
                && payrollComponent.Account__c != null;
    }

    public Boolean isValidRecordReimbursable(Payroll_Component__c payrollComponent) {
        return payrollComponent.RecordTypeId == REIMBURSEMENT_RECORD_TYPE_ID
                && payrollComponent.Approval_Status__c == WAITING_FOR_MANAGER_APPROVAL_STATUS
                && String.isBlank(payrollComponent.Reimbursment__c);
    }

    public Boolean isValidPCWithTravelRequestForCreationBT(Payroll_Component__c payrollComponent, Payroll_Component__c oldPayrollComponent, String convertedRecordType, String reimbursableType) {
        return payrollComponent.Reimbursment__c != convertedRecordType
                    && (
                        payrollComponent.Reimbursment__c == reimbursableType
                        && oldPayrollComponent.Approval_Status__c == WAITING_FOR_APPROVAL_STATUS
                        || payrollComponent.Reimbursment__c != reimbursableType
                        && oldPayrollComponent.Approval_Status__c == WAITING_FOR_MANAGER_APPROVAL_STATUS
                    );
    }

    public Boolean isValidPCSendToApprove(Payroll_Component__c payrollComponent, Payroll_Component__c oldPayrollComponent, String notReimbursableType) {
        return payrollComponent.Reimbursment__c == notReimbursableType
                && payrollComponent.Approval_Status__c == WAITING_FOR_MANAGER_APPROVAL_STATUS
                && oldPayrollComponent.Approval_Status__c == WAITING_FOR_APPROVAL_STATUS;
    }

    public Boolean isValidPCForCreationBTI(Payroll_Component__c payrollComponent, Payroll_Component__c oldPayrollComponent) {
        return payrollComponent.Approval_Status__c == APPROVED_STATUS
                && (oldPayrollComponent.Approval_Status__c == WAITING_FOR_APPROVAL_STATUS || oldPayrollComponent.Approval_Status__c == WAITING_FOR_MANAGER_APPROVAL_STATUS);
    }

    public Boolean isValidPCWithoutTravelRequestForCreationBT(Payroll_Component__c payrollComponent, Payroll_Component__c oldPayrollComponent) {
        return payrollComponent.Approval_Status__c == APPROVED_STATUS
                && (oldPayrollComponent.Approval_Status__c == WAITING_FOR_APPROVAL_STATUS || oldPayrollComponent.Approval_Status__c == WAITING_FOR_MANAGER_APPROVAL_STATUS);
    }

    public Boolean isValidPCForCreationBTForBonuses(Payroll_Component__c payrollComponent, Payroll_Component__c oldPayrollComponent) {
        return payrollComponent.Approval_Status__c == APPROVED_STATUS
                && oldPayrollComponent.Approval_Status__c == WAITING_FOR_APPROVAL_STATUS;
    }

    public Boolean isValidToSetRejectionReason(Payroll_Component__c payrollComponent, Payroll_Component__c oldPayrollComponent, String reason) {
        return payrollComponent.Approval_Status__c == REJECTED_STATUS
                && (oldPayrollComponent.Approval_Status__c == WAITING_FOR_APPROVAL_STATUS || oldPayrollComponent.Approval_Status__c == WAITING_FOR_MANAGER_APPROVAL_STATUS)
                && String.isNotBlank(reason);
    }

    public Boolean isPCRecordHasTravelRequestAndStatusIsApproved(Payroll_Component__c payrollComponent) {
        return String.isNotBlank(payrollComponent.Travel_request__c) && payrollComponent.Approval_Status__c == APPROVED_STATUS;
    }
}