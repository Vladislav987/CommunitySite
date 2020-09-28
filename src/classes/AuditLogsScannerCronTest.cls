@IsTest
private with sharing class AuditLogsScannerCronTest {

    @IsTest
    static void testExecute(){
        Test.startTest();
        String jobId = System.schedule('Audit Log tracker', '0 00 20 * * ?', new AuditLogsScannerCron());
        Test.stopTest();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertNotEquals(null, ct);
    }




}