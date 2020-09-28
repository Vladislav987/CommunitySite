@IsTest
private class FinancialPlanningYearControllerTest {

    @TestSetup
    static void setup() {
        List<Financial_Planning_Year__c> financialPlanningYears = new List<Financial_Planning_Year__c>();
        Financial_Planning_Year__c year = new Financial_Planning_Year__c(Year__c = 2019);
        Financial_Planning_Year__c year1 = new Financial_Planning_Year__c(Year__c = 2018);
        Financial_Planning_Year__c year2 = new Financial_Planning_Year__c(Year__c = 2017);
        Financial_Planning_Year__c year3 = new Financial_Planning_Year__c(Year__c = 2016);
        financialPlanningYears.add(year);
        financialPlanningYears.add(year1);
        financialPlanningYears.add(year2);
        financialPlanningYears.add(year3);
        insert financialPlanningYears;
    }
    @IsTest
    static void getFinancialPlanningYearDataTest() {
        Test.startTest();
        FinancialPlanningYearController.getFinancialPlanningYearData(1,5);
        Test.stopTest();
    }

    @IsTest
    static void updateFinancialPlanningYearTest() {
        Test.startTest();
        Financial_Planning_Year__c year = [SELECT Id,End_Planning_Date__c,Start_Planing_Date__c FROM Financial_Planning_Year__c WHERE Year__c = 2019];
        Boolean result = FinancialPlanningYearController.updateFinancialPlanningYear(year);
        Test.stopTest();
        System.assertEquals(true,result);
    }

    @IsTest
    static void endFinancialPlanningYear() {
        Test.startTest();
        Financial_Planning_Year__c year = [SELECT Id,End_Planning_Date__c,Start_Planing_Date__c FROM Financial_Planning_Year__c WHERE Year__c = 2019];
        Boolean result = FinancialPlanningYearController.endFinancialPlanningYear(year);
        Test.stopTest();
        System.assertEquals(true,result);
    }
}