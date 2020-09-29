@IsTest
private class LW_AllocationGroupingProjectContTest {
    private static final Id PROJECT_RECORD_TYPE_GROUPING_ID =
            Schema.Project__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Grouping_Project').getRecordTypeId();
    private static final Id PROJECT_RECORD_TYPE_COMMERCIAL_ID =
            Schema.Project__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Commercial').getRecordTypeId();
    private static final Date TEST_DATE_START = Date.newInstance(2020, 1, 1);
    private static final Date TEST_DATE_END = Date.newInstance(2020, 12, 1);

    @TestSetup
    static void setup() {
        List<Project__c> projects = new List<Project__c>();
        Project__c project = new Project__c();
        project.Name = 'project name';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.RecordTypeId = PROJECT_RECORD_TYPE_GROUPING_ID;
        project.Start_date__c = TEST_DATE_START;
        project.End_date__c = TEST_DATE_END;
        project.Department__c = 'SFDC Department';
        insert project;

        Project__c childProject = project.clone(false,false,false, false);
        childProject.Parent_Project__c = project.Id;
        childProject.RecordTypeId = PROJECT_RECORD_TYPE_COMMERCIAL_ID;
        projects.add(childProject);
        insert childProject;

        Contractor__c contractor1 = new Contractor__c();
        contractor1.Name = 'Grouping test';
        contractor1.Resource_Type__c = 'SFDC Developer';
        contractor1.Resource_Level__c = 'Trainee';
        contractor1.Department__c = 'SFDC Department';

        insert contractor1;

        List<Allocation__c> allocations = new List<Allocation__c>();
        Allocation__c allocation1 = new Allocation__c();
        allocation1.Project__c = childProject.Id;
        allocation1.Contractor__c = contractor1.Id;
        allocation1.Allocation__c = 99;
        allocation1.Allocation_Type__c = 'Billable';
        allocation1.Start_date__c = System.today().addDays(-5);
        allocation1.Status__c = 'Active';
        allocation1.End_date__c = System.today().addDays(5);
        allocation1.Resource_Type__c = 'SEO';
        allocation1.Expected_Rate__c = 12;
        allocation1.Station__c = 'CTDev Kiev Office';

        Allocation__c allocation2 = allocation1.clone(false,false, false, false);
        allocations.add(allocation1);
        allocations.add(allocation2);

        insert allocations;
    }

    @IsTest
    private static void getRelatedListInitDataTestCorrectFlow() {
        List<Project__c> project = [
                SELECT Id
                FROM Project__c
                WHERE RecordTypeId = :PROJECT_RECORD_TYPE_GROUPING_ID
        ];
        if (!project.isEmpty()) {

            Test.startTest();

            LW_AllocationGroupingProjectController.GroupingDataWrapper relatedListData = LW_AllocationGroupingProjectController.getData(project[0].Id);

            Test.stopTest();
            system.assertEquals(1, relatedListData.childProjects.size());
            system.assertEquals(2, relatedListData.childProjects[0].Allocations__r.size());
        }
    }

    @IsTest
    private static void getRelatedListInitDataTestIncorrectFlowEmptyId() {
        String exceptionTypeName;
        Test.startTest();

        try {
            LW_AllocationGroupingProjectController.GroupingDataWrapper relatedListData = LW_AllocationGroupingProjectController.getData(null);
        } catch (Exception e) {
            exceptionTypeName = e.getTypeName();
        }

        Test.stopTest();
        System.assertEquals('System.AuraHandledException', exceptionTypeName);
    }
    @IsTest
    private static void getRelatedListInitDataTestFlowNotGroupingProject() {
        List<Project__c> project = [
                SELECT Id
                FROM Project__c
                WHERE RecordTypeId = :PROJECT_RECORD_TYPE_COMMERCIAL_ID
        ];
        if (!project.isEmpty()) {

            Test.startTest();

            LW_AllocationGroupingProjectController.GroupingDataWrapper relatedListData = LW_AllocationGroupingProjectController.getData(project[0].Id);

            Test.stopTest();
            system.assertEquals(0, relatedListData.childProjects.size());
        }
    }


}