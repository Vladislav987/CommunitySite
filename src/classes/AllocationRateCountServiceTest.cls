/**
 * Created by Mychailo Hamdzii on 25.04.2019.
 */
@IsTest
public with sharing class AllocationRateCountServiceTest {
    private static final Date TEST_DATE_START = Date.newInstance(1900, 1, 1);
    private static final Date TEST_DATE_END = Date.newInstance(1901, 1, 1);
    private static final Decimal DECIMAL_ZERO = 0;
    private static final Decimal DECIMAL_FIVE = 5;
    private static final Decimal DECIMAL_SIX = 6;
    private static final Decimal DECIMAL_SEVEN = 7;
    private static final Integer MONTHLY_COEFFICIENT = 21;
    private static final Integer DAILY_COEFFICIENT = 8;
    private static final String ENTITY_IS_DELETED_MESSAGE = 'ENTITY_IS_DELETED';
    private static final String DML_EXCEPTION_TYPE = 'System.DmlException';
    private static final String INVALID_ID = 'id value of incorrect type';
    private static final List<User> systemAdministratorUsers = [SELECT Id FROM User WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'System Administrator') AND IsActive = true];

    @TestSetup
    private static void setup() {
        List<Project__c> projects = new List<Project__c>();

        for (Integer i = 0; i < 4; i ++) {
            Project__c project = new Project__c();
            project.Name = 'project name' + i;
            project.Project_type__c = 'Outsource';
            project.Contract_type__c = 'Fixed cost';
            project.Start_date__c = TEST_DATE_START;
            project.End_date__c = TEST_DATE_END;
            projects.add(project);
        }

        insert projects;

        Contractor__c contractor = new Contractor__c();
        contractor.Name = 'zdarova';
        contractor.Resource_Type__c = 'SFDC Developer';
        contractor.Resource_Level__c = 'Trainee';
        contractor.Salary__c = 500;

        insert contractor;
    }

    @IsTest
    private static void prepareRecordsForInsertTestCorrectFlow() {
        List<Project__c> projects = [
                SELECT Id
                FROM Project__c
        ];
        Contractor__c contractor = [
                SELECT Id
                FROM Contractor__c
                LIMIT 1
        ];

        List<Allocation__c> allocations = new List<Allocation__c>();
        allocations.add(generateAllocationWithRates(projects[0].Id, contractor.Id, DECIMAL_FIVE, DECIMAL_ZERO, null));
        allocations.add(generateAllocationWithRates(projects[1].Id, contractor.Id, null, DECIMAL_SIX, DECIMAL_ZERO));
        allocations.add(generateAllocationWithRates(projects[2].Id, contractor.Id, null, DECIMAL_ZERO, DECIMAL_SEVEN));
        allocations.add(generateAllocationWithRates(projects[3].Id, contractor.Id, null, null, null));

        Test.startTest();
        //SObjectDomain.isEnabledMap.put(AllocationTriggerHandler.class.getName(), true);
        insert allocations;

        Test.stopTest();
        List<Allocation__c> allocationsAfterInsert = [
                SELECT
                        Id,
                        Expected_Rate__c,
                        Expected_Rate_Daily__c,
                        Expected_Rate_Monthly__c
                FROM Allocation__c
                WHERE Project__c IN :projects
                LIMIT :allocations.size()
        ];

        for (Allocation__c allocation : allocationsAfterInsert) {
            if (allocation.Expected_Rate__c != null) {

                System.assertEquals(allocation.Expected_Rate__c.setScale(2),
                        (allocation.Expected_Rate_Daily__c / DAILY_COEFFICIENT).setScale(2)
                );
                System.assertEquals(allocation.Expected_Rate_Daily__c.setScale(2),
                        (allocation.Expected_Rate_Monthly__c / MONTHLY_COEFFICIENT).setScale(2)
                );

            } else {

                System.assert(
                        allocation.Expected_Rate__c == null &&
                                allocation.Expected_Rate_Daily__c == null &&
                                allocation.Expected_Rate_Monthly__c == null
                );

            }
        }

    }

    @IsTest
    private static void prepareRecordsForUpdateTestCorrectFlow() {
        List<Project__c> projects = [
                SELECT Id
                FROM Project__c
        ];
        Contractor__c contractor = [
                SELECT Id
                FROM Contractor__c
                LIMIT 1
        ];
        List<Allocation__c> allocationsToInsert = new List<Allocation__c>();

        allocationsToInsert.add(generateAllocationWithRates(projects[0].Id, contractor.Id, DECIMAL_FIVE, DECIMAL_ZERO, null));
        allocationsToInsert.add(generateAllocationWithRates(projects[1].Id, contractor.Id, null, DECIMAL_SIX, DECIMAL_ZERO));
        allocationsToInsert.add(generateAllocationWithRates(projects[2].Id, contractor.Id, DECIMAL_SEVEN, null, null));
        allocationsToInsert.add(generateAllocationWithRates(projects[3].Id, contractor.Id, DECIMAL_SEVEN, DECIMAL_SIX, DECIMAL_FIVE));

        Test.startTest();
        insert allocationsToInsert;
        List<Allocation__c> allocationBeforeUpdate = [
                SELECT
                        Id,
                        Expected_Rate__c,
                        Allocation_Type__c,
                        Expected_Rate_Daily__c,
                        Expected_Rate_Monthly__c,
                        Comments__c
                FROM Allocation__c
                WHERE Project__c IN :projects
                ORDER BY Id
        ];
        allocationBeforeUpdate[0].Expected_Rate_Monthly__c = DECIMAL_SEVEN;
        allocationBeforeUpdate[1].Expected_Rate_Daily__c = DECIMAL_ZERO;
        allocationBeforeUpdate[2].Expected_Rate__c = null;
        allocationBeforeUpdate[3].Comments__c += '.';


        //SObjectDomain.isEnabledMap.put(AllocationTriggerHandler.class.getName(), true);
        update allocationBeforeUpdate;
        Test.stopTest();

        List<Allocation__c> allocationAfterUpdate = [
                SELECT
                        Id,
                        Expected_Rate__c,
                        Expected_Rate_Daily__c,
                        Expected_Rate_Monthly__c
                FROM Allocation__c
                WHERE Project__c IN :projects
                ORDER BY Id
        ];

        System.assertEquals(DECIMAL_SEVEN, allocationAfterUpdate[0].Expected_Rate_Monthly__c);
        System.assertEquals(DECIMAL_SEVEN / MONTHLY_COEFFICIENT, allocationAfterUpdate[0].Expected_Rate_Daily__c);
        System.assertEquals(DECIMAL_SEVEN / (MONTHLY_COEFFICIENT * DAILY_COEFFICIENT), allocationAfterUpdate[0].Expected_Rate__c);

        System.assert(
                (allocationAfterUpdate[1].Expected_Rate__c == DECIMAL_ZERO) &&
                        (allocationAfterUpdate[1].Expected_Rate_Daily__c == DECIMAL_ZERO) &&
                        (allocationAfterUpdate[1].Expected_Rate_Monthly__c == DECIMAL_ZERO)
        );

        System.assert(
                (allocationAfterUpdate[2].Expected_Rate__c == null) &&
                        (allocationAfterUpdate[2].Expected_Rate_Daily__c == null) &&
                        (allocationAfterUpdate[2].Expected_Rate_Monthly__c == null)
        );

        System.assert(
                (allocationAfterUpdate[3].Expected_Rate__c == allocationBeforeUpdate[3].Expected_Rate__c) &&
                        (allocationAfterUpdate[3].Expected_Rate_Daily__c == allocationBeforeUpdate[3].Expected_Rate_Daily__c) &&
                        (allocationAfterUpdate[3].Expected_Rate_Monthly__c == allocationBeforeUpdate[3].Expected_Rate_Monthly__c)
        );

    }

    @IsTest
    private static void prepareRecordsForInsertIncorrectFlow() {
        Project__c project = [
                SELECT Id
                FROM Project__c
                LIMIT 1
        ];
        Allocation__c allocation = new Allocation__c(OwnerId = project.Id);
        String error;
        Test.startTest();

        try {
            insert allocation;
        } catch (Exception e) {
            error = e.getMessage();
        }

        Test.stopTest();
        System.assert(error.contains(INVALID_ID));
    }
    @IsTest
    private static void prepareRecordsForUpdateIncorrectFlow() {
        if (!systemAdministratorUsers.isEmpty()) {
            System.runAs(systemAdministratorUsers[0]) {
                Project__c project = [
                        SELECT Id
                        FROM Project__c
                        LIMIT 1
                ];
                Contractor__c contractor = [
                        SELECT Id
                        FROM Contractor__c
                        LIMIT 1
                ];
                List<Allocation__c> allocationsToInsert = new List<Allocation__c>();
                allocationsToInsert.add(generateAllocationWithRates(project.Id, contractor.Id, DECIMAL_FIVE, DECIMAL_ZERO, null));
                //SObjectDomain.isEnabledMap.put(AllocationTriggerHandler.class.getName(), true);
                insert allocationsToInsert;
                List<Allocation__c> allocationBeforeUpdate = [
                        SELECT
                                Id,
                                Expected_Rate__c,
                                Expected_Rate_Daily__c,
                                Expected_Rate_Monthly__c
                        FROM Allocation__c
                        WHERE Project__c = :project.Id
                        ORDER BY Id
                ];

                allocationBeforeUpdate[0].Expected_Rate_Monthly__c = DECIMAL_SEVEN;

                delete allocationBeforeUpdate;
                String errorType;
                String errorMessage;

                Test.startTest();

                try {
                    //SObjectDomain.isEnabledMap.put(AllocationTriggerHandler.class.getName(), true);
                    update allocationBeforeUpdate;
                } catch (Exception e) {
                    errorMessage = e.getMessage();
                    errorType = e.getTypeName();
                }

                Test.stopTest();

                System.assert(errorMessage.contains(ENTITY_IS_DELETED_MESSAGE));
                System.assertEquals(DML_EXCEPTION_TYPE, errorType);
            }
        }
    }

    private static Allocation__c generateAllocationWithRates(
            Id projectId,
            Id contractorId,
            Decimal hourlyRate,
            Decimal dailyRate,
            Decimal monthlyRate
    ) {
        Allocation__c allocation = new Allocation__c();
        allocation.Project__c = projectId;
        allocation.Contractor__c = contractorId;
        allocation.Allocation__c = 100;
        allocation.Allocation_Type__c = 'Billable';
        allocation.Start_date__c = TEST_DATE_START;
        allocation.End_date__c = TEST_DATE_END;
        allocation.Expected_Rate__c = hourlyRate;
        allocation.Expected_Rate_Daily__c = dailyRate;
        allocation.Expected_Rate_Monthly__c = monthlyRate;

        return allocation;
    }

}