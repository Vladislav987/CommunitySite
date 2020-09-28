public without sharing class BudgetTransactionItemTriggerHandler extends SObjectDomain{
    

	public override void onAfterInsert(){
        //System.enqueueJob(new RollupSummaryServiceQueue(this.records));
    }    
    
    public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
        
        //System.enqueueJob(new RollupSummaryServiceQueue(this.records, existingRecords.values()));
    }

    public override void onAfterDelete() {

        //System.enqueueJob(new RollupSummaryServiceQueue(this.records));
    }

}