@IsTest
private class LW_PayrollModificationControllerTest {

    @TestSetup static void createData() {
        Payroll_Component__c[] payrollComponentList = new Payroll_Component__c[]{};
        Id bonusRTId = PayrollComponentSelector.RECORD_TYPE_INFO_BONUS.getRecordTypeId();
        Id recurrentBonusRTId = PayrollComponentSelector.RECORD_TYPE_INFO_RECURRENT_BONUS.getRecordTypeId();
        Date startDate = Date.valueOf(Datetime.now()).toStartOfMonth();
        Date endDate = DateUtils.getLastDayOfMonth(Date.valueOf(Datetime.now()));

        payrollComponentList.add(new Payroll_Component__c(
            Reason__c = 'tRF',
            Recurrent__c = false,
            StartDate__c = startDate,
            RecordTypeId = bonusRTId
        ));

        payrollComponentList.add(new Payroll_Component__c(
            Reason__c = 'tRF',
            Recurrent__c = false,
            StartDate__c = startDate,
            RecordTypeId = bonusRTId
        ));

        payrollComponentList.add(new Payroll_Component__c(
            Reason__c = 'tRT',
            Recurrent__c = true,
            StartDate__c = startDate,
            EndDate__c = endDate,
            RecordTypeId = recurrentBonusRTId
        ));

        payrollComponentList.add(new Payroll_Component__c(
            Reason__c = 'tRT',
            Recurrent__c = true,
            StartDate__c = startDate,
            EndDate__c = endDate,
            RecordTypeId = recurrentBonusRTId
        ));

        insert payrollComponentList;
    }

    @IsTest static void test_getPayrollComponents() {
        Payroll_Component_Configurations__mdt payrollComponentConfigurations = createPayrollComponentConfigurations();
        Payroll_Component_Configuration_Field__mdt[] payrollComponentConfigurationFieldList = createPayrollComponentConfigurationFields();

        Map<String, LW_PayrollModificationController.PayslipContainerWrapper> payslipContainerWrappersByType = LW_PayrollModificationController.getPayrollComponents(payrollComponentConfigurations, payrollComponentConfigurationFieldList);

        System.assertEquals(
            'tRF',
            payslipContainerWrappersByType.get(LW_PayrollModificationController.NON_RECURRENT).payslipWrappers[0].reason
        );
    }

    @IsTest static void test_deletePayrollComponents() {
        Payroll_Component_Configurations__mdt payrollComponentConfigurations = createPayrollComponentConfigurations();
        Payroll_Component_Configuration_Field__mdt[] payrollComponentConfigurationFieldList = createPayrollComponentConfigurationFields();

        Map<String, LW_PayrollModificationController.PayslipContainerWrapper> payslipContainerWrappersByType = LW_PayrollModificationController.getPayrollComponents(payrollComponentConfigurations, payrollComponentConfigurationFieldList);
        Id pcToDeleteId = payslipContainerWrappersByType.get(LW_PayrollModificationController.NON_RECURRENT).payslipWrappers[0].Id;

        Test.startTest();
            LW_PayrollModificationController.deletePayrollComponents(new List<Id>{pcToDeleteId});
        Test.stopTest();

        System.assert(
            [
                SELECT Id
                FROM Payroll_Component__c
                WHERE Id = :pcToDeleteId
            ].isEmpty()
        );
    }

    @IsTest static void getPayrollComponentsSuccess() {
        Payroll_Component_Configurations__mdt payrollComponentConfigurations = createPayrollComponentConfigurations();
        Payroll_Component_Configuration_Field__mdt[] payrollComponentConfigurationFieldList = createPayrollComponentConfigurationFields();

        Map<String, LW_PayrollModificationController.PayslipContainerWrapper> payslipContainerWrappersByType = LW_PayrollModificationController.getPayrollComponents(payrollComponentConfigurations, payrollComponentConfigurationFieldList);
        Id pcToDeactivateId = payslipContainerWrappersByType.get(LW_PayrollModificationController.RECURRENT).payslipWrappers[0].Id;

        Test.startTest();
            LW_PayrollModificationController.deactivatePayrollComponents(new List<Id>{pcToDeactivateId});
        Test.stopTest();

        System.assertEquals(
            LW_PayrollModificationController.DEACTIVATED,
            [
                SELECT Approval_Status__c
                FROM Payroll_Component__c
                WHERE Id = :pcToDeactivateId
            ].Approval_Status__c
        );
    }

    static Payroll_Component_Configurations__mdt createPayrollComponentConfigurations() {

        return new Payroll_Component_Configurations__mdt(
            RecordType__c = PayrollComponentSelector.RECORD_TYPE_INFO_BONUS.getDeveloperName(),
            RecordType_recurrent__c = PayrollComponentSelector.RECORD_TYPE_INFO_RECURRENT_BONUS.getDeveloperName()
        );
    }

    static Payroll_Component_Configuration_Field__mdt[] createPayrollComponentConfigurationFields() {

        Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField_null_1 = new Payroll_Component_Configuration_Field__mdt(
            Title__c = 'Null 1',
            Recurrent_Only__c = false,
            Is_Hidden__c = false,
            Order__c = null
        );

        Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField_null_2 = new Payroll_Component_Configuration_Field__mdt(
            Title__c = 'Null 2',
            Recurrent_Only__c = false,
            Is_Hidden__c = false,
            Order__c = null
        );

        Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField_1 = new Payroll_Component_Configuration_Field__mdt(
            Title__c = 'Sum',
            Recurrent_Only__c = false,
            Is_Hidden__c = false,
            Order__c = 1
        );

        Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField_2 = new Payroll_Component_Configuration_Field__mdt(
            Title__c = 'Currency',
            Recurrent_Only__c = false,
            Is_Hidden__c = false,
            Order__c = 2
        );

        Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField_3 = new Payroll_Component_Configuration_Field__mdt(
            Title__c = 'Reason',
            Recurrent_Only__c = false,
            Is_Hidden__c = false,
            Order__c = 3
        );

        Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField_4 = new Payroll_Component_Configuration_Field__mdt(
            Title__c = 'Bonus start date',
            Recurrent_Only__c = false,
            Is_Hidden__c = false,
            Order__c = 4
        );

        Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField_5 = new Payroll_Component_Configuration_Field__mdt(
            Title__c = 'Bonus end date',
            Recurrent_Only__c = true,
            Is_Hidden__c = false,
            Order__c = 5
        );

        Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField_6 = new Payroll_Component_Configuration_Field__mdt(
            Title__c = 'Sum Type',
            Recurrent_Only__c = false,
            Is_Hidden__c = true,
            Order__c = 6
        );

        return new Payroll_Component_Configuration_Field__mdt[]{
            payrollComponentConfigurationField_null_1,
            payrollComponentConfigurationField_6,
            payrollComponentConfigurationField_5,
            payrollComponentConfigurationField_4,
            payrollComponentConfigurationField_1,
            payrollComponentConfigurationField_2,
            payrollComponentConfigurationField_3,
            payrollComponentConfigurationField_null_2
        };
    }

}