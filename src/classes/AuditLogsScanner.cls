public class AuditLogsScanner {

    private static final String PROFILE_CHANGES_MESSAGE_HEADER = 'Profile changes: ';
    private static final String USERS_CHANGES_MESSAGE_HEADER = 'User changes: ';
    private static final String EMPTY_LOGS_HISTORY_MESSAGE = 'Users performed no actions for last ';
    private static final String EMPTY_PROFILE_CHANGES = 'Selected profiles are invalid or have no changes for last ';
    private static final String EMPTY_USERNAMES_LIST = 'You\'ve provided no usernames for users to monitor.';
    private static final String EMPTY_PROFILES_LIST = 'You\'ve provided no profiles for users to monitor.';
    private static final String INVALID_USERNAMES_LIST = 'There are some problems with usernames you provided: ';
    // lookback period
    private Decimal lookBackHoursPeriod;
    // List of Salesforce user ids to send the email to
    private List<String> sendEmailTo;
    // List of sections to ignore from the audit log events
    private List<String> lookForSections;
    // List of users to monitor
    private List<String> usersToMonitor;
    // Email subject
    private String emailSubject;
    private List<String> profiles;
    //System Administrator user Ids
    private List<String> systemAdmins;
    //Abs of lookBackHours
    private String lookBackHoursPeriodString;
    //Full Names of provided User's
    private List<String> usersToMonitorFullNames;
    public List<String> emailBodyList;

    public auditLogsScanner(Decimal lookBackHoursPeriod, String sendEmailTo, String lookForSections, String usersToMonitor, String emailSubject, String profiles){
        this.lookBackHoursPeriod = lookBackHoursPeriod == null? -24 : lookBackHoursPeriod;
        this.lookBackHoursPeriodString = Math.abs(lookBackHoursPeriod) + ' hours: ';
        this.sendEmailTo = parseSendEmailToString(sendEmailTo);
        this.lookForSections = parseInputString(lookForSections);
        this.usersToMonitor = parseUsersToMonitorString(usersToMonitor);
        this.usersToMonitorFullNames = this.usersToMonitor == null ? null : getUserFullNames(this.usersToMonitor);
        this.profiles = parseInputString(profiles);
        this.emailSubject = emailSubject == null ? 'Audit Logs' : emailSubject;
    }

    public List<String> parseInputString(String input){
        if (!String.isEmpty(input)) {
            List<String> parsedInput = input.split(',');
            if (parsedInput.isEmpty() || parsedInput.size() == 1){
                parsedInput = input.split('\r\n');
            }
            return parsedInput;
        }
        return null;
    }

    public List<String> getSystemAdmins(){
        List<User> systemAdminUsers = [SELECT id, Email FROM User WHERE ProfileId IN (SELECT id FROM Profile WHERE Name = 'System Administrator')];
        List<String> systemAdmins = new List<String>();
        for (User systemAdmin : systemAdminUsers){
            systemAdmins.add(systemAdmin.Id);
        }
        return systemAdmins;
    }

    public List<String> getUserFullNames(List<String> userNames){
        List<User> users = [SELECT id, Name FROM User WHERE Username IN :userNames];
        if (!users.isEmpty()) {
            List<String> userFullNames = new List<String>();
            for (User us : users) {
                userFullNames.add(us.Name);
            }
            return userFullNames;
        }
        return null;
    }

    public List<String> parseSendEmailToString(String sendEmailTo){
        if (!String.isEmpty(sendEmailTo)) {
            List<String> sendEmailToList = parseInputString(sendEmailTo);
            List<String> sendEmailToIds = new List<String>();
            for (User userToSend : [SELECT id FROM User WHERE Username IN :sendEmailToList]){
                sendEmailToIds.add(userToSend.Id);
            }
            return sendEmailToIds;
        }
        return null;
    }

    public List<String> parseUsersToMonitorString(String usersToMonitor){
        if (!String.isEmpty(usersToMonitor)) {
            List<String> usersToMonitorList = parseInputString(usersToMonitor);
            List<String> usersToMonitorListInQuotes = new List<String>();
            for (String user : usersToMonitorList){
                usersToMonitorListInQuotes.add('\'' + user + '\'');
            }
           return usersToMonitorList;
        }
        return null;
    }

    public void sendEmailMessage(List<String> body) {

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        this.systemAdmins = getSystemAdmins();
        message.toAddresses = sendEmailTo == null ? systemAdmins : sendEmailTo;                                         //If sendEmailTo field is empty, send email to all System Admins
        message.subject = emailSubject;
        String messageBody = String.join(body, '\n\n');
        message.plainTextBody = messageBody;

        try {
            if (!Test.isRunningTest()){
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {message});
            }
        } catch(System.CalloutException e) {
            System.debug('ERROR:' + e);
        }
    }

    public void parseAuditLogs() {

        DateTime dt = System.Now().addHours((Integer)lookbackHoursPeriod);

        String query = 'SELECT CreatedDate, CreatedBy.UserName, Action, Section, Display FROM SetupAuditTrail WHERE CreatedDate >= ' + dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        query += ' ORDER BY CreatedDate DESC';
        List<SetupAuditTrail> queryResults = Database.query(query);

        if (queryResults.isEmpty()) {
            List<String> emailBodyList = new List<String>();
            String emailLine = EMPTY_LOGS_HISTORY_MESSAGE;

            emailBodyList.add(emailLine);
            sendEmailMessage(emailBodyList);
        }

        emailBodyList = new List<String>();

        if (usersToMonitorFullNames != null){                                                                           //If provided usernames are valid
            String headerLine = USERS_CHANGES_MESSAGE_HEADER;
            emailBodyList.add(headerLine);
            for (String userFullName : usersToMonitorFullNames) {
                for (SetupAuditTrail log : queryResults) {
                    if (log.Section == 'Manage Users' && log.Display.contains(userFullName)) {
                        String emailLine = 'USER: ' + userFullName + '\n' +
                                           'Change was made by: ' + log.CreatedBy.UserName + '\n' +
                                           'Section: ' + log.Section + '\n' +
                                           'Action: ' + log.Action  + '\n' +
                                           'Details: ' + log.Display;
                        emailBodyList.add(emailLine);
                    }
                }
            }
        }
        else {                                                                                                          //If provided usernames are invalid
            String emailLine = INVALID_USERNAMES_LIST;
            String userNamesList;
            if (usersToMonitor != null) {
                userNamesList = String.join(usersToMonitor, '\n');
            }
            else {
                userNamesList = EMPTY_USERNAMES_LIST;                                                                   //If provided usernames are empty
            }
            emailBodyList.add(emailLine);
            emailBodyList.add(userNamesList);
        }

        if (profiles != null) {                                                                                         //Profiles section
            system.debug(profiles);
            List<String> profileBodyList = new List<String>();
            String headerLine = PROFILE_CHANGES_MESSAGE_HEADER;
            profileBodyList.add(headerLine);
            for (String profile : profiles) {
                for (SetupAuditTrail log : queryResults) {
                    if (log.Section == 'Manage Users' && log.Display.contains(profile)) {
                        String emailLine = 'PROFILE: ' + profile + '\n' +
                                           'Change was made by: ' + log.CreatedBy.UserName + '\n' +
                                           'Section: ' + log.Section + '\n' +
                                           'Action: ' + log.Action + '\n' +
                                           'Details: ' + log.Display;
                        profileBodyList.add(emailLine);
                    }
                }
            }

            if (profileBodyList.size() == 1){                                                                           //If there is no changes for Profile
                String emailLine = EMPTY_PROFILE_CHANGES + lookBackHoursPeriodString;
                String profileNamesList = String.join(profiles, '\n');
                profileBodyList.add(emailLine);
                profileBodyList.add(profileNamesList);
                emailBodyList.addAll(profileBodyList);
            }
            else {
                emailBodyList.addAll(profileBodyList);
            }
        }
        else {                                                                                                          //If empty Profile string provided
            String headerLine = PROFILE_CHANGES_MESSAGE_HEADER;
            String profileNamesList = EMPTY_PROFILES_LIST;
            emailBodyList.add(headerLine);
            emailBodyList.add(profileNamesList);
        }

        if (!emailBodyList.isEmpty()) {
            sendEmailMessage(emailBodyList);
        }

    }
}