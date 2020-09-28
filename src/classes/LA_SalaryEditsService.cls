/**
 * Created by Lambru Dmytro on 06.04.2020.
 * NOTE: "LA_" - Lightning Aura.
 */

public inherited sharing class LA_SalaryEditsService {

    public Date START_DATE;

    {
        Date dateNow = Date.valueOf(System.now());
        Decimal compensationDay = getCompensationDay();

        START_DATE = (dateNow.day() < compensationDay) ? dateNow.toStartOfMonth() : dateNow.toStartOfMonth().addMonths(1);
    }

    /**
    * @description Forms a list with options for dropdown with months.
    *
    * @return List with options.
    */
    public Model.PicklistOption[] createMonthOptions() {
        Model.PicklistOption[] optionList = new Model.PicklistOption[]{};
        Integer currentMonthNumber = System.today().month();

        for (Integer monthNumber = 1; monthNumber <= 12; monthNumber++) {
            Model.PicklistOption option = new Model.PicklistOption();

            option.optionLabel = Util.getFullMonthLabelByMonthNumberForCurrentLanguage(monthNumber);
            option.optionApiName = String.valueOf(monthNumber);
            option.isSelected = (monthNumber == currentMonthNumber);

            optionList.add(option);
        }

        return optionList;
    }

    /**
    * @description Forms a list with options for dropdown with years.
    *
    * @return List with options.
    */
    public Model.PicklistOption[] createYearOptions() {
        Integer currentYear = System.today().year();

        Model.PicklistOption[] optionList = new Model.PicklistOption[]{};

        for (Integer year = currentYear, lowerLimitYear = (currentYear - 10); year > lowerLimitYear; year--) {
            Model.PicklistOption option = new Model.PicklistOption();

            option.optionLabel = String.valueOf(year);
            option.optionApiName = String.valueOf(year);
            option.isSelected = (year == currentYear);

            optionList.add(option);
        }

        return optionList;
    }

    /**
    * @description Forms a list with options for dropdown with currency ISO codes.
    *
    * @return List with options.
    */
    public Model.PicklistOption[] createCurrencyOptions() {
        CurrencyType[] currencyTypeList = [SELECT IsoCode FROM CurrencyType WHERE IsActive = TRUE];

        Model.PicklistOption[] optionList = new Model.PicklistOption[]{};

        for (CurrencyType currencyType : currencyTypeList) {
            Model.PicklistOption option = new Model.PicklistOption();

            option.optionLabel = currencyType.IsoCode;
            option.optionApiName = currencyType.IsoCode;

            optionList.add(option);
        }

        return optionList;
    }

    /**
    * @description Forms a list with options for dropdown with Travel Requests.
    *
    * @return List with options.
    */
    public Model.PicklistOption[] createTravelRequestOptions(Travel_request__c[] travelRequestList) {

        Model.PicklistOption[] optionList = new Model.PicklistOption[]{};

        for (Travel_request__c travelRequest : travelRequestList) {
            Model.PicklistOption option = new Model.PicklistOption();

            option.optionApiName = travelRequest.Id;
            option.optionLabel = (String.isNotBlank(travelRequest.Country__c) && travelRequest.Start_Date__c != null)
                    ? travelRequest.Country__c + ' ' + travelRequest.Start_Date__c.format()
                    : travelRequest.Name;

            optionList.add(option);
        }

        return optionList;
    }


    /**
    * @description Map formation with Contractor ID to the contractor data based on project allocations.
    *
    * @param allocationList List with project allocations.
    * @param projectId Id of project.
    *
    * @return Map with value: Contractor ID | key: Contractor data
    */
    public Map<Id, ContractorInfo> createMapWithContractorIdToInfo(Allocation__c[] allocationList) {
        Map<Id, ContractorInfo> contractorIdToInfoMap = new Map<Id, ContractorInfo>();

        if ( !allocationList.isEmpty() ) {

            for (Allocation__c allocation : allocationList) {

                if (!contractorIdToInfoMap.containsKey(allocation.Contractor__c)) {
                    ContractorInfo contractorInfo = new ContractorInfo();

                    contractorInfo.contractorId = allocation.Contractor__c;
                    contractorInfo.contractorName = allocation.Contractor__r.Name;
                    contractorInfo.currencyType = allocation.CurrencyIsoCode;

                    contractorIdToInfoMap.put(contractorInfo.contractorId, contractorInfo);
                }
            }
        }

        return contractorIdToInfoMap;
    }

    public Map<Id, ContractorInfo> mapContractorIdToInfoForReimbursements(Allocation__c[] allocationList, Id projectId) {
        Map<Id, ContractorInfo> contractorIdToInfoMap = new Map<Id, ContractorInfo>();
        Id reimbursableRTId = BudgetTransactionSelector.RECORD_TYPE_INFO_REIMBURSABLE_EXPENSE.getRecordTypeId();

        if ( !allocationList.isEmpty() ) {

            for (Allocation__c allocation : allocationList) {

                if (!contractorIdToInfoMap.containsKey(allocation.Contractor__c)) {
                    ContractorInfo contractorInfo = new ContractorInfo();

                    contractorInfo.contractorId = allocation.Contractor__c;
                    contractorInfo.contractorName = allocation.Contractor__r.Name;
                    contractorInfo.currencyType = allocation.CurrencyIsoCode;

                    contractorIdToInfoMap.put(contractorInfo.contractorId, contractorInfo);
                }
            }

            Travel_request__c[] travelRequests = new TravelRequestSelector().getByContractorIdsAndProjectId(contractorIdToInfoMap.keySet(), projectId);

            for (Travel_request__c travelRequest : travelRequests) {
                ContractorInfo contractorInfo = contractorIdToInfoMap.get(travelRequest.Contractor_Name__c);
                contractorInfo.travelRequestsInfos.add(new TravelRequestsInfo(travelRequest, reimbursableRTId));
            }
        }

        return contractorIdToInfoMap;
    }

    /**
    * @description Map formation with Contractor ID to the Contractor person account.
    *
    * @param contractorPersonAccountList List with Contractor's person accounts
    *
    * @return Map with value: Contractor ID | key: Contractor's person account
    */
    public Map<Id, Account> createMapWithContractorIdToPersonAccount(Account[] contractorPersonAccountList) {
        Map<Id, Account> contractorIdToPersonAccountMap = new Map<Id, Account>();

        for (Account contractorPersonAccount : contractorPersonAccountList) {
            contractorIdToPersonAccountMap.put(contractorPersonAccount.Contractor__c, contractorPersonAccount);
        }

        return contractorIdToPersonAccountMap;
    }

    /**
    * @description Deletes Contractors who do not have the person account.
    *
    * @param contractorIdToInfoMap Map with Contractor ID to the contractor data.
    * @param contractorIdWithPersonAccountSet Set with the IDs who have a person account.
    */
    public void removeContractorsWithoutPersonAccount(Map<Id, ContractorInfo> contractorIdToInfoMap, Set<Id> contractorIdWithPersonAccountSet) {

        for (Id contractorId : contractorIdToInfoMap.keySet()) {

            if (!contractorIdWithPersonAccountSet.contains(contractorId)) {
                contractorIdToInfoMap.remove(contractorId);
            }
        }
    }

    /**
    * @description Creates a “Budget_transaction” record for each list item based on the Contractor’s data.
    *
    * @param projectId ID of Project record.
    * @param contractorInfoList List with Contractor data.
    *
    * @return Map with key: Budget_transaction ID | value: Budget_transaction record
    */
    public Map<Id, Budget_transaction__c> createBudgetTransactionForContractors(Id projectId, LA_SalaryEditsService.ContractorInfo[] contractorInfoList) {
        Map<Id, Budget_transaction__c> contractorIdToBudgetTransactionMap = new Map<Id, Budget_transaction__c>();

        for (ContractorInfo contractorInfo : contractorInfoList) {
            if(contractorInfo.isIncludedToInvoice) {
                Budget_transaction__c budgetTransaction = new Budget_transaction__c();

                budgetTransaction.Project__c = projectId;
                budgetTransaction.Expense_type__c = BudgetTransactionSelector.EXPENSE_TYPE_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypePicklistKey.BONUS);
                budgetTransaction.Expense_type_details__c = BudgetTransactionSelector.EXPENSE_TYPE_DETAILS_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypeDetailsPicklistKey.OTHER);
                budgetTransaction.RecordTypeId = BudgetTransactionSelector.RECORD_TYPE_INFO_REIMBURSABLE_EXPENSE.getRecordTypeId();
                budgetTransaction.Comments__c = contractorInfo.reasonDescription;
                budgetTransaction.CurrencyIsoCode = contractorInfo.currencyType;
                budgetTransaction.Amount__c = contractorInfo.currencyAmount;

                contractorIdToBudgetTransactionMap.put(contractorInfo.contractorId, budgetTransaction);
            }
        }

        insert contractorIdToBudgetTransactionMap.values();

        return contractorIdToBudgetTransactionMap;
    }

    /**
    * @description Creates a “Payroll_Component” records based on Contractor's data,
    *              previously created record of "Budget_transaction" and Contractor's person account.
    *
    * @param projectId ID of Project record.
    * @param contractorInfoList List with Contractor data.
    * @param contractorIdToBudgetTransactionMap Map with "Budget_transaction" ID to record.
    * @param contractorIdToPersonAccountMap Map with contractor ID to Contractor person account.
     *
     * @return List of inserted Payroll_Component__c.
    */
    public Payroll_Component__c[] createPayrollComponentsWithRTBonus(Id projectId,
            ContractorInfo[] contractorInfoList,
            Map<Id, Budget_transaction__c> contractorIdToBudgetTransactionMap,
            Map<Id, Account> contractorIdToPersonAccountMap) {

        Payroll_Component__c[] payrollComponentList = new Payroll_Component__c[]{};
        Id approverId = getApproverId();

        for (ContractorInfo contractorInfo : contractorInfoList) {
            Payroll_Component__c payrollComponent = new Payroll_Component__c();

            payrollComponent.RecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_BONUS.getRecordTypeId();
            payrollComponent.Project__c = projectId;
            payrollComponent.Contractor__c = contractorInfo.contractorId;
            payrollComponent.Account__c = contractorIdToPersonAccountMap.get(contractorInfo.contractorId).Id;
            payrollComponent.Reason__c = contractorInfo.reasonDescription;
            payrollComponent.CurrencyIsoCode = contractorInfo.currencyType;
            payrollComponent.SumType__c = PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.SumTypePicklistKey.INCREMENT);
            payrollComponent.Sum__c = contractorInfo.currencyAmount;
            payrollComponent.StartDate__c = START_DATE;
            payrollComponent.EndDate__c = START_DATE;

            if(contractorInfo.isIncludedToInvoice) {
                payrollComponent.Budget_transaction__c = contractorIdToBudgetTransactionMap.get(contractorInfo.contractorId).Id;
                payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
                payrollComponent.Reimbursment__c = PayrollComponentSelector.REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ReimbursementTypePicklistKey.REIMBURSABLE);

            } else {
                payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
                payrollComponent.Approver__c = approverId;
                payrollComponent.Reimbursment__c = PayrollComponentSelector.REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ReimbursementTypePicklistKey.NOT_REIMBURSABLE);

            }

            payrollComponentList.add(payrollComponent);
        }

        insert payrollComponentList;

        return payrollComponentList;
    }

    public Id createBudgetTransactionForReimbursement(Id projectId, PayrollComponentInfo payrollComponentList) {
        Budget_transaction__c budgetTransaction = new Budget_transaction__c();
        String projectCurrency = [SELECT Id, CurrencyIsoCode FROM Project__c WHERE Id = :projectId].CurrencyIsoCode;

        budgetTransaction.Project__c = projectId;
        budgetTransaction.RecordTypeId = BudgetTransactionSelector.RECORD_TYPE_INFO_REIMBURSABLE_EXPENSE.getRecordTypeId();
        budgetTransaction.Expense_type__c = BudgetTransactionSelector.EXPENSE_TYPE_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypePicklistKey.REIMBURSEMENT);
        budgetTransaction.Expense_type_details__c = BudgetTransactionSelector.EXPENSE_TYPE_DETAILS_PICKLIST_VALUES_MAP.get(BudgetTransactionSelector.ExpenseTypeDetailsPicklistKey.OTHER);
        budgetTransaction.Comments__c = payrollComponentList.reason;

        if(projectCurrency != payrollComponentList.currencyIsoCode) {
            Util_DatedCurrencyConverter currencyConverter = new Util_DatedCurrencyConverter();
            Decimal convertedSum = currencyConverter.convertCurrencyToTodayRates(payrollComponentList.amount, payrollComponentList.currencyIsoCode, projectCurrency);
            budgetTransaction.CurrencyIsoCode = projectCurrency;
            budgetTransaction.Amount__c = convertedSum.setScale(2);
        } else {
            budgetTransaction.CurrencyIsoCode = payrollComponentList.currencyIsoCode;
            budgetTransaction.Amount__c = payrollComponentList.amount;
        }

        insert budgetTransaction;

        return budgetTransaction.Id;
    }

    public Id createBudgetTransactionItemForReimbursement(PayrollComponentInfo payrollComponent) {
        Budget_transaction_item__c budgetTransactionItem = new Budget_transaction_item__c();
        budgetTransactionItem.Budget_transaction__c = payrollComponent.budgetTransactionId;
        budgetTransactionItem.CurrencyIsoCode = [SELECT CurrencyIsoCode FROM Budget_transaction__c WHERE Id = :payrollComponent.budgetTransactionId LIMIT 1].CurrencyIsoCode;

        if(budgetTransactionItem.CurrencyIsoCode != payrollComponent.currencyIsoCode) {
            Util_DatedCurrencyConverter currencyConverter = new Util_DatedCurrencyConverter();
            Decimal convertedSum = currencyConverter.convertCurrencyToTodayRates(payrollComponent.amount, payrollComponent.currencyIsoCode, budgetTransactionItem.CurrencyIsoCode);
            budgetTransactionItem.Total_Amount__c = convertedSum.setScale(2);
        } else {
            budgetTransactionItem.Total_Amount__c = payrollComponent.amount;
        }

        insert budgetTransactionItem;

        return budgetTransactionItem.Id;
    }

    public Payroll_Component__c createPayrollComponent(Id projectId, PayrollComponentInfo payrollComponentList, Id budgetTransactionId) {
        Payroll_Component__c payrollComponent = new Payroll_Component__c();

        payrollComponent.RecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId();
        payrollComponent.Project__c = projectId;
        payrollComponent.Contractor__c = payrollComponentList.contractorId;
        Set<Id> accIds = new Set<Id>{payrollComponentList.contractorId};
        Account[] accounts = new AccountSelector().getActualPersonAccountsByContractorIds(accIds);
        payrollComponent.Account__c = accounts[0].Id;

        if(String.isNotBlank(budgetTransactionId)) {
            payrollComponent.Budget_transaction__c = budgetTransactionId;
        }

        payrollComponent.CurrencyIsoCode = payrollComponentList.currencyIsoCode;
        payrollComponent.SumType__c = PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.SumTypePicklistKey.INCREMENT);
        payrollComponent.Sum__c = payrollComponentList.amount;
        payrollComponent.Reason__c = payrollComponentList.reason;
        payrollComponent.StartDate__c = START_DATE;
        payrollComponent.EndDate__c = START_DATE;
        payrollComponent.Travel_request__c = payrollComponentList.travel;

        if(payrollComponentList.invoice) {
            payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
            payrollComponent.Reimbursment__c = PayrollComponentSelector.REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ReimbursementTypePicklistKey.REIMBURSABLE);
        } else {
            payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
            payrollComponent.Approver__c = getApproverId();
            payrollComponent.Reimbursment__c = PayrollComponentSelector.REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ReimbursementTypePicklistKey.NOT_REIMBURSABLE);
        }

        insert payrollComponent;

        return payrollComponent;
    }

    public void updateBudgetTransactionItemForReimbursement(Id budgetTransactionItemId, Id payrollComponentId) {
        if(String.isNotEmpty(budgetTransactionItemId)) {
            Budget_transaction_item__c budgetTransactionItem = [SELECT Payroll_Component__c FROM Budget_transaction_item__c WHERE Id = :budgetTransactionItemId LIMIT 1];

            budgetTransactionItem.Payroll_Component__c = payrollComponentId;

            update budgetTransactionItem;
        }
    }

    public void createPayrollComponentItem(Id payrollComponentId, PayrollComponentItemInfo[] payrollComponentItemList) {
        List<Payroll_Component_Item__c> payrollComponentItemsList = new List<Payroll_Component_Item__c>();

        for(PayrollComponentItemInfo payrollItem: payrollComponentItemList) {
            Payroll_Component_Item__c payrollComponentItem = new Payroll_Component_Item__c();

            payrollComponentItem.Sum__c = payrollItem.amount;
            payrollComponentItem.CurrencyIsoCode = payrollItem.currencyIsoCode;
            payrollComponentItem.Comment__c = payrollItem.comment;
            payrollComponentItem.Payroll_Component__c = payrollComponentId;

            payrollComponentItemsList.add(payrollComponentItem);

        }

        insert payrollComponentItemsList;
    }

    public void createAttachmentsForPayrollComponent(Id payrollComponentId, AttachmentsInfo[] filesList) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();

        for(AttachmentsInfo file: filesList) {
            file.fileData = EncodingUtil.urlDecode(file.fileData, 'UTF-8');

            ContentVersion cv = new ContentVersion();
            cv.Title = file.fileName;
            cv.PathOnClient = '/' + file.fileName;
            cv.VersionData = EncodingUtil.base64Decode(file.fileData);

            contentVersions.add(cv);
        }

        insert contentVersions;

        Map<Id, ContentVersion> contentVersionIdToRecord = new Map<Id, ContentVersion>([SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions]);

        for(ContentVersion cv: contentVersions) {
            Id contentDocumentId = contentVersionIdToRecord.get(cv.Id).ContentDocumentId;
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
                    ContentDocumentId = contentDocumentId, LinkedEntityId = payrollComponentId, ShareType = 'I', Visibility = 'AllUsers'
            );

            contentDocumentLinks.add(contentDocumentLink);
        }

        insert contentDocumentLinks;

    }

    public void sendToApproval(Set<Id> objectIds) {
        String APPROVAL_PROCESS = 'Reimbursement_Approval_Process';

        Approval.ProcessSubmitRequest[] processSubmitRequestList = new Approval.ProcessSubmitRequest[]{};
        Approval.ProcessSubmitRequest processSubmitRequest = new Approval.ProcessSubmitRequest();

        for(Id objectId: objectIds) {
            processSubmitRequest.setObjectId(objectId);
            processSubmitRequest.setProcessDefinitionNameOrId(APPROVAL_PROCESS);
            processSubmitRequestList.add(processSubmitRequest);
        }

        Approval.process(processSubmitRequestList);
    }

    public void sendToApprovePayrollComponentWithRTBonus(Payroll_Component__c[] payrollComponentList) {
        Set<Id> payrollComponentIdsToApprove = new Set<Id>();

        for(Payroll_Component__c payrollComponentToApprove: payrollComponentList) {
            if(payrollComponentToApprove.Approval_Status__c == PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL)) {
                payrollComponentIdsToApprove.add(payrollComponentToApprove.Id);
            }
        }

        if(!payrollComponentIdsToApprove.isEmpty()) {
            sendToApproval(payrollComponentIdsToApprove);
        }
    }

    public Decimal getCompensationDay() {
        Decimal day = 20; // by default
        PayrollDateRulesService.PayrollBlockingDaysInfo payrollBlockingDaysInfo = new PayrollDateRulesService().getBlockingDaysInfoByUserAndUserRoleIds(
            UserInfo.getUserId(),
            UserInfo.getUserRoleId()
        );

        // leave the default if no setting is assigned to the current user
        if ( !payrollBlockingDaysInfo.isAvailable() || payrollBlockingDaysInfo.getProjectCompensationDay() == null) return day;

        return payrollBlockingDaysInfo.getProjectCompensationDay();
    }

    public Id getApproverId() {
        String IDENTIFIER = 'Project Supplement';

        ApproverAssignerSettingsDAO.ApproverAssignerSettingsWrapper approverAssignerSettingsWrapper = (ApproverAssignerSettingsDAO.ApproverAssignerSettingsWrapper)CustomMetadataDAO.getSettings(ApproverAssignerSettingsDAO.class, IDENTIFIER);

        return approverAssignerSettingsWrapper.getApproverId();
    }

    /**
     * @description Class to keep settings for the component.
     */
    public class ComponentConfig {

        public Model.PicklistOption[] monthDropdownOptionList { get; set; }
        public Model.PicklistOption[] yearDropdownOptionList { get; set; }
        public Model.PicklistOption[] currencyDropdownOptionList { get; set; }
    }

    /**
     * @description Class to keep settings for the Travel Request.
     */
    public class TravelRequestConfig {
        public Model.PicklistOption[] travelRequestDropdownOptionList { get; set; }
    }

    /**
     * @description Class for storing Contractor information and user input from the Aura component.
     */
    public class ContractorInfo {

        public Id contractorId { get; set; }
        public String contractorName { get; set; }
        public String currencyType { get; set; }
        public Decimal currencyAmount { get; set; }
        public String reasonDescription { get; set; }
        public Boolean isSelected { get; set; }
        public Boolean isIncludedToInvoice { get; set; }
        public TravelRequestsInfo[] travelRequestsInfos = new TravelRequestsInfo[]{};

        {
            this.isSelected = false;
            this.isIncludedToInvoice = false;
        }
    }

    /**
     * @description Class for storing data of "Payroll_Component".
     */
    public class PayrollComponentInfo {

        public Id contractorId { get; set; }
        public Id travel { get; set; }
        public Id budgetTransactionId { get; set; }
        public String contractorName { get; set; }
        public Decimal amount { get; set; }
        public String currencyIsoCode { get; set; }
        public String reason { get; set; }
        public Boolean invoice { get; set; }
    }

    /**
   * @description Class for storing data of "Payroll_Component_item".
   */
    public class PayrollComponentItemInfo {

        public Decimal amount { get; set; }
        public String currencyIsoCode { get; set; }
        public String comment { get; set; }
    }

    /**
    * @description Class for storing data of "Payroll_Component" Attachments.
    */
    public class AttachmentsInfo {

        public String fileName { get; set; }
        public String fileData { get; set; }
    }

    public class TravelRequestsInfo {
        public Id travelId { get; set; }
        public String budgetTransactionRecordType { get; set; }
        public Id budgetTransactionId { get; set; }
        public Boolean isReimbursable { get; set; }
        public TravelRequestsInfo(Travel_request__c travelRequest, Id reimbursableRTId) {
            this.travelId = travelRequest.Id;
            this.budgetTransactionId = travelRequest.Budget_transaction__r.Id;
            this.budgetTransactionRecordType = travelRequest.Budget_transaction__r.RecordType.Name;
            this.isReimbursable = travelRequest.Budget_transaction__r.RecordTypeId == reimbursableRTId;
        }
    }
}