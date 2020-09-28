public with sharing class LA_BP_TestSetup {
    public static final String TEST_WORD = 'test';
    public static final String EMAIL = 'test@test.com';
    public static final String COST_CENTER = 'Cost_Center';
    public static final String COST_CENTER_RT = 'Cost Center';
    public static final String EN_US = 'en_US';
    public static final String AMERICA_LOS_ANGELES = 'America/Los_Angeles';
    public static final String UTF_8 = 'UTF-8';
    public static final String SYS_ADMIN = 'System Administrator';


    public static Business_Unit__c getBusinessUnit(String name) {
        Profile profile = getProfile(SYS_ADMIN);
        User user = getUser(profile);

        Id businessUnitRecordTypeId = Schema.SObjectType.Business_Unit__c
                .getRecordTypeInfosByName()
                .get('Cost Center')
                .getRecordTypeId();


        Business_Unit__c businessUnit = new Business_Unit__c();
        businessUnit.Name = name;
        businessUnit.Responsible_User__c = user.Id;
        businessUnit.RecordTypeId = businessUnitRecordTypeId;
        businessUnit.Hierarchy_area__c = TEST_WORD;
        businessUnit.Company_code__c = TEST_WORD;
        businessUnit.Cost_center__c = TEST_WORD;

        return businessUnit;
    }

    public static Profile getProfile(String profileName) {
        return [
                SELECT Id
                FROM Profile
                WHERE Name = :profileName
        ];
    }

    public static User getUser(Profile profile) {
        String orgId = UserInfo.getOrganizationId();
        String userName = TEST_WORD + '@test' + orgId + '.org';

        User user = new User();
        user.Alias = TEST_WORD;
        user.Email = EMAIL;
        user.LastName = TEST_WORD;
        user.LanguageLocaleKey = EN_US;
        user.EmailEncodingKey = UTF_8;
        user.LocaleSidKey = EN_US;
        user.ProfileId = profile.Id;
        user.TimeZoneSidKey = AMERICA_LOS_ANGELES;
        user.Username = userName;

        return user ;
    }

    public static Id getBudgetElementRecordTypeId(String recordTypeName) {
        return Schema.SObjectType.Budget_Element__c
                .getRecordTypeInfosByName()
                .get(recordTypeName)
                .getRecordTypeId();
    }

    public static Budget_Element__c getBudgetElement(Id recordTypeId, Id userId, Id parent, String calcType) {
        return new Budget_Element__c(
                Parent_Cost_Element__c = parent,
                RecordTypeId = recordTypeId,
                Responsible_User__c = userId,
                Is_Active__c = true,
                Calculation_Type__c = calcType
        );
    }
}