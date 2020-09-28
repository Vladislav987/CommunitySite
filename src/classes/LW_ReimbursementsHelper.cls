/**
 * Created by IlliaLuhovyi on 8/3/2020.
 */

public inherited sharing class LW_ReimbursementsHelper {

    private static LW_ReimbursementsService service = new LW_ReimbursementsService();

    public LW_ReimbursementsService.ProjectWrapper[] getContractorProjects(Boolean status) {
        Id contractorId = service.getContractorId();

        Map<Id, Project__c> contractorProjects = service.getProjects(contractorId);
        Map<Id, Travel_request__c> contractorBudgeTravelRequestsByIds = service.getTravelRequests(contractorId, contractorProjects);
        Map<Id, Payroll_Component__c> payrollComponentMap = service.getPayrollComponentsInProject(contractorBudgeTravelRequestsByIds);

        return service.createMainWrapper(contractorProjects, contractorBudgeTravelRequestsByIds, payrollComponentMap, status);
    }

    public LW_ReimbursementsService.PayrollComponentWrapper[] setPayrollComponent(String payrollDataStrJson, String travelRequestId, String projectId, String fileData) {
        LW_ReimbursementsService.FilesWrapper[] filesWrapperArray = (LW_ReimbursementsService.FilesWrapper[]) JSON.deserialize(fileData, LW_ReimbursementsService.FilesWrapper[].class);
        LW_ReimbursementsService.PayrollComponentWrapper[] payrollComponentWrapperArray = new LW_ReimbursementsService.PayrollComponentWrapper[]{};
        String contractorCurrCode = service.getContractorCurrCode(projectId);
        Decimal totalSum = 0;

        Payroll_Component__c payrollComponent = service.createPayrollComponent(projectId, travelRequestId, contractorCurrCode, totalSum);
        service.saveFiles(payrollComponent.Id, filesWrapperArray);
        service.createPayrollComponentItem(payrollComponent, payrollDataStrJson, totalSum, contractorCurrCode);
        service.sendToApproval(payrollComponent.Id);

        User projectManager = service.getProjectManager(payrollComponent.Approver__c);

        LW_ReimbursementsService.PayrollComponentWrapper payroll = new LW_ReimbursementsService.PayrollComponentWrapper();
        payroll.Id = payrollComponent.Id;
        payroll.Name = payrollComponent.Name;
        payroll.TravelId = payrollComponent.Travel_request__c;
        payroll.Sum = payrollComponent.Sum__c;
        payroll.CurrencyCode = payrollComponent.CurrencyIsoCode;
        payroll.Status = payrollComponent.Approval_Status__c;
        payroll.projectId = payrollComponent.Project__c;
        payroll.projectManager = projectManager.FirstName + ' ' + projectManager.LastName;
        payroll.isEditable = true;

        payrollComponentWrapperArray.add(payroll);

        return payrollComponentWrapperArray;
    }

    public LW_ReimbursementsService.CurrencyConfig[] getCurrencyTypes() {
        CurrencyType[] currencyTypes = service.getCurrencyTypes();

        return service.createCurrencyConfig(currencyTypes);
    }

    public LW_ReimbursementsService.PayrollComponentWrapper getPayrollComponentWithFilesAndItems(Id payrollComponentId) {
        Payroll_Component__c[] payrollComponents = new PayrollComponentSelector().getComponentById(payrollComponentId);
        Payroll_Component__c payrollComponent;

        if (!payrollComponents.isEmpty()) {
            payrollComponent = payrollComponents[0];
        }

        LW_ReimbursementsService.PayrollComponentWrapper payrollComponentWrapper = new LW_ReimbursementsService.PayrollComponentWrapper();

        payrollComponentWrapper.Id = payrollComponent.Id;
        payrollComponentWrapper.Sum = payrollComponent.Sum__c;
        payrollComponentWrapper.CurrencyCode = payrollComponent.CurrencyIsoCode;

        payrollComponentWrapper.payrollComponentItemInfo = service.getPayrollComponentItems(payrollComponentId);
        payrollComponentWrapper.filesWrappers = service.getPayrollComponentAttachments(payrollComponentId);

        return payrollComponentWrapper;
    }

    public LW_ReimbursementsService.PayrollComponentWrapper updatePayrollComponent(Id payrollComponentId, Id projectId, String payrollComponentJson) {
        service.editPayrollComponentItems(payrollComponentJson);
        service.updateFiles(payrollComponentJson);

        Payroll_Component_Item__c[] payrollComponentItems = new PayrollComponentItemSelector().getByPayrollComponentId(payrollComponentId);
        Payroll_Component__c[] payrollComponents = new PayrollComponentSelector().getComponentById(payrollComponentId);
        Payroll_Component__c payrollComponent;

        if (!payrollComponents.isEmpty()) {
            payrollComponent = payrollComponents[0];
        }

        String contractorCurrCode = service.getContractorCurrCode(projectId);
        Id approverId = service.getProjectManagerIdByProjectId(projectId);
        User approver = service.getProjectManager(approverId);

        Util_DatedCurrencyConverter currencyConverter = new Util_DatedCurrencyConverter();

        Decimal totalSum = 0;
        String oldStatus = payrollComponent.Approval_Status__c;

        for (Payroll_Component_Item__c payrollComponentItem: payrollComponentItems) {
            if (payrollComponentItem.CurrencyIsoCode != contractorCurrCode) {
                Decimal convertedSum = currencyConverter.convertCurrencyToTodayRates(payrollComponentItem.Sum__c, payrollComponentItem.CurrencyIsoCode, contractorCurrCode);
                totalSum = totalSum + convertedSum.setScale(2);
            }
            else {
                totalSum = totalSum + payrollComponentItem.Sum__c;
            }
        }

        payrollComponent.Sum__c = totalSum;

        if (oldStatus == PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.REJECTED)) {
            payrollComponent.Reimbursment__c = null;
        }

        payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
        payrollComponent.Approver__c = approverId;
        payrollComponent.Rejection_Reason__c = '';

        update payrollComponent;

        if (oldStatus == PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.REJECTED)) {
            service.sendToApproval(payrollComponent.Id);
        }

        LW_ReimbursementsService.PayrollComponentWrapper payrollComponentWrapper = new LW_ReimbursementsService.PayrollComponentWrapper();
        payrollComponentWrapper.Sum = payrollComponent.Sum__c;
        payrollComponentWrapper.TravelId = payrollComponent.Travel_request__c;
        payrollComponentWrapper.projectId = payrollComponent.Project__c;
        payrollComponentWrapper.Status = payrollComponent.Approval_Status__c;
        payrollComponentWrapper.CurrencyCode = contractorCurrCode;
        payrollComponentWrapper.projectManager = approver.FirstName + ' ' + approver.LastName;
        payrollComponentWrapper.Id = payrollComponent.Id;
        payrollComponentWrapper.rejectionReason = '';

        return payrollComponentWrapper;
    }
}