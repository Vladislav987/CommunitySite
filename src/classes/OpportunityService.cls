/**
 * Created by MaxymMirona on 15.04.2020.
 */

public without sharing class OpportunityService {
    OpportunitySelector opportunitySelectorObject = new OpportunitySelector();

    public void checkForClosedOpportunities(Map<Id, Opportunity> existingOpportunities, List<Opportunity> newOpportunities){
        List<Opportunity> opportunitiesToProcess = new List<Opportunity>();

        for (Opportunity newOpportunity : newOpportunities){
            if (
                    newOpportunity.StageName != existingOpportunities.get(newOpportunity.Id).StageName
                ){
                opportunitiesToProcess.add(newOpportunity);
            }
        }

        if (!opportunitiesToProcess.isEmpty()) {
            checkForClosedOpportunities(opportunitiesToProcess);
        }
    }

    public void checkForClosedOpportunities(List<Opportunity> newOpportunities){
        List<Opportunity> opportunitiesToProcess = new List<Opportunity>();
        List<Allocation__c> allocationsToUpdate = new List<Allocation__c>();

        for (Opportunity newOpportunity : newOpportunities){
            if (newOpportunity.StageName == 'Closed Lost'){
                opportunitiesToProcess.add(newOpportunity);
            }
        }

        List<Opportunity> opportunitiesWithRelatedAllocations =
                opportunitySelectorObject.getOpportunitiesWithRelatedAllocations(opportunitiesToProcess);

        for (Opportunity opportunityWithAllocations : opportunitiesWithRelatedAllocations){
            for (Allocation__c allocation : opportunityWithAllocations.Allocations__r){
                allocation.Status__c = 'Rejected';
                allocationsToUpdate.add(allocation);
            }
        }

        update allocationsToUpdate;
    }
}