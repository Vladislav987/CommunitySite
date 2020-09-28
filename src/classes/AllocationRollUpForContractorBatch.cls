public without sharing class AllocationRollUpForContractorBatch implements Database.Batchable<sObject>,Schedulable,Database.Stateful{
    private static final Integer CHUNK_SIZE = 200;
    private ContractorService contractorService = new ContractorService();
    private Date IN_TWO_WEEK = Date.today().addDays(14);
    private static final Id PROJECT_REPORT_RECORD_TYPE_POOL_ID =
            Schema.Project__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Pool').getRecordTypeId();


    private static final List<String> INACTIVITY_FLAGS = new List<String>{'Finished', 'Rejected'};

    public Database.QueryLocator start(Database.BatchableContext bc){
        String q = 'SELECT Id' +
                ', Contractor__c ' +
                'FROM Allocation__c ' +
                'WHERE Status__c NOT IN :INACTIVITY_FLAGS '+
                'AND Contractor__c != null '+
                'AND Project__r.RecordTypeId != :PROJECT_REPORT_RECORD_TYPE_POOL_ID '+
                'AND ((Start_date__c <= TODAY ' +
                'AND End_date__c >= TODAY) ' +
                'OR (Start_date__c <= :IN_TWO_WEEK ' +
                'AND End_date__c >= :IN_TWO_WEEK)) ';
        return Database.getQueryLocator(q);
    }
    public void execute(Database.BatchableContext bc, List<Allocation__c> scope) {
        Set<Id> contractorsIds = new Set<Id>();
        for(Allocation__c allocation : scope){
            contractorsIds.add(allocation.Contractor__c);
        }
        contractorService.recalculateAllocationFields(contractorsIds);

    }
    public void finish(Database.BatchableContext bc){
    }
    public void execute(SchedulableContext sc){
        AllocationRollUpForContractorBatch b = new AllocationRollUpForContractorBatch();
        //Parameters of ExecuteBatch(context,BatchSize)
        database.executebatch(b,CHUNK_SIZE);
    }

}