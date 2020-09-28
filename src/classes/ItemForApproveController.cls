/**
 * Created by ArtemShevchenko on 08.11.2019.
 */

public without sharing class ItemForApproveController {
    private static final String FIELD_SET_NAME = 'FieldsForApprove';
    private static SObjectType ALLOCATION_TYPE = Schema.Allocation__c.SObjectType;
    private static SObjectType PROCESS_INSTANCE_TYPE = Schema.ProcessInstance.SObjectType;
    private static String ALLOCATION_RT_NEW_RESOURCE_REQUEST = Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('New_resource_Request').getRecordTypeId();
    private static String ALLOCATION_RT_BOOKING = Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Booking').getRecordTypeId();

    @AuraEnabled
    public static List<ProcessInstance> getRecordsForApprove() {
        List<ProcessInstanceWorkitem> processInstanceWorkitems = [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ActorId = :UserInfo.getUserId()];
        List<Id> processInstanceId = new List<Id>();
        for (ProcessInstanceWorkitem workItem : processInstanceWorkitems) {
            processInstanceId.add(workItem.ProcessInstanceId);
        }
        return [SELECT Id, TargetObjectId, CreatedBy.Name, TargetObject.Name, TargetObject.Type FROM ProcessInstance WHERE Id IN :processInstanceId];
    }
    public static void approveRecords(List<ProcessInstance> recordsForApprove) {
        List<ProcessInstanceWorkitem> instanceWorkitems = [SELECT Id, ActorId,  ProcessInstanceId, OriginalActorId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId IN :recordsForApprove];

        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
        for (ProcessInstanceWorkitem instanceWorkitem : instanceWorkitems) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setComments('Approving request.');
            req.setWorkitemId(instanceWorkitem.Id);
            req.setAction('Approve');
            requests.add(req);
        }
        Approval.ProcessResult[] processResults = Approval.process(requests);
    }
    public static void rejectRecords(List<ProcessInstance> recordsForReject) {
        List<ProcessInstanceWorkitem> instanceWorkitems = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstanceId IN :recordsForReject];

        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
        for (ProcessInstanceWorkitem instanceWorkitem : instanceWorkitems) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setComments('Rejecting request.');
            req.setAction('Reject');
            req.setWorkitemId(instanceWorkitem.Id);
            req.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            requests.add(req);
        }
        Approval.ProcessResult[] processResults = Approval.process(requests);
    }
    @AuraEnabled
    public static Map<String, String> getObjectFieldSet(String objectName) {
        Map<String, String> fieldsLabelAndPath = new Map<String, String>();
        Map<String, Schema.FieldSet> fsMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fieldSets.getMap();
        for (FieldSetMember field : fsMap.get(FIELD_SET_NAME).getFields()) {
            fieldsLabelAndPath.put(field.getLabel(), field.getFieldPath());
        }
        return fieldsLabelAndPath;
    }
    @AuraEnabled
    public static DataTableWrapper initData(String objectName) {
        List<Id> processInstanceId = new List<Id>();
        for (ProcessInstanceWorkitem workItem : [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ActorId = :UserInfo.getUserId()]) {
            processInstanceId.add(workItem.ProcessInstanceId);
        }
        List<Id> recordsIds = new List<Id>();
        for (ProcessInstance processInstance : [SELECT Id, TargetObjectId, CreatedBy.Name, TargetObject.Name, TargetObject.Type FROM ProcessInstance WHERE Id IN :processInstanceId AND TargetObject.Type = :objectName]) {
            recordsIds.add(processInstance.TargetObjectId);
        }
        Map<String, String> fieldsLabelAndPath = getObjectFieldSet(objectName);
        String query = 'SELECT Id';
        if (objectName == 'Allocation__c') {
            query = 'SELECT Id, Project__c';
        }
        for (String field : fieldsLabelAndPath.values()) {
            if (field != 'Id') {
                query += ', ' + field;
            }
        }
        query += ' FROM ' + objectName + ' WHERE Id IN :recordsIds';
        DataTableWrapper wrapper = new DataTableWrapper();
        wrapper.recordsList = Database.query(query);
        wrapper.fieldsList = fieldsLabelAndPath;
        wrapper.fieldsTypes = getFieldsTypes(fieldsLabelAndPath.values(), objectName);
        return wrapper;
    }
    public class DataTableWrapper {
        @AuraEnabled
        public List<SObject> recordsList;
        @AuraEnabled
        public Map<String, String> fieldsList;
        @AuraEnabled
        public Map<String, String> fieldsTypes;
    }
    @AuraEnabled
    public static Result approveByTargetId(List<SObject> recordsForApprove) {
        if(recordsForApprove[0].Id.getSObjectType() == ALLOCATION_TYPE){
            List<Allocation__c> allocationWithoutContractors = [SELECT Id, Name
                                                                FROM Allocation__c
                                                                WHERE Id IN :recordsForApprove
                                                                AND Contractor__c = null AND (RecordTypeId = :ALLOCATION_RT_NEW_RESOURCE_REQUEST OR RecordTypeId = :ALLOCATION_RT_BOOKING)

            ];
            if (!allocationWithoutContractors.isEmpty()) {
                String allocationsName = '';
                for (Allocation__c allocation: allocationWithoutContractors){
                    allocationsName += allocation.Name + '; ';
                }
                return new Result(false, 'You forgot to add Contractor in  Allocation: ' + allocationsName);
            }
        }
        if (recordsForApprove[0].Id.getSObjectType() == PROCESS_INSTANCE_TYPE) {
            approveRecords(recordsForApprove);
        }else{
            approveRecords([SELECT Id FROM ProcessInstance WHERE TargetObjectId IN :recordsForApprove]);
        }
        return new Result(true, 'You approved '+ recordsForApprove.size() +  ' records!');
    }
    @AuraEnabled
    public static void rejectByTargetId(List<SObject> recordsForReject) {
        if (recordsForReject[0].Id.getSObjectType() == PROCESS_INSTANCE_TYPE) {
            rejectRecords(recordsForReject);
        }else{
            rejectRecords([SELECT Id FROM ProcessInstance WHERE TargetObjectId IN :recordsForReject]);
        }

    }
    @AuraEnabled
    public static Id getApproveRequestId(Id recordId) {
        Id processInstanceId = [SELECT Id FROM ProcessInstance WHERE TargetObjectId = :recordId].Id;
        return [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :processInstanceId].Id;
    }

    private static Map<String, String> getFieldsTypes(List<String> fieldsApiNames, String objectName) {
        Map<String, String> fieldsLabelsAndType = new Map<String, String>();
        for (String fieldApi : fieldsApiNames) {
            Schema.DisplayType type = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldApi).getDescribe().getType();
            String label = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldApi).getDescribe().getLabel();
            fieldsLabelsAndType.put(label, String.valueOf(type));
        }
        return fieldsLabelsAndType;
    }

    public class Result {
        @AuraEnabled
        public Boolean isSuccessful { get; set; }
        @AuraEnabled
        public String message { get; set; }
        public Result(Boolean isSuccessful, String message) {
            this.isSuccessful = isSuccessful;
            this.message = message;
        }
    }

}