/**
 * Created by Yauheniy Malakhouskiy on 17-Apr-20.
 */

public with sharing class UserTriggerHandler extends SObjectDomain {

    public override void onAfterInsert() {
        UserService.createUsersMonthlyReportEditingRule(new Map<Id, User>((List<User>)this.records).keySet());
    }
}