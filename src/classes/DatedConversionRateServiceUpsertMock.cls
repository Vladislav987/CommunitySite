/**
 * Created by MaxymMirona on 27.12.2019.
 */

@IsTest
global class DatedConversionRateServiceUpsertMock implements HttpCalloutMock{

    global HTTPResponse respond(HTTPRequest req){
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(JSON.serialize(
                new List<DatedConversionRateServiceWrapper>{
                    new DatedConversionRateServiceWrapper(
                        true,
                         new List<DatedConversionRateServiceWrapper.Errors>{
                                 new DatedConversionRateServiceWrapper.Errors(
                                        '',
                                        '',
                                        new List<DatedConversionRateServiceWrapper.Fields>(

                                        )
                                 )
                         },
                        null
                    )
                }
        ));

        return response;
    }

}