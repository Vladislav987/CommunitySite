@IsTest
private class LA_BP_FinancialReportItemManagerTest {
    private static final String TEST_NAME = 'TEST_NAME';
    private static final String USD = 'USD';
    private static final Integer FRIsSizeForBudgetElement = 12;
    private static final Integer YEAR = 2020;
    private static List<Business_Unit__c> businessUnits;
    private static Business_Unit__c businessUnit;
    private static Budget_Element__c parentBudgetElement;
    private static Budget_Element__c childBudgetElement;
    private static List<Budget_Element__c> budgetElements = new List<Budget_Element__c>();
    private static List<LA_BP_BudgetHierarchyWrapper> budgetHierarchyWrappers;
    private static List<Financial_Report__c> financialReports = new List<Financial_Report__c>();
    private static Financial_Report__c financialReport = new Financial_Report__c();
    private static Id budgetRecordTypeId = LA_BP_TestSetup.getBudgetElementRecordTypeId(LA_BP_Constants.GLOBAL_RECORD_TYPE);
    private static List<Financial_Report_Item__c> financialReportItems = new List<Financial_Report_Item__c>();

    @TestSetup
    static void setup() {
        businessUnit = LA_BP_TestSetup.getBusinessUnit(TEST_NAME);
        insert businessUnit;

        financialReport = LA_BP_FinancialReportManager.getNewFinancialReport(businessUnit.Id, YEAR);
        insert financialReport;

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
            Financial_Report_Item__c financialReportItem = new Financial_Report_Item__c();
            financialReportItem.Cost_Center__c = businessUnit.Id;
            financialReportItem.GlobalStatus__c = LA_BP_Constants.SHARED;
            financialReportItem.Budget_Element__c = childBudgetElement.Id;
            financialReportItem.Financial_Report__c = financialReport.Id;
            financialReportItems.add(financialReportItem);
        }
        insert financialReportItems;


    }

    @IsTest
    static void getLastNotFinalizedSharedVersionTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        financialReportItems = LA_BP_FinancialReportItemManager.getLastNotFinalizedSharedVersion(new List<Id>{
                businessUnit.Id
        });
        Test.stopTest();

        System.assertEquals(FRIsSizeForBudgetElement, financialReportItems.size());
    }

    @IsTest
    static void getDraftFRIsForEveryBudgetElementTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        Test.stopTest();
        businessUnit = businessUnits[0];
        budgetHierarchyWrappers = LA_BP_BudgetHierarchyWrapper.getBudgetHierarchyWrappers(LA_BP_Constants.GLOBAL_PLANNING);
        financialReportItems = LA_BP_FinancialReportItemManager.getDraftFRIsForEveryBudgetElement(businessUnit.Id, YEAR, budgetHierarchyWrappers, USD);

        System.assertEquals(FRIsSizeForBudgetElement, financialReportItems.size());
    }

    @IsTest
    static void getFinancialReportItemTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        financialReports = LA_BP_DataSelector.getFinancialReports(new List<Id>{
                businessUnit.Id
        }, new List<String>{
                LA_BP_Constants.DRAFT
        });
        financialReport = financialReports[0];
        budgetElements = LA_BP_DataSelector.getAllBudgetElements();
        Test.stopTest();

        Budget_Element__c cBudgetElement;
        for (Budget_Element__c bu : budgetElements) {
            if (bu.Parent_Cost_Element__c == null) {
                cBudgetElement = bu;
            }
        }

        businessUnit = businessUnits[0];
        Financial_Report_Item__c financialReportItem = LA_BP_FinancialReportItemManager.getFinancialReportItem(
                businessUnit.Id,
                cBudgetElement,
                financialReport,
                YEAR,
                1,
                LA_BP_Constants.DRAFT,
                USD
        );
        Date startDate = Date.newInstance(YEAR, LA_BP_Constants.JANUARY_MONTH, LA_BP_Constants.FIRST_DAY_OF_MONTH);
        Date endDate = Date.newInstance(YEAR, LA_BP_Constants.JANUARY_MONTH, LA_BP_Constants.LAST_DAY_OF_DECEMBER);

        System.assertEquals(LA_BP_Constants.DRAFT, financialReportItem.GlobalStatus__c);
        System.assertEquals(businessUnit.Id, financialReportItem.Cost_Center__c);
        System.assertEquals(cBudgetElement.Id, financialReportItem.Budget_Element__c);
        System.assertEquals(financialReport.Id, financialReportItem.Financial_Report__c);
        System.assertEquals(USD, financialReportItem.CurrencyIsoCode);
        System.assertEquals(startDate, financialReportItem.StartDate__c);
        System.assertEquals(endDate, financialReportItem.EndDate__c);

    }

    @IsTest
    static void setFinancialReportItemsForBudgetElementsTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        budgetHierarchyWrappers = LA_BP_BudgetHierarchyWrapper.getBudgetHierarchyWrappers(LA_BP_Constants.GLOBAL_PLANNING);
        financialReportItems = LA_BP_FinancialReportItemManager.getLastNotFinalizedSharedVersion(new List<Id>{
                businessUnit.Id
        });
        Test.stopTest();

        LA_BP_FinancialReportItemManager.setFinancialReportItemsForBudgetElements(budgetHierarchyWrappers, financialReportItems);

        List<LA_BP_BudgetHierarchyWrapper> childBudgetHierarchyWrappers = budgetHierarchyWrappers.get(0).budgetHierarchyItems;
        System.assertEquals(FRIsSizeForBudgetElement,childBudgetHierarchyWrappers.get(0).financialReportItems.size());

    }

    @IsTest
    static void getUpdatedFinancialReportItemsTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        budgetHierarchyWrappers = LA_BP_BudgetHierarchyWrapper.getBudgetHierarchyWrappers(LA_BP_Constants.GLOBAL_PLANNING);
        financialReportItems = LA_BP_FinancialReportItemManager.getLastNotFinalizedSharedVersion(new List<Id>{
                businessUnit.Id
        });
        Test.stopTest();

        List<Financial_Report_Item__c> financialReportItemsFromForm = LA_BP_FinancialReportItemManager.getLastNotFinalizedSharedVersion(new List<Id>{
                businessUnit.Id
        });

        for (Financial_Report_Item__c financialReportItem : financialReportItemsFromForm) {
            financialReportItem.Sum__c = Integer.valueOf(Math.random() * 15000);
        }

        Map<String, Financial_Report_Item__c> financialReportItemsFromFormByKey = LA_BP_ActionService.getFinancialReportItemsByKey(financialReportItemsFromForm);
        Map<String, Financial_Report_Item__c> financialReportItemsForInsertByKey = LA_BP_ActionService.getFinancialReportItemsByKey(financialReportItems);

        financialReportItems = LA_BP_FinancialReportItemManager.getUpdatedFinancialReportItems(financialReportItemsForInsertByKey,financialReportItemsFromFormByKey,false);

        for (Financial_Report_Item__c financialReportItem : financialReportItems) {
            System.assert(financialReportItem.Sum__c != null);
        }
    }

    @IsTest
    static void getFinancialReportItemsForEveryBudgetElementTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        budgetHierarchyWrappers = LA_BP_BudgetHierarchyWrapper.getBudgetHierarchyWrappers(LA_BP_Constants.GLOBAL_PLANNING);
        financialReportItems = LA_BP_FinancialReportItemManager.getLastNotFinalizedSharedVersion(new List<Id>{
                businessUnit.Id
        });
        Test.stopTest();
        List<LA_BP_BudgetHierarchyWrapper> childBudgetHierarchyWrappers = budgetHierarchyWrappers.get(0).budgetHierarchyItems;
        List<Budget_Element__c> budgetElements = new List<Budget_Element__c>{childBudgetHierarchyWrappers.get(0).budgetElement};

        financialReportItems = LA_BP_FinancialReportItemManager.getFinancialReportItemsForEveryBudgetElement(YEAR,
                financialReport,
                null,
                budgetElements,
                USD
        );

        System.assertEquals(FRIsSizeForBudgetElement, financialReportItems.size());
    }

    @IsTest
    static void setInfoFromPreviousFinReportTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        budgetHierarchyWrappers = LA_BP_BudgetHierarchyWrapper.getBudgetHierarchyWrappers(LA_BP_Constants.GLOBAL_PLANNING);
        financialReportItems = LA_BP_FinancialReportItemManager.getLastNotFinalizedSharedVersion(new List<Id>{
                businessUnit.Id
        });
        List<Financial_Report__c> financialReports = LA_BP_DataSelector.getFinancialReports(new List<Id>{businessUnit.Id},
                new List<String>{LA_BP_Constants.DRAFT });
        financialReport = financialReports[0];
        Test.stopTest();

        for(Financial_Report_Item__c financialReportItem : financialReportItems) {
            financialReportItem.Sum__c = Integer.valueOf(Math.random() * 15000);
        }
        Financial_Report_Item__c financialReportItem = financialReportItems[0];
        LA_BP_FinancialReportItemManager.setInfoFromPreviousFinReport(financialReportItem, financialReport);

        System.assertEquals(financialReport.Financial_Report_Items__r[0].Sum__c, financialReportItem.Sum__c);
    }
}