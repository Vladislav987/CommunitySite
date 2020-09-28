/**
 * Created by Lambru Dmytro on 06.04.2020.
 * NOTE: "LA_" - Lightning Aura.
 */

public inherited sharing class LA_SalaryEditsHelper {

    private static LA_SalaryEditsService service = new LA_SalaryEditsService();

    /**
     * @description Forms an object with settings for the component.
     *
     * @return Object with settings.
     */
    public LA_SalaryEditsService.ComponentConfig generateComponentConfigForBonuses() {
        LA_SalaryEditsService.ComponentConfig componentConfig = new LA_SalaryEditsService.ComponentConfig();

        componentConfig.monthDropdownOptionList = service.createMonthOptions();
        componentConfig.yearDropdownOptionList = service.createYearOptions();
        componentConfig.currencyDropdownOptionList = service.createCurrencyOptions();

        return componentConfig;
    }


    /**
     * @description Travel Request info selected by Ids.
     *
     * @param contractorId ID of Contractor.
     * @param projectId ID of Project.
     *
     * @return Object with settings.
     */
    public LA_SalaryEditsService.TravelRequestConfig getTravelRequestsById(String contractorId, String projectId) {

        LA_SalaryEditsService.TravelRequestConfig travelRequestConfig = new LA_SalaryEditsService.TravelRequestConfig();
        Travel_request__c[] travelRequestList = new TravelRequestSelector().getByContractorIdAndProjectId(contractorId, projectId);

        travelRequestConfig.travelRequestDropdownOptionList = service.createTravelRequestOptions(travelRequestList);

        return travelRequestConfig;
    }

    /**
     * @description Is the current user the owner of the record or not?
     *
     * @param projectId ID of Project record.
     * @return Check result.
     */
    public Boolean isCurrentUserProjectOwner(String projectId) {
        Project__c project = [SELECT OwnerId FROM Project__c WHERE Id = :projectId LIMIT 1];

        return UserInfo.getUserId() == project.OwnerId;
    }

    /**
     * @description Forms a list based on project allocations with Contractor's data.
     *
     * @param projectId ID of Project record.
     * @param monthNumber Order number of the month.
     * @param year Year.
     *
     * @return List with Contractors data.
     */
    public LA_SalaryEditsService.ContractorInfo[] getContractorsForPeriod(String projectId, Integer monthNumber, Integer year) {
        Map<Id, LA_SalaryEditsService.ContractorInfo> contractorIdToInfoMap = new Map<Id, LA_SalaryEditsService.ContractorInfo>();
        Date startDateWithLastDayInMonth = Date.newInstance(year, monthNumber, Date.daysInMonth(year, monthNumber));

        Allocation__c[] allocationList = new AllocationSelector().getContractorInfoWithRTProjectByProjectIdAndStartDateBelow(projectId, startDateWithLastDayInMonth);

        if (!allocationList.isEmpty()) {
            contractorIdToInfoMap = service.createMapWithContractorIdToInfo(allocationList);
            Account[] contractorPersonAccountList = new AccountSelector().getActualPersonAccountsByContractorIds(contractorIdToInfoMap.keySet());
            Map<Id, Account> contractorIdToPersonAccountMap = service.createMapWithContractorIdToPersonAccount(contractorPersonAccountList);
            service.removeContractorsWithoutPersonAccount(contractorIdToInfoMap, contractorIdToPersonAccountMap.keySet());
        }

        return contractorIdToInfoMap.values();
    }

    /**
     * @description Forms a list based on project allocations with Contractor's data.
     *
     * @param projectId ID of Project record.
     * @param monthNumber Order number of the month.
     * @param year Year.
     *
     * @return List with Contractors data.
     */
    public LA_SalaryEditsService.ContractorInfo[] getContractorsForPeriodForReimbursement(String projectId, Integer monthNumber, Integer year) {
        Map<Id, LA_SalaryEditsService.ContractorInfo> contractorIdToInfoMap = new Map<Id, LA_SalaryEditsService.ContractorInfo>();
        Date startDateWithLastDayInMonth = Date.newInstance(year, monthNumber, Date.daysInMonth(year, monthNumber));

        Allocation__c[] allocationList = new AllocationSelector().getContractorInfoWithRTProjectByProjectIdAndStartDateBelow(projectId, startDateWithLastDayInMonth);

        if (!allocationList.isEmpty()) {
            contractorIdToInfoMap = service.mapContractorIdToInfoForReimbursements(allocationList, projectId);
            Account[] contractorPersonAccountList = new AccountSelector().getActualPersonAccountsByContractorIds(contractorIdToInfoMap.keySet());
            Map<Id, Account> contractorIdToPersonAccountMap = service.createMapWithContractorIdToPersonAccount(contractorPersonAccountList);
            service.removeContractorsWithoutPersonAccount(contractorIdToInfoMap, contractorIdToPersonAccountMap.keySet());
        }

        return contractorIdToInfoMap.values();
    }

    /**
     * @description Creates 1 "Budget_transaction" record and 1 "Payroll_Component" record based on user input.
     *
     * @param projectId ID of Project record.
     * @param contractorInfoList Modified list by user with Contractor's data.
     */
    public void generateBonusesForContractors(Id projectId, LA_SalaryEditsService.ContractorInfo[] contractorInfoList) {

        if (!contractorInfoList.isEmpty()) {
            Set<Id> contractorsIds = new Set<Id>();

            for(LA_SalaryEditsService.ContractorInfo contractorInfo: contractorInfoList) {
                contractorsIds.add(contractorInfo.contractorId);
            }

            Map<Id, Budget_transaction__c> contractorIdToBudgetTransactionMap = service.createBudgetTransactionForContractors(projectId, contractorInfoList);
            Account[] contractorPersonAccountList = new AccountSelector().getActualPersonAccountsByContractorIds(contractorsIds);
            Map<Id, Account> contractorIdToPersonAccountMap = service.createMapWithContractorIdToPersonAccount(contractorPersonAccountList);
            Payroll_Component__c[] payrollComponents = service.createPayrollComponentsWithRTBonus(projectId, contractorInfoList, contractorIdToBudgetTransactionMap, contractorIdToPersonAccountMap);
            service.sendToApprovePayrollComponentWithRTBonus(payrollComponents);
        }
    }

    /**
     * @description Creates 1 "Budget_transaction" record , 1 "Payroll_Component" record and several "Payroll_Component_item" records based on user input.
     *
     * @param projectId ID of Project record.
     * @param payrollComponent Modified data for Payroll_Component.
     * @param payrollComponentItemList Modified list of data for Payroll_Component_item.
     * @param fileList Modified list of files data for Payroll_Component Attachments.
     */
    public void generateReimbursementForContractors(Id projectId, LA_SalaryEditsService.PayrollComponentInfo payrollComponent, LA_SalaryEditsService.PayrollComponentItemInfo[] payrollComponentItemList, LA_SalaryEditsService.AttachmentsInfo[] fileList) {
        Id budgetTransactionId;
        Id budgetTransactionItemId;

        if(String.isNotBlank(payrollComponent.travel) && payrollComponent.invoice) {
            budgetTransactionId = payrollComponent.budgetTransactionId;
            budgetTransactionItemId = service.createBudgetTransactionItemForReimbursement(payrollComponent);
        } else if(String.isBlank(payrollComponent.travel) && payrollComponent.invoice) {
            budgetTransactionId = service.createBudgetTransactionForReimbursement(projectId, payrollComponent);
        }

        Payroll_Component__c insertedPayrollComponent = service.createPayrollComponent(projectId, payrollComponent, budgetTransactionId);
        service.updateBudgetTransactionItemForReimbursement(budgetTransactionItemId, insertedPayrollComponent.Id);
        service.createPayrollComponentItem(insertedPayrollComponent.Id, payrollComponentItemList);

        if(!payrollComponent.invoice) {
            service.sendToApproval(new Set<Id>{insertedPayrollComponent.Id});
        }

        if(!fileList.isEmpty()) {
            service.createAttachmentsForPayrollComponent(insertedPayrollComponent.Id, fileList);
        }
    }
}