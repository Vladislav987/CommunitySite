@IsTest
private class LA_BP_BudgetHierarchyWrapperTest {
    private static final String TEST_NAME = 'TEST_NAME';
    private static List<Business_Unit__c> businessUnits;
    private static Business_Unit__c businessUnit;
    private static Budget_Element__c parentBudgetElement;
    private static Budget_Element__c childBudgetElement;
    private static List<LA_BP_BudgetHierarchyWrapper> budgetHierarchyWrappers;
    private static Id budgetRecordTypeId = LA_BP_TestSetup.getBudgetElementRecordTypeId(LA_BP_Constants.GLOBAL_RECORD_TYPE);
    private static List<Financial_Report_Item__c> financialReportItems = new List<Financial_Report_Item__c>();

    @TestSetup
    static void setup() {
        businessUnit = LA_BP_TestSetup.getBusinessUnit(TEST_NAME);
        insert businessUnit;

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

    }

    @IsTest
    static void getBudgetHierarchyWrappersTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        Test.stopTest();
        budgetHierarchyWrappers = LA_BP_BudgetHierarchyWrapper.getBudgetHierarchyWrappers(LA_BP_Constants.GLOBAL_PLANNING);

        System.assertEquals(1, budgetHierarchyWrappers.size());
    }

    @IsTest
    static void getBudgetHierarchyWrappersCostCenterPlanningTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        Test.stopTest();
        budgetHierarchyWrappers = LA_BP_BudgetHierarchyWrapper.getBudgetHierarchyWrappers(LA_BP_Constants.COST_CENTER_PLANNING);

        System.assertEquals(1, budgetHierarchyWrappers.size());
    }
}