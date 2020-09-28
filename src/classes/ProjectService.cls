public without sharing class ProjectService {
    AllocationSelector allocationSelectorObject = new AllocationSelector();
    ProjectSelector projectSelectorObject = new ProjectSelector();
    AllocationService allocationServiceObject = new AllocationService();
    public static final Id PARENT_PROJECT_RECORD_TYPE_ID = Schema.Project__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId();

    public void sortProjectByFieldParent(List<Project__c> projects){
        Set<Id> projectsIds = new Set<Id>();

        for (Project__c project: projects){
            if (String.isNotBlank(project.Parent_Project__c) && project.Id != null) {
                projectsIds.add(project.Id);
            }
        }

        if (!projectsIds.isEmpty()) {

            //checkAllocationOnChildReports(projectsIds);
        }
    }

    public void updateRelatedAllocations(Map<Id, Project__c> oldProjectsMap, List<Project__c> newProjects){
        List<Allocation__c> allocationsToUpdate = new List<Allocation__c>();
        Map<Id, Project__c> projectsWithRelatedAllocations = new Map<Id, Project__c>([SELECT Department__c, Company_Group__c, (SELECT DepartmentP__c, Company_Group__c FROM Allocations__r) FROM Project__c WHERE Id IN :newProjects]);

        for (Project__c newProject : newProjects) {
            Project__c oldProject = oldProjectsMap.get(newProject.Id);
            Boolean areAllocationsUpdated = false;
            List<Allocation__c> relatedAllocations = projectsWithRelatedAllocations.get(newProject.Id).Allocations__r;

            if (oldProject.Department__c != newProject.Department__c){
                for (Allocation__c relatedAllocation : relatedAllocations){
                    relatedAllocation.DepartmentP__c = newProject.Department__c;
                }

                areAllocationsUpdated = true;
            }

            if (oldProject.Company_Group__c != newProject.Company_Group__c){
                for (Allocation__c relatedAllocation : relatedAllocations){
                    relatedAllocation.Company_Group__c = newProject.Company_Group__c;
                }

                areAllocationsUpdated = true;
            }

            if (areAllocationsUpdated){
                allocationsToUpdate.addAll(relatedAllocations);
            }
        }

        update allocationsToUpdate;
    }

    public void checkAllocationOnChildReports(Set<Id> projects){
        List<Allocation__c> allocations = allocationSelectorObject.getAllocationsByProjectIds(projects);
        if (!allocations.isEmpty()) {
            Trigger.new[0].addError('You can not add Project with Allocation to Parent Project');
        }
    }

    public void triggerChildAllocationsForValidation(List<Project__c> projects){
        Map<Id, Allocation__c> allocationsToTriggerMap = new Map<Id, Allocation__c>();
        List<Project__c> childProjects = new List<Project__c>();

        for (Project__c project : projectSelectorObject.getProjectWithRelatedAllocations(projects)){

            if (!project.Allocations__r.isEmpty() &&
                    (
                            project.RecordTypeId == PARENT_PROJECT_RECORD_TYPE_ID ||
                            project.Parent_Project__r.RecordTypeId == PARENT_PROJECT_RECORD_TYPE_ID
                    )
            ){
                allocationsToTriggerMap.putAll(project.Allocations__r);
            }

            if (!project.Projects__r.isEmpty() && project.RecordTypeId == PARENT_PROJECT_RECORD_TYPE_ID){
                childProjects.addAll(project.Projects__r);
            }
        }

        if (!childProjects.isEmpty()){
            for (Project__c project : projectSelectorObject.getProjectWithRelatedAllocations(childProjects)){
                if (!project.Allocations__r.isEmpty()){
                    allocationsToTriggerMap.putAll(project.Allocations__r);
                }
            }
        }

        String validationResult = allocationServiceObject.validateForSingleAllocationOfSomeTypeForParentProject(allocationsToTriggerMap.values(), true);

        if (validationResult != 'Success') {
            projects[0].addError(validationResult);
        }
    }

    public void sortProjectOnAllocation(List<Project__c> projects, Map<Id, Project__c> oldProjectsByIds){
        Set<Id> projectIds = new Set<Id>();
        for (Project__c  project: projects){
            if (project.Parent_Project__c != oldProjectsByIds.get(project.Id).Parent_Project__c && project.Parent_Project__c != null) {

                projectIds.add(project.Id);
            }
        }
        if (!projectIds.isEmpty()) {

            //checkAllocationOnChildReports(projectIds);
        }
    }
}