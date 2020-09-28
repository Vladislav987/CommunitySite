/**
 * Created by Mychailo Hamdzii on 24.04.2019.
 */
@IsTest
private with sharing class DateRangeSelectorTest {
    private static final Date TEST_DATE_START = Date.newInstance(1900, 1, 1);
    private static final Date TEST_DATE_END = Date.newInstance(1901, 1, 1);
    private static final List<User> systemAdministratorUsers = [
            SELECT Id
            FROM User
            WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'System Administrator') AND IsActive = true
    ];

    @TestSetup
    private static void setup() {
        Project__c project = new Project__c();
        project.Name = 'project name';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.Start_date__c = TEST_DATE_START;
        project.End_date__c = TEST_DATE_END;

        insert project;

        Contractor__c contractor = new Contractor__c();
        contractor.Name = 'zdarova';
        contractor.Resource_Type__c = 'SFDC Developer';
        contractor.Resource_Level__c = 'Trainee';

        insert contractor;
        List<Allocation__c> allocations = new List<Allocation__c>();
        Allocation__c allocation = new Allocation__c();
        allocation.Project__c = project.Id;
        allocation.Contractor__c = contractor.Id;
        allocation.Allocation__c = 100;
        allocation.Allocation_Type__c = 'Billable';
        allocation.Start_date__c = TEST_DATE_START;
        allocation.End_date__c = TEST_DATE_END;
        allocations.add(allocation);

        insert allocations;
    }

    @IsTest
    private static void selectRequiredSObjectWithDatesCorrectFlow() {
        Allocation__c allocation = [
            SELECT Id
            FROM Allocation__c
            LIMIT 1
        ];
        SObjectType sObjectType = Allocation__c.SObjectType;
        DateRangeSelector selector = new DateRangeSelector(sObjectType);

        Test.startTest();

        List<SObject> rangeHolderRecord = selector.selectRequiredSObjectWithDates(allocation.Id);

        Test.stopTest();
        System.assert(!rangeHolderRecord.isEmpty());
        System.assertNotEquals(null, rangeHolderRecord[0].get(DateRangeSelector.START_DATES_BY_TYPE.get(sObjectType)));
        System.assertNotEquals(null, rangeHolderRecord[0].get(DateRangeSelector.END_DATES_BY_TYPE.get(sObjectType)));
    }

    @IsTest
    private static void selectRequiredSObjectWithDatesIncorrectFlow() {
        if (!systemAdministratorUsers.isEmpty()) {
            System.runAs(systemAdministratorUsers[0]) {
                Allocation__c allocation = [
                        SELECT Id
                        FROM Allocation__c
                        LIMIT 1
                ];
                SObjectType sObjectType = Allocation__c.SObjectType;
                DateRangeSelector selector = new DateRangeSelector(sObjectType);

                delete allocation;
                Test.startTest();

                List<SObject> rangeHolderRecord = selector.selectRequiredSObjectWithDates(allocation.Id);

                Test.stopTest();
                System.assert(rangeHolderRecord.isEmpty());
            }
        }
    }
}