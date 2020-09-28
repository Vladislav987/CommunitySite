/**
 * Created by Lambru Dmytro on 10.08.2020.
 */

public inherited sharing class LA_PayslipGenerationHelper {

    private static LA_PayslipGenerationService service = new LA_PayslipGenerationService();
    private static LA_PayslipGenerationSelector selector = new LA_PayslipGenerationSelector();
    private static LA_PayslipGenerationValidator validator = new LA_PayslipGenerationValidator();

    public Date getMaxSalaryTransitionDateByUser() {
        // set default value
        Date maxSalaryTransitionDate = Date.newInstance(LA_PayslipGenerationController.DATE_NOW.year(), LA_PayslipGenerationController.DATE_NOW.month(), 20);
        PayrollDateRulesService.PayrollBlockingDaysInfo payrollBlockingDaysInfo = new PayrollDateRulesService().getBlockingDaysInfoByUserAndUserRoleIds(
            UserInfo.getUserId(),
            UserInfo.getUserRoleId()
        );

        // leave the default if no setting is assigned to the current user
        if (payrollBlockingDaysInfo.isAvailable() && payrollBlockingDaysInfo.getSalaryTransitionDay() != null) {
            // set value from settings
            maxSalaryTransitionDate = Date.newInstance(LA_PayslipGenerationController.DATE_NOW.year(), LA_PayslipGenerationController.DATE_NOW.month(), (Integer)payrollBlockingDaysInfo.getSalaryTransitionDay());
        }

        return maxSalaryTransitionDate;
    }

    public LA_PayslipGenerationController.PayslipPart[] getPayslipParts(Date dateRange, LA_PayslipGenerationController.SelectedContractorInfo[] selectedContractorList) {
        Util_DatedCurrencyConverter datedCurrencyConverter = new Util_DatedCurrencyConverter();

        Set<Id> personAccountIdSet = service.getContractorPersonAccountIds(selectedContractorList);
        Account[] accountList = selector.getAccountsByIds(personAccountIdSet);
        Payroll_Component__c[] payrollComponentList = selector.getAllPCsOnDate(dateRange, personAccountIdSet);
        Map<Id, Payroll_Component__c[]> accountIdToPayrollComponentsMap = service.mapAccountIdToPayrollComponents(payrollComponentList);
        Map<String, LA_PayslipGenerationController.PayslipInfo[]> resourceTypeToPayslipInfosMap = service.mapResourceTypeToPayslipInfos(datedCurrencyConverter, accountList, accountIdToPayrollComponentsMap);

        return service.createPayslipParts(resourceTypeToPayslipInfosMap);
    }

    public LA_PayslipGenerationController.PayslipPart[] getHistoricalPayslipParts(Date dateRange, LA_PayslipGenerationController.SelectedContractorInfo[] selectedContractorList) {
        Util_DatedCurrencyConverter datedCurrencyConverter = new Util_DatedCurrencyConverter(dateRange.year());

        Set<Id> personAccountIdSet = service.getContractorPersonAccountIds(selectedContractorList);
        Payroll__c[] payrollList = selector.getPayrollsWithPCsOnDate(dateRange, personAccountIdSet);
        Map<String, LA_PayslipGenerationController.PayslipInfo[]> resourceTypeToPayslipInfosMap = service.mapResourceTypeToPayslipInfos(datedCurrencyConverter, payrollList);

        return service.createPayslipParts(resourceTypeToPayslipInfosMap);
    }

    public Boolean isPayrollExistsForContractors(LA_PayslipGenerationController.SelectedContractorInfo[] selectedContractorList) {
        Set<Id> personAccountIdSet = service.getContractorPersonAccountIds(selectedContractorList);
        Payroll__c[] payrollList = selector.getPayrollsByAccountIds(personAccountIdSet);

        return !payrollList.isEmpty();
    }

    public void generatePayrolls(Date startMonthDate, Date salaryDate, LA_PayslipGenerationController.PayslipPart[] payslipPartList) {
        Set<Id> personAccountIdSet = service.getPersonAccountIdsFromPayslipParts(payslipPartList);

        this.deletePCsForSalaryChange(startMonthDate, personAccountIdSet);
        this.deleteInvalidPCsFromTemplate(startMonthDate, personAccountIdSet);
        this.untieInvalidPCsFromPayroll(startMonthDate, personAccountIdSet);
        this.generatePayrolls(startMonthDate, salaryDate, personAccountIdSet, payslipPartList);
    }

    public void deletePCsForSalaryChange(Date startMonthDate, Set<Id> accountIdSet) {
        delete selector.getExistingPCsForSalaryChange(startMonthDate, accountIdSet);
    }

    public void deleteInvalidPCsFromTemplate(Date startMonthDate, Set<Id> accountIdSet) {
        Payroll_Component__c[] payrollComponentToDeleteList = new Payroll_Component__c[]{};
        Payroll_Component__c[] payrollComponentFromTemplateList = selector.getPCsFromTemplateOnDate(startMonthDate, accountIdSet);

        for (Payroll_Component__c payrollComponent : payrollComponentFromTemplateList) {

            if ( !validator.isPCDatesWithinTemplateDates(payrollComponent) ) {
                payrollComponentToDeleteList.add(payrollComponent);
            }
        }

        // delete all invalid PC from recurrent PC templates
        delete payrollComponentToDeleteList;
    }

    public void untieInvalidPCsFromPayroll(Date startMonthDate, Set<Id> accountIdSet) {
        Payroll_Component__c[] payrollComponentToUpdateList = new Payroll_Component__c[]{};
        Payroll__c[] payrollList = selector.getPayrollsWithPCsOnDateForDateValidation(startMonthDate, accountIdSet);

        for (Payroll__c payroll : payrollList) {

            for (Payroll_Component__c payrollComponent : payroll.Payroll_Components__r) {

                if (payrollComponent.StartDate__c != payroll.StartMonthDate__c) {
                    // untie PC from Payroll if invalid date
                    payrollComponent.Payroll__c = null;

                    payrollComponentToUpdateList.add(payrollComponent);
                }
            }
        }

        update payrollComponentToUpdateList;
    }

    public void generatePayrolls(Date startMonthDate, Date salaryDate, Set<Id> personAccountIdSet, LA_PayslipGenerationController.PayslipPart[] payslipPartList) {
        Set<Id> recurrentPCIdSet = new Set<Id>();
        Payroll_Component__c[] pcForSalaryChangeList = new Payroll_Component__c[]{};
        Payroll__c[] payrollToUpsertList = new Payroll__c[]{};

        // get existing Payroll and PCs records
        Map<Id, Payroll_Component__c> idToPayrollComponentMap = new Map<Id, Payroll_Component__c>(selector.getAllPCsOnDate(startMonthDate, personAccountIdSet));
        Map<Id, Payroll_Component__c[]> accountIdToPCsMap = service.mapAccountIdToPayrollComponents(idToPayrollComponentMap.values());
        Payroll__c[] existingPayrollList = selector.getExistingPayrollsOnDate(startMonthDate, personAccountIdSet);
        Map<Id, Payroll__c> accountIdToExistingPayrollMap = service.mapAccountIdToExistingPayroll(existingPayrollList);

        for (LA_PayslipGenerationController.PayslipPart payslipPart: payslipPartList) {

            for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {
                // skip blocked contractor for payslip generation
                if (payslipInfo.contractorInfo.isBlockedByJoiningDate) continue;

                validator.payrollComponentListsValid(payslipInfo, accountIdToPCsMap);

                for (LA_PayslipGenerationController.PayrollComponentInfo payrollComponentInfo : payslipInfo.payrollComponentInfoList) {
                    validator.payrollComponentValid(payrollComponentInfo, idToPayrollComponentMap);

                    if (payrollComponentInfo.isRecurrent) {
                        recurrentPCIdSet.add(payrollComponentInfo.id);
                    }
                }

                // add salary changes as Payroll Components
                if (payslipInfo.contractorInfo.hasSalaryChanges) {
                    pcForSalaryChangeList = service.createPCsForSalaryChangeFromPayslipInfo(payslipInfo, startMonthDate);
                }

                Payroll__c payroll = service.generatePayrollFromPayslipInfo(payslipInfo, accountIdToExistingPayrollMap, startMonthDate, salaryDate);
                payrollToUpsertList.add(payroll);
            }
        }

        Payroll_Component__c[] recurrentPCList = selector.getRecurrentPCsByIds(recurrentPCIdSet);
        Payroll_Component__c[] pcFromTemplateList = selector.getPCsByRecurrentTemplateIds(startMonthDate, recurrentPCIdSet);
        Map<Id, Payroll_Component__c> templateIdToPCFromTemplateMap = service.mapTemplateIdToPCFromTemplate(pcFromTemplateList);
        Payroll_Component__c[] generatedPCFromTemplateList = service.generatePCsFromRecurrentTemplates(recurrentPCList, templateIdToPCFromTemplateMap, startMonthDate);

        upsert payrollToUpsertList;
        insert pcForSalaryChangeList;
        upsert generatedPCFromTemplateList;

        Payroll_Component__c[] pcToAddList = new Payroll_Component__c[]{};
        pcToAddList.addAll(pcForSalaryChangeList);
        pcToAddList.addAll(generatedPCFromTemplateList);

        service.addGeneratedPCsToMap(accountIdToPCsMap, pcToAddList);

        Payroll_Component__c[] pcForUpdateList = service.setLinkToPayrollForPCs(payrollToUpsertList, accountIdToPCsMap);
        update pcForUpdateList;
    }

    public void deletePayrollsWithSpecificPCs(LA_PayslipGenerationController.PayslipPart[] payslipPartList) {
        Date startMonthDate = LA_PayslipGenerationController.DATE_NOW.toStartOfMonth();
        Set<Id> personAccountIdSet = service.getAccountIdsSelectedForPayrollDeletion(payslipPartList);
        SObject[] sObjectToDeleteList = new SObject[]{};

        // get Payrolls with specific PCs
        Map<Id, Payroll__c> idToPayrollMap = new Map<Id, Payroll__c>(selector.getPayrollsWithPCsForDeletion(startMonthDate, personAccountIdSet));

        validator.payrollsValidForDeletion(payslipPartList, idToPayrollMap);

        // add to delete validated Payrolls
        sObjectToDeleteList.addAll(idToPayrollMap.values());

        // add to delete specific PCs
        Payroll_Component__c[] relatedPCList = service.getPCsRelatedToPayrollsForDeletion(idToPayrollMap.values());
        sObjectToDeleteList.addAll(relatedPCList);

        delete sObjectToDeleteList;
    }
}