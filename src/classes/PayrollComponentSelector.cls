/**
 * Created by Lambru Dmytro on 10.04.2020.
 */
public inherited sharing class PayrollComponentSelector extends SObjectSelector {
    private static final Integer SOQL_LIMIT_MIN = 1;
    public static final Schema.SObjectType SOBJECT_TYPE = Schema.Payroll_Component__c.SObjectType;

    // Record Types (RT)
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_BONUS;
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_OVERTIME;
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_DEDUCTION;
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_REIMBURSEMENT;
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_INSURANCE;
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_ADJUSTMENTS;
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_RECURRENT_BONUS;
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_RECURRENT_DEDUCTION;
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_RECURRENT_INSURANCE;

    // Setting the Record Types (RT)
    static {
        Map<String, RecordTypeInfo> apiNameToRecordTypeInfoMap = SOBJECT_TYPE.getDescribe().getRecordTypeInfosByDeveloperName();

        RECORD_TYPE_INFO_BONUS = apiNameToRecordTypeInfoMap.get('Bonus');
        RECORD_TYPE_INFO_OVERTIME = apiNameToRecordTypeInfoMap.get('Overtime');
        RECORD_TYPE_INFO_DEDUCTION = apiNameToRecordTypeInfoMap.get('Deduction');
        RECORD_TYPE_INFO_REIMBURSEMENT = apiNameToRecordTypeInfoMap.get('Reimbursement');
        RECORD_TYPE_INFO_INSURANCE = apiNameToRecordTypeInfoMap.get('Insurance');
        RECORD_TYPE_INFO_ADJUSTMENTS = apiNameToRecordTypeInfoMap.get('Adjustments');
        RECORD_TYPE_INFO_RECURRENT_BONUS = apiNameToRecordTypeInfoMap.get('Recurrent_Bonus');
        RECORD_TYPE_INFO_RECURRENT_DEDUCTION = apiNameToRecordTypeInfoMap.get('Recurrent_Deduction');
        RECORD_TYPE_INFO_RECURRENT_INSURANCE = apiNameToRecordTypeInfoMap.get('Recurrent_Insurance');
    }

    // Fields
    public static final Schema.DescribeFieldResult DESCRIBE_FIELD_RESULT_HOURS = Payroll_Component__c.Hours__c.getDescribe();
    public static final Schema.DescribeFieldResult DESCRIBE_FIELD_RESULT_RECURRENT = Payroll_Component__c.Recurrent__c.getDescribe();

    // picklist field values
    public static final Map<ApprovalStatusPicklistKey, String> APPROVAL_STATUS_PICKLIST_VALUES_MAP = new Map<ApprovalStatusPicklistKey, String>{
        ApprovalStatusPicklistKey.APPROVED => 'Approved',
        ApprovalStatusPicklistKey.WAITING_FOR_APPROVAL => 'Waiting For Approval',
        ApprovalStatusPicklistKey.REJECTED => 'Rejected',
        ApprovalStatusPicklistKey.WAITING_FOR_MANAGER_APPROVAL => 'Waiting For Manager Approval'
    };

    public static final Map<SumTypePicklistKey, String> SUM_TYPE_PICKLIST_VALUES_MAP = new Map<SumTypePicklistKey, String>{
        SumTypePicklistKey.INCREMENT => 'Increment',
        SumTypePicklistKey.DECREMENT => 'Decrement'
    };

    public static final Map<AdjustmentTypePicklistKey, String> ADJUSTMENT_TYPE_PICKLIST_VALUES_MAP = new Map<AdjustmentTypePicklistKey, String>{
        AdjustmentTypePicklistKey.SALARY_ADJUSTMENT => 'Salary Adjustment'
    };

    public static final Map<ReimbursementTypePicklistKey, String> REIMBURSEMENT_TYPE_PICKLIST_VALUES_MAP = new Map<ReimbursementTypePicklistKey, String>{
            ReimbursementTypePicklistKey.REIMBURSABLE => 'Reimbursable',
            ReimbursementTypePicklistKey.NOT_REIMBURSABLE => 'NotReimbursable'
    };

    public enum ApprovalStatusPicklistKey { APPROVED, WAITING_FOR_APPROVAL, REJECTED, WAITING_FOR_MANAGER_APPROVAL }
    public enum SumTypePicklistKey { INCREMENT, DECREMENT }
    public enum AdjustmentTypePicklistKey { SALARY_ADJUSTMENT }
    public enum ReimbursementTypePicklistKey { REIMBURSABLE, NOT_REIMBURSABLE }

    protected override SObjectType getSObjectType() {
        return SOBJECT_TYPE;
    }

    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {
        return new Map<String, SObjectQueryBuilder.RollupOperation>{
            'Id' => null
        };
    }

    public Payroll_Component__c[] getComponentById(Id payrollComponentId) {
        String soql = queryBuilder
                .registerField('Id')
                .registerField('Sum__c')
                .registerField('CurrencyIsoCode')
                .registerField('Project__c')
                .registerField('Travel_request__c')
                .registerField('Rejection_Reason__c')
                .registerField('Approval_Status__c')
                .registerField('Reimbursment__c')
                .registerField('Approver__c')
                .addWhere('Id', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':payrollComponentId')
                .registerLimit(SOQL_LIMIT_MIN)
                .toString();

        return Database.query(soql);
    }
}