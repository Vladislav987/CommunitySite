/**
 * Created by Mychailo Hamdzii on 23.04.2019.
 */

public inherited sharing class AllocationSelector extends SObjectSelector{
    private static final Integer SOQL_LIMIT_MAX = 50000;
    private static final Integer SOQL_LIMIT_MID = 25000;
    private static final Integer SOQL_LIMIT_SINGLE_RECORD = 1;
    private static final String PROJECT_RECORD_TYPE = 'Project';
    private static final List<String> STATUS_ACTIVE_AND_FINISHED = new List<String>{'Active','Finished'};

    // Record Types (RT)
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_PROJECT = Schema.SObjectType.Allocation__c.getRecordTypeInfosByDeveloperName().get('Project');

    // picklist field values
    public static final Map<AllocationTypePicklistKey, String> ALLOCATION_TYPE_PICKLIST_VALUES_MAP = new Map<AllocationTypePicklistKey, String>{
            AllocationTypePicklistKey.BILLABLE => 'Billable'
    };

    public enum AllocationTypePicklistKey { BILLABLE }

    @TestVisible
    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {
        return new Map<String, SObjectQueryBuilder.RollupOperation>{
            'Id' => null,
            'Project__c' => null,
            'End_date__c' => null,
            'RecordTypeId' => null,
            'Start_date__c' => null,
            'Allocation__c' => null,
            'Contractor__c' => null,
            'Project__r.Account__r.CurrencyIsoCode' => null
        };
    }

    @TestVisible
    protected override SObjectType getSObjectType() {
        return Allocation__c.SObjectType;
    }

    public List<Allocation__c> getAllocationsByProjectIds(Set<Id> projectIds){
        String soql = queryBuilder
                .addWhere('Project__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectIds')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();
        return Database.query(soql);
    }
    /**
     * Selecting all allocation for project, filtered by status
     *
     * @param recordId - Parent project Id
     * @param status - Status of needed allocations
     * @return List<Allocation__c> - all allocation, based on params
     */
    public List<Allocation__c> getAllocationByRecordTypeId(Id recordId, Id recordTypeId) {
        String soql = queryBuilder
                .registerField('CurrencyIsoCode')
                .registerField('Project__r.RecordTypeId')
                .registerField('Contractor__r.Salary__c')
                .addWhere('Project__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':recordId')
                .addWhere('RecordTypeId', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':recordTypeId')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }
    /**
     *
     *
     * @param recordId - Id of required allocation to select
     * @return List<Allocation__c> - single allocation as list for further logic/check
     */
    public List<Allocation__c> getSingleAllocation(Id recordId) {
        String soql = queryBuilder
                .registerField('CurrencyIsoCode')
                .registerField('Project__r.RecordTypeId')
                .registerField('Station__c')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':recordId')
                .registerLimit(SOQL_LIMIT_SINGLE_RECORD)
                .toString();

        return Database.query(soql);
    }
    /**
     * Selecting allocation with related to object Project field Description
     *
     * @param allocations - allocations without related to object Project field Description
     * @return List<Allocation__c>  with related to object Project field Description
     */
    public List<Allocation__c> getAllocationsWithProjectDescription(List<Allocation__c> allocations) {
        String soql = queryBuilder
                .registerField('Project__r.Project_description__c')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':allocations')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }
    /**
     * Selecting allocation with related to object Project field Description
     *
     * @param projects - projects with modified descriptions
     * @return List<Allocation__c>  with related to object Project field Description
     */

    public List<Allocation__c> getAllocationsWithProjectDescriptionByProjects(List<Project__c> projects){
        String soql = queryBuilder
                .registerField('Allocation_Type__c')
                .registerField('Name')
                .registerField('Overrun_Type__c')
                .registerField('Project__r.Project_description__c')
                .addWhere('Project__c', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':projects')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

    public List<Allocation__c> getCurrentWithStatusActiveAndFinishedByProjectId(Id projectId){
        Date todayAddToMonth = Date.today().addMonths(-2);
        String soql = queryBuilder
                .registerField('Name')
                .registerField('CurrencyIsoCode')
                .registerField('Contractor__r.Name')
                .registerField('Expected_Rate_Daily__c')
                .registerField('Allocation_Type__c')
                .registerField('Contractor__c')
                .addWhere('Project__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectId')
                .addWhere('Contractor__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null')
                .addWhere('RecordType.Name', SObjectQueryBuilder.ComparisonOperation.EQUALS,  ':PROJECT_RECORD_TYPE')
                .addWhere('Status__c', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION,  ':STATUS_ACTIVE_AND_FINISHED')
                .addWhere('End_date__c', SObjectQueryBuilder.ComparisonOperation.GREATER_OR_EQUALS, ':todayAddToMonth')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();
        return Database.query(soql);
    }

    /**
     * @description [ICRM-590] Merge from QA sandbox to Alex sandbox by Dmytro Lambru.
     *
     * @param allocationsIds --
     *
     * @return --
     */
    public List<Allocation__c> getWithDataByIds(Set<String> allocationsIds){
        String soql = queryBuilder
                .registerField('Name')
                .registerField('Project__r.Account__r.CurrencyIsoCode')
                .registerField('Start_date__c')
                .registerField('End_date__c')
                .registerField('Allocation__c')
                .registerField('Station__c')
                .registerField('Contractor__r.Station__c')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':allocationsIds')
                .addWhere('Contractor__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

    public List<Allocation__c> getAllocationsByProjectAndFieldSet(Id projectId, String fieldset){
        List<String> fields = getFieldsTokenPathFromFieldSet(fieldset);                                                 //Retrieve field token path from FieldSet

        for (String field : fields){
            queryBuilder.registerField(field);
        }

        String soql = queryBuilder
                .registerField('Allocation_Type__c')
                .registerField('Status__c')
                .registerField('Contractor__c')
                .registerField('Contractor__r.Name')
                .registerField('Start_date__c')
                .registerField('End_date__c')
                .registerField('RecordType.Name')
                .registerSubquery('Monthly_reports__r', new List<String>{'Id'})
                .addWhere('Project__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectId')
                .registerOther('ORDER BY Contractor__r.Name ASC, Allocation__c DESC')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

    public List<Allocation__c> getAllocationsByProjectAndTypeAndContractor(Id projectId, Id contractorId, String allocationType, List<String> excludedStatuses){
        String soql = queryBuilder
                .registerField('Id')
                .registerField('Start_date__c')
                .registerField('End_date__c')
                .registerField('CurrencyIsoCode')
                .registerField('Status__c')
                .registerField('Overrun_Type__c')
                .addWhere('Project__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectId')
                .addWhere('Contractor__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':contractorId')
                .addWhere('Allocation_Type__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':allocationType')
                .addWhere('Status__c', SObjectQueryBuilder.ComparisonOperation.NOT_IN_OPERATION, ':excludedStatuses')
                .registerOther('ORDER BY Contractor__r.Name ASC, Allocation__c DESC')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

    /**
     * @description Not used.
     * @param projectIds --
     * @param allocationTypes --
     *
     * @return --
     */
    public List<Allocation__c> getActiveAllocationsOfSpecifiedTypesForProjects(List<Id> projectIds, Set<String> allocationTypes){
        String soql = queryBuilder
                .registerField('Id')
                .registerField('Allocation__c')
                .registerField('Contractor__c')
                .registerField('Contractor__r.Name')
                .registerField('Allocation_Type__c')
                .addWhere('Project__c', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':projectIds')
                .addWhere('Status__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, '\'Active\'')
                .addWhere('Allocation_Type__c', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':allocationTypes')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

    public List<Allocation__c> getSameAllocationsWithAdditionalFields(List<Allocation__c> allocations){
        String soql = queryBuilder
                .registerField('Project__r.RecordTypeId')
                .registerField('Project__r.Parent_Project__r.RecordTypeId')
                .registerField('Project__c')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':allocations')
                .toString();

        return Database.query(soql);
    }
        public List<Allocation__c> getByOpportunityIdAndNotIncludedAllocations(Id opportunityId, Set<Id> allocationsIds){
        String soql = queryBuilder
                .addWhere('Opportunity__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':opportunityId')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.NOT_IN_OPERATION, ':allocationsIds')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();
        return Database.query(soql);
    }

    public List<Allocation__c> getAllocationsWithUnifiedCurrencyString(List<Allocation__c> allocations){
        String soql = queryBuilder
                .registerField('Name')
                .registerField('Allocation__c')
                .registerField('Contractor__c')
                .registerField('Status__c')
                .registerField('Allocation_Type__c')
                .registerField('Contractor__r.Name')
                .registerField('Project__r.Parent_project__c')
                .registerField('Start_date__c')
                .registerField('End_date__c')
                .registerField('Overrun_type__c')
                .registerField('New_Allocation__c')
                .registerField('RecordTypeId')
                .registerField('CurrencyIsoCode')
                .registerField('Comments__c')
                .registerField('Resource_Type__c')
                .registerField('Expected_Rate__c')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':allocations')
                .toString();

        soql = AllocationService.addConvertCurrencyFieldsToSOQL(
                new List<Schema.SObjectField>{Schema.Allocation__c.fields.Expected_Rate__c},
                soql
        );

        return Database.query(soql);
    }

    /**
     * @author Dmytro Lambru
     * @description To get information about the Contractor with Allocations below the final starting date.
     *
     * @param projectId ID of Project record.
     * @param startDate Final starting date.
     *
     * @return List with Allocation records.
     */
    public List<Allocation__c> getContractorInfoWithRTProjectByProjectIdAndStartDateBelow(String projectId, Date startDate) {
        String soql = queryBuilder
                .registerField('Contractor__c')
                .registerField('Contractor__r.Name')
                .registerField('CurrencyIsoCode')
                .registerField('Contractor__r.Exit_Date__c')
                .addWhere('IsDeleted', SObjectQueryBuilder.ComparisonOperation.EQUALS, 'false')
                .addWhere('Project__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectId')
                .addWhere('RecordType.Name', SObjectQueryBuilder.ComparisonOperation.EQUALS,  ':PROJECT_RECORD_TYPE')
                .addWhere('Contractor__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null')
                .addWhere('Start_date__c', SObjectQueryBuilder.ComparisonOperation.LESS_OR_EQUALS, ':startDate')
                .registerOther('AND (Contractor__r.Exit_Date__c = NULL OR Contractor__r.Exit_Date__c >= THIS_MONTH) ORDER BY Contractor__r.Name ASC')
                .registerLimit(SOQL_LIMIT_MID)
                .toString();

        return Database.query(soql);
    }

    public List<Allocation__c> getWithManagerAndApprover(Id contractorId, Date pointDate) {
        List<String> statuses = new List<String>{'Active', 'Finished'};
        String soql = queryBuilder
                .registerField('Name')
                .registerField('Project__r.Project_Manager__c')
                .registerField('Project__r.Invoice_Approver__c')
                .registerField('Station__c')
                .registerField('Project__r.Station__c')
                .registerField('End_date__c')
                .addWhere('Contractor__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':contractorId')
                .addWhere('End_date__c', SObjectQueryBuilder.ComparisonOperation.GREATER_OR_EQUALS, ':pointDate')
                .addWhere('Status__c', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION,  ':statuses')
                .registerLimit(SOQL_LIMIT_MID)
                .toString();
        return Database.query(soql);
    }


    private List<String> getFieldsTokenPathFromFieldSet(String fieldsetName){
        List<String> fieldTokenPaths;

        if (!String.isEmpty(fieldsetName)) {
            fieldTokenPaths = new List<String>();
            Schema.FieldSet fieldset = Schema.SObjectType.Allocation__c.fieldSets.getMap().get(fieldsetName);
            for (Schema.FieldSetMember field : fieldset.getFields()) {
                fieldTokenPaths.add(field.getFieldPath());
            }
        }

        return fieldTokenPaths;
    }
}