/**
 * Created by Dmytro Ardashov on 25.04.2019.
 */

@IsTest
private class RollupSummaryServiceTest {
/*    private static final Id PROJECT_RECORD_TYPE_COMMERCIAL =
            Schema.Project__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Commercial').getRecordTypeId();


    private static final Integer FACTORY_PRODUCTIVITY = 3;

    @TestSetup
    static void createContractorsAndRelatedAllocations() {
        Profile p = [SELECT Id FROM Profile WHERE Name='CT_Project Manager'];
        User u = new User(Alias = 'standt', Email='test123987528@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='test123987528@testorg.com');

        insert u;

        List<Project__c> projects = new List<Project__c>();
        for (Integer i = 0; i < FACTORY_PRODUCTIVITY; i++) {
            Project__c project = new Project__c();
            project.Name = 'project name ' + i;
            project.Project_type__c = 'Outsource';
            project.Contract_type__c = 'Fixed cost';
            project.Start_date__c = Date.today().addMonths(-5);
            project.End_date__c = Date.today().addMonths(5);
            project.RecordTypeId = PROJECT_RECORD_TYPE_COMMERCIAL;
            project.Project_Manager__c = u.Id;
            project.CurrencyIsoCode = 'USD';
            projects.add(project);
        }

        insert projects;

        List<Contractor__c> contractors = new List<Contractor__c>();
        List<Allocation__c> allocations = new List<Allocation__c>();

        for (Integer i = 0; i < FACTORY_PRODUCTIVITY; i++) {

            Contractor__c contractor = new Contractor__c(
                    Name = 'TestContractor' + i,
                    Resource_Type__c = 'SFDC Developer',
                    Resource_Level__c = 'Junior',
                    CurrencyIsoCode = 'USD',
                    Salary__c = 500
            );
            contractors.add(contractor);
        }

        insert contractors;

        SObjectDomain.isEnabledMap.put(SalaryHistoryTriggerHandler.class.getName(), true);
        SObjectDomain.isEnabledMap.put(ContractorTriggerHandler.class.getName(), true);

        for (Integer i = 0; i < FACTORY_PRODUCTIVITY; i++) {

            for (Integer j = 0; j < FACTORY_PRODUCTIVITY; j++) {

                Allocation__c allocation = new Allocation__c(
                        Allocation__c = (i + 1) * (j + 1),
                        Project__c = projects[i].Id,
                        Contractor__c = contractors[j].Id,
                        Status__c = 'Active',
                        Allocation_Type__c = 'Billable',
                        Start_date__c = System.now().dateGmt().addDays(-1),
                        End_date__c = System.now().dateGmt().addDays(1)
                );
                allocations.add(allocation);
            }

        }

        insert allocations;
    }

    @IsTest
    static void testInitCalculations() {

        doAssertion();

        Test.startTest();

        RollupSummaryService.doInitCalculations('ContractorAllActiveAllocations');

        Test.stopTest();

        doAssertion();
    }

    @IsTest
    static void testRecalculationsAfterDeleteAndUndeleteChildren() {

        doAssertion();

        List<Allocation__c> allocations = [
                SELECT
                        Id,
                        Allocation__c,
                        Contractor__c,
                        Status__c
                FROM Allocation__c
        ];

        Allocation__c notDeletedAllocation = allocations.remove(0);

        Test.startTest();
        delete allocations;

        allocations = [
                SELECT
                        Id,
                        Allocation__c,
                        Contractor__c,
                        Status__c
                FROM Allocation__c
                WHERE Id <> :notDeletedAllocation.Id
                ALL ROWS
        ];

        undelete allocations;
        Test.stopTest();

        doAssertion();

    }

    @IsTest
    static void testRecalculationsAfterUpdate() {

        doAssertion();
        Test.startTest();
        List<Allocation__c> allocations = [
                SELECT
                        Id,
                        Allocation__c,
                        Contractor__c,
                        Status__c
                FROM Allocation__c
        ];

        allocations[0].Status__c = 'New';
        allocations[3].Contractor__c = allocations[6].Contractor__c;

        update allocations;
        Test.stopTest();
        doAssertion();
    }

    @IsTest
    static void testRecalculationsAfterInsertChildren() {
        List<Project__c> project = [SELECT Id FROM Project__c];

        doAssertion();

        List<Contractor__c> contractors = [
                SELECT
                        Id,
                        All_active_allocations__c
                FROM Contractor__c
        ];

        List<Allocation__c> allocations = new List<Allocation__c>();

        for (Integer j = 0; j < FACTORY_PRODUCTIVITY; j++) {

            Allocation__c allocation = new Allocation__c(
                    Allocation__c = j,
                    Project__c = project[0].Id,
                    Contractor__c = contractors[j].Id,
                    Status__c = 'Rejected',
                    Allocation_Type__c = 'Billable',
                    Start_date__c = System.now().dateGmt().addDays(-1),
                    End_date__c = System.now().dateGmt().addDays(1)
            );
            allocations.add(allocation);
        }
        test.startTest();
        insert allocations;
        test.stopTest();
        doAssertion();
    }

    static void doAssertion() {

        List<AggregateResult> rollupCalculationsResults = [
                SELECT
                        SUM(Allocation__c),
                        Contractor__c
                FROM Allocation__c
                WHERE Status__c = 'Active'

                GROUP BY Contractor__c
        ];

        List<Contractor__c> contractors = [
                SELECT
                        Id,
                        All_active_allocations__c
                FROM Contractor__c

        ];

        for (Contractor__c contractor : contractors) {

            Boolean assertion = contractor.All_active_allocations__c == getResultById(rollupCalculationsResults, contractor.Id);
            System.debug(contractor.All_active_allocations__c);
            System.debug(getResultById(rollupCalculationsResults, contractor.Id));
            System.assert(assertion, 'Calculated and stored value have to be equal');
        }
    }

    private static Decimal getResultById(List<AggregateResult> aggregateResults, Id objectId) {

        for (AggregateResult result : aggregateResults) {

            if ((Id)result.get('Contractor__c') == objectId) {

                return (Decimal)result.get('expr0');
            }
        }

        return null;
    }

 */
}