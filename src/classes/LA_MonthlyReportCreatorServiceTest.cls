@IsTest
private class LA_MonthlyReportCreatorServiceTest {
    private static final Date TEST_DATE_START = Date.newInstance(2020, 1, 1);
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
        allocation2.Contractor__c = contractor.Id;
        allocation2.Status__c = 'Active';
        allocation2.Allocation__c = 100;
        allocation2.Allocation_Type__c = 'Billable';
        allocation2.Start_date__c = TEST_DATE_START;
        allocation2.End_date__c = TEST_DATE_END;
        allocation2.RecordTypeId = ALLOCATION_RECORD_TYPE_BOOKING_ID;

        allocations.add(allocation1);
        allocations.add(allocation2);

        insert allocations;
    }

    @IsTest
    private static void tryToCreateReports(){
        List<Allocation__c> allocations = [SELECT Id FROM Allocation__c];
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        List<Date> dates = new List<Date>();
        Set<String> allocationsIdsInStringFormat = new Set<String>();
        for(Allocation__c allocation: allocations){
            allocationsIdsInStringFormat.add(allocation.Id);
        }

        Test.startTest();
        la_MonthlyReportCreatorService.createReportsFromComponent(allocationsIdsInStringFormat, project.Id, 'May', '2020', dates);
        Test.stopTest();

        List<Monthly_Report__c> monthlyReports = [SELECT Id FROM Monthly_Report__c];
        System.assertEquals(2, monthlyReports.size());
    }
    @IsTest
    private static void tryToCreateMultipleReports(){
        List<Allocation__c> allocations = [SELECT Id, Start_date__c FROM Allocation__c];
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        List<Date> dates = new List<Date>();
        dates.add(allocations[0].Start_date__c.addDays(15));
        Set<String> allocationsIdsInStringFormat = new Set<String>();
        for(Allocation__c allocation: allocations){
            allocationsIdsInStringFormat.add(allocation.Id);
        }

        Test.startTest();
        la_MonthlyReportCreatorService.createReportsFromComponent(allocationsIdsInStringFormat, project.Id, 'May', '2020', dates);
        Test.stopTest();

        List<Monthly_Report__c> monthlyReports = [SELECT Id FROM Monthly_Report__c];
        System.assertEquals(4, monthlyReports.size());
    }
    @IsTest
    private static void getInfoAboutReports(){
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
        la_MonthlyReportCreatorService.createReportsFromComponent(allocationsIdsInStringFormat, project.Id, 'May', '2020', dates);
        Test.stopTest();

        List<Allocation__c> withReports = la_MonthlyReportCreatorService.getInfoAboutReports(allocationsIdsInString, project.Id, 'May', '2020').withOneReport;
        System.assert(withReports.size() > 0);
    }


}