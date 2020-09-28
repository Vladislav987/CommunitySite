/*
 *  @description    Test class for ContractorPrimaryPMRecalculateBatch.
 */
@isTest 
private class ContractorPrimaryPMRecalculateBatchTest {

    private static final Integer    NUMBER_OF_TEST_PROJECT_MANAGERS     = 2;
    private static final Integer    NUMBER_OF_TEST_PROJECTS             = 3;
    private static final String     DAILY_MIDNIGHT_CRON_EXPRESSION      = '0 0 0 * * ? *';

    @isTest
    private static void contractorPrimaryPMRecalculateTest() {
        // Create test Contractor
        Id contractorRecordTypeId = Schema.SObjectType.Contractor__c.getRecordTypeInfosByDeveloperName().get('Contractor').getRecordTypeId();

        Contractor__c testContractor = new Contractor__c(
            Name = 'Test Contractor',
            Active__c = true,
            Joining_Date__c = System.today().addDays(-9),
            Exit_Date__c = System.today().addDays(9),
            Resource_Type__c = 'SFDC Developer',
            Resource_Level__c = 'Middle',
            Department__c = 'SFDC Department',
            Station__c = 'CT Minsk'
        );
        
        insert testContractor;

        // Create test Project Managers
        Blob uniqueBlob = Crypto.GenerateAESKey(128);
        String uniqueUsernameId = EncodingUtil.ConvertTohex(uniqueBlob).substring(0,8);

        Profile projectManagerProfile = [
            SELECT  Id 
            FROM    Profile 
            WHERE   Name = 'CT_Project Manager'
            LIMIT   1
        ];
        
        List<User> testProjectsManagers = new List<User>();

        for (Integer i = 0; i < NUMBER_OF_TEST_PROJECT_MANAGERS; i++) {
            testProjectsManagers.add(
                new User(
                    Alias = 'stand' + i, 
                    Email = 'testpm'+ i + '@testorg.com',
                    EmailEncodingKey = 'UTF-8', 
                    LastName = 'TestPM' + i, 
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', 
                    ProfileId = projectManagerProfile.Id,
                    TimeZoneSidKey = 'America/Los_Angeles', 
                    UserName = 'testpm' + i + uniqueUsernameId + '@testorg.com'
                )
            );
        }

        insert testProjectsManagers;

        // Create test Projects
        List<Project__c> testProjects = new List<Project__c>();
        Id commercialRecordTypeId = Schema.SObjectType.Project__c.getRecordTypeInfosByDeveloperName().get('Commercial').getRecordTypeId();

        for (Integer i = 0; i < NUMBER_OF_TEST_PROJECTS; i++) {
            testProjects.add(
                new Project__c(
                    RecordTypeId = commercialRecordTypeId,
                    Name = 'Test Project ' + i,
                    Contract_Type__c = 'Fixed Cost',
                    Project_Type__c = 'Outsource',
                    Start_Date__c = System.today().addDays(-10),
                    End_Date__c = System.today().addDays(10),
                    Department__c = 'SFDC Department'
                )
            );
        }

        // Set Project__r.Project_Manager__c
        testProjects[0].Project_Manager__c = testProjectsManagers[0].Id;
        testProjects[1].Project_Manager__c = testProjectsManagers[1].Id;
        testProjects[2].Project_Manager__c = testProjectsManagers[1].Id;

        insert testProjects;

        // Create test Allocations
        List<Allocation__c> testAllocations = new List<Allocation__c>();
        Id projectRecordTypeId = Schema.SObjectType.Allocation__c.getRecordTypeInfosByDeveloperName().get('Project').getRecordTypeId();

        for (Integer i = 0; i < testProjects.size(); i++) {
            testAllocations.add(
                new Allocation__c(
                    Start_Date__c = System.today().addDays(-2),
                    End_Date__c = System.today().addDays(2),
                    Status__c = 'Active',
                    Allocation_Type__c = 'Billable',
                    Contractor__c = testContractor.Id,
                    Project__c = testProjects[i].Id
                )
            );
        }

        // Set Allocation__r.Allocation__c
        testAllocations[0].Allocation__c = 70;
        testAllocations[1].Allocation__c = 35;
        testAllocations[2].Allocation__c = 35;

        insert testAllocations;

        // Set Allocation__r.CreatedDate
        Test.setCreatedDate(testAllocations[0].Id, Date.newInstance(2020, 5, 15));
        Test.setCreatedDate(testAllocations[1].Id, Date.newInstance(2020, 5, 20));
        Test.setCreatedDate(testAllocations[2].Id, Date.newInstance(2020, 5, 10));

        // Run test scheduler that will run batch
        Test.startTest();
        ContractorPrimaryPMRecalculateBatch testScheduledJob = new ContractorPrimaryPMRecalculateBatch();
        System.schedule('ScheduledPrimaryPMRecalculateTest', DAILY_MIDNIGHT_CRON_EXPRESSION, testScheduledJob);
        testScheduledJob.execute(null);
        Test.stopTest();

        // Assert results
        testContractor = [
            SELECT  Primary_PM__c
            FROM    Contractor__c
            WHERE   Id = :testContractor.Id
            LIMIT   1
        ];

        System.assert(
            String.isNotBlank(testContractor.Primary_PM__c),
            'Contractor__r.Primary_PM__c field cannot be empty'
        );
        System.assert(
            testContractor.Primary_PM__c == testProjectsManagers[1].Id,
            'Contractor__r.Primary_PM__c was set incorrectly'
        );
    }

}