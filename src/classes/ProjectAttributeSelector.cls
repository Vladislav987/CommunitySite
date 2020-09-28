/**
 * Created by Lambru Dmytro on 24.03.2020.
 */

public inherited sharing class ProjectAttributeSelector extends SObjectSelector {

    public static final Schema.SObjectType PROJECT_ATTRIBUTE_SOBJECT_TYPE = Schema.Project_attribute__c.SObjectType;
    public static final Id PROJECT_ATTRIBUTE_RECORD_TYPE_SPECIALIZATION_ID = PROJECT_ATTRIBUTE_SOBJECT_TYPE.getDescribe().getRecordTypeInfosByDeveloperName().get('Specialization').getRecordTypeId();
    public static final Id PROJECT_ATTRIBUTE_RECORD_TYPE_ASSESSMENT_ID = PROJECT_ATTRIBUTE_SOBJECT_TYPE.getDescribe().getRecordTypeInfosByDeveloperName().get('Assessment').getRecordTypeId();
    public static final Schema.SObjectField IS_DELETED_SOBJECT_FIELD = Schema.Project_attribute__c.IsDeleted;
    public static final Schema.SObjectField RECORD_TYPE_ID_SOBJECT_FIELD = Schema.Project_attribute__c.RecordTypeId;
    public static final Schema.SObjectField PROJECT_SOBJECT_FIELD = Schema.Project_attribute__c.Project__c;
    public static final Schema.SObjectField MASTER_SOBJECT_FIELD = Schema.Project_attribute__c.Master__c;
    public static final Schema.SObjectField SPECIALIZATION_SOBJECT_FIELD = Schema.Project_attribute__c.Specialization__c;

    private static final Integer SOQL_LIMIT_MIN = 1000;

    @TestVisible
    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {
        return new Map<String, SObjectQueryBuilder.RollupOperation>{
                'Id' => null
        };
    }

    @TestVisible
    protected override SObjectType getSObjectType() {
        return Schema.Project_attribute__c.SObjectType;
    }

    public Project_attribute__c[] getWithRTSpecializationAndSpecifiedPicklistOptionsByProjectId(Id projectId, Set<String> masterPicklistOptionApiNameSet, Set<String> specializationPicklistOptionApiNameSet) {
        String soql = queryBuilder
                .registerField(PROJECT_SOBJECT_FIELD)
                .registerField(MASTER_SOBJECT_FIELD)
                .registerField(SPECIALIZATION_SOBJECT_FIELD)
                .addWhere(IS_DELETED_SOBJECT_FIELD.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, 'false')
                .addWhere(RECORD_TYPE_ID_SOBJECT_FIELD.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, ':PROJECT_ATTRIBUTE_RECORD_TYPE_SPECIALIZATION_ID')
                .addWhere(PROJECT_SOBJECT_FIELD.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectId')
                .addWhere(MASTER_SOBJECT_FIELD.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':masterPicklistOptionApiNameSet')
                .addWhere(SPECIALIZATION_SOBJECT_FIELD.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':specializationPicklistOptionApiNameSet')
                .registerLimit(SOQL_LIMIT_MIN)
                .toString();

        return Database.query(soql);
    }

    public Project_attribute__c[] getByIdSet(Set<Id> idSet) {

        String soql = queryBuilder
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':idSet')
                .registerLimit(SOQL_LIMIT_MIN)
                .toString();

        return Database.query(soql);
    }

    public Project_attribute__c[] getProjectAttributesForAssessmentRT(List<String> fieldApiNames, Id projectId) {
        SObjectQueryBuilder builder = queryBuilder;

        for (String field : fieldApiNames) {
            builder = builder.registerField(field);
        }
        builder
                .addWhere(IS_DELETED_SOBJECT_FIELD.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, 'false')
                .addWhere(RECORD_TYPE_ID_SOBJECT_FIELD.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, ':PROJECT_ATTRIBUTE_RECORD_TYPE_ASSESSMENT_ID')
                .addWhere(PROJECT_SOBJECT_FIELD.getDescribe().getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectId')
                .registerLimit(SOQL_LIMIT_MIN);

        String soql = builder.toString();
        return Database.query(soql);
    }
}