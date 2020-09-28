/**
 * Created by MaxymMirona on 19.12.2019.
 */
@IsTest
public with sharing class AllocationServiceTest {

    private static final Date TEST_DATE_START = Date.newInstance(1900, 1, 1);
    private static final Date TEST_DATE_END = Date.newInstance(1901, 1, 1);
    private static final Date TEST_DATE_IN_RANGE = Date.newInstance(1900, 2, 2);
    private static final String AURA_HANDLED_EXCEPTION_TYPE_NAME = 'System.AuraHandledException';
    private static final Id ALLOCATION_RECORD_TYPE_PROJECT_ID =
            Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Project').getRecordTypeId();
    private static final Id ALLOCATION_RECORD_TYPE_BOOKING_ID =
            Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Booking').getRecordTypeId();
    private static final String ALLOCATION_LEAVE_TYPE = 'Leave';
    private static final String ALLOCATIONS_RELATED_LIST_FIELDSET = 'RelatedListFieldsForProject';
    private static AllocationService allocationServiceObject = new AllocationService();
    private static AllocationSelector allocationSelector = new AllocationSelector();
    public static final Id PARENT_PROJECT_RECORD_TYPE_ID = Schema.Project__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId();

    @TestSetup
    private static void setup() {
        Project__c project = new Project__c();
        project.Name = 'project name';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.Start_date__c = TEST_DATE_START;
        project.End_date__c = TEST_DATE_END;
        project.RecordTypeId = PARENT_PROJECT_RECORD_TYPE_ID;

        insert project;

        Contractor__c contractor1 = new Contractor__c();
        contractor1.Name = 'zdarova1';
        contractor1.Resource_Type__c = 'SFDC Developer';
        contractor1.Resource_Level__c = 'Trainee';

        insert contractor1;

        Contractor__c contractor2 = new Contractor__c();
        contractor2.Name = 'zdarova2';
        contractor2.Resource_Type__c = 'SFDC Developer';
        contractor2.Resource_Level__c = 'Trainee';

        insert contractor2;

        List<Allocation__c> allocations = new List<Allocation__c>();
        Allocation__c allocation1 = new Allocation__c();
        allocation1.Project__c = project.Id;
        allocation1.Contractor__c = contractor1.Id;
        allocation1.Allocation__c = 100;
        allocation1.Allocation_Type__c = 'Billable';
        allocation1.Start_date__c = TEST_DATE_START;
        allocation1.End_date__c = TEST_DATE_END;
        allocation1.RecordTypeId = ALLOCATION_RECORD_TYPE_PROJECT_ID;

        Allocation__c allocation2 = new Allocation__c();
        allocation2.Project__c = project.Id;
        allocation2.Contractor__c = contractor2.Id;
        allocation2.Allocation__c = 0;
        allocation2.Allocation_Type__c = 'Billable';
        allocation2.Start_date__c = TEST_DATE_START;
        allocation2.End_date__c = TEST_DATE_END;
        allocation2.RecordTypeId = ALLOCATION_RECORD_TYPE_BOOKING_ID;

        allocations.add(allocation1);
        allocations.add(allocation2);

        insert allocations;
    }

    @IsTest
    private static void insertNullableAllocationTestCorrectFlow(){
        List<Project__c> projects = [
                SELECT Id
                FROM Project__c
        ];
        List<Allocation__c> allocations = allocationSelector.getAllocationsByProjectAndFieldSet(projects[0].Id, ALLOCATIONS_RELATED_LIST_FIELDSET);

        if (!allocations.isEmpty() && !projects.isEmpty()){
            Test.startTest();

            String result = allocationServiceObject.insertNullableAllocation(projects[0].Id, allocations[0], ALLOCATION_LEAVE_TYPE, '');

            Test.stopTest();

            system.assertEquals('Success', result);
        }
    }

    @IsTest
    private static void checkAllocationsForPossibilityToDeleteTestCorrectFlow(){
        List<Allocation__c> allocations = [SELECT Id, IsDeleted FROM Allocation__c WHERE Contractor__c != null];
        List<User> users = [SELECT Id FROM User WHERE ProfileId NOT IN (SELECT id FROM Profile WHERE Name = 'System Administrator') AND IsActive = true];

        if (!allocations.isEmpty() && !users.isEmpty()){
            System.runAs(users[0]) {
                Exception exceptionResult;

                Test.startTest();

                try {
                    delete allocations[0];
                } catch (Exception e){
                    exceptionResult = e;
                }

                Test.stopTest();

                if (Schema.Allocation__c.SObjectType.getDescribe().isDeletable()) {
                    System.assert(exceptionResult.getMessage().contains(AllocationService.RESTRICT_DELETION_FOR_NOT_ADMIN_USER_ERROR));
                } else {
                    System.assert(exceptionResult.getMessage().contains(String.valueOf(StatusCode.INSUFFICIENT_ACCESS_OR_READONLY)));
                }
            }
        }
    }

    /*@IsTest
    private static void validateForSingleAllocationOfSomeTypeForParentProjectTestCorrectFlow(){
        List<Project__c> projects = [
                SELECT Id, (
                        SELECT
                                Id,
                                Contractor__c,
                                Project__c,
                                Resource_Type__c,
                                Allocation__c,
                                Allocation_Type__c,
                                Start_date__c,
                                End_date__c
                        FROM Allocations__r)
                FROM Project__c
        ];

        if (!projects.isEmpty()){
            if (!projects[0].Allocations__r.isEmpty()){
                String error = '';
                Allocation__c duplicateAllocation = projects[0].Allocations__r[0].clone();

                Test.startTest();

                try {
                    insert duplicateAllocation;
                } catch (Exception e){
                    error = e.getMessage();
                }

                System.assert(error.contains(AllocationService.DUPLICATE_ALLOCATION_OF_SOME_TYPE_FOR_PARENT_PROJECT));
            }
        }

    }*/
}