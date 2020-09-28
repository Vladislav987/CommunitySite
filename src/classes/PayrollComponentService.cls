/**
 * Created by IlliaLuhovyi on 6/23/2020.
 */

public inherited sharing class PayrollComponentService {
    public void checkRecordIsReimbursable(Map<Id, Payroll_Component__c> payrollComponentsByIds) {
        String ERROR_MSG = 'You need to select a value in the "Reimbursement type" field before approve ';

        for(Payroll_Component__c payrollComponent: payrollComponentsByIds.values()) {
            if (
                    payrollComponent.RecordTypeId == PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId()
                    && payrollComponent.Approval_Status__c == PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_MANAGER_APPROVAL)
                    && String.isBlank(payrollComponent.Reimbursment__c)
            ) {
               payrollComponent.addError(ERROR_MSG + payrollComponent.Name);
            }
        }
    }

    public void handleComponentAfterUpdateForReimbursement(Map<Id, Payroll_Component__c> newPayrollComponentsByIds, Map<Id, Payroll_Component__c> oldPayrollComponentsByIds) {
        Map<Id, Payroll_Component__c> payrollComponentsWithTravelRequest = new Map<Id, Payroll_Component__c>();
        Map<Id, Payroll_Component__c> payrollComponentsWithoutTravelRequest = new Map<Id, Payroll_Component__c>();

        for(Payroll_Component__c payrollComponent: newPayrollComponentsByIds.values()) {
            if(payrollComponent.RecordTypeId == PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId()) {
                if (String.isNotBlank(payrollComponent.Travel_request__c) && payrollComponent.Approval_Status__c == PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED)) {
                    payrollComponentsWithTravelRequest.put(payrollComponent.Id, payrollComponent);
                } else {
                    payrollComponentsWithoutTravelRequest.put(payrollComponent.Id, payrollComponent);
                }
            }
        }

        if(!payrollComponentsWithTravelRequest.isEmpty()) {
            chooseEventForComponentWithTravelRequest(payrollComponentsWithTravelRequest, oldPayrollComponentsByIds);
        }

        if(!payrollComponentsWithoutTravelRequest.isEmpty()) {
            createBudgetTransactionForReimbursement(payrollComponentsWithoutTravelRequest, oldPayrollComponentsByIds);
        }
    }

    public void chooseEventForComponentWithTravelRequest(Map<Id, Payroll_Component__c> newPayrollComponentsByIds, Map<Id, Payroll_Component__c> oldPayrollComponentsByIds) {
        Set<Id> travelRequestIds = new Set<Id>();
        Map<Id, String> recordTypeMap = new Map<Id, String>();
        Map<Id, Payroll_Component__c> payrollComponentMapToCreateBudgetTransactionItem = new Map<Id, Payroll_Component__c>();
        Map<Id, Payroll_Component__c> payrollComponentMapToCreateBudgetTransaction = new Map<Id, Payroll_Component__c>();
        String reimbursableType =  PayrollComponentSelector.REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ReimbursementTypePicklistKey.REIMBURSABLE);
        String notReimbursableType = PayrollComponentSelector.REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ReimbursementTypePicklistKey.NOT_REIMBURSABLE);
        String waitingForApproval = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
        String waitingForManagerApproval = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_MANAGER_APPROVAL);

        recordTypeMap.put(BudgetTransactionSelector.RECORD_TYPE_INFO_REIMBURSABLE_EXPENSE.getRecordTypeId(), reimbursableType);
        recordTypeMap.put(BudgetTransactionSelector.RECORD_TYPE_INFO_INCLUDED_EXPENSE.getRecordTypeId(), notReimbursableType);

        for(Payroll_Component__c payrollComponent: newPayrollComponentsByIds.values()) {
            travelRequestIds.add(payrollComponent.Travel_request__c);
        }

        Map<Id, Travel_request__c> travelRequestMap = new Map<Id, Travel_request__c>([
                SELECT Budget_transaction__r.RecordTypeId, Budget_transaction__r.Id FROM Travel_request__c WHERE Id IN :travelRequestIds LIMIT 200
        ]);

        for(Payroll_Component__c payrollComponent: newPayrollComponentsByIds.values()) {
            String recordType = travelRequestMap.get(payrollComponent.Travel_request__c).Budget_transaction__r.RecordTypeId;
            String convertedRecordType = recordTypeMap.get(recordType);
            Payroll_Component__c oldPayrollComponent = oldPayrollComponentsByIds.get(payrollComponent.Id);

            if(payrollComponent.Reimbursment__c == convertedRecordType) {
                payrollComponentMapToCreateBudgetTransactionItem.put(payrollComponent.Id, payrollComponent);
            } else if (
                    payrollComponent.Reimbursment__c != convertedRecordType
                            && (payrollComponent.Reimbursment__c == reimbursableType && oldPayrollComponent.Approval_Status__c == waitingForApproval || payrollComponent.Reimbursment__c != reimbursableType && oldPayrollComponent.Approval_Status__c == waitingForManagerApproval)
                ) {
                payrollComponentMapToCreateBudgetTransaction.put(payrollComponent.Id, payrollComponent);
            }
        }

        if(!payrollComponentMapToCreateBudgetTransactionItem.isEmpty()) {
            createBudgetTransactionItemForReimbursement(payrollComponentMapToCreateBudgetTransactionItem, oldPayrollComponentsByIds);
        } else if(!payrollComponentMapToCreateBudgetTransaction.isEmpty()) {
            createBudgetTransactionForReimbursement(payrollComponentMapToCreateBudgetTransaction, oldPayrollComponentsByIds);
        }

    }

    public void moveComponentToNextApproveLevel(Map<Id, Payroll_Component__c> newPayrollComponentsByIds, Map<Id, Payroll_Component__c> oldPayrollComponentsByIds) {
        Map<Id, Id> pcIdToTravelRequestIdMap = new Map<Id, Id>();
        Map<Id, String> btRtIdToReimbursableTypeMap = new Map<Id, String>();
        Set<Id> payrollComponentSetIdsSendToApprove = new Set<Id>();
        String reimbursableType =  PayrollComponentSelector.REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ReimbursementTypePicklistKey.REIMBURSABLE);
        String notReimbursableType = PayrollComponentSelector.REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ReimbursementTypePicklistKey.NOT_REIMBURSABLE);
        String waitingForManagerApprovalStatus = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_MANAGER_APPROVAL);
        String waitingForApprovalStatus = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);

        btRtIdToReimbursableTypeMap.put(BudgetTransactionSelector.RECORD_TYPE_INFO_REIMBURSABLE_EXPENSE.getRecordTypeId(), reimbursableType);
        btRtIdToReimbursableTypeMap.put(BudgetTransactionSelector.RECORD_TYPE_INFO_INCLUDED_EXPENSE.getRecordTypeId(), notReimbursableType);

        for (Payroll_Component__c payrollComponent: newPayrollComponentsByIds.values()) {

            if (payrollComponent.Travel_request__c != null) {
                pcIdToTravelRequestIdMap.put(payrollComponent.Id, payrollComponent.Travel_request__c);
            }
        }

        Map<Id, Travel_request__c> travelRequestMap = new Map<Id, Travel_request__c>([
            SELECT
                Budget_transaction__r.RecordTypeId
            FROM Travel_request__c
            WHERE Id IN :pcIdToTravelRequestIdMap.values()
            LIMIT 200
        ]);

        for (Id pcId: pcIdToTravelRequestIdMap.keySet()) {
            Payroll_Component__c newPayrollComponent = newPayrollComponentsByIds.get(pcId);
            Travel_request__c travelRequest = travelRequestMap.get(newPayrollComponent.Travel_request__c);

            if (travelRequest.Budget_transaction__r == null) continue;

            String convertedRecordType = btRtIdToReimbursableTypeMap.get(travelRequest.Budget_transaction__r.RecordTypeId);
            Payroll_Component__c oldPayrollComponent = oldPayrollComponentsByIds.get(newPayrollComponent.Id);

            if (
                newPayrollComponent.Reimbursment__c == notReimbursableType
                    && newPayrollComponent.Approval_Status__c == waitingForManagerApprovalStatus
                    && oldPayrollComponent.Approval_Status__c == waitingForApprovalStatus
            ) {
                payrollComponentSetIdsSendToApprove.add(newPayrollComponent.Id);
            }

        }

        if (!payrollComponentSetIdsSendToApprove.isEmpty()) {
            updatePayrollComponent(payrollComponentSetIdsSendToApprove);
        }
    }

    public void updatePayrollComponent(Set<Id> payrollComponentSetIdsSendToApprove) {
        Map<Id, Payroll_Component__c> updatedPayrollComponentMap = new Map<Id, Payroll_Component__c>();

        Payroll_Component__c[] payrollComponentList = [
            SELECT
                Approval_Status__c,
                Approver__c,
                Budget_transaction__c
            FROM Payroll_Component__c
            WHERE Id IN :payrollComponentSetIdsSendToApprove
        ];

        Id approverId = getApproverId();

        for (Payroll_Component__c payrollComponent: payrollComponentList) {
            payrollComponent.Approver__c = approverId;

            updatedPayrollComponentMap.put(payrollComponent.Id, payrollComponent);
        }

        update updatedPayrollComponentMap.values();
    }

    public Id getApproverId() {
        String IDENTIFIER = 'Project Supplement';

        ApproverAssignerSettingsDAO.ApproverAssignerSettingsWrapper approverAssignerSettingsWrapper = (ApproverAssignerSettingsDAO.ApproverAssignerSettingsWrapper)CustomMetadataDAO.getSettings(ApproverAssignerSettingsDAO.class, IDENTIFIER);

        return approverAssignerSettingsWrapper.getApproverId();
    }

    public void createBudgetTransactionItemForReimbursement(Map<Id, Payroll_Component__c> newPayrollComponentsByIds, Map<Id, Payroll_Component__c> oldPayrollComponentsByIds) {
        String statusWaitingForApproval =  PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
        String statusWaitingForManagerApproval = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_MANAGER_APPROVAL);
        String statusApproved =  PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
        Budget_transaction_item__c[] budgetTransactionItems = new Budget_transaction_item__c[]{};
        Util_DatedCurrencyConverter currencyConverter = new Util_DatedCurrencyConverter();
        Set<Id> travelRequestIds = new Set<Id>();
        Map<Id, Id> budgetTransactionMap = new Map<Id, Id>();

        for(Payroll_Component__c newPayrollComponent: newPayrollComponentsByIds.values()) {
            travelRequestIds.add(newPayrollComponent.Travel_request__c);
        }

        Map<Id, Travel_request__c> travelRequestMap = new Map<Id, Travel_request__c>([
            SELECT Budget_transaction__r.CurrencyIsoCode, Budget_transaction__r.Id FROM Travel_request__c WHERE Id IN :travelRequestIds LIMIT 200
        ]);

        for(Payroll_Component__c newPayrollComponent: newPayrollComponentsByIds.values())  {
            Payroll_Component__c oldPayrollComponent = oldPayrollComponentsByIds.get(newPayrollComponent.Id);

            if (
                    isValidPCWithRTReimbursement(newPayrollComponent)
                    && newPayrollComponent.Approval_Status__c == statusApproved
                    && (oldPayrollComponent.Approval_Status__c == statusWaitingForApproval || oldPayrollComponent.Approval_Status__c == statusWaitingForManagerApproval)
            ) {
                Budget_transaction_item__c budgetTransactionItem = new Budget_transaction_item__c();
                budgetTransactionItem.Budget_transaction__c = travelRequestMap.get(newPayrollComponent.Travel_request__c).Budget_transaction__r.Id;
                budgetTransactionItem.CurrencyIsoCode = travelRequestMap.get(newPayrollComponent.Travel_request__c).Budget_transaction__r.CurrencyIsoCode;
                budgetTransactionItem.Payroll_Component__c = newPayrollComponent.Id;

                if(budgetTransactionItem.CurrencyIsoCode != newPayrollComponent.CurrencyIsoCode) {
                    Decimal convertedSum = currencyConverter.convertCurrencyToTodayRates(newPayrollComponent.Sum__c, newPayrollComponent.CurrencyIsoCode, budgetTransactionItem.CurrencyIsoCode);
                    budgetTransactionItem.Total_Amount__c = convertedSum.setScale(2, RoundingMode.HALF_UP);
                } else {
                    budgetTransactionItem.Total_Amount__c = newPayrollComponent.Sum__c;
                }

                budgetTransactionItems.add(budgetTransactionItem);

                if(newPayrollComponent.Budget_transaction__c == null) {
                    budgetTransactionMap.put(newPayrollComponent.Id, travelRequestMap.get(newPayrollComponent.Travel_request__c).Budget_transaction__r.Id);
                }
            }
        }

        insert budgetTransactionItems;

        if(!budgetTransactionMap.isEmpty()) {
            addBudgetTransactionToPayrollComponentById(budgetTransactionMap, newPayrollComponentsByIds);
        }
    }

    public void createBudgetTransactionForReimbursement(Map<Id, Payroll_Component__c> newPayrollComponentsByIds, Map<Id, Payroll_Component__c> oldPayrollComponentsByIds) {
        String statusWaitingForApproval =  PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
        String statusWaitingForManagerApproval =  PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_MANAGER_APPROVAL);
        String statusApproved =  PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
        Map<Id, Budget_transaction__c> budgetTransactionMap = new Map<Id, Budget_transaction__c>();
        Set<Id> projectIds = new Set<Id>();
        Util_DatedCurrencyConverter currencyConverter = new Util_DatedCurrencyConverter();

        for(Payroll_Component__c newPayrollComponent: newPayrollComponentsByIds.values())  {
            projectIds.add(newPayrollComponent.Project__c);
        }

        Map<Id, Project__c> projectMap = new Map<Id, Project__c>([
                SELECT Id, CurrencyIsoCode FROM Project__c WHERE Id = :projectIds
        ]);

        for(Payroll_Component__c newPayrollComponent: newPayrollComponentsByIds.values())  {
            Payroll_Component__c oldPayrollComponent = oldPayrollComponentsByIds.get(newPayrollComponent.Id);

            if (
                    isValidPCWithRTReimbursementWithoutTravelRequest(newPayrollComponent)
                    && newPayrollComponent.Approval_Status__c == statusApproved
                    && (oldPayrollComponent.Approval_Status__c == statusWaitingForApproval || oldPayrollComponent.Approval_Status__c == statusWaitingForManagerApproval)
            ) {
                String projectCurrency = projectMap.get(newPayrollComponent.Project__c).CurrencyIsoCode;

                Budget_transaction__c budgetTransaction = new Budget_transaction__c();
                budgetTransaction.Project__c = newPayrollComponent.Project__c;
                budgetTransaction.Expense_type__c = BudgetTransactionSelector.EXPENSE_TYPE_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypePicklistKey.REIMBURSEMENT);
                budgetTransaction.Expense_type_details__c = BudgetTransactionSelector.EXPENSE_TYPE_DETAILS_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypeDetailsPicklistKey.OTHER);
                budgetTransaction.RecordTypeId = BudgetTransactionSelector.RECORD_TYPE_INFO_INCLUDED_EXPENSE.getRecordTypeId();
                budgetTransaction.Comments__c = newPayrollComponent.Reason__c;

                if(projectCurrency != newPayrollComponent.CurrencyIsoCode) {
                    Decimal convertedSum = currencyConverter.convertCurrencyToTodayRates(newPayrollComponent.Sum__c, newPayrollComponent.CurrencyIsoCode, projectCurrency);
                    budgetTransaction.CurrencyIsoCode = projectCurrency;
                    budgetTransaction.Amount__c = convertedSum.setScale(2);
                } else {
                    budgetTransaction.CurrencyIsoCode = newPayrollComponent.CurrencyIsoCode;
                    budgetTransaction.Amount__c = newPayrollComponent.Sum__c;
                }


                budgetTransactionMap.put(newPayrollComponent.Id, budgetTransaction);
            }
        }

        if (!budgetTransactionMap.isEmpty()) {

            insert budgetTransactionMap.values();
            addBudgetTransactionToPayrollComponent(budgetTransactionMap, newPayrollComponentsByIds);
        }
    }

    public void addBudgetTransactionToPayrollComponentById(Map<Id, Id> budgetTransactionMap, Map<Id, Payroll_Component__c> payrollComponentMap) {
        Payroll_Component__c[] payrollComponentsList = new Payroll_Component__c[]{};
        Payroll_Component__c[] payrollComponents = [SELECT Budget_transaction__c FROM Payroll_Component__c WHERE Id IN : payrollComponentMap.keySet()];

        for(Payroll_Component__c payrollComponent: payrollComponents) {
            Id budgetTransactionId = budgetTransactionMap.get(payrollComponent.Id);

            payrollComponent.Budget_transaction__c = budgetTransactionId;

            payrollComponentsList.add(payrollComponent);
        }

        update payrollComponentsList;
    }

    public void addBudgetTransactionToPayrollComponent(Map<Id, Budget_transaction__c> budgetTransactionMap, Map<Id, Payroll_Component__c> payrollComponentMap) {
        Payroll_Component__c[] payrollComponentsList = new Payroll_Component__c[]{};
        Payroll_Component__c[] payrollComponents = [SELECT Budget_transaction__c FROM Payroll_Component__c WHERE Id IN : payrollComponentMap.keySet()];

        for(Payroll_Component__c payrollComponent: payrollComponents) {
            Budget_transaction__c budgetTransaction = budgetTransactionMap.get(payrollComponent.Id);

            payrollComponent.Budget_transaction__c = budgetTransaction.Id;

            payrollComponentsList.add(payrollComponent);
        }

        update payrollComponentsList;
    }

    public void createBudgetTransactionForBonuses(Map<Id, Payroll_Component__c> newPayrollComponentsByIds, Map<Id, Payroll_Component__c> oldPayrollComponentsByIds) {
        String statusWaitingForApproval =  PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
        String statusApproved =  PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
        Map<Id, Budget_transaction__c> budgetTransactionMap = new Map<Id, Budget_transaction__c>();


        for(Payroll_Component__c newPayrollComponent: newPayrollComponentsByIds.values())  {
            Payroll_Component__c oldPayrollComponent = oldPayrollComponentsByIds.get(newPayrollComponent.Id);

            if (
                isValidPCWithRTBonus(newPayrollComponent)
                && newPayrollComponent.Approval_Status__c == statusApproved
                && oldPayrollComponent.Approval_Status__c == statusWaitingForApproval
            ) {
                Budget_transaction__c budgetTransaction = new Budget_transaction__c();
                budgetTransaction.Project__c = newPayrollComponent.Project__c;
                budgetTransaction.Expense_type__c = BudgetTransactionSelector.EXPENSE_TYPE_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypePicklistKey.BONUS);
                budgetTransaction.Expense_type_details__c = BudgetTransactionSelector.EXPENSE_TYPE_DETAILS_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypeDetailsPicklistKey.OTHER);
                budgetTransaction.RecordTypeId = BudgetTransactionSelector.RECORD_TYPE_INFO_INCLUDED_EXPENSE.getRecordTypeId();
                budgetTransaction.Comments__c = newPayrollComponent.Reason__c;
                budgetTransaction.CurrencyIsoCode = newPayrollComponent.CurrencyIsoCode;
                budgetTransaction.Amount__c = newPayrollComponent.Sum__c;


                budgetTransactionMap.put(newPayrollComponent.Id, budgetTransaction);
            }
        }

        if (!budgetTransactionMap.isEmpty()) {

            insert budgetTransactionMap.values();
            addBudgetTransactionToPayrollComponent(budgetTransactionMap, newPayrollComponentsByIds);
        }
    }

    public void setRejectionReason(Map<Id, Payroll_Component__c> newPayrollComponentsByIds, Map<Id, Payroll_Component__c> oldPayrollComponentsByIds) {
        String statusWaitingForApproval = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
        String statusWaitingForManagerApproval = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_MANAGER_APPROVAL);
        String statusRejected = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.REJECTED);
        Map<Id, String> commentsWithIds = new Map<Id, String>();
        ProcessInstanceStep[] processInstanceSteps = [SELECT Comments, ProcessInstance.TargetObjectId FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId IN :newPayrollComponentsByIds.keySet()  LIMIT 200];

        for(ProcessInstanceStep processInstanceStep: processInstanceSteps) {
            commentsWithIds.put(processInstanceStep.ProcessInstance.TargetObjectId, processInstanceStep.Comments);
        }

        for(Payroll_Component__c newPayrollComponent: newPayrollComponentsByIds.values())  {
            Payroll_Component__c oldPayrollComponent = oldPayrollComponentsByIds.get(newPayrollComponent.Id);
            String reason = commentsWithIds.get(newPayrollComponent.Id);

            if (
                    isValidPCWithRTReimbursement(newPayrollComponent)
                    && newPayrollComponent.Approval_Status__c == statusRejected
                    && (oldPayrollComponent.Approval_Status__c == statusWaitingForApproval || oldPayrollComponent.Approval_Status__c == statusWaitingForManagerApproval)
                    && String.isNotBlank(reason)
            ) {
                newPayrollComponent.Rejection_Reason__c = reason;
            }
        }
    }

    public Boolean isValidPCWithRTReimbursement(Payroll_Component__c payrollComponent) {
        return payrollComponent.RecordTypeId == PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId()
                && payrollComponent.Travel_request__c != null
                && payrollComponent.Project__c != null;
    }

    public Boolean isValidPCWithRTReimbursementWithoutTravelRequest(Payroll_Component__c payrollComponent) {
        return payrollComponent.RecordTypeId == PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId()
                && payrollComponent.Project__c != null;
    }

    public Boolean isValidPCWithRTBonus(Payroll_Component__c payrollComponent) {
        return payrollComponent.RecordTypeId == PayrollComponentSelector.RECORD_TYPE_INFO_BONUS.getRecordTypeId()
                && payrollComponent.Travel_request__c == null
                && payrollComponent.Budget_transaction__c == null
                && payrollComponent.Project__c != null
                && payrollComponent.Contractor__c != null
                && payrollComponent.Account__c != null;
    }
}