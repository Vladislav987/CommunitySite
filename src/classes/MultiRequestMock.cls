/**
 * Created by MaxymMirona on 27.12.2019.
 */

@IsTest
global class MultiRequestMock implements HttpCalloutMock{

    public Map<String, HttpCalloutMock> mocks;

    public MultiRequestMock(Map<String, HttpCalloutMock> mocks){
        this.mocks = mocks;
    }

    global HTTPResponse respond(HTTPRequest req){
        HttpCalloutMock mock = mocks.get(req.getEndpoint());

        return mock.respond(req);
    }

    public void addRequestMock(String url, HttpCalloutMock mock) {
        mocks.put(url, mock);
    }

}