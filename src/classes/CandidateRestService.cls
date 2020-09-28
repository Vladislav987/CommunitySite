@RestResource(urlMapping='/CandidateRest/*')
global with sharing class CandidateRestService {
    private static final Id CONTRACTOR_CANDIDATE_RT =
            Schema.Contractor__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Candidate').getRecordTypeId();

    @HttpPost
    global static String creteContractor() {
        String jsonStr = RestContext.request.requestBody.toString();
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonStr);
        String url = (String) data.get('url');
        if (url.endsWith('/')) {
            url = url.removeEnd('/');
        }
        String email = (String) data.get('email');

        List<Contractor__c> contractor = [SELECT Id
                                          FROM Contractor__c
                                          WHERE Social_Links__c = :url OR Email_Address__c = :email
        ];

        if (!data.containsKey('name') && !data.containsKey('company') && !data.containsKey('url')) {

            return 'Bad request';
        }

        Boolean isOverwrite = (Boolean) data.get('isOverwrite');

        if (!contractor.isEmpty() && isOverwrite == false) {

            return 'Sorry, we have this profile!';
        } else if (!contractor.isEmpty() && isOverwrite == true) {

            Contractor__c candidate = contractor[0];
            try {
                createCandidate(candidate, data);
                return 'Successful, the candidate has been updated!';
            }catch (Exception e){
                return JSON.serialize(e.getMessage());
            }
        }

        Contractor__c candidate = new Contractor__c();
        try {
            createCandidate(candidate, data);
            return 'Successful, the candidate has been inserted!';
        }catch (Exception e){
            return JSON.serialize(e.getMessage());
        }
    }

    private static void createCandidate(Contractor__c contractor, Map<String, Object> data){
        String url = (String) data.get('url');
        url = url.removeEnd('/');
        contractor.Name = (String) data.get('name');
        contractor.Recruitment_Source__c = 'LinkedIn';
        contractor.OwnerId = (Id) data.get('ownerId');
        contractor.Current_Company__c = (String) data.get('company');
        contractor.Mobile_Number__c = (String) data.get('phone');
        contractor.Email_Address__c = (String) data.get('email');
        contractor.Comments__c = (String) data.get('description');
        contractor.Resource_Type__c = (String) data.get('source');
        contractor.Social_Links__c = url;
        contractor.Employment_History__c = (String) data.get('workedPlace');
        contractor.Technologies__c = (String) data.get('technologies');
        contractor.RecordTypeId = CONTRACTOR_CANDIDATE_RT;
        String imageInBase64 = (String) data.get('foto');
        if (String.isNotBlank(imageInBase64)) {

            String image = imageInBase64.replaceAll('\"', '');
            Blob blobImage = EncodingUtil.base64Decode(image.replace('data:image/jpeg;base64,', ''));

            List<Folder> folders = [SELECT Id FROM Folder WHERE DeveloperName = :Label.Candidate_Image];
            if (!folders.isEmpty()) {
                String imageName = contractor.Name.replaceAll(' ', '_');

                Document doc = new Document();
                doc.Body = blobImage;
                doc.FolderId = folders[0].Id;
                doc.Name = imageName;
                doc.IsPublic = true;
                insert doc;

                contractor.Image_of_contractor__c = '<img src=' + System.URL.getOrgDomainUrl().toExternalForm() + '/servlet/servlet.FileDownload?file=' + doc.Id + '></img>';
            }
        }
        upsert contractor;
    }
}