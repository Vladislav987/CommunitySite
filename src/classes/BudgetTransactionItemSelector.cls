/**
 * Created by MaxymMirona on 02.06.2020.
 */


public inherited sharing class BudgetTransactionItemSelector extends SObjectSelector {
    private static final Integer SOQL_LIMIT_MAX = 50000;

    public static final Schema.SObjectType SOBJECT_TYPE = Schema.Budget_transaction_Item__c.SObjectType;

    protected override SObjectType getSObjectType() {
        return SOBJECT_TYPE;
    }

    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {
        return new Map<String, SObjectQueryBuilder.RollupOperation>{
                'Id' => null
        };
    }

    public List<Budget_transaction_item__c> getBudgetTransactionItemWithRelatedMonthlyReports(Set<Id> recordIds){
        String soql = queryBuilder
                .registerSubquery('Monthly_Reports__r', new List<String>{
                        'CurrencyIsoCode',
                        'Allocation__r.Billed_as__c',
                        'Allocation__r.Expected_Rate__c',
                        'Allocation__r.CurrencyIsoCode',
                        'CurrencyIsoCode',
                        'Budget_Transaction_item__r.Name',
                        'Budget_Transaction_item__r.Hours__c',
                        'Budget_Transaction_item__r.Total_Amount__c',
                        'Budget_Transaction_item__r.CurrencyIsoCode',
                        'Budget_Transaction_item__r.Budget_Transaction__c',
                        'Budget_Transaction_item__r.Billed_as__c',
                        'Budget_Transaction_item__r.Rate__c',
                        'Budget_transaction_item__c',
                        'Monthly_Report_Start_Date__c',
                        'Monthly_revenueNew__c',
                        'Fact_hours__c',
                        'Project__c'
                })
                .registerField('Budget_Transaction__c')
                .registerField('Total_Amount__c')
                .registerField('Hours__c')
                .registerField('Billed_as__c')
                .registerField('CurrencyIsoCode')
                .registerField('Rate__c')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':recordIds')
                .toString();

        return Database.query(soql);
    }
}