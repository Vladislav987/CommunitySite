/**
 * Created by MaxymMirona on 23.12.2019.
 */

public with sharing class DatedConversionRateSelector extends SObjectSelector{
    private static final Integer SOQL_LIMIT_MAX = 50000;

    @TestVisible
    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {
        return new Map<String, SObjectQueryBuilder.RollupOperation>{
                'Id' => null
        };
    }

    @TestVisible
    protected override SObjectType getSObjectType() {
        return DatedConversionRate.SObjectType;
    }

    public List<DatedConversionRate> getDatedConversionRatesForRelatedList(List<String> fieldToSelect){

        for (String field : fieldToSelect){
            queryBuilder.registerField(field);
        }

        String soql = queryBuilder
                .registerField('IsoCode')
                .registerField('ConversionRate')
                .registerField('StartDate')
                .registerField('NextStartDate')
                .addWhere('StartDate', SObjectQueryBuilder.ComparisonOperation.LESS_OR_EQUALS, 'TODAY')
                .registerOther('ORDER BY StartDate DESC')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

    public List<DatedConversionRate> getAllDatedConversionRate(){

        String soql = queryBuilder
                .registerField('IsoCode')
                .registerField('ConversionRate')
                .registerField('StartDate')
                .registerLimit(SOQL_LIMIT_MAX)
                .toString();

        return Database.query(soql);
    }

}