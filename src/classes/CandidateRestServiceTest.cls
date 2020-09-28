@IsTest
private class CandidateRestServiceTest {
    @IsTest
    static void createCandidateHttpPostTest() {
        Id currentUserId  = UserInfo.getUserId();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/CandidateRest/';
        String jsonInput = '{\n' +
                ' "name" :"Test ",\n' +
                ' "ownerId" : "' + currentUserId +'",\n' +
                ' "company" :"Test ",\n' +
                ' "phone" :"(777)7778899",\n' +
                ' "email" :"test@test.com ",\n' +
                ' "description" :"Test ",\n' +
                ' "source" :"Golang Developer",\n' +
                ' "url" :"https://www.linkedin.com",\n' +
                ' "workedPlace" :"Test ",\n' +
                ' "technologies" :"Apex ",\n' +
                ' "foto" :"123456789"\n' +
                '}';
        req.requestBody = Blob.valueof(jsonInput);
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        CandidateRestService.creteContractor();
        Test.stopTest();
    }
}