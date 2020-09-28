/**
 * Created by MaxymMirona on 18.06.2020.
 */

public without sharing class SOWTriggerHandler extends SObjectDomain {

    public override void onAfterInsert(){
        System.enqueueJob(new RollupSummaryServiceQueue(this.records));
    }

    public override void onAfterUpdate(Map<Id,SObject> existingRecords) {
        System.enqueueJob(new RollupSummaryServiceQueue(this.records, existingRecords.values()));
    }

    public override void onAfterDelete() {
        System.enqueueJob(new RollupSummaryServiceQueue(this.records));
    }
}