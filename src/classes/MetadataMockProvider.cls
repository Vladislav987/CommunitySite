/**
 * Created by Mychailo Hamdzii on 22.04.2019.
 */
@IsTest
public with sharing class MetadataMockProvider implements StubProvider {
    /**
     * Mocking test class for RatesCoefitients, to work on any metadata change, from Stub Api
     *
     * @param stubbedObject
     * @param stubbedMethodName
     * @param returnType
     * @param listOfParamTypes
     * @param listOfParamNames
     * @param listOfArgs
     *
     * @return
     */
    public Object handleMethodCall(
        Object stubbedObject,
        String stubbedMethodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> listOfArgs
    ) {
        if (returnType.getName() == 'List<Rates_Coefitients__mdt>' && stubbedMethodName == 'getCoefitientsFromMdt') {
            List<Rates_Coefitients__mdt> rates = new List<Rates_Coefitients__mdt>();
            Rates_Coefitients__mdt rate = new Rates_Coefitients__mdt();
            rate.Id = 'm001t000000dHojAAE';
            rate.Label = 'mdt label';
            rate.Value__c = 21.00;
            rates.add(rate);

            return rates;
        } else {
            return null;
        }
    }
}