@IsTest
private with sharing class AuditLogsScannerTest {

    private static Decimal lookBackHoursPeriod;
    // List of Salesforce user ids to send the email to
    private static String sendEmailTo;
    // List of sections to ignore from the audit log events
    private static String lookForSections;
    // Email subject
    private static String emailSubject;
    private static String profiles;
    private static final String PROFILE_CHANGES_MESSAGE_HEADER = 'Profile changes: ';
    private static final String USERS_CHANGES_MESSAGE_HEADER = 'User changes: ';
    private static final String EMPTY_PROFILE_CHANGES_LAST_24_HOURS = 'Selected profiles are invalid or have no changes for last 24 hours: ';
    private static final String EMPTY_USERNAMES_LIST = 'You\'ve provided no usernames for users to monitor.';
    private static final String EMPTY_PROFILES_LIST = 'You\'ve provided no profiles for users to monitor.';
    private static final String INVALID_USERNAMES_LIST = 'There are some problems with usernames you provided: ';

    @IsTest
    static void testExecute(){
        Test.startTest();
        AuditLogsScanner logScanner = new AuditLogsScanner(-24, sendEmailTo, lookForSections, UserInfo.getUserName(), emailSubject, 'Contract Manager');
        logScanner.parseAuditLogs();
        Test.stopTest();

        System.assertEquals(true, logScanner.emailBodyList.contains(PROFILE_CHANGES_MESSAGE_HEADER));
        System.assertEquals(true, logScanner.emailBodyList.contains(USERS_CHANGES_MESSAGE_HEADER));
    }

    @IsTest
    static void testExecuteWithInvalidUsername(){
        Test.startTest();
        AuditLogsScanner logScanner = new AuditLogsScanner(-24, sendEmailTo, lookForSections, 'invalidusername', emailSubject, profiles);
        logScanner.parseAuditLogs();
        Test.stopTest();

        System.assertEquals(true, logScanner.emailBodyList.contains(INVALID_USERNAMES_LIST));
    }

    @IsTest
    static void testExecuteWithEmptyUsername(){
        Test.startTest();
        AuditLogsScanner logScanner = new AuditLogsScanner(-24, sendEmailTo, lookForSections, '', emailSubject, profiles);
        logScanner.parseAuditLogs();
        Test.stopTest();

        System.assertEquals(true, logScanner.emailBodyList.contains(EMPTY_USERNAMES_LIST));
    }

    @IsTest
    static void testExecuteWithEmptyProfiles(){
        Test.startTest();
        AuditLogsScanner logScanner = new AuditLogsScanner(-24, sendEmailTo, lookForSections, '', emailSubject, '');
        logScanner.parseAuditLogs();
        Test.stopTest();

        System.assertEquals(true, logScanner.emailBodyList.contains(EMPTY_PROFILES_LIST));
    }

    @IsTest
    static void testExecuteWithInvalidProfiles(){
        Test.startTest();
        AuditLogsScanner logScanner = new AuditLogsScanner(-24, sendEmailTo, lookForSections, '', emailSubject, 'Sys Admin');
        logScanner.parseAuditLogs();
        Test.stopTest();
        system.debug(logScanner.emailBodyList);
        System.assertEquals(true, logScanner.emailBodyList.contains(EMPTY_PROFILE_CHANGES_LAST_24_HOURS));
    }

}