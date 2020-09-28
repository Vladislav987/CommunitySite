/**
 * Created by MaxymMirona on 15.04.2020.
 */

public without sharing class OpportunityTriggerHandler extends SObjectDomain{

    private OpportunityService opportunityServiceObject = new OpportunityService();

    public override void onBeforeUpdate(Map<Id,SObject> existingRecords) {
        opportunityServiceObject.checkForClosedOpportunities((Map<Id, Opportunity>)existingRecords, (List<Opportunity>) this.records);
    }

    public override void onAfterUnDelete() {
        opportunityServiceObject.checkForClosedOpportunities((List<Opportunity>) this.records);

    }

}