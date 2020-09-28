public without sharing class ProjectTriggerHandler extends SObjectDomain{

    ProjectDescriptionService projectDescriptionService = new ProjectDescriptionService();

    ProjectService projectService = new ProjectService();

    public override void onBeforeInsert() {
        projectService.sortProjectByFieldParent((List<Project__c>)this.records);
        projectService.triggerChildAllocationsForValidation((List<Project__c>)this.records);
    }

    public override void onBeforeUpdate(Map<Id,SObject> existingRecords) {
        projectService.updateRelatedAllocations((Map<Id, Project__c>)existingRecords, (List<Project__c>)this.records);
        projectService.sortProjectOnAllocation((List<Project__c>)this.records, (Map<Id, Project__c>)existingRecords);
    }

    public override void onAfterUpdate(Map<Id,SObject> existingRecords) {
        projectService.triggerChildAllocationsForValidation((List<Project__c>)this.records);
        projectDescriptionService.sortProjectWithChangedDescriptionAndIntroduceToAllocation((List<Project__c>)Trigger.new, (Map<Id, Project__c>)Trigger.oldMap);
    }

    public override void onAfterUnDelete(){
        projectService.triggerChildAllocationsForValidation((List<Project__c>)this.records);
    }
}