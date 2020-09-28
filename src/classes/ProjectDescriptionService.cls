public with sharing class ProjectDescriptionService {

    /**
     * Sorts projects with changed field  Description and change in related Allocation field Project_description
     *
     * @param projects - Trigger.new, changed Projects
     * @param oldProjects - Trigger.oldMap, old Projects
     */
    public void sortProjectWithChangedDescriptionAndIntroduceToAllocation(List<Project__c> projects, Map<Id, Project__c> oldProjects){
        List<Project__c> projectsWithChangedDescription = new List<Project__c>();
        AllocationProjectDescriptionService allocationProjectDescriptionService = new AllocationProjectDescriptionService();

        for (Project__c project: projects){
            if (!isDescriptionChanged(project, oldProjects)) {
                projectsWithChangedDescription.add(project);
            }
        }

        allocationProjectDescriptionService.updateProjectDescriptionByProjects(new Map<Id, Project__c>(projectsWithChangedDescription));
    }

    private Boolean isDescriptionChanged(Project__c project, Map<Id, Project__c> oldProjects) {
        return (project.Project_description__c == oldProjects.get(project.Id).Project_description__c);
    }
}