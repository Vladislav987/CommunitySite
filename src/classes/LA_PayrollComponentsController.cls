/*
* Created by Lambru Dmytro on 02.07.2020.
* */
public without sharing class LA_PayrollComponentsController {

    @AuraEnabled
    public static Payroll_Component_Configurations__mdt[] getCustomMetadata() {
        Payroll_Component_Configurations__mdt[] payrollComponentConfigurationsList = getByCurrentUserId();

        if (payrollComponentConfigurationsList.isEmpty()) {
            payrollComponentConfigurationsList = getByUserPublicGroups();
        }

        return payrollComponentConfigurationsList;
    }

    private static Payroll_Component_Configurations__mdt[] getByCurrentUserId() {

        return [
            SELECT
                Id,
                Additional_Available_Stations__c,
                Allow_recurrence__c,
                DeveloperName,
                Generate_Button_Title__c,
                Label,
                Language,
                MasterLabel,
                NamespacePrefix,
                Order__c,
                QualifiedApiName,
                RecordType__c,
                RecordType_recurrent__c,
                Title__c,
                Type__c,
                User_Id__c,
            (
                SELECT
                    DefaultValue__c,
                    DeveloperName,
                    Field_API_Name__c,
                    Id,
                    Is_Hidden__c,
                    Label,
                    Language,
                    MasterLabel,
                    NamespacePrefix,
                    Order__c,
                    Payroll_Component_Configurations__c,
                    QualifiedApiName,
                    Recurrent_Only__c,
                    Required__c,
                    Title__c
                FROM Payroll_Component_Configuration_Fields__r
            )
            FROM Payroll_Component_Configurations__mdt
            WHERE User_Id__c = :UserInfo.getUserId()
            ORDER BY Order__c
        ];
    }

    private static Payroll_Component_Configurations__mdt[] getByUserPublicGroups() {
        Set<String> publicGroupDevNameSet = getPublicGroupDevNamesForCurrentUser();

        return [
            SELECT
                Id,
                Additional_Available_Stations__c,
                Allow_recurrence__c,
                DeveloperName,
                Generate_Button_Title__c,
                Label,
                Language,
                MasterLabel,
                NamespacePrefix,
                Order__c,
                QualifiedApiName,
                RecordType__c,
                RecordType_recurrent__c,
                Title__c,
                Type__c,
                User_Id__c,
            (
                SELECT
                    DefaultValue__c,
                    DeveloperName,
                    Field_API_Name__c,
                    Id,
                    Is_Hidden__c,
                    Label,
                    Language,
                    MasterLabel,
                    NamespacePrefix,
                    Order__c,
                    Payroll_Component_Configurations__c,
                    QualifiedApiName,
                    Recurrent_Only__c,
                    Required__c,
                    Title__c
                FROM Payroll_Component_Configuration_Fields__r
            )
            FROM Payroll_Component_Configurations__mdt
            WHERE Public_group__c = :publicGroupDevNameSet
            ORDER BY Order__c
        ];
    }

    public static Set<String> getPublicGroupDevNamesForCurrentUser() {
        Set<String> groupDevNameSet = new Set<String>();
        Set<Id> userOrGroupIdSet = new Set<Id>{UserInfo.getUserId()};
        userOrGroupIdSet.addAll(getGroupIdsByUserRoleId(UserInfo.getUserRoleId()));

        GroupMember[] groupMemberList = [
            SELECT Group.DeveloperName
            FROM GroupMember
            WHERE UserOrGroupId = :userOrGroupIdSet
            LIMIT 1000
        ];

        for (GroupMember groupMember : groupMemberList) {
            groupDevNameSet.add(groupMember.Group.DeveloperName);
        }

        return groupDevNameSet;
    }

    public static Set<Id> getGroupIdsByUserRoleId(Id userRoleId) {
        Map<Id, Group> groupMap = new Map<Id, Group>([
            SELECT Id
            FROM Group
            WHERE RelatedId = :userRoleId
            LIMIT 1000
        ]);

        return groupMap.keySet();
    }

}