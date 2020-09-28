public with sharing class UserService {

    @Future
    public static void createUsersMonthlyReportEditingRule(Set<Id> usersIds){
        List<Monthly_Report_Editing_Rule__c> rules = new List<Monthly_Report_Editing_Rule__c>();

        for (Id userId: usersIds){
            Monthly_Report_Editing_Rule__c rule = new Monthly_Report_Editing_Rule__c();
            rule.User__c = userId;
            rule.Allow_Late_Report_Editing__c = false;
            rules.add(rule);

        }

        insert rules;
    }
}