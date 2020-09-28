public with sharing class DatedConversionRateService {

    private static final String ENDPOINT_BASE_URL = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v47.0/composite/sobjects';
    private static final String UNSUCCESSFUL_AUTHORIZATION_ERROR = 'Authorization was unsuccessful';
    private static final String REST_RESPONSE_ERROR_MESSAGE = 'Unfortunately, there are some errors. Please, contact your Administrator. \n\n Details: ';
    public static List<String> FIELDS_FOR_SELECTOR = new List<String>{'IsoCode', 'ConversionRate'};
    DatedConversionRateSelector datedConversionRateSelector = new DatedConversionRateSelector();

    private static String getAccessToken(){
        Dated_Conversion_Rate_Component_Config__mdt config = [SELECT Id,
                                                                     Consumer_Key__c,
                                                                     Consumer_Secret__c,
                                                                     Integration_User_Password__c,
                                                                     Integration_User_Username__c
                                                              FROM Dated_Conversion_Rate_Component_Config__mdt
                                                              WHERE DeveloperName = 'Main'
                                                              LIMIT 1];

        HttpRequest req = new HttpRequest();
        req.setEndpoint(getOrgLoginURL());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('grant_type=password' +
                '&client_id=' + config.Consumer_Key__c +
                '&client_secret=' + config.Consumer_Secret__c +
                '&username=' + config.Integration_User_Username__c +
                '&password=' + config.Integration_User_Password__c
        );

        Http http = new Http();
        Map<String, Object> responseMap = new Map<String, Object>();

        HTTPResponse response = http.send(req);

        if (response.getStatusCode() == 200) {
            responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                return responseMap.get('access_token').toString();
        }

        return UNSUCCESSFUL_AUTHORIZATION_ERROR;
    }

    public static String getOrgLoginURL(){
        Boolean isSandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
        String orgURL = 'https://';

        if (isSandbox){
            orgURL += 'test';
        } else {
            orgURL += 'login';
        }

        orgURL += '.salesforce.com/services/oauth2/token';

        return orgURL;
    }

    public DataTableWrapper getDatedConversionRatesForRelatedList(){
        DataTableWrapper dataTable = new DataTableWrapper();
        dataTable.recordsList = datedConversionRateSelector.getDatedConversionRatesForRelatedList(FIELDS_FOR_SELECTOR);
        dataTable.recordsList = getLatestConversionRates(dataTable.recordsList);
        dataTable.fieldsList = getFieldsDescribe();
        dataTable.fieldsTypes = getFieldTypesDescribe(dataTable.fieldsList.values());
        dataTable.ISOCodes = getISOCodes(dataTable.recordsList);

        return dataTable;
    }

    public List<DatedConversionRate> getDatedConversionRatesToInsert(List<DatedConversionRate> records){
        List<DatedConversionRate> newExchangeRates = new List<DatedConversionRate>();
        String corporateISOCOde = getCorporateISOCode();

        for (DatedConversionRate record :records){
            if (record.IsoCode != corporateISOCOde) {
                newExchangeRates.add(new DatedConversionRate(
                        IsoCode = record.IsoCode,
                        ConversionRate = record.ConversionRate
                ));
            }
        }

        return newExchangeRates;
    }

    public List<Date> getBlockedStartDates(){
        List<Date> blockedStartDates = new List<Date>();
        List<DatedConversionRate> rates = datedConversionRateSelector.getAllDatedConversionRate();

        for(DatedConversionRate rate : rates){
            if (!blockedStartDates.contains(rate.StartDate)){
                blockedStartDates.add(rate.StartDate);
            }
        }

        return blockedStartDates;
    }


    public String getCorporateISOCode(){
        return [SELECT IsoCode FROM CurrencyType WHERE IsCorporate = true LIMIT 1].IsoCode;
    }

    public List<String> getISOCodes (List<DatedConversionRate> rates){
        List<String> ISOCodes = new List<String>();

        for(DatedConversionRate rate : rates){
            if (!ISOCodes.contains(rate.IsoCode)){
                ISOCodes.add(rate.IsoCode);
            }
        }

        return ISOCodes;
    }

    public List<DatedConversionRate> getLatestConversionRates(List<DatedConversionRate> rates){
        Map<String, DatedConversionRate> ISOCodeToRate = new Map<String, DatedConversionRate>();
        List<String> activeCurrencies = new List<String>();

        for (CurrencyType activeCurrency : [SELECT IsoCode FROM CurrencyType WHERE IsActive = true]){
            activeCurrencies.add(activeCurrency.IsoCode);
        }

        for (DatedConversionRate rate : rates){
            if (!ISOCodeToRate.containsKey(rate.IsoCode) && activeCurrencies.contains(rate.IsoCode)){
                ISOCodeToRate.put(rate.IsoCode, rate);
            }
        }

        return ISOCodeToRate.values();
    }

    public Map<String, String> getFieldsDescribe(){
        Map<String, String> fieldsLabelAndPath = new Map<String, String>();
        for (String field : FIELDS_FOR_SELECTOR) {
            DescribeFieldResult fieldDescribe = Schema.getGlobalDescribe().get('DatedConversionRate').getDescribe().fields.getMap().get(field).getDescribe();
            if (field.contains('.')) {
                String fieldLabel = getLabelOfFieldWithParentRelationship(field);
                fieldsLabelAndPath.put(fieldLabel, field);
            }
            else {
                fieldsLabelAndPath.put(fieldDescribe.getLabel(), field);
            }
        }

        return fieldsLabelAndPath;
    }

    public Map<String, String> getFieldTypesDescribe(List<String> fieldsApiNames){
        Map<String, String> fieldsLabelsAndType = new Map<String, String>();
        for (String fieldApi : fieldsApiNames) {
            if (fieldApi.contains('.')) {
                String fieldLabel = getLabelOfFieldWithParentRelationship(fieldApi);
                fieldsLabelsAndType.put(fieldLabel, String.valueOf(Schema.DisplayType.REFERENCE));
                continue;
            }

            Schema.DisplayType type = Schema.getGlobalDescribe().get('DatedConversionRate').getDescribe().fields.getMap().get(fieldApi).getDescribe().getType();
            String label = Schema.getGlobalDescribe().get('DatedConversionRate').getDescribe().fields.getMap().get(fieldApi).getDescribe().getLabel();
            fieldsLabelsAndType.put(label, String.valueOf(type));
        }

        return fieldsLabelsAndType;
    }

    @TestVisible
    public static String getLabelOfFieldWithParentRelationship(String fieldPath){
        String fieldAPIName = fieldPath.substringAfterLast('.');          //customobject__r.customobject2__r.Name ----> Name
        fieldPath = fieldPath.removeEnd('.' + fieldAPIName);              //customobject__r.customobject2__r.Name ----> Customobject__r.customobject2__r
        String objectTokenPath;                                           //SObject token used in SOQL
        String objectAPIName;                                             //SObject API Name
        String objectLabel;                                               //SObject Label
        String fieldLabel;                                                //Returning field label

        if (fieldPath.contains('.')) {
            objectTokenPath = fieldPath.substringAfterLast('.');          //customobject__r.customobject2__r ----> customobject2__r
        }
        else {
            objectTokenPath = fieldPath;
        }

        if (objectTokenPath.contains('__r')){
            objectTokenPath = objectTokenPath.removeEnd('r') + 'c';        //customobject2__r ----> customobject2__c
        }

        if (objectTokenPath.equalsIgnoreCase('LastModifiedBy') || objectTokenPath.equalsIgnoreCase('CreatedBy')){
            objectAPIName = Schema.getGlobalDescribe().get('User').getDescribe().getName();                             //if we fetch through standard lookup parent field, i.e 'CreatedBy',
            objectLabel = Schema.getGlobalDescribe().get('User').getDescribe().getLabel();                              //which is originally User lookup
        }
        else {
            objectAPIName = Schema.getGlobalDescribe().get(objectTokenPath).getDescribe().getName();
            objectLabel = Schema.getGlobalDescribe().get(objectTokenPath).getDescribe().getLabel();
        }

        fieldLabel = Schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap().get(fieldAPIName).getDescribe().getLabel();
        if (!fieldLabel.contains(objectLabel)){
            fieldLabel = objectLabel + ' ' + fieldLabel;                                                                //If we retreive field without object label in it's own label
        }                                                                                                               //Example got 'Name' from Customobj__c and change to 'Customobj Name'
        if (objectTokenPath.equalsIgnoreCase('LastModifiedBy') || objectTokenPath.equalsIgnoreCase('CreatedBy')){
            fieldLabel = objectTokenPath + fieldLabel;                                                                  //If we retreive field without Standard object label in it's own label
        }                                                                                                               //Example got 'First Name' from CreatedBy and change to 'CreatedBy First Name'
        return fieldLabel;
    }

    public String upsertDatedConversionRateFromRelatedList(List<DatedConversionRate> recordsList) {

        if (getAccessToken() == UNSUCCESSFUL_AUTHORIZATION_ERROR){
            return UNSUCCESSFUL_AUTHORIZATION_ERROR;
        }

        HttpRequest request = new HttpRequest();
        request.setHeader('Authorization', 'OAuth ' + getAccessToken());
        request.setHeader('Content-Type', 'application/json');
        request.setMethod('POST');

        request = constructRequestBodyAndEndpoint(request, recordsList);

        Http http = new Http();
        HTTPResponse response = http.send(request);

        List<DatedConversionRateServiceWrapper> responseJSON = (List<DatedConversionRateServiceWrapper>)JSON.deserialize(response.getBody(), List<DatedConversionRateServiceWrapper>.class);
        String responseErrorsMessage = responseJSON.size() == 0 ? '' : responseJSON[0].errors == null ? 'Unexpected Error' : responseJSON[0].errors.size() == 0 ? '' : responseJSON[0].errors[0].message;

        return String.isEmpty(responseErrorsMessage) ? 'Success' : REST_RESPONSE_ERROR_MESSAGE + responseErrorsMessage;
    }

    private HttpRequest constructRequestBodyAndEndpoint(HttpRequest request, List<DatedConversionRate> recordsList){
        String requestBody;

        if (recordsList != null) {
            //If record Id is null, then we're inserting new Records
            if (recordsList[0].Id == null) {
                request.setEndpoint(ENDPOINT_BASE_URL);

                requestBody = formRequestBodyForInsert(recordsList);
            } else {
                //Else if record Id is not null, then we're updating Records. Change endpoint to PATCH
                request.setEndpoint(ENDPOINT_BASE_URL + '?_HttpMethod=PATCH');

                requestBody = formRequestBodyForUpdate(recordsList);
            }

        }
        request.setBody(requestBody);
        return request;
    }

    private String formRequestBodyForInsert(List<DatedConversionRate> recordsList){
        String requestBody;
        List<RecordForRequestWrapper> recordsWrapper = new List<RecordForRequestWrapper>();

        for (DatedConversionRate rate : recordsList) {
            recordsWrapper.add(new RecordForRequestWrapper(rate.IsoCode, rate.ConversionRate, rate.StartDate));
        }

        requestBody = '{ "allOrNone" : true,' +
                '"records" : [';

        for (RecordForRequestWrapper record : recordsWrapper) {
            requestBody += '{"attributes" : {"type" : "DatedConversionRate"}, ';
            requestBody += JSON.serialize(record).removeStart('{') + ', ';
        }

        requestBody = requestBody.removeEnd(', ');
        requestBody += ']}';

        return requestBody;
    }

    private String formRequestBodyForUpdate(List<DatedConversionRate> recordsList){
        String requestBody;
        requestBody = '{ "allOrNone" : true,' +
                '"records" : [';

        //Provide only id and ConversionRate fields in Request Body
        for (DatedConversionRate rate : recordsList) {
            requestBody += '{"attributes" : {"type" : "DatedConversionRate"}, ';
            requestBody += '"Id" : "' + rate.Id + '", ';
            requestBody += '"ConversionRate" : ' + rate.ConversionRate + '}, ';
        }
        requestBody = requestBody.removeEnd(', ');
        requestBody += ']}';

        return requestBody;
    }

    public class RecordForRequestWrapper {
        public String IsoCode;
        public Decimal ConversionRate;
        public Date StartDate;
        public RecordForRequestWrapper(String IsoCode, Decimal ConversionRate, Date StartDate){
            this.IsoCode = IsoCode;
            this.ConversionRate = ConversionRate;
            this.StartDate = StartDate;
        }
    }

    public class DataTableWrapper {
        @AuraEnabled
        public List<DatedConversionRate> recordsList;
        @AuraEnabled
        public Map<String, String> fieldsList;
        @AuraEnabled
        public Map<String, String> fieldsTypes;
        @AuraEnabled
        public List<String> ISOCodes;
    }
}