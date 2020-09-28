/**
 * Created by IlliaLuhovyi on 6/10/2020.
 */
public inherited sharing class PayrollComponentItemSelector extends SObjectSelector {
    private static final Integer SOQL_LIMIT_MID = 25000;

    // Fields
    public static final Schema.DescribeFieldResult DESCRIBE_FIELD_SUM = Payroll_Component_Item__c.Sum__c.getDescribe();
    public static final Schema.DescribeFieldResult DESCRIBE_FIELD_COMMENT = Payroll_Component_Item__c.Comment__c.getDescribe();
    public static final Schema.DescribeFieldResult DESCRIBE_FIELD_PAYROLL_COMPONENT = Payroll_Component_Item__c.Payroll_Component__c.getDescribe();
    public static final Schema.DescribeFieldResult DESCRIBE_FIELD_CURRENCY = Payroll_Component_Item__c.CurrencyIsoCode.getDescribe();


    public static final Schema.SObjectType SOBJECT_TYPE = Schema.Payroll_Component_Item__c.SObjectType;
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_REIMBURSEMENT_DETAILS;

    static {
        Map<String, RecordTypeInfo> apiNameToRecordTypeInfoMap = SOBJECT_TYPE.getDescribe().getRecordTypeInfosByDeveloperName();

        RECORD_TYPE_INFO_REIMBURSEMENT_DETAILS = apiNameToRecordTypeInfoMap.get('Reimbursement_details');
    }

    protected override SObjectType getSObjectType() {
        return SOBJECT_TYPE;
    }

    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {
        return new Map<String, SObjectQueryBuilder.RollupOperation>{
                'Id' => null
        };
    }

    public Payroll_Component_Item__c[] getByPayrollComponentId(Id payrollComponentId) {
        String soql = queryBuilder
                .registerField('Id')
                .registerField(DESCRIBE_FIELD_SUM.getName())
                .registerField(DESCRIBE_FIELD_CURRENCY.getName())
                .registerField(DESCRIBE_FIELD_COMMENT.getName())
                .registerField(DESCRIBE_FIELD_PAYROLL_COMPONENT.getName())
                .addWhere(DESCRIBE_FIELD_PAYROLL_COMPONENT.getName(), SObjectQueryBuilder.ComparisonOperation.EQUALS, ':payrollComponentId')
                .registerLimit(SOQL_LIMIT_MID)
                .toString();

        return Database.query(soql);
    }

    public Payroll_Component_Item__c[] getByIds(Set<Id> payrollComponentItemIds) {
        String soql = queryBuilder
                .registerField('Id')
                .registerField(DESCRIBE_FIELD_SUM.getName())
                .registerField(DESCRIBE_FIELD_CURRENCY.getName())
                .registerField(DESCRIBE_FIELD_COMMENT.getName())
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':payrollComponentItemIds')
                .registerLimit(SOQL_LIMIT_MID)
                .toString();

        return Database.query(soql);
    }
}