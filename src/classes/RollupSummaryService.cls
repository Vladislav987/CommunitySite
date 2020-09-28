/**
 * Created by Dmytro Ardashov on 18.04.2019.
 * @description
 *  Custom Rollup Summary On Lookup Relationships Feature.
 *  RollupSummarySetting__mdt - Custom metadata type describes  lookup relationships need to be evaluated by Custom Rollup Summary Feature.
 *  Note, the only settings with "Active" field checked will be evaluated.
 *
 *  To start  Custom Rollup Summary evaluations for new Rollup Summary Setting do the following:
 *  1. Create new RollupSummarySetting record describing Rollup Summary On Lookup Relationships you need to be evaluated.
 *  2. Handle children mutations in Child Object Trigger:
 *  In proper Trigger handler instantiate RollupSummaryService service and call its recalculateRollupSummary method passing triggered records scope as list(s).
 *  (pass triggerOld and triggerNew lists in arter update case).
 *  Service will handle all active Rollup Summary Settings specified for Child Object.
 *  3. Do initial Rollup Summary calculations:
 *  In anonymous Apex call RollupSummaryService.doInitCalculations static method as described below:
 *  RollupSummaryService.doInitCalculations('NewRollupSummarySettingName');
 *  where 'NewRollupSummarySettingName' is the RollupSummarySetting Name for
 *  Rollup Summary Setting you've just created.
 *  Do initial Rollup Summary calculations only once when creating new Rollup Summary Setting.
 *
 *  For example look at:
 *  - Contractor All Active Allocations RollupSummarySetting record;
 *  - AllocationTriggerHandler class.  *
 */



