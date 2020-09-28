public without sharing class DeliverySupportRequestService {

    public void sendEmailsForUsersByCriteria(List<Delivery_Support_Request__c> supportRequests) {
        Map<String, List<Delivery_Support_Request_mtd__mdt>> requestMtdByTypeAndPractice = new Map<String, List<Delivery_Support_Request_mtd__mdt>>();
        Set<String> userNames = new Set<String>();
        Map<String, User> userByUserName = new Map<String, User>();
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        List<Delivery_Support_Request_mtd__mdt> deliverySupportRequestMtds = [SELECT Primary__c, Type__c, Responsible_user__c, Opportunity_Practice__c FROM Delivery_Support_Request_mtd__mdt];


        requestMtdByTypeAndPractice = this.fillRequestMtdByTypeAndPracticeMap(deliverySupportRequestMtds);
        userNames = this.getUserNamesFromDeliveryRequests(deliverySupportRequestMtds);
        userByUserName = this.fillUsersMapByUsersNames(userNames);

        List<EmailTemplate> templates = [SELECT Id, Name, Body, Subject FROM EmailTemplate WHERE Name IN (:System.Label.PositiveTemplate,  :System.Label.NegativeTemplate)];
        Map<String, Id> templateIdsByName = new  Map<String, Id>();
        for (EmailTemplate template: templates){

            templateIdsByName.put(template.Name, template.Id);
        }

        List<User> adminId  = [SELECT Id FROM User WHERE Username =: System.Label.UserForErrorEmails];

        for (Delivery_Support_Request__c request : supportRequests) {
            String key = request.Type__c + request.Opportunity_Practice__c;
            List<Delivery_Support_Request_mtd__mdt> mtds = requestMtdByTypeAndPractice.get(key) == null ? new List<Delivery_Support_Request_mtd__mdt>(): requestMtdByTypeAndPractice.get(key);
            if (mtds.isEmpty()){

                key = request.Opportunity_Practice__c;
                mtds = requestMtdByTypeAndPractice.get(key) == null ? new List<Delivery_Support_Request_mtd__mdt>(): requestMtdByTypeAndPractice.get(key);
            }
            for (Delivery_Support_Request_mtd__mdt d : mtds) {

                Id userId = userByUserName.get(d.Responsible_user__c).Id;

                if (userId != null) {

                    Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templateIdsByName.get(System.Label.PositiveTemplate), userId, request.Id);
                    email.saveAsActivity = false;
                    messages.add(email);
                }else if(!adminId.isEmpty()){

                    Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templateIdsByName.get(System.Label.NegativeTemplate), adminId[0].Id, request.Id);
                    email.saveAsActivity = false;
                    messages.add(email);
                }
            }
            if ((mtds.isEmpty() || String.isBlank(request.Assigned_to__c))
                    && !adminId.isEmpty()) {

                Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templateIdsByName.get(System.Label.NegativeTemplate), adminId[0].Id, request.Id);
                email.saveAsActivity = false;
                messages.add(email);
            }
        }
        if (!Test.isRunningTest()) {

            Messaging.SendEmailResult [] results = Messaging.sendEmail(messages);
        }
    }


    public void assignUser(List<Delivery_Support_Request__c> supportRequests){
        Set<Id> opportunityIds = new Set<Id>();

        List<Delivery_Support_Request_mtd__mdt> deliverySupportRequestMtds = [SELECT Primary__c, Type__c, Responsible_user__c, Opportunity_Practice__c FROM Delivery_Support_Request_mtd__mdt];
        for (Delivery_Support_Request__c request: supportRequests){

            opportunityIds.add(request.Opportunity__c);
        }

        Map<Id, Opportunity> opportunitiesByIds = new Map<Id, Opportunity>([SELECT Id, Key_practice__c FROM Opportunity WHERE Id IN :opportunityIds]);
        Map<String, List<Delivery_Support_Request_mtd__mdt>> requestMtdByTypeAndPractice = new Map<String, List<Delivery_Support_Request_mtd__mdt>>();
        Set<String> userNames = new Set<String>();
        Map<String, User> userByUserName = new Map<String, User>();

        requestMtdByTypeAndPractice = this.fillRequestMtdByTypeAndPracticeMap(deliverySupportRequestMtds);
        userNames = this.getUserNamesFromDeliveryRequests(deliverySupportRequestMtds);
        userByUserName = this.fillUsersMapByUsersNames(userNames);

        for (Delivery_Support_Request__c request : supportRequests) {

            request.Practice_of_Opportunity__c = opportunitiesByIds.get(request.Opportunity__c).Key_practice__c;
            String key = request.Type__c + request.Practice_of_Opportunity__c;
            List<Delivery_Support_Request_mtd__mdt> mtds = requestMtdByTypeAndPractice.get(key) == null ? new List<Delivery_Support_Request_mtd__mdt>() : requestMtdByTypeAndPractice.get(key);
            if (mtds.isEmpty()|| mtds == null){

                key = request.Practice_of_Opportunity__c;
                mtds = requestMtdByTypeAndPractice.get(key) == null ? new List<Delivery_Support_Request_mtd__mdt>() : requestMtdByTypeAndPractice.get(key);
            }
            for (Delivery_Support_Request_mtd__mdt d : mtds) {

                User user = userByUserName.get(d.Responsible_user__c);
                if (d.Primary__c) {
                    request.Assigned_to__c = user.Id;
                }
            }
        }
    }
    private Map<String, List<Delivery_Support_Request_mtd__mdt>> fillRequestMtdByTypeAndPracticeMap(List<Delivery_Support_Request_mtd__mdt> deliverySupportRequestMtds){
        Map<String, List<Delivery_Support_Request_mtd__mdt>> requestMtdByTypeAndPractice = new Map<String, List<Delivery_Support_Request_mtd__mdt>>();

        for (Delivery_Support_Request_mtd__mdt requestMtd : deliverySupportRequestMtds) {
            if (String.isNotBlank(requestMtd.Opportunity_Practice__c)) {

                String typeAndPractice = String.isNotBlank(requestMtd.Type__c)? requestMtd.Type__c + requestMtd.Opportunity_Practice__c: requestMtd.Opportunity_Practice__c;

                if (requestMtdByTypeAndPractice.containsKey(typeAndPractice)) {

                    requestMtdByTypeAndPractice.get(typeAndPractice).add(requestMtd);
                } else {

                    requestMtdByTypeAndPractice.put(typeAndPractice, new List<Delivery_Support_Request_mtd__mdt>{requestMtd});
                }
            }
        }
        return requestMtdByTypeAndPractice;
    }
    private Set<String> getUserNamesFromDeliveryRequests(List<Delivery_Support_Request_mtd__mdt> deliverySupportRequestMtds){
        Set<String> userNames = new Set<String>();
        for (Delivery_Support_Request_mtd__mdt request: deliverySupportRequestMtds){

            userNames.add(request.Responsible_user__c);
        }
        return userNames;
    }
    private Map<String, User> fillUsersMapByUsersNames(Set<String> userNames){
        Map<String, User> userByUserName = new Map<String, User>();
        for (User user : [SELECT Id, Username FROM User WHERE Username IN :userNames]) {
            if (!userByUserName.containsKey(user.Username)) {

                userByUserName.put(user.Username, user);
            }
        }
        return userByUserName;
    }
}