/**
 * Created by MaxymMirona on 27.01.2020.
 */

public with sharing class RollupSummaryServiceQueue implements Queueable{
    private List<SObject> oldRecords;
    private List<SObject> newRecords;

    public RollupSummaryServiceQueue(List<SObject> newRecords){
        this.newRecords = newRecords;
    }
    public RollupSummaryServiceQueue(List<SObject> newRecords, List<SObject> oldRecords){
        this.newRecords = newRecords;
        this.oldRecords = oldRecords;
    }

    public void execute(QueueableContext context){
        RollupSummaryService service = new RollupSummaryService();
        AllocationService allocationService = new AllocationService();

        if (this.oldRecords == null) {
            service.recalculateRollupSummary(this.newRecords);
        } else {

            //allocationService.sortNeededRecords((List<Allocation__c>)this.newRecords, new Map<Id, Allocation__c>((List<Allocation__c>)this.oldRecords));
            service.recalculateRollupSummary(this.newRecords, this.oldRecords);
        }
    }

}