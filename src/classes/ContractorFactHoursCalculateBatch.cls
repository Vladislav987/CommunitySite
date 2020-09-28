public without sharing class ContractorFactHoursCalculateBatch implements Database.Batchable<sObject>,Schedulable,Database.Stateful{
    private static final Integer CHUNK_SIZE = 200;
    private ContractorService contractorService = new ContractorService();
    private static final Id CONTRACTOR_RECORD_TYPE_CONTRACTOR =
            Schema.Contractor__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Contractor').getRecordTypeId();

    public Database.QueryLocator start(Database.BatchableContext bc){
        String q = 'SELECT Id' +
                ' FROM Contractor__c ' +
                ' WHERE RecordTypeId = :CONTRACTOR_RECORD_TYPE_CONTRACTOR';
        return Database.getQueryLocator(q);
    }
    public void execute(Database.BatchableContext bc, List<Contractor__c> contractorsIds) {

        contractorService.recalculatePlanHours(new Map<Id, Contractor__c>(contractorsIds).keySet());

    }
    public void finish(Database.BatchableContext bc){
    }
    public void execute(SchedulableContext sc){
        ContractorFactHoursCalculateBatch b = new ContractorFactHoursCalculateBatch();
        //Parameters of ExecuteBatch(context,BatchSize)
        database.executebatch(b,CHUNK_SIZE);
    }
}