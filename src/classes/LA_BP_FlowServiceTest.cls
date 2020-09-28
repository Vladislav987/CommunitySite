@IsTest
private class LA_BP_FlowServiceTest {
    private static final String draftBusinessUnitName = 'draftBusinessUnit';
    private static final String generatedBusinessUnitName = 'generatedBusinessUnit';
    private static final String emptyBusinessUnitName = 'emptyBusinessUnit';
    private static final Integer FRIsSizeForBudgetElement = 12;
    private static final Integer numberOfMonth = 12;
    private static final Integer YEAR = 2020;
    private static List<Business_Unit__c> businessUnits = new List<Business_Unit__c>();
    private static Business_Unit__c draftBusinessUnit;
    private static Business_Unit__c emptyBusinessUnit;
    private static Business_Unit__c generatedBusinessUnit;
    private static Budget_Element__c parentBudgetElement;
    private static Budget_Element__c childBudgetElement;
    private static Financial_Report__c draftFinancialReport = new Financial_Report__c();
    private static Financial_Report__c generatedFinancialReport = new Financial_Report__c();
    private static Id budgetRecordTypeId = LA_BP_TestSetup.getBudgetElementRecordTypeId(LA_BP_Constants.GLOBAL_RECORD_TYPE);
    private static List<Financial_Report_Item__c> financialReportItems = new List<Financial_Report_Item__c>();
    private static final Date startDate = Date.newInstance(YEAR, LA_BP_Constants.JANUARY_MONTH, LA_BP_Constants.FIRST_DAY_OF_MONTH);
    private static final Date endDate = Date.newInstance(YEAR, LA_BP_Constants.DECEMBER_MONTH, LA_BP_Constants.LAST_DAY_OF_DECEMBER);

    @TestSetup
    public static void setup() {
        draftBusinessUnit = LA_BP_TestSetup.getBusinessUnit(draftBusinessUnitName);
        draftBusinessUnit.Start_Date__c = startDate;
        draftBusinessUnit.Responsible_User__c = UserInfo.getUserId();
        businessUnits.add(draftBusinessUnit);

        emptyBusinessUnit = LA_BP_TestSetup.getBusinessUnit(emptyBusinessUnitName);
        emptyBusinessUnit.Start_Date__c = startDate;
        emptyBusinessUnit.Responsible_User__c = UserInfo.getUserId();
        businessUnits.add(emptyBusinessUnit);

        generatedBusinessUnit = LA_BP_TestSetup.getBusinessUnit(generatedBusinessUnitName);
        generatedBusinessUnit.Start_Date__c = startDate;
        generatedBusinessUnit.Responsible_User__c = UserInfo.getUserId();
        businessUnits.add(generatedBusinessUnit);

        insert businessUnits;


        draftFinancialReport = LA_BP_FinancialReportManager.getNewFinancialReport(draftBusinessUnit.Id, YEAR);
        insert draftFinancialReport;

        generatedFinancialReport = LA_BP_FinancialReportManager.getNewFinancialReport(generatedBusinessUnit.Id, YEAR);
        generatedFinancialReport.Status__c = LA_BP_Constants.GENERATED;
        generatedFinancialReport.Report_Version_Number__c = 1;
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

        Integer sum = Integer.valueOf(Math.random() * 15000);

            for (Integer i = 0; i < FRIsSizeForBudgetElement; i++) {
                Financial_Report_Item__c draftFinancialReportItem = new Financial_Report_Item__c();
                Financial_Report_Item__c emptyFinancialReportItem = new Financial_Report_Item__c();
                Financial_Report_Item__c generatedFinancialReportItem = new Financial_Report_Item__c();
                Financial_Report_Item__c sharedVersion = new Financial_Report_Item__c();

                draftFinancialReportItem.Cost_Center__c = draftBusinessUnit.Id;
                draftFinancialReportItem.GlobalStatus__c = LA_BP_Constants.DRAFT;
                draftFinancialReportItem.Budget_Element__c = childBudgetElement.Id;
                draftFinancialReportItem.Financial_Report__c = draftFinancialReport.Id;
                draftFinancialReportItem.Sum__c = sum;
                draftFinancialReportItem.StartDate__c = startDate;
                draftFinancialReportItem.EndDate__c = endDate;

                sharedVersion.Cost_Center__c = draftBusinessUnit.Id;
                sharedVersion.GlobalStatus__c = LA_BP_Constants.SHARED;
                sharedVersion.Budget_Element__c = childBudgetElement.Id;
                sharedVersion.Financial_Report__c = draftFinancialReport.Id;
                sharedVersion.Sum__c = sum;
                sharedVersion.StartDate__c = startDate;
                sharedVersion.EndDate__c = endDate;

                emptyFinancialReportItem.Cost_Center__c = emptyBusinessUnit.Id;
                emptyFinancialReportItem.GlobalStatus__c = LA_BP_Constants.DRAFT;
                emptyFinancialReportItem.Budget_Element__c = childBudgetElement.Id;
                emptyFinancialReportItem.Financial_Report__c = null;
                emptyFinancialReportItem.Sum__c = sum;
                emptyFinancialReportItem.StartDate__c = startDate;
                emptyFinancialReportItem.EndDate__c = endDate;

                generatedFinancialReportItem.Cost_Center__c = generatedBusinessUnit.Id;
                generatedFinancialReportItem.GlobalStatus__c = LA_BP_Constants.SHARED;
                generatedFinancialReportItem.Budget_Element__c = childBudgetElement.Id;
                generatedFinancialReportItem.Financial_Report__c = generatedFinancialReport.Id;
                generatedFinancialReportItem.Sum__c = sum;
                generatedFinancialReportItem.StartDate__c = startDate;
                generatedFinancialReportItem.EndDate__c = endDate;

                financialReportItems.add(draftFinancialReportItem);
                financialReportItems.add(emptyFinancialReportItem);
                financialReportItems.add(generatedFinancialReportItem);
                financialReportItems.add(sharedVersion);
            }

        insert financialReportItems;
    }

