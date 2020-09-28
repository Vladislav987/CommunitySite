@IsTest
private class LW_SalaryComponentControllerTest {
    private static final Date TEST_DATE_START = Date.today().addYears(-1);
    private static final Date TEST_DATE_END = Date.today().addYears(1);
    private static final Id ALLOCATION_RECORD_TYPE_PROJECT_ID =
            Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Project').getRecordTypeId();
    private static Id PERSON_ACCOUNT_RT_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

    public static final String TEST_WORD = 'testHier';
    public static final String TEST_PM_WORD = 'testPM';
    public static final String TEST_PM_MANAGER_WORD = 'manager';
    public static final String EN_US = 'en_US';
    public static final String AMERICA_LOS_ANGELES = 'America/Los_Angeles';
    public static final String UTF_8 = 'UTF-8';

    @TestSetup
    static void setup() {
        List<User> users = new List<User>();
        List<Account> accounts = new List<Account>();
        List<Contractor__c> contractors = new List<Contractor__c>();
        String orgId = UserInfo.getOrganizationId();
        String userName = TEST_WORD + '@test' + orgId + '.org';
        String userPMName = TEST_PM_WORD + '@test' + orgId + '.org';
        String userManager = TEST_PM_MANAGER_WORD + '@test' + orgId + '.org';

        Profile profile = [
                SELECT Id
                FROM Profile
                WHERE Name = 'CT_Basic User'
        ];
        Profile profilePM = [
                SELECT Id
                FROM Profile
                WHERE Name = 'CT_Project Manager'
        ];

        User user = new User();
        user.Alias = 'Dev';
        user.Email = 'MyEmail@email.com';
        user.LastName = TEST_WORD;
        user.LanguageLocaleKey = EN_US;
        user.EmailEncodingKey = UTF_8;
        user.LocaleSidKey = EN_US;
        user.ProfileId = profile.Id;
        user.TimeZoneSidKey = AMERICA_LOS_ANGELES;
        user.Username = userName;
        users.add(user);

        User userPM = new User();
        userPM.Alias = 'PMTest';
        userPM.Email = 'PM_Email@email.com';
        userPM.LastName = TEST_PM_WORD;
        userPM.LanguageLocaleKey = EN_US;
        userPM.EmailEncodingKey = UTF_8;
        userPM.LocaleSidKey = EN_US;
        userPM.ProfileId = profilePM.Id;
        userPM.TimeZoneSidKey = AMERICA_LOS_ANGELES;
        userPM.Username = userPMName;
        users.add(userPM);

        User manager = new User();
        manager.Alias = 'Manager';
        manager.Email = 'Manager_Email@email.com';
        manager.LastName = TEST_PM_MANAGER_WORD;
        manager.LanguageLocaleKey = EN_US;
        manager.EmailEncodingKey = UTF_8;
        manager.LocaleSidKey = EN_US;
        manager.ProfileId = profilePM.Id;
        manager.TimeZoneSidKey = AMERICA_LOS_ANGELES;
        manager.Username = userManager;
        users.add(manager);
        insert users;

        Contractor__c contractor = createContractorByNameAndEmail('TEST_CONTRACTOR', user.Email);
        contractors.add(contractor);

        Contractor__c contractorPM = createContractorByNameAndEmail('TEST_PM', userPM.Email);
        contractors.add(contractorPM);

        Contractor__c contractorManager = createContractorByNameAndEmail('Manager', manager.Email);
        contractors.add(contractorManager);
        insert contractors;

        Account account = createPersonAccountByContractor(contractor);
        accounts.add(account);

        Account accountPM = createPersonAccountByContractor(contractorPM);
        accounts.add(accountPM);

        Account accountManager = createPersonAccountByContractor(contractorManager);
        accounts.add(accountManager);
        insert accounts;

        Project__c project = new Project__c();
        project.Name = 'project name';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.Start_date__c = TEST_DATE_START;
        project.End_date__c = TEST_DATE_END;
        project.Station__c = 'CT Minsk';

        insert project;

        Allocation__c allocation = new Allocation__c();
        allocation.Project__c = project.Id;
        allocation.Contractor__c = contractor.Id;
        allocation.Status__c = 'Active';
        allocation.Allocation__c = 100;
        allocation.Allocation_Type__c = 'Billable';
        allocation.Start_date__c = TEST_DATE_START;
        allocation.End_date__c = TEST_DATE_END;
        allocation.RecordTypeId = ALLOCATION_RECORD_TYPE_PROJECT_ID;
        insert allocation;

        Monthly_Report__c report = new Monthly_Report__c();
        report.Contractor__c = contractor.Id;
        report.Allocation__c = allocation.Id;
        report.Plan_hours__c = 152;
        report.Monthly_Report_Start_Date__c = Date.today().toStartOfMonth();
        report.Monthly_Report_End_Date__c = Date.today().toStartOfMonth().addMonths(1).addDays(-1);
        report.Project__c = allocation.Project__c;
        insert report;

        insertGroupMemberByUserIds(new Map<Id, User>(users).keySet());
    }

