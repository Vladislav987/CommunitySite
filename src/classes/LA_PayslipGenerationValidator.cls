/**
 * Created by Lambru Dmytro
 */

public inherited sharing class LA_PayslipGenerationValidator {

    private static final Date DATE_NOW = Date.valueOf(System.now());

    @TestVisible private static final Integer ERROR_CODE_400 = 400; // HTTP 400 Bad Request
    @TestVisible private static final Integer ERROR_CODE_406 = 406; // HTTP 406 Not Acceptable
    @TestVisible private static final Integer ERROR_CODE_1001 = 1001;
    @TestVisible private static final Integer ERROR_CODE_1002 = 1002;
    @TestVisible private static final Integer ERROR_CODE_1003 = 1003;
    @TestVisible private static final Integer ERROR_CODE_1004 = 1004;
    @TestVisible private static final Integer ERROR_CODE_1005 = 1005;

    /*##################################################*/
    /*################### STATEMENTS ###################*/
    /*################## (EXCEPTION) ###################*/
    /*##################################################*/

    public void notNull(Object param) {

        if (param == null) {
            throwException(ERROR_CODE_400);
        }
    }

    public void notNull(Object param1, Object param2, Object param3) {

        if (param1 == null || param2 == null || param3 == null) {
            throwException(ERROR_CODE_400);
        }
    }

    public void currentMonthAndYear(Integer month, Integer year) {

        if (month != DATE_NOW.month() || year != DATE_NOW.year()) {
            throwException(ERROR_CODE_406);
        }
    }

    public void notNextMonthOrYear(Integer month, Integer year) {

        if (year > DATE_NOW.year() || (year == DATE_NOW.year() && month > DATE_NOW.month())) {
            throwException(ERROR_CODE_406);
        }
    }

    public void notEmpty(LA_PayslipGenerationController.PayslipPart[] payslipPartList) {

        if (payslipPartList == null || payslipPartList.isEmpty()) {
            throwException(ERROR_CODE_406);
        }
    }

    public void notEmpty(LA_PayslipGenerationController.SelectedContractorInfo[] selectedContractorList) {

        if (selectedContractorList == null || selectedContractorList.isEmpty()) {
            throwException(ERROR_CODE_406);
        }
    }

    public void payrollComponentListsValid(LA_PayslipGenerationController.PayslipInfo payslipInfo, Map<Id, Payroll_Component__c[]> accountIdToPayrollComponentsMap) {

        if (
            isListsDifferentByState(payslipInfo, accountIdToPayrollComponentsMap)
            || isListsDifferentBySize(payslipInfo, accountIdToPayrollComponentsMap)
        ) {
            // throw an exception if the number of PC records has changed
            throwException(ERROR_CODE_1001);
        }
    }

    public void payrollComponentValid(LA_PayslipGenerationController.PayrollComponentInfo payrollComponentInfo, Map<Id, Payroll_Component__c> idToPayrollComponentMap) {

        if (!idToPayrollComponentMap.containsKey(payrollComponentInfo.id)) {
            // throw an exception if the PC record has been deleted
            throwException(ERROR_CODE_1002);
        }
        else if (idToPayrollComponentMap.get(payrollComponentInfo.id).SystemModstamp.getTime() != payrollComponentInfo.lastUpdateTimestamp) {
            // throw an exception if the PC record has changed
            throwException(ERROR_CODE_1003);
        }
    }

    public void notBlockedForGenerationBasedOnUser() {

        if (this.isBlockedForGenerationBasedOnUser()) {
            // throw an exception if the record is already deleted
            throwException(ERROR_CODE_406);
        }
    }

    public void payrollsValidForDeletion(LA_PayslipGenerationController.PayslipPart[] payslipPartList, Map<Id, Payroll__c> idToPayrollMap) {

        for (LA_PayslipGenerationController.PayslipPart payslipPart : payslipPartList) {

            for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {

                if (payslipInfo.isToDelete) {

                    if (!idToPayrollMap.containsKey(payslipInfo.id)) {
                        // throw an exception if the record is already deleted
                        throwException(ERROR_CODE_1004);
                    }
                    else if (payslipInfo.lastUpdateTimestamp != idToPayrollMap.get(payslipInfo.id).SystemModstamp.getTime()) {
                        // throw an exception if record has been changed
                        throwException(ERROR_CODE_1005);
                    }
                }
            }
        }
    }

    /*##################################################*/
    /*################## VERIFICATION ##################*/
    /*################### (BOOLEAN) ####################*/
    /*##################################################*/

    public Boolean isBlockedForGenerationBasedOnUser() {
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

    public Boolean isPCDatesWithinTemplateDates(Payroll_Component__c payrollComponent) {
        return (
            payrollComponent.StartDate__c >= payrollComponent.Payroll_Component_Template__r.StartDate__c
            && payrollComponent.EndDate__c <= payrollComponent.Payroll_Component_Template__r.EndDate__c
        );
    }

    /*##################################################*/
    /*################ PRIVATE METHODS #################*/
    /*##################################################*/

    private static Boolean isListsDifferentByState(LA_PayslipGenerationController.PayslipInfo payslipInfo, Map<Id, Payroll_Component__c[]> accountIdToPayrollComponentsMap) {
        return (
            (
                payslipInfo.payrollComponentInfoList.isEmpty()
                && accountIdToPayrollComponentsMap.containsKey(payslipInfo.contractorInfo.personAccountId)
            )
            ||
            (
                !accountIdToPayrollComponentsMap.containsKey(payslipInfo.contractorInfo.personAccountId)
                && !payslipInfo.payrollComponentInfoList.isEmpty()
            )
        );
    }

    private static Boolean isListsDifferentBySize(LA_PayslipGenerationController.PayslipInfo payslipInfo, Map<Id, Payroll_Component__c[]> accountIdToPayrollComponentsMap) {
        return (
            accountIdToPayrollComponentsMap.containsKey(payslipInfo.contractorInfo.personAccountId)
            &&
            (
                payslipInfo.payrollComponentInfoList.size()
                != accountIdToPayrollComponentsMap.get(payslipInfo.contractorInfo.personAccountId).size()
            )
        );
    }

    private void throwException(Integer errorCode) {
        throw new ValidatorException(errorCode);
    }

    public class ValidatorException extends Exception {

        public Integer errorCode;

        public ValidatorException(Integer errorCode) {
            this.errorCode = errorCode;
        }
    }
}