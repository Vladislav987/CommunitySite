/**
 * Created by MaxymMirona on 27.12.2019.
 */
@IsTest
public with sharing class DatedConversionRateServiceTest {
    private static final String TEST_OBJECT_NAME = 'Monthly_Report__c';
    private static final String TEST_FIELD_NAME = 'Allocation__c';

    @IsTest
    private static void getLabelOfFieldWithParentRelationshipTestCorrectFlow(){

        String schemaObjectLabel = Schema.getGlobalDescribe().get(TEST_OBJECT_NAME).getDescribe().getLabel();
        String schemaFieldLabel = Schema.getGlobalDescribe().get(TEST_OBJECT_NAME).getDescribe().fields.getMap().get(TEST_FIELD_NAME).getDescribe().getLabel();

        Test.setMock(HttpCalloutMock.class, new DatedConversionRateServiceGetTokenMock());

        Test.startTest();

        String fieldLabel = DatedConversionRateService.getLabelOfFieldWithParentRelationship(TEST_OBJECT_NAME.removeEnd('c') + 'r.' + TEST_FIELD_NAME);

        Test.stopTest();

        System.assertEquals(schemaObjectLabel + ' ' + schemaFieldLabel, fieldLabel);
    }

}