/**
 * Created by MaxymMirona on 01.07.2020.
 */

public without sharing class SupportCaseServiceDAO extends CustomMetadataDAO {
    public enum ACTION_TYPE {SENDEMAIL}
    private static final Map<ACTION_TYPE, String> LOCATION_SOURCE_PICKLIST = new Map<ACTION_TYPE, String>{
            ACTION_TYPE.SENDEMAIL => 'Send Email'
    };

    public override List<SObject> fetchMetadataSettings() {
        return [
                SELECT Id, Is_Active__c,
                (SELECT Id, Action_Type__c, Email__c, Email_Template__c FROM Support_Case_Actions__r)
                FROM Support_Case_Service__mdt
                WHERE Identifier__c = :this.identifier
        ];
    }

    public override ICustomMetadataDAOWrapper getWrapperBySettings(SObject settings, List<SObject> targetRecords) {
        return new SupportCaseServiceWrapper(settings, targetRecords);
    }

    public class SupportCaseServiceWrapper implements ICustomMetadataDAOWrapper {
        private List<SObject> targetRecords;
        private Map<ACTION_TYPE, List<Support_Case_Action__mdt>> actionsByType;

        private String errorMessage;

        public SupportCaseServiceWrapper(String errorMessage) {
            this.errorMessage = errorMessage;
        }

        public SupportCaseServiceWrapper(SObject metadataSettings, List<SObject> targetRecords) {
            Support_Case_Service__mdt setting = (Support_Case_Service__mdt) metadataSettings;

            this.targetRecords = targetRecords;

            if (!setting.Support_Case_Actions__r.isEmpty() && setting.Is_Active__c) {
                List<Support_Case_Action__mdt> sendEmailActions = new List<Support_Case_Action__mdt>();
                actionsByType = new Map<SupportCaseServiceDAO.ACTION_TYPE, List<Support_Case_Action__mdt>>();

                try {
                    for (Support_Case_Action__mdt action : setting.Support_Case_Actions__r) {
                        if (action.Action_Type__c == LOCATION_SOURCE_PICKLIST.get(ACTION_TYPE.SENDEMAIL)) {
                            sendEmailActions.add(action);
                        }
                    }

                    if (!sendEmailActions.isEmpty()) {
                        this.actionsByType.put(ACTION_TYPE.SENDEMAIL, sendEmailActions);
                    }

                } catch (Exception e) {

                }
            }
        }

        public List<SObject> getRecords() {
            return this.targetRecords;
        }

        public void handleActions() {
            if (this.actionsByType != null) {
                for (ACTION_TYPE actionType : this.actionsByType.keySet()) {
                    this.handleAction(actionType);
                }
            }
        }

        public void handleSingleAction(ACTION_TYPE actionType) {
            this.handleAction(actionType);
        }

        public void handleAction(ACTION_TYPE actionType) {

            if (actionType == ACTION_TYPE.SENDEMAIL) {
                if (this.actionsByType != null && this.actionsByType.containsKey(actionType)) {
                    this.handleSendEmailAction(this.actionsByType.get(actionType));
                }
            }
        }

        private void handleSendEmailAction(List<Support_Case_Action__mdt> sendEmailActions) {
            Map<Id, List<User>> usersByTemplateIds = new Map<Id, List<User>>();
            Map<String, String> emailAddressesByTemplateName = new Map<String, String>();
            Map<String, User> usersByEmailAddresses = new Map<String, User>();

            for (Support_Case_Action__mdt action : sendEmailActions) {
                if (action.Email_template__c != null && action.Email__c != null) {
                    emailAddressesByTemplateName.put(action.Email_template__c, action.Email__c);
                }
            }

            for (User user : [SELECT Id, Email FROM User WHERE Email IN :emailAddressesByTemplateName.values()]) {
                usersByEmailAddresses.put(user.Email, user);
            }

            for (EmailTemplate template : [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :emailAddressesByTemplateName.keySet()]){
                if (usersByTemplateIds.containsKey(template.Id)) {
                    usersByTemplateIds.get(template.Id).add(usersByEmailAddresses.get(emailAddressesByTemplateName.get(template.DeveloperName)));
                } else {
                    usersByTemplateIds.put(template.Id, new List<User>{usersByEmailAddresses.get(emailAddressesByTemplateName.get(template.DeveloperName))});
                }
            }

            Messaging.sendEmail(this.constructEmail(usersByTemplateIds, this.targetRecords));
        }

        private List<Messaging.SingleEmailMessage> constructEmail(Map<Id, List<User>> emailAddressesByTemplateIds, List<SObject> targetRecords) {
            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

            for (SObject record : targetRecords) {
                for (Id templateId : emailAddressesByTemplateIds.keySet()) {
                    for (User user : emailAddressesByTemplateIds.get(templateId)) {
                        Messaging.SingleEmailMessage emailMessage = Messaging.renderStoredEmailTemplate(templateId, user.Id, record.Id);
                        emailMessage.saveAsActivity = false;

                        emailMessages.add(emailMessage);
                    }
                }
            }

            return emailMessages;
        }
    }

}