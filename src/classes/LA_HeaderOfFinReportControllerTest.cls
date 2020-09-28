@IsTest
public with sharing class LA_HeaderOfFinReportControllerTest {
    private static final String TEST_NAME = 'TEST_NAME';
    private static final Integer FRIsSizeForBudgetElement = 12;
    private static final Integer YEAR = 2020;
    private static List<Business_Unit__c> businessUnits;
    private static Business_Unit__c businessUnit;
    private static Budget_Element__c parentBudgetElement;
    private static Budget_Element__c childBudgetElement;
    private static Financial_Report__c financialReport = new Financial_Report__c();
    private static Financial_Report__c generatedFinancialReport = new Financial_Report__c();
    private static Id budgetRecordTypeId = LA_BP_TestSetup.getBudgetElementRecordTypeId(LA_BP_Constants.GLOBAL_RECORD_TYPE);
    private static List<Financial_Report_Item__c> financialReportItems = new List<Financial_Report_Item__c>();
    private static final Date startDate = Date.newInstance(YEAR, LA_BP_Constants.JANUARY_MONTH, LA_BP_Constants.FIRST_DAY_OF_MONTH);
    private static final Date endDate = Date.newInstance(YEAR, LA_BP_Constants.DECEMBER_MONTH, LA_BP_Constants.LAST_DAY_OF_DECEMBER);

    @TestSetup
    public static void setup() {
        businessUnit = LA_BP_TestSetup.getBusinessUnit(TEST_NAME);
        businessUnit.Start_Date__c = startDate;
        businessUnit.Responsible_User__c = UserInfo.getUserId();
        insert businessUnit;

        financialReport = LA_BP_FinancialReportManager.getNewFinancialReport(businessUnit.Id, YEAR);
        insert financialReport;

        generatedFinancialReport = LA_BP_FinancialReportManager.getNewFinancialReport(businessUnit.Id, YEAR);
        generatedFinancialReport.Status__c = LA_BP_Constants.GENERATED;
        insert generatedFinancialReport;

        parentBudgetElement = LA_BP_TestSetup.getBudgetElement(budgetRecordTypeId,
                UserInfo.getUserId(),
                null,
                LA_BP_Constants.MONEY);
        insert parentBudgetElement;

        childBudgetElement = LA_BP_TestSetup.getBudgetElement(budgetRecordTypeId,
                UserInfo.getUserId(),
                parentBudgetElement.Id,
                LA_BP_Constants.MONEY);
        insert childBudgetElement;


        for (Integer i = 0; i < FRIsSizeForBudgetElement; i++) {
            Financial_Report_Item__c draftFinancialReportItem = new Financial_Report_Item__c();
            Financial_Report_Item__c sharedFinancialReportItem = new Financial_Report_Item__c();
            Financial_Report_Item__c autoCopyFinancialReportItem = new Financial_Report_Item__c();
            Financial_Report_Item__c notFinalFinancialReportItem = new Financial_Report_Item__c();
            Financial_Report_Item__c emptyFinancialReportItem = new Financial_Report_Item__c();

            draftFinancialReportItem.Cost_Center__c = businessUnit.Id;
            draftFinancialReportItem.GlobalStatus__c = LA_BP_Constants.DRAFT;
            draftFinancialReportItem.Budget_Element__c = childBudgetElement.Id;
            draftFinancialReportItem.Financial_Report__c = financialReport.Id;
            draftFinancialReportItem.StartDate__c = startDate;
            draftFinancialReportItem.EndDate__c = endDate;

            sharedFinancialReportItem.Cost_Center__c = businessUnit.Id;
            sharedFinancialReportItem.GlobalStatus__c = LA_BP_Constants.SHARED;
            sharedFinancialReportItem.Budget_Element__c = childBudgetElement.Id;
            sharedFinancialReportItem.Financial_Report__c = generatedFinancialReport.Id;
            sharedFinancialReportItem.StartDate__c = startDate;
            sharedFinancialReportItem.EndDate__c = endDate;

            autoCopyFinancialReportItem.Cost_Center__c = businessUnit.Id;
            autoCopyFinancialReportItem.GlobalStatus__c = LA_BP_Constants.AUTO_COPY;
            autoCopyFinancialReportItem.Budget_Element__c = childBudgetElement.Id;
            autoCopyFinancialReportItem.Financial_Report__c = generatedFinancialReport.Id;
            autoCopyFinancialReportItem.StartDate__c = startDate;
            autoCopyFinancialReportItem.EndDate__c = endDate;

            notFinalFinancialReportItem.Cost_Center__c = businessUnit.Id;
            notFinalFinancialReportItem.GlobalStatus__c = LA_BP_Constants.SHARED;
            notFinalFinancialReportItem.Budget_Element__c = childBudgetElement.Id;
            notFinalFinancialReportItem.Financial_Report__c = financialReport.Id;
            notFinalFinancialReportItem.StartDate__c = startDate;
            notFinalFinancialReportItem.EndDate__c = endDate;

            emptyFinancialReportItem.Cost_Center__c = businessUnit.Id;
            emptyFinancialReportItem.GlobalStatus__c = LA_BP_Constants.DRAFT;
            emptyFinancialReportItem.Budget_Element__c = childBudgetElement.Id;
            emptyFinancialReportItem.Financial_Report__c = null;
            emptyFinancialReportItem.StartDate__c = startDate;
            emptyFinancialReportItem.EndDate__c = endDate;

            financialReportItems.add(draftFinancialReportItem);
            financialReportItems.add(sharedFinancialReportItem);
            financialReportItems.add(autoCopyFinancialReportItem);
            financialReportItems.add(notFinalFinancialReportItem);
            financialReportItems.add(emptyFinancialReportItem);
        }

        insert financialReportItems;

    }

    @IsTest
    static void getListOfYearTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        Test.stopTest();

        List<Integer> years = LA_HeaderOfFinReportController.getListOfYear(businessUnit.Id);
        System.assertEquals(YEAR, years[0]);
    }

    @IsTest
    static void getHeaderWrapperForGlobalTest() {
        Test.startTest();
        insertGroupMember();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        Test.stopTest();

        LA_HeaderOfFinReportController.HeaderWrapper headerWrapper = LA_HeaderOfFinReportController.getHeaderWrapper(LA_BP_Constants.GLOBAL_PLANNING, YEAR);

        System.assertEquals(true, headerWrapper.isGlobalAvailable);
        System.assertEquals(true, headerWrapper.isCostCenterAvailable);
    }

    @IsTest
    static void getHeaderWrapperForCostCenterTest() {
        Test.startTest();
        insertGroupMember();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        Test.stopTest();

        LA_HeaderOfFinReportController.HeaderWrapper headerWrapper = LA_HeaderOfFinReportController.getHeaderWrapper(LA_BP_Constants.COST_CENTER_PLANNING, YEAR);

        System.assertEquals(true, headerWrapper.isGlobalAvailable);
        System.assertEquals(true, headerWrapper.isCostCenterAvailable);
    }

    private static void insertGroupMember() {
        Group globalGroup = new Group();
        globalGroup.Name = LA_BP_Constants.GLOBAL_GROUP;
        insert globalGroup;

        Group costCenterGroup = new Group();
        costCenterGroup.Name = LA_BP_Constants.COST_CENTER_GROUP;
        insert costCenterGroup;

        GroupMember groupMember = new GroupMember();
        groupMember.UserOrGroupId = UserInfo.getUserId();
        groupMember.GroupId = globalGroup.Id;
        insert groupMember;

        GroupMember groupMember2 = new GroupMember();
        groupMember2.UserOrGroupId = UserInfo.getUserId();
        groupMember2.GroupId = costCenterGroup.Id;
        insert groupMember2;
    }
}