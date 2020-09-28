public inherited sharing class SalaryHistorySelector extends SObjectSelector{
    private static final Integer SOQL_LIMIT_MAX = 50000;
    private static final Integer SOQL_LIMIT_SINGLE_RECORD = 1;

    protected override SObjectType getSObjectType() {
        return Salary_History__c.SObjectType;
    }

    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {
        return new Map<String, SObjectQueryBuilder.RollupOperation>{
                'Id' => null,
                'Salary__c' => null,
                'Start_Date__c' => null,
                'End_Date__c' => null,
                'CurrencyIsoCode' => null,
                'Contractor__c' => null
        };
    }

    public List<Salary_History__c> getByContractorsIds(Set<Id> contractorsIds, Set<Id> salaryHistoriesIds) {
        String soql = queryBuilder
                .registerField('Contractor__r.Salary__c')
                .addWhere('Contractor__c', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':contractorsIds')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.NOT_IN_OPERATION, ':salaryHistoriesIds')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();
        return Database.query(soql);
    }
    public List<Salary_History__c> getSalaryHistoryWithFieldSetFields(List<String> fieldApiNames, Id contractorId) {
        SObjectQueryBuilder builder = queryBuilder;

        for (String field : fieldApiNames) {
            builder = builder.registerField(field);
        }

        String soql = builder
                .addWhere('Contractor__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':contractorId')
                .registerOther('ORDER BY End_Date__c DESC')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

}