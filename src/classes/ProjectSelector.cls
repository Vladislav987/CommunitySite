public inherited sharing class ProjectSelector extends SObjectSelector {
    private static final Integer SOQL_LIMIT_MAX = 50000;
    private static final Integer SOQL_LIMIT_SINGLE_RECORD = 1;
    private static Map<String, Schema.ChildRelationship> PROJECT_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME = new Map<String, Schema.ChildRelationship>();
    private static Schema.SObjectType PROJECT_SOBJECT_TYPE = Project__c.getSObjectType();

    // picklist field values
    public static final Map<ContractTypePicklistKey, String> CONTRACT_TYPE_PICKLIST_VALUES_MAP = new Map<ContractTypePicklistKey, String>{
            ContractTypePicklistKey.FIXED_COST => 'Fixed cost'
    };

    public static final Map<ProjectTypePicklistKey, String> PROJECT_TYPE_PICKLIST_VALUES_MAP = new Map<ProjectTypePicklistKey, String>{
            ProjectTypePicklistKey.OUTSTAFF => 'Outstaff'
    };

    public static final Map<CompanyGroupPicklistKey, String> COMPANY_GROUP_PICKLIST_VALUES_MAP = new Map<CompanyGroupPicklistKey, String>{
        CompanyGroupPicklistKey.CUSTOMERTIMES => 'Customertimes'
    };

    public static final Map<DepartmentPicklistKey, String> DEPARTMENT_PICKLIST_VALUES_MAP = new Map<DepartmentPicklistKey, String>{
        DepartmentPicklistKey.SFDC_DEPARTMENT => 'SFDC Department'
    };

    public enum ContractTypePicklistKey { FIXED_COST }
    public enum ProjectTypePicklistKey { OUTSTAFF }
    public enum CompanyGroupPicklistKey { CUSTOMERTIMES }
    public enum DepartmentPicklistKey { SFDC_DEPARTMENT }

    static {
        for (Schema.ChildRelationship relationship : Project__c.SObjectType.getDescribe().getChildRelationships()){
            if (relationship != null){
                if (relationship.getChildSObject() != null){
                    if (relationship.getChildSObject().getDescribe() != null){
                        if (relationship.getChildSObject().getDescribe().getName() != null){
                            PROJECT_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME.put(relationship.getChildSObject().getDescribe().getName(), relationship);
                        }
                    }
                }
            }
        }
    }

    @TestVisible
    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {
        return new Map<String, SObjectQueryBuilder.RollupOperation>{
                'Id' => null,
                'Name' => null,
                'End_date__c' => null,
                'RecordTypeId' => null,
                'Start_date__c' => null
        };
    }
    @TestVisible
    protected override SObjectType getSObjectType() {
        return Project__c.SObjectType;
    }

    public Project__c getWithChildren(Id parentId) {
        String soql = queryBuilder
                .registerSubquery('Projects__r', new List<String>{
                        'Name'
                })
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':parentId')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();
        return Database.query(soql);
    }

    public Project__c getProjectWithAllocations(Id projectId, List<String> excludedStatuses){
        sObjectQueryBuilder subQuery = new sObjectQueryBuilder(PROJECT_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME.get('Allocation__c'), PROJECT_SOBJECT_TYPE);
        subQuery
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
                //.addWhere('Allocation_Type__c', SObjectQueryBuilder.ComparisonOperation.NOT_IN_OPERATION, ':excludedTypes')
                .addWhere('Status__c', SObjectQueryBuilder.ComparisonOperation.NOT_IN_OPERATION, ':excludedStatuses')
                .addWhere('Contractor__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null')
                .addWhere('Resource_Type__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null')
                .addWhere('Expected_Rate__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null');
        String soql = queryBuilder
                .registerField('Name')
                .registerSubquery(subQuery)
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectId')
                .registerLimit(1)
                .toString();

        return Database.query(soql);
    }

    public List<Project__c> getProjectsWithAllUniqueAllocationsByProjectIds(List<Id> projectIds, List<Allocation__c> excludedAllocations, List<String> excludedTypes, List<String> excludedStatuses){
        sObjectQueryBuilder subQuery = new sObjectQueryBuilder(PROJECT_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME.get('Allocation__c'), PROJECT_SOBJECT_TYPE);
        subQuery
                .registerField('Name')
                .registerField('Allocation__c')
                .registerField('Contractor__c')
                .registerField('Status__c')
                .registerField('Allocation_Type__c')
                .registerField('Project__r.Parent_project__c')
                .registerField('Start_date__c')
                .registerField('End_date__c')
                .registerField('Contractor__r.Name')
                .registerField('Resource_Type__c')
                .registerField('Expected_Rate__c')
                .registerField('CurrencyIsoCode')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.NOT_IN_OPERATION, ':excludedAllocations')
                .addWhere('Allocation_Type__c', SObjectQueryBuilder.ComparisonOperation.NOT_IN_OPERATION, ':excludedTypes')
                .addWhere('Status__c', SObjectQueryBuilder.ComparisonOperation.NOT_IN_OPERATION, ':excludedStatuses');

        String soql = queryBuilder
                .registerField('Name')
                .registerSubquery(subQuery)
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':projectIds')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        soql = AllocationService.addConvertCurrencyFieldsToSOQL(
                new List<Schema.SObjectField>{Schema.Allocation__c.fields.Expected_Rate__c},
                soql
        );

        return Database.query(soql);
    }

    public List<Project__c> getChildProjectsWithAllocationsByParentProject(Id parentProjectId, List<String> excludedStatuses){
        sObjectQueryBuilder subQuery = new sObjectQueryBuilder(PROJECT_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME.get('Allocation__c'), PROJECT_SOBJECT_TYPE);
        subQuery
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
                //.addWhere('Allocation_Type__c', SObjectQueryBuilder.ComparisonOperation.NOT_IN_OPERATION, ':excludedTypes')
                .addWhere('Status__c', SObjectQueryBuilder.ComparisonOperation.NOT_IN_OPERATION, ':excludedStatuses')
                .addWhere('Contractor__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null')
                .addWhere('Resource_Type__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null')
                .addWhere('Expected_Rate__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null');
        String soql = queryBuilder
                .registerField('Name')
                .registerSubquery(subQuery)
                .addWhere('Parent_Project__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':parentProjectId')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

    public List<Project__c> getProjectWithRelatedAllocations(List<Project__c> projects){
        sObjectQueryBuilder allocationSubQuery = new sObjectQueryBuilder(PROJECT_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME.get('Allocation__c'), PROJECT_SOBJECT_TYPE);
        allocationSubQuery
                .registerField('Allocation__c')
                .registerField('Contractor__c')
                .registerField('Status__c')
                .registerField('Allocation_Type__c')
                .registerField('Resource_Type__c')
                .registerField('Expected_Rate__c')
                .registerField('Project__c')
                .registerField('Start_date__c')
                .registerField('End_date__c')
                .registerField('CurrencyIsoCode')
                .registerField('Project__r.Parent_Project__c');
        sObjectQueryBuilder projectSubQuery = new sObjectQueryBuilder(PROJECT_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME.get('Project__c'), PROJECT_SOBJECT_TYPE);
        projectSubQuery
                .registerField('Id');

        String soql = queryBuilder
                .registerField('RecordTypeId')
                .registerField('Parent_Project__r.RecordTypeId')
                .registerSubquery(allocationSubQuery)
                .registerSubquery(projectSubQuery)
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':projects')
                .toString();

        return Database.query(soql);
    }

    public List<Project__c> getProjectWithRelatedAllocations(Id project){
        sObjectQueryBuilder allocationSubQuery = new sObjectQueryBuilder(PROJECT_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME.get('Allocation__c'), PROJECT_SOBJECT_TYPE);
        allocationSubQuery
                .registerField('Allocation__c')
                .registerField('Contractor__c')
                .registerField('Status__c')
                .registerField('Allocation_Type__c')
                .registerField('Resource_Type__c')
                .registerField('Project__c');
        sObjectQueryBuilder projectSubQuery = new sObjectQueryBuilder(PROJECT_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME.get('Project__c'), PROJECT_SOBJECT_TYPE);
        projectSubQuery
                .registerField('Id');

        String soql = queryBuilder
                .registerField('RecordTypeId')
                .registerField('Parent_Project__r.RecordTypeId')
                .registerSubquery(allocationSubQuery)
                .registerSubquery(projectSubQuery)
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':project')
                .toString();

        return Database.query(soql);
    }

    /**
     * @description [ICRM-590] Merge from QA sandbox to Alex sandbox by Dmytro Lambru.
     * @param projectId --
     *
     * @return --
     */
    public List<Project__c> getProjectFields(Id projectId){
        String soql = queryBuilder
                .registerField('Invoice_approver__c')
                .registerField('Account__c')
                .registerField('Billed_from__c')
                .registerField('CurrencyIsoCode')
                .registerField('Contract_type__c')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectId')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

    public List<Project__c> getSingleProjectById(Id projectId){
        String soql = queryBuilder
                .registerField('Project_Manager__c')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectId')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();
        return Database.query(soql);

    }

    public Id getProjectOwnerById(Id projectId) {
        String soql = queryBuilder
                .registerField('OwnerId')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectId')
                .toString();

        Project__c project = Database.query(soql);

        return project.OwnerId;
    }

}