    @IsTest
    public static void setSharedFlowTest() {

        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);

        for (Business_Unit__c businessUnit : businessUnits) {
            if(businessUnit.Name == draftBusinessUnitName) {
                draftBusinessUnit = businessUnit;
            }
        }


        LA_BudgetPlanningController.setCurrentFlow(LA_BP_Constants.SHARED, draftBusinessUnit.Id, YEAR, LA_BP_Constants.GLOBAL_PLANNING);

    }

    @IsTest
    public static void setDraftFlowTest() {

        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);

        for (Business_Unit__c businessUnit : businessUnits) {
            if(businessUnit.Name == draftBusinessUnitName) {
                draftBusinessUnit = businessUnit;
            }
        }
        LA_BudgetPlanningController.setCurrentFlow(LA_BP_Constants.DRAFT, draftBusinessUnit.Id, YEAR, LA_BP_Constants.GLOBAL_PLANNING);


    }

    @IsTest
    public static void setEmptyDraftFlowTest() {
        Business_Unit__c businessUnit = LA_BP_TestSetup.getBusinessUnit('NewBU');
        insert businessUnit;

        LA_BudgetPlanningController.setCurrentFlow(LA_BP_Constants.DRAFT, businessUnit.Id, YEAR, LA_BP_Constants.GLOBAL_PLANNING);

    }

    @IsTest
    public static void setGeneratedFlowTest() {
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        Financial_Report__c financialReport = [SELECT Id,Status__c,Report_Version_Number__c FROM Financial_Report__c WHERE Status__c = :LA_BP_Constants.GENERATED LIMIT 1];
        for (Business_Unit__c businessUnit : businessUnits) {
            if(businessUnit.Name == generatedBusinessUnitName) {
                generatedBusinessUnit = businessUnit;
            }
        }
        LA_BudgetPlanningController.setCurrentFlow('Generated v ' + financialReport.Report_Version_Number__c, generatedBusinessUnit.Id, YEAR, LA_BP_Constants.GLOBAL_PLANNING);

    }

    @IsTest
    public static void setDraftEmptyFlowCostCenterTest() {
        Business_Unit__c businessUnit = LA_BP_TestSetup.getBusinessUnit('NewBU');
        insert businessUnit;

        LA_BudgetPlanningController.setCurrentFlow(LA_BP_Constants.DRAFT, businessUnit.Id, YEAR, LA_BP_Constants.COST_CENTER_PLANNING);
    }

    @IsTest
    public static void setGeneratedFlowCostCenterTest() {
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        Financial_Report__c financialReport = [SELECT Id,Status__c,Report_Version_Number__c FROM Financial_Report__c WHERE Status__c = :LA_BP_Constants.GENERATED LIMIT 1];
        for (Business_Unit__c businessUnit : businessUnits) {
            if(businessUnit.Name == generatedBusinessUnitName) {
                generatedBusinessUnit = businessUnit;
            }
        }
        LA_BudgetPlanningController.setCurrentFlow('Generated v ' + financialReport.Report_Version_Number__c, generatedBusinessUnit.Id, YEAR, LA_BP_Constants.COST_CENTER_PLANNING);

    }


}