/**
 * Created by Lambru Dmytro on 13.04.2020.
 */
public inherited sharing class Util_DatedCurrencyConverter {

    @TestVisible private Map<String, Decimal> isoCodeToTodayCurrencyRateMap;

    // Text constants
    @TestVisible private final static String EXCEPTION_MSG_EMPTY_ISO_CODE = 'ISO code not specified!';
    @TestVisible private final static String EXCEPTION_MSG_NOT_ACTIVE_FROM_ISO_CODE = 'Unable to find active "fromIsoCode" ISO currency!';
    @TestVisible private final static String EXCEPTION_MSG_NOT_ACTIVE_TO_ISO_CODE = 'Unable to find active "toIsoCode" ISO currency!';

    @TestVisible
    private void initDataForTodayCurrencyConversion() {

        if (isoCodeToTodayCurrencyRateMap == null) {
            this.generateMapWithTodayCurrencyRates();
        }
    }

    private void generateMapWithTodayCurrencyRates() {
        DatedConversionRate[] datedConversionRateList = [
            SELECT Id, IsoCode, ConversionRate
            FROM DatedConversionRate
            WHERE NextStartDate > TODAY
            LIMIT 1000
        ];

        this.isoCodeToTodayCurrencyRateMap = new Map<String, Decimal>();

        for (DatedConversionRate datedConversionRate : datedConversionRateList) {
            this.isoCodeToTodayCurrencyRateMap.put(datedConversionRate.IsoCode, datedConversionRate.ConversionRate);
        }
    }

    public Decimal convertCurrencyToTodayRates(Decimal value, String fromIsoCode, String toIsoCode) {
        Decimal result;

        try {

            if (String.isEmpty(fromIsoCode) || String.isEmpty(toIsoCode)) {
                throw new Util_DatedCurrencyConverterException(EXCEPTION_MSG_EMPTY_ISO_CODE);
            }

            this.initDataForTodayCurrencyConversion();

            // ensure valid to/from ISO
            if (!this.isoCodeToTodayCurrencyRateMap.containsKey(fromIsoCode)) {
                throw new Util_DatedCurrencyConverterException(EXCEPTION_MSG_NOT_ACTIVE_FROM_ISO_CODE);
            }
            if (!this.isoCodeToTodayCurrencyRateMap.containsKey(toIsoCode)) {
                throw new Util_DatedCurrencyConverterException(EXCEPTION_MSG_NOT_ACTIVE_TO_ISO_CODE);
            }

            if (fromIsoCode.equalsIgnoreCase(toIsoCode)) {
                // if same
                result = value;
            }
            else {
                Decimal fromRate = this.isoCodeToTodayCurrencyRateMap.get(fromIsoCode.toUpperCase());
                Decimal toRate = this.isoCodeToTodayCurrencyRateMap.get(toIsoCode.toUpperCase());
                // calc rate
                Decimal rate = toRate/fromRate;

                // convert
                result = value * rate;
            }
        }
        catch (QueryException exc) {
            Util.trackException(true, exc, Util_DatedCurrencyConverter.class);
            throw exc;
        }
        catch (Exception exc) {
            Util.trackException(true, exc, Util_DatedCurrencyConverter.class);
            throw exc;
        }

        return result;
    }

    public class Util_DatedCurrencyConverterException extends Exception {}
}