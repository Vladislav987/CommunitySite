/**
 * Created by IlliaLuhovyi on 4/27/2020.
 */

@IsTest
private class LW_ReimbursementsControllerTest {
    private static final String DEFAULT_CONTRACTOR_NAME = UserInfo.getName();
    private static final Date DEFAULT_DATE = Date.newInstance(2025, 1, 1);
    private static final String DEFAULT_CURRENCY = 'USD';

    @TestSetup
    static void setup() {
        Contractor__c contractor = new Contractor__c();
        contractor.Name = DEFAULT_CONTRACTOR_NAME;
        contractor.Resource_Type__c = ContractorSelector.RESOURCE_TYPE_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceTypePicklistKey.SFDC_DEVELOPER);
        contractor.Resource_Level__c = ContractorSelector.RESOURCE_LEVEL_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceLevelPicklistKey.TRAINEE);

        insert contractor;

        Account account = new Account();
        account.RecordTypeId = AccountSelector.RECORD_TYPE_INFO_PERSON_ACCOUNT.getRecordTypeId();
        account.LastName = contractor.Name;
        account.Contractor__c = contractor.Id;

        insert account;

        User user = [SELECT Employee_AccountId__c FROM User WHERE Id = :UserInfo.getUserId()];
        user.Employee_AccountId__c = account.Id;

        update user;

        Project__c project = new Project__c();
        project.Name = 'Project';
        project.Contract_type__c = ProjectSelector.CONTRACT_TYPE_PICKLIST_VALUES_MAP.get(ProjectSelector.ContractTypePicklistKey.FIXED_COST);
        project.Project_type__c = ProjectSelector.PROJECT_TYPE_PICKLIST_VALUES_MAP.get(ProjectSelector.ProjectTypePicklistKey.OUTSTAFF);
        project.Start_date__c = System.today();
        project.End_date__c = Util.dateToEndOfMonth(DEFAULT_DATE);

        insert project;

        Allocation__c allocation = new Allocation__c();
        allocation.Project__c = project.Id;
        allocation.Contractor__c = contractor.Id;
        allocation.Allocation__c = 100;
        allocation.Allocation_Type__c = AllocationSelector.ALLOCATION_TYPE_PICKLIST_VALUES_MAP.get(AllocationSelector.AllocationTypePicklistKey.BILLABLE);
        allocation.Start_date__c = System.today();
        allocation.End_date__c = Util.dateToEndOfMonth(DEFAULT_DATE);

        insert allocation;

        Budget_transaction__c budgetTransaction = new Budget_transaction__c();
        budgetTransaction.Project__c = project.Id;

        insert budgetTransaction;

        Travel_request__c travelRequest = new Travel_request__c();
        travelRequest.Budget_transaction__c = budgetTransaction.Id;
        travelRequest.Country__c = TravelRequestSelector.COUNTRY_PICKLIST_VALUES_MAP.get(TravelRequestSelector.CountryPicklistKey.UKRAINE);
        travelRequest.City__c = TravelRequestSelector.CITY_PICKLIST_VALUES_MAP.get(TravelRequestSelector.CityPicklistKey.KYIV);
        travelRequest.Start_Date__c = System.today();
        travelRequest.End_Date__c = System.today();

        insert travelRequest;

        Payroll_Component__c payrollComponent = new Payroll_Component__c();
        payrollComponent.Sum__c = 100;
        payrollComponent.CurrencyIsoCode = DEFAULT_CURRENCY;
        payrollComponent.Travel_request__c = travelRequest.Id;
        payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
        payrollComponent.Account__c = account.Id;

        insert payrollComponent;

        Payroll_Component_Item__c[] payrollComponentItems = new Payroll_Component_Item__c[]{};

        for(Integer i = 0; i < 4; i++) {
            Payroll_Component_Item__c payrollComponentItem = new Payroll_Component_Item__c();
            payrollComponentItem.Sum__c = 100 + i;
            payrollComponentItem.CurrencyIsoCode = DEFAULT_CURRENCY;
            payrollComponentItem.Payroll_Component__c = payrollComponent.Id;
            payrollComponentItem.Comment__c = 'Comment_' + i;

            payrollComponentItems.add(payrollComponentItem);
        }

        insert payrollComponentItems;

        List<ContentVersion> lstContentVersions = new List<ContentVersion>();
        List<ContentDocumentLink> lstContentDocumentLinks = new List<ContentDocumentLink>();

        for(Integer i = 0; i < 4; i++) {
            ContentVersion cv = new ContentVersion();
            cv.Title = 'File_Name' + i;
            cv.PathOnClient = '/' + cv.Title;
            cv.VersionData = EncodingUtil.base64Decode('File Data' + i);

            lstContentVersions.add(cv);
        }

        insert lstContentVersions;

        for(ContentVersion cv: lstContentVersions) {
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

            ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
                    ContentDocumentId = contentDocumentId, LinkedEntityId = payrollComponent.Id, ShareType = 'I', Visibility = 'AllUsers'
            );

            lstContentDocumentLinks.add(contentDocumentLink);
        }

        insert lstContentDocumentLinks;

    }

    @IsTest
    static void getAccountIdTest() {
        Test.startTest();
        Id accountId = LW_ReimbursementsController.getAccountId();
        Test.stopTest();

        System.assert(String.isNotBlank(accountId), 'Account Id should not be blank!');
    }

    @IsTest
    static void getContractorProjectsTest() {
        final Boolean DEFAULT_STATUS = true;

        Test.startTest();
        LW_ReimbursementsController.ProjectWrapper[] projectWrapperInfo = LW_ReimbursementsController.getContractorProjects(DEFAULT_STATUS);
        Test.stopTest();

        System.assert(!projectWrapperInfo.isEmpty(), 'List should not be empty!');

        for(LW_ReimbursementsController.ProjectWrapper projectWrapperItem: projectWrapperInfo) {
            System.assert(String.isNotBlank(projectWrapperItem.Name), 'Name should not be blank!');
            System.assert(String.isNotBlank(projectWrapperItem.Id), 'Id should not be blank!');

            for(LW_ReimbursementsController.TravelWrapper travelWrapper: projectWrapperItem.travelArray) {
                System.assert(String.isNotBlank(travelWrapper.Id),  'Id should not be blank');

                for(LW_ReimbursementsController.PayrollComponentWrapper payrollComponentWrapper: travelWrapper.payrollComponentArray) {
                    System.assert(String.isNotBlank(payrollComponentWrapper.Id),  'Id should not be blank');
                }
            }
        }

    }

    @IsTest
    static void getCurrencyTypesTest() {
        Test.startTest();
        CurrencyType[] currencyTypeList = LW_ReimbursementsController.getCurrencyTypes();
        Test.stopTest();

        System.assert(!currencyTypeList.isEmpty(), 'List should not be empty!');
    }

    @IsTest
    static void saveFilesTest() {
        final String DEFAULT_FILE_NAME = 'Default File Name';
        final String DEFAULT_FILE_DATA = 'Default FIle Data';

        Payroll_Component__c payrollComponent = [SELECT Id FROM Payroll_Component__c];
        LW_ReimbursementsController.FilesWrapper[] filesWrapperInfo = new LW_ReimbursementsController.FilesWrapper[]{};

        for (Integer i = 0; i < 3; i++) {
            LW_ReimbursementsController.FilesWrapper filesWrapper = new LW_ReimbursementsController.FilesWrapper();

            filesWrapper.fileName = DEFAULT_FILE_NAME;
            filesWrapper.fileData = DEFAULT_FILE_DATA;

            filesWrapperInfo.add(filesWrapper);
        }

        Test.startTest();
        LW_ReimbursementsController.saveFiles(payrollComponent.Id, filesWrapperInfo);
        Test.stopTest();

        ContentVersion[] contentVersionList = [SELECT Id, Title, VersionData FROM ContentVersion WHERE Title = :DEFAULT_FILE_NAME];

        for (ContentVersion contentVersion : contentVersionList) {
            System.assertEquals(DEFAULT_FILE_NAME, contentVersion.Title);
            System.assert(String.isNotBlank(EncodingUtil.base64Encode(contentVersion.VersionData)), 'File Data should not be empty!');
        }
    }

    @IsTest
    static void deleteFilesTest() {
        ContentVersion[] contentVersionList = [SELECT Id, Title, VersionData, ContentDocumentId FROM ContentVersion];
        LW_ReimbursementsController.FilesWrapper[] filesWrappers = new LW_ReimbursementsController.FilesWrapper[]{};

        for(ContentVersion contentVersion: contentVersionList) {
            LW_ReimbursementsController.FilesWrapper fileWrapper = new LW_ReimbursementsController.FilesWrapper();

            fileWrapper.contentDocumentId = contentVersion.ContentDocumentId;
            fileWrapper.fileName = contentVersion.Title;

            filesWrappers.add(fileWrapper);
        }

        Test.startTest();
        LW_ReimbursementsController.deleteFiles(filesWrappers);
        Test.stopTest();

        ContentDocument[] contentDocuments = [SELECT Id FROM ContentDocument];

        for(ContentDocument contentDocument: contentDocuments) {
            System.assert(String.isBlank(contentDocument.Id), 'ContentDocument should be deleted');
        }
    }

    @IsTest
    static void getPayrollComponentAttachmentsTest() {
        Id payrollComponentId = [SELECT Id FROM Payroll_Component__c].Id;

        Test.startTest();
        LW_ReimbursementsController.FilesWrapper[] filesWrappers = LW_ReimbursementsController.getPayrollComponentAttachments(payrollComponentId);
        Test.stopTest();

        for(LW_ReimbursementsController.FilesWrapper filesWrapper: filesWrappers) {
            System.assert(String.isNotBlank(filesWrapper.contentDocumentId), 'Id should not be blank');
        }
    }

    @IsTest
    static void getPayrollComponentItemsTest() {
        Id payrollComponentId = [SELECT Id FROM Payroll_Component__c].Id;

        Test.startTest();
        LW_ReimbursementsController.PayrollComponentItemInfo[] payrollComponentItemInfos = LW_ReimbursementsController.getPayrollComponentItems(payrollComponentId);
        Test.stopTest();

        for(LW_ReimbursementsController.PayrollComponentItemInfo payrollComponentItemInfo: payrollComponentItemInfos) {
            System.assert(String.isNotBlank(payrollComponentItemInfo.id), 'Is should not be empty');
            System.assert(String.isNotBlank(payrollComponentItemInfo.payrollComponentId), 'Payroll_Component__c should not be empty');
            System.assert(payrollComponentItemInfo.sum > 0, 'Sum__c should be more than 0');
            System.assert(String.isNotBlank(payrollComponentItemInfo.curr), 'CurrencyIsoCode should not be blank');
        }
    }

    @IsTest
    static void setPayrollComponentTest() {
        final String DEFAULT_FILE_NAME = 'Default File Name';
        final String DEFAULT_FILE_DATA = 'Default FIle Data';

        Travel_request__c travelRequest = [ SELECT Id FROM Travel_request__c LIMIT 1];
        Project__c project = [ SELECT Id FROM Project__c LIMIT 1 ];
        LW_ReimbursementsController.PayrollData[] payrollDataList = new LW_ReimbursementsController.PayrollData[]{};
        LW_ReimbursementsController.PayrollData payrollData = new LW_ReimbursementsController.PayrollData();

        payrollData.sum = 50;
        payrollData.travel = travelRequest.Id;
        payrollData.comment = 'Test';
        payrollData.curr = DEFAULT_CURRENCY;

        payrollDataList.add(payrollData);

        LW_ReimbursementsController.FilesWrapper[] filesWrapperInfo = new LW_ReimbursementsController.FilesWrapper[]{};
        LW_ReimbursementsController.FilesWrapper filesWrapper = new LW_ReimbursementsController.FilesWrapper();

        filesWrapper.fileName = DEFAULT_FILE_NAME;
        filesWrapper.fileData = DEFAULT_FILE_DATA;

        filesWrapperInfo.add(filesWrapper);

        Test.startTest();
        LW_ReimbursementsController.LightningResponse response = LW_ReimbursementsController.setPayrollComponent(JSON.serialize(payrollDataList), travelRequest.Id, project.Id, JSON.serialize(filesWrapperInfo));
        Test.stopTest();

        LW_ReimbursementsController.PayrollComponentWrapper[] payrollComponentWrapperResult = (LW_ReimbursementsController.PayrollComponentWrapper[]) JSON.deserialize(response.data, LW_ReimbursementsController.PayrollComponentWrapper[].class);

        System.assert(!payrollComponentWrapperResult.isEmpty(), 'List should not be empty!');

        for(LW_ReimbursementsController.PayrollComponentWrapper payrollComponentWrapperItem: payrollComponentWrapperResult){
            System.assert(String.isNotBlank(payrollComponentWrapperItem.Id), 'Id should not be blank!');
            System.assert(String.isNotBlank(payrollComponentWrapperItem.CurrencyCode), 'CurrencyIsoCode should not be blank!');
            System.assert(String.isNotBlank(payrollComponentWrapperItem.Status), 'Status should not be blank!');
            System.assert(String.isNotBlank(payrollComponentWrapperItem.TravelId), 'TravelId should not be blank!');
            System.assert(payrollComponentWrapperItem.Sum != null, 'Sum should not be null');
        }

    }

    @IsTest
    static void getPayrollComponentWithFilesAndItemsTest() {
        Id payrollComponentId = [SELECT Id FROM Payroll_Component__c].Id;

        Test.startTest();
        Model.LightningResponse response = LW_ReimbursementsController.getPayrollComponentWithFilesAndItems(payrollComponentId);
        Test.stopTest();

        LW_ReimbursementsController.PayrollComponentWrapper payrollComponentWrapper = (LW_ReimbursementsController.PayrollComponentWrapper) JSON.deserialize(response.data, LW_ReimbursementsController.PayrollComponentWrapper.class);


        System.assert(String.isNotBlank(payrollComponentWrapper.Id), 'Id should not be blank');
        System.assert(payrollComponentWrapper.Sum > 0, 'Sum__c should be more than 0');
    }

    @IsTest
    static void updateFilesTest() {
        Payroll_Component__c payrollComponent = [SELECT Id, CurrencyIsoCode, Sum__c FROM Payroll_Component__c LIMIT 1];
        LW_ReimbursementsController.PayrollComponentWrapper payrollComponentWrapper = new LW_ReimbursementsController.PayrollComponentWrapper();
        LW_ReimbursementsController.PayrollComponentItemInfo[] payrollComponentItemInfos = LW_ReimbursementsController.getPayrollComponentItems(payrollComponent.Id);
        LW_ReimbursementsController.FilesWrapper[] filesWrappers = LW_ReimbursementsController.getPayrollComponentAttachments(payrollComponent.Id);

        filesWrappers[0].isDeleted = true;

        LW_ReimbursementsController.FilesWrapper filesWrapper = new LW_ReimbursementsController.FilesWrapper();

        filesWrapper.isInserted = true;
        filesWrapper.fileName = 'Name';
        filesWrapper.fileData = 'Data';

        filesWrappers.add(filesWrapper);

        payrollComponentWrapper.Id = payrollComponent.Id;
        payrollComponentWrapper.Sum = payrollComponent.Sum__c;
        payrollComponentWrapper.CurrencyCode = payrollComponent.CurrencyIsoCode;

        payrollComponentWrapper.payrollComponentItemInfo = payrollComponentItemInfos;
        payrollComponentWrapper.filesWrappers = filesWrappers;


        Test.startTest();
        LW_ReimbursementsController.updateFiles(JSON.serialize(payrollComponentWrapper));
        Test.stopTest();
    }

    @IsTest
    static void updatePayrollComponentItemsTest() {
        Payroll_Component__c payrollComponent = [SELECT Id, CurrencyIsoCode, Sum__c FROM Payroll_Component__c LIMIT 1];
        LW_ReimbursementsController.PayrollComponentWrapper payrollComponentWrapper = new LW_ReimbursementsController.PayrollComponentWrapper();
        LW_ReimbursementsController.PayrollComponentItemInfo[] payrollComponentItemInfos = LW_ReimbursementsController.getPayrollComponentItems(payrollComponent.Id);
        LW_ReimbursementsController.FilesWrapper[] filesWrappers = new LW_ReimbursementsController.FilesWrapper[]{};

        payrollComponentWrapper.Id = payrollComponent.Id;
        payrollComponentWrapper.Sum = payrollComponent.Sum__c;
        payrollComponentWrapper.CurrencyCode = payrollComponent.CurrencyIsoCode;

        payrollComponentItemInfos[0].sum = 100;
        payrollComponentItemInfos[0].isUpdated = true;
        payrollComponentItemInfos[1].isDeleted = true;

        Payroll_Component_Item__c payrollComponentItem = new Payroll_Component_Item__c();
        payrollComponentItem.Payroll_Component__c = payrollComponent.Id;
        payrollComponentItem.CurrencyIsoCode = DEFAULT_CURRENCY;
        payrollComponentItem.Sum__c = 50;

        LW_ReimbursementsController.PayrollComponentItemInfo payrollComponentItemInfo = new LW_ReimbursementsController.PayrollComponentItemInfo(payrollComponentItem, 4);
        payrollComponentItemInfo.isInserted = true;

        payrollComponentItemInfos.add(payrollComponentItemInfo);

        payrollComponentWrapper.payrollComponentItemInfo = payrollComponentItemInfos;
        payrollComponentWrapper.filesWrappers = filesWrappers;

        Test.startTest();
        LW_ReimbursementsController.editPayrollComponentItems(JSON.serialize(payrollComponentWrapper));
        Test.stopTest();
    }

    @IsTest
    static void updatePayrollComponentTest() {
        Id projectId = [SELECT Id FROM Project__c].Id;
        Payroll_Component__c payrollComponent = [SELECT Id, CurrencyIsoCode, Sum__c FROM Payroll_Component__c LIMIT 1];
        LW_ReimbursementsController.PayrollComponentWrapper payrollComponentWrapper = new LW_ReimbursementsController.PayrollComponentWrapper();
        LW_ReimbursementsController.PayrollComponentItemInfo[] payrollComponentItemInfos = LW_ReimbursementsController.getPayrollComponentItems(payrollComponent.Id);
        LW_ReimbursementsController.FilesWrapper[] filesWrappers = new LW_ReimbursementsController.FilesWrapper[]{};

        payrollComponentWrapper.Id = payrollComponent.Id;
        payrollComponentWrapper.Sum = payrollComponent.Sum__c;
        payrollComponentWrapper.CurrencyCode = payrollComponent.CurrencyIsoCode;

        payrollComponentItemInfos[0].sum = 100;
        payrollComponentItemInfos[0].isUpdated = true;
        payrollComponentItemInfos[1].isDeleted = true;

        Payroll_Component_Item__c payrollComponentItem = new Payroll_Component_Item__c();
        payrollComponentItem.Payroll_Component__c = payrollComponent.Id;
        payrollComponentItem.CurrencyIsoCode = DEFAULT_CURRENCY;
        payrollComponentItem.Sum__c = 50;

        LW_ReimbursementsController.PayrollComponentItemInfo payrollComponentItemInfo = new LW_ReimbursementsController.PayrollComponentItemInfo(payrollComponentItem, 4);
        payrollComponentItemInfo.isInserted = true;

        payrollComponentItemInfos.add(payrollComponentItemInfo);

        payrollComponentWrapper.payrollComponentItemInfo = payrollComponentItemInfos;
        payrollComponentWrapper.filesWrappers = filesWrappers;

        Test.startTest();
        Model.LightningResponse response = LW_ReimbursementsController.updatePayrollComponent(payrollComponent.Id, projectId, JSON.serialize(payrollComponentWrapper));
        Test.stopTest();

        LW_ReimbursementsController.PayrollComponentWrapper payrollComponentWrapper2 = (LW_ReimbursementsController.PayrollComponentWrapper) JSON.deserialize(response.data, LW_ReimbursementsController.PayrollComponentWrapper.class);


        System.assert(String.isNotBlank(payrollComponentWrapper2.Id), 'Id should not be blank');
        System.assert(payrollComponentWrapper2.Sum != payrollComponent.Sum__c, 'Sum__c should be equal to previous Sum__c');
    }
}