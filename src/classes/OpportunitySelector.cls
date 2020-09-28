/**
 * Created by MaxymMirona on 15.04.2020.
 */

public inherited sharing class OpportunitySelector extends SObjectSelector{
    private static final Integer SOQL_LIMIT_MAX = 50000;
    private static Schema.SobjectType OPPORTUNITY_SOBJECT_TYPE = Opportunity.getSObjectType();
    private static Map<String, Schema.ChildRelationship> OPPORTUNITY_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME = new Map<String, Schema.ChildRelationship>();


    static {
        for (Schema.ChildRelationship relationship : Project__c.SObjectType.getDescribe().getChildRelationships()){
            if (relationship != null){
                if (relationship.getChildSObject() != null){
                    if (relationship.getChildSObject().getDescribe() != null){
                        if (relationship.getChildSObject().getDescribe().getName() != null){
                            OPPORTUNITY_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME.put(relationship.getChildSObject().getDescribe().getName(), relationship);
                        }
                    }
                }
            }
        }
    }

    @TestVisible
    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {
        return new Map<String, SObjectQueryBuilder.RollupOperation>{
                'Id' => null
        };
    }

    @TestVisible
    protected override SObjectType getSObjectType() {
        return Opportunity.SObjectType;
    }

    public List<Opportunity> getOpportunitiesWithRelatedAllocations(List<Opportunity> opportunities){
        sObjectQueryBuilder subQuery = new sObjectQueryBuilder(
                OPPORTUNITY_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME.get('Allocation__c'),
                OPPORTUNITY_SOBJECT_TYPE
        );
        subQuery
                .registerField('Status__c')
                .addWhere('Status__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, '\'Rejected\'');
        String soql = queryBuilder
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':opportunities')
                .registerSubquery(subQuery)
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

}