/**
 * Created by Lambru Dmytro on 12.05.2020.
 */
public without sharing class LA_PayslipGenerationController {

    /* SETTINGS */
    private static Date maxSalaryTransitionDate;

    /* HELPERS */
    private static Map<String, Integer> stationToWorkingDaysInCurrentMonth;
    private static Map<String, Integer> stationToWorkingDaysInPreviousMonth;

    /* CONSTANTS */
    private static final Date DATE_NOW = Date.valueOf(System.now());
    private static final Id PC_RT_ADJUSTMENTS_ID = PayrollComponentSelector.RECORD_TYPE_INFO_ADJUSTMENTS.getRecordTypeId();
    private static final String PC_RT_ADJUSTMENTS_NAME = PayrollComponentSelector.RECORD_TYPE_INFO_ADJUSTMENTS.getName();
    private static final String PC_SUM_TYPE_INCREMENT = PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.SumTypePicklistKey.INCREMENT);
    private static final String PC_SUM_TYPE_DECREMENT = PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.SumTypePicklistKey.DECREMENT);
    private static final String PC_APPROVAL_STATUS_APPROVED = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
    private static final String PC_ADJUSTMENT_TYPE_SALARY_ADJUSTMENT = PayrollComponentSelector.ADJUSTMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.AdjustmentTypePicklistKey.SALARY_ADJUSTMENT);

    @TestVisible private static final Integer ERROR_CODE_1001 = 1001;
    @TestVisible private static final Integer ERROR_CODE_1002 = 1002;
    @TestVisible private static final Integer ERROR_CODE_1003 = 1003;
    @TestVisible private static final Integer ERROR_CODE_1004 = 1004;
    @TestVisible private static final Integer ERROR_CODE_1005 = 1005;

    private static final String KEY_WORD_DAY_NUMBER = '%%DAY_NUMBER%%';
    private static final String KEY_WORD_HOUR_NUMBER = '%%HOUR_NUMBER%%';
    private static final String TXT_SALARY_REASON_FOR_JOINING_NEXT_MONTH = 'The amount will be calculated for ' + KEY_WORD_DAY_NUMBER + ' day(s) (or ' + KEY_WORD_HOUR_NUMBER + ' hours) in the next month due to join date.';
    private static final String TXT_SALARY_REASON_FOR_JOINING_PREVIOUS_MONTH = 'The rest of the salary for ' + KEY_WORD_DAY_NUMBER + ' day(s) (or ' + KEY_WORD_HOUR_NUMBER + ' hours) of the previous month due to join date.';
    private static final String TXT_SALARY_REASON_FOR_EXIT = 'Salary decrement for non-working ' + KEY_WORD_DAY_NUMBER + ' day(s) (or ' + KEY_WORD_HOUR_NUMBER + ' hours) due to exit date.';

    @AuraEnabled
    public static LightningResponse deletePayslips(String jsonPayslipPartList) {
        LightningResponse response = new LightningResponse();

        if (jsonPayslipPartList == null) {
            return response.setError(400); // HTTP 400 Bad Request
        }

        try {

            PayslipPart[] payslipPartList = (PayslipPart[]) JSON.deserialize(jsonPayslipPartList, PayslipPart[].class);

            if (payslipPartList == null || payslipPartList.isEmpty()) {
                return response.setError(406); // HTTP 406 Not Acceptable
            }

            validateAndDeletePayslips(payslipPartList);

            response.success = true;
        }
        catch (PayrollGenerationException exc) {
            response.setError(exc.errorCode);
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_PayslipGenerationController.class));
        }

        return response;
    }

    private static Set<Id> getSelectedPersonAccIdsToDeletePayslips(PayslipPart[] payslipPartList) {
        Set<Id> personAccountIdSet = new Set<Id>();

        for (PayslipPart payslipPart: payslipPartList) {

            for (PayslipInfo payslipInfo : payslipPart.payslipInfoList) {

                if (payslipInfo.isToDelete) {
                    personAccountIdSet.add(payslipInfo.contractorInfo.personAccountId);
                }
            }
        }

        return personAccountIdSet;
    }

    private static void validateAndDeletePayslips(PayslipPart[] payslipPartList) {
        Date startMonthDate = DATE_NOW.toStartOfMonth();
        Set<Id> personAccountIdSet = getSelectedPersonAccIdsToDeletePayslips(payslipPartList);
        SObject[] sObjectToDeleteList = new SObject[]{};

        // get Payrolls with PCs from template
        Map<Id, Payroll__c> idToPayrollMap = new Map<Id, Payroll__c>([
            SELECT
                SystemModstamp,
                (
                    SELECT Id
                    FROM Payroll_Components__r
                    WHERE Payroll_Component_Template__c <> NULL
                    OR (RecordTypeId = :PC_RT_ADJUSTMENTS_ID AND Adjustment_Type__c = :PC_ADJUSTMENT_TYPE_SALARY_ADJUSTMENT)
                    LIMIT 10000
                )
            FROM Payroll__c
            WHERE Account__c IN :personAccountIdSet
            AND StartMonthDate__c = :startMonthDate
            LIMIT 10000
            FOR UPDATE
        ]);

        // add to delete PCs from template
        for (Payroll__c payroll : idToPayrollMap.values()) {

            if (!payroll.Payroll_Components__r.isEmpty()) {
                sObjectToDeleteList.addAll(payroll.Payroll_Components__r);
            }
        }

        // validate payslips
        for (PayslipPart payslipPart : payslipPartList) {

            for (PayslipInfo payslipInfo : payslipPart.payslipInfoList) {

                if (payslipInfo.isToDelete) {

                    if (!idToPayrollMap.containsKey(payslipInfo.id)) {
                        // throw an exception if the record is already deleted
                        throw new PayrollGenerationException(LA_PayslipGenerationController.ERROR_CODE_1004);
                    }
                    else if (payslipInfo.lastUpdateTimestamp != idToPayrollMap.get(payslipInfo.id).SystemModstamp.getTime()) {
                        // throw an exception if record has been changed
                        throw new PayrollGenerationException(LA_PayslipGenerationController.ERROR_CODE_1005);
                    }
                }

            }
        }

        // add to delete validated Payrolls
        sObjectToDeleteList.addAll(idToPayrollMap.values());

        delete sObjectToDeleteList;
    }

    // ########################################################################################################################################
    // ########################################################################################################################################
    // ########################################################################################################################################

    @AuraEnabled
    public static LightningResponse isPayrollExistsForContractors(Integer month, Integer year, String jsonWithSelectedContractors) {
        LightningResponse response = new LightningResponse();

        if (isInvalidParams(month, year, jsonWithSelectedContractors)) {
            return response.setError(400); // HTTP 400 Bad Request
        }
        else if (year != DATE_NOW.year() || month != DATE_NOW.month()) {
            return response.setError(406); // HTTP 406 Not Acceptable
        }

        try {

            SelectedContractorInfo[] selectedContractorList = (SelectedContractorInfo[]) JSON.deserialize(jsonWithSelectedContractors, SelectedContractorInfo[].class);

            if (selectedContractorList == null || selectedContractorList.isEmpty()) {
                return response.setError(406); // HTTP 406 Not Acceptable
            }

            Set<Id> personAccountIdSet = getContractorPersonAccountIds(selectedContractorList);

            Payroll__c[] payrollList = [
                SELECT Id
                FROM Payroll__c
                WHERE Account__c IN :personAccountIdSet
                AND StartMonthDate__c = :DATE_NOW.toStartOfMonth()
                LIMIT 10000
            ];

            response.setResult(JSON.serialize(!payrollList.isEmpty()));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_PayslipGenerationController.class));
        }

        return response;
    }

    private static Boolean isInvalidParams(Integer month, Integer year, String jsonWithSelectedContractors) {
        return month == null || year == null || jsonWithSelectedContractors == null;
    }

    // ##########################################################################################
    // ##########################################################################################
    // ##########################################################################################

    @AuraEnabled
    public static LightningResponse generatePayslips(Integer month, Integer year, String salaryDateString, String jsonPayslipPartList) {
        LightningResponse response = new LightningResponse();

        if (month == null || year == null || salaryDateString == null || jsonPayslipPartList == null) {
            return response.setError(400); // HTTP 400 Bad Request
        }

        try {
            Date salaryDate = Date.valueOf(salaryDateString);
            PayslipPart[] payslipPartList = (PayslipPart[]) JSON.deserialize(jsonPayslipPartList, PayslipPart[].class);

            if (month != DATE_NOW.month()
                || year != DATE_NOW.year()
                || salaryDate <= DATE_NOW
                || payslipPartList == null
                || payslipPartList.isEmpty()
                || isBlockedForGenerationBasedOnUser()) {

                return response.setError(406); // HTTP 406 Not Acceptable
            }

            Date startMonthDate = Date.newInstance(year, month, 1);
            Set<Id> personAccountIdSet = getPersonAccountIdsFromPayslipParts(payslipPartList);

            validateAndUpdatePayslips(startMonthDate, personAccountIdSet);
            generatePayrolls(startMonthDate, salaryDate, personAccountIdSet, payslipPartList);

            response.success = true;
        }
        catch (PayrollGenerationException exc) {
            response.setError(exc.errorCode);
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_PayslipGenerationController.class));
        }

        return response;
    }

    private static Set<Id> getPersonAccountIdsFromPayslipParts(PayslipPart[] payslipPartList) {
        Set<Id> personAccountIdSet = new Set<Id>();

        for (PayslipPart payslipPart: payslipPartList) {

            for (PayslipInfo payslipInfo : payslipPart.payslipInfoList) {

                if (payslipInfo.contractorInfo.isBlockedByJoiningDate) continue;

                personAccountIdSet.add(payslipInfo.contractorInfo.personAccountId);
            }
        }

        return personAccountIdSet;
    }

    private static void validateAndUpdatePayslips(Date startMonthDate, Set<Id> personAccountIdSet) {
        Payroll_Component__c[] payrollComponentFromTemplateList = [
            SELECT StartDate__c,
                EndDate__c,
                Payroll_Component_Template__r.StartDate__c,
                Payroll_Component_Template__r.EndDate__c
            FROM Payroll_Component__c
            WHERE StartDate__c = :startMonthDate
            AND Account__c IN :personAccountIdSet
            AND Payroll_Component_Template__c <> NULL
            LIMIT 10000
            FOR UPDATE
        ];

        Payroll_Component__c[] payrollComponentToDeleteList = new Payroll_Component__c[]{};

        for (Payroll_Component__c payrollComponent : payrollComponentFromTemplateList) {

            if (false == (
                payrollComponent.StartDate__c >= payrollComponent.Payroll_Component_Template__r.StartDate__c
                && payrollComponent.EndDate__c <= payrollComponent.Payroll_Component_Template__r.EndDate__c
            )) {

                payrollComponentToDeleteList.add(payrollComponent);
            }
        }

        // delete all invalid PC from recurrent PC templates
        delete payrollComponentToDeleteList;

        Payroll__c[] payrollList = [
            SELECT StartMonthDate__c,
            (
                SELECT StartDate__c, Payroll__c
                FROM Payroll_Components__r
            )
            FROM Payroll__c
            WHERE StartMonthDate__c = :startMonthDate
            AND Account__c IN :personAccountIdSet
            LIMIT 10000
            FOR UPDATE
        ];

        Payroll_Component__c[] payrollComponentToUpdateList = new Payroll_Component__c[]{};

        for (Payroll__c payroll : payrollList) {

            for (Payroll_Component__c payrollComponent : payroll.Payroll_Components__r) {

                if (payrollComponent.StartDate__c != payroll.StartMonthDate__c) {
                    payrollComponent.Payroll__c = null;

                    payrollComponentToUpdateList.add(payrollComponent);
                }
            }
        }

        // untie PC from Payroll if invalid date
        update payrollComponentToUpdateList;
    }

    private static void generatePayrolls(Date startMonthDate, Date salaryDate, Set<Id> personAccountIdSet, PayslipPart[] payslipPartList) {
        Id payrollRecordTypeId = PayrollSelector.RECORD_TYPE_INFO_PAYROLL.getRecordTypeId();
        Set<Id> recurrentPayrollComponentIdSet = new Set<Id>();
        Payroll_Component__c[] pcForSalaryChangeList = new Payroll_Component__c[]{};
        Payroll__c[] payrollToUpsertList = new Payroll__c[]{};

        delete getExistingPCsForSalaryChange(startMonthDate, personAccountIdSet);

        // get existing Payroll and PCs records
        Map<Id, Payroll_Component__c> idToPayrollComponentMap = new Map<Id, Payroll_Component__c>(getPayrollComponentsOnDate(startMonthDate, personAccountIdSet));
        Map<Id, Payroll_Component__c[]> accountIdToPayrollComponentsMap = mapAccountIdToPayrollComponents(idToPayrollComponentMap.values());
        Payroll__c[] existingPayrollList = getExistingPayrolls(startMonthDate, personAccountIdSet);
        Map<Id, Payroll__c> accountIdToExistingPayrollMap = mapAccountIdToExistingPayroll(existingPayrollList);

        for (PayslipPart payslipPart: payslipPartList) {

            for (PayslipInfo payslipInfo : payslipPart.payslipInfoList) {
                // skip blocked contractor for payslip generation
                if (payslipInfo.contractorInfo.isBlockedByJoiningDate) continue;

                validatePayslipInfo(payslipInfo, accountIdToPayrollComponentsMap);

                for (PayrollComponentInfo payrollComponentInfo : payslipInfo.payrollComponentInfoList) {
                    validatePayrollComponentInfo(payrollComponentInfo, idToPayrollComponentMap);

                    if (payrollComponentInfo.isRecurrent) {
                        recurrentPayrollComponentIdSet.add(payrollComponentInfo.id);
                    }
                }

                // add salary change as Payroll Component
                if (payslipInfo.contractorInfo.hasSalaryChangeByJoiningDate || payslipInfo.contractorInfo.hasSalaryChangeByExitDate) {
                    Payroll_Component__c pcForSalaryChange = createPayrollComponentForSalaryChange(payslipInfo, startMonthDate);
                    pcForSalaryChangeList.add(pcForSalaryChange);
                }

                Payroll__c payroll = generatePayrollFromPayslipInfo(payslipInfo, accountIdToExistingPayrollMap, payrollRecordTypeId, startMonthDate, salaryDate);
                payrollToUpsertList.add(payroll);
            }
        }

        Payroll_Component__c[] recurrentPayrollComponentList = getRecurrentPayrollComponentsByIds(recurrentPayrollComponentIdSet);
        Payroll_Component__c[] existingPayrollComponentFromRecurrentList = getExistingPayrollComponentsByRecurrentIds(startMonthDate, recurrentPayrollComponentIdSet);
        Map<Id, Payroll_Component__c> recurrentIdToExistingPayrollComponentFromRecurrentMap = mapRecurrentIdToExistingPayrollComponent(existingPayrollComponentFromRecurrentList);
        Payroll_Component__c[] pcFromRecurrentList = generatePayrollComponentsFromRecurrent(recurrentPayrollComponentList, recurrentIdToExistingPayrollComponentFromRecurrentMap, startMonthDate);

        upsert payrollToUpsertList;
        insert pcForSalaryChangeList;
        upsert pcFromRecurrentList;

        Payroll_Component__c[] pcToAddList = new Payroll_Component__c[]{};
        pcToAddList.addAll(pcForSalaryChangeList);
        pcToAddList.addAll(pcFromRecurrentList);

        addPayrollComponentsToMap(accountIdToPayrollComponentsMap, pcToAddList);

        Payroll_Component__c[] pcForUpdateList = new Payroll_Component__c[]{};

        for (Payroll__c payroll : payrollToUpsertList) {

            if (accountIdToPayrollComponentsMap.containsKey(payroll.Account__c)) {
                Payroll_Component__c[] payrollComponentList = accountIdToPayrollComponentsMap.get(payroll.Account__c);

                for (Payroll_Component__c payrollComponent : payrollComponentList) {

                    if (payrollComponent.Recurrent__c) continue;

                    payrollComponent.Payroll__c = payroll.Id;

                    pcForUpdateList.add(payrollComponent);
                }
            }
        }

        update pcForUpdateList;
    }

    private static void addPayrollComponentsToMap(Map<Id, Payroll_Component__c[]> accountIdToPayrollComponentsMap, Payroll_Component__c[] payrollComponentFromRecurrentList) {

        for (Payroll_Component__c payrollComponent : payrollComponentFromRecurrentList) {

            if (!accountIdToPayrollComponentsMap.containsKey(payrollComponent.Account__c)) {
                accountIdToPayrollComponentsMap.put(payrollComponent.Account__c, new Payroll_Component__c[]{});
            }

            accountIdToPayrollComponentsMap.get(payrollComponent.Account__c).add(payrollComponent);
        }

    }

    private static Payroll__c[] getExistingPayrolls(Date startMonthDate, Set<Id> contractorAccountIdSet) {

        return [
            SELECT Account__c,
                Contractor__c,
                CurrencyIsoCode,
                Salary__c,
                Sum__c,
                SalaryDate__c,
                StartMonthDate__c
            FROM Payroll__c
            WHERE RecordTypeId = :PayrollSelector.RECORD_TYPE_INFO_PAYROLL.getRecordTypeId()
            AND Account__c IN :contractorAccountIdSet
            AND StartMonthDate__c = :startMonthDate
        ];
    }

    private static Map<Id, Payroll__c> mapAccountIdToExistingPayroll(Payroll__c[] payrollList) {
        Map<Id, Payroll__c> accountIdToExistingPayrollMap = new Map<Id, Payroll__c>();

        for (Payroll__c payrollComponent : payrollList) {
            accountIdToExistingPayrollMap.put(payrollComponent.Account__c, payrollComponent);
        }

        return accountIdToExistingPayrollMap;
    }

    private static void validatePayslipInfo(PayslipInfo payslipInfo, Map<Id, Payroll_Component__c[]> accountIdToPayrollComponentsMap) {

        if (
            isListsDifferentByState(payslipInfo, accountIdToPayrollComponentsMap)
            || isListsDifferentBySize(payslipInfo, accountIdToPayrollComponentsMap)
        ) {
            // throw an exception if the number of PC records has changed
            throw new PayrollGenerationException(ERROR_CODE_1001);
        }
    }

    private static Boolean isListsDifferentByState(PayslipInfo payslipInfo, Map<Id, Payroll_Component__c[]> accountIdToPayrollComponentsMap) {
        return (
            payslipInfo.payrollComponentInfoList.isEmpty() && accountIdToPayrollComponentsMap.containsKey(payslipInfo.contractorInfo.personAccountId)
            || !accountIdToPayrollComponentsMap.containsKey(payslipInfo.contractorInfo.personAccountId) && !payslipInfo.payrollComponentInfoList.isEmpty()
        );
    }

    private static Boolean isListsDifferentBySize(PayslipInfo payslipInfo, Map<Id, Payroll_Component__c[]> accountIdToPayrollComponentsMap) {
        return (
            accountIdToPayrollComponentsMap.containsKey(payslipInfo.contractorInfo.personAccountId)
            && payslipInfo.payrollComponentInfoList.size() != accountIdToPayrollComponentsMap.get(payslipInfo.contractorInfo.personAccountId).size()
        );
    }

    private static void validatePayrollComponentInfo(PayrollComponentInfo payrollComponentInfo, Map<Id, Payroll_Component__c> idToPayrollComponentMap) {

        if (!idToPayrollComponentMap.containsKey(payrollComponentInfo.id)) {
            // throw an exception if the PC record has been deleted
            throw new PayrollGenerationException(ERROR_CODE_1002);
        }
        else if (idToPayrollComponentMap.get(payrollComponentInfo.id).SystemModstamp.getTime() != payrollComponentInfo.lastUpdateTimestamp) {
            // throw an exception if the PC record has changed
            throw new PayrollGenerationException(ERROR_CODE_1003);
        }
    }

    private static Payroll_Component__c createPayrollComponentForSalaryChange(PayslipInfo payslipInfo, Date startMonthDate) {

        return new Payroll_Component__c(
            RecordTypeId = PC_RT_ADJUSTMENTS_ID,
            Contractor__c = payslipInfo.contractorInfo.id,
            Account__c = payslipInfo.contractorInfo.personAccountId,
            Reason__c = payslipInfo.contractorInfo.salaryChangeInfo.payrollComponentInfo.reason,
            CurrencyIsoCode = payslipInfo.contractorInfo.salaryChangeInfo.payrollComponentInfo.currencyIsoCode,
            Sum__c = payslipInfo.contractorInfo.salaryChangeInfo.payrollComponentInfo.sum,
            SumType__c = payslipInfo.contractorInfo.salaryChangeInfo.payrollComponentInfo.isIncrementSumType
                         ? PC_SUM_TYPE_INCREMENT
                         : PC_SUM_TYPE_DECREMENT,
            Approval_Status__c = PC_APPROVAL_STATUS_APPROVED,
            Adjustment_Type__c = PC_ADJUSTMENT_TYPE_SALARY_ADJUSTMENT,
            Recurrent__c = false,
            StartDate__c = startMonthDate,
            EndDate__c = startMonthDate
        );
    }

    private static Map<Id, Payroll_Component__c> mapRecurrentIdToExistingPayrollComponent(Payroll_Component__c[] existingPayrollComponentFromRecurrentList) {
        Map<Id, Payroll_Component__c> recurrentIdToExistingPayrollComponentFromRecurrentMap = new Map<Id, Payroll_Component__c>();

        for (Payroll_Component__c existingPayrollComponentFromRecurrent : existingPayrollComponentFromRecurrentList) {
            recurrentIdToExistingPayrollComponentFromRecurrentMap.put(existingPayrollComponentFromRecurrent.Payroll_Component_Template__c, existingPayrollComponentFromRecurrent);
        }

        return recurrentIdToExistingPayrollComponentFromRecurrentMap;
    }

    private static Payroll_Component__c[] generatePayrollComponentsFromRecurrent(Payroll_Component__c[] recurrentPayrollComponentList, Map<Id, Payroll_Component__c> recurrentIdToExistingPayrollComponentFromRecurrentMap, Date startMonthDate) {
        Payroll_Component__c[] payrollComponentFromRecurrentList = new Payroll_Component__c[]{};
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

            if (recurrentIdToExistingPayrollComponentFromRecurrentMap.containsKey(recurrentPayrollComponent.Id)) {
                payrollComponent = recurrentIdToExistingPayrollComponentFromRecurrentMap.get(recurrentPayrollComponent.Id);

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
                payrollComponent.Approval_Status__c = PC_APPROVAL_STATUS_APPROVED;
                payrollComponent.StartDate__c = startMonthDate;
                payrollComponent.EndDate__c = startMonthDate;
            }

            payrollComponentFromRecurrentList.add(payrollComponent);
        }

        return payrollComponentFromRecurrentList;
    }

    private static Payroll__c generatePayrollFromPayslipInfo(PayslipInfo payslipInfo, Map<Id, Payroll__c> accountIdToExistingPayrollMap, Id payrollRecordTypeId, Date startMonthDate, Date salaryDate) {
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

            payroll.RecordTypeId = payrollRecordTypeId;
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

    //################################################################################
    //################################################################################
    //################################################################################

    @AuraEnabled
    public static LightningResponse getHistoricalPayslipsByResourceType(Integer month, Integer year, String jsonWithSelectedContractors) {
        LightningResponse response = new LightningResponse();

        if (isInvalidParams(month, year, jsonWithSelectedContractors)) {
            return response.setError(400); // HTTP 400 Bad Request
        }
        else if (year > DATE_NOW.year() || (year == DATE_NOW.year() && month > DATE_NOW.month())) {
            return response.setError(406); // HTTP 406 Not Acceptable
        }

        try {

            SelectedContractorInfo[] selectedContractorList = (SelectedContractorInfo[]) JSON.deserialize(jsonWithSelectedContractors, SelectedContractorInfo[].class);

            if (selectedContractorList == null) {
                return response.setError(406); // HTTP 406 Not Acceptable
            }

            Date dateRange = Date.newInstance(year, month, 1);
            Set<Id> personAccountIdSet = getContractorPersonAccountIds(selectedContractorList);

            Payroll__c[] payrollList = [
                SELECT
                    Account__c,
                    Account__r.Name,
                    Account__r.Resource_Type__c,
                    Salary__c,
                    Sum__c,
                    CurrencyIsoCode,
                    SystemModstamp,
                    (
                        SELECT
                            RecordType.Name,
                            Payroll_Component_Template__c,
                            Recurrent__c,
                            CurrencyIsoCode,
                            SumType__c,
                            Sum__c,
                            Reason__c
                        FROM Payroll_Components__r
                    )
                FROM Payroll__c
                WHERE Account__c IN :personAccountIdSet
                AND StartMonthDate__c = :dateRange
                LIMIT 10000
            ];

            PayslipInfo[] payslipInfoList = new PayslipInfo[]{};

            for (Payroll__c payroll : payrollList) {
                payslipInfoList.add(new PayslipInfo(payroll));
            }

            Map<String, PayslipInfo[]> resourceTypeToPayslipInfosMap = mapResourceTypeToPayslipInfos(payslipInfoList);
            PayslipPart[] payslipPartList = createPayslipParts(resourceTypeToPayslipInfosMap);

            response.setResult(JSON.serialize(payslipPartList, true));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_PayslipGenerationController.class));
        }

        return response;
    }

    //################################################################################
    //################################################################################
    //################################################################################

    @AuraEnabled
    public static LightningResponse getPayslipsByResourceType(Integer month, Integer year, String jsonWithSelectedContractors) {
        LightningResponse response = new LightningResponse();

        if (isInvalidParams(month, year, jsonWithSelectedContractors)) {
            return response.setError(400); // HTTP 400 Bad Request
        }
        else if (year != DATE_NOW.year() || month != DATE_NOW.month()) {
            return response.setError(406); // HTTP 406 Not Acceptable
        }

        try {
            SelectedContractorInfo[] selectedContractorList = (SelectedContractorInfo[]) JSON.deserialize(jsonWithSelectedContractors, SelectedContractorInfo[].class);

            if (selectedContractorList == null || selectedContractorList.isEmpty()) {
                return response.setError(406); // HTTP 406 Not Acceptable
            }

            setMaxSalaryTransitionDateByUser();
            createHelperMapsForCalculatingWorkingDays();
            stationToWorkingDaysInCurrentMonth = mapStationToWorkingDaysForMonth(DATE_NOW.toStartOfMonth());
            stationToWorkingDaysInPreviousMonth = mapStationToWorkingDaysForMonth(DATE_NOW.addMonths(-1).toStartOfMonth());

            Set<Id> personAccountIdSet = getContractorPersonAccountIds(selectedContractorList);

            Account[] contractorAccountList = [
                SELECT Name,
                    Resource_Type__c,
                    Station__c,
                    Contractor__r.Id,
                    Contractor__r.CurrencyIsoCode,
                    Contractor__r.Salary__c,
                    Contractor__r.Joining_Date__c,
                    Contractor__r.Exit_Date__c
                FROM Account
                WHERE Id IN :personAccountIdSet
                LIMIT 10000
            ];

            Map<Id, PayslipInfo> accountIdToPayslipInfoMap = mapAccountIdToPayslipInfo(contractorAccountList);
            Date dateRange = Date.newInstance(year, month, 1);
            Payroll_Component__c[] payrollComponentList = getPayrollComponentsOnDate(dateRange, personAccountIdSet);
            Map<Id, Payroll_Component__c[]> accountIdToPayrollComponentsMap = mapAccountIdToPayrollComponents(payrollComponentList);
            Map<String, PayslipInfo[]> resourceTypeToPayslipInfosMap = mapResourceTypeToPayslipInfos(accountIdToPayslipInfoMap, accountIdToPayrollComponentsMap);
            PayslipPart[] payslipPartList = createPayslipParts(resourceTypeToPayslipInfosMap);

            response.setResult(JSON.serialize(payslipPartList));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_PayslipGenerationController.class));
        }

        return response;
    }

    private static void setMaxSalaryTransitionDateByUser() {
        // set default value
        maxSalaryTransitionDate = Date.newInstance(DATE_NOW.year(), DATE_NOW.month(), 20);
        PayrollDateRulesService.PayrollBlockingDaysInfo payrollBlockingDaysInfo = new PayrollDateRulesService().getBlockingDaysInfoByUserAndUserRoleIds(
            UserInfo.getUserId(),
            UserInfo.getUserRoleId()
        );

        // leave the default if no setting is assigned to the current user
        if ( !payrollBlockingDaysInfo.isAvailable() || payrollBlockingDaysInfo.getSalaryTransitionDay() == null) return;

        // set value from settings
        maxSalaryTransitionDate = Date.newInstance(DATE_NOW.year(), DATE_NOW.month(), (Integer)payrollBlockingDaysInfo.getSalaryTransitionDay());
    }

    /**
    * @description Get working days in a month for each station based on date.
    *
    * @param firstDayOfMonth Date on 1st day of the month.
    *
    * @return Map with key: station | value: total working days
    */
    private static Map<String, Integer> mapStationToWorkingDaysForMonth(Date firstDayOfMonth) {
        Map<String, Integer> stationToWorkingDaysMap = new Map<String, Integer>();
        Date lastDayOfMonth = DateUtils.getLastDayOfMonth(firstDayOfMonth);
        Map<String, Integer> countryPrefixToWorkingDaysMap = new Map<String, Integer>();

        for (String countryPrefix : countryPrefixToHolidayDatesMap.keySet()) {
            Set<Date> holidaysSet = countryPrefixToHolidayDatesMap.get(countryPrefix);
            Integer workingDays = 0;

            for (Integer i = 0; i <= firstDayOfMonth.daysBetween(lastDayOfMonth); i++) {
                Date nextWorkingDate = firstDayOfMonth + i;
                Integer weekdayNumber = DateUtils.getWeekdayNumberFromDate(nextWorkingDate);

                if ( // skip on saturday, sunday and public holidays
                    weekdayNumber != 6
                    && weekdayNumber != 7
                    && (holidaysSet == null || !holidaysSet.contains(nextWorkingDate))
                ) {
                    workingDays++;
                }
            }

            countryPrefixToWorkingDaysMap.put(countryPrefix, workingDays);
        }

        for (String station : stationToCountryPrefixMap.keySet()) {
            String countryPrefix = stationToCountryPrefixMap.get(station);

            stationToWorkingDaysMap.put(station, countryPrefixToWorkingDaysMap.get(countryPrefix));
        }

        return stationToWorkingDaysMap;
    }
        
    private static Set<Id> getContractorPersonAccountIds(SelectedContractorInfo[] contractorList) {
        Set<Id> contractorAccountIdSet = new Set<Id>();

        for (SelectedContractorInfo contractorInfo : contractorList) {
            contractorAccountIdSet.add(contractorInfo.personAccountId);
        }

        return contractorAccountIdSet;
    }

    private static Payroll_Component__c[] getPayrollComponentsOnDate(Date dateRange, Set<Id> contractorAccountIdSet) {
        Payroll_Component__c[] payrollComponentList = new Payroll_Component__c[]{};

        Payroll_Component__c[] ordinaryPayrollComponentList = getOrdinaryPayrollComponentsOnDate(dateRange, contractorAccountIdSet);
        Payroll_Component__c[] recurrentPayrollComponentList = getRecurrentPayrollComponentsInRange(dateRange, contractorAccountIdSet);

        payrollComponentList.addAll(ordinaryPayrollComponentList);
        payrollComponentList.addAll(recurrentPayrollComponentList);

        return payrollComponentList;
    }

    private static Payroll_Component__c[] getOrdinaryPayrollComponentsOnDate(Date dateRange, Set<Id> contractorAccountIdSet) {
        return [
            SELECT RecordType.Name,
                Account__c,
                Recurrent__c,
                CurrencyIsoCode,
                SumType__c,
                Sum__c,
                Reason__c,
                SystemModstamp,
                StartDate__c,
                EndDate__c
            FROM Payroll_Component__c
            WHERE Account__c IN :contractorAccountIdSet
            AND Approval_Status__c = :PC_APPROVAL_STATUS_APPROVED
            AND Recurrent__c = FALSE
            AND Payroll_Component_Template__c = NULL
            AND Adjustment_Type__c <> :PC_ADJUSTMENT_TYPE_SALARY_ADJUSTMENT
            AND SumType__c <> NULL
            AND Sum__c <> NULL
            AND StartDate__c >= :dateRange
            AND StartDate__c <= :DateUtils.getLastDayOfMonth(dateRange)
        ];
    }

    private static Payroll_Component__c[] getRecurrentPayrollComponentsInRange(Date dateRange, Set<Id> contractorAccountIdSet) {
        return [
            SELECT RecordType.Name,
                Account__c,
                Recurrent__c,
                CurrencyIsoCode,
                SumType__c,
                Sum__c,
                Reason__c,
                SystemModstamp,
                StartDate__c,
                EndDate__c
            FROM Payroll_Component__c
            WHERE Account__c IN :contractorAccountIdSet
            AND Approval_Status__c = :PC_APPROVAL_STATUS_APPROVED
            AND Recurrent__c = TRUE
            AND SumType__c <> NULL
            AND Sum__c <> NULL
            AND StartDate__c <= :dateRange
            AND EndDate__c > :dateRange
        ];
    }

    private static Payroll_Component__c[] getRecurrentPayrollComponentsByIds(Set<Id> recurrentPayrollComponentIdSet) {
        return [
            SELECT RecordTypeId,
                RecordType.DeveloperName,
                Account__c,
                Contractor__c,
                CurrencyIsoCode,
                SumType__c,
                Sum__c,
                Reason__c
            FROM Payroll_Component__c
            WHERE Id IN :recurrentPayrollComponentIdSet
            LIMIT 10000
            FOR UPDATE
        ];
    }

    private static Payroll_Component__c[] getExistingPayrollComponentsByRecurrentIds(Date startMonthDate, Set<Id> recurrentPayrollComponentIdSet) {

        return [
            SELECT Payroll_Component_Template__c,
                RecordTypeId,
                RecordType.DeveloperName,
                Payroll__c,
                Account__c,
                Contractor__c,
                CurrencyIsoCode,
                SumType__c,
                Sum__c,
                Reason__c,
                Recurrent__c
            FROM Payroll_Component__c
            WHERE Payroll_Component_Template__c IN :recurrentPayrollComponentIdSet
            AND StartDate__c = :startMonthDate
            AND EndDate__c = :startMonthDate
            LIMIT 10000
            FOR UPDATE
        ];
    }

    private static Payroll_Component__c[] getExistingPCsForSalaryChange(Date startMonthDate, Set<Id> contractorAccountIdSet) {

        return [
            SELECT
                Id
            FROM Payroll_Component__c
            WHERE Account__c IN :contractorAccountIdSet
            AND RecordTypeId = :PC_RT_ADJUSTMENTS_ID
            AND Adjustment_Type__c = :PC_ADJUSTMENT_TYPE_SALARY_ADJUSTMENT
            AND StartDate__c = :startMonthDate
            AND EndDate__c = :startMonthDate
            LIMIT 10000
            FOR UPDATE
        ];
    }

    private static Map<Id, Payroll_Component__c[]> mapAccountIdToPayrollComponents(Payroll_Component__c[] payrollComponentList) {
        Map<Id, Payroll_Component__c[]> accountIdToPayrollComponentsMap = new Map<Id, Payroll_Component__c[]>();

        for (Payroll_Component__c payrollComponent : payrollComponentList) {

            if (!accountIdToPayrollComponentsMap.containsKey(payrollComponent.Account__c)) {
                accountIdToPayrollComponentsMap.put(payrollComponent.Account__c, new Payroll_Component__c[]{});
            }

            accountIdToPayrollComponentsMap.get(payrollComponent.Account__c).add(payrollComponent);
        }

        return accountIdToPayrollComponentsMap;
    }

    private static Map<Id, PayslipInfo> mapAccountIdToPayslipInfo(Account[] contractorAccountList) {
        Map<Id, PayslipInfo> accountIdToPayslipInfosMap = new Map<Id, PayslipInfo>();

        for (Account personAccount : contractorAccountList) {
            accountIdToPayslipInfosMap.put(personAccount.Id, new PayslipInfo(personAccount));
        }

        return accountIdToPayslipInfosMap;
    }

    private static Map<String, PayslipInfo[]> mapResourceTypeToPayslipInfos(Map<Id, PayslipInfo> accountIdToPayslipInfoMap, Map<Id, Payroll_Component__c[]> accountIdToPayrollComponentsMap) {
        Map<String, PayslipInfo[]> resourceTypeToPayslipInfosMap = new Map<String, PayslipInfo[]>();
        Util_DatedCurrencyConverter datedCurrencyConverter = new Util_DatedCurrencyConverter();

        for (Id personAccountId : accountIdToPayslipInfoMap.keySet()) {
            PayslipInfo payslipInfo = accountIdToPayslipInfoMap.get(personAccountId);
            Payroll_Component__c[] payrollComponentList = accountIdToPayrollComponentsMap.get(personAccountId);

            payslipInfo.addInfoFromPayrollComponents(datedCurrencyConverter, payrollComponentList);

            if (!resourceTypeToPayslipInfosMap.containsKey(payslipInfo.contractorInfo.resourceType)) {
                resourceTypeToPayslipInfosMap.put(payslipInfo.contractorInfo.resourceType, new PayslipInfo[]{});
            }

            resourceTypeToPayslipInfosMap.get(payslipInfo.contractorInfo.resourceType).add(payslipInfo);
        }

        return resourceTypeToPayslipInfosMap;
    }

    private static Map<String, PayslipInfo[]> mapResourceTypeToPayslipInfos(PayslipInfo[] payslipInfoList) {
        Map<String, PayslipInfo[]> resourceTypeToPayslipInfosMap = new Map<String, PayslipInfo[]>();

        for (PayslipInfo payslipInfo : payslipInfoList) {

            if (!resourceTypeToPayslipInfosMap.containsKey(payslipInfo.contractorInfo.resourceType)) {
                resourceTypeToPayslipInfosMap.put(payslipInfo.contractorInfo.resourceType, new PayslipInfo[]{});
            }

            resourceTypeToPayslipInfosMap.get(payslipInfo.contractorInfo.resourceType).add(payslipInfo);
        }

        return resourceTypeToPayslipInfosMap;
    }

    private static PayslipPart[] createPayslipParts(Map<String, PayslipInfo[]> resourceTypeToPayslipInfosMap) {
        PayslipPart[] payslipPartList = new PayslipPart[]{};

        for (String resourceType : resourceTypeToPayslipInfosMap.keySet()) {
            PayslipPart payslipPart = new PayslipPart();
            payslipPart.resourceType = resourceType;
            payslipPart.payslipInfoList = resourceTypeToPayslipInfosMap.get(resourceType);

            payslipPartList.add(payslipPart);
        }

        return payslipPartList;
    }

    // SALARY CHANGE CALCULATION
    //############################################################################################################################################

    private static final Integer WORKING_HOURS_PER_DAY = 8;
    private static Map<String, String> stationToCountryPrefixMap = new Map<String, String>();
    private static Map<String, Set<Date>> countryPrefixToHolidayDatesMap = new Map<String, Set<Date>>();

    private static void createHelperMapsForCalculatingWorkingDays() {
        Set<String> countryPrefixSet = new Set<String>();

        for (Station_by_Country_prefix__mdt stationByCountryPrefix : getStationByCountryPrefixes()) {
            countryPrefixSet.add(stationByCountryPrefix.Country_prefix__c);
            stationToCountryPrefixMap.put(stationByCountryPrefix.Station__c, stationByCountryPrefix.Country_prefix__c);
        }

        for (String countryPrefix : countryPrefixSet) {
            countryPrefixToHolidayDatesMap.put(countryPrefix, new Set<Date>());
        }

        for (Holiday holiday : getHolidays()) {

            if (holiday.Name.contains('_')) {
                String countryPrefix = holiday.Name.substring(0, holiday.Name.indexOf('_'));

                if (countryPrefixToHolidayDatesMap.containsKey(countryPrefix)) {
                    countryPrefixToHolidayDatesMap.get(countryPrefix).add(holiday.ActivityDate);
                }
            }
        }
    }

    private static List<Station_by_Country_prefix__mdt> getStationByCountryPrefixes() {
        return [
            SELECT
                Station__c,
                Country_prefix__c
            FROM Station_by_Country_prefix__mdt
        ];
    }

    private static List<Holiday> getHolidays() {
        return [
            SELECT
                Name,
                ActivityDate
            FROM Holiday
        ];
    }

    //############################################################################################################################################
    //############################################################################################################################################
    //############################################################################################################################################

    @AuraEnabled
    public static LightningResponse isUserBlockedForGeneration() {
        LightningResponse response = new LightningResponse();

        try {
            response.setResult(JSON.serialize(isBlockedForGenerationBasedOnUser()));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_PayslipGenerationController.class));
        }

        return response;
    }

    private static Boolean isBlockedForGenerationBasedOnUser() {
        PayrollDateRulesService.PayrollBlockingDaysInfo payrollBlockingDaysInfo = new PayrollDateRulesService().getBlockingDaysInfoByUserAndUserRoleIds(
            UserInfo.getUserId(),
            UserInfo.getUserRoleId()
        );

        // to avoid dependence on settings
        if (Test.isRunningTest()) return false;

        // block if there is no setting for the current user or the day is not specified
        if ( !payrollBlockingDaysInfo.isAvailable() || payrollBlockingDaysInfo.getPayrollDay() == null) return true;

        // block if current day greater than day from settings
        return DATE_NOW.day() > payrollBlockingDaysInfo.getPayrollDay();
    }

    //############################################################################################################################################
    //############################################################################################################################################
    //############################################################################################################################################

    /**
     * @description Wrapper with information about selected Contractor.
     */
    public class SelectedContractorInfo {

        public Id personAccountId;
    }

    public class PayslipPart {

        public String id;
        public String resourceType;
        public PayslipInfo[] payslipInfoList = new PayslipInfo[]{};
        public final Boolean isAccordionOpen = true;
        public final Boolean isDisabled = false;
        public final Boolean isAllToDelete = false;

        {
            this.id = String.valueOf(Crypto.getRandomLong());
        }
    }

    public class PayslipInfo {

        public String id;
        public Long lastUpdateTimestamp;
        public ContractorInfo contractorInfo;
        public PayrollComponentInfo[] payrollComponentInfoList = new PayrollComponentInfo[]{};
        public Boolean isToDelete = false;
        public final Boolean isAccordionOpen = true;

        public PayslipInfo(Account contractorPersonAccount) {
            // TODO: move to here payslipInfo.addInfoFromPayrollComponents()
            this.contractorInfo = new ContractorInfo(contractorPersonAccount);
        }

        public PayslipInfo(Payroll__c payroll) {
            this.id = payroll.Id;
            this.lastUpdateTimestamp = payroll.SystemModstamp.getTime();
            this.contractorInfo = new ContractorInfo(payroll);
            addInfoFromPayrollComponents(payroll.Payroll_Components__r);
        }

        public void addInfoFromPayrollComponents(Util_DatedCurrencyConverter datedCurrencyConverter, Payroll_Component__c[] payrollComponentList) {

            if (payrollComponentList == null || contractorInfo.isBlockedByJoiningDate) return;

            for (Payroll_Component__c payrollComponent : payrollComponentList) {
                PayrollComponentInfo payrollComponentInfo = new PayrollComponentInfo().addInfoForCurrentPeriod(payrollComponent);
                contractorInfo.changeTotalSalaryBasedOnPayrollComponent(datedCurrencyConverter, payrollComponentInfo);

                this.payrollComponentInfoList.add(payrollComponentInfo);
            }

            // round up after all calculations
            this.contractorInfo.totalSalary = this.contractorInfo.totalSalary.setScale(2, RoundingMode.HALF_UP);
        }

        public void addInfoFromPayrollComponents(Payroll_Component__c[] payrollComponentList) {

            if (payrollComponentList == null) return;

            for (Payroll_Component__c payrollComponent : payrollComponentList) {
                this.payrollComponentInfoList.add(new PayrollComponentInfo().addInfoForPreviousPeriod(payrollComponent));
            }
        }
    }

    /**
     * @description Wrapper with information about Contractor.
     */
    public class ContractorInfo {

        public Id id;
        public Id personAccountId;
        public String name;
        public String resourceType;
        public String station;
        public Date joiningDate;
        public Date exitDate;
        public String currencyIsoCode;
        public Decimal salary;
        public Decimal totalSalary;
        public Boolean isBlockedByJoiningDate = false;
        public Boolean hasSalaryChangeByJoiningDate = false;
        public Boolean hasSalaryChangeByExitDate = false;
        public SalaryChangeInfo salaryChangeInfo;

        public ContractorInfo(Account personAccount) {
            this.id = personAccount.Contractor__r.Id;
            this.personAccountId = personAccount.Id;
            this.name = personAccount.Name;
            this.resourceType = personAccount.Resource_Type__c;
            this.station = personAccount.Station__c;
            this.joiningDate = personAccount.Contractor__r.Joining_Date__c;
            this.exitDate = personAccount.Contractor__r.Exit_Date__c;
            this.currencyIsoCode = personAccount.Contractor__r.CurrencyIsoCode;
            this.salary = personAccount.Contractor__r.Salary__c != null ? personAccount.Contractor__r.Salary__c : 0;
            this.totalSalary = this.salary;
            this.isBlockedByJoiningDate = personAccount.Contractor__r.Joining_Date__c > maxSalaryTransitionDate;
            this.hasSalaryChangeByJoiningDate = this.hasSalaryChangeByJoiningDate(personAccount);
            this.hasSalaryChangeByExitDate = this.hasSalaryChangeByExitDate(personAccount);

            if (this.isBlockedByJoiningDate || this.hasSalaryChangeByJoiningDate || this.hasSalaryChangeByExitDate) {
                this.salaryChangeInfo = new SalaryChangeInfo(this);
                this.changeTotalSalaryBasedOnPayrollComponent(salaryChangeInfo.payrollComponentInfo, salaryChangeInfo.payrollComponentInfo.sum);
                this.totalSalary = this.isBlockedByJoiningDate ? 0 : this.totalSalary;
            }
        }

        public ContractorInfo(Payroll__c payroll) {
            this.personAccountId = payroll.Account__c;
            this.name = payroll.Account__r.Name;
            this.resourceType = payroll.Account__r.Resource_Type__c;
            this.currencyIsoCode = payroll.CurrencyIsoCode;
            this.salary = payroll.Salary__c;
            this.totalSalary = payroll.Sum__c;
        }

        public void changeTotalSalaryBasedOnPayrollComponent(Util_DatedCurrencyConverter datedCurrencyConverter, PayrollComponentInfo payrollComponentInfo) {
            Decimal convertedCurrency = datedCurrencyConverter.convertCurrencyToTodayRates(payrollComponentInfo.sum, payrollComponentInfo.currencyIsoCode, this.currencyIsoCode);

            this.changeTotalSalaryBasedOnPayrollComponent(payrollComponentInfo, convertedCurrency);
        }

        private void changeTotalSalaryBasedOnPayrollComponent(PayrollComponentInfo payrollComponentInfo, Decimal sum) {

            if (payrollComponentInfo.isIncrementSumType) {
                this.totalSalary += sum;
            }
            else {
                this.totalSalary -= sum;
            }
        }

        private Boolean hasSalaryChangeByJoiningDate(Account personAccount) {

            return (
                personAccount.Contractor__r.Joining_Date__c.month() == maxSalaryTransitionDate.addMonths(-1).month()
                && (personAccount.Contractor__r.Joining_Date__c.day() > maxSalaryTransitionDate.day())
            );
        }

        private Boolean hasSalaryChangeByExitDate(Account personAccount) {

            return (
                personAccount.Contractor__r.Exit_Date__c != null
                && personAccount.Contractor__r.Exit_Date__c.year() == DATE_NOW.year()
                && personAccount.Contractor__r.Exit_Date__c.month() == DATE_NOW.month()
            );
        }
    }

    public class SalaryChangeInfo {

        public transient Integer workingDays;
        public transient Integer workingHours;
        public PayrollComponentInfo payrollComponentInfo = new PayrollComponentInfo();

        public SalaryChangeInfo(ContractorInfo contractorInfo) {
            this.workingDays = this.getWorkingDays(contractorInfo);
            this.workingHours = this.workingDays * WORKING_HOURS_PER_DAY;

            this.payrollComponentInfo.recordTypeName = PC_RT_ADJUSTMENTS_NAME;
            this.payrollComponentInfo.currencyIsoCode = contractorInfo.currencyIsoCode;
            this.payrollComponentInfo.sum = this.calculateSalaryFromWorkingDays(contractorInfo);
            this.payrollComponentInfo.reason = this.getReasonByState(contractorInfo);
            this.payrollComponentInfo.isIncrementSumType = contractorInfo.hasSalaryChangeByJoiningDate || contractorInfo.isBlockedByJoiningDate;
            this.payrollComponentInfo.isDecrementSumType = contractorInfo.hasSalaryChangeByExitDate;
        }

        private Integer getWorkingDays(ContractorInfo contractorInfo) {
            Date fromDate = contractorInfo.hasSalaryChangeByExitDate
                            ? contractorInfo.exitDate
                            : contractorInfo.joiningDate;
            Date toDate = DateUtils.getLastDayOfMonth(fromDate);

            return this.getWorkingDaysByContractorStation(contractorInfo.station, fromDate, toDate);
        }

        private Integer getWorkingDaysByContractorStation(String station, Date fromDate, Date toDate) {
            Integer workingDays = 0;
            String countryPrefix = stationToCountryPrefixMap.get(station);
            Set<Date> holidaysSet = countryPrefixToHolidayDatesMap.get(countryPrefix);

            for (Integer i = 0, daysBetween = fromDate.daysBetween(toDate); i <= daysBetween; i++) {
                Date nextWorkingDate = fromDate + i;
                Integer weekdayNumber = DateUtils.getWeekdayNumberFromDate(nextWorkingDate);

                if ( // skip on saturday, sunday and public holidays
                    weekdayNumber != 6
                    && weekdayNumber != 7
                    && (holidaysSet == null || !holidaysSet.contains(nextWorkingDate))
                ) {
                    workingDays++;
                }
            }

            return workingDays;
        }

        private Decimal calculateSalaryFromWorkingDays(ContractorInfo contractorInfo) {
            Integer workingDays = contractorInfo.hasSalaryChangeByExitDate
                                  ? stationToWorkingDaysInCurrentMonth.get(contractorInfo.station)
                                  : stationToWorkingDaysInPreviousMonth.get(contractorInfo.station);

            Decimal dayCost = (contractorInfo.salary == null || contractorInfo.salary == 0) || (workingDays == null || workingDays == 0)
                              ? 0
                              : contractorInfo.salary / workingDays;

            return (dayCost * this.workingDays).setScale(2, RoundingMode.HALF_UP);
        }

        private String getReasonByState(ContractorInfo contractorInfo) {
            String reason;

            if (contractorInfo.isBlockedByJoiningDate) {
                reason = this.replaceKeywordsForReason(TXT_SALARY_REASON_FOR_JOINING_NEXT_MONTH);
            }
            else if (contractorInfo.hasSalaryChangeByJoiningDate) {
                reason = this.replaceKeywordsForReason(TXT_SALARY_REASON_FOR_JOINING_PREVIOUS_MONTH);
            }
            else if (contractorInfo.hasSalaryChangeByExitDate) {
                reason = this.replaceKeywordsForReason(TXT_SALARY_REASON_FOR_EXIT);
            }

            return reason;
        }

        private String replaceKeywordsForReason(String text) {
            text = text.replace(KEY_WORD_DAY_NUMBER, String.valueOf(this.workingDays));
            text = text.replace(KEY_WORD_HOUR_NUMBER, String.valueOf(this.workingHours));

            return text;
        }
    }

    public class PayrollComponentInfo {

        public Id id;
        public String recordTypeName;
        public String reason;
        public String currencyIsoCode;
        public String sumType;
        public Decimal sum;
        public Long lastUpdateTimestamp;
        public Boolean isRecurrent;
        public Boolean isFromRecurrent;
        public Boolean isIncrementSumType;
        public Boolean isDecrementSumType;

        public PayrollComponentInfo addInfoForCurrentPeriod(Payroll_Component__c payrollComponent) {
            this.id = payrollComponent.Id;
            this.recordTypeName = payrollComponent.RecordType.Name;
            this.reason = payrollComponent.Reason__c;
            this.currencyIsoCode = payrollComponent.CurrencyIsoCode;
            this.sumType = payrollComponent.SumType__c;
            this.sum = payrollComponent.Sum__c;
            this.lastUpdateTimestamp = payrollComponent.SystemModstamp.getTime();
            this.isRecurrent = payrollComponent.Recurrent__c;
            this.isIncrementSumType = (payrollComponent.SumType__c == PC_SUM_TYPE_INCREMENT);
            this.isDecrementSumType = (payrollComponent.SumType__c == PC_SUM_TYPE_DECREMENT);

            return this;
        }

        public PayrollComponentInfo addInfoForPreviousPeriod(Payroll_Component__c payrollComponent) {
            this.recordTypeName = payrollComponent.RecordType.Name;
            this.reason = payrollComponent.Reason__c;
            this.currencyIsoCode = payrollComponent.CurrencyIsoCode;
            this.sumType = payrollComponent.SumType__c;
            this.sum = payrollComponent.Sum__c;
            this.isFromRecurrent = String.isNotBlank(payrollComponent.Payroll_Component_Template__c);
            this.isIncrementSumType = (payrollComponent.SumType__c == PC_SUM_TYPE_INCREMENT);
            this.isDecrementSumType = (payrollComponent.SumType__c == PC_SUM_TYPE_DECREMENT);

            return this;
        }
    }

    /**
     * @description Wrapper for sending a response to a Lightning component
     */
    public class LightningResponse extends Model.LightningResponse {

        public void setResult(String data) {
            this.data = data;
            this.success = true;
        }

        public void setError(String message) {
            this.message = message;
            this.success = false;
        }

        public LightningResponse setError(Integer code) {
            this.code = code;
            this.success = false;
            return this;
        }
    }

    public class PayrollGenerationException extends Exception {

        public Integer errorCode;

        public PayrollGenerationException(Integer errorCode) {
            this.errorCode = errorCode;
        }
    }
}