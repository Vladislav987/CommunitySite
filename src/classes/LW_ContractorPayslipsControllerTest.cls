@IsTest
private class LW_ContractorPayslipsControllerTest {

    @TestSetup static void createData() {
        Contractor__c contractor = ContractorTestDataFactory.createDefaultPortalContractor();
        User portalUser = [SELECT Employee_AccountId__c FROM User WHERE Name = :contractor.Name][0];

        Payroll__c payroll = new Payroll__c(
            Salary__c = 1000,
            Account__c = portalUser.Employee_AccountId__c,
            Contractor__c = contractor.Id,
            StartMonthDate__c = Date.newInstance(2000, 1, 1),
            SalaryDate__c = Date.newInstance(2000, 1, 1)
        );

        insert payroll;

        Payroll_Component__c pc1 = new Payroll_Component__c(
            Payroll__c = payroll.Id,
            Account__c = portalUser.Employee_AccountId__c,
            Contractor__c = contractor.Id,
            Sum__c = 500,
            Reason__c = 'Reason one'
        );

        Payroll_Component__c pc2 = new Payroll_Component__c(
            Payroll__c = payroll.Id,
            Account__c = portalUser.Employee_AccountId__c,
            Contractor__c = contractor.Id,
            Sum__c = 500,
            Reason__c = 'Reason two'
        );

        insert new Payroll_Component__c[]{ pc1, pc2 };
    }

    @IsTest static void test_getContractorPayslips() {
        User portalUser = [SELECT Id FROM User WHERE Name = :ContractorTestDataFactory.DEFAULT_CONTRACTOR_NAME LIMIT 1];

        System.runAs(portalUser) {
            Map<Integer, LW_ContractorPayslipsController.PayslipWrapper[]> payslipWrappersByYear = LW_ContractorPayslipsController.getContractorPayslips();

            System.assert(!payslipWrappersByYear.values().isEmpty());
            System.assertEquals(1000, payslipWrappersByYear.values()[0][0].Salary);
            System.assertEquals('Reason one', payslipWrappersByYear.values()[0][0].Payroll_Components[0].Reason);
            System.assertEquals('Reason two', payslipWrappersByYear.values()[0][0].Payroll_Components[1].Reason);
        }
    }
}