/**
 * Created by MaxymMirona on 17.04.2020.
 */

@IsTest
public without sharing class OpportunityServiceTest {

    OpportunityService opportunityServiceObject = new OpportunityService();

    @TestSetup
    private static void setup() {

        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'New';
        opp.CloseDate = System.today().addDays(12);

        insert opp;

        Allocation__c allocation1 = new Allocation__c();
        allocation1.Allocation__c = 12;
        allocation1.Allocation_Type__c = 'Billable';
        allocation1.Start_date__c = System.today().addDays(-1);
        allocation1.End_date__c = System.today().addDays(+1);
        allocation1.Opportunity__c = opp.Id;

        insert allocation1;
    }

    @IsTest
    private static void checkForClosedOpportunitiesTestCorrectFlow(){
        List<Opportunity> opportunities = [SELECT Id, StageName FROM Opportunity];

        if (!opportunities.isEmpty()){
            opportunities[0].StageName = 'Closed Lost';

            Test.startTest();

            update opportunities;

            Test.stopTest();

            List<Opportunity> updatedOpportunities = [SELECT Id, StageName, (SELECT id, Status__c FROM Allocations__r) FROM Opportunity];

            if (!updatedOpportunities.isEmpty()){
                if (!updatedOpportunities[0].Allocations__r.isEmpty()) {
                    system.assertEquals('Rejected', updatedOpportunities[0].Allocations__r[0].Status__c);
                }
            }
        }
    }

    @IsTest
    private static void checkForClosedOpportunitiesTestCorrectFlowUndelete(){
        List<Opportunity> opportunities = [SELECT Id, StageName FROM Opportunity];

        if (!opportunities.isEmpty()){
            opportunities[0].StageName = 'Closed Lost';

            Test.startTest();

            SObjectDomain.isEnabled = false;
            update opportunities;
            SObjectDomain.isEnabled = true;

            delete opportunities;
            undelete opportunities;

            Test.stopTest();

            List<Opportunity> updatedOpportunities = [SELECT Id, StageName, (SELECT id, Status__c FROM Allocations__r) FROM Opportunity];

            if (!updatedOpportunities.isEmpty()){
                if (!updatedOpportunities[0].Allocations__r.isEmpty()) {
                    system.assertEquals('Rejected', updatedOpportunities[0].Allocations__r[0].Status__c);
                }
            }
        }
    }

}