@IsTest
public with sharing class LA_BP_DataSelectorTest {
    private static final String TEST_NAME = 'TEST_NAME';
    private static final String USD = 'USD';
    private static final Integer FRIsSizeForBudgetElement = 12;
    private static final Integer YEAR = 2020;
    private static Business_Unit__c businessUnit;
    private static Budget_Element__c budgetElement;
    private static List<Budget_Element__c> budgetElements;
    private static List<Business_Unit__c> businessUnits;
    private static List<Financial_Report__c> financialReports;
    private static Financial_Report__c financialReport;
    private static Id budgetRecordTypeId = LA_BP_TestSetup.getBudgetElementRecordTypeId(LA_BP_Constants.GLOBAL_RECORD_TYPE);
    private static List<Financial_Report_Item__c> financialReportItems = new List<Financial_Report_Item__c>();

    @TestSetup
    static void setup() {
        businessUnit = LA_BP_TestSetup.getBusinessUnit(TEST_NAME);
        businessUnit.CurrencyIsoCode = USD;
        insert businessUnit;

        financialReport = LA_BP_FinancialReportManager.getNewFinancialReport(businessUnit.Id, YEAR);
        insert financialReport;

        budgetElement = LA_BP_TestSetup.getBudgetElement(budgetRecordTypeId,
                UserInfo.getUserId(),
                null,
                LA_BP_Constants.MONEY);

        insert budgetElement;


        for(Integer i = 0; i < FRIsSizeForBudgetElement; i++) {
            Financial_Report_Item__c financialReportItem = new Financial_Report_Item__c();
            financialReportItem.Cost_Center__c = businessUnit.Id;
            financialReportItem.GlobalStatus__c = LA_BP_Constants.DRAFT;
            financialReportItem.Budget_Element__c = budgetElement.Id;
            financialReportItem.Financial_Report__c = financialReport.Id;
            financialReportItems.add(financialReportItem);
        }

        insert financialReportItems;
    }

    @IsTest
    static void getBudgetElementTest() {
        Test.startTest();
        List<Budget_Element__c> budgetElements = LA_BP_DataSelector.getAllBudgetElements();
        Test.stopTest();

        System.assertEquals(1, budgetElements.size());
    }

    @IsTest
    static void getBusinessUnitsForCurrentUserTest() {

        Test.startTest();
        List<Business_Unit__c> businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        Test.stopTest();

        System.assertEquals(1, businessUnits.size());
    }

    @IsTest
    static void getDraftFinancialReportItemsByResponsibleUserTest() {

        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        List<Financial_Report_Item__c> resultFinancialReportItems = LA_BP_DataSelector.getDraftFinancialReportItemsByResponsibleUser(new List<Id>{businessUnit.Id});
        Test.stopTest();

        System.assertEquals(FRIsSizeForBudgetElement, resultFinancialReportItems.size());
    }

    @IsTest
    static void getFinancialReportItemsByFinancialReportTest() {

        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        financialReports = LA_BP_DataSelector.getFinancialReports(new List<Id>{
                businessUnit.Id
        }, new List<String>{
                LA_BP_Constants.DRAFT
        });
        financialReport = financialReports[0];
        List<Financial_Report_Item__c> resultFinancialReportItems = LA_BP_DataSelector.getFinancialReportItemsByFinancialReport(new List<Id>{financialReport.Id});
        Test.stopTest();

        System.assertEquals(FRIsSizeForBudgetElement, resultFinancialReportItems.size());
    }

    @IsTest
    static void getFinancialReportItemsForCostCenterTest() {

        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        financialReports = LA_BP_DataSelector.getFinancialReports(new List<Id>{
                businessUnit.Id
        }, new List<String>{
                LA_BP_Constants.DRAFT
        });
        List<Financial_Report_Item__c> resultFinancialReportItems = LA_BP_DataSelector.getFinancialReportItemsForCostCenter(
                businessUnit.Id, LA_BP_Constants.GLOBAL_PLANNING
        );
        Test.stopTest();

        System.assertEquals(FRIsSizeForBudgetElement, resultFinancialReportItems.size());
    }

    @IsTest
    static void getFinancialReportItemsTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];

        List<Financial_Report_Item__c> resultFinancialReportItems = LA_BP_DataSelector.getFinancialReportItems(
                new List<Id>{businessUnit.Id},
                new List<String>{LA_BP_Constants.DRAFT},
                LA_BP_Constants.DRAFT
        );
        Test.stopTest();

        System.assertEquals(FRIsSizeForBudgetElement, resultFinancialReportItems.size());
    }

    @IsTest
    static void getFinancialReportsTest() {

        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];

        List<Financial_Report__c> resultFinancialReports = LA_BP_DataSelector.getFinancialReports(
                new List<Id>{businessUnit.Id},
                new List<String>{LA_BP_Constants.DRAFT}
        );
        Test.stopTest();

        System.assertEquals(1, resultFinancialReports.size());
    }

    @IsTest
    static void getBudgetPlanningBatchTest() {
        BudgetPlanningBatch__c budgetPlanningBatch = new BudgetPlanningBatch__c();
        budgetPlanningBatch.LastBatchJobId__c = 'AAAAAAAAAAAAAAAAA';
        insert budgetPlanningBatch;

        Test.startTest();
        List<BudgetPlanningBatch__c> budgetPlanningBatchResult = LA_BP_DataSelector.getBudgetPlanningBatchJobs();
        Test.stopTest();

        System.assertEquals('AAAAAAAAAAAAAAAAA', budgetPlanningBatchResult[0].LastBatchJobId__c);
    }

    @IsTest
    static void getDraftFromSharedTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        financialReports = LA_BP_DataSelector.getFinancialReports(new List<Id>{
                businessUnit.Id
        }, new List<String>{
                LA_BP_Constants.DRAFT
        });
        List<Financial_Report_Item__c> resultFinancialReportItems = LA_BP_DataSelector.getDraftFromShared(businessUnit.Id);
        Test.stopTest();

        System.assertEquals(FRIsSizeForBudgetElement, resultFinancialReportItems.size());
    }


    @IsTest
    static void getFinancialReportItemsFromFormTest() {

        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        updateFinancialReportItemsToShared(true, LA_BP_Constants.DRAFT);
        List<Financial_Report_Item__c> resultFinancialReportItems = LA_BP_DataSelector.getFinancialReportItemsFromForm(new List<Id>{businessUnit.Id}, UserInfo.getUserId());
        Test.stopTest();

        System.assertEquals(FRIsSizeForBudgetElement, resultFinancialReportItems.size());
    }

    @IsTest
    static void getFinancialReportItemsForUpdateTest() {

        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        financialReports = LA_BP_DataSelector.getFinancialReports(new List<Id>{
                businessUnit.Id
        }, new List<String>{
                LA_BP_Constants.DRAFT
        });
        updateFinancialReportItemsToShared(false, LA_BP_Constants.SHARED);
        List<Financial_Report_Item__c> resultFinancialReportItems = LA_BP_DataSelector.getFinancialReportItemsForUpdate(new List<Id>{businessUnit.Id});
        Test.stopTest();

        System.assertEquals(FRIsSizeForBudgetElement, resultFinancialReportItems.size());
    }

    @IsTest
    static void getMaxAndMinYearTest() {

        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        financialReports = LA_BP_DataSelector.getFinancialReports(new List<Id>{
                businessUnit.Id
        }, new List<String>{
                LA_BP_Constants.DRAFT
        });
        updateFinancialReportItemsToShared(false, LA_BP_Constants.SHARED);
        List<AggregateResult> aggregateResults = LA_BP_DataSelector.getMaxAndMinYear(businessUnit.Id);
        Test.stopTest();

        Datetime maxDate = (Datetime) aggregateResults[0].get('max');
        Datetime minDate = (Datetime) aggregateResults[0].get('min');

        System.assertEquals(System.Date.today(),maxDate);
        System.assertEquals(System.Date.today() + 1,minDate);
    }


    @IsTest
    static void getCurrencyFromBUTest() {

        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        String ISOCode = LA_BP_DataSelector.getCurrencyFromBU(businessUnit.Id);
        Test.stopTest();

        System.assertEquals(USD, ISOCode);
    }


    @IsTest
    static void getCountOfEmptySumTest() {

        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        budgetElements = LA_BP_DataSelector.getAllBudgetElements();
        Integer numberOfEmptyFinancialReportItems = LA_BP_DataSelector.getCountOfEmptySum(new List<Id>{businessUnit.Id});
        Test.stopTest();

        System.assertEquals(FRIsSizeForBudgetElement,numberOfEmptyFinancialReportItems);

    }

    @IsTest
    static void getCostCentersForShareTest() {

        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        budgetElements = LA_BP_DataSelector.getAllBudgetElements();
        List<AggregateResult> aggregateResults = LA_BP_DataSelector.getCostCentersForShare( LA_BP_Constants.DRAFT);
        Test.stopTest();

        System.assertEquals(TEST_NAME, aggregateResults[0].get('csName'));

    }

    @IsTest
    static void getCountOfBUWithFillFRIsTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        budgetElements = LA_BP_DataSelector.getAllBudgetElements();
        Integer numberOfFRIs = LA_BP_DataSelector.getCountOfBUWithFillFRIs(new List<Id>{businessUnit.Id});
        Test.stopTest();

        System.assertEquals(1, numberOfFRIs);

    }

    @IsTest
    static void getCountOfEmptySumAndDummyStatusTest() {

        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        budgetElements = LA_BP_DataSelector.getAllBudgetElements();
        updateFinancialReportItemsToShared(false, LA_BP_Constants.DUMMY);
        Integer numberOfFRIs = LA_BP_DataSelector.getCountOfAutoCopyOrDummyStatus(new List<Id>{businessUnit.Id});
        Test.stopTest();

        System.assertEquals(12, numberOfFRIs);

    }

    @IsTest
    static void getCostCentersForGenerationTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        budgetElements = LA_BP_DataSelector.getAllBudgetElements();
        updateFinancialReportItemsToShared(false, LA_BP_Constants.SHARED);
        List<AggregateResult> aggregateResults = LA_BP_DataSelector.getCostCentersForGeneration(
                LA_BP_Constants.SHARED, new List<Id>{businessUnit.Id});
        Test.stopTest();

        System.assertEquals(TEST_NAME, aggregateResults[0].get('csName'));
    }

    @IsTest
    static void getCountOfEmptySumForCostCenterTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        businessUnit = businessUnits[0];
        budgetElements = LA_BP_DataSelector.getAllBudgetElements();
        updateFinancialReportItemsToShared(false, null);
        List<AggregateResult> aggregateResults = LA_BP_DataSelector.getCostCentersForGeneration(
                LA_BP_Constants.SHARED, new List<Id>{businessUnit.Id});
        Test.stopTest();

        System.assertEquals(TEST_NAME, aggregateResults[0].get('csName'));
    }

    private static void updateFinancialReportItemsToShared(Boolean isFinRepNull, String status) {
        List<Financial_Report_Item__c> financialReportItemsForUpdate = [SELECT GlobalStatus__c FROM Financial_Report_Item__c];
        for (Financial_Report_Item__c financialReportItem : financialReportItemsForUpdate) {
            financialReportItem.StartDate__c = System.Date.today();
            financialReportItem.EndDate__c = System.Date.today() + 1;
            if(isFinRepNull) {
                financialReportItem.Financial_Report__c = null;
            }
            financialReportItem.GlobalStatus__c = status;
        }
        update financialReportItemsForUpdate;
    }


}