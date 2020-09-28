/**
 * Created by MaxymMirona on 12.03.2020.
 */

public inherited sharing class BudgetTransactionSelector extends SObjectSelector {
    private static final Integer SOQL_LIMIT_MAX = 50000;

    public static final Schema.SObjectType SOBJECT_TYPE = Schema.Budget_transaction__c.SObjectType;
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_REIMBURSABLE_EXPENSE = SOBJECT_TYPE.getDescribe().getRecordTypeInfosByDeveloperName().get('Reimbursable_expense');
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_INCLUDED_EXPENSE = SOBJECT_TYPE.getDescribe().getRecordTypeInfosByDeveloperName().get('Included_expense');

    public static final Map<ExpenseTypePicklistKey, String> EXPENSE_TYPE_PICKLIST_VALUES_MAP = new Map<ExpenseTypePicklistKey, String>{
            ExpenseTypePicklistKey.BONUS => 'Bonus',
            ExpenseTypePicklistKey.REIMBURSEMENT => 'Reimbursement'
    };

    public static final Map<ExpenseTypeDetailsPicklistKey, String> EXPENSE_TYPE_DETAILS_PICKLIST_VALUES_MAP = new Map<ExpenseTypeDetailsPicklistKey, String>{
            ExpenseTypeDetailsPicklistKey.OTHER => 'Other'
    };

    public enum ExpenseTypePicklistKey { BONUS,  REIMBURSEMENT }
    public enum ExpenseTypeDetailsPicklistKey { OTHER }

    protected override SObjectType getSObjectType() {
        return SOBJECT_TYPE;
    }

    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {
        return new Map<String, SObjectQueryBuilder.RollupOperation>{
                'Id' => null
        };
    }

    public List<Budget_transaction__c> getBudgetTransactionsWithRelatedBudgetTransactionItems(Set<Id> recordIds){
        String soql = queryBuilder
                .registerSubquery('Budget_transaction_items__r', new List<String>{'CurrencyIsoCode'})
                .registerField('Project__r.CurrencyIsoCode')
                .registerField('Status__c')
                .registerField('RecordTypeId')
                .registerField('SOW__c')
                .registerField('Project__r.Contract_type__c')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':recordIds')
                .toString();

        return Database.query(soql);
    }

}