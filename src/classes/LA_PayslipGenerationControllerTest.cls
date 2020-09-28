/**
 * Created by Lambru Dmytro on 18.05.2020.
 */
@IsTest
private class LA_PayslipGenerationControllerTest {

    private static final String FAKE_EMAIL = 'fake.email@test.com';
    private static final String DEFAULT_REASON = 'Reason for test only!';
    private static final Date DEFAULT_DATE = Date.valueOf(System.now()).toStartOfMonth();
    private static final String SALARY_DATE_STRING = String.valueOf(DEFAULT_DATE.addMonths(1));
    private static final Integer RECURRENT_PAYROLL_COMPONENTS_PER_CONTRACTOR = 3;

    private static final String CORPORATE_CURRENCY_ISO_CODE = [SELECT IsoCode FROM CurrencyType WHERE IsCorporate = TRUE LIMIT 1].IsoCode;
    private static final String NOT_CORPORATE_CURRENCY_ISO_CODE = [SELECT IsoCode FROM CurrencyType WHERE IsCorporate = FALSE LIMIT 1].IsoCode;
    private static final String PAYROLL_COMPONENT_SUM_TYPE_INCREMENT = PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.SumTypePicklistKey.INCREMENT);
    private static final String PAYROLL_COMPONENT_SUM_TYPE_DECREMENT = PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.SumTypePicklistKey.DECREMENT);

    private static LA_PayslipGenerationController.SelectedContractorInfo[] SELECTED_CONTRACTOR_INFO_LIST {
        get {

            if (SELECTED_CONTRACTOR_INFO_LIST == null) {
                SELECTED_CONTRACTOR_INFO_LIST = getSelectedContractorInfos();
            }

            return SELECTED_CONTRACTOR_INFO_LIST;
        }

        set;
    }

    @TestSetup
    static void doSetup() {
        ContractorTestDataFactory.createPortalContractorsForPayslipGeneration();
        createPayrollComponentsForContractors();
        createDummyUser();
    }

    @IsTest
    static void test_getPayslipsByResourceType_errorCode_400() {

        Test.startTest();
            Model.LightningResponse response1 = LA_PayslipGenerationController.getPayslipsByResourceType(null, DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            System.assertEquals(false, response1.success, 'Response must not be successful.');
            System.assertEquals(400, response1.code, 'The error code must match.');

            Model.LightningResponse response2 = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), null, JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            System.assertEquals(false, response2.success, 'Response must not be successful.');
            System.assertEquals(400, response2.code, 'The error code must match.');

            Model.LightningResponse response3 = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), null);
            System.assertEquals(false, response3.success, 'Response must not be successful.');
            System.assertEquals(400, response3.code, 'The error code must match.');

            Model.LightningResponse response4 = LA_PayslipGenerationController.getPayslipsByResourceType(null, null, null);
            System.assertEquals(false, response4.success, 'Response must not be successful.');
            System.assertEquals(400, response4.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_getPayslipsByResourceType_errorCode_406() {

        Test.startTest();
            // not current month
            Model.LightningResponse response1 = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.addMonths(1).month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            System.assertEquals(false, response1.success, 'Response must not be successful.');
            System.assertEquals(406, response1.code, 'The error code must match.');

            // not current year
            Model.LightningResponse response2 = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.addYears(-1).year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            System.assertEquals(false, response2.success, 'Response must not be successful.');
            System.assertEquals(406, response2.code, 'The error code must match.');

            // invalid list with selected contractors
            Model.LightningResponse response3 = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), 'null');
            System.assertEquals(false, response3.success, 'Response must not be successful.');
            System.assertEquals(406, response3.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_getHistoricalPayslipsByResourceType_errorCode_400() {

        Test.startTest();
            Model.LightningResponse response1 = LA_PayslipGenerationController.getHistoricalPayslipsByResourceType(null, DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            System.assertEquals(false, response1.success, 'Response must not be successful.');
            System.assertEquals(400, response1.code, 'The error code must match.');

            Model.LightningResponse response2 = LA_PayslipGenerationController.getHistoricalPayslipsByResourceType(DEFAULT_DATE.month(), null, JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            System.assertEquals(false, response2.success, 'Response must not be successful.');
            System.assertEquals(400, response2.code, 'The error code must match.');

            Model.LightningResponse response3 = LA_PayslipGenerationController.getHistoricalPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), null);
            System.assertEquals(false, response3.success, 'Response must not be successful.');
            System.assertEquals(400, response3.code, 'The error code must match.');

            Model.LightningResponse response4 = LA_PayslipGenerationController.getHistoricalPayslipsByResourceType(null, null, null);
            System.assertEquals(false, response4.success, 'Response must not be successful.');
            System.assertEquals(400, response4.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_getHistoricalPayslipsByResourceType_errorCode_406() {

        Test.startTest();
            // next month
            Model.LightningResponse response1 = LA_PayslipGenerationController.getHistoricalPayslipsByResourceType(DEFAULT_DATE.addMonths(1).month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            System.assertEquals(false, response1.success, 'Response must not be successful.');
            System.assertEquals(406, response1.code, 'The error code must match.');

            // next year
            Model.LightningResponse response2 = LA_PayslipGenerationController.getHistoricalPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.addYears(1).year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            System.assertEquals(false, response2.success, 'Response must not be successful.');
            System.assertEquals(406, response2.code, 'The error code must match.');

            // invalid list with selected contractors
            Model.LightningResponse response3 = LA_PayslipGenerationController.getHistoricalPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), 'null');
            System.assertEquals(false, response3.success, 'Response must not be successful.');
            System.assertEquals(406, response3.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_generatePayslips_errorCode_400() {

        Test.startTest();
            Model.LightningResponse response1 = LA_PayslipGenerationController.generatePayslips(null,
                                                                                                DEFAULT_DATE.year(),
                                                                                                SALARY_DATE_STRING,
                                                                                                JSON.serialize(new LA_PayslipGenerationController.PayslipPart[]{}));
            System.assertEquals(false, response1.success, 'Response must not be successful.');
            System.assertEquals(400, response1.code, 'The error code must match.');

            Model.LightningResponse response2 = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(),
                                                                                                null,
                                                                                                SALARY_DATE_STRING,
                                                                                                JSON.serialize(new LA_PayslipGenerationController.PayslipPart[]{}));
            System.assertEquals(false, response2.success, 'Response must not be successful.');
            System.assertEquals(400, response2.code, 'The error code must match.');

            Model.LightningResponse response3 = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(),
                                                                                                DEFAULT_DATE.year(),
                                                                                                null,
                                                                                                JSON.serialize(new LA_PayslipGenerationController.PayslipPart[]{}));
            System.assertEquals(false, response3.success, 'Response must not be successful.');
            System.assertEquals(400, response3.code, 'The error code must match.');

            Model.LightningResponse response4 = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(),
                                                                                                DEFAULT_DATE.year(),
                                                                                                SALARY_DATE_STRING,
                                                                                                null);
            System.assertEquals(false, response4.success, 'Response must not be successful.');
            System.assertEquals(400, response4.code, 'The error code must match.');

            Model.LightningResponse response5 = LA_PayslipGenerationController.generatePayslips(null, null, null, null);
            System.assertEquals(false, response5.success, 'Response must not be successful.');
            System.assertEquals(400, response5.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_generatePayslips_errorCode_406() {

        Test.startTest();
            // next month
            Model.LightningResponse response1 = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.addMonths(1).month(),
                                                                                                DEFAULT_DATE.year(),
                                                                                                SALARY_DATE_STRING,
                                                                                                JSON.serialize(new LA_PayslipGenerationController.PayslipPart[]{}));
            System.assertEquals(false, response1.success, 'Response must not be successful.');
            System.assertEquals(406, response1.code, 'The error code must match.');

            // previous year
            Model.LightningResponse response2 = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(),
                                                                                                DEFAULT_DATE.addYears(-1).year(),
                                                                                                SALARY_DATE_STRING,
                                                                                                JSON.serialize(new LA_PayslipGenerationController.PayslipPart[]{}));
            System.assertEquals(false, response2.success, 'Response must not be successful.');
            System.assertEquals(406, response2.code, 'The error code must match.');

            // invalid salary date year
            String salaryDateOnPast = String.valueOf(Date.valueOf(SALARY_DATE_STRING).addMonths(-1));

            Model.LightningResponse response3 = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(),
                                                                                                DEFAULT_DATE.year(),
                                                                                                salaryDateOnPast,
                                                                                                JSON.serialize(new LA_PayslipGenerationController.PayslipPart[]{}));
            System.assertEquals(false, response3.success, 'Response must not be successful.');
            System.assertEquals(406, response3.code, 'The error code must match.');

            // invalid list
            Model.LightningResponse response4 = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, 'null');
            System.assertEquals(false, response4.success, 'Response must not be successful.');
            System.assertEquals(406, response4.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_isPayrollExistsForContractors_errorCode_400() {

        Test.startTest();
            Model.LightningResponse response1 = LA_PayslipGenerationController.isPayrollExistsForContractors(null, DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            System.assertEquals(false, response1.success, 'Response must not be successful.');
            System.assertEquals(400, response1.code, 'The error code must match.');

            Model.LightningResponse response2 = LA_PayslipGenerationController.isPayrollExistsForContractors(DEFAULT_DATE.month(), null, JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            System.assertEquals(false, response2.success, 'Response must not be successful.');
            System.assertEquals(400, response2.code, 'The error code must match.');

            Model.LightningResponse response3 = LA_PayslipGenerationController.isPayrollExistsForContractors(DEFAULT_DATE.month(), DEFAULT_DATE.year(), null);
            System.assertEquals(false, response3.success, 'Response must not be successful.');
            System.assertEquals(400, response3.code, 'The error code must match.');

            Model.LightningResponse response4 = LA_PayslipGenerationController.isPayrollExistsForContractors(null, null, null);
            System.assertEquals(false, response4.success, 'Response must not be successful.');
            System.assertEquals(400, response4.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_isPayrollExistsForContractors_errorCode_406() {

        Test.startTest();
            // not current month
            Model.LightningResponse response1 = LA_PayslipGenerationController.isPayrollExistsForContractors(DEFAULT_DATE.addMonths(1).month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            System.assertEquals(false, response1.success, 'Response must not be successful.');
            System.assertEquals(406, response1.code, 'The error code must match.');

            // not current year
            Model.LightningResponse response2 = LA_PayslipGenerationController.isPayrollExistsForContractors(DEFAULT_DATE.month(), DEFAULT_DATE.addYears(-1).year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            System.assertEquals(false, response2.success, 'Response must not be successful.');
            System.assertEquals(406, response2.code, 'The error code must match.');

            // invalid list with selected contractors
            Model.LightningResponse response3 = LA_PayslipGenerationController.isPayrollExistsForContractors(DEFAULT_DATE.month(), DEFAULT_DATE.year(), 'null');
            System.assertEquals(false, response3.success, 'Response must not be successful.');
            System.assertEquals(406, response3.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_deletePayslips_errorCode_400() {
        Test.startTest();
            Model.LightningResponse response = LA_PayslipGenerationController.deletePayslips(null);
            System.assertEquals(false, response.success, 'Response must not be successful.');
            System.assertEquals(400, response.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_deletePayslips_errorCode_406() {
        Test.startTest();
            Model.LightningResponse response = LA_PayslipGenerationController.deletePayslips('[]');
            System.assertEquals(false, response.success, 'Response must not be successful.');
            System.assertEquals(406, response.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_getPayslipsByResourceType() {
        Test.startTest();
            // get information about Payslips by resource type of contractors
            Model.LightningResponse response = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            assertSuccessLightningResponse(response);
        Test.stopTest();

        LA_PayslipGenerationController.PayslipPart[] payslipPartList = (LA_PayslipGenerationController.PayslipPart[]) JSON.deserialize(response.data, LA_PayslipGenerationController.PayslipPart[].class);
        System.assert(!payslipPartList.isEmpty(), 'List must not be empty.');

        // validate data
        String[] contractorResourceTypePicklistValueList = ContractorSelector.RESOURCE_TYPE_PICKLIST_VALUES_MAP.values();
        String[] pcSumTypePicklistValueList = PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.values();

        for (LA_PayslipGenerationController.PayslipPart payslipPart : payslipPartList) {
            // validate parts
            System.assert(contractorResourceTypePicklistValueList.contains(payslipPart.resourceType), 'Value must match.');
            System.assert(!payslipPart.payslipInfoList.isEmpty(), 'List must not be empty.');

            for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {
                // validate payslips
                System.assert(String.isNotBlank(payslipInfo.contractorInfo.id), 'Value must be.');
                System.assert(String.isNotBlank(payslipInfo.contractorInfo.personAccountId), 'Value must be.');
                System.assert(String.isNotBlank(payslipInfo.contractorInfo.name), 'Value must be.');
                System.assert(String.isNotBlank(payslipInfo.contractorInfo.resourceType), 'Value must be.');
                System.assert(String.isNotBlank(payslipInfo.contractorInfo.currencyIsoCode), 'Value must be.');
                System.assert(payslipInfo.contractorInfo.salary > 0, 'Value must be greater than 0.');
                System.assert(payslipInfo.contractorInfo.totalSalary > 0, 'Value must be greater than 0.');

                for (LA_PayslipGenerationController.PayrollComponentInfo payrollComponentInfo : payslipInfo.payrollComponentInfoList) {
                    // validate Payroll Component info
                    System.assert(String.isNotBlank(payrollComponentInfo.id), 'Value must be.');
                    System.assert(String.isNotBlank(payrollComponentInfo.recordTypeName), 'Value must be.');
                    System.assert(String.isNotBlank(payrollComponentInfo.reason), 'Value must be.');
                    System.assert(String.isNotBlank(payrollComponentInfo.currencyIsoCode), 'Value must be.');
                    System.assert(pcSumTypePicklistValueList.contains(payrollComponentInfo.sumType), 'Value must match.');
                    System.assert(payrollComponentInfo.sum > 0, 'Value must be greater than 0.');
                    System.assert(payrollComponentInfo.lastUpdateTimestamp > 0, 'Value must be greater than 0.');
                }
            }
        }
    }

    @IsTest
    static void test_getPayslipsByResourceType_SalaryChange_join_current() {
        // joined current month after transition blocking day (20 by default)
        ContractorTestDataFactory.createPortalContractorWithDatesForPayslipGeneration(DEFAULT_DATE.addDays(21), null);
        User dummyUser = [SELECT Id FROM User WHERE Email = :FAKE_EMAIL LIMIT 1];

        System.runAs(dummyUser) {

            Test.startTest();
                // get information about Payslips by resource type of contractors
                Model.LightningResponse response = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
                assertSuccessLightningResponse(response);
            Test.stopTest();

            LA_PayslipGenerationController.PayslipPart[] payslipPartList = (LA_PayslipGenerationController.PayslipPart[]) JSON.deserialize(response.data, LA_PayslipGenerationController.PayslipPart[].class);
            System.assert(!payslipPartList.isEmpty(), 'List must not be empty.');

            // validate data
            Boolean isBreakParentLoop = false;
            LA_PayslipGenerationController.ContractorInfo justJoinedContractorInfo;

            for (LA_PayslipGenerationController.PayslipPart payslipPart : payslipPartList) {

                if (isBreakParentLoop) break;

                for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {

                    if (payslipInfo.contractorInfo.isBlockedByJoiningDate) {
                        justJoinedContractorInfo = payslipInfo.contractorInfo;
                        isBreakParentLoop = true;
                        break;
                    }
                }
            }

            // validate data for payslip
            System.assert(justJoinedContractorInfo != null, 'Contractor info must be.');
            System.assertEquals(false, justJoinedContractorInfo.hasSalaryChangeByExitDate, 'Value must be false.');
            System.assertEquals(true, justJoinedContractorInfo.isBlockedByJoiningDate, 'Contractor must be blocked by "Joining Date".');
            System.assertEquals(false, justJoinedContractorInfo.hasSalaryChangeByJoiningDate, 'Value must be false.');
            System.assertEquals(0, justJoinedContractorInfo.totalSalary, 'Salary must be 0.');
            // validate data for Payroll Component
            System.assertEquals(true, justJoinedContractorInfo.salaryChangeInfo.payrollComponentInfo.isIncrementSumType, 'Value must be true.');
            System.assertEquals(false, justJoinedContractorInfo.salaryChangeInfo.payrollComponentInfo.isDecrementSumType, 'Value must be false.');
            System.assert(justJoinedContractorInfo.salaryChangeInfo.payrollComponentInfo.sum < justJoinedContractorInfo.salary, 'Value must be less than Contractors salary.');
            System.assert(String.isNotBlank(justJoinedContractorInfo.salaryChangeInfo.payrollComponentInfo.recordTypeName), 'Value must be.');
            System.assert(String.isNotBlank(justJoinedContractorInfo.salaryChangeInfo.payrollComponentInfo.reason), 'Value must be.');
            System.assert(String.isNotBlank(justJoinedContractorInfo.salaryChangeInfo.payrollComponentInfo.currencyIsoCode), 'Value must be.');
        }
    }

    @IsTest
    static void test_getPayslipsByResourceType_SalaryChange_join_last() {
        // joined last month after transition blocking day (20 by default)
        ContractorTestDataFactory.createPortalContractorWithDatesForPayslipGeneration(DEFAULT_DATE.addMonths(-1).addDays(21), null);
        User dummyUser = [SELECT Id FROM User WHERE Email = :FAKE_EMAIL LIMIT 1];

        System.runAs(dummyUser) {

            Test.startTest();
                // get information about Payslips by resource type of contractors
                Model.LightningResponse response = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
                assertSuccessLightningResponse(response);
            Test.stopTest();

            LA_PayslipGenerationController.PayslipPart[] payslipPartList = (LA_PayslipGenerationController.PayslipPart[]) JSON.deserialize(response.data, LA_PayslipGenerationController.PayslipPart[].class);
            System.assert(!payslipPartList.isEmpty(), 'List must not be empty.');

            // validate data
            Boolean isBreakParentLoop = false;
            LA_PayslipGenerationController.ContractorInfo justJoinedContractorInfo;

            for (LA_PayslipGenerationController.PayslipPart payslipPart : payslipPartList) {

                if (isBreakParentLoop) break;

                for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {

                    if (payslipInfo.contractorInfo.hasSalaryChangeByJoiningDate) {
                        justJoinedContractorInfo = payslipInfo.contractorInfo;
                        isBreakParentLoop = true;
                        break;
                    }
                }
            }

            // validate data for payslip
            System.assert(justJoinedContractorInfo != null, 'Contractor info must be.');
            System.assertEquals(false, justJoinedContractorInfo.hasSalaryChangeByExitDate, 'Value must be false.');
            System.assertEquals(false, justJoinedContractorInfo.isBlockedByJoiningDate, 'Value must be false.');
            System.assertEquals(true, justJoinedContractorInfo.hasSalaryChangeByJoiningDate, 'Contractor must have salary change for the last month.');
            System.assert(justJoinedContractorInfo.totalSalary > justJoinedContractorInfo.salary, 'The contractor must be accrued the rest of the salary for the last month.');
            // validate data for Payroll Component
            System.assertEquals(true, justJoinedContractorInfo.salaryChangeInfo.payrollComponentInfo.isIncrementSumType, 'Value must be true.');
            System.assertEquals(false, justJoinedContractorInfo.salaryChangeInfo.payrollComponentInfo.isDecrementSumType, 'Value must be false.');
            System.assert(justJoinedContractorInfo.salaryChangeInfo.payrollComponentInfo.sum < justJoinedContractorInfo.salary, 'Value must be less than Contractors salary.');
            System.assert(String.isNotBlank(justJoinedContractorInfo.salaryChangeInfo.payrollComponentInfo.recordTypeName), 'Value must be.');
            System.assert(String.isNotBlank(justJoinedContractorInfo.salaryChangeInfo.payrollComponentInfo.reason), 'Value must be.');
            System.assert(String.isNotBlank(justJoinedContractorInfo.salaryChangeInfo.payrollComponentInfo.currencyIsoCode), 'Value must be.');
        }
    }

    @IsTest
    static void test_getPayslipsByResourceType_SalaryChange_exit() {
        // contractor with exit date in the current month
        ContractorTestDataFactory.createPortalContractorWithDatesForPayslipGeneration(DEFAULT_DATE.addMonths(-1), DEFAULT_DATE.addDays(20));
        User dummyUser = [SELECT Id FROM User WHERE Email = :FAKE_EMAIL LIMIT 1];

        System.runAs(dummyUser) {

            Test.startTest();
                // get information about Payslips by resource type of contractors
                Model.LightningResponse response = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
                assertSuccessLightningResponse(response);
            Test.stopTest();

            LA_PayslipGenerationController.PayslipPart[] payslipPartList = (LA_PayslipGenerationController.PayslipPart[]) JSON.deserialize(response.data, LA_PayslipGenerationController.PayslipPart[].class);
            System.assert(!payslipPartList.isEmpty(), 'List must not be empty.');

            // validate data
            Boolean isBreakParentLoop = false;
            LA_PayslipGenerationController.ContractorInfo outgoingContractorInfo;

            for (LA_PayslipGenerationController.PayslipPart payslipPart : payslipPartList) {

                if (isBreakParentLoop) break;

                for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {

                    if (payslipInfo.contractorInfo.hasSalaryChangeByExitDate) {
                        outgoingContractorInfo = payslipInfo.contractorInfo;
                        isBreakParentLoop = true;
                        break;
                    }
                }
            }

            // validate data for payslip
            System.assert(outgoingContractorInfo != null, 'Contractor info must be.');
            System.assertEquals(true, outgoingContractorInfo.hasSalaryChangeByExitDate, 'Contractor must have a change in salary by the "Exit Date".');
            System.assertEquals(false, outgoingContractorInfo.isBlockedByJoiningDate, 'Value must be false.');
            System.assertEquals(false, outgoingContractorInfo.hasSalaryChangeByJoiningDate, 'Value must be false.');
            System.assert(outgoingContractorInfo.totalSalary < outgoingContractorInfo.salary, 'Total salary must be less.');
            // validate data for Payroll Component
            System.assertEquals(false, outgoingContractorInfo.salaryChangeInfo.payrollComponentInfo.isIncrementSumType, 'Value must be false.');
            System.assertEquals(true, outgoingContractorInfo.salaryChangeInfo.payrollComponentInfo.isDecrementSumType, 'Value must be true.');
            System.assert(outgoingContractorInfo.salaryChangeInfo.payrollComponentInfo.sum < outgoingContractorInfo.salary, 'Value must be less than Contractors salary.');
            System.assert(String.isNotBlank(outgoingContractorInfo.salaryChangeInfo.payrollComponentInfo.recordTypeName), 'Value must be.');
            System.assert(String.isNotBlank(outgoingContractorInfo.salaryChangeInfo.payrollComponentInfo.reason), 'Value must be.');
            System.assert(String.isNotBlank(outgoingContractorInfo.salaryChangeInfo.payrollComponentInfo.currencyIsoCode), 'Value must be.');
        }
    }

    @IsTest
    static void test_generatePayslips_Payrolls() {
        // generate Payrolls for current PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        Test.startTest();
            Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
            assertSuccessLightningResponse(responseAfterGeneration);
        Test.stopTest();

        // check that Payrolls with valid data
        Payroll__c[] payrollList = [
            SELECT Account__c,
                Contractor__c,
                Account__r.Contractor__r.Salary__c,
                CurrencyIsoCode,
                Salary__c,
                Sum__c,
                SalaryDate__c,
                StartMonthDate__c,
                (
                    SELECT
                        StartDate__c
                    FROM Payroll_Components__r
                )
            FROM Payroll__c
            WHERE RecordTypeId = :PayrollSelector.RECORD_TYPE_INFO_PAYROLL.getRecordTypeId()
        ];

        System.assertEquals(10, payrollList.size(), 'Value must match.');

        Date salaryDate = Date.valueOf(SALARY_DATE_STRING);

        for (Payroll__c payroll : payrollList) {
            System.assert(String.isNotBlank(payroll.Account__c), 'Value must be.');
            System.assert(String.isNotBlank(payroll.Contractor__c), 'Value must be.');
            System.assertEquals(CORPORATE_CURRENCY_ISO_CODE, payroll.CurrencyIsoCode, 'Value must match.');
            System.assertEquals(salaryDate, payroll.SalaryDate__c, 'Value must match.');
            System.assertEquals(DEFAULT_DATE, payroll.StartMonthDate__c, 'Value must match.');
            System.assert(payroll.Salary__c == payroll.Account__r.Contractor__r.Salary__c, 'Value must be equal to Contractors salary.');
            System.assert(payroll.Sum__c > payroll.Account__r.Contractor__r.Salary__c, 'Value must be greater than Contractors salary.');

            for (Payroll_Component__c payrollComponent : payroll.Payroll_Components__r) {
                System.assertEquals(DEFAULT_DATE, payrollComponent.StartDate__c, 'Value must match.');
            }
        }
    }

    @IsTest
    static void test_generatePayslips_update_Payrolls() {
        // generate Payrolls for current PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
        assertSuccessLightningResponse(responseAfterGeneration);

        // save generated Payrolls until regeneration
        Map<Id, Payroll__c> idToPayrollAfterGenerationMap = new Map<Id, Payroll__c>([
            SELECT Sum__c,
                SalaryDate__c,
                StartMonthDate__c,
                Account__r.Contractor__r.Salary__c,
                Account__r.Contractor__r.CurrencyIsoCode
            FROM Payroll__c
            WHERE RecordTypeId = :PayrollSelector.RECORD_TYPE_INFO_PAYROLL.getRecordTypeId()
        ]);

        Payroll_Component__c[] payrollComponentToDeleteList = [SELECT Id FROM Payroll_Component__c];
        delete payrollComponentToDeleteList;

        // regenerate Payrolls
        Model.LightningResponse responseWithUpdatedPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithUpdatedPayslipsByResourceType);

        Test.startTest();
            Model.LightningResponse responseAfterRegeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithUpdatedPayslipsByResourceType.data);
            assertSuccessLightningResponse(responseAfterRegeneration);
        Test.stopTest();

        // checking that the regenerated ones are different from the generated ones
        Payroll__c[] regeneratedPayrollList = [
            SELECT Account__c,
                Contractor__c,
                CurrencyIsoCode,
                Salary__c,
                Sum__c,
                SalaryDate__c,
                StartMonthDate__c
            FROM Payroll__c
            WHERE RecordTypeId = :PayrollSelector.RECORD_TYPE_INFO_PAYROLL.getRecordTypeId()
        ];

        for (Payroll__c regeneratedPayroll : regeneratedPayrollList) {
            Payroll__c generatedPayroll = idToPayrollAfterGenerationMap.get(regeneratedPayroll.Id);

            System.assert(regeneratedPayroll.Sum__c < generatedPayroll.Sum__c, 'Value must be less after regeneration.');
            System.assert(regeneratedPayroll.Account__c == generatedPayroll.Account__r.Id, 'Value must match.');
            System.assert(regeneratedPayroll.Contractor__c == generatedPayroll.Account__r.Contractor__r.Id, 'Value must match. ');
            System.assert(regeneratedPayroll.Salary__c == generatedPayroll.Account__r.Contractor__r.Salary__c, 'Value must match.');
            System.assert(regeneratedPayroll.CurrencyIsoCode == generatedPayroll.Account__r.Contractor__r.CurrencyIsoCode, 'Value must match.');
            System.assert(regeneratedPayroll.SalaryDate__c == generatedPayroll.SalaryDate__c, 'Value must match.');
            System.assert(regeneratedPayroll.StartMonthDate__c == generatedPayroll.StartMonthDate__c, 'Value must match.');
        }
    }

    @IsTest
    static void test_generatePayslips_create_PC_from_recurrent_PC() {
        // generate Payrolls for current PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        Test.startTest();
            Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
            assertSuccessLightningResponse(responseAfterGeneration);
        Test.stopTest();

        // check that PCs have been created from recurrent PCs
        Payroll__c[] payrollList = [
            SELECT
                (
                    SELECT
                        Id
                    FROM Payroll_Components__r
                    WHERE Payroll_Component_Template__c <> NULL
                )
            FROM Payroll__c
            WHERE RecordTypeId = :PayrollSelector.RECORD_TYPE_INFO_PAYROLL.getRecordTypeId()
        ];

        for (Payroll__c payroll : payrollList) {
            System.assertEquals(RECURRENT_PAYROLL_COMPONENTS_PER_CONTRACTOR, payroll.Payroll_Components__r.size(), 'Value must match.');
        }
    }

    @IsTest
    static void test_generatePayslips_update_PC_from_recurrent_PC() {
        final String ANOTHER_REASON = 'Another ' + DEFAULT_REASON;
        final Integer ANOTHER_SUM = 1000;

        // generate Payrolls for current PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
        assertSuccessLightningResponse(responseAfterGeneration);

        // update recurrent PCs
        Payroll_Component__c[] payrollComponentList = [
            SELECT CurrencyIsoCode, SumType__c, Sum__c, Reason__c
            FROM Payroll_Component__c
            WHERE Recurrent__c = TRUE
        ];

        for (Payroll_Component__c payrollComponent : payrollComponentList) {
            payrollComponent.CurrencyIsoCode = NOT_CORPORATE_CURRENCY_ISO_CODE;
            payrollComponent.SumType__c = PAYROLL_COMPONENT_SUM_TYPE_INCREMENT;
            payrollComponent.Sum__c = ANOTHER_SUM;
            payrollComponent.Reason__c = ANOTHER_REASON;
        }
        update payrollComponentList;

        // regenerate Payrolls with changed recurrent PCs
        Model.LightningResponse responseWithUpdatedPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithUpdatedPayslipsByResourceType);

        Test.startTest();
            Model.LightningResponse responseAfterRegeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithUpdatedPayslipsByResourceType.data);
            assertSuccessLightningResponse(responseAfterRegeneration);
        Test.stopTest();

        // check that PCs created from recurrent PCs have been updated
        Payroll__c[] payrollList = [
            SELECT
                (
                    SELECT CurrencyIsoCode, SumType__c, Sum__c, Reason__c
                    FROM Payroll_Components__r
                    WHERE Payroll_Component_Template__c <> NULL
                )
            FROM Payroll__c
            WHERE RecordTypeId = :PayrollSelector.RECORD_TYPE_INFO_PAYROLL.getRecordTypeId()
        ];

        for (Payroll__c payroll : payrollList) {
            System.assertEquals(RECURRENT_PAYROLL_COMPONENTS_PER_CONTRACTOR, payroll.Payroll_Components__r.size(), 'Value must match.');

            for (Payroll_Component__c payrollComponent : payroll.Payroll_Components__r) {
                System.assertEquals(NOT_CORPORATE_CURRENCY_ISO_CODE, payrollComponent.CurrencyIsoCode, 'Value must match.');
                System.assertEquals(PAYROLL_COMPONENT_SUM_TYPE_INCREMENT, payrollComponent.SumType__c, 'Value must match.');
                System.assertEquals(ANOTHER_SUM, payrollComponent.Sum__c, 'Value must match.');
                System.assertEquals(ANOTHER_REASON, payrollComponent.Reason__c, 'Value must match.');
            }
        }
    }

    @IsTest
    static void test_generatePayslips_delete_PC_from_recurrent_PC() {
        // generate Payrolls for current PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
        assertSuccessLightningResponse(responseAfterGeneration);

        // store created PCs from recurrent PCs
        Map<Id, Payroll_Component__c> idToPayrollComponentMap = new Map<Id, Payroll_Component__c>([SELECT Id FROM Payroll_Component__c WHERE Payroll_Component_Template__c <> NULL]);
        System.assert(!idToPayrollComponentMap.isEmpty(), 'Map must not be empty');

        // update recurrent PCs
        Payroll_Component__c[] recurrentPayrollComponentList = [
            SELECT EndDate__c
            FROM Payroll_Component__c
            WHERE Recurrent__c = TRUE
        ];

        for (Payroll_Component__c payrollComponent : recurrentPayrollComponentList) {
            payrollComponent.EndDate__c = DateUtils.getLastDayOfMonth(DEFAULT_DATE.addMonths(-1));
        }
        update recurrentPayrollComponentList;

        // regenerate Payrolls with changed recurrent PCs
        Model.LightningResponse responseWithUpdatedPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithUpdatedPayslipsByResourceType);

        Test.startTest();
            Model.LightningResponse responseAfterRegeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithUpdatedPayslipsByResourceType.data);
            assertSuccessLightningResponse(responseAfterRegeneration);
        Test.stopTest();

        // check that PCs from template have been deleted
        Payroll_Component__c[] payrollComponentList = [SELECT Id FROM Payroll_Component__c WHERE Id IN :idToPayrollComponentMap.keySet()];
        System.assert(payrollComponentList.isEmpty(), 'List must be empty');
    }

    @IsTest
    static void test_generatePayslips_unlink_changed_payrollComponents() {
        //generate Payrolls for existing PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
        assertSuccessLightningResponse(responseAfterGeneration);

        Map<Id, Payroll_Component__c> idToPayrollComponentMap = new Map<Id, Payroll_Component__c>([SELECT StartDate__c FROM Payroll_Component__c WHERE Recurrent__c = FALSE]);

        //change start date for not recurrent PCs
        Date startDateOnNextMonth = DEFAULT_DATE.addMonths(1);
        for (Payroll_Component__c payrollComponent : idToPayrollComponentMap.values()) {
            payrollComponent.StartDate__c = startDateOnNextMonth;
        }
        update idToPayrollComponentMap.values();

        Model.LightningResponse responseWithUpdatedPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithUpdatedPayslipsByResourceType);

        //regenerate Payrolls with changed PCs
        Test.startTest();
            Model.LightningResponse responseAfterRegeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithUpdatedPayslipsByResourceType.data);
            assertSuccessLightningResponse(responseAfterRegeneration);
        Test.stopTest();

        //check that the records are unlinked from Payrolls
        for (Payroll_Component__c payrollComponent : [SELECT Payroll__c FROM Payroll_Component__c WHERE Id IN :idToPayrollComponentMap.keySet()]) {
            System.assert(String.isBlank(payrollComponent.Payroll__c), 'Value must be empty.');
        }

        Payroll__c[] regeneratedPayrollList = [
            SELECT
                (
                    SELECT Payroll_Component_Template__c
                    FROM Payroll_Components__r
                )
            FROM Payroll__c
            WHERE RecordTypeId = :PayrollSelector.RECORD_TYPE_INFO_PAYROLL.getRecordTypeId()
        ];

        for (Payroll__c regeneratedPayroll : regeneratedPayrollList) {
            System.assertEquals(RECURRENT_PAYROLL_COMPONENTS_PER_CONTRACTOR, regeneratedPayroll.Payroll_Components__r.size(), 'Value must match.');

            for (Payroll_Component__c payrollComponent : regeneratedPayroll.Payroll_Components__r) {
                System.assert(String.isNotBlank(payrollComponent.Payroll_Component_Template__c), 'Value must be.');
            }
        }
    }

    @IsTest
    static void test_generatePayslips_SalaryChange_join_current() {
        // joined current month after transition blocking day (20 by default)
        Date joiningDate = DEFAULT_DATE.addDays(21);
        ContractorTestDataFactory.createPortalContractorWithDatesForPayslipGeneration(joiningDate, null);
        User dummyUser = [SELECT Id FROM User WHERE Email = :FAKE_EMAIL LIMIT 1];

        System.runAs(dummyUser) {

            // generate Payrolls for contractors
            Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            assertSuccessLightningResponse(responseWithPayslipsByResourceType);

            Test.startTest();
                Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
                assertSuccessLightningResponse(responseAfterGeneration);
            Test.stopTest();

            // validate data
            Payroll__c[] payrollList = [
                SELECT Id
                FROM Payroll__c
                WHERE RecordTypeId = :PayrollSelector.RECORD_TYPE_INFO_PAYROLL.getRecordTypeId()
                AND Contractor__r.Joining_Date__c = :joiningDate
            ];

            System.assert(payrollList.isEmpty(), 'Nothing should be generated for the joined contractor in the current month.');
        }
    }

    @IsTest
    static void test_generatePayslips_SalaryChange_join_last() {
        // joined last month after transition blocking day (20 by default)
        Date joiningDate = DEFAULT_DATE.addMonths(-1).addDays(21);
        ContractorTestDataFactory.createPortalContractorWithDatesForPayslipGeneration(joiningDate, null);
        User dummyUser = [SELECT Id FROM User WHERE Email = :FAKE_EMAIL LIMIT 1];

        System.runAs(dummyUser) {

            // generate Payrolls for contractors
            Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            assertSuccessLightningResponse(responseWithPayslipsByResourceType);

            Test.startTest();
                Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
                assertSuccessLightningResponse(responseAfterGeneration);
            Test.stopTest();

            // validate data
            String salaryAdjustmentPicklistValue = PayrollComponentSelector.ADJUSTMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.AdjustmentTypePicklistKey.SALARY_ADJUSTMENT);

            Payroll__c[] payrollList = [
                SELECT
                (
                    SELECT
                        RecordTypeId,
                        Contractor__c,
                        Contractor__r.CurrencyIsoCode,
                        Account__c,
                        Reason__c,
                        CurrencyIsoCode,
                        Sum__c,
                        SumType__c,
                        Approval_Status__c,
                        Recurrent__c,
                        StartDate__c,
                        EndDate__c
                    FROM Payroll_Components__r
                    WHERE Adjustment_Type__c = :salaryAdjustmentPicklistValue
                )
                FROM Payroll__c
                WHERE RecordTypeId = :PayrollSelector.RECORD_TYPE_INFO_PAYROLL.getRecordTypeId()
                AND Contractor__r.Joining_Date__c = :joiningDate
            ];

            System.assert(payrollList.size() == 1, 'Payroll should be generated for the joined contractor last month.');
            System.assert(payrollList[0].Payroll_Components__r.size() == 1, 'Only one record should be generated for the salary change.');

            Payroll_Component__c pcForSalaryChange = payrollList[0].Payroll_Components__r[0];
            System.assert(String.isNotBlank(pcForSalaryChange.Contractor__c), 'Value must be.');
            System.assert(String.isNotBlank(pcForSalaryChange.Account__c), 'Value must be.');
            System.assert(String.isNotBlank(pcForSalaryChange.Reason__c), 'Value must be.');
            System.assert(pcForSalaryChange.Sum__c > 0, 'Value must be greater than 0.');
            System.assert(pcForSalaryChange.Recurrent__c == false, 'Value must be false.');
            System.assert(pcForSalaryChange.StartDate__c == DEFAULT_DATE, 'Values must be equal.');
            System.assert(pcForSalaryChange.EndDate__c == DEFAULT_DATE, 'Values must be equal.');

            System.assertEquals(
                PayrollComponentSelector.RECORD_TYPE_INFO_ADJUSTMENTS.getRecordTypeId(),
                pcForSalaryChange.RecordTypeId,
                'Value must match.'
            );
            System.assertEquals(
                pcForSalaryChange.Contractor__r.CurrencyIsoCode,
                pcForSalaryChange.CurrencyIsoCode,
                'Value must match.'
            );
            System.assertEquals(
                PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.SumTypePicklistKey.INCREMENT),
                pcForSalaryChange.SumType__c,
                'Value must match.'
            );
            System.assertEquals(
                PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED),
                pcForSalaryChange.Approval_Status__c,
                'Value must match.'
            );
        }
    }

    @IsTest
    static void test_generatePayslips_SalaryChange_join_last_regeneration() {
        // joined last month after transition blocking day (20 by default)
        Date joiningDate = DEFAULT_DATE.addMonths(-1).addDays(21);
        ContractorTestDataFactory.createPortalContractorWithDatesForPayslipGeneration(joiningDate, null);
        User dummyUser = [SELECT Id FROM User WHERE Email = :FAKE_EMAIL LIMIT 1];

        System.runAs(dummyUser) {

            // generate Payrolls for contractors
            Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            assertSuccessLightningResponse(responseWithPayslipsByResourceType);

            Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
            assertSuccessLightningResponse(responseAfterGeneration);

            // regenerate Payrolls
            Model.LightningResponse responseWithUpdatedPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            assertSuccessLightningResponse(responseWithUpdatedPayslipsByResourceType);

            Test.startTest();
                Model.LightningResponse responseAfterRegeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithUpdatedPayslipsByResourceType.data);
                assertSuccessLightningResponse(responseAfterRegeneration);
            Test.stopTest();

            // validate data
            String salaryAdjustmentPicklistValue = PayrollComponentSelector.ADJUSTMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.AdjustmentTypePicklistKey.SALARY_ADJUSTMENT);

            Payroll__c[] payrollList = [
                SELECT
                (
                    SELECT Id
                    FROM Payroll_Components__r
                    WHERE Adjustment_Type__c = :salaryAdjustmentPicklistValue
                )
                FROM Payroll__c
                WHERE RecordTypeId = :PayrollSelector.RECORD_TYPE_INFO_PAYROLL.getRecordTypeId()
                AND Contractor__r.Joining_Date__c = :joiningDate
            ];

            System.assert(payrollList.size() == 1, 'Payroll should be generated for the joined contractor last month.');
            System.assert(payrollList[0].Payroll_Components__r.size() == 1, 'Only one record should be generated for the salary change.');
        }
    }

    @IsTest
    static void test_generatePayslips_SalaryChange_exit() {
        // contractor with exit date in the current month
        Date exitDate = DEFAULT_DATE.addDays(20);
        ContractorTestDataFactory.createPortalContractorWithDatesForPayslipGeneration(DEFAULT_DATE.addMonths(-1), exitDate);
        User dummyUser = [SELECT Id FROM User WHERE Email = :FAKE_EMAIL LIMIT 1];

        System.runAs(dummyUser) {

            // generate Payrolls for contractors
            Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            assertSuccessLightningResponse(responseWithPayslipsByResourceType);

            Test.startTest();
            Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
            assertSuccessLightningResponse(responseAfterGeneration);
            Test.stopTest();

            // validate data
            String salaryAdjustmentPicklistValue = PayrollComponentSelector.ADJUSTMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.AdjustmentTypePicklistKey.SALARY_ADJUSTMENT);

            Payroll__c[] payrollList = [
                SELECT
                (
                    SELECT
                        RecordTypeId,
                        Contractor__c,
                        Contractor__r.CurrencyIsoCode,
                        Account__c,
                        Reason__c,
                        CurrencyIsoCode,
                        Sum__c,
                        SumType__c,
                        Approval_Status__c,
                        Recurrent__c,
                        StartDate__c,
                        EndDate__c
                    FROM Payroll_Components__r
                    WHERE Adjustment_Type__c = :salaryAdjustmentPicklistValue
                )
                FROM Payroll__c
                WHERE RecordTypeId = :PayrollSelector.RECORD_TYPE_INFO_PAYROLL.getRecordTypeId()
                AND Contractor__r.Exit_Date__c = :exitDate
            ];

            System.assert(payrollList.size() == 1, 'Payroll should be generated for the contractor.');
            System.assert(payrollList[0].Payroll_Components__r.size() == 1, 'Only one record should be generated for the salary change.');

            Payroll_Component__c pcForSalaryChange = payrollList[0].Payroll_Components__r[0];
            System.assert(String.isNotBlank(pcForSalaryChange.Contractor__c), 'Value must be.');
            System.assert(String.isNotBlank(pcForSalaryChange.Account__c), 'Value must be.');
            System.assert(String.isNotBlank(pcForSalaryChange.Reason__c), 'Value must be.');
            System.assert(pcForSalaryChange.Sum__c > 0, 'Value must be greater than 0.');
            System.assert(pcForSalaryChange.Recurrent__c == false, 'Value must be false.');
            System.assert(pcForSalaryChange.StartDate__c == DEFAULT_DATE, 'Values must be equal.');
            System.assert(pcForSalaryChange.EndDate__c == DEFAULT_DATE, 'Values must be equal.');

            System.assertEquals(
                PayrollComponentSelector.RECORD_TYPE_INFO_ADJUSTMENTS.getRecordTypeId(),
                pcForSalaryChange.RecordTypeId,
                'Value must match.'
            );
            System.assertEquals(
                pcForSalaryChange.Contractor__r.CurrencyIsoCode,
                pcForSalaryChange.CurrencyIsoCode,
                'Value must match.'
            );
            System.assertEquals(
                PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.SumTypePicklistKey.DECREMENT),
                pcForSalaryChange.SumType__c,
                'Value must match.'
            );
            System.assertEquals(
                PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED),
                pcForSalaryChange.Approval_Status__c,
                'Value must match.'
            );
        }
    }

    @IsTest
    static void test_generatePayslips_SalaryChange_exit_regeneration() {
        // contractor with exit date in the current month
        Date exitDate = DEFAULT_DATE.addDays(20);
        ContractorTestDataFactory.createPortalContractorWithDatesForPayslipGeneration(DEFAULT_DATE.addMonths(-1), exitDate);
        User dummyUser = [SELECT Id FROM User WHERE Email = :FAKE_EMAIL LIMIT 1];

        System.runAs(dummyUser) {

            // generate Payrolls for contractors
            Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            assertSuccessLightningResponse(responseWithPayslipsByResourceType);

            Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
            assertSuccessLightningResponse(responseAfterGeneration);

            // regenerate Payrolls
            Model.LightningResponse responseWithUpdatedPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            assertSuccessLightningResponse(responseWithUpdatedPayslipsByResourceType);

            Test.startTest();
            Model.LightningResponse responseAfterRegeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithUpdatedPayslipsByResourceType.data);
            assertSuccessLightningResponse(responseAfterRegeneration);
            Test.stopTest();

            // validate data
            String salaryAdjustmentPicklistValue = PayrollComponentSelector.ADJUSTMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.AdjustmentTypePicklistKey.SALARY_ADJUSTMENT);

            Payroll__c[] payrollList = [
                SELECT
                (
                    SELECT Id
                    FROM Payroll_Components__r
                    WHERE Adjustment_Type__c = :salaryAdjustmentPicklistValue
                )
                FROM Payroll__c
                WHERE RecordTypeId = :PayrollSelector.RECORD_TYPE_INFO_PAYROLL.getRecordTypeId()
                AND Contractor__r.Exit_Date__c = :exitDate
            ];

            System.assert(payrollList.size() == 1, 'Payroll should be regenerated for the contractor.');
            System.assert(payrollList[0].Payroll_Components__r.size() == 1, 'Only one record should be generated for the salary change.');
        }
    }

    @IsTest
    static void test_generatePayslips_exception_errorCode_1001_state() {
        // generate Payrolls for current PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        // delete all PCs for random contractor
        Account personAccount = [SELECT Id FROM Account WHERE IsPersonAccount = TRUE LIMIT 1];
        Payroll_Component__c[] payrollComponentList = [SELECT Id FROM Payroll_Component__c WHERE Account__c = :personAccount.Id];
        delete payrollComponentList;

        Test.startTest();
        Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
        System.assertEquals(false, responseAfterGeneration.success, 'Response must not be successful.');
        System.assertEquals(LA_PayslipGenerationController.ERROR_CODE_1001, responseAfterGeneration.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_generatePayslips_exception_errorCode_1001_size() {
        // generate Payrolls for current PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        // delete random PC
        Payroll_Component__c[] payrollComponentList = [SELECT Id FROM Payroll_Component__c LIMIT 1];
        delete payrollComponentList;

        Test.startTest();
        Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
        System.assertEquals(false, responseAfterGeneration.success, 'Response must not be successful.');
        System.assertEquals(LA_PayslipGenerationController.ERROR_CODE_1001, responseAfterGeneration.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_generatePayslips_exception_errorCode_1002() {
        // generate Payrolls for current PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        // clone and delete random PC, to keep total PC size for one contractor
        Payroll_Component__c randomPayrollComponent = [
            SELECT
                Id,
                Account__c,
                Approval_Status__c,
                Budget_transaction__c,
                Contractor__c,
                CreatedById,
                CreatedDate,
                CurrencyIsoCode,
                EndDate__c,
                Hours__c,
                Insurance__c,
                IsDeleted,
                LastModifiedById,
                LastModifiedDate,
                LastReferencedDate,
                LastViewedDate,
                Name,
                Overtime_Rate__c,
                Payroll__c,
                Payroll_Component_Template__c,
                Project__c,
                Approver__c,
                Reason__c,
                RecordTypeId,
                Recurrent__c,
                Rejection_Reason__c,
                StartDate__c,
                Sum__c,
                SumType__c,
                SystemModstamp,
                Travel_request__c
            FROM Payroll_Component__c
            LIMIT 1
        ];

        delete randomPayrollComponent;

        Payroll_Component__c clonedPayrollComponent = randomPayrollComponent.clone();
        insert clonedPayrollComponent;

        Test.startTest();
        Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
        System.assertEquals(false, responseAfterGeneration.success, 'Response must not be successful.');
        System.assertEquals(LA_PayslipGenerationController.ERROR_CODE_1002, responseAfterGeneration.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_generatePayslips_exception_errorCode_1003() {
        // generate Payrolls for current PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        // change random PC
        Payroll_Component__c payrollComponent = [SELECT Id, Sum__c FROM Payroll_Component__c LIMIT 1];
        payrollComponent.Sum__c = 123456.78;
        update payrollComponent;

        Test.startTest();
        Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
        System.assertEquals(false, responseAfterGeneration.success, 'Response must not be successful.');
        System.assertEquals(LA_PayslipGenerationController.ERROR_CODE_1003, responseAfterGeneration.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_getHistoricalPayslipsByResourceType() {
        //generate Payrolls for existing PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
        assertSuccessLightningResponse(responseAfterGeneration);

        // transferring records to a previous period
        SObject[] objectToUpdateList = new SObject[]{};
        Date startMonthDateForPreviousPeriod = DEFAULT_DATE.addMonths(-1);

        Payroll__c[] payrollList = [SELECT StartMonthDate__c, SalaryDate__c FROM Payroll__c];

        for (Payroll__c payroll : payrollList) {
            payroll.StartMonthDate__c = startMonthDateForPreviousPeriod;
            payroll.SalaryDate__c = DEFAULT_DATE;

            objectToUpdateList.add(payroll);
        }

        Payroll_Component__c[] payrollComponentList = [SELECT StartDate__c, EndDate__c FROM Payroll_Component__c WHERE Recurrent__c = FALSE];

        for (Payroll_Component__c payrollComponent : payrollComponentList) {
            payrollComponent.StartDate__c = startMonthDateForPreviousPeriod;
            payrollComponent.EndDate__c = startMonthDateForPreviousPeriod;

            objectToUpdateList.add(payrollComponent);
        }

        update objectToUpdateList;

        Test.startTest();
            Model.LightningResponse responseWithHistoricalPayslipsByResourceType = LA_PayslipGenerationController.getHistoricalPayslipsByResourceType(startMonthDateForPreviousPeriod.month(),
                                                                                                                                                      startMonthDateForPreviousPeriod.year(),
                                                                                                                                                      JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            assertSuccessLightningResponse(responseWithHistoricalPayslipsByResourceType);
        Test.stopTest();


        LA_PayslipGenerationController.PayslipPart[] payslipPartList = (LA_PayslipGenerationController.PayslipPart[]) JSON.deserialize(responseWithHistoricalPayslipsByResourceType.data,
                                                                                                                                       LA_PayslipGenerationController.PayslipPart[].class);
        System.assert(!payslipPartList.isEmpty(), 'List must not be empty.');

        // validate historical data
        String[] contractorResourceTypePicklistValueList = ContractorSelector.RESOURCE_TYPE_PICKLIST_VALUES_MAP.values();
        String[] pcSumTypePicklistValueList = PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.values();

        for (LA_PayslipGenerationController.PayslipPart payslipPart : payslipPartList) {
            System.assert(contractorResourceTypePicklistValueList.contains(payslipPart.resourceType), 'Value must match.');
            System.assert(!payslipPart.payslipInfoList.isEmpty(), 'List must not be empty.');

            for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {
                System.assert(String.isNotBlank(payslipInfo.contractorInfo.name), 'Value must be.');
                System.assert(String.isNotBlank(payslipInfo.contractorInfo.resourceType), 'Value must be.');
                System.assert(String.isNotBlank(payslipInfo.contractorInfo.currencyIsoCode), 'Value must be.');
                System.assert(payslipInfo.contractorInfo.salary > 0, 'Value must be greater than 0.');
                System.assert(payslipInfo.contractorInfo.totalSalary > 0, 'Value must be greater than 0.');

                for (LA_PayslipGenerationController.PayrollComponentInfo payrollComponentInfo : payslipInfo.payrollComponentInfoList) {
                    System.assert(String.isNotBlank(payrollComponentInfo.recordTypeName), 'Value must be.');
                    System.assert(String.isNotBlank(payrollComponentInfo.reason), 'Value must be.');
                    System.assert(String.isNotBlank(payrollComponentInfo.currencyIsoCode), 'Value must be.');
                    System.assert(pcSumTypePicklistValueList.contains(payrollComponentInfo.sumType), 'Value must match.');
                    System.assert(payrollComponentInfo.sum > 0, 'Value must be greater than 0.');
                }
            }
        }
    }

    @IsTest
    static void test_isPayrollExistsForContractors() {
        // generate Payrolls for current PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
        assertSuccessLightningResponse(responseAfterGeneration);

        Test.startTest();
            Model.LightningResponse responseAfterCheck = LA_PayslipGenerationController.isPayrollExistsForContractors(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            assertSuccessLightningResponse(responseAfterCheck);
        Test.stopTest();

        System.assertEquals(true, JSON.deserializeUntyped(responseAfterCheck.data), 'Check result must be true.');
    }

    @IsTest
    static void test_deletePayslips_all() {
        // generate Payrolls for current PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
        assertSuccessLightningResponse(responseAfterGeneration);

        // simulate user selection for deletion payrolls
        Model.LightningResponse responseWithHistoricalPayslipsByResourceType = LA_PayslipGenerationController.getHistoricalPayslipsByResourceType(DEFAULT_DATE.month(),
                                                                                                                                                  DEFAULT_DATE.year(),
                                                                                                                                                  JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithHistoricalPayslipsByResourceType);

        LA_PayslipGenerationController.PayslipPart[] payslipPartList = (LA_PayslipGenerationController.PayslipPart[]) JSON.deserialize(responseWithHistoricalPayslipsByResourceType.data, LA_PayslipGenerationController.PayslipPart[].class);
        System.assert(!payslipPartList.isEmpty(), 'List must not be empty.');

        for (LA_PayslipGenerationController.PayslipPart payslipPart : payslipPartList) {

            for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {
                payslipInfo.isToDelete = true;
            }
        }

        // delete
        Test.startTest();
            Model.LightningResponse responseAfterDeletion = LA_PayslipGenerationController.deletePayslips(JSON.serialize(payslipPartList));
            assertSuccessLightningResponse(responseAfterDeletion);
        Test.stopTest();

        // check that Payrolls has been deleted
        Payroll__c[] payrollList = [SELECT Id FROM Payroll__c];
        System.assert(payrollList.isEmpty(), 'List must be empty.');
    }

    @IsTest
    static void test_deletePayslips_partial() {
        // generate Payrolls for current PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
        assertSuccessLightningResponse(responseAfterGeneration);

        // simulate user selection for deletion payrolls
        Model.LightningResponse responseWithHistoricalPayslipsByResourceType = LA_PayslipGenerationController.getHistoricalPayslipsByResourceType(DEFAULT_DATE.month(),
                                                                                                                                                  DEFAULT_DATE.year(),
                                                                                                                                                  JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithHistoricalPayslipsByResourceType);

        LA_PayslipGenerationController.PayslipPart[] payslipPartList = (LA_PayslipGenerationController.PayslipPart[]) JSON.deserialize(responseWithHistoricalPayslipsByResourceType.data, LA_PayslipGenerationController.PayslipPart[].class);
        System.assert(!payslipPartList.isEmpty(), 'List must not be empty.');

        Set<Id> deletedPayrollIdSet = new Set<Id>();
        for (LA_PayslipGenerationController.PayslipPart payslipPart : payslipPartList) {

            for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {
                payslipInfo.isToDelete = true;
                deletedPayrollIdSet.add(payslipInfo.id);
            }

            break;
        }

        System.assert(!deletedPayrollIdSet.isEmpty(), 'Set must not be empty.');

        // delete partial Payrolls
        Test.startTest();
            Model.LightningResponse responseAfterDeletion = LA_PayslipGenerationController.deletePayslips(JSON.serialize(payslipPartList));
            assertSuccessLightningResponse(responseAfterDeletion);
        Test.stopTest();

        // check that Payrolls has been deleted
        Payroll__c[] payrollList = [SELECT Id FROM Payroll__c];
        System.assert(!payrollList.isEmpty(), 'List must not be empty.');

        for (Payroll__c payroll : payrollList) {
            System.assert(!deletedPayrollIdSet.contains(payroll.Id), 'Set must not contain existing ids.');
        }
    }

    @IsTest
    static void test_deletePayslips_pc_from_template() {
        // generate Payrolls for current PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
        assertSuccessLightningResponse(responseAfterGeneration);

        // simulate user selection for deletion payrolls
        Model.LightningResponse responseWithHistoricalPayslipsByResourceType = LA_PayslipGenerationController.getHistoricalPayslipsByResourceType(DEFAULT_DATE.month(),
                                                                                                                                                  DEFAULT_DATE.year(),
                                                                                                                                                  JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithHistoricalPayslipsByResourceType);

        LA_PayslipGenerationController.PayslipPart[] payslipPartList = (LA_PayslipGenerationController.PayslipPart[]) JSON.deserialize(responseWithHistoricalPayslipsByResourceType.data, LA_PayslipGenerationController.PayslipPart[].class);
        System.assert(!payslipPartList.isEmpty(), 'List must not be empty.');

        for (LA_PayslipGenerationController.PayslipPart payslipPart : payslipPartList) {

            for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {
                payslipInfo.isToDelete = true;
            }
        }

        Payroll_Component__c[] pcFromTemplateList_before = [SELECT Id FROM Payroll_Component__c WHERE Payroll_Component_Template__c <> NULL];
        System.assert(!pcFromTemplateList_before.isEmpty(), 'List must not be empty.');

        // delete Payrolls
        Test.startTest();
            Model.LightningResponse responseAfterDeletion = LA_PayslipGenerationController.deletePayslips(JSON.serialize(payslipPartList));
            assertSuccessLightningResponse(responseAfterDeletion);
        Test.stopTest();

        // check that Payrolls has been deleted
        Payroll_Component__c[] pcFromTemplateList_after = [SELECT Id FROM Payroll_Component__c WHERE Payroll_Component_Template__c <> NULL];
        System.assert(pcFromTemplateList_after.isEmpty(), 'List must be empty.');
    }

    @IsTest
    static void test_deletePayslips_pc_for_SalaryChange_join() {
        // joined last month after transition blocking day (20 by default)
        Date joiningDate = DEFAULT_DATE.addMonths(-1).addDays(21);
        ContractorTestDataFactory.createPortalContractorWithDatesForPayslipGeneration(joiningDate, null);
        User dummyUser = [SELECT Id FROM User WHERE Email = :FAKE_EMAIL LIMIT 1];

        System.runAs(dummyUser) {

            // generate Payrolls for current PCs
            Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            assertSuccessLightningResponse(responseWithPayslipsByResourceType);

            Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
            assertSuccessLightningResponse(responseAfterGeneration);

            // simulate user selection for deletion payrolls
            Model.LightningResponse responseWithHistoricalPayslipsByResourceType = LA_PayslipGenerationController.getHistoricalPayslipsByResourceType(DEFAULT_DATE.month(),
                DEFAULT_DATE.year(),
                JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            assertSuccessLightningResponse(responseWithHistoricalPayslipsByResourceType);

            LA_PayslipGenerationController.PayslipPart[] payslipPartList = (LA_PayslipGenerationController.PayslipPart[]) JSON.deserialize(responseWithHistoricalPayslipsByResourceType.data, LA_PayslipGenerationController.PayslipPart[].class);
            System.assert(!payslipPartList.isEmpty(), 'List must not be empty.');

            for (LA_PayslipGenerationController.PayslipPart payslipPart : payslipPartList) {

                for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {
                    payslipInfo.isToDelete = true;
                }
            }

            String salaryAdjustmentPicklistValue = PayrollComponentSelector.ADJUSTMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.AdjustmentTypePicklistKey.SALARY_ADJUSTMENT);

            Payroll_Component__c[] pcForTailList_before = [
                SELECT Id
                FROM Payroll_Component__c
                WHERE Contractor__r.Joining_Date__c = :joiningDate
                AND Adjustment_Type__c = :salaryAdjustmentPicklistValue
            ];

            System.assert(pcForTailList_before.isEmpty() == false, 'List must not be empty.');

            // delete Payrolls
            Test.startTest();
            Model.LightningResponse responseAfterDeletion = LA_PayslipGenerationController.deletePayslips(JSON.serialize(payslipPartList));
            assertSuccessLightningResponse(responseAfterDeletion);
            Test.stopTest();

            // check that Payroll Component has been deleted
            Payroll_Component__c[] pcForTailList_after = [
                SELECT Id
                FROM Payroll_Component__c
                WHERE Contractor__r.Joining_Date__c = :joiningDate
                AND Adjustment_Type__c = :salaryAdjustmentPicklistValue
            ];

            System.assert(pcForTailList_after.isEmpty(), 'List must be empty.');
        }
    }

    @IsTest
    static void test_deletePayslips_pc_for_SalaryChange_exit() {
        // contractor with exit date in the current month
        Date exitDate = DEFAULT_DATE.addDays(20);
        ContractorTestDataFactory.createPortalContractorWithDatesForPayslipGeneration(DEFAULT_DATE.addMonths(-1), exitDate);
        User dummyUser = [SELECT Id FROM User WHERE Email = :FAKE_EMAIL LIMIT 1];

        System.runAs(dummyUser) {

            // generate Payrolls for current PCs
            Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(),
                DEFAULT_DATE.year(),
                JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            assertSuccessLightningResponse(responseWithPayslipsByResourceType);

            Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(),
                DEFAULT_DATE.year(),
                SALARY_DATE_STRING,
                responseWithPayslipsByResourceType.data);
            assertSuccessLightningResponse(responseAfterGeneration);

            // simulate user selection for deletion payrolls
            Model.LightningResponse responseWithHistoricalPayslipsByResourceType = LA_PayslipGenerationController.getHistoricalPayslipsByResourceType(DEFAULT_DATE.month(),
                DEFAULT_DATE.year(),
                JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
            assertSuccessLightningResponse(responseWithHistoricalPayslipsByResourceType);

            LA_PayslipGenerationController.PayslipPart[] payslipPartList = (LA_PayslipGenerationController.PayslipPart[]) JSON.deserialize(responseWithHistoricalPayslipsByResourceType.data,
                LA_PayslipGenerationController.PayslipPart[].class);
            System.assert(!payslipPartList.isEmpty(), 'List must not be empty.');

            for (LA_PayslipGenerationController.PayslipPart payslipPart : payslipPartList) {

                for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {
                    payslipInfo.isToDelete = true;
                }
            }

            String salaryAdjustmentPicklistValue = PayrollComponentSelector.ADJUSTMENT_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.AdjustmentTypePicklistKey.SALARY_ADJUSTMENT);

            Payroll_Component__c[] pcForTailList_before = [
                SELECT Id
                FROM Payroll_Component__c
                WHERE Contractor__r.Exit_Date__c = :exitDate
                AND Adjustment_Type__c = :salaryAdjustmentPicklistValue
            ];

            System.assert(pcForTailList_before.isEmpty() == false, 'List must not be empty.');

            // delete Payrolls
            Test.startTest();
            Model.LightningResponse responseAfterDeletion = LA_PayslipGenerationController.deletePayslips(JSON.serialize(payslipPartList));
            assertSuccessLightningResponse(responseAfterDeletion);
            Test.stopTest();

            // check that Payroll Component has been deleted
            Payroll_Component__c[] pcForTailList_after = [
                SELECT Id
                FROM Payroll_Component__c
                WHERE Contractor__r.Exit_Date__c = :exitDate
                AND Adjustment_Type__c = :salaryAdjustmentPicklistValue
            ];

            System.assert(pcForTailList_after.isEmpty(), 'List must be empty.');
        }
    }

    @IsTest
    static void test_deletePayslips_errorCode_1004() {
        // generate Payrolls for current PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
        assertSuccessLightningResponse(responseAfterGeneration);

        // simulate user selection for deletion payrolls
        Model.LightningResponse responseWithHistoricalPayslipsByResourceType = LA_PayslipGenerationController.getHistoricalPayslipsByResourceType(DEFAULT_DATE.month(),
                                                                                                                                                  DEFAULT_DATE.year(),
                                                                                                                                                  JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithHistoricalPayslipsByResourceType);

        LA_PayslipGenerationController.PayslipPart[] payslipPartList = (LA_PayslipGenerationController.PayslipPart[]) JSON.deserialize(responseWithHistoricalPayslipsByResourceType.data, LA_PayslipGenerationController.PayslipPart[].class);
        System.assert(!payslipPartList.isEmpty(), 'List must not be empty.');

        for (LA_PayslipGenerationController.PayslipPart payslipPart : payslipPartList) {

            for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {
                payslipInfo.isToDelete = true;
            }
        }

        // delete random Payroll
        delete [SELECT Id FROM Payroll__c LIMIT 1];

        // delete Payrolls
        Test.startTest();
            Model.LightningResponse responseAfterDeletion = LA_PayslipGenerationController.deletePayslips(JSON.serialize(payslipPartList));

            System.assert(!responseAfterDeletion.success, 'Response must not be successful.');
            System.assertEquals(LA_PayslipGenerationController.ERROR_CODE_1004, responseAfterDeletion.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_deletePayslips_errorCode_1005() {
        // generate Payrolls for current PCs
        Model.LightningResponse responseWithPayslipsByResourceType = LA_PayslipGenerationController.getPayslipsByResourceType(DEFAULT_DATE.month(), DEFAULT_DATE.year(), JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithPayslipsByResourceType);

        Model.LightningResponse responseAfterGeneration = LA_PayslipGenerationController.generatePayslips(DEFAULT_DATE.month(), DEFAULT_DATE.year(), SALARY_DATE_STRING, responseWithPayslipsByResourceType.data);
        assertSuccessLightningResponse(responseAfterGeneration);

        // simulate user selection for deletion payrolls
        Model.LightningResponse responseWithHistoricalPayslipsByResourceType = LA_PayslipGenerationController.getHistoricalPayslipsByResourceType(DEFAULT_DATE.month(),
                                                                                                                                                  DEFAULT_DATE.year(),
                                                                                                                                                  JSON.serialize(SELECTED_CONTRACTOR_INFO_LIST));
        assertSuccessLightningResponse(responseWithHistoricalPayslipsByResourceType);

        LA_PayslipGenerationController.PayslipPart[] payslipPartList = (LA_PayslipGenerationController.PayslipPart[]) JSON.deserialize(responseWithHistoricalPayslipsByResourceType.data, LA_PayslipGenerationController.PayslipPart[].class);
        System.assert(!payslipPartList.isEmpty(), 'List must not be empty.');

        for (LA_PayslipGenerationController.PayslipPart payslipPart : payslipPartList) {

            for (LA_PayslipGenerationController.PayslipInfo payslipInfo : payslipPart.payslipInfoList) {
                payslipInfo.isToDelete = true;
            }
        }

        // update random Payroll
        Payroll__c payroll = [SELECT Sum__c FROM Payroll__c LIMIT 1];
        payroll.Sum__c = 12345;

        // freeze - to get the difference with the last change
        codeFreeze(500);
        update payroll;

        // delete Payrolls
        Test.startTest();
            Model.LightningResponse responseAfterDeletion = LA_PayslipGenerationController.deletePayslips(JSON.serialize(payslipPartList));

            System.assert(!responseAfterDeletion.success, 'Response must not be successful.');
            System.assertEquals(LA_PayslipGenerationController.ERROR_CODE_1005, responseAfterDeletion.code, 'The error code must match.');
        Test.stopTest();
    }

    @IsTest
    static void test_isUserBlockedForGeneration() {
        Test.startTest();
            Model.LightningResponse response = LA_PayslipGenerationController.isUserBlockedForGeneration();

            assertSuccessLightningResponse(response);
            System.assertEquals(false, JSON.deserializeUntyped(response.data), 'Result must be "false".');
        Test.stopTest();
    }

    /*##################################################*/
    /*################# HELPER METHODS #################*/
    /*##################################################*/
    static void assertSuccessLightningResponse(Model.LightningResponse response) {
        System.assert(response.success, 'Response must be successful. RESPONSE: ' + JSON.serializePretty(response));
    }

    static void createDummyUser() {

        insert new User(
            ProfileId = UserInfo.getProfileId(),
            FirstName = 'FirstName',
            LastName = 'LastName',
            Username = FAKE_EMAIL,
            Email = FAKE_EMAIL,
            Alias = 'alias',
            TimeZoneSidKey = 'Europe/Helsinki',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            IsActive = true
        );
    }

    /*
     * @author: Dmytro Lambru
     * @description: to stop the execution of the code for a certain number of seconds
     * @param: milliseconds - the number of milliseconds to wait
     * @note: Warning! Per-Transaction Apex Limits! Maximum CPU time on the Salesforce servers | Synchronous Limit: 10,000 milliseconds | Asynchronous Limit: 60,000 milliseconds
     */
    public static void codeFreeze(Integer delayInMilliseconds) {
        Decimal startingTime = System.currentTimeMillis();

        while (System.currentTimeMillis() - startingTime < delayInMilliseconds)  {
            /* Do nothing until desired delay has passed */
        }
    }

    static LA_PayslipGenerationController.SelectedContractorInfo[] getSelectedContractorInfos() {
        LA_PayslipGenerationController.SelectedContractorInfo[] selectedContractorInfoList = new LA_PayslipGenerationController.SelectedContractorInfo[]{};

        Account[] contractorPersonAccountList = [
            SELECT Id
            FROM Account
            WHERE IsPersonAccount = TRUE
            AND Name LIKE :ContractorTestDataFactory.DEFAULT_CONTRACTOR_NAME + '%'
        ];

        for (Account account : contractorPersonAccountList) {
            LA_PayslipGenerationController.SelectedContractorInfo selectedContractorInfo = new LA_PayslipGenerationController.SelectedContractorInfo();
            selectedContractorInfo.personAccountId = account.Id;

            selectedContractorInfoList.add(selectedContractorInfo);
        }

        return selectedContractorInfoList;
    }

    static void createPayrollComponentsForContractors() {
        Account[] contractorPersonAccountList = [
            SELECT Contractor__r.Id,
                Contractor__r.CurrencyIsoCode
            FROM Account
            WHERE IsPersonAccount = TRUE
        ];

        Payroll_Component__c[] payrollComponentList = new Payroll_Component__c[]{};
        String approvedApprovalStatus = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
        Id bonusRecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_BONUS.getRecordTypeId();
        Id deductionRecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_DEDUCTION.getRecordTypeId();
        Id overtimeRecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_OVERTIME.getRecordTypeId();
        Id reimbursementRecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId();
        Id recurrentBonusRecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_RECURRENT_BONUS.getRecordTypeId();
        Id recurrentDeductionRecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_RECURRENT_DEDUCTION.getRecordTypeId();
        Id recurrentInsuranceRecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_INSURANCE.getRecordTypeId();

        Date recurrentStartDate = DEFAULT_DATE.addMonths(-1);
        Date recurrentEndDate = DEFAULT_DATE.addMonths(1);

        for (Account account : contractorPersonAccountList) {
            // ordinary (except RT Adjustments and Insurance)
            Payroll_Component__c payrollComponentBonus = createPayrollComponentWithRTBonus(account, bonusRecordTypeId, approvedApprovalStatus);
            Payroll_Component__c payrollComponentDeduction = createPayrollComponentWithRTDeduction(account, deductionRecordTypeId, approvedApprovalStatus);
            Payroll_Component__c payrollComponentOvertime = createPayrollComponentWithRTOvertime(account, overtimeRecordTypeId, approvedApprovalStatus);
            Payroll_Component__c payrollComponentReimbursement = createPayrollComponentWithRTReimbursement(account, reimbursementRecordTypeId, approvedApprovalStatus);

            // recurrent
            Payroll_Component__c payrollComponentRecurrentBonus = createPayrollComponentWithRTRecurrentBonus(account, recurrentBonusRecordTypeId, approvedApprovalStatus, recurrentStartDate, recurrentEndDate);
            Payroll_Component__c payrollComponentRecurrentDeduction = createPayrollComponentWithRTRecurrentDeduction(account, recurrentDeductionRecordTypeId, approvedApprovalStatus, recurrentStartDate, recurrentEndDate);
            Payroll_Component__c payrollComponentRecurrentInsurance = createPayrollComponentWithRTRecurrentInsurance(account, recurrentInsuranceRecordTypeId, approvedApprovalStatus, recurrentStartDate, recurrentEndDate);

            payrollComponentList.addAll(new Payroll_Component__c[]{
                payrollComponentBonus, payrollComponentDeduction, payrollComponentOvertime, payrollComponentReimbursement,
                payrollComponentRecurrentBonus, payrollComponentRecurrentDeduction, payrollComponentRecurrentInsurance
            });
        }

        insert payrollComponentList;
    }

    static Payroll_Component__c createPayrollComponentWithRTBonus(Account personAccount, Id recordTypeId, String approvedApprovalStatus) {
        Payroll_Component__c payrollComponent = new Payroll_Component__c();

        payrollComponent.RecordTypeId = recordTypeId;
        payrollComponent.Contractor__c = personAccount.Contractor__r.Id;
        payrollComponent.Account__c = personAccount.Id;
        payrollComponent.Approval_Status__c = approvedApprovalStatus;
        payrollComponent.CurrencyIsoCode = NOT_CORPORATE_CURRENCY_ISO_CODE;
        payrollComponent.StartDate__c = DEFAULT_DATE;
        payrollComponent.EndDate__c = DEFAULT_DATE;
        payrollComponent.Reason__c = DEFAULT_REASON;
        payrollComponent.SumType__c = PAYROLL_COMPONENT_SUM_TYPE_INCREMENT;
        payrollComponent.Sum__c = 100;

        return payrollComponent;
    }

    static Payroll_Component__c createPayrollComponentWithRTDeduction(Account personAccount, Id recordTypeId, String approvedApprovalStatus) {
        Payroll_Component__c payrollComponent = new Payroll_Component__c();

        payrollComponent.RecordTypeId = recordTypeId;
        payrollComponent.Contractor__c = personAccount.Contractor__r.Id;
        payrollComponent.Account__c = personAccount.Id;
        payrollComponent.Approval_Status__c = approvedApprovalStatus;
        payrollComponent.CurrencyIsoCode = NOT_CORPORATE_CURRENCY_ISO_CODE;
        payrollComponent.StartDate__c = DEFAULT_DATE;
        payrollComponent.EndDate__c = DEFAULT_DATE;
        payrollComponent.Reason__c = DEFAULT_REASON;
        payrollComponent.SumType__c = PAYROLL_COMPONENT_SUM_TYPE_DECREMENT;
        payrollComponent.Sum__c = 50;

        return payrollComponent;
    }

    static Payroll_Component__c createPayrollComponentWithRTOvertime(Account personAccount, Id recordTypeId, String approvedApprovalStatus) {
        Payroll_Component__c payrollComponent = new Payroll_Component__c();

        payrollComponent.RecordTypeId = recordTypeId;
        payrollComponent.Approval_Status__c = approvedApprovalStatus;
        payrollComponent.Contractor__c = personAccount.Contractor__r.Id;
        payrollComponent.Account__c = personAccount.Id;
        payrollComponent.CurrencyIsoCode = personAccount.Contractor__r.CurrencyIsoCode;
        payrollComponent.StartDate__c = DEFAULT_DATE;
        payrollComponent.EndDate__c = DEFAULT_DATE;
        payrollComponent.Reason__c = DEFAULT_REASON;
        payrollComponent.SumType__c = PAYROLL_COMPONENT_SUM_TYPE_INCREMENT;
        payrollComponent.Sum__c = 100;

        return payrollComponent;
    }

    static Payroll_Component__c createPayrollComponentWithRTReimbursement(Account personAccount, Id recordTypeId, String approvedApprovalStatus) {
        Payroll_Component__c payrollComponent = new Payroll_Component__c();

        payrollComponent.RecordTypeId = recordTypeId;
        payrollComponent.Approval_Status__c = approvedApprovalStatus;
        payrollComponent.Contractor__c = personAccount.Contractor__r.Id;
        payrollComponent.Account__c = personAccount.Id;
        payrollComponent.CurrencyIsoCode = CORPORATE_CURRENCY_ISO_CODE;
        payrollComponent.StartDate__c = DEFAULT_DATE;
        payrollComponent.EndDate__c = DEFAULT_DATE;
        payrollComponent.Reason__c = DEFAULT_REASON;
        payrollComponent.SumType__c = PAYROLL_COMPONENT_SUM_TYPE_INCREMENT;
        payrollComponent.Sum__c = 100;

        return payrollComponent;
    }

    static Payroll_Component__c createPayrollComponentWithRTRecurrentBonus(Account personAccount,
                                                                            Id recordTypeId,
                                                                            String approvedApprovalStatus,
                                                                            Date recurrentStartDate,
                                                                            Date recurrentEndDate) {
        Payroll_Component__c payrollComponent = new Payroll_Component__c();

        payrollComponent.RecordTypeId = recordTypeId;
        payrollComponent.Recurrent__c = true;
        payrollComponent.Contractor__c = personAccount.Contractor__r.Id;
        payrollComponent.Account__c = personAccount.Id;
        payrollComponent.Approval_Status__c = approvedApprovalStatus;
        payrollComponent.CurrencyIsoCode = CORPORATE_CURRENCY_ISO_CODE;
        payrollComponent.StartDate__c = recurrentStartDate;
        payrollComponent.EndDate__c = recurrentEndDate;
        payrollComponent.Reason__c = DEFAULT_REASON;
        payrollComponent.SumType__c = PAYROLL_COMPONENT_SUM_TYPE_INCREMENT;
        payrollComponent.Sum__c = 200;

        return payrollComponent;
    }

    static Payroll_Component__c createPayrollComponentWithRTRecurrentDeduction(Account personAccount,
                                                                                Id recordTypeId,
                                                                                String approvedApprovalStatus,
                                                                                Date recurrentStartDate,
                                                                                Date recurrentEndDate) {
        Payroll_Component__c payrollComponent = new Payroll_Component__c();

        payrollComponent.RecordTypeId = recordTypeId;
        payrollComponent.Recurrent__c = true;
        payrollComponent.Contractor__c = personAccount.Contractor__r.Id;
        payrollComponent.Account__c = personAccount.Id;
        payrollComponent.Approval_Status__c = approvedApprovalStatus;
        payrollComponent.CurrencyIsoCode = CORPORATE_CURRENCY_ISO_CODE;
        payrollComponent.StartDate__c = recurrentStartDate;
        payrollComponent.EndDate__c = recurrentEndDate;
        payrollComponent.Reason__c = DEFAULT_REASON;
        payrollComponent.SumType__c = PAYROLL_COMPONENT_SUM_TYPE_DECREMENT;
        payrollComponent.Sum__c = 100;

        return payrollComponent;
    }

    static Payroll_Component__c createPayrollComponentWithRTRecurrentInsurance(Account personAccount,
                                                                                Id recordTypeId,
                                                                                String approvedApprovalStatus,
                                                                                Date recurrentStartDate,
                                                                                Date recurrentEndDate) {
        Payroll_Component__c payrollComponent = new Payroll_Component__c();

        payrollComponent.RecordTypeId = recordTypeId;
        payrollComponent.Recurrent__c = true;
        payrollComponent.Contractor__c = personAccount.Contractor__r.Id;
        payrollComponent.Account__c = personAccount.Id;
        payrollComponent.Approval_Status__c = approvedApprovalStatus;
        payrollComponent.CurrencyIsoCode = CORPORATE_CURRENCY_ISO_CODE;
        payrollComponent.StartDate__c = recurrentStartDate;
        payrollComponent.EndDate__c = recurrentEndDate;
        payrollComponent.Reason__c = DEFAULT_REASON;
        payrollComponent.SumType__c = PAYROLL_COMPONENT_SUM_TYPE_INCREMENT;
        payrollComponent.Sum__c = 50;

        return payrollComponent;
    }
}