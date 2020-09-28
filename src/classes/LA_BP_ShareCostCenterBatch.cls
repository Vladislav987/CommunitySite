global class LA_BP_ShareCostCenterBatch implements Database.Batchable<sObject> {

    private Map<Id, Id> responsibleUsersIds;
    private List<Id> costCenterIds;
    private Integer year;
    private String currentUserId;

    public LA_BP_ShareCostCenterBatch(List<Id> costCenterIds, Integer year,Map<Id, Id> responsibleUsersIds,String currentUserId) {
        this.costCenterIds = costCenterIds;
        this.year = year;
        this.responsibleUsersIds = responsibleUsersIds;
        this.currentUserId = currentUserId;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id FROM Business_Unit__c WHERE Id IN : costCenterIds');
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<SObject> results = scope;
        List<Id> resultIds = new List<Id>((new Map<Id,SObject>(results)).keySet());

        LA_BP_ActionService.shareAction(resultIds, year,responsibleUsersIds,currentUserId);

        List<Financial_Report_Item__c> financialReportItemsForInsert = LA_BP_ActionService.getFinancialReportItemsForInsert();
        List<Financial_Report_Item__c> financialReportItemsForUpdate = LA_BP_ActionService.getFinancialReportItemsForUpdate();
        List<Financial_Report_Item__c> financialReportItemsForDelete = LA_BP_ActionService.getFinancialReportItemsForDelete();

        if (financialReportItemsForInsert.size() > 0) {
            insert financialReportItemsForInsert;
        }
        if (financialReportItemsForUpdate.size() > 0) {
            upsert financialReportItemsForUpdate;
        }
        if (financialReportItemsForDelete.size() > 0) {
            delete financialReportItemsForDelete;
        }

    }

    global void finish(Database.BatchableContext BC) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[]{UserInfo.getUserEmail()};
        Id emailTemplateId = LA_BP_DataSelector.getIdOfEmailTemplate();
        mail.setToAddresses(toAddresses);
        mail.setTargetObjectId(currentUserId);
        mail.setTemplateId(emailTemplateId);
        mail.setSaveAsActivity(false);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }


}