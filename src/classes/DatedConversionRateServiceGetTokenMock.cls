/**
 * Created by MaxymMirona on 27.12.2019.
 */

@isTest
global class DatedConversionRateServiceGetTokenMock implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req){
    HttpResponse response = new HttpResponse();
    response.setStatusCode(200);
    response.setBody(JSON.serialize(new DatedConversionRateServiceResponseWrapper('test token')));

    return response;
    }

    public class DatedConversionRateServiceResponseWrapper{
        public String access_token;

        public DatedConversionRateServiceResponseWrapper(String access_token){
            this.access_token = access_token;
        }
    }
}