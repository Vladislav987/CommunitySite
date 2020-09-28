/**
 * Created by ArtemShevchenko on 15.11.2019.
 */

public with sharing class SharingButtonController {
    @AuraEnabled
    public static List<String> getEntitiesNamesForSharing(String entityType) {
        List<String> entitiesNames = new List<String>();
        switch on entityType {
            when 'Users' {
                entitiesNames = getUsersNames();
                return entitiesNames;
            } when 'Groups' {
                entitiesNames = getGroupsNames();
                return entitiesNames;
            } when 'Roles' {
                entitiesNames = getRolesNames();
                return entitiesNames;
            } when else {
                return entitiesNames;
            }
        }
    }
    @AuraEnabled
    public static void shareWithEntities(List<String> entitiesNames, String entityType, Id recordId, String accessLevel) {
        switch on entityType {
            when 'Users' {
                shareWithUsers(entitiesNames, recordId, accessLevel);
            } when 'Groups' {
                shareWithGroups(entitiesNames, recordId, accessLevel);
            } when 'Roles' {
                shareWithRoles(entitiesNames, recordId, accessLevel);
            } when else {

            }
        }
    }
    private static void shareWithUsers(List<String> entitiesNames, Id recordId, String accessLevel) {
        String objectType = recordId.getSobjectType().getDescribe().getName();
        objectType = objectType.replaceAll('__c', '__Share');
        Schema.SObjectType shareType = Schema.getGlobalDescribe().get(objectType);
        List<SObject> recordsShares = new List<SObject>();
        for (User user : [SELECT Id FROM User WHERE Name IN :entitiesNames AND License__c != 'Chatter Free']) {
            SObject recordShare = shareType.newSObject();
            recordShare.put('ParentId', recordId);
            recordShare.put('UserOrGroupId', user.Id);
            recordShare.put('AccessLevel', accessLevel);
            recordsShares.add(recordShare);
        }
        insert recordsShares;
    }
    private static void shareWithGroups(List<String> entitiesNames, Id recordId, String accessLevel) {
        String objectType = recordId.getSobjectType().getDescribe().getName();
        objectType = objectType.replaceAll('__c', '__Share');
        Schema.SObjectType shareType = Schema.getGlobalDescribe().get(objectType);
        List<SObject> recordsShares = new List<SObject>();
        for (Group grp : [SELECT Id FROM Group WHERE Name IN :entitiesNames]) {
            SObject recordShare = shareType.newSObject();
            recordShare.put('ParentId', recordId);
            recordShare.put('UserOrGroupId', grp.Id);
            recordShare.put('AccessLevel', accessLevel);
            recordsShares.add(recordShare);
        }
        insert recordsShares;
    }
    private static void shareWithRoles(List<String> entitiesNames, Id recordId, String accessLevel) {
        String objectType = recordId.getSobjectType().getDescribe().getName();
        objectType = objectType.replaceAll('__c', '__Share');
        Schema.SObjectType shareType = Schema.getGlobalDescribe().get(objectType);

        List<UserRole> roles = [SELECT Id FROM UserRole WHERE Name IN :entitiesNames];
        List<SObject> recordsShares = new List<SObject>();

        for (User user : [SELECT Id, Name FROM User WHERE UserRoleId IN :roles AND IsActive = TRUE AND License__c != 'Chatter Free' AND Id != :UserInfo.getUserId()]) {
            SObject recordShare = shareType.newSObject();
            recordShare.put('ParentId', recordId);
            recordShare.put('UserOrGroupId', user.Id);
            recordShare.put('AccessLevel', accessLevel);
            recordsShares.add(recordShare);
        }
        insert recordsShares;
    }
    private static List<String> getUsersNames() {
        List<String> usersNames = new List<String>();
        List<User> users = [SELECT Id, Name FROM User WHERE UserType != 'CloudIntegrationUser' AND UserType != 'AutomatedProcess'AND IsActive = TRUE AND Id != :UserInfo.getUserId() AND License__c != 'Chatter Free' ORDER BY Name];
        for (User user : users) {
            usersNames.add(user.Name);
        }
        return usersNames;
    }
    private static List<String> getGroupsNames() {
        List<String> groupsNames = new List<String>();
        List<Group> groups = [SELECT Id, Name FROM Group WHERE Type = 'Regular'];
        for (Group grp : groups) {
            groupsNames.add(grp.Name);
        }
        return groupsNames;
    }
    private static List<String> getRolesNames() {
        List<String> rolesNames = new List<String>();
        List<UserRole> roles = [SELECT Id, Name FROM UserRole];
        for (UserRole role : roles) {
            rolesNames.add(role.Name);
        }
        return rolesNames;
    }
}