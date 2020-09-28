/**
 * Created by Lambru Dmytro on 22.07.2020.
 */

@IsTest
private class LW_ModifyPayrollControllerTest {

    @TestSetup
    static void doSetup() {
        createPayrollComponents();
    }

    @IsTest
    static void test_getLayoutConfigFields_pc_not_recurrent() {
        Payroll_Component_Configuration_Field__mdt[] payrollComponentConfigurationFields = createPayrollComponentConfigurationFields();
        Payroll_Component__c payrollComponent = [SELECT Id FROM Payroll_Component__c WHERE Recurrent__c = FALSE];

        Test.startTest();
        Model.LightningResponse response = LW_ModifyPayrollController.getLayoutConfigFields(payrollComponent.Id, payrollComponentConfigurationFields, false);
        Test.stopTest();

        assertSuccessLightningResponse(response);
        validateData(response);
    }

    @IsTest
    static void test_getLayoutConfigFields_pc_recurrent() {
        Payroll_Component_Configuration_Field__mdt[] payrollComponentConfigurationFields = createPayrollComponentConfigurationFields();
        Payroll_Component__c payrollComponent = [SELECT Id FROM Payroll_Component__c WHERE Recurrent__c = TRUE];

        Test.startTest();
            Model.LightningResponse response = LW_ModifyPayrollController.getLayoutConfigFields(payrollComponent.Id, payrollComponentConfigurationFields, false);
        Test.stopTest();

        assertSuccessLightningResponse(response);
        validateData(response);
    }

    @IsTest
    static void test_getLayoutConfigFields_pc_recurrent_isReadOnlyMode() {
        Payroll_Component_Configuration_Field__mdt[] payrollComponentConfigurationFields = createPayrollComponentConfigurationFields();
        Payroll_Component__c payrollComponent = [SELECT Id FROM Payroll_Component__c WHERE Recurrent__c = TRUE];

        Test.startTest();
            Model.LightningResponse response = LW_ModifyPayrollController.getLayoutConfigFields(payrollComponent.Id, payrollComponentConfigurationFields, true);
        Test.stopTest();

        assertSuccessLightningResponse(response);
        validateData(response);
    }

    static void assertSuccessLightningResponse(Model.LightningResponse response) {
        System.assert(response.success, 'Response must be successful. RESPONSE: ' + JSON.serializePretty(response));
    }

    static void validateData(Model.LightningResponse response) {
        LW_ModifyPayrollController.LayoutConfigFields[] layoutConfigFieldsList = (LW_ModifyPayrollController.LayoutConfigFields[]) JSON.deserialize(response.data, LW_ModifyPayrollController.LayoutConfigFields[].class);

        for (LW_ModifyPayrollController.LayoutConfigFields layoutConfigFields : layoutConfigFieldsList) {
            System.assert(layoutConfigFields.label != null, 'Value must not be null.');
            System.assert(layoutConfigFields.value != null, 'Value must not be null.');
            System.assert(layoutConfigFields.isInputType != null, 'Value must not be null.');
            System.assert(layoutConfigFields.order != null, 'Value must not be null.');
        }
    }

    static Payroll_Component_Configuration_Field__mdt[] createPayrollComponentConfigurationFields() {

        Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField_1 = new Payroll_Component_Configuration_Field__mdt(
            Title__c = 'Sum',
            Field_API_Name__c = 'Sum__c',
            Recurrent_Only__c = false,
            Is_Hidden__c = false,
            Order__c = 1
        );

        Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField_2 = new Payroll_Component_Configuration_Field__mdt(
            Title__c = 'Currency',
            Field_API_Name__c = 'CurrencyIsoCode',
            Recurrent_Only__c = false,
            Is_Hidden__c = false,
            Order__c = 2
        );

        Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField_3 = new Payroll_Component_Configuration_Field__mdt(
            Title__c = 'Reason',
            Field_API_Name__c = 'Reason__c',
            Recurrent_Only__c = false,
            Is_Hidden__c = false,
            Order__c = 3
        );

        Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField_4 = new Payroll_Component_Configuration_Field__mdt(
            Title__c = 'Bonus start date',
            Field_API_Name__c = 'StartDate__c',
            Recurrent_Only__c = false,
            Is_Hidden__c = false,
            Order__c = 4
        );

        Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField_5 = new Payroll_Component_Configuration_Field__mdt(
            Title__c = 'Bonus end date',
            Field_API_Name__c = 'EndDate__c',
            Recurrent_Only__c = true,
            Is_Hidden__c = false,
            Order__c = 5
        );

        Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField_6 = new Payroll_Component_Configuration_Field__mdt(
            Title__c = 'Sum Type',
            Field_API_Name__c = 'SumType__c',
            Recurrent_Only__c = false,
            Is_Hidden__c = true,
            Order__c = 6
        );

        return new Payroll_Component_Configuration_Field__mdt[]{
            payrollComponentConfigurationField_1,
            payrollComponentConfigurationField_2,
            payrollComponentConfigurationField_3,
            payrollComponentConfigurationField_4,
            payrollComponentConfigurationField_5,
            payrollComponentConfigurationField_6
        };
    }

    static void createPayrollComponents() {
        Payroll_Component__c[] payrollComponentList = new Payroll_Component__c[]{};
        Id bonusRTId = PayrollComponentSelector.RECORD_TYPE_INFO_BONUS.getRecordTypeId();
        Id recurrentBonusRTId = PayrollComponentSelector.RECORD_TYPE_INFO_RECURRENT_BONUS.getRecordTypeId();
        Date startDate = Date.valueOf(Datetime.now()).toStartOfMonth();
        Date endDate = DateUtils.getLastDayOfMonth(Date.valueOf(Datetime.now()));

        payrollComponentList.add(new Payroll_Component__c(
            Reason__c = 'Test reason',
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

        insert payrollComponentList;
    }
}