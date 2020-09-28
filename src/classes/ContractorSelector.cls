public inherited sharing class ContractorSelector extends SObjectSelector{
    private static final Integer SOQL_LIMIT_MAX = 50000;
    private static final Integer SOQL_LIMIT_MID = 25000;
    private static final Integer SOQL_LIMIT_SINGLE_RECORD = 1;
    public static final Schema.SObjectType SOBJECT_TYPE = Schema.Contractor__c.SObjectType;
    private static final String PROJECT_RECORD_TYPE = 'Project';
    private static final List<String> STATUS_ACTIVE_AND_FINISHED = new List<String>{'Active','Finished'};
    private static Schema.SobjectType CONTRACTOR_SOBJECT_TYPE = Contractor__c.getSObjectType();
    private static List<String> NEGATIVE_STATUSES = new List<String>{'Rejected', 'Finished'};
    private static final Id PROJECT_REPORT_RECORD_TYPE_POOL_ID =
            Schema.Project__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Pool').getRecordTypeId();
    /* Merge from QA sandbox to Alex sandbox by Dmytro Lambru 11.08.20 */
    private static Map<String, Schema.ChildRelationship> CONTRACTOR_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME = new Map<String, Schema.ChildRelationship>();

    /* Merge from QA sandbox to Alex sandbox by Dmytro Lambru 11.08.20 */
    static {
        for (Schema.ChildRelationship relationship : Contractor__c.SObjectType.getDescribe().getChildRelationships()){
            if (relationship != null){
                if (relationship.getChildSObject() != null){
                    if (relationship.getChildSObject().getDescribe() != null){
                        if (relationship.getChildSObject().getDescribe().getName() != null){
                            CONTRACTOR_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME.put(relationship.getChildSObject().getDescribe().getName(), relationship);
                        }
                    }
                }
            }
        }
    }

    //fields
    public static final Schema.SObjectField FIELD_CURRENCY_ISO_CODE = Schema.Contractor__c.CurrencyIsoCode;

    // Record Types (RT)
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_CONTRACTOR;

    // Setting the Record Types (RT)
    static {
        Map<String, RecordTypeInfo> apiNameToRecordTypeInfoMap = SOBJECT_TYPE.getDescribe().getRecordTypeInfosByDeveloperName();

        RECORD_TYPE_INFO_CONTRACTOR = apiNameToRecordTypeInfoMap.get('Contractor');
    }

    // picklist field values
    public static final Map<ResourceTypePicklistKey, String> RESOURCE_TYPE_PICKLIST_VALUES_MAP = new Map<ResourceTypePicklistKey, String>{
        ResourceTypePicklistKey.SFDC_DEVELOPER => 'SFDC Developer',
        ResourceTypePicklistKey.NET_DEVELOPER => '.Net developer',
        ResourceTypePicklistKey.ANDROID_DEVELOPER => 'Android Developer',
        ResourceTypePicklistKey.IOS_DEVELOPER => 'IOS Developer'
    };

    public static final Map<ResourceLevelPicklistKey, String> RESOURCE_LEVEL_PICKLIST_VALUES_MAP = new Map<ResourceLevelPicklistKey, String>{
        ResourceLevelPicklistKey.TRAINEE => 'Trainee'
    };

    public static final Map<StationPicklistKey, String> STATION_PICKLIST_VALUES_MAP = new Map<StationPicklistKey, String>{
        StationPicklistKey.CTDEV_KYIV_OFFICE => 'CTDev Kiev Office',
        StationPicklistKey.CTDEV_LVIV_OFFICE => 'CTDev Lviv Office',
        StationPicklistKey.CTDEV_CHERKASY_OFFICE => 'CTDev Cherkasy Office',
        StationPicklistKey.CTDEV_NEW_YORK_OFFICE => 'CT New York'
    };

    public static final Map<DepartmentPicklistKey, String> DEPARTMENT_PICKLIST_VALUES_MAP = new Map<DepartmentPicklistKey, String>{
        DepartmentPicklistKey.SFDC_DEPARTMENT => 'SFDC Department',
        DepartmentPicklistKey.ENTERPRISE_AND_TECHNOLOGY => 'Enterprise & Technology',
        DepartmentPicklistKey.FINANCE_DEPARTMENT => 'Finance Department',
        DepartmentPicklistKey.HR_DEPARTMENT => 'HR Department',
        DepartmentPicklistKey.IT_DEPARTMENT => 'IT Department',
        DepartmentPicklistKey.SALES_AND_MARKETING => 'Sales and Marketing',
        DepartmentPicklistKey.OFFICE_ADMINISTRATION => 'Office Administration'
    };

    public static final Map<SubDepartmentPicklistKey, String> SUB_DEPARTMENT_PICKLIST_VALUES_MAP = new Map<SubDepartmentPicklistKey, String>{
        SubDepartmentPicklistKey.SFDC_DEVELOPMENT => 'SFDC Development',
        SubDepartmentPicklistKey.SFDC_CONSULTING => 'SFDC Consulting',
        SubDepartmentPicklistKey.SFDC_PMO => 'SFDC PMO'
    };

    // map keys for picklist field values
    public enum ResourceTypePicklistKey { SFDC_DEVELOPER, NET_DEVELOPER, ANDROID_DEVELOPER, IOS_DEVELOPER }
    public enum ResourceLevelPicklistKey { TRAINEE }
    public enum StationPicklistKey { CTDEV_KYIV_OFFICE,  CTDEV_LVIV_OFFICE, CTDEV_CHERKASY_OFFICE, CTDEV_NEW_YORK_OFFICE }
    public enum DepartmentPicklistKey { SFDC_DEPARTMENT, ENTERPRISE_AND_TECHNOLOGY, FINANCE_DEPARTMENT, HR_DEPARTMENT, IT_DEPARTMENT, SALES_AND_MARKETING, OFFICE_ADMINISTRATION }
    public enum SubDepartmentPicklistKey { SFDC_DEVELOPMENT, SFDC_CONSULTING, SFDC_PMO }

    protected override SObjectType getSObjectType() {
        return SOBJECT_TYPE;
    }

    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {
        return new Map<String, SObjectQueryBuilder.RollupOperation>{
            'Id' => null
        };
    }

    /**
     * @description Not used.
     * @param projectIds --
     *
     * @return --
     */
    public List<Allocation__c> getAllocationsByProjectIds(Set<Id> projectIds){
        String soql = queryBuilder
                .registerField('All_billable_allocations__c')
                .registerField('All_active_allocations__c')
                .registerSubquery('Monthly_reports__r', new List<String>{'Id','Status__c','Allocation_Type__c','Allocation__c'})
                .addWhere('Project__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectIds')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();
        return Database.query(soql);
    }

    public List<Contractor__c> getWithDataForRollUpCount(Set<Id> contractorsIds){
        Date inTwoWeek = Date.today().addDays(14);
        Map<String, Schema.ChildRelationship> contractorChildRelationshipsByName = new Map<String, ChildRelationship>();

        Schema.DescribeSObjectResult R = Contractor__c.SObjectType.getDescribe();
        List<Schema.ChildRelationship> C = R.getChildRelationships();

        for (Schema.ChildRelationship relationship: C){
            contractorChildRelationshipsByName.put(relationship.getChildSObject().getDescribe().getName(), relationship);
        }

        sObjectQueryBuilder subQuery = new sObjectQueryBuilder(contractorChildRelationshipsByName.get('Allocation__c'), CONTRACTOR_SOBJECT_TYPE);
        subQuery.registerField('Id')
                .registerField('Status__c')
                .registerField('Allocation_Type__c')
                .registerField('Allocation__c')
                .registerField('Start_date__c')
                .registerField('End_date__c')
                .registerWhere('WHERE Status__c NOT IN :NEGATIVE_STATUSES AND Project__r.RecordTypeId != :PROJECT_REPORT_RECORD_TYPE_POOL_ID AND ((Start_date__c <= :inTwoWeek AND End_date__c >= :inTwoWeek) OR (Start_date__c <= TODAY AND End_date__c >= TODAY))');


        String soql = queryBuilder
                .registerField('All_billable_allocations__c')
                .registerField('All_active_allocations__c')
                .registerSubquery(subQuery)
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':contractorsIds')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

    public Contractor__c[] getNameAndCurrIsoCodeById(Id contractorId) {
        String soql = queryBuilder
                .registerField('Id')
                .registerField(FIELD_CURRENCY_ISO_CODE.getDescribe().getName())
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':contractorId')
                .toString();

        return Database.query(soql);
    }

    public List<Contractor__c> getByIds(Set<Id> contractorsIds) {
        return [
                SELECT Id
                        ,Name
                        ,CurrencyIsoCode
                        ,Station__c
                        ,Department__c
                        ,Sub_Department__c
                        ,Salary__c
                FROM Contractor__c
                WHERE Id IN :contractorsIds
        ];
    }

    public List<Contractor__c> getByPersonalAccountsIds(Set<Id> accountsIds) {
        return [
                SELECT Id
                FROM Contractor__c
                WHERE Id IN (SELECT Contractor__c
                             FROM Account
                             WHERE Id IN : accountsIds
                            )
        ];
    }

    /**
     * @description Merge from QA sandbox to Alex sandbox by Dmytro Lambru 11.08.20
     *
     * @param userId --
     * @param startPeriod --
     * @param endPeriod --
     *
     * @return --
     */
    public List<Contractor__c> getContractorsByPrimaryPM(Id userId, Date startPeriod, Date endPeriod) {

        sObjectQueryBuilder allocationSubQuery = new sObjectQueryBuilder(CONTRACTOR_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME.get('Allocation__c'), CONTRACTOR_SOBJECT_TYPE);
        allocationSubQuery
                .registerField('Name')
                .registerField('Status__c')
                .registerField('Allocation_Type__c')
                .registerField('Allocation__c')
                .registerField('Project__r.Name')
                .registerField('Project__r.Project_Manager__c')
                .registerField('Project__r.Project_Manager__r.Name')
                .registerWhere('WHERE ((Start_date__c <= :startPeriod AND End_date__c >= :startPeriod) OR (Start_date__c >= :startPeriod AND Start_date__c <= :endPeriod))');
        //.addWhere('Start_date__c', SObjectQueryBuilder.ComparisonOperation.GREATER_OR_EQUALS, ':startPeriod')
        //.addWhere('End_date__c', SObjectQueryBuilder.ComparisonOperation.LESS_OR_EQUALS, ':endPeriod');

        sObjectQueryBuilder monthlyReportsSubQuery = new sObjectQueryBuilder(CONTRACTOR_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME.get('Monthly_Report__c'), CONTRACTOR_SOBJECT_TYPE);
        monthlyReportsSubQuery
                .registerField('Fact_hours__c')
                .registerField('Project__c')
                .registerField('Project__r.Name')
                .registerField('Allocation__c')
                .registerField('Allocation__r.Project__c')
                .registerWhere('WHERE ((Monthly_Report_Start_Date__c <= :startPeriod AND Monthly_Report_End_Date__c >= :startPeriod) OR (Monthly_Report_Start_Date__c >= :startPeriod AND Monthly_Report_Start_Date__c <= :endPeriod))');
        //.addWhere('Monthly_Report_Start_Date__c', SObjectQueryBuilder.ComparisonOperation.GREATER_OR_EQUALS, ':startPeriod')
        //.addWhere('Monthly_Report_End_Date__c', SObjectQueryBuilder.ComparisonOperation.LESS_OR_EQUALS, ':endPeriod');

        String soql = queryBuilder
                .registerField('Id')
                .registerField('Station__c')
                .registerField('Joining_Date__c')
                .registerField('Exit_Date__c')
                .registerField('Name')
                .registerSubquery(allocationSubQuery)
                .registerSubquery(monthlyReportsSubQuery)
                .addWhere('Primary_PM__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':userId')
                .toString();

        return Database.query(soql);//        sObjectQueryBuilder allocationSubQuery = new sObjectQueryBuilder(CONTRACTOR_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME.get('Allocation__c'), CONTRACTOR_SOBJECT_TYPE);
    }


    public List<Contractor__c> getAll() {
        String soql = queryBuilder
                .registerField('Id')
                .registerField('Station__c')
                .registerField('Department__c')
                .registerField('Sub_Department__c')
                .registerField('CurrencyIsoCode')
                .registerField('Salary__c')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }
}