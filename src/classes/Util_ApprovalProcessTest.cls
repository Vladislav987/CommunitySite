/**
 * Created by IlliaLuhovyi on 6/2/2020.
 */

@IsTest
private class Util_ApprovalProcessTest {
    private static final String DEFAULT_CURRENCY = 'USD';
    private static Util_ApprovalProcess process = new Util_ApprovalProcess();

    @TestSetup
    static void doSetup() {
        Account account = new Account();
        account.Name = 'Test Account';
        account.CurrencyIsoCode = DEFAULT_CURRENCY;

        insert account;

        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;

        User user = new User();
        user.Username = 'supertestuserofthistest@supertest.com';
        user.Email = 'supertestuserofthistest@supertest.com';
        user.LastName = 'Tester';
        user.Alias = 'Company';
        user.TimeZoneSidKey = 'Europe/London';
        user.LocaleSidKey = 'en_GB';
        user.LanguageLocaleKey = 'en_US';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.ProfileId = profileId;

        insert user;

        Payroll_Component__c payrollComponent = new Payroll_Component__c();
        payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
        payrollComponent.Account__c = account.Id;
        payrollComponent.RecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId();
        payrollComponent.Approver__c = user.Id;

        insert payrollComponent;

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(payrollComponent.Id);
        req.setComments('Test comment');
        req.setNextApproverIds(new Id[]{
                user.Id
        });
        req.setProcessDefinitionNameOrId('Reimbursement_Approval_Process');
        Approval.process(req);

    }

    @IsTest
    static void testGetProcessInstanceId() {
        Id payrollComponentId = [SELECT Id FROM Payroll_Component__c LIMIT 1].Id;

        Test.startTest();
        Id processInstanceId = process.getProcessInstanceId(payrollComponentId);
        Test.stopTest();

        System.assert(String.isNotBlank(processInstanceId), 'Id should not be blank!');
    }

    @IsTest
    static void testGetProcessInstanceWorkitemId() {
        Id payrollComponentId = [SELECT Id FROM Payroll_Component__c LIMIT 1].Id;

        Test.startTest();
        Id processInstanceWorkitemId = process.getProcessInstanceWorkitemId(payrollComponentId);
        Test.stopTest();

        System.assert(String.isNotBlank(processInstanceWorkitemId), 'Id should not be blank!');
    }

    @IsTest
    static void testApproveRecord() {
        Test.startTest();
        Payroll_Component__c payrollComponent = [SELECT Id FROM Payroll_Component__c LIMIT 1];
        process.approveRecord(payrollComponent.Id);
        Test.stopTest();

        Payroll_Component__c payrollComponentAfterApprove = [SELECT Id, Approval_Status__c FROM Payroll_Component__c LIMIT 1];

        System.assertEquals(
                PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED),
                payrollComponentAfterApprove.Approval_Status__c
        );
    }

    @IsTest
    static void testRejectRecord() {
        Test.startTest();
        Payroll_Component__c payrollComponent = [SELECT Id FROM Payroll_Component__c LIMIT 1];
        process.rejectRecord(payrollComponent.Id);
        Test.stopTest();

        Payroll_Component__c payrollComponentAfterReject = [SELECT Id, Approval_Status__c FROM Payroll_Component__c LIMIT 1];

        System.assertEquals(
                PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.REJECTED),
                payrollComponentAfterReject.Approval_Status__c
        );
    }
}