public without sharing class LW_ContractorPayslipsController {

    private static final String INCREMENT = 'Increment';
    private static final String DECREMENT = 'Decrement';
    private static final String ERROR_MESSAGE = 'Sorry, something went wrong. Please contact your administrator.';

    private static final Map<Integer, String> MONTH_NUMBER_TO_NAME = new Map<Integer, String>{
            1 => 'January'
            , 2 => 'February'
            , 3 => 'March'
            , 4 => 'April'
            , 5 => 'May'
            , 6 => 'June'
            , 7 => 'July'
            , 8 => 'August'
            , 9 => 'September'
            , 10 => 'October'
            , 11 => 'November'
            , 12 => 'December'
    };

    @AuraEnabled(Cacheable=true)
    public static Map<Integer, PayslipWrapper[]> getContractorPayslips() {
        Map<Integer, PayslipWrapper[]> payslipWrappersByYear = new Map<Integer, PayslipWrapper[]>();

        try {
            for (Payroll__c payroll : getPayrolls()) {
                PayslipWrapper payslipWrapper = new PayslipWrapper();

                payslipWrapper.month = MONTH_NUMBER_TO_NAME.get(payroll.StartMonthDate__c.month());
                payslipWrapper.Id = payroll.Id;
                payslipWrapper.Sum = payroll.Sum__c;
                payslipWrapper.CurrencyIsoCode = payroll.CurrencyIsoCode;
                payslipWrapper.SalaryDate = payroll.SalaryDate__c;
                payslipWrapper.Salary = payroll.Salary__c;
                payslipWrapper.Payroll_Components = new List<PayslipComponentWrapper>();

                for (Payroll_Component__c payrollComponent : payroll.Payroll_Components__r) {
                    PayslipComponentWrapper payslipComponentWrapper = new PayslipComponentWrapper();

                    payslipComponentWrapper.Name = payrollComponent.RecordType.Name;
                    payslipComponentWrapper.Reason = payrollComponent.Reason__c;
                    payslipComponentWrapper.SumType = payrollComponent.SumType__c;
                    payslipComponentWrapper.Sum = payrollComponent.Sum__c;
                    payslipComponentWrapper.increment = INCREMENT;
                    payslipComponentWrapper.decrement = DECREMENT;

                    payslipWrapper.Payroll_Components.add(payslipComponentWrapper);
                }

                Integer salaryYear = payroll.SalaryDate__c.year();
                List<PayslipWrapper> payslips = payslipWrappersByYear.containsKey(salaryYear)
                                                ? payslipWrappersByYear.get(salaryYear)
                                                : new List<PayslipWrapper>();

                payslips.add(payslipWrapper);
                payslipWrappersByYear.put(salaryYear, payslips);
            }

           return payslipWrappersByYear;
        }
        catch (Exception ex) {
            PayslipWrapper payslipWrapper = new PayslipWrapper();

            payslipWrapper.error = ex.getMessage();
            payslipWrapper.errorMessage = ERROR_MESSAGE;
            payslipWrappersByYear.put(400, new PayslipWrapper[]{payslipWrapper});

            return payslipWrappersByYear;
        }
    }
    
    public static List<Payroll__c> getPayrolls() {
        Payroll__c[] payrollList = new Payroll__c[]{};
        User currentUser = [SELECT Employee_AccountId__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        Account[] contractorPersonAccList = [
            SELECT Id
            FROM Account
            WHERE Id = :currentUser.Employee_AccountId__c
            LIMIT 1
        ];
        
        if (!contractorPersonAccList.isEmpty()) {
            payrollList = [
                SELECT
                Salary__c
                , Sum__c
                , CurrencyIsoCode
                , SalaryDate__c
                , StartMonthDate__c
                , (
                    SELECT
                    RecordType.Name
                    , CurrencyIsoCode
                    , SumType__c
                    , Sum__c
                    , Reason__c
                    FROM Payroll_Components__r
                )
                FROM Payroll__c
                WHERE Account__c = :contractorPersonAccList[0].Id
                ORDER BY SalaryDate__c ASC
                LIMIT 10000
            ];
        }

        return payrollList;
    }

    @TestVisible
    class PayslipWrapper {

        @AuraEnabled public Id Id;
        @AuraEnabled public String error;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String month;
        @AuraEnabled public Decimal Sum;
        @AuraEnabled public String CurrencyIsoCode;
        @AuraEnabled public Date SalaryDate;
        @AuraEnabled public Decimal Salary;
        @AuraEnabled public List<PayslipComponentWrapper> Payroll_Components;
    }

    class PayslipComponentWrapper {

        @AuraEnabled public String Name;
        @AuraEnabled public String Reason;
        @AuraEnabled public String increment;
        @AuraEnabled public String decrement;
        @AuraEnabled public String SumType;
        @AuraEnabled public Decimal Sum;
    }
}