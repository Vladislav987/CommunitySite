public with sharing class RedmineRequestService {

    private static final String BASE_ENDPOINT = 'callout:Redmine_REST_API';
    private static final String TIME_ENTRIES = 'time_entries';
    private static final String JSN = 'json';
    private static final String REQUEST_GET_METHOD = 'GET';
    private static final String PARAM_LIMIT = 'limit';
    private static final String PARAM_OFFSET = 'offset';
    private static final String PARAM_SPENT_ON = 'spent_on';
    private static final Integer MAX_CALLOUT_NUMBER = 100;
    private static final Integer RESPONSE_STATUS_CODE_OK = 200;
    private static final Integer RESPONSE_FAIL_LIMIT = 10;

    private Http http;
    private Integer lim;
    private Integer failCounter;


    public RedmineRequestService() {
        http = new Http();
        lim = (Integer) redmine_rest_params__c.getOrgDefaults().result_chunk_size__c;
        failCounter = 0;
    }

    public void fetchTimeEntriesForPeriod(List<TimeEntryWrapper.TimeEntry> fetchedTimeEntries, Map<String, String> params) {
        if (fetchedTimeEntries == null) {
            fetchedTimeEntries = new List<TimeEntryWrapper.TimeEntry>();
        }
        Integer offset = fetchedTimeEntries.size();
        Integer entriesTotalCount;
        String totalCountString = params.get('entriesTotalCount');
        if (totalCountString != null) {
            entriesTotalCount = Integer.valueOf(totalCountString);
        }

        for (Integer i = 0; i < MAX_CALLOUT_NUMBER; i++) {
            if (this.isFirstRequest(entriesTotalCount)
                    || this.needsAdditionalFetch(fetchedTimeEntries.size(), entriesTotalCount)) {

                RedmineRequest request = new RedmineRequest(http, REQUEST_GET_METHOD);
                HttpResponse response = request
                        .setResource(TIME_ENTRIES)
                        .setFormat(JSN)
                        .setParam(PARAM_LIMIT, String.valueOf(this.lim))
                        .setParam(PARAM_OFFSET, String.valueOf(offset))
                        .setParam(PARAM_SPENT_ON, this.formatSpentOnParam(params.get('fromDate'), params.get('toDate')))
                        .execute();

                if (response.getStatusCode() == RESPONSE_STATUS_CODE_OK) {
                    TimeEntryWrapper wrapper = (TimeEntryWrapper) JSON.deserialize(response.getBody(), TimeEntryWrapper.class);
                    fetchedTimeEntries.addAll(wrapper.getTimeEntries());
                    entriesTotalCount = wrapper.getTotalCount();
                    offset += lim;
                } else {
                    System.debug('Response fail with status code: ' + response.getStatusCode());
                    failCounter++;
                    if (RESPONSE_FAIL_LIMIT == failCounter) {
                        throw new RedmineServiceException('Reached limit of fail request (' + RESPONSE_FAIL_LIMIT + ')');
                    }
                }

            } else {
                break;
            }
        }

        if (this.needsAdditionalFetch(fetchedTimeEntries.size(), entriesTotalCount)) {
            params.put('entriesTotalCount', String.valueOf(entriesTotalCount));
            Id jobId = System.enqueueJob(new MonthlyReportUpdateQueueable(fetchedTimeEntries, params));
        } else {
            MonthlyReportUpdateBatch batch = new MonthlyReportUpdateBatch(fetchedTimeEntries, params.get('reportPeriod'));
            Id batchId = Database.executeBatch(batch, 200);
        }
    }

    private String formatSpentOnParam(String fromDate, String toDate) {
        return '><' + fromDate + '|' + toDate;
    }

    private Boolean isFirstRequest(Integer entriesTotalCount) {
        return entriesTotalCount == null;
    }

    private Boolean needsAdditionalFetch(Integer fetchedEntriesCount, Integer entriesTotalCount) {
        return fetchedEntriesCount < entriesTotalCount;
    }


    private class RedmineRequest {

        private Http http;
        private String method;
        private String url;
        private String resource;
        private String format;
        private Map<String, String> fetchParams;


        public RedmineRequest() {
            this.url = BASE_ENDPOINT;
            this.fetchParams = new Map<String, String>();
        }

        public RedmineRequest(String method) {
            this();
            this.method = method;
        }

        public RedmineRequest(Http http, String method) {
            this(method);
            this.http = http;
        }

        public RedmineRequest setResource(String resource) {
            this.resource = '/' + resource;

            return this;
        }

        public RedmineRequest setFormat(String format) {
            this.format = '.' + format;

            return this;
        }

        public RedmineRequest setParam(String key, String value) {
            this.fetchParams.put(key, value);

            return this;
        }

        public HttpResponse execute() {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod(this.method);
            request.setEndpoint(this.url + this.resource + this.format + this.stringifyParams());

            return http.send(request);
        }

        private String stringifyParams() {
            String paramsString;
            for (String key : fetchParams.keySet()) {
                if (String.isEmpty(paramsString)) {
                    paramsString = '?';
                } else {
                    paramsString += '&';
                }
                paramsString += key + '=' + EncodingUtil.urlEncode(fetchParams.get(key), 'UTF-8');
            }

            return paramsString;
        }

    }


    private class RedmineServiceException extends Exception {}

}