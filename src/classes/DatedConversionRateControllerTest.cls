/**
 * Created by MaxymMirona on 26.12.2019.
 */
@IsTest
public with sharing class DatedConversionRateControllerTest {

    private static final Date TEST_TODAYS_DATE = System.today();
    private static String corporateISOCode = [SELECT IsoCode FROM CurrencyType WHERE IsCorporate = true LIMIT 1].IsoCode;
    private static String notCorporateISOCode = [SELECT IsoCode FROM CurrencyType WHERE IsCorporate = false LIMIT 1].IsoCode;
    private static DatedConversionRate corporateDatedConversionRate = [SELECT IsoCode, ConversionRate FROM DatedConversionRate WHERE IsoCode =: corporateISOCode LIMIT 1];
    private static DatedConversionRate notCorporateDatedConversionRate = [SELECT IsoCode, ConversionRate FROM DatedConversionRate WHERE IsoCode =: notCorporateISOCode LIMIT 1];
    private static DatedConversionRateServiceUpsertMock upsertCalloutMock = new DatedConversionRateServiceUpsertMock();
    private static DatedConversionRateServiceGetTokenMock getTokenMock = new DatedConversionRateServiceGetTokenMock();

    @IsTest
    private static void getRelatedListInitDataTestCorrectFlow(){

        Test.setMock(HttpCalloutMock.class, new DatedConversionRateServiceGetTokenMock());

        Test.startTest();

        DatedConversionRateController.RelatedListInfo relatedListInfo = DatedConversionRateController.getRelatedListInitData();

        Test.stopTest();

        System.assertEquals(corporateISOCode, relatedListInfo.corporateISOCode);
    }

    @IsTest
    private static void getDatedConversionRatesToInsertTestCorrectFlow(){

        Test.setMock(HttpCalloutMock.class, new DatedConversionRateServiceGetTokenMock());

        Test.startTest();

        List<DatedConversionRate> ratesToInsert = DatedConversionRateController.getDatedConversionRatesToInsert(new List<DatedConversionRate>{notCorporateDatedConversionRate});

        Test.stopTest();

        System.assertEquals(notCorporateISOCode, ratesToInsert[0].IsoCode);
    }

    @IsTest
    private static void getDatedConversionRatesToInsertTestIncorrectFlow(){

        Test.setMock(HttpCalloutMock.class, new DatedConversionRateServiceGetTokenMock());

        Test.startTest();

        List<DatedConversionRate> ratesToInsert = DatedConversionRateController.getDatedConversionRatesToInsert(new List<DatedConversionRate>{corporateDatedConversionRate});

        Test.stopTest();

        System.assertEquals(0, ratesToInsert.size());
    }

    @IsTest
    private static void upsertDatedConversionRateTestInsertCorrectFlow(){

        List<DatedConversionRate> ratesToInsert = new List<DatedConversionRate>();

        Map<String, HttpCalloutMock> mocks = new Map<String, HttpCalloutMock>();

        ratesToInsert.add(new DatedConversionRate(
                IsoCode = notCorporateISOCode,
                ConversionRate = 1,
                StartDate = TEST_TODAYS_DATE));

        Dated_Conversion_Rate_Component_Config__mdt config = [SELECT Id,
                Consumer_Key__c,
                Consumer_Secret__c,
                Integration_User_Password__c,
                Integration_User_Username__c
        FROM Dated_Conversion_Rate_Component_Config__mdt
        WHERE DeveloperName = 'Main'
        LIMIT 1];

        mocks.put(DatedConversionRateService.getOrgLoginURL(), getTokenMock);
        mocks.put(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v47.0/composite/sobjects', upsertCalloutMock);

        HttpCalloutMock multiRequestMock = new MultiRequestMock(mocks);

        Test.setMock(HttpCalloutMock.class, multiRequestMock);

        Test.startTest();

        String response = DatedConversionRateController.upsertDatedConversionRate(ratesToInsert);

        Test.stopTest();

        System.assertEquals('Success', response);
    }

}