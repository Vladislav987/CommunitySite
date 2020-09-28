/**
 * Created by MaxymMirona on 19.12.2019.
 */
@IsTest
public with sharing class AllocationControllerTest {

    private static final Date TEST_DATE_START = Date.newInstance(1900, 1, 1);
    private static final Date TEST_DATE_END = Date.newInstance(1901, 1, 1);
    private static final Date TEST_DATE_IN_RANGE = Date.newInstance(1900, 2, 2);
    private static final String AURA_HANDLED_EXCEPTION_TYPE_NAME = 'System.AuraHandledException';
    private static final Id ALLOCATION_RECORD_TYPE_PROJECT_ID =
            Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Project').getRecordTypeId();
    private static final Id ALLOCATION_RECORD_TYPE_BOOKING_ID =
            Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Booking').getRecordTypeId();
    private static final Id ALLOCATION_RECORD_TYPE_NEW_RESOURCE_REQUEST_ID =
            Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('New_resource_Request').getRecordTypeId();
    private static final String ALLOCATION_LEAVE_TYPE = 'Leave';
    private static final String ALLOCATION_OVERRUN_TYPE = 'Overrun';
    private static final String OVERRUN_TYPE = 'PM';
    private static final String ALLOCATIONS_RELATED_LIST_FIELDSET = 'RelatedListFieldsForProject';
    private static AllocationSelector allocationSelector = new AllocationSelector();
    private static final Id PARENT_PROJECT_RECORD_TYPE_ID = Schema.Project__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId();
    private static final Id ALLOCATION_RECORD_TYPE_NEW_RESOURCE_REQUEST = 
        Schema.Allocation__c.SobjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('New_resource_Request').getRecordTypeId();


    @TestSetup
    private static void setup() {
        Project__c project = new Project__c();
        project.Name = 'project name';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.Start_date__c = TEST_DATE_START;
        project.End_date__c = TEST_DATE_END;
        project.Department__c = 'SFDC Department';

        insert project;

        Contractor__c contractor1 = new Contractor__c();
        contractor1.Name = 'zdarova';
        contractor1.Resource_Type__c = 'SFDC Developer';
        contractor1.Resource_Level__c = 'Trainee';
        contractor1.Department__c = 'SFDC Department';

        insert contractor1;

        Contractor__c contractor2 = new Contractor__c();
        contractor2.Name = 'zdarova2';
        contractor2.Resource_Type__c = 'SFDC Developer';
        contractor2.Resource_Level__c = 'Trainee';
        contractor2.Department__c = 'SFDC Department';

        insert contractor2;

        List<Allocation__c> allocations = new List<Allocation__c>();
        Allocation__c allocation1 = new Allocation__c();
        allocation1.Project__c = project.Id;
        allocation1.Contractor__c = contractor1.Id;
        allocation1.Allocation__c = 99;
        allocation1.Allocation_Type__c = 'Billable';
        allocation1.Start_date__c = System.today().addDays(-5);
        allocation1.Status__c = 'Active';
        allocation1.End_date__c = System.today().addDays(5);
        allocation1.RecordTypeId = ALLOCATION_RECORD_TYPE_PROJECT_ID;
        allocation1.Resource_Type__c = 'SEO';
        allocation1.Expected_Rate__c = 12;
        allocation1.Station__c = 'CTDev Kiev Office';

        Allocation__c allocation2 = new Allocation__c();
        allocation2.Project__c = project.Id;
        allocation2.Contractor__c = contractor2.Id;
        allocation2.Allocation__c = 0;
        allocation2.Allocation_Type__c = 'Billable';
        allocation2.Status__c = 'Active';
        allocation2.Start_date__c = System.today().addDays(-5);
        allocation2.End_date__c = System.today().addDays(5);
        allocation2.RecordTypeId = ALLOCATION_RECORD_TYPE_BOOKING_ID;
        allocation2.Resource_Type__c = 'SEO';
        allocation2.Expected_Rate__c = 15;
        allocation2.Station__c = 'CTDev Kiev Office';

        allocations.add(allocation1);
        allocations.add(allocation2);

        insert allocations;
    }

    @IsTest
    private static void getRelatedListInitDataTestCorrectFlow() {
        List<Project__c> project = [
                SELECT Id
                FROM Project__c
        ];
        if (!project.isEmpty()) {

            Test.startTest();

            AllocationController.RelatedListInfo relatedListData = AllocationController.getRelatedListInitData(project[0].Id);

            Test.stopTest();
            system.assertEquals(2, relatedListData.dataTable.recordsList.size());
        }
    }

    @IsTest
    private static void getRelatedListInitDataTestIncorrectFlowEmptyId() {
        Account acc = new Account(Name = 'acc name 1');

        String exceptionTypeName;
        Test.startTest();

        try {
            AllocationController.RelatedListInfo relatedListData = AllocationController.getRelatedListInitData(acc.Id);
        } catch (Exception e) {
            exceptionTypeName = e.getTypeName();
        }

        Test.stopTest();
        System.assertEquals(AURA_HANDLED_EXCEPTION_TYPE_NAME, exceptionTypeName);
    }

    @IsTest
    private static void createNullableLeaveAllocationTestCorrectFlow(){
        List<Project__c> project = [
                SELECT Id
                FROM Project__c
        ];
        List<Allocation__c> allocation = allocationSelector.getAllocationsByProjectAndFieldSet(project[0].Id, ALLOCATIONS_RELATED_LIST_FIELDSET);

        if (!allocation.isEmpty() && !project.isEmpty()){
            Test.startTest();

            String result = AllocationController.createNullableAllocation(project[0].Id, allocation[0], ALLOCATION_LEAVE_TYPE, '');

            Test.stopTest();
            system.assertEquals('Success', result);
        }
    }

    @IsTest
    private static void deleteNullableAllocationTestCorrectFlow(){
        List<Allocation__c> allocations = [
                SELECT Id
                FROM Allocation__c
                WHERE Allocation__c = 0
        ];

        List<User> systemAdminUsers = [
                SELECT Id
                FROM User
                WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'System Administrator')
                AND IsActive = TRUE
        ];

        if (!allocations.isEmpty() && !systemAdminUsers.isEmpty()){
            System.runAs(systemAdminUsers[0]) {
                Test.startTest();

                String result = AllocationController.deleteNullableAllocation(allocations[0]);

                Test.stopTest();

                system.assertEquals('Success', result);
            }
        }
    }

    @IsTest
    private static void deleteNullableAllocationTestIncorrectFlowEmptyAllocation() {

        Test.startTest();

        String result = AllocationController.deleteNullableAllocation(null);

        Test.stopTest();

        system.assertEquals('Empty Allocation', result);
    }

    @IsTest
    private static void getOverrunTypesTestCorrectFlow(){

        Test.startTest();
        List<String> overrunTypes = AllocationController.getOverrunTypes();
        Test.stopTest();

        system.assertEquals(true, overrunTypes.contains(OVERRUN_TYPE));
    }

    @IsTest
    private static void getMatrixAllocationAndContractorsInitDataTestCorrectFlow(){

        List<Project__c> project = [
                SELECT Id
                FROM Project__c
        ];

        if (!project.isEmpty()) {

            Test.startTest();
            AllocationController.MatrixInfo matrixInfo = AllocationController.getMatrixAllocationAndContractorsInitData(project[0].Id);
            Test.stopTest();

            system.assertEquals(2, matrixInfo.matrixData.allocationsByProjectIds.get(project[0].Id).size());
        }
    }

    @IsTest
    private static void upsertAndApproveAllocationsTestCorrectFlow(){
        List<Allocation__c> allocations = [
                SELECT
                        Id,
                        Allocation_Type__c,
                        Allocation__c,
                        Contractor__c,
                        End_date__c,
                        Name,
                        Project__c,
                        Overrun_Type__c,
                        Status__c,
                        RecordTypeId,
                        Start_date__c,
                        New_Allocation__c
                FROM Allocation__c
        ];

        List<Object> allocationObjects = new List<Object>();

        if (!allocations.isEmpty()) {

            for (Allocation__c allocation : allocations){
                allocation.Status__c = 'New';
                allocation.RecordTypeId = ALLOCATION_RECORD_TYPE_NEW_RESOURCE_REQUEST_ID;
                allocationObjects.add((Object)allocation);
            }

            update allocations;
            Test.startTest();
            String result = AllocationController.upsertAndApproveAllocations(allocationObjects);
            Test.stopTest();

            System.assertEquals('Success', result);
        }
    }

    @IsTest
    private static void upsertAndApproveAllocationsTestIncorrectFlowNoApplicableApprovalProcess(){
        List<Allocation__c> allocations = [
                SELECT
                        Id,
                        Allocation_Type__c,
                        Allocation__c,
                        Contractor__c,
                        End_date__c,
                        Name,
                        Project__c,
                        Overrun_Type__c,
                        Status__c,
                        RecordTypeId,
                        Start_date__c,
                        New_Allocation__c
                FROM Allocation__c
        ];

        List<Object> allocationObjects = new List<Object>();

        if (!allocations.isEmpty()) {

            for (Allocation__c allocation : allocations){
                allocation.Status__c = 'New';
                allocation.RecordTypeId = ALLOCATION_RECORD_TYPE_PROJECT_ID;
                allocationObjects.add((Object)allocation);
            }

            Test.startTest();
            String result = AllocationController.upsertAndApproveAllocations(allocationObjects);
            Test.stopTest();

            System.assertEquals('There is no applicable Approval process found.', result);
        }
    }

    @IsTest
    private static void upsertAndApproveAllocationsTestIncorrectFlowMissingRequiredField(){
        List<Allocation__c> allocations = [
                SELECT
                        Id,
                        Allocation_Type__c,
                        Allocation__c,
                        Contractor__c,
                        End_date__c,
                        Name,
                        Project__c,
                        Overrun_Type__c,
                        Status__c,
                        RecordTypeId,
                        Start_date__c,
                        New_Allocation__c
                FROM Allocation__c
        ];

        List<Object> allocationObjects = new List<Object>();
        String missingField = 'Start_date__c';
        String errorMessage = 'Allocation with Id \'' + allocations[0].Id + '\' has following errors: Random Project Allocation missing such fields: ' + missingField;

        if (!allocations.isEmpty()) {

            for (Allocation__c allocation : allocations){
                allocation.put(missingField, null);
                allocationObjects.add((Object)allocation);
            }

            Test.startTest();
            String result = AllocationController.upsertAndApproveAllocations(allocationObjects);
            Test.stopTest();

            System.assert(result.contains(errorMessage));
        }
    }

    @IsTest
    private static void upsertAndApproveAllocationsTestIncorrectFlowAlreadyInApprovalProcess(){
        List<Allocation__c> allocations = [
                SELECT
                        Id,
                        Allocation_Type__c,
                        Allocation__c,
                        Contractor__c,
                        End_date__c,
                        Name,
                        Project__c,
                        Overrun_Type__c,
                        Status__c,
                        RecordTypeId,
                        Start_date__c,
                        New_Allocation__c
                FROM Allocation__c
        ];

        List<Object> allocationObjects = new List<Object>();

        if (!allocations.isEmpty()) {

            for (Allocation__c allocation : allocations){
                allocationObjects.add((Object)allocation);
                allocation.Status__c = 'New';
                allocation.RecordTypeId = ALLOCATION_RECORD_TYPE_NEW_RESOURCE_REQUEST_ID;
            }
            update allocations;

            Test.startTest();
            AllocationController.upsertAndApproveAllocations(allocationObjects);
            String result = AllocationController.upsertAndApproveAllocations(allocationObjects);
            Test.stopTest();

            System.assertEquals(AllocationService.ALREADY_IN_APPROVAL_PROCESS_ERROR, result);
        }
    }

    @IsTest
    private static void upsertAllocationsBaseOnRandomAllocationTestCorrectFlow(){
        List<Project__c> project = [
                SELECT Id
                FROM Project__c
        ];

        List<Contractor__c> contractor = [
                SELECT Id
                FROM Contractor__c
        ];

        if (!project.isEmpty() && !contractor.isEmpty()) {
            Allocation__c allocation = new Allocation__c();
            allocation.Project__c = project[0].Id;
            allocation.Contractor__c = contractor[0].Id;
            allocation.Allocation__c = 0;
            allocation.Allocation_Type__c = 'Billable';
            allocation.Status__c = 'New';
            allocation.Start_date__c = TEST_DATE_START;
            allocation.End_date__c = TEST_DATE_END;
            allocation.RecordTypeId = ALLOCATION_RECORD_TYPE_NEW_RESOURCE_REQUEST;
            //allocation.Overrun_type__c = 'Warranty';
            //allocation.Comments__c = 'test';

            List<Object> allocationObjects = new List<Object>{(Object)allocation};

            Test.startTest();
            String result = AllocationController.upsertAllocationsBaseOnRandomAllocation(allocationObjects);
            Test.stopTest();

            System.assertEquals('Success', result);
        }
    }

    /*@IsTest
    private static void upsertAllocationsBaseOnRandomAllocationTestIncorrectFlowDuplicateAllocationOfSomeType(){
        List<Project__c> project = [
                SELECT Id,
                (
                        SELECT Id, Contractor__c, Allocation__c, Allocation_Type__c, Project__c, Status__c, Start_date__c, End_date__c, RecordTypeId, Resource_Type__c
                        FROM Allocations__r
                )
                FROM Project__c
        ];

        List<Contractor__c> contractor = [
                SELECT Id
                FROM Contractor__c
        ];

        if (!project.isEmpty() && !contractor.isEmpty()) {
            if (!project[0].Allocations__r.isEmpty()) {
                Test.startTest();

                Allocation__c allocation = project[0].Allocations__r[0].clone();

                List<Object> allocationObjects = new List<Object>{(Object)allocation};

                String result = AllocationController.upsertAllocationsBaseOnRandomAllocation(allocationObjects);

                Test.stopTest();

                System.assert(result.contains(AllocationService.DUPLICATE_ALLOCATION_OF_SOME_TYPE_FOR_PROJECT));
            }
        }
    }*/

    @IsTest
    private static void getAllocationRecordTypesTestCorrectFlow(){

        Test.startTest();
        Map<Id, String> allocationRecordTypes = AllocationController.getAllocationRecordTypes();
        Test.stopTest();

        System.assert(allocationRecordTypes.containsKey(ALLOCATION_RECORD_TYPE_PROJECT_ID));
        System.assert(allocationRecordTypes.containsKey(ALLOCATION_RECORD_TYPE_BOOKING_ID));
    }
}