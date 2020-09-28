/**
 * Created by Lambru Dmytro on 10.08.2020.
 */

public inherited sharing class LA_PayslipGenerationSelector {

    private static final Id PC_RT_ADJUSTMENTS_ID = PayrollComponentSelector.RECORD_TYPE_INFO_ADJUSTMENTS.getRecordTypeId();
    private static final String PC_APPROVAL_STATUS_APPROVED = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
    private static final String PC_ADJUSTMENT_TYPE_SALARY_ADJUSTMENT = PayrollComponentSelector.ADJUSTMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.AdjustmentTypePicklistKey.SALARY_ADJUSTMENT);

    public Account[] getAccountsByIds(Set<Id> personAccountIdSet) {

        return [
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
    }

    public Payroll_Component__c[] getAllPCsOnDate(Date dateRange, Set<Id> accountIdSet) {
        Payroll_Component__c[] payrollComponentList = new Payroll_Component__c[]{};

        Payroll_Component__c[] ordinaryPayrollComponentList = getOrdinaryPCsOnDate(dateRange, accountIdSet);
        Payroll_Component__c[] recurrentPayrollComponentList = getRecurrentPCsInDateRange(dateRange, accountIdSet);

        payrollComponentList.addAll(ordinaryPayrollComponentList);
        payrollComponentList.addAll(recurrentPayrollComponentList);

        return payrollComponentList;
    }

    public Payroll__c[] getPayrollsWithPCsOnDate(Date dateRange, Set<Id> accountIdSet) {
        return [
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
            WHERE Account__c IN :accountIdSet
            AND StartMonthDate__c = :dateRange
            LIMIT 10000
        ];
    }

    public Payroll_Component__c[] getExistingPCsForSalaryChange(Date onDate, Set<Id> contractorAccountIdSet) {

        return [
            SELECT
                Id
            FROM Payroll_Component__c
            WHERE Account__c IN :contractorAccountIdSet
            AND RecordTypeId = :PC_RT_ADJUSTMENTS_ID
            AND Adjustment_Type__c = :PC_ADJUSTMENT_TYPE_SALARY_ADJUSTMENT
            AND StartDate__c = :onDate
            AND EndDate__c = :onDate
            LIMIT 10000
            FOR UPDATE
        ];
    }

    public Payroll_Component__c[] getPCsFromTemplateOnDate(Date onDate, Set<Id> accountIdSet) {

        return [
            SELECT StartDate__c,
                EndDate__c,
                Payroll_Component_Template__r.StartDate__c,
                Payroll_Component_Template__r.EndDate__c
            FROM Payroll_Component__c
            WHERE Account__c IN :accountIdSet
            AND StartDate__c = :onDate
            AND Payroll_Component_Template__c <> NULL
            LIMIT 10000
            FOR UPDATE
        ];
    }

    public Payroll__c[] getPayrollsWithPCsOnDateForDateValidation(Date onDate, Set<Id> accountIdSet) {

        return [
            SELECT StartMonthDate__c,
            (
                SELECT StartDate__c, Payroll__c
                FROM Payroll_Components__r
            )
            FROM Payroll__c
            WHERE Account__c IN :accountIdSet
            AND StartMonthDate__c = :onDate
            LIMIT 10000
            FOR UPDATE
        ];
    }

    public Payroll__c[] getExistingPayrollsOnDate(Date onDate, Set<Id> accountIdSet) {

        return [
            SELECT Account__c,
                Contractor__c,
                CurrencyIsoCode,
                Salary__c,
                Sum__c,
                SalaryDate__c,
                StartMonthDate__c
            FROM Payroll__c
            WHERE Account__c IN :accountIdSet
            AND RecordTypeId = :PayrollSelector.RECORD_TYPE_INFO_PAYROLL.getRecordTypeId()
            AND StartMonthDate__c = :onDate
            LIMIT 10000
        ];
    }

    public Payroll_Component__c[] getRecurrentPCsByIds(Set<Id> recurrentPCIdSet) {
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
            WHERE Id IN :recurrentPCIdSet
            LIMIT 10000
            FOR UPDATE
        ];
    }

    public Payroll_Component__c[] getPCsByRecurrentTemplateIds(Date onDate, Set<Id> recurrentPayrollComponentIdSet) {

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
            AND StartDate__c = :onDate
            AND EndDate__c = :onDate
            LIMIT 10000
            FOR UPDATE
        ];
    }

    public Payroll__c[] getPayrollsByAccountIds(Set<Id> accountIdSet) {

        return [
            SELECT Id
            FROM Payroll__c
            WHERE Account__c IN :accountIdSet
            AND StartMonthDate__c = :LA_PayslipGenerationController.DATE_NOW.toStartOfMonth()
            LIMIT 10000
        ];
    }

    public Payroll__c[] getPayrollsWithPCsForDeletion(Date onDate, Set<Id> accountIdSet) {

        return [
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
            WHERE Account__c IN :accountIdSet
            AND StartMonthDate__c = :onDate
            LIMIT 10000
            FOR UPDATE
        ];
    }

    /*##################################################*/
    /*################ PRIVATE METHODS #################*/
    /*##################################################*/

    private Payroll_Component__c[] getOrdinaryPCsOnDate(Date dateRange, Set<Id> accountIdSet) {
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
            WHERE Account__c IN :accountIdSet
            AND Approval_Status__c = :PC_APPROVAL_STATUS_APPROVED
            AND Recurrent__c = FALSE
            AND Payroll_Component_Template__c = NULL
            AND Adjustment_Type__c <> :PC_ADJUSTMENT_TYPE_SALARY_ADJUSTMENT
            AND SumType__c <> NULL
            AND Sum__c <> NULL
            AND StartDate__c >= :dateRange
            AND StartDate__c <= :DateUtils.getLastDayOfMonth(dateRange)
            LIMIT 10000
        ];
    }

    private Payroll_Component__c[] getRecurrentPCsInDateRange(Date dateRange, Set<Id> accountIdSet) {
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
            WHERE Account__c IN :accountIdSet
            AND Approval_Status__c = :PC_APPROVAL_STATUS_APPROVED
            AND Recurrent__c = TRUE
            AND SumType__c <> NULL
            AND Sum__c <> NULL
            AND StartDate__c <= :dateRange
            AND EndDate__c > :dateRange
            LIMIT 10000
        ];
    }
}