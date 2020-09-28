/**
 * Created by Ponomarov Vladyslav on 10.06.2019.
 */

@IsTest
private class AllocationProjectDescriptionServiceTest {
    private static final Date TEST_DATE_START = Date.newInstance(2020, 1, 1);
    private static final Date TEST_DATE_END = Date.newInstance(2021, 1, 1);

    @TestSetup
    private static void setup() {
        Project__c project = new Project__c();
        project.Name = 'project name';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.Start_date__c = TEST_DATE_START;
        project.End_date__c = TEST_DATE_END;
        project.Project_description__c = 'test description';

        insert project;

        Project__c projectWithoutDescriptions = new Project__c();
        projectWithoutDescriptions.Name = 'project test name';
        projectWithoutDescriptions.Project_type__c = 'Outsource';
        projectWithoutDescriptions.Contract_type__c = 'Fixed cost';
        projectWithoutDescriptions.Start_date__c = TEST_DATE_START;
        projectWithoutDescriptions.End_date__c = TEST_DATE_END;

        insert projectWithoutDescriptions;


        List<Allocation__c> allocations = new List<Allocation__c>();
        Allocation__c allocationWithDescription = new Allocation__c();
        allocationWithDescription.Project__c = project.Id;
        allocationWithDescription.Allocation__c = 100;
        allocationWithDescription.Allocation_Type__c = 'Billable';
        allocationWithDescription.Start_date__c = TEST_DATE_START;
        allocationWithDescription.End_date__c = TEST_DATE_END;

        Allocation__c allocationWithoutDescription = new Allocation__c();
        allocationWithoutDescription.Project__c = projectWithoutDescriptions.Id;
        allocationWithoutDescription.Allocation__c = 100;
        allocationWithoutDescription.Allocation_Type__c = 'Billable';
        allocationWithoutDescription.Start_date__c = TEST_DATE_START;
        allocationWithoutDescription.End_date__c = TEST_DATE_END;

        allocations.add(allocationWithoutDescription);
        allocations.add(allocationWithDescription);

        insert allocations;


    }

    @IsTest
    static void updateProjectDescription() {
        List<Project__c> projects = [
                SELECT Id,
                        Project_description__c
                FROM Project__c

        ];
        for (Project__c elem: projects) {
            elem.Project_description__c = 'Changed description';
        }
        update projects;

        List<Allocation__c> allocations = [
                SELECT Id,
                        Project_description__c
                FROM Allocation__c
                WHERE Project__c = :projects
                LIMIT 1
        ];
        for (Allocation__c elem: allocations){
            System.assertEquals(elem.Project_description__c, projects.get(0).Project_description__c);

        }
    }
}