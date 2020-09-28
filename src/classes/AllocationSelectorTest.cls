/**
 * Created by Mychailo Hamdzii on 24.04.2019.
 */
@IsTest
private with sharing class AllocationSelectorTest {
    private static final Date TEST_DATE_START = Date.newInstance(1900, 1, 1);
    private static final Date TEST_DATE_END = Date.today();
    private static final Id ALLOCATION_RECORD_TYPE_PROJECT_ID =
        Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Project').getRecordTypeId();
    private static final Id ALLOCATION_RECORD_TYPE_BOOKING_ID =
        Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Booking').getRecordTypeId();
    private static final Integer ZERO_RECORDS_NUMBER = 0;
    private static final String ALLOCATIONS_RELATED_LIST_FIELDSET = 'RelatedListFieldsForProject';
    private static final List<User> systemAdministratorUsers = [SELECT Id FROM User WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'System Administrator') AND IsActive = true];


    @TestSetup
    private static void setup() {
        Project__c project = new Project__c();
        project.Name = 'project name';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.Start_date__c = TEST_DATE_START;
        project.End_date__c = TEST_DATE_END;

        insert project;

        Contractor__c contractor1 = new Contractor__c();
        contractor1.Name = 'zdarova';
        contractor1.Resource_Type__c = 'SFDC Developer';
        contractor1.Resource_Level__c = 'Trainee';
        contractor1.Salary__c = 500;

        insert contractor1;

        Contractor__c contractor2 = new Contractor__c();
        contractor2.Name = 'zdarova2';
        contractor2.Resource_Type__c = 'SFDC Developer';
        contractor2.Resource_Level__c = 'Trainee';
        contractor2.Salary__c = 500;

        insert contractor2;

        List<Allocation__c> allocations = new List<Allocation__c>();
        Allocation__c allocationRecordTypeProject = new Allocation__c();
        allocationRecordTypeProject.Project__c = project.Id;
        allocationRecordTypeProject.Contractor__c = contractor1.Id;
        allocationRecordTypeProject.Status__c = 'Active';
        allocationRecordTypeProject.Allocation__c = 100;
        allocationRecordTypeProject.Allocation_Type__c = 'Billable';
        allocationRecordTypeProject.Start_date__c = TEST_DATE_START;
        allocationRecordTypeProject.End_date__c = TEST_DATE_END;
        allocationRecordTypeProject.RecordTypeId = ALLOCATION_RECORD_TYPE_PROJECT_ID;

        Allocation__c allocationRecordTypeNotProject = new Allocation__c();
        allocationRecordTypeNotProject.Project__c = project.Id;
        allocationRecordTypeNotProject.Contractor__c = contractor2.Id;
        allocationRecordTypeProject.Status__c = 'Active';
        allocationRecordTypeNotProject.Allocation__c = 100;
        allocationRecordTypeNotProject.Allocation_Type__c = 'Billable';
        allocationRecordTypeNotProject.Start_date__c = TEST_DATE_START;
        allocationRecordTypeNotProject.End_date__c = TEST_DATE_END;
        allocationRecordTypeNotProject.RecordTypeId = ALLOCATION_RECORD_TYPE_BOOKING_ID;

        allocations.add(allocationRecordTypeProject);
        allocations.add(allocationRecordTypeNotProject);

        insert allocations;
    }

    static AllocationSelector allocationSelector = new AllocationSelector();

    @IsTest
    private static void getAllocationByRecordTypeTestCorrectFlow() {
        Project__c project = [
            SELECT Id
            FROM Project__c
            LIMIT 1
        ];
        Integer numOfAllocationRecordTypeProject = [
            SELECT COUNT()
            FROM Allocation__c
            WHERE Project__c = :project.Id
                AND RecordTypeId = :ALLOCATION_RECORD_TYPE_PROJECT_ID
        ];
        Test.startTest();

        List<Allocation__c> allocations =
            allocationSelector.getAllocationByRecordTypeId(project.Id, ALLOCATION_RECORD_TYPE_PROJECT_ID);

        Test.stopTest();
        System.assert(!allocations.isEmpty());
        System.assertEquals(numOfAllocationRecordTypeProject, allocations.size());
        System.assertEquals(ALLOCATION_RECORD_TYPE_PROJECT_ID, allocations[0].RecordTypeId);
    }

    @IsTest
    private static void getAllocationByRecordTypeTestIncorrectFlow() {
        Project__c project = [
            SELECT Id
            FROM Project__c
            LIMIT 1
        ];
        Integer numOfAllocationRecordTypeProject = [
            SELECT COUNT()
            FROM Allocation__c
            WHERE Project__c = :project.Id
            AND RecordTypeId = :ALLOCATION_RECORD_TYPE_PROJECT_ID
        ];

        delete project;
        Test.startTest();

        List<Allocation__c> allocations =
            allocationSelector.getAllocationByRecordTypeId(project.Id, ALLOCATION_RECORD_TYPE_PROJECT_ID);

        Test.stopTest();
        System.assert(allocations.isEmpty());
        System.assert(numOfAllocationRecordTypeProject > ZERO_RECORDS_NUMBER);
    }

    @IsTest
    private static void getSingleAllocationCorrectFlow() {
        Allocation__c allocation = [
            SELECT Id
            FROM Allocation__c
            LIMIT 1
        ];

        Test.startTest();

        List<Allocation__c> allocations = allocationSelector.getSingleAllocation(allocation.Id);

        Test.stopTest();
        System.assert(!allocations.isEmpty());
        System.assertEquals(allocation.Id, allocations[0].Id);
    }

    @IsTest
    private static void getSingleAllocationIncorrectFlow() {
        if (!systemAdministratorUsers.isEmpty()) {
            System.runAs(systemAdministratorUsers[0]) {
                Allocation__c allocation = [
                        SELECT
                                Id
                        FROM Allocation__c
                        LIMIT 1
                ];

                delete allocation;
                Test.startTest();

                List<Allocation__c> allocations = allocationSelector.getSingleAllocation(allocation.Id);

                Test.stopTest();
                System.assert(allocations.isEmpty());
            }
        }
    }

    @isTest
    private static void getAllocationsWithProjectDescription(){
        List<Allocation__c> allocation = [
                SELECT Id
                FROM Allocation__c
        ];
        Test.startTest();

        List<Allocation__c> allocations = allocationSelector.getAllocationsWithProjectDescription(allocation);

        Test.stopTest();
        System.assert(!allocations.isEmpty());
    }
    @isTest
    private static  void getAllocationsWithProjectDescriptionByProjects(){
        List<Project__c> projects = [
                SELECT Id
                FROM Project__c
        ];
        Test.startTest();

        List<Allocation__c> allocations = allocationSelector.getAllocationsWithProjectDescriptionByProjects(projects);

        Test.stopTest();
        System.assert(!allocations.isEmpty());

    }

    @isTest
    private static void getAllocationsByProjectIdsTest() {
        List<Project__c> projects = [SELECT Id FROM Project__c];
        Set<Id> setPIds = new Map<Id, Project__c>(projects).keySet();

        Test.startTest();
        List<Allocation__c> allocations = allocationSelector.getAllocationsByProjectIds(setPIds);
        Test.stopTest();

        System.assert(!allocations.isEmpty());
    }

    @isTest
    private static void getByProjectIdTest(){
        List<Project__c> projects = [SELECT Id FROM Project__c];

        Test.startTest();
        List<Allocation__c> allocations = allocationSelector.getCurrentWithStatusActiveAndFinishedByProjectId(projects[0].Id);
        Test.stopTest();

        System.assert(!allocations.isEmpty());
    }

    @isTest
    private static void getWithDataByIdsTest(){
        Set<String> setAllIds = new Set<String>();
        for(Allocation__c prj: [SELECT Id FROM Allocation__c]){
            setAllIds.add(prj.Id);
        }

        Test.startTest();
        List<Allocation__c> allocations = allocationSelector.getWithDataByIds(setAllIds);
        Test.stopTest();

        System.assert(!allocations.isEmpty());
    }

    @isTest
    private static void getAllocationsByProjectAndFieldSetTest(){
        List<Project__c> projects = [SELECT Id FROM Project__c];

        Test.startTest();
        List<Allocation__c> allocations = allocationSelector.getAllocationsByProjectAndFieldSet(projects[0].Id, ALLOCATIONS_RELATED_LIST_FIELDSET);
        Test.stopTest();

        System.assert(!allocations.isEmpty());
    }
}