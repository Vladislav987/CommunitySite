/**
 * Created by Mychailo Hamdzii on 24.04.2019.
 */
/**
 * Generic class for selecting start/end date fields for any sobject, currently used for project/allocation range selecting
 */
public with sharing class DateRangeSelector {
    private SObjectType sobjectType { get; set; }
    private SObjectQueryBuilder queryBuilder { get; set; }

    private static final Integer SOQL_LIMIT_SINGLE_RECORD = 1;

    public DateRangeSelector(SObjectType sobjectType) {
        this.sobjectType = sobjectType;
        this.queryBuilder = new sObjectQueryBuilder(sobjectType);
    }
    /**
     * Public because used for getting selected date fields in service
     */
    public static final Map<SObjectType, SObjectField> START_DATES_BY_TYPE = new Map<SObjectType, SObjectField>{
        Project__c.SObjectType => Project__c.Start_date__c,
        Allocation__c.SObjectType => Allocation__c.Start_date__c
    };
    public static final Map<SObjectType, SObjectField> END_DATES_BY_TYPE = new Map<SObjectType, SObjectField>{
        Project__c.SObjectType => Project__c.End_date__c,
        Allocation__c.SObjectType => Allocation__c.End_date__c
    };

    private String getFieldName(SObjectType sobjectType, Boolean isStartDate) {
        Map<SObjectType, SObjectField> appropriateMap = isStartDate ? START_DATES_BY_TYPE : END_DATES_BY_TYPE;

        return appropriateMap.get(sobjectType).getDescribe().getName();
    }
    /**
     * Selecting record by Id with appropriate querybuilder, with Start/End date fields
     *
     * @param recordId - record Id to select
     * @return List<SObject> - selected record with 2 date fields: Start & End date for object
     */
    public List<SObject> selectRequiredSObjectWithDates(Id recordId) {
        String soql = queryBuilder
            .registerField(getFieldName(sobjectType, true), null)
            .registerField(getFieldName(sobjectType, false), null)
            .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':recordId')
            .registerLimit(SOQL_LIMIT_SINGLE_RECORD)
            .toString();

        return Database.query(soql);
    }
}