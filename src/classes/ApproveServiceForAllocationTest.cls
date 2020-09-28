@IsTest
private class ApproveServiceForAllocationTest {
    private static final Date TEST_DATE_START = Date.today().addYears(-1);
    private static final Date TEST_DATE_END = Date.today().addYears(1);
    private static final Id ALLOCATION_RECORD_TYPE_PROJECT_ID =
            Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Project').getRecordTypeId();

    public static final String TEST_WORD = 'testDev';
    public static final String TEST_PM_WORD = 'testPM';
    public static final String EN_US = 'en_US';
    public static final String AMERICA_LOS_ANGELES = 'America/Los_Angeles';
    public static final String UTF_8 = 'UTF-8';

    @TestSetup
    static void doSetup() {
        List<User> users = new List<User>();

        String orgId = UserInfo.getOrganizationId();
        String userName = TEST_WORD + '@test' + orgId + '.org';
        String userPMName = TEST_PM_WORD + '@test' + orgId + '.org';


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

        User userPM = new User();
        userPM.Alias = 'PMTest';
        userPM.Email = TEST_PM_WORD + 'Email@email.com';
        userPM.LastName = TEST_PM_WORD;
        userPM.LanguageLocaleKey = EN_US;
        userPM.EmailEncodingKey = UTF_8;
        userPM.LocaleSidKey = EN_US;
        userPM.ProfileId = profilePM.Id;
        userPM.TimeZoneSidKey = AMERICA_LOS_ANGELES;
        userPM.Username = userPMName;
        users.add(userPM);

        User user = new User();
        user.Alias = 'Dev';
        user.Email = TEST_WORD + 'Email@email.com';
        user.LastName = TEST_WORD;
        user.LanguageLocaleKey = EN_US;
        user.EmailEncodingKey = UTF_8;
        user.LocaleSidKey = EN_US;
        user.ProfileId = profile.Id;
        user.TimeZoneSidKey = AMERICA_LOS_ANGELES;
        user.Username = userName;
        user.ManagerId = userPM.Id;
        users.add(user);

        insert users;

        Project__c project = new Project__c();
        project.Name = 'project name';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.Start_date__c = TEST_DATE_START;
        project.End_date__c = TEST_DATE_END;
        project.Station__c = 'CT Minsk';
        project.Department__c = 'Enterprise & Technology';
        project.Project_Manager__c = user.Id;

        insert project;

        Allocation__c allocation = new Allocation__c();
        allocation.Project__c = project.Id;
        allocation.Status__c = 'Active';
        allocation.Allocation__c = 100;
        allocation.Allocation_Type__c = 'Billable';
        allocation.Start_date__c = TEST_DATE_START;
        allocation.End_date__c = TEST_DATE_END;
        allocation.RecordTypeId = ALLOCATION_RECORD_TYPE_PROJECT_ID;
        allocation.Resource_Type__c = 'Designer';
        allocation.Station__c = 'All';
        insert allocation;
    }
    @IsTest
    static void checkApproverAfterInsert() {
        Allocation__c allocation = getAllocationForTest();
        List<Approval_Assigner_Settings_Details__mdt> priority1 = getApprovalAssignerSettingsDetailsPriority1(allocation);
        List<Approval_Assigner_Settings_Details__mdt> priority2 = getApprovalAssignerSettingsDetailsPriority2(allocation);
        List<Approval_Assigner_Settings_Details__mdt> priority3 = getApprovalAssignerSettingsDetailsPriority3(allocation);
        List<Approval_Assigner_Settings_Details__mdt> priority4 = getApprovalAssignerSettingsDetailsPriority4(allocation);
        Project__c project = [SELECT Project_Manager__r.ManagerId FROM Project__c];
        Test.startTest();

        if (!priority1.isEmpty()) {
            if (priority1[0].User_Id__c.contains('@')) {
                System.assertEquals(priority1[0].User_Id__c, allocation.Approver_Manager__r.Username);
            } else {
                System.assertEquals(priority1[0].User_Id__c, allocation.Approver_Manager__r.Id);
            }
        } else if (!priority2.isEmpty()) {
            if (priority2[0].User_Id__c.contains('@')) {
                System.assertEquals(priority2[0].User_Id__c, allocation.Approver_Manager__r.Username);
            } else {
                System.assertEquals(priority2[0].User_Id__c, allocation.Approver_Manager__r.Id);
            }
        } else if (!priority3.isEmpty()) {
            if (priority3[0].User_Id__c.contains('@')) {
                System.assertEquals(priority3[0].User_Id__c, allocation.Approver_Manager__r.Username);
            } else {
                System.assertEquals(priority3[0].User_Id__c, allocation.Approver_Manager__r.Id);
            }
        } else if (!priority4.isEmpty()) {
            if (priority4[0].User_Id__c.contains('@')) {
                System.assertEquals(priority4[0].User_Id__c, allocation.Approver_Manager__r.Username);
            } else {
                System.assertEquals(priority4[0].User_Id__c, allocation.Approver_Manager__r.Id);
            }
        } else {
            System.assertEquals(project.Project_Manager__r.ManagerId, allocation.Approver_Manager__r.Id);
        }
        Test.stopTest();
    }


