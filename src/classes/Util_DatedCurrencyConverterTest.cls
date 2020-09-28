/**
 * Created by Lambru Dmytro on 13.04.2020.
 */
@IsTest
private class Util_DatedCurrencyConverterTest {

    @IsTest
    static void testConvertCurrencyToTodayRates_success() {
        Util_DatedCurrencyConverter datedCurrencyConverter = new Util_DatedCurrencyConverter();

        // call to private method
        datedCurrencyConverter.initDataForTodayCurrencyConversion();

        // access to a private variable named "isoCodeToTodayCurrencyRateMap"
        if (datedCurrencyConverter.isoCodeToTodayCurrencyRateMap.size() > 0 ) {
            String firstIsoCode = new List<String>(datedCurrencyConverter.isoCodeToTodayCurrencyRateMap.keySet())[0];
            Decimal rateForFirstIsoCode = datedCurrencyConverter.isoCodeToTodayCurrencyRateMap.get(firstIsoCode);

            for (String isoCode : datedCurrencyConverter.isoCodeToTodayCurrencyRateMap.keySet()) {

                if (isoCode == firstIsoCode) continue;
                Decimal result = datedCurrencyConverter.convertCurrencyToTodayRates(100, isoCode, firstIsoCode);

                Decimal rateForCurrentIsoCode = datedCurrencyConverter.isoCodeToTodayCurrencyRateMap.get(isoCode);

                if (rateForCurrentIsoCode < rateForFirstIsoCode) {
                    System.assertEquals(true, result > 100, 'The result after conversion should be greater.');
                }
                else if (rateForCurrentIsoCode == rateForFirstIsoCode) {
                    System.assertEquals(true, result == 100, 'The result after conversion should be the same.');
                }
                else {
                    System.assertEquals(true, result < 100, 'The result after conversion should be less.');
                }

            }
        }
    }

    @IsTest
    static void testConvertCurrencyToTodayRates_success_sameIsoCodes() {
        Util_DatedCurrencyConverter datedCurrencyConverter = new Util_DatedCurrencyConverter();

        // call to private method
        datedCurrencyConverter.initDataForTodayCurrencyConversion();

        // access to a private variable named "isoCodeToTodayCurrencyRateMap"
        if (datedCurrencyConverter.isoCodeToTodayCurrencyRateMap.size() > 0 ) {
            String firstIsoCode = new List<String>(datedCurrencyConverter.isoCodeToTodayCurrencyRateMap.keySet())[0];

            Decimal result = datedCurrencyConverter.convertCurrencyToTodayRates(100, firstIsoCode, firstIsoCode);
            System.assertEquals(true, result == 100, 'The result after conversion should be the same.');
        }
    }

    @IsTest
    static void testConvertCurrencyToTodayRates_inner_exception() {
        Util_DatedCurrencyConverter datedCurrencyConverter = new Util_DatedCurrencyConverter();

        // call to private method
        datedCurrencyConverter.initDataForTodayCurrencyConversion();

        // access to a private variable named "isoCodeToTodayCurrencyRateMap"
        if (datedCurrencyConverter.isoCodeToTodayCurrencyRateMap.size() > 0 ) {
            String firstIsoCode = new List<String>(datedCurrencyConverter.isoCodeToTodayCurrencyRateMap.keySet())[0];


            try {
                datedCurrencyConverter.convertCurrencyToTodayRates(100, '', '');
            }
            catch (Util_DatedCurrencyConverter.Util_DatedCurrencyConverterException exc) {
                System.assertEquals(Util_DatedCurrencyConverter.EXCEPTION_MSG_EMPTY_ISO_CODE, exc.getMessage());
            }

            try {
                datedCurrencyConverter.convertCurrencyToTodayRates(100, 'INVALID', firstIsoCode);
            }
            catch (Util_DatedCurrencyConverter.Util_DatedCurrencyConverterException exc) {
                System.assertEquals(Util_DatedCurrencyConverter.EXCEPTION_MSG_NOT_ACTIVE_FROM_ISO_CODE, exc.getMessage());
            }

            try {
                datedCurrencyConverter.convertCurrencyToTodayRates(100, firstIsoCode, 'INVALID');
            }
            catch (Util_DatedCurrencyConverter.Util_DatedCurrencyConverterException exc) {
                System.assertEquals(Util_DatedCurrencyConverter.EXCEPTION_MSG_NOT_ACTIVE_TO_ISO_CODE, exc.getMessage());
            }
        }
    }
}