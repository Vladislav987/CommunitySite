public without sharing class AllocationProjectDescriptionService {
    static  AllocationSelector allocationSelector = new AllocationSelector();

    /**
     * Insert related Project description in Allocation
     *
     * @param allocations - Trigger.new Allocation to insert
     */

    public void setProjectDescription(List<Allocation__c> allocations){
        List<Allocation__c> allocationsWithProject = allocationSelector.getAllocationsWithProjectDescription(allocations);

        for (Allocation__c allocation: allocationsWithProject){
            allocation.Project_description__c = allocation.Project__r.Project_description__c;
        }
        update(allocationsWithProject);
    }

    /**
     * Update related Project description in Allocation
     *
     * @param projects - List<Project__c> with changed Description
     */
    public void updateProjectDescriptionByProjects(Map<Id, Project__c> projectsByIds){
        List<Allocation__c> allocationsWithProject = allocationSelector.getAllocationsWithProjectDescriptionByProjects(projectsByIds.values());
        Set<String> overrunAllocationsWithoutOverrunType = new Set<String>();

        for (Allocation__c allocation:  allocationsWithProject){
            if (allocation.Allocation_Type__c == 'Overrun' && String.isBlank(allocation.Overrun_Type__c)) {
                allocationsWithProject = new List<Allocation__c>();
                overrunAllocationsWithoutOverrunType.add(allocation.Name);
            }
            allocation.Project_description__c = projectsByIds.get(allocation.Project__c).Project_description__c;
        }
        if (!overrunAllocationsWithoutOverrunType.isEmpty()) {
            
            Trigger.new[0].addError('You can not update Project because you have related Allocation ' + overrunAllocationsWithoutOverrunType + ' with type Overrun but without chosen Overrun Type!');
        }


        if(!allocationsWithProject.isEmpty()){
            update(allocationsWithProject);
        }
    }

}