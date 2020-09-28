/**
 * Created by Dmytro Ardashov on 18.04.2019.
 *
 * Selector for RollupSummarySetting__mdt Custom metadata type
 */

public class RollupSummarySettingsSelector extends SObjectSelector{

    /**
     * Method returns all active Rollup Summary Settings for specified Child Object Type
     * @param objectType - Child Object as mentioned in RollupSummarySetting__mdt Custom metadata type
     *
     * @return records of RollupSummarySetting__mdt type describing Rollup Summary Settings
     */

    public List<RollupSummarySetting__mdt> getActiveRollupSummarySettingsByChildObjectType(SObjectType objectType) {

        String objectTypeNm = objectType.getDescribe().name;
        queryBuilder = queryBuilder.addWhere('ChildObject__r.QualifiedApiName', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':objectTypeNm');
        queryBuilder = queryBuilder.addWhere('Active__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, 'true');
        String queryString = queryBuilder.toString();
        List<RollupSummarySetting__mdt> toReturn = Database.query(queryString);
        return toReturn;
    }

    /**
     * Method returns Rollup Summary Setting with specified developerName if it exists and is set as active
     * @param developerName - API name of RollupSummarySetting__mdt Custom metadata type record
     *
     * @return record of RollupSummarySetting__mdt type describing Rollup Summary Settings
     */

    public RollupSummarySetting__mdt getActiveRollupSummarySettingByName(String developerName) {

        queryBuilder = queryBuilder.addWhere('DeveloperName', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':developerName');
        queryBuilder = queryBuilder.addWhere('Active__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, 'true');
        String queryString = queryBuilder.toString();
        List<RollupSummarySetting__mdt> queryResult = Database.query(queryString);

        if (queryResult.isEmpty()) {

            return null;
        }
        else {

            return queryResult[0];
        }
    }

    protected override SObjectType getSObjectType() {
        return Schema.getGlobalDescribe().get('RollupSummarySetting__mdt');
    }

    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {
        return new Map<String,SObjectQueryBuilder.RollupOperation>{
                'DeveloperName' => null,
                'ChildObject__r.QualifiedApiName' => null,
                'FieldToAggregate__r.QualifiedApiName' => null,
                'LookupField__r.QualifiedApiName' => null,
                'ParentObject__r.QualifiedApiName' => null,
                'TargetField__r.QualifiedApiName' => null,
                'RollupFilterCriteria__c' => null,
                'RollupType__c' => null,
                'Active__c' => null
        };
    }
}