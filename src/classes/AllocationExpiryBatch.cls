/**
 * @description: Batch job to identify expired 'Active' allocations
 * of record types 'Project' and 'Booking'
 * where end date < TODAY and set them as Status = 'Inactive'
 *
 *
 * @author: pz - Customertimes Corp.
 * @created: 16.04.2019
 * @version: 0.1
 */
public without sharing class AllocationExpiryBatch implements Database.Batchable<sObject>,Schedulable,Database.Stateful {

    private Boolean forceError = false;

    @TestVisible
    private static final Integer CHUNK_SIZE = 200;
    @TestVisible
    private static final Map<Schema.sObjectField,Object> INACTIVITY_FLAGS = new Map<Schema.sObjectField,Object>{
            Allocation__c.Status__c => 'Finished'
    };

    @TestVisible
    private static final List<String> FLIP_STATUSES = new List<String>{
        'Active'
    };
    @TestVisible
    private static final List<String> FLIP_RTS = new List<String>{
            'Project'
            ,'Booking'
    };

    Map<Id,List<String>> errs = new Map<Id,List<String>>();

    /*=========================================================================
    *
    *                            BATCH
    **=========================================================================*/

    /**
    * Method returns query locator for allocations eligible to be closed
    * These allocations should be of specific record types, with past end date
    * and set as 'Active' status
    * @param: bc - batchable context of the job
    * @return: Database.QueryLocator - query locator for the records in scope
    */
    public Database.QueryLocator start(Database.BatchableContext bc){
        String q = 'SELECT Id' +
                ', Name' +
                ', Status__c ' +
                'FROM Allocation__c ' +
                'WHERE End_date__c < TODAY ' +
                    'AND Status__c IN :FLIP_STATUSES ' +
                    'AND RecordType.DeveloperName IN :FLIP_RTS';

        return Database.getQueryLocator(q);
    }
    /**
    * Main logic of the batch - runs through scope records and sets them as
    * inactive
    *
    * @param: bc - batchable context of the job
    * @param: scope - records returned by the query locator returned in start method
    */
    public void execute(Database.BatchableContext bc, List<Allocation__c> scope) {
        for(Allocation__c a : scope){
            for(Schema.sObjectField fld : INACTIVITY_FLAGS.keySet()){
                a.put(fld,INACTIVITY_FLAGS.get(fld));
            }
            if(forceError && System.Test.isRunningTest()){
                a.OwnerId = a.Id;
            }
        }

        List<Database.SaveResult> dsrs = Database.update(scope,false);

        for(Integer i= 0; i< dsrs.size(); i++){
            Database.SaveResult dsr = dsrs[i];
            Allocation__c alloc = scope[i];


            if (!dsr.isSuccess()) {
                if(errs.get(alloc.Id) == null){
                    errs.put(alloc.Id,new List<String>());
                }

                for (Database.Error e : dsr.getErrors()){
                    errs.get(alloc.Id).add(e.getMessage());
                }

            }

        }

    }
    /**
    * Method for reporting on errors that have occurred on update of scope allocations
    * Allocations that could not be updated have chatter feed items with error messages attached
    *
    * @param: bc - batchable context of the job
    */
    public void finish(Database.BatchableContext bc){
        Set<FeedItem> fis = new Set<FeedItem>();

        for (Id allocId : errs.keySet()){

            if (errs.get(allocId) != null && !errs.get(allocId).isEmpty()) {
                FeedItem fi = new FeedItem();
                fis.add(fi);
                String bd = 'Error on Allocation Expiry Batch when setting "Finished" status:';
                fi.ParentId = allocId;

                for(String err :errs.get(allocId)){
                    bd += '\r\n' + err;
                }
                fi.Body = bd;
            }
        }
        if(!fis.isEmpty()){
            insert new List<FeedItem>(fis);
        }
    }
    /*=========================================================================
    *
    *                           SCHEDULABLE
    **=========================================================================*/
    /**
    * Method for scheduling context batch job
    *
    * @param: sc - schedulable context of the job
    */
    public void execute(SchedulableContext sc){
        AllocationExpiryBatch b = new AllocationExpiryBatch();
        //Parameters of ExecuteBatch(context,BatchSize)
        database.executebatch(b,CHUNK_SIZE);
    }
    public AllocationExpiryBatch(){

    }
    public AllocationExpiryBatch(Boolean forceError){
        this.forceError = forceError;
    }
}