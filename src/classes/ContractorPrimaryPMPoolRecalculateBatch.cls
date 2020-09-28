/*
 *  @description    Batch to update Contractor__r.Primary_PM__c field. It can be scheduled.
 */
public with sharing class ContractorPrimaryPMPoolRecalculateBatch implements Database.Batchable<sObject>, Schedulable {

    private static Integer CHUNK_SIZE = 200;

    public Database.QueryLocator start(Database.BatchableContext bc) {

        String contractorsQuery =   'SELECT Id, ' +
                '       Primary_PM__c ' +
                'FROM   Contractor__c ' +
                'WHERE  (RecordType.DeveloperName = \'Contractor\') ' +
                'AND    (Active__c = TRUE) ' +
                'AND    (Joining_Date__c <= TODAY) ' +
                'AND    ((Exit_Date__c = NULL) OR (Exit_Date__c >= TODAY))';

        return Database.getQueryLocator(contractorsQuery);
    }

    public void execute(Database.BatchableContext batchableContext, List<Contractor__c> scope) {
        // Generate map where keys are Contractors Ids
        Map<Id, Contractor__c> contractorsMapping = new Map<Id, Contractor__c>(scope);

        // Contains Ids of Contracts which Primary_PM__c with actual value
        Set<Id> idsOfUpdatedContractors = new Set<Id>();
        Map<Id, Boolean> hasNotPoolAllocationsByContractorIds = new Map<Id, Boolean>();

        for (Allocation__c allocation : [
                SELECT Id, Contractor__c
                FROM Allocation__c
                WHERE (Contractor__c IN :contractorsMapping.keySet())
                AND   (Project__r.RecordType.DeveloperName != 'Pool')
                AND   (Project__r.Project_Manager__c != NULL)
                AND   (Start_Date__c <= TODAY)
                AND   (End_Date__c >= TODAY)
                AND   (Status__c = 'Active')
                AND   (Allocation_Type__c != 'Leave')
        ]) {
            hasNotPoolAllocationsByContractorIds.put(allocation.Contractor__c, true);
        }

        // Query for related Allocation__c records grouped by Contractor__c and Project__r.Project_Manager__c.
        // It's also ordered by Contractor, SUM(Allocation) and MIN(CreatedDate) to place correct PM
        // at the top of grouped records.
        for (AggregateResult allocationAggregateResult: [
                SELECT      Contractor__c,
                            Project__r.Project_Manager__c
                FROM        Allocation__c
                WHERE       (Contractor__c IN :contractorsMapping.keySet())
                AND         (Project__r.Project_Manager__c != NULL)
                AND         (Start_Date__c <= TODAY)
                AND         (End_Date__c >= TODAY)
                AND         (Status__c = 'Active')
                AND         (Allocation_Type__c != 'Leave')
                AND         (Project__r.RecordType.DeveloperName = 'Pool')
                GROUP BY    Contractor__c,
                            Project__r.Project_Manager__c
                ORDER BY    Contractor__c   ASC,
                        SUM(Allocation__c)  DESC,
                        MIN(CreatedDate)    ASC
        ]) {
            Id projectManagerId = (Id) allocationAggregateResult.get('Project_Manager__c');
            Id contractorId = (Id) allocationAggregateResult.get('Contractor__c');
            Contractor__c relatedContractor = contractorsMapping.get(contractorId);

            // Primary_PM__c should be updated only with the first value that is related to contractor, that's why set is used
            if (!idsOfUpdatedContractors.contains(contractorId) && (relatedContractor.Primary_PM__c != projectManagerId) && !hasNotPoolAllocationsByContractorIds.containsKey(contractorId)) {
                relatedContractor.Primary_PM__c = projectManagerId;
                idsOfUpdatedContractors.add(contractorId);
            } else if (relatedContractor.Primary_PM__c == projectManagerId) {
                idsOfUpdatedContractors.add(contractorId);
            }
        }

        // Update contractors if at least one record was updated with new Primary_PM__c value
        if (!idsOfUpdatedContractors.isEmpty()) {
            update contractorsMapping.values();
        }
    }

    public void finish(Database.BatchableContext batchableContext) {
        // Handle batch finish
    }

    /*
     *  @description    To schedule batch.
     *
     *                  Example of usage:
     *                  System.schedule(*Process Name*, *CRON Expression*, new ContractorPrimaryPMRecalculateBatch());
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ContractorPrimaryPMPoolRecalculateBatch(), CHUNK_SIZE);
    }

}