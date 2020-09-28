/**
 * Created by Lambru Dmytro on 10.08.2020.
 */

public inherited sharing class LA_PayslipGenerationService {

    public Set<Id> getContractorPersonAccountIds(LA_PayslipGenerationController.SelectedContractorInfo[] contractorList) {
        Set<Id> contractorAccountIdSet = new Set<Id>();

        for (LA_PayslipGenerationController.SelectedContractorInfo contractorInfo : contractorList) {
            contractorAccountIdSet.add(contractorInfo.personAccountId);
        }

        return contractorAccountIdSet;
    }

    public Map<Id, Payroll_Component__c[]> mapAccountIdToPayrollComponents(Payroll_Component__c[] payrollComponentList) {
        Map<Id, Payroll_Component__c[]> accountIdToPayrollComponentsMap = new Map<Id, Payroll_Component__c[]>();

        for (Payroll_Component__c payrollComponent : payrollComponentList) {

            if (!accountIdToPayrollComponentsMap.containsKey(payrollComponent.Account__c)) {
                accountIdToPayrollComponentsMap.put(payrollComponent.Account__c, new Payroll_Component__c[]{});
            }

            accountIdToPayrollComponentsMap.get(payrollComponent.Account__c).add(payrollComponent);
        }

        return accountIdToPayrollComponentsMap;
    }

    public Map<String, LA_PayslipGenerationController.PayslipInfo[]> mapResourceTypeToPayslipInfos(
        Util_DatedCurrencyConverter datedCurrencyConverter,
        Account[] accountList,
        Map<Id, Payroll_Component__c[]> accountIdToPayrollComponentsMap
    ) {
        Map<String, LA_PayslipGenerationController.PayslipInfo[]> resourceTypeToPayslipInfosMap = new Map<String, LA_PayslipGenerationController.PayslipInfo[]>();

        for (Account account : accountList) {
            Payroll_Component__c[] payrollComponentList = accountIdToPayrollComponentsMap.get(account.Id);
            LA_PayslipGenerationController.PayslipInfo payslipInfo = new LA_PayslipGenerationController.PayslipInfo(datedCurrencyConverter, account, payrollComponentList);

            if (!resourceTypeToPayslipInfosMap.containsKey(payslipInfo.contractorInfo.resourceType)) {
                resourceTypeToPayslipInfosMap.put(payslipInfo.contractorInfo.resourceType, new LA_PayslipGenerationController.PayslipInfo[]{});
            }

            resourceTypeToPayslipInfosMap.get(payslipInfo.contractorInfo.resourceType).add(payslipInfo);
        }

        return resourceTypeToPayslipInfosMap;
    }

    public Map<String, LA_PayslipGenerationController.PayslipInfo[]> mapResourceTypeToPayslipInfos(Util_DatedCurrencyConverter datedCurrencyConverter, Payroll__c[] payrollList) {
        Map<String, LA_PayslipGenerationController.PayslipInfo[]> resourceTypeToPayslipInfosMap = new Map<String, LA_PayslipGenerationController.PayslipInfo[]>();


        for (Payroll__c payroll : payrollList) {
            LA_PayslipGenerationController.PayslipInfo payslipInfo = new LA_PayslipGenerationController.PayslipInfo(datedCurrencyConverter, payroll);

            if (!resourceTypeToPayslipInfosMap.containsKey(payslipInfo.contractorInfo.resourceType)) {
                resourceTypeToPayslipInfosMap.put(payslipInfo.contractorInfo.resourceType, new LA_PayslipGenerationController.PayslipInfo[]{});
            }

            resourceTypeToPayslipInfosMap.get(payslipInfo.contractorInfo.resourceType).add(payslipInfo);
        }

        return resourceTypeToPayslipInfosMap;
    }

    public LA_PayslipGenerationController.PayslipPart[] createPayslipParts(Map<String, LA_PayslipGenerationController.PayslipInfo[]> resourceTypeToPayslipInfosMap) {
        LA_PayslipGenerationController.PayslipPart[] payslipPartList = new LA_PayslipGenerationController.PayslipPart[]{};

        for (String resourceType : resourceTypeToPayslipInfosMap.keySet()) {
            LA_PayslipGenerationController.PayslipPart payslipPart = new LA_PayslipGenerationController.PayslipPart();
            payslipPart.resourceType = resourceType;
            payslipPart.payslipInfoList = resourceTypeToPayslipInfosMap.get(resourceType);

            payslipPartList.add(payslipPart);
        }

        return payslipPartList;
    }

    public Set<Id> getPersonAccountIdsFromPayslipParts(LA_PayslipGenerationController.PayslipPart[] payslipPartList) {
        Set<Id> personAccountIdSet = new Set<Id>();

        for (LA_PayslipGenerationController.PayslipPart payslipPart: payslipPartList) {

            for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {

                if (payslipInfo.contractorInfo.isBlockedByJoiningDate) continue;

                personAccountIdSet.add(payslipInfo.contractorInfo.personAccountId);
            }
        }

        return personAccountIdSet;
    }

    public Map<Id, Payroll__c> mapAccountIdToExistingPayroll(Payroll__c[] payrollList) {
        Map<Id, Payroll__c> accountIdToExistingPayrollMap = new Map<Id, Payroll__c>();

        for (Payroll__c payroll : payrollList) {
            accountIdToExistingPayrollMap.put(payroll.Account__c, payroll);
        }

        return accountIdToExistingPayrollMap;
    }

    public Payroll_Component__c[] createPCsForSalaryChangeFromPayslipInfo(LA_PayslipGenerationController.PayslipInfo payslipInfo, Date startMonthDate) {
        Payroll_Component__c[] pcForSalaryChangeList = new Payroll_Component__c[]{};

        for (LA_PayslipGenerationController.SalaryChangeInfo salaryChangeInfo : payslipInfo.contractorInfo.salaryChangeInfoList) {
            Payroll_Component__c payrollComponent = new Payroll_Component__c(
                RecordTypeId = LA_PayslipGenerationController.PC_RT_ADJUSTMENTS_ID,
                Contractor__c = payslipInfo.contractorInfo.id,
                Account__c = payslipInfo.contractorInfo.personAccountId,
                Reason__c = salaryChangeInfo.payrollComponentInfo.reason,
                CurrencyIsoCode = salaryChangeInfo.payrollComponentInfo.currencyIsoCode,
                Sum__c = salaryChangeInfo.payrollComponentInfo.sum,
                SumType__c = salaryChangeInfo.payrollComponentInfo.isIncrementSumType
                    ? LA_PayslipGenerationController.PC_SUM_TYPE_INCREMENT
                    : LA_PayslipGenerationController.PC_SUM_TYPE_DECREMENT,
                Approval_Status__c = LA_PayslipGenerationController.PC_APPROVAL_STATUS_APPROVED,
                Adjustment_Type__c = LA_PayslipGenerationController.PC_ADJUSTMENT_TYPE_SALARY_ADJUSTMENT,
                Recurrent__c = false,
                StartDate__c = startMonthDate,
                EndDate__c = startMonthDate
            );

            pcForSalaryChangeList.add(payrollComponent);
        }

        return pcForSalaryChangeList;
    }

    public Payroll__c generatePayrollFromPayslipInfo(
        LA_PayslipGenerationController.PayslipInfo payslipInfo,
        Map<Id, Payroll__c> accountIdToExistingPayrollMap,
        Date startMonthDate,
        Date salaryDate
    ) {
        Payroll__c payroll;

        if (accountIdToExistingPayrollMap.containsKey(payslipInfo.contractorInfo.personAccountId)) {
            payroll = accountIdToExistingPayrollMap.get(payslipInfo.contractorInfo.personAccountId);

            payroll.CurrencyIsoCode = payslipInfo.contractorInfo.currencyIsoCode;
            payroll.Salary__c = payslipInfo.contractorInfo.salary;
            payroll.Sum__c = payslipInfo.contractorInfo.totalSalary;
            payroll.SalaryDate__c = salaryDate;
        }
        else {
            payroll = new Payroll__c();

            payroll.RecordTypeId = LA_PayslipGenerationController.PAYROLL_RT_ID;
            payroll.Account__c = payslipInfo.contractorInfo.personAccountId;
            payroll.Contractor__c = payslipInfo.contractorInfo.id;
            payroll.CurrencyIsoCode = payslipInfo.contractorInfo.currencyIsoCode;
            payroll.Salary__c = payslipInfo.contractorInfo.salary;
            payroll.Sum__c = payslipInfo.contractorInfo.totalSalary;
            payroll.SalaryDate__c = salaryDate;
            payroll.StartMonthDate__c = startMonthDate;
        }

        return payroll;
    }

    public Map<Id, Payroll_Component__c> mapTemplateIdToPCFromTemplate(Payroll_Component__c[] pcFromTemplateList) {
        Map<Id, Payroll_Component__c> templateIdToPCFromTemplateMap = new Map<Id, Payroll_Component__c>();

        for (Payroll_Component__c pcFromTemplate : pcFromTemplateList) {
            templateIdToPCFromTemplateMap.put(pcFromTemplate.Payroll_Component_Template__c, pcFromTemplate);
        }

        return templateIdToPCFromTemplateMap;
    }

    public Payroll_Component__c[] generatePCsFromRecurrentTemplates(
        Payroll_Component__c[] recurrentPayrollComponentList,
        Map<Id, Payroll_Component__c> templateIdToPCFromTemplateMap,
        Date startMonthDate
    ) {
        Payroll_Component__c[] pcFromTemplateList = new Payroll_Component__c[]{};
        String recordTypeDevNameBonus = PayrollComponentSelector.RECORD_TYPE_INFO_BONUS.getDeveloperName();
        String recordTypeDevNameDeduction = PayrollComponentSelector.RECORD_TYPE_INFO_DEDUCTION.getDeveloperName();
        String recordTypeDevNameInsurance = PayrollComponentSelector.RECORD_TYPE_INFO_INSURANCE.getDeveloperName();
        Id recordTypeIdBonus = PayrollComponentSelector.RECORD_TYPE_INFO_BONUS.getRecordTypeId();
        Id recordTypeIdDeduction = PayrollComponentSelector.RECORD_TYPE_INFO_DEDUCTION.getRecordTypeId();
        Id recordTypeIdInsurance = PayrollComponentSelector.RECORD_TYPE_INFO_INSURANCE.getRecordTypeId();

        for (Payroll_Component__c recurrentPayrollComponent : recurrentPayrollComponentList) {
            Payroll_Component__c payrollComponent;
            Id recordTypeId;

            // TODO: Config__mdt for mapping
            if (recurrentPayrollComponent.RecordType.DeveloperName.contains(recordTypeDevNameBonus)) {
                recordTypeId = recordTypeIdBonus;
            }
            else if (recurrentPayrollComponent.RecordType.DeveloperName.contains(recordTypeDevNameDeduction)) {
                recordTypeId = recordTypeIdDeduction;
            }
            else if (recurrentPayrollComponent.RecordType.DeveloperName.contains(recordTypeDevNameInsurance)) {
                recordTypeId = recordTypeIdInsurance;
            }

            if (templateIdToPCFromTemplateMap.containsKey(recurrentPayrollComponent.Id)) {
                payrollComponent = templateIdToPCFromTemplateMap.get(recurrentPayrollComponent.Id);

                payrollComponent.RecordTypeId = recordTypeId;
                payrollComponent.CurrencyIsoCode = recurrentPayrollComponent.CurrencyIsoCode;
                payrollComponent.SumType__c = recurrentPayrollComponent.SumType__c;
                payrollComponent.Sum__c = recurrentPayrollComponent.Sum__c;
                payrollComponent.Reason__c = recurrentPayrollComponent.Reason__c;
            }
            else {
                payrollComponent = new Payroll_Component__c();

                payrollComponent.RecordTypeId = recordTypeId;
                payrollComponent.Payroll_Component_Template__c = recurrentPayrollComponent.Id;
                payrollComponent.Account__c = recurrentPayrollComponent.Account__c;
                payrollComponent.Contractor__c = recurrentPayrollComponent.Contractor__c;
                payrollComponent.CurrencyIsoCode = recurrentPayrollComponent.CurrencyIsoCode;
                payrollComponent.SumType__c = recurrentPayrollComponent.SumType__c;
                payrollComponent.Sum__c = recurrentPayrollComponent.Sum__c;
                payrollComponent.Reason__c = recurrentPayrollComponent.Reason__c;
                payrollComponent.Approval_Status__c = LA_PayslipGenerationController.PC_APPROVAL_STATUS_APPROVED;
                payrollComponent.StartDate__c = startMonthDate;
                payrollComponent.EndDate__c = startMonthDate;
            }

            pcFromTemplateList.add(payrollComponent);
        }

        return pcFromTemplateList;
    }

    public void addGeneratedPCsToMap(Map<Id, Payroll_Component__c[]> accountIdToPCsMap, Payroll_Component__c[] pcToAddList) {

        for (Payroll_Component__c payrollComponent : pcToAddList) {

            if (!accountIdToPCsMap.containsKey(payrollComponent.Account__c)) {
                accountIdToPCsMap.put(payrollComponent.Account__c, new Payroll_Component__c[]{});
            }

            accountIdToPCsMap.get(payrollComponent.Account__c).add(payrollComponent);
        }
    }

    public Payroll_Component__c[] setLinkToPayrollForPCs(Payroll__c[] payrollList, Map<Id, Payroll_Component__c[]> accountIdToPCsMap) {
        Payroll_Component__c[] pcForUpdateList = new Payroll_Component__c[]{};

        for (Payroll__c payroll : payrollList) {

            if (accountIdToPCsMap.containsKey(payroll.Account__c)) {
                Payroll_Component__c[] payrollComponentList = accountIdToPCsMap.get(payroll.Account__c);

                for (Payroll_Component__c payrollComponent : payrollComponentList) {

                    if (payrollComponent.Recurrent__c) continue;

                    payrollComponent.Payroll__c = payroll.Id;

                    pcForUpdateList.add(payrollComponent);
                }
            }
        }

        return pcForUpdateList;
    }

    public Set<Id> getAccountIdsSelectedForPayrollDeletion(LA_PayslipGenerationController.PayslipPart[] payslipPartList) {
        Set<Id> personAccountIdSet = new Set<Id>();

        for (LA_PayslipGenerationController.PayslipPart payslipPart: payslipPartList) {

            for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {

                if (payslipInfo.isToDelete) {
                    personAccountIdSet.add(payslipInfo.contractorInfo.personAccountId);
                }
            }
        }

        return personAccountIdSet;
    }

    public Payroll_Component__c[] getPCsRelatedToPayrollsForDeletion(Payroll__c[] payrollList) {
        Payroll_Component__c[] payrollComponentList = new Payroll_Component__c[]{};

        for (Payroll__c payroll : payrollList) {

            if (!payroll.Payroll_Components__r.isEmpty()) {
                payrollComponentList.addAll(payroll.Payroll_Components__r);
            }
        }

        return payrollComponentList;
    }
}