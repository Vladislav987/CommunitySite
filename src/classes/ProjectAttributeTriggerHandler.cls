/**
 * Created by MaxymMirona on 10.08.2020.
 */

public without sharing class ProjectAttributeTriggerHandler extends SObjectDomain {

    public static User currentUser = Util.CURRENT_USER;
    public ProjectAttributeService projectAttributeServiceObject = new ProjectAttributeService();

    public override void onBeforeUpdate(Map<Id,SObject> existingRecords) {
        Boolean passedValidation = currentUser.Skip_validation_rules__c ? true : projectAttributeServiceObject.validateProjectAttribute((Map<Id, Project_attribute__c>)existingRecords, (List<Project_attribute__c>)this.records);

        if (passedValidation) {

        }
    }
}