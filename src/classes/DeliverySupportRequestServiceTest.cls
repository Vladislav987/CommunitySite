@IsTest
private class DeliverySupportRequestServiceTest {

    @TestSetup
    private static void setup() {
        Account account = new Account();
        account.Name = 'Test';
        insert account;

        Opportunity opportunity = new Opportunity();
        opportunity.Name = 'Test Opportunity';
        opportunity.Key_practice__c = 'Other';
        opportunity.StageName = 'New';
        opportunity.CloseDate = Date.today().addYears(1);
        insert opportunity;
    }

    @IsTest
    static void testBehavior() {
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Delivery_Support_Request__c request = new Delivery_Support_Request__c();
        request.Opportunity__c = opportunity.Id;
        insert request;
    }
}