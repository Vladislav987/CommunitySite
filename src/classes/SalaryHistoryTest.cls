@IsTest
private class SalaryHistoryTest {
    @IsTest
    static void changeSalary() {

        Contractor__c contractor = new Contractor__c();
        contractor.Name = 'TEST_CONTRACTOR';
        contractor.Resource_Type__c = 'SFDC Developer';
        contractor.Resource_Level__c = 'Trainee';
        contractor.Salary__c = 1000;
        contractor.CurrencyIsoCode = 'USD';
        insert contractor;

        Test.startTest();

        contractor.Salary__c = 1100;
        update contractor;

        Test.stopTest();

        List<Salary_History__c> salaryHistory = [SELECT Id FROM Salary_History__c];
        System.equals(2, salaryHistory.size());

    }
    @IsTest
    static void validationOfSalaryHistoryTest() {
        Contractor__c contractor = new Contractor__c();
        contractor.Name = 'CONTRACTOR_TEST';
        contractor.Resource_Type__c = 'SFDC Developer';
        contractor.Resource_Level__c = 'Trainee';
        contractor.Salary__c = 1000;
        contractor.CurrencyIsoCode = 'USD';
        insert contractor;

        Salary_History__c newSalaryHistory = new Salary_History__c(Salary__c = 1200, Contractor__c = contractor.Id, Start_Date__c = Date.today());

        Test.startTest();
        SObjectDomain.isEnabledMap.put(SalaryHistoryTriggerHandler.class.getName(), true);
        SObjectDomain.isEnabledMap.put(ContractorTriggerHandler.class.getName(), true);
        insert newSalaryHistory;
        Salary_History__c lastSalaryHistory = [SELECT Id, Start_Date__c, End_Date__c FROM Salary_History__c WHERE Salary__c = 1200 LIMIT 1];
        System.assertEquals(Date.today().toStartOfMonth(), lastSalaryHistory.Start_Date__c);
        System.assertEquals(Date.parse('01/12/2099'), lastSalaryHistory.End_Date__c);

        lastSalaryHistory.Salary__c = 1500;
        SObjectDomain.isEnabledMap.put(SalaryHistoryTriggerHandler.class.getName(), true);
        SObjectDomain.isEnabledMap.put(ContractorTriggerHandler.class.getName(), true);
        update lastSalaryHistory;
        List<Salary_History__c> updatedSalaryHistories = [SELECT Id, Salary__c FROM Salary_History__c WHERE Salary__c = 1500];
        Contractor__c updatedContractor = [SELECT Id, Salary__c FROM Contractor__c WHERE Id = :contractor.Id LIMIT 1];

        System.assertEquals(1, updatedSalaryHistories.size());
        System.assertEquals(1500, updatedContractor.Salary__c);

        Salary_History__c firstSalaryHistory = [SELECT Id, Salary__c FROM Salary_History__c WHERE Salary__c = 1000];
        firstSalaryHistory.Salary__c = 900;
        SObjectDomain.isEnabledMap.put(SalaryHistoryTriggerHandler.class.getName(), true);
        SObjectDomain.isEnabledMap.put(ContractorTriggerHandler.class.getName(), true);
        try {
            update firstSalaryHistory;
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            System.assertEquals(0, [SELECT Id FROM Salary_History__c WHERE Salary__c = 900].size());
        }
        firstSalaryHistory.Start_Date__c = Date.parse('07/11/2018');
        SObjectDomain.isEnabledMap.put(SalaryHistoryTriggerHandler.class.getName(), true);
        SObjectDomain.isEnabledMap.put(ContractorTriggerHandler.class.getName(), true);
        try {
            update firstSalaryHistory;
        } catch (Exception ex) {
            System.assertEquals(0, [SELECT Id FROM Salary_History__c WHERE Start_Date__c = :firstSalaryHistory.Start_Date__c].size());
        }
        firstSalaryHistory.Start_Date__c = Date.today().toStartOfMonth();
        firstSalaryHistory.End_Date__c = Date.parse('09/04/2018');
        SObjectDomain.isEnabledMap.put(SalaryHistoryTriggerHandler.class.getName(), true);
        SObjectDomain.isEnabledMap.put(ContractorTriggerHandler.class.getName(), true);
        try {
            update firstSalaryHistory;
        } catch (Exception ex) {
            System.assertEquals(0, [SELECT Id FROM Salary_History__c WHERE End_Date__c = :firstSalaryHistory.End_Date__c].size());
        }
        contractor.Salary__c = 2000;
        SObjectDomain.isEnabledMap.put(SalaryHistoryTriggerHandler.class.getName(), true);
        SObjectDomain.isEnabledMap.put(ContractorTriggerHandler.class.getName(), true);
        update contractor;
        System.assertEquals(2000, [SELECT Id, Salary__c FROM Salary_History__c WHERE End_Date__c = :Date.parse('01/12/2099')][0].Salary__c);

        Test.stopTest();
    }
}