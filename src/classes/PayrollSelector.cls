/**
 * Created by Lambru Dmytro on 19.05.2020.
 */

public inherited sharing class PayrollSelector extends SObjectSelector {

    public static final Schema.SObjectType SOBJECT_TYPE = Schema.Payroll__c.SObjectType;

    // Record Types (RT)
    public static final Schema.RecordTypeInfo RECORD_TYPE_INFO_PAYROLL;

    // Setting the Record Types (RT)
    static {
        Map<String, RecordTypeInfo> apiNameToRecordTypeInfoMap = SOBJECT_TYPE.getDescribe().getRecordTypeInfosByDeveloperName();

        RECORD_TYPE_INFO_PAYROLL = apiNameToRecordTypeInfoMap.get('Payroll');
    }

    protected override SObjectType getSObjectType() {
        return SOBJECT_TYPE;
    }

    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {
        return new Map<String, SObjectQueryBuilder.RollupOperation>{
            'Id' => null
        };
    }
}