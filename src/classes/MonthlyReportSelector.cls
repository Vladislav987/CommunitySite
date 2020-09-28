/**
 * Created by Mychailo Hamdzii on 23.04.2019.
 */

public inherited sharing class MonthlyReportSelector extends SObjectSelector{
    private static final Integer SOQL_LIMIT_MAX = 50000;
    private static Map<String, Schema.ChildRelationship> MONTHLY_REPORT_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME = new Map<String, Schema.ChildRelationship>();
    private static Schema.SobjectType MONTHLY_REPORT_SOBJECT_TYPE = Monthly_Report__c.getSObjectType();

    static {
        for (Schema.ChildRelationship relationship : Monthly_Report__c.SObjectType.getDescribe().getChildRelationships()){
            if (relationship != null){
                if (relationship.getChildSObject() != null){
                    if (relationship.getChildSObject().getDescribe() != null){
                        if (relationship.getChildSObject().getDescribe().getName() != null){
                            MONTHLY_REPORT_CHILD_RELATIONSHIPS_BY_SOBJECT_NAME.put(relationship.getChildSObject().getDescribe().getName(), relationship);
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
        return Monthly_Report__c.SObjectType;
    }
    /**
     * Selecting all monthly reports for allocation in list on date period
     *
     * @param allocations - childs of this allocations to select
     * @param reportRangeStart - period to get(<Monthly_Report_Period_start__c> field on monthly report)
     *
     * @return List<Monthly_Report__c> - all reports, passed with input params
     */
    public List<Monthly_Report__c> getReportsByRangeForAllocations(List<Allocation__c> allocations, String periodAsString) {
        String soql = queryBuilder
            .registerField('Allocation__c')
            .addWhere('Allocation__c', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':allocations')
            .addWhere('Monthly_Report_Period__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':periodAsString')
            .toString();

        return Database.query(soql);
    }
    /**
     * Selecting all related report to this allocation for further filtration
     *
     * @param allocationId - parent allocation Id
     *
     * @return List<Monthly_Report__c> - reports for this period for this allocation
     */
    public List<Monthly_Report__c> getReportsByAllocationId(Id allocationId) {
        String soql = queryBuilder
            .registerField('Monthly_Report_Period__c')
            .addWhere('Allocation__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':allocationId')
            .registerLimit(SOQL_LIMIT_MAX)
            .toString();

        return Database.query(soql);
    }

    public Set<Id> getReportsByAllocationsIds(Set<Id> allocationIds){
        String soql  = queryBuilder
                .registerField('Name')
                .addWhere('Allocation__c',  SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':allocationIds')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();
        List<Monthly_Report__c> reports = Database.query(soql);
        return new Map<Id, Monthly_Report__c>(reports).keySet();
    }
    public List<Monthly_Report__c> getMonthlyReportsWithFieldMonthlyReports(Set<Id> monthlyReports){

        String soql = queryBuilder
                .registerField('Allocation__r.Expected_Rate__c')
                .registerField('Contractor__c')
                .registerField('RecordTypeId')
                .registerField('Coefficient_1__c')
                .registerField('Coefficient_2__c')
                .registerField('Allocation__r.Contract_Type__c')
                .registerField('Allocation__r.Allocation_Type__c')
                .registerField('Allocation__r.Billing_type__c')
                .registerField('Fact_hours__c')
                .registerField('CurrencyIsoCode')
                .registerField('Allocation__r.CurrencyIsoCode')
                .registerField('Hourly_cost__c')
                .registerField('Period_in_Date_Format__c')
                .registerField('Monthly_Report_Start_Date__c')
                .registerField('Contractor__r.Salary__c')
                .registerField('Contractor__r.CurrencyIsoCode')
                .registerField('Monthly_Report_Period__c')
                .registerField('Allocation__r.Station__c')
                .registerField('Allocation__r.Expected_Rate_Monthly__c')
                .registerField('Allocation__r.Start_date__c')
                .registerField('Allocation__r.End_date__c')
                .registerSubquery('Monthly_Reports__r', new List<String>{'Fact_hours__c'})
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':monthlyReports')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

    public List<Monthly_Report__c> getMonthlyReports(List<Monthly_Report__c> monthlyReports){
        String soql = queryBuilder
                .registerField('Hourly_cost__c')
                .registerField('Monthly_revenueNew__c')
                .registerField('CurrencyIsoCode')
                .registerField('Company_monthly_cost_with_overhead__c')
                .registerField('Company_monthly_cost_without_overhead__c')
                .registerField('Monthly_Report_Start_Date__c')
                .registerField('Monthly_Report_End_Date__c')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':monthlyReports')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

    public List<Monthly_Report__c> getReportsByProjectIdAndAllocationAndPeriod(Id projectId, Set<String> allocationsIds, String period){
        String soql = queryBuilder
                .registerField('Monthly_Report_Period__c')
                .registerField('Project__c')
                .registerField('Allocation__c')
                .registerSubquery('Monthly_Reports__r', new List<String>{'Id', 'Name', 'Project__c'})
                .addWhere('Project__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectId')
                .addWhere('Allocation__c',SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':allocationsIds')
                .addWhere('Monthly_Report_Period__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':period')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

    public List<Monthly_Report__c> getReportsByIds(List<Id> reportIds){
        String soql = queryBuilder
                .registerField('Monthly_Report_Start_Date__c')
                .registerField('Monthly_Report_End_Date__c')
                .registerField('Allocation__r.Billed_as__c')
                .registerField('Allocation__r.CurrencyIsoCode')
                .registerField('Allocation__r.Expected_Rate__c')
                .registerField('CurrencyIsoCode')
                .registerField('Fact_hours__c')
                .registerField('Budget_transaction_item__c')
                .registerField('Budget_transaction_item__r.Billed_as__c')
                .registerField('Budget_transaction_item__r.CurrencyIsoCode')
                .registerField('Budget_Transaction_item__r.Rate__c')
                .registerField('Monthly_revenueNew__c')
                .registerField('Allocation__r.SOW__c')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':reportIds')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

    public List<Monthly_Report__c> getReportsByProjectAndParentProjectIdAndFieldSet(Id projectId, String fieldSet){
        List<String> fields = getFieldsTokenPathFromFieldSet(fieldSet);                                                 //Retrieve field token path from FieldSet

        for (String field : fields){
            queryBuilder.registerField(field);
        }

        String soql = queryBuilder
                .registerField('Monthly_Report_Period__c')                                                      //For Related List filter
                .registerField('Project__r.RecordType.Name')
                .registerField('Project__r.Parent_Project__r.RecordType.Name')
                .registerField('Allocation__r.Contractor__c')
                .registerField('Contractor__r.Name')
                .registerField('Allocation__r.Status__c')
                .addWhere('Project__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectId')
                .registerOther('ORDER BY Project__r.Name ASC')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

    public List<Monthly_Report__c> getMonthlyReportsWithRelatedBudgetTransaction(
            String projectId,
            List<String> additionalFieldsToQuery,
            String fieldSet,
            List<String> allocationTypes,
            List<String> allocationStatuses
    ){
        List<String> fields = getFieldsTokenPathFromFieldSet(fieldSet);                                                 //Retrieve field token path from FieldSet

        for (String field : fields){
            queryBuilder.registerField(field);
        }

        for (String additionalField : additionalFieldsToQuery){
            queryBuilder.registerField(additionalField);
        }

        String soql = queryBuilder
                .registerField('Id')
                .registerField('Name')
                .registerField('Monthly_Report_Start_Date__c')
                .registerField('Monthly_Report_End_Date__c')
                .registerField('Budget_transaction_item__r.Budget_transaction__r.Name')
                .registerField('Budget_transaction_item__r.Budget_transaction__r.Invoiced_on__c')
                .registerField('Budget_transaction_item__r.Budget_transaction__r.Status__c')
                .registerField('Budget_transaction_item__r.Budget_transaction__r.RecordTypeId')
                .registerField('Budget_transaction_item__r.Budget_transaction__r.Accrual_status__c')
                .registerField('Budget_transaction_item__r.Budget_transaction__r.Invoice__c')
                .registerField('Budget_transaction_item__r.Budget_transaction_item__r.Budget_transaction__r.Name')
                .registerField('Budget_transaction_item__r.Budget_transaction_item__r.Budget_transaction__r.Invoiced_on__c')
                .registerField('Budget_transaction_item__r.Budget_transaction_item__r.Budget_transaction__r.Status__c')
                .registerField('Budget_transaction_item__r.Budget_transaction_item__r.Budget_transaction__r.RecordTypeId')
                .registerField('Budget_transaction_item__r.Budget_transaction_item__r.Budget_transaction__r.Accrual_status__c')
                .registerField('Budget_transaction_item__r.Budget_transaction_item__r.Budget_transaction__r.Invoice__c')
                //.registerSubquery(subQuery)
                .addWhere('Project__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectId')
                .addWhere('Allocation__r.Allocation_Type__c', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':allocationTypes')
                .addWhere('Fact_hours__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null')
                .addWhere('Allocation__r.Billed_as__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null')
                .addWhere('Allocation__r.Expected_Rate__c', SObjectQueryBuilder.ComparisonOperation.NOT_EQUALS, 'null')
                .addWhere('Allocation__r.Status__c', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':allocationStatuses')
                .toString();

        return Database.query(soql);
    }

    public List<Monthly_Report__c> getWithRateAndContractor(List<Id> reportIds){
        String soql = queryBuilder
                .registerField('Contractor__c')
                .registerField('Hourly_rate__c')
                .registerField('Hourly_cost__c')
                .registerField('Company_monthly_cost__c')
                .registerField('Company_monthly_cost_with_overhead__c')
                .registerField('Company_monthly_cost_without_overhead__c')
                .registerField('Contractor__r.NBA_position__c')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':reportIds')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

    private List<String> getFieldsTokenPathFromFieldSet(String fieldsetName){
        List<String> fieldTokenPaths;

        if (!String.isEmpty(fieldsetName)) {
            fieldTokenPaths = new List<String>();
            Schema.FieldSet fieldset = Schema.SObjectType.Monthly_Report__c.fieldSets.getMap().get(fieldsetName);

            if (fieldset != null) {
                for (Schema.FieldSetMember field : fieldset.getFields()) {
                    fieldTokenPaths.add(field.getFieldPath());
                }
            }
        }

        return fieldTokenPaths;
    }

}