    @IsTest
    static void checkApproverAfterUpdate() {
        Allocation__c allocation = getAllocationForTest();
        allocation.Station__c = 'CTDev Lviv Office';
        update allocation;
        Test.startTest();
        List<Approval_Assigner_Settings_Details__mdt> priority1 = getApprovalAssignerSettingsDetailsPriority1(allocation);
        List<Approval_Assigner_Settings_Details__mdt> priority2 = getApprovalAssignerSettingsDetailsPriority2(allocation);
        List<Approval_Assigner_Settings_Details__mdt> priority3 = getApprovalAssignerSettingsDetailsPriority3(allocation);
        List<Approval_Assigner_Settings_Details__mdt> priority4 = getApprovalAssignerSettingsDetailsPriority4(allocation);
        Project__c project = [SELECT Project_Manager__r.ManagerId FROM Project__c];

        Test.stopTest();

        if (!priority1.isEmpty()) {
            if (priority1[0].User_Id__c.contains('@')) {
                System.assertEquals(priority1[0].User_Id__c, allocation.Approver_Manager__r.Username);
            } else {
                System.assertEquals(priority1[0].User_Id__c, allocation.Approver_Manager__r.Id);
            }
        } else if (!priority2.isEmpty()) {
            if (priority2[0].User_Id__c.contains('@')) {
                System.assertEquals(priority2[0].User_Id__c, allocation.Approver_Manager__r.Username);
            } else {
                System.assertEquals(priority2[0].User_Id__c, allocation.Approver_Manager__r.Id);
            }
        } else if (!priority3.isEmpty()) {
            if (priority3[0].User_Id__c.contains('@')) {
                System.assertEquals(priority3[0].User_Id__c, allocation.Approver_Manager__r.Username);
            } else {
                System.assertEquals(priority3[0].User_Id__c, allocation.Approver_Manager__r.Id);
            }
        } else if (!priority4.isEmpty()) {
            if (priority4[0].User_Id__c.contains('@')) {
                System.assertEquals(priority4[0].User_Id__c, allocation.Approver_Manager__r.Username);
            } else {
                System.assertEquals(priority4[0].User_Id__c, allocation.Approver_Manager__r.Id);
            }
        } else {
            System.assertEquals(project.Project_Manager__r.ManagerId, allocation.Approver_Manager__r.Id);
        }

    }
    private static List<Approval_Assigner_Settings_Details__mdt> getApprovalAssignerSettingsDetailsPriority4(Allocation__c allocation) {
        return [
                SELECT User_Id__c
                FROM Approval_Assigner_Settings_Details__mdt
                WHERE Station__c = :allocation.Station__c
                AND Department__c = NULL
                AND Resource_type__c = NULL
        ];
    }

    private static List<Approval_Assigner_Settings_Details__mdt> getApprovalAssignerSettingsDetailsPriority3(Allocation__c allocation) {
        return [
                SELECT User_Id__c
                FROM Approval_Assigner_Settings_Details__mdt
                WHERE Station__c = :allocation.Station__c
                AND Department__c = :allocation.Department_for_approve__c
                AND Resource_type__c = NULL
        ];
    }

    private static List<Approval_Assigner_Settings_Details__mdt> getApprovalAssignerSettingsDetailsPriority2(Allocation__c allocation) {
        return [
                SELECT User_Id__c
                FROM Approval_Assigner_Settings_Details__mdt
                WHERE Station__c = :allocation.Station__c
                AND Department__c = NULL
                AND Resource_type__c = :allocation.Resource_Type__c
        ];
    }

    private static List<Approval_Assigner_Settings_Details__mdt> getApprovalAssignerSettingsDetailsPriority1(Allocation__c allocation) {
        return [
                SELECT User_Id__c
                FROM Approval_Assigner_Settings_Details__mdt
                WHERE Station__c = :allocation.Station__c
                AND Department__c = :allocation.Department_for_approve__c
                AND Resource_type__c = :allocation.Resource_Type__c
        ];
    }

    private static Allocation__c getAllocationForTest() {
        return [
                SELECT Approver_Manager__r.Username
                        , Approver_Manager__r.Id
                        , Station__c
                        , Resource_Type__c
                        , Department_for_approve__c
                FROM Allocation__c
        ];
    }


}