/**
 * Created by Dmytro Ardashov on 22.04.2019.
 */

public without sharing class RollupSummaryChildSelector extends SObjectSelector {

    /**
     * rsSetting - Rollup Summary Setting description
     */
    private RollupSummaryService.RollupSummarySetting rsSetting {
        get;
        set {
            rsSetting = value;
            injectFields();
            queryBuilder.registerOther('GROUP BY ' + rsSetting.lookupFieldName + ' HAVING ' + rsSetting.lookupFieldName +' != null');
        }
    }

    /**
     * constructor
     *
     * @param rsSetting - Rollup Summary Setting
     * @param queryBuilder -  sObjectQueryBuilder instantiated for SObject named as specified in rsSetting.childObjectName
     */
    public RollupSummaryChildSelector(RollupSummaryService.RollupSummarySetting rsSetting, sObjectQueryBuilder queryBuilder ) {

        super(true, true, queryBuilder);
        this.rsSetting = rsSetting;
    }

    protected override Schema.SObjectType getSObjectType() {

        if (rsSetting != null) {

            return Schema.getGlobalDescribe().get(rsSetting.childObjectName);
        }
        else {

            return null;
        }
    }

    protected override Map<String,SObjectQueryBuilder.RollupOperation> getFieldList() {

        if (rsSetting != null) {

            return getChildFieldMap(rsSetting);
        }
        else {

            return null;
        }
    }

    /**
     * Method to return AggregateResults for all existing children
     *
     * @return AggregateResults according to Rollup Summary Setting description
     */
    public List<AggregateResult> getAggregateResults() {

        if (!String.isEmpty(rsSetting.rollupFilterCriteria)) {

            queryBuilder.registerWhere('WHERE ' + rsSetting.rollupFilterCriteria);
        }

        return Database.query(queryBuilder.toString());
    }

    /**
     * Method to return AggregateResults for all children related to parents with Id in scopeIds
     *
     * @param scopeIds - parents Ids scope
     *
     * @return AggregateResults according to Rollup Summary Setting description
     */
    public List<AggregateResult> getAggregateResults(Set<Id> scopeIds) {

        if (!String.isEmpty(rsSetting.rollupFilterCriteria)) {

            queryBuilder.registerWhere('WHERE ' + rsSetting.rollupFilterCriteria + ' AND ' + rsSetting.lookupFieldName + ' IN :scopeIds');
        }
        else {

            queryBuilder.registerWhere('WHERE ' + rsSetting.lookupFieldName + ' IN :scopeIds');
        }


        return Database.query(queryBuilder.toString());
    }

    private Map<String,SObjectQueryBuilder.RollupOperation> getChildFieldMap(RollupSummaryService.RollupSummarySetting rsSetting) {

        SObjectQueryBuilder.RollupOperation rollupOperation = getRollupOperationByName(rsSetting.rollupType);

        Map<String,SObjectQueryBuilder.RollupOperation> toReturn = new Map<String,SObjectQueryBuilder.RollupOperation>{
                rsSetting.fieldToAggregateName => rollupOperation,
                rsSetting.lookupFieldName => null
        };

        return toReturn;
    }

    private SObjectQueryBuilder.RollupOperation getRollupOperationByName(String rollupOperationName) {

        List<SObjectQueryBuilder.RollupOperation> rollupOperations = SObjectQueryBuilder.RollupOperation.values();
        for (SObjectQueryBuilder.RollupOperation rollupOperation : rollupOperations) {

            if (rollupOperation.name().equalsIgnoreCase(rollupOperationName)) {

                return rollupOperation;
            }
        }
        return null;
    }
}