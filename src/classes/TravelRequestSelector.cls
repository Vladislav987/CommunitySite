/**
 * Created by IlliaLuhovyi on 5/21/2020.
 */

public inherited sharing class TravelRequestSelector extends SObjectSelector{
    private static final Integer SOQL_LIMIT_MID = 25000;

    public static final Map<CountryPicklistKey, String> COUNTRY_PICKLIST_VALUES_MAP = new Map<CountryPicklistKey, String>{
            CountryPicklistKey.UKRAINE => 'Ukraine'
    };

    public enum CountryPicklistKey { UKRAINE }

    public static final Map<CityPicklistKey, String> CITY_PICKLIST_VALUES_MAP = new Map<CityPicklistKey, String>{
            CityPicklistKey.KYIV => 'Kyiv'
    };

    public enum CityPicklistKey { KYIV }

    @TestVisible
    protected override Map<String, SObjectQueryBuilder.RollupOperation> getFieldList() {
        return new Map<String, SObjectQueryBuilder.RollupOperation>{
                'Id' => null,
                'Name' => null,
                'Country__c' => null,
                'Start_date__c' => null
        };
    }

    @TestVisible
    protected override SObjectType getSObjectType() {
        return Travel_request__c.SObjectType;
    }

    public Travel_request__c[] getByContractorIdsAndProjectId(Set<Id> contractorIds, Id projectId) {
        String soql = queryBuilder
                .registerField('Id')
                .registerField('Budget_transaction__r.RecordType.Name')
                .registerField('Budget_transaction__r.Id')
                .registerField('Contractor_Name__c')
                .addWhere('Contractor_Name__c', SObjectQueryBuilder.ComparisonOperation.IN_OPERATION, ':contractorIds')
                .addWhere('Budget_transaction__r.Project__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectId')
                .registerLimit(SOQL_LIMIT_MID)
                .toString();

        return Database.query(soql);
    }

    public Travel_request__c[] getByContractorIdAndProjectId(String contractorId, String projectId) {
        String soql = queryBuilder
                .registerField('Id')
                .registerField('Name')
                .registerField('Country__c')
                .registerField('Start_date__c')
                .addWhere('Contractor_Name__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':contractorId')
                .addWhere('Budget_transaction__r.Project__c', SObjectQueryBuilder.ComparisonOperation.EQUALS, ':projectId')
                .registerLimit(SOQL_LIMIT_MID)
                .toString();

        return Database.query(soql);
    }
}