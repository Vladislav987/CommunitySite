/**
 * Created by IlliaLuhovyi on 4/16/2020.
 */

public without sharing class LW_ReimbursementsController {
    private static LightningResponse response = new LightningResponse();
    private final static String APPROVAL_PROCESS = 'Reimbursement_Two_Step_Approval';

    @AuraEnabled
    public static ProjectWrapper[] getContractorProjects(Boolean status) {
        Id contractorId = getContractorId();

        Map<Id, Project__c> contractorProjects = getProjects(contractorId);
        Map<Id, Travel_request__c> contractorBudgeTravelRequestsByIds = getTravelRequests(contractorId, contractorProjects);
        Map<Id, Payroll_Component__c> payrollComponentMap = getPayrollComponentsInProject(contractorBudgeTravelRequestsByIds);

        return createMainWrapper(contractorProjects, contractorBudgeTravelRequestsByIds, payrollComponentMap, status);
    }

    @AuraEnabled
    public static LightningResponse setPayrollComponent(String payrollDataStrJson, String travelRequestId, String projectId, String fileData) {
        try {
            PayrollComponentWrapper[] payrollComponentWrapperArray = new PayrollComponentWrapper[]{};
            String contractorCurrCode = [SELECT CurrencyIsoCode FROM Allocation__c WHERE Project__c = :projectId LIMIT 1].CurrencyIsoCode;
            Decimal totalSum = 0;

            Payroll_Component__c payrollComponent = createPayrollComponent(projectId, travelRequestId, fileData, contractorCurrCode, totalSum);
            createPayrollComponentItem(payrollComponent, payrollDataStrJson, totalSum, contractorCurrCode);
            sendToApproval(payrollComponent.Id);

            User projectManager = [SELECT Id, FirstName, LastName FROM User WHERE Id = :payrollComponent.Approver__c LIMIT 1];

            PayrollComponentWrapper payroll = new PayrollComponentWrapper();
            payroll.Id = payrollComponent.Id;
            payroll.Name = payrollComponent.Name;
            payroll.TravelId = payrollComponent.Travel_request__c;
            payroll.Sum = payrollComponent.Sum__c;
            payroll.CurrencyCode = payrollComponent.CurrencyIsoCode;
            payroll.Status = payrollComponent.Approval_Status__c;
            payroll.projectId = payrollComponent.Project__c;
            payroll.projectManager = projectManager.FirstName + ' ' + projectManager.LastName;
            payroll.isEditable = true;

            payrollComponentWrapperArray.add(payroll);

            response.setResult(JSON.serialize(payrollComponentWrapperArray));

        } catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LW_ReimbursementsController.class));
        }



        return response;
    }

    @AuraEnabled
    public static CurrencyType[] getCurrencyTypes() {
        return [ SELECT IsoCode, IsCorporate  FROM CurrencyType  WHERE IsActive = TRUE ];
    }

    @AuraEnabled
    public static LightningResponse getPayrollComponentWithFilesAndItems(Id payrollComponentId) {
        try {

            if ( String.isEmpty(payrollComponentId) ) {
                return response.setError(401);
            }

            Payroll_Component__c[] payrollComponents = new PayrollComponentSelector().getComponentById(payrollComponentId);
            Payroll_Component__c payrollComponent;

            if(!payrollComponents.isEmpty()) {
                payrollComponent = payrollComponents[0];
            }

            PayrollComponentWrapper payrollComponentWrapper = new PayrollComponentWrapper();

            payrollComponentWrapper.Id = payrollComponent.Id;
            payrollComponentWrapper.Sum = payrollComponent.Sum__c;
            payrollComponentWrapper.CurrencyCode = payrollComponent.CurrencyIsoCode;

            payrollComponentWrapper.payrollComponentItemInfo = getPayrollComponentItems(payrollComponentId);
            payrollComponentWrapper.filesWrappers = getPayrollComponentAttachments(payrollComponentId);


            response.setResult(JSON.serialize(payrollComponentWrapper, true));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LW_ReimbursementsController.class));
        }

        return response;
    }

    @AuraEnabled
    public static LightningResponse updatePayrollComponent(Id payrollComponentId, Id projectId, String payrollComponentJson) {
        try {
            editPayrollComponentItems(payrollComponentJson);
            updateFiles(payrollComponentJson);

            Payroll_Component_Item__c[] payrollComponentItems = new PayrollComponentItemSelector().getByPayrollComponentId(payrollComponentId);
            Payroll_Component__c[] payrollComponents = new PayrollComponentSelector().getComponentById(payrollComponentId);
            Payroll_Component__c payrollComponent;

            if(!payrollComponents.isEmpty()) {
                payrollComponent = payrollComponents[0];
            }

            String contractorCurrCode = [SELECT CurrencyIsoCode FROM Allocation__c WHERE Project__c = :projectId LIMIT 1].CurrencyIsoCode;
            String projectOwner = [SELECT OwnerId FROM Project__c WHERE Id = :projectId LIMIT 1].OwnerId;
            Util_DatedCurrencyConverter currencyConverter = new Util_DatedCurrencyConverter();

            Decimal totalSum = 0;
            String oldStatus = payrollComponent.Approval_Status__c;

            for(Payroll_Component_Item__c payrollComponentItem: payrollComponentItems) {
                if(payrollComponentItem.CurrencyIsoCode != contractorCurrCode) {
                    Decimal convertedSum = currencyConverter.convertCurrencyToTodayRates(payrollComponentItem.Sum__c, payrollComponentItem.CurrencyIsoCode, contractorCurrCode);
                    totalSum = totalSum + convertedSum.setScale(2);
                } else {
                    totalSum = totalSum + payrollComponentItem.Sum__c;
                }
            }

            payrollComponent.Sum__c = totalSum;

            if(oldStatus == PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.REJECTED)) {
                payrollComponent.Reimbursment__c = null;
            }

            payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
            payrollComponent.Approver__c = projectOwner;
            payrollComponent.Rejection_Reason__c = '';

            update payrollComponent;

            if(oldStatus == PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.REJECTED)) {
                sendToApproval(payrollComponent.Id);

            }

            PayrollComponentWrapper payrollComponentWrapper = new PayrollComponentWrapper();
            payrollComponentWrapper.Sum = payrollComponent.Sum__c;
            payrollComponentWrapper.TravelId = payrollComponent.Travel_request__c;
            payrollComponentWrapper.projectId = payrollComponent.Project__c;
            payrollComponentWrapper.Status = payrollComponent.Approval_Status__c;
            payrollComponentWrapper.CurrencyCode = contractorCurrCode;
            payrollComponentWrapper.Id = payrollComponent.Id;
            payrollComponentWrapper.rejectionReason = '';

            response.setResult(JSON.serialize(payrollComponentWrapper, true));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LW_ReimbursementsController.class));
        }

        return response;
    }

    public static String getPersonAccountIdFromUser() {
        User currUsr = [
                SELECT
                        Employee_AccountId__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
        ];

        return currUsr.Employee_AccountId__c;
    }

    public static Id getAccountId() {
        Account[] accounts = new Account[]{};

        accounts = [
                SELECT
                        Id,
                        Name
                FROM Account
                WHERE Id = :getPersonAccountIdFromUser()
                LIMIT 1
        ];


        return accounts[0].Id;
    }

    public static Id getContractorId() {
        Account[] accounts = new Account[]{};

        accounts = [
                SELECT
                        Id,
                        Contractor__c
                FROM Account
                WHERE Id = :getPersonAccountIdFromUser()
        ];

        return accounts[0].Contractor__c;
    }

    public static Map<Id, Travel_request__c> getTravelRequests(Id contractorId, Map<Id, Project__c> contractorProjects) {
        Map<Id, Travel_request__c> contractorBudgeTravelRequestsByIds = new Map<Id, Travel_request__c>([
                SELECT Id,
                        Name,
                        Total_Amount__c,
                        City__c,
                        Country__c,
                        Start_Date__c,
                        End_Date__c,
                        Budget_transaction__c,
                        Project__c
                FROM Travel_request__c
                WHERE Budget_transaction__c IN (
                        SELECT Id
                        FROM Budget_transaction__c
                        WHERE Project__c IN :contractorProjects.keySet()
                )
                AND Contractor_Name__c = :contractorId
                LIMIT 25000
        ]);

        return contractorBudgeTravelRequestsByIds;
    }

    public static Map<Id, Project__c> getProjects(Id contractorId) {
        Map<Id, Project__c> contractorProjects = new Map<Id, Project__c>([
                SELECT Id, Name, Start_date__c, End_date__c, Project_Manager__r.FirstName, Project_Manager__r.LastName
                FROM Project__c
                WHERE Id IN (
                        SELECT Project__c
                        FROM Allocation__c
                        WHERE Contractor__r.Id = :contractorId
                )
                LIMIT 25000
        ]);

        return contractorProjects;
    }

    public static Map<Id, Payroll_Component__c> getPayrollComponentsInProject(Map<Id, Travel_request__c> contractorBudgeTravelRequestsByIds) {
        Map<Id, Payroll_Component__c> payrollComponentMap = new Map<Id, Payroll_Component__c>([
                SELECT Id,
                        Name,
                        Sum__c,
                        StartDate__c,
                        CurrencyIsoCode,
                        Approval_Status__c,
                        Rejection_Reason__c,
                        Travel_request__c,
                        CreatedById
                FROM Payroll_Component__c
                WHERE Travel_request__c IN :contractorBudgeTravelRequestsByIds.keySet()
                AND Travel_request__c <> NULL
                AND RecordTypeId = :PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId()
                ORDER BY CreatedDate
                LIMIT 25000
        ]);

        return payrollComponentMap;
    }

    public static ProjectWrapper createProjectWrapper(Project__c project) {
        ProjectWrapper newProjectWrapper = new ProjectWrapper();
        newProjectWrapper.Id = project.Id;
        newProjectWrapper.Name = project.Name;
        newProjectWrapper.startDate = project.Start_date__c;
        newProjectWrapper.endDate = project.End_date__c;

        return newProjectWrapper;
    }

    public static TravelWrapper createTravelRequestWrapper(Travel_request__c travelRequest) {
        TravelWrapper newTravelWrapper = new TravelWrapper();
        newTravelWrapper.Id = travelRequest.Id;
        newTravelWrapper.Name = travelRequest.Name;
        newTravelWrapper.totalAmount = travelRequest.Total_Amount__c;
        newTravelWrapper.country = travelRequest.Country__c;
        newTravelWrapper.city = travelRequest.City__c;
        newTravelWrapper.endDate = travelRequest.End_Date__c;
        newTravelWrapper.startDate = travelRequest.Start_Date__c;
        newTravelWrapper.label = travelRequest.Country__c + ' ' + travelRequest.Start_Date__c.format();

        return newTravelWrapper;
    }

    public static PayrollComponentWrapper createPayrollComponentWrapper(Payroll_Component__c payrollComponent, String projectManagerName) {
        PayrollComponentWrapper newPayrollComponentWrapper = new PayrollComponentWrapper();
        String statusWaitingForApproval = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
        String statusRejected = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.REJECTED);
        String statusApproved = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);

        newPayrollComponentWrapper.Id = payrollComponent.Id;
        newPayrollComponentWrapper.Name = payrollComponent.Name;
        newPayrollComponentWrapper.Sum = payrollComponent.Sum__c;
        newPayrollComponentWrapper.CurrencyCode = payrollComponent.CurrencyIsoCode;
        newPayrollComponentWrapper.TravelId = payrollComponent.Travel_request__c;
        newPayrollComponentWrapper.Status = payrollComponent.Approval_Status__c;
        newPayrollComponentWrapper.projectManager = projectManagerName;

        if(payrollComponent.Approval_Status__c == statusRejected) {
            newPayrollComponentWrapper.rejectionReason = payrollComponent.Rejection_Reason__c;
        }

        if(payrollComponent.Approval_Status__c == statusApproved) {
            newPayrollComponentWrapper.salaryDate = payrollComponent.StartDate__c.format();
        }

        if(payrollComponent.Approval_Status__c == statusWaitingForApproval || payrollComponent.Approval_Status__c == statusRejected) {
            if(payrollComponent.CreatedById == UserInfo.getUserId()) {
                newPayrollComponentWrapper.isEditable = true;
            }
        } else {
            newPayrollComponentWrapper.isEditable = false;
        }

        return newPayrollComponentWrapper;
    }

    public static ProjectWrapper[] createMainWrapper
            (
                Map<Id, Project__c> contractorProjects,
                Map<Id, Travel_request__c> contractorBudgeTravelRequestsByIds,
                Map<Id, Payroll_Component__c> payrollComponentMap,
                Boolean status
            )
    {
        ProjectWrapper[] projectWrapperArray = new ProjectWrapper[]{};
        String projectManagerName;

        for(Project__c project: contractorProjects.values()) {
            TravelWrapper[] travelWrapperArray = new TravelWrapper[]{};
            ProjectWrapper newProjectWrapper = createProjectWrapper(project);
            projectManagerName = project.Project_Manager__r.FirstName + ' ' + project.Project_Manager__r.LastName;

            for(Travel_request__c travelRequest: contractorBudgeTravelRequestsByIds.values()) {
                PayrollComponentWrapper[] payrollComponentWrapperArray = new PayrollComponentWrapper[]{};
                TravelWrapper newTravelWrapper =  createTravelRequestWrapper(travelRequest);

                for(Payroll_Component__c payrollComponent: payrollComponentMap.values()) {
                    PayrollComponentWrapper newPayrollComponentWrapper = createPayrollComponentWrapper(payrollComponent, projectManagerName);

                    if(travelRequest.Id == payrollComponent.Travel_request__c) {
                        payrollComponentWrapperArray.add(newPayrollComponentWrapper);
                    }

                }

                newTravelWrapper.payrollComponentArray = payrollComponentWrapperArray;

                if(travelRequest.Project__c == project.Name) {
                    travelWrapperArray.add(newTravelWrapper);
                }

            }

            newProjectWrapper.travelArray = travelWrapperArray;

            if(!status && project.End_date__c <= System.today()) continue;
            projectWrapperArray.add(newProjectWrapper);
        }

        return projectWrapperArray;
    }

    public static Payroll_Component__c createPayrollComponent(Id projectId ,Id travelRequestId, String fileData, String contractorCurrCode, Decimal totalSum) {
        FilesWrapper[] filesWrapperArray = (FilesWrapper[]) JSON.deserialize(fileData, FilesWrapper[].class);
        Project__c project = [SELECT Id, OwnerId, Company_Group__c, Department__c  FROM Project__c WHERE Id = :projectId LIMIT 1];

        Integer year = System.today().year();
        Integer month = System.today().month();

        Payroll_Component__c payrollComponent = new Payroll_Component__c();
        payrollComponent.Travel_request__c = travelRequestId;
        payrollComponent.Account__c = getAccountId();
        payrollComponent.Approval_Status__c = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL);
        payrollComponent.Sum__c = totalSum;
        payrollComponent.CurrencyIsoCode = contractorCurrCode;
        payrollComponent.StartDate__c = Date.newInstance(year, month, 1);
        payrollComponent.EndDate__c = Date.newInstance(year, month, 1);
        payrollComponent.Contractor__c = getContractorId();
        payrollComponent.RecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_REIMBURSEMENT.getRecordTypeId();
        payrollComponent.Approver__c = project.OwnerId;
        payrollComponent.Project_Company_Group__c = project.Company_Group__c;
        payrollComponent.Project_Department__c = project.Department__c;
        payrollComponent.Project__c = projectId;
        payrollComponent.SumType__c = PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.SumTypePicklistKey.INCREMENT);
        payrollComponent.OwnerId = payrollComponent.Approver__c;

        insert payrollComponent;

        if(!filesWrapperArray.isEmpty()) {
            saveFiles(payrollComponent.Id, filesWrapperArray);
        }

        return payrollComponent;
    }

    public static void createPayrollComponentItem(Payroll_Component__c payrollComponent, String payrollDataStrJson, Decimal totalSum, String contractorCurrCode) {
        PayrollData[] payrollDataArray = (PayrollData[]) JSON.deserialize(payrollDataStrJson, PayrollData[].class);
        List<Payroll_Component_Item__c> lstPayrollComponentItems = new List<Payroll_Component_Item__c>();
        Util_DatedCurrencyConverter currencyConverter = new Util_DatedCurrencyConverter();

        Id recordTypeId = PayrollComponentItemSelector.RECORD_TYPE_INFO_REIMBURSEMENT_DETAILS.getRecordTypeId();

        for(PayrollData item: payrollDataArray) {
            Payroll_Component_Item__c payrollComponentItem = new Payroll_Component_Item__c();

            if(item.curr != contractorCurrCode) {
                Decimal convertedSum = currencyConverter.convertCurrencyToTodayRates(item.sum, item.curr, contractorCurrCode);

                totalSum = totalSum + convertedSum.setScale(2);
            } else {
                totalSum = totalSum + item.sum;
            }

            payrollComponentItem.Sum__c = item.sum;
            payrollComponentItem.CurrencyIsoCode = item.curr;
            payrollComponentItem.Payroll_Component__c = payrollComponent.Id;
            payrollComponentItem.Comment__c = item.comment;
            payrollComponentItem.RecordTypeId = recordTypeId;

            lstPayrollComponentItems.add(payrollComponentItem);
        }

        insert lstPayrollComponentItems;

        payrollComponent.Sum__c = totalSum;

        update payrollComponent;
    }

    public static void saveFiles(String parentId, FilesWrapper[] filesData) {
        List<ContentVersion> lstContentVersions = new List<ContentVersion>();
        List<ContentDocumentLink> lstContentDocumentLinks = new List<ContentDocumentLink>();

        for(FilesWrapper item: filesData) {
            item.fileData = EncodingUtil.urlDecode(item.fileData, 'UTF-8');

            ContentVersion cv = new ContentVersion();
            cv.Title = item.fileName;
            cv.PathOnClient = '/' + item.fileName;
            cv.VersionData = EncodingUtil.base64Decode(item.fileData);

            lstContentVersions.add(cv);
        }

        insert lstContentVersions;

        for(ContentVersion cv: lstContentVersions) {
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

            ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
                    ContentDocumentId = contentDocumentId, LinkedEntityId = parentId, ShareType = 'I', Visibility = 'AllUsers'
            );

            lstContentDocumentLinks.add(contentDocumentLink);
        }

        insert lstContentDocumentLinks;
    }

    public static void deleteFiles(FilesWrapper[] filesData) {
        Set<Id> filesWrapperIds = new Set<Id>();

        for(FilesWrapper filesWrapper: filesData) {
            filesWrapperIds.add(filesWrapper.contentDocumentId);
        }

        ContentDocument[] contentDocuments = [SELECT Id, Title FROM ContentDocument WHERE Id IN :filesWrapperIds LIMIT 2500];

        delete contentDocuments;
    }

    public static void sendToApproval(Id objectId) {
        Approval.ProcessSubmitRequest[] processSubmitRequestList = new Approval.ProcessSubmitRequest[]{};
        Approval.ProcessSubmitRequest processSubmitRequest = new Approval.ProcessSubmitRequest();

        processSubmitRequest.setObjectId(objectId);
        processSubmitRequest.setProcessDefinitionNameOrId(APPROVAL_PROCESS);

        processSubmitRequestList.add(processSubmitRequest);

        Approval.process(processSubmitRequestList);
    }

    public static FilesWrapper[] getPayrollComponentAttachments(Id payrollComponentId) {
        ContentDocumentLink[] contentDocumentLinks = [ SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :payrollComponentId LIMIT 2500];
        Set<Id> contentDocumentIds = new Set<Id>();
        FilesWrapper[] filesWrappers = new FilesWrapper[]{};

        for(ContentDocumentLink contentDocumentLink: contentDocumentLinks) {
            contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
        }

        ContentVersion[] contentVersions = [ SELECT ContentDocumentId, Title FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds LIMIT 2500];

        for(ContentVersion contentVersion: contentVersions) {
            FilesWrapper filesWrapper = new FilesWrapper();
            filesWrapper.contentDocumentId = contentVersion.ContentDocumentId;
            filesWrapper.fileName = contentVersion.Title;

            filesWrappers.add(filesWrapper);
        }

        return filesWrappers;
    }

    public static PayrollComponentItemInfo[] getPayrollComponentItems(Id payrollComponentId) {
        Payroll_Component_Item__c[] payrollComponentItems = new PayrollComponentItemSelector().getByPayrollComponentId(payrollComponentId);
        PayrollComponentItemInfo[] payrollComponentItemInfos = new PayrollComponentItemInfo[]{};
        Integer i = -1;

        for(Payroll_Component_Item__c payrollComponentItem: payrollComponentItems) {
            i++;
            PayrollComponentItemInfo payrollComponentItemInfo = new PayrollComponentItemInfo(payrollComponentItem, i);

            payrollComponentItemInfos.add(payrollComponentItemInfo);
        }

        return payrollComponentItemInfos;
    }

    public static void updateFiles(String payrollComponentJson) {
        PayrollComponentWrapper payrollComponentWrappers = (PayrollComponentWrapper) JSON.deserialize(payrollComponentJson, PayrollComponentWrapper.class);
        FilesWrapper[] filesWrappers = payrollComponentWrappers.filesWrappers;
        FilesWrapper[] filesForInsert = new FilesWrapper[]{};
        FilesWrapper[] filesForDelete = new FilesWrapper[]{};
        Id payrollComponentId = payrollComponentWrappers.Id;

        for(FilesWrapper filesWrapper: filesWrappers) {
            if(filesWrapper.isInserted) {
                filesForInsert.add(filesWrapper);
            } else if(filesWrapper.isDeleted) {
                filesForDelete.add(filesWrapper);
            }
        }

        saveFiles(payrollComponentId, filesForInsert);
        deleteFiles(filesForDelete);
    }

    public static void deletePayrollComponentItems(Set<Id> idsForDelete) {
        Payroll_Component_Item__c[] payrollComponentItemsForDelete = new PayrollComponentItemSelector().getByIds(idsForDelete);

        delete payrollComponentItemsForDelete;
    }

    public static void upsertPayrollComponentItems(Map<Id, PayrollComponentItemInfo> mapForUpsert, Payroll_Component_Item__c[] payrollComponentItemForUpsert) {
        Payroll_Component_Item__c[] payrollComponentItemsForUpdate = new PayrollComponentItemSelector().getByIds(mapForUpsert.keySet());
        Id recordTypeId =  PayrollComponentItemSelector.RECORD_TYPE_INFO_REIMBURSEMENT_DETAILS.getRecordTypeId();

        for(Payroll_Component_Item__c payrollComponentItem: payrollComponentItemsForUpdate) {
            PayrollComponentItemInfo updatedPayrollComponentItemInfo = mapForUpsert.get(payrollComponentItem.Id);

            payrollComponentItem.Sum__c = updatedPayrollComponentItemInfo.sum;
            payrollComponentItem.CurrencyIsoCode = updatedPayrollComponentItemInfo.curr;
            payrollComponentItem.Comment__c = updatedPayrollComponentItemInfo.comment;
            payrollComponentItem.RecordTypeId = recordTypeId;

            payrollComponentItemForUpsert.add(payrollComponentItem);
        }

        upsert payrollComponentItemForUpsert;
    }

    public static void editPayrollComponentItems(String payrollComponentJson) {
        PayrollComponentWrapper payrollComponentWrappers = (PayrollComponentWrapper) JSON.deserialize(payrollComponentJson, PayrollComponentWrapper.class);
        Payroll_Component_Item__c[] payrollComponentItemForUpsert = new Payroll_Component_Item__c[]{};
        Set<Id> idsForDelete = new Set<Id>();
        Map<Id, PayrollComponentItemInfo> mapForUpdate = new Map<Id, PayrollComponentItemInfo>();

        PayrollComponentItemInfo[] payrollComponentItemInfos = payrollComponentWrappers.payrollComponentItemInfo;

        for(PayrollComponentItemInfo payrollComponentItemInfo: payrollComponentItemInfos) {
            if(payrollComponentItemInfo.isDeleted) {
                idsForDelete.add(payrollComponentItemInfo.id);
            } else if(payrollComponentItemInfo.isInserted) {
                Payroll_Component_Item__c payrollComponentItem = new Payroll_Component_Item__c();
                payrollComponentItem.Payroll_Component__c = payrollComponentWrappers.Id;
                payrollComponentItem.Sum__c = payrollComponentItemInfo.sum;
                payrollComponentItem.CurrencyIsoCode = payrollComponentItemInfo.curr;
                payrollComponentItem.Comment__c = payrollComponentItemInfo.comment;

                payrollComponentItemForUpsert.add(payrollComponentItem);
            } else if(payrollComponentItemInfo.isUpdated && !payrollComponentItemInfo.isInserted) {
                mapForUpdate.put(payrollComponentItemInfo.id, payrollComponentItemInfo);
            }
        }

        deletePayrollComponentItems(idsForDelete);
        upsertPayrollComponentItems(mapForUpdate, payrollComponentItemForUpsert);
    }

    public class ProjectWrapper {
        @AuraEnabled
        public Id Id;
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public Date startDate;
        @AuraEnabled
        public Date endDate;

        @AuraEnabled
        public TravelWrapper[] travelArray;

    }

    public class TravelWrapper {
        @AuraEnabled
        public Id Id;
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public Decimal totalAmount;
        @AuraEnabled
        public String country;
        @AuraEnabled
        public String city;
        @AuraEnabled
        public Date startDate;
        @AuraEnabled
        public Date endDate;
        @AuraEnabled
        public String label;

        @AuraEnabled
        public PayrollComponentWrapper[] payrollComponentArray;
    }

    public class PayrollComponentWrapper {
        @AuraEnabled
        public Id Id;
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public Decimal Sum;
        @AuraEnabled
        public String CurrencyCode;
        @AuraEnabled
        public Id TravelId;
        @AuraEnabled
        public Id projectId;
        @AuraEnabled
        public String Status;
        @AuraEnabled
        public String rejectionReason;
        @AuraEnabled
        public String projectManager;
        @AuraEnabled
        public String salaryDate;
        @AuraEnabled
        public Boolean isEditable;

        @AuraEnabled
        public PayrollComponentItemInfo[] payrollComponentItemInfo;
        @AuraEnabled
        public FilesWrapper[] filesWrappers;
    }

    public class PayrollData{
        @AuraEnabled
        public String comment {get;set;}
        @AuraEnabled
        public Id travel {get;set;}
        @AuraEnabled
        public String curr {get;set;}
        @AuraEnabled
        public Decimal sum {get;set;}
    }

    public class FilesWrapper {
        @AuraEnabled
        public String fileName{ get; set; }
        @AuraEnabled
        public String fileData{ get; set; }
        @AuraEnabled
        public Id contentDocumentId { get; set; }
        @AuraEnabled
        public Boolean isInserted { get; set; }
        @AuraEnabled
        public Boolean isDeleted { get; set; }

        {
            this.isInserted = false;
            this.isDeleted = false;
        }
    }

    public class PayrollComponentItemInfo {
        public Id id { get; set; }
        public String comment { get; set; }
        public Decimal sum { get; set; }
        public String curr { get; set; }
        public Id payrollComponentId { get; set; }
        public Integer key { get; set; }
        public Boolean isUpdated { get; set; }
        public Boolean isDeleted { get; set; }
        public Boolean isInserted { get; set; }

        {
            this.isUpdated = false;
            this.isDeleted = false;
            this.isInserted = false;
        }

        public PayrollComponentItemInfo(Payroll_Component_Item__c payrollComponentItem, Integer i) {
            this.id = payrollComponentItem.Id;
            this.sum = payrollComponentItem.Sum__c;
            this.comment = payrollComponentItem.Comment__c;
            this.curr = payrollComponentItem.CurrencyIsoCode;
            this.payrollComponentId = payrollComponentItem.Payroll_Component__c;
            this.key = i;
        }
    }

    public class LightningResponse extends Model.LightningResponse {

        /* For success response with JSON data  */
        public void setResult(String data) {
            this.data = data;
            this.success = true;
        }

        /* For error response - set message */
        public void setError(String message) {
            this.message = message;
            this.success = false;
        }

        /* For error response - set code */
        public LightningResponse setError(Integer code) {
            this.code = code;
            this.success = false;
            return this;
        }
    }
}