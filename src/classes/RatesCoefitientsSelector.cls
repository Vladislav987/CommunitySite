/**
 * Created by Mychailo Hamdzii on 23.04.2019.
 */

public inherited sharing class RatesCoefitientsSelector extends SObjectSelector{
    private static final Integer SOQL_LIMIT_SINGLE_RECORD = 1;
    @TestVisible
    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {

        return new Map<String, SObjectQueryBuilder.RollupOperation>{
            'Id' => null,
            'Value__c' => null
        };
    }

    @TestVisible
    protected override SObjectType getSObjectType() {

        return Rates_Coefitients__mdt.SObjectType;
    }
    /**
     * Selecting Rates_Coefitients__mdt record by Label
     *
     * @param label - name of Rates_Coefitients__mdt record to select
     *
     * @return List<Rates_Coefitients__mdt> - selected mdt record as list
     */
    public List<Rates_Coefitients__mdt> getCoefitientsFromMdt(String label) {
        String soql = queryBuilder
            .addWhere('Label', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':label')
            .registerLimit(SOQL_LIMIT_SINGLE_RECORD)
            .toString();

        return Database.query(soql);
    }
}