    @IsTest
    static void checkAsCurrentPM() {
        Contractor__c contractor = getContractorByName('TEST_CONTRACTOR');
        User userPM = getUserByEmail('PM_Email@email.com');
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'project name'];

        Test.startTest();
        Decimal salary;
        System.runAs(userPM) {
            salary = LW_SalaryComponentController.getValue(contractor.Id) == null ? null
                : LW_SalaryComponentController.getValue(contractor.Id).salary;
            System.assertEquals(null, salary);
        }
        project.Project_Manager__c = userPM.Id;
        update project;

        test.stopTest();
        System.runAs(userPM) {

            salary = LW_SalaryComponentController.getValue(contractor.Id).salary;
            System.assertEquals(1000, salary);
        }
    }


    @IsTest
    static void checkAsHierarchy() {
        User user = getUserByEmail('MyEmail@email.com');
        User userPM = getUserByEmail('PM_Email@email.com');
        User userManager = getUserByEmail('Manager_Email@email.com');
        Monthly_Report__c report = [SELECT Id From Monthly_Report__c WHERE Project__r.Name = 'project name'];
        Account account = getAccountByLastName('TEST_CONTRACTOR');
        Account accountPM = getAccountByLastName('TEST_PM');
        Account accountManager = getAccountByLastName('Manager');

        Decimal hourlyRate;
        System.runAs(userPM) {
            hourlyRate = LW_SalaryComponentController.getValue(report.Id)== null ? null
                    : LW_SalaryComponentController.getValue(report.Id).hourlyRate;
            System.assertEquals(null, hourlyRate);
        }
        System.runAs(userManager) {
            hourlyRate = LW_SalaryComponentController.getValue(report.Id)== null ? null
                    : LW_SalaryComponentController.getValue(report.Id).hourlyRate;
            System.assertEquals(null, hourlyRate);
        }

        Test.startTest();
        setManagerAndEmployeeAccount(user.Id, userPM.Id, account.Id);
        setManagerAndEmployeeAccount(userPM.Id, userManager.Id, accountPM.Id);
        setManagerAndEmployeeAccount(userManager.Id, null, accountManager.Id);

        test.stopTest();

        System.runAs(userPM) {
            hourlyRate = LW_SalaryComponentController.getValue(report.Id).hourlyRate;
            System.assertEquals(8.42, hourlyRate);
        }
        System.runAs(userManager) {
            hourlyRate = LW_SalaryComponentController.getValue(report.Id).hourlyRate;
            System.assertEquals(8.42, hourlyRate);
        }
    }

    @future
    private static void insertGroupMember(Id userId) {
        Group publicGroupForComponent = [SELECT Id FROM Group WHERE Name = :System.Label.Public_group_for_Show_Salary_Hourly_Rate_Component];
        GroupMember newMember = new GroupMember();
        newMember.GroupId = publicGroupForComponent.Id;
        newMember.UserOrGroupId = userId;
        insert newMember;
    }
    @future
    private static void insertGroupMemberByUserIds(Set<Id> userIds) {
        List<GroupMember> members = new List<GroupMember>();
        Group publicGroupForComponent = [SELECT Id FROM Group WHERE Name = :System.Label.Public_group_for_Show_Salary_Hourly_Rate_Component];
        for (Id userId : userIds) {
            GroupMember newMember = new GroupMember();
            newMember.GroupId = publicGroupForComponent.Id;
            newMember.UserOrGroupId = userId;
            members.add(newMember);
        }
        insert members;
    }

    private static Contractor__c getContractorByName(String name) {
        return [SELECT Id, Name FROM Contractor__c WHERE Name = :name LIMIT 1];
    }

    @future
    private static void setManagerAndEmployeeAccount(Id userId, Id managerId, Id accountId) {
        User user = [SELECT Id, Employee_AccountId__c, Name, Account.Name, Account.IsPersonAccount, Account.Active__c FROM User WHERE Id = :userId];
        user.ManagerId = managerId;
        user.Employee_AccountId__c = accountId;
        SObjectDomain.isEnabled = false;
        update user;
        SObjectDomain.isEnabled = true;
    }
    private static Contractor__c createContractorByNameAndEmail(String name, String email) {
        Contractor__c contractor = new Contractor__c();
        contractor.Name = name;
        contractor.Resource_Type__c = 'SFDC Developer';
        contractor.Resource_Level__c = 'Trainee';
        contractor.Salary__c = 1000;
        contractor.CurrencyIsoCode = 'USD';
        contractor.Email_Address__c = email;
        return contractor;
    }
    private static Account createPersonAccountByContractor(Contractor__c contractor) {
        Account account = new Account();
        account.Contractor__c = contractor.Id;
        account.LastName = contractor.Name;
        account.RecordTypeId = PERSON_ACCOUNT_RT_ID;
        return account;
    }
    private static User getUserByEmail(String email) {
        return [SELECT Id, AccountId, Employee_AccountId__c From User WHERE Email = :email];
    }
    private static Account getAccountByLastName(String lastName) {
        return [SELECT Id FROM Account WHERE LastName = :lastName];
    }
}