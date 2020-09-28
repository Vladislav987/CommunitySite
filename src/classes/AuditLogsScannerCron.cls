global class AuditLogsScannerCron implements Schedulable {
    private static final String CONFIG_NAME = 'Main_config';

    global void execute(SchedulableContext sc) {
        Audit_Logs_Scanner_Config__mdt logsScannerConfig = [SELECT Look_Back_Hours_Period__c, Recepients_Username__c, Sections__c, Username_of_users_to_monitor__c, Subject__c, Profiles__c
                                                            FROM Audit_Logs_Scanner_Config__mdt
                                                            WHERE DeveloperName = :CONFIG_NAME LIMIT 1];
        if (logsScannerConfig != null) {
            AuditLogsScanner logScanner = new AuditLogsScanner(logsScannerConfig.Look_Back_Hours_Period__c,
                    logsScannerConfig.Recepients_Username__c,
                    logsScannerConfig.Sections__c,
                    logsScannerConfig.Username_of_users_to_monitor__c,
                    logsScannerConfig.Subject__c,
                    logsScannerConfig.Profiles__c);
            logScanner.parseAuditLogs();
        }
        else {
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :sc.getTriggerId()];
            ct.addError('There is no such config in Metadata Types: ' + CONFIG_NAME);
        }
    }
}