public without sharing class RollupSummaryService {

    public class RollupSummarySetting {

        public String childObjectName {public get; private set;}
        public String fieldToAggregateName {public get; private set;}
        public String lookupFieldName {public get; private set;}
        public String parentObjectName {public get; private set;}
        public String targetFieldName {public get; private set;}
        public String rollupFilterCriteria {public get; private set;}
        public String rollupType {public get; private set;}
        public Boolean active {public get; private set;}

        @TestVisible
        private RollupSummarySetting(RollupSummarySetting__mdt rsSetting) {

            this.childObjectName = rsSetting.ChildObject__r.QualifiedApiName;
            this.fieldToAggregateName = rsSetting.FieldToAggregate__r.QualifiedApiName;
            this.lookupFieldName = rsSetting.LookupField__r.QualifiedApiName;
            this.parentObjectName = rsSetting.ParentObject__r.QualifiedApiName;
            this.targetFieldName = rsSetting.TargetField__r.QualifiedApiName;
            this.rollupFilterCriteria = rsSetting.RollupFilterCriteria__c;
            this.rollupType = rsSetting.RollupType__c;
            this.active = rsSetting.Active__c;
        }
    }

    public static Map<String, Decimal> organizationRates {
        get {
            Map<String, Decimal> rates = new Map<String, Decimal>();

            if (organizationRates == null){
                for (DatedConversionRate rate : [SELECT
                        ConversionRate,
                        IsoCode
                FROM DatedConversionRate]){
                    rates.put(rate.IsoCode, rate.ConversionRate);
                }
            }

            return rates;
        }
        set {}
    }

    /**
     * Static method to preform initial Rollup Summary calculations for new Rollup Summary Setting
     *
     * @param settingName - API Name for Rollup Summary Setting
     */
    public static void doInitCalculations(String settingName) {

        RollupSummarySettingsSelector selector = new RollupSummarySettingsSelector();
        RollupSummarySetting__mdt rsSettingMdt = selector.getActiveRollupSummarySettingByName(settingName);

        if (rsSettingMdt != null) {

            System.debug(JSON.serializePretty(rsSettingMdt));
            RollupSummaryService service = new RollupSummaryService();
            service.calculateRollupSummary(rsSettingMdt);
            System.debug('Init calculations for ' + settingName + ' are completed.');
        }
        else {

            System.debug(settingName + ': no such settings found or setting is not active');
        }

    }

    /**
     * Method used in after update trigger handler to handle children changes
     *
     * @param triggerNew - triggerNew records
     * @param triggerOld - triggerOld records
     */
    public void recalculateRollupSummary(List<SObject> triggerNew, List<SObject> triggerOld) {

        List<SObject> triggerScope = new List<SObject>();
        triggerScope.addAll(triggerNew);
        triggerScope.addAll(triggerOld);

        recalculateRollupSummary(triggerScope);
    }

    /**
     * Method used in after insert, after delete, after undelete trigger handler to handle children changes
     *
     * @param triggerScope - trigger scope
     */

    public void recalculateRollupSummary(List<SObject> triggerScope) {
        Map<String, Map<Id, SObject>> recordsBySObjectType = new Map<String, Map<Id, SObject>>();

        Map<RollupSummarySetting, Set<Id>> parentScopesByRollupSummarySettings = getParentScopesByRollupSummarySettings(triggerScope);
        for (RollupSummarySetting rsSetting : parentScopesByRollupSummarySettings.keySet()) {
            String parentObjName = rsSetting.parentObjectName;
            Set<Id> parentScopeIds = parentScopesByRollupSummarySettings.get(rsSetting);

            if (!parentScopeIds.isEmpty()) {
                Map<Id, SObject> recordsMapExisting = recordsBySObjectType.containsKey(parentObjName)?
                        recordsBySObjectType.get(parentObjName): new Map<Id, SObject>();
                Map<Id, SObject> recordsMap = this.getRecalculatedRecords(rsSetting, parentScopeIds, recordsMapExisting);

                System.debug('@@@ recordsMap: '+recordsMap);

                if (!recordsMap.isEmpty()) {
                    if (!recordsBySObjectType.containsKey(parentObjName)) {
                        recordsBySObjectType.put(parentObjName, new Map<Id, SObject>());
                    }
                    recordsBySObjectType.get(parentObjName).putAll(recordsMap);
                }
            }
        }

        try {
            for (String sobjectType : recordsBySObjectType.keySet()){
                if (!recordsBySObjectType.get(sobjectType).isEmpty()) {
                    update new List<SObject>(recordsBySObjectType.get(sobjectType).values());
                }
            }
        } catch (Exception e) {
            if (e.getTypeName() == System.DmlException.class.toString()){
                System.DmlException dmlException = (System.DmlException)e;

                if (dmlException.getDmlType(0) == StatusCode.UNABLE_TO_LOCK_ROW){
                    System.enqueueJob(new RollupSummaryServiceQueue(triggerScope));
                }
            }
        }
    }

    @TestVisible
    private void calculateRollupSummary(RollupSummarySetting__mdt rsSettingMdt) {

        RollupSummarySetting rsSetting = new RollupSummarySetting(rsSettingMdt);
        update this.getRecalculatedRecords(rsSetting).values();
    }

    @TestVisible
    private Map<RollupSummarySetting, Set<Id>> getParentScopesByRollupSummarySettings(List<SObject> triggerScope) {

        Map<RollupSummarySetting, Set<Id>> toReturn = new Map<RollupSummaryService.RollupSummarySetting, Set<Id>>();

        SObjectType childObjectType = triggerScope[0].getSObjectType();
        RollupSummarySettingsSelector rsSelector = new RollupSummarySettingsSelector();

        List<RollupSummarySetting__mdt> rollupSummarySettingsMdt = rsSelector.getActiveRollupSummarySettingsByChildObjectType(childObjectType);
        List<RollupSummarySetting> rollupSummarySettings = new List<RollupSummaryService.RollupSummarySetting>();

        for (RollupSummarySetting__mdt rollupSummarySettingMdt : rollupSummarySettingsMdt) {

            RollupSummarySetting rollupSummarySetting = new RollupSummarySetting(rollupSummarySettingMdt);
            rollupSummarySettings.add(rollupSummarySetting);
            toReturn.put(rollupSummarySetting, new Set<Id>());
        }

        for (SObject record : triggerScope) {

            for (RollupSummarySetting rsSetting : rollupSummarySettings) {

                if (record.get(rsSetting.lookupFieldName) != null) {

                    Id parentId = (Id)record.get(rsSetting.lookupFieldName);
                    toReturn.get(rsSetting).add(parentId);
                }
            }
        }

        return toReturn;
    }

    @TestVisible
    private Map<Id, SObject> getRecalculatedRecords(RollupSummarySetting rsSetting) {

        Map<Id, SObject> toReturn;

        SObjectQueryBuilder childQueryBuilder = new SObjectQueryBuilder(Schema.getGlobalDescribe().get(rsSetting.childObjectName));
        RollupSummaryChildSelector childSelector = new RollupSummaryChildSelector(rsSetting, childQueryBuilder);
        SObjectGenerator generator = new SObjectGenerator(rsSetting);

        List<AggregateResult> results = childSelector.getAggregateResults();

        toReturn = generator.populateSObjects(results, new Map<Id, SObject>());

        return toReturn;
    }

    @TestVisible
    private Map<Id, SObject> getRecalculatedRecords(RollupSummarySetting rsSetting, Set<Id> scopeIds, Map<Id, SObject> recordsMap) {
        Map<Id, SObject> toReturn;

        SObjectQueryBuilder childQueryBuilder = new SObjectQueryBuilder(Schema.getGlobalDescribe().get(rsSetting.childObjectName));
        RollupSummaryChildSelector childSelector = new RollupSummaryChildSelector(rsSetting, childQueryBuilder);
        SObjectGenerator generator = new SObjectGenerator(rsSetting);

        List<AggregateResult> results = childSelector.getAggregateResults(scopeIds);

        generator.populateSObjectsNULL(scopeIds, recordsMap);
        scopeIds.removeAll(recordsMap.keySet());
        if (!scopeIds.isEmpty()) {
            recordsMap.putAll(generator.generateSObjects());
        }

        toReturn = generator.populateSObjects(results, recordsMap);
        toReturn.putAll(recordsMap);

        return toReturn;
    }

    @TestVisible
    public static Decimal getConvertedCurrencyValue(Object amount, Object currencyIsoCode){
        Decimal decAmount = amount == null ? 0 : Decimal.valueOf(String.valueOf(amount));
        Decimal rate = organizationRates.get(String.valueOf(currencyIsoCode)) == null ? 1 : organizationRates.get(String.valueOf(currencyIsoCode));

        return decAmount * rate;
    }

    @TestVisible
    private class SObjectGenerator {

        @TestVisible
        private RollupSummarySetting rsSetting;

        @TestVisible
        private SObjectGenerator(RollupSummarySetting rsSetting) {

            this.rsSetting = rsSetting;
        }

        @TestVisible
        private Map<Id, SObject> populateSObjects(List<AggregateResult> aggregateResults, Map<Id, SObject> mapRecords) {
            Map<Id, SObject> toReturn = new Map<Id, SObject>();
            SObjectType type = Schema.getGlobalDescribe().get(rsSetting.parentObjectName);

            for (AggregateResult result : aggregateResults) {
                Id idx = (Id)result.get(rsSetting.lookupFieldName);
                SObject newSObject = mapRecords.containsKey(idx)? mapRecords.get(idx): type.newSObject(idx);
                if (Schema.getGlobalDescribe().get(rsSetting.childObjectName).getDescribe().fields.getMap().get(rsSetting.fieldToAggregateName).getDescribe().getType() == DisplayType.CURRENCY){
                    newSObject.put(rsSetting.targetFieldName, getConvertedCurrencyValue(result.get('expr0'), newSObject.get('CurrencyIsoCode')));
                } else {
                    newSObject.put(rsSetting.targetFieldName, result.get('expr0'));
                }
                toReturn.put(newSObject.Id, newSObject);
            }

            return toReturn;
        }

        @TestVisible
        private void populateSObjectsNULL(Set<Id> scopeIds, Map<Id, SObject> mapRecords) {
            for (Id sObjId : mapRecords.keySet()) {
                if(scopeIds.contains(sObjId)){
                    SObject newSObject = mapRecords.get(sObjId);
                    newSObject.put(rsSetting.targetFieldName, null);
                }
            }
        }

        @TestVisible
        private Map<Id, SObject> generateSObjects() {
            Map<Id, SObject> toReturn = new Map<Id, SObject>();
            SObjectType type = Schema.getGlobalDescribe().get(rsSetting.parentObjectName);

            for (SObject sObj : Database.query('SELECT Id, CurrencyIsoCode FROM ' + type)) {
                sObj.put(rsSetting.targetFieldName, null);
                toReturn.put(sObj.Id, sObj);
            }

            return toReturn;
        }

    }
}