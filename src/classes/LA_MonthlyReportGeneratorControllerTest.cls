@IsTest
private class LA_MonthlyReportGeneratorControllerTest {
    private static final Date TEST_DATE_START = Date.newInstance(1900, 1, 1);
    private static final Date TEST_DATE_END = Date.today();
    private static final Id ALLOCATION_RECORD_TYPE_PROJECT_ID =
            Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Project').getRecordTypeId();
    private static final Id ALLOCATION_RECORD_TYPE_BOOKING_ID =
            Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Booking').getRecordTypeId();
    private static LA_MonthlyReportCreatorService la_MonthlyReportCreatorService = new LA_MonthlyReportCreatorService();

    @TestSetup
    static void setup() {
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

        Contractor__c contractor2 = new Contractor__c();
        contractor2.Name = 'Peter';
        contractor2.Resource_Type__c = 'SFDC Developer';
        contractor2.Resource_Level__c = 'Trainee';

        insert contractor2;

        List<Allocation__c> allocations = new List<Allocation__c>();
        Allocation__c allocation1 = new Allocation__c();
        allocation1.Project__c = project.Id;
        allocation1.Status__c = 'Active';
        allocation1.Contractor__c = contractor.Id;
        allocation1.Allocation__c = 100;
        allocation1.Allocation_Type__c = 'Billable';
        allocation1.Start_date__c = TEST_DATE_START;
        allocation1.End_date__c = TEST_DATE_END;
        allocation1.RecordTypeId = ALLOCATION_RECORD_TYPE_PROJECT_ID;

        Allocation__c allocation2 = new Allocation__c();
        allocation2.Project__c = project.Id;
        allocation2.Contractor__c = contractor2.Id;
        allocation2.Status__c = 'Active';
        allocation2.Allocation__c = 100;
        allocation2.Allocation_Type__c = 'Billable';
        allocation2.Start_date__c = TEST_DATE_START;
        allocation2.End_date__c = TEST_DATE_END;
        allocation2.RecordTypeId = ALLOCATION_RECORD_TYPE_PROJECT_ID;

        allocations.add(allocation1);
        allocations.add(allocation2);

        insert allocations;
    }
    @IsTest
    private static void testInitData(){
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        List<Allocation__c> allocations = LA_MonthlyReportGeneratorController.getInitAllocations(project.Id);
        System.debug('Alloc--> ' + allocations);
        Test.stopTest();
        System.assertEquals( 2, allocations.size());
    }
    @IsTest
    private static void getInfoAboutAllocations(){
        List<Allocation__c> allocations = [SELECT Id, Start_date__c FROM Allocation__c];
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        List<Date> dates = new List<Date>();
        Set<String> allocationsIdsInStringFormat = new Set<String>();
        List<String> allocationsIdsInString = new List<String>();
        for(Allocation__c allocation: allocations){
            allocationsIdsInStringFormat.add(allocation.Id);
            allocationsIdsInString.add(allocation.Id);
        }

        Test.startTest();
        la_MonthlyReportCreatorService.createReportsFromComponent(allocationsIdsInStringFormat, project.Id, 'May', '1990', dates);
        Test.stopTest();

        List<Allocation__c> withReports = LA_MonthlyReportGeneratorController.getInfoAboutAllocations(allocationsIdsInString, project.Id, 'May', '1990').withOneReport;
        System.assert(withReports.size() > 0);
    }
    @IsTest
    private static void tryToCreateMultipleReports(){
        List<Allocation__c> allocations = [SELECT Id, Start_date__c FROM Allocation__c];
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        List<Date> dates = new List<Date>();
        dates.add(allocations[0].Start_date__c.addDays(15));

        Test.startTest();
        LA_MonthlyReportGeneratorController.generateReports(allocations[0].Id, project.Id, 'May', '1990', dates);
        Test.stopTest();

        List<Monthly_Report__c> monthlyReports = [SELECT Id FROM Monthly_Report__c];
        System.assertEquals(2, monthlyReports.size());
    }
}