@IsTest
public with sharing class LA_BudgetPlanningControllerTest {
    private static final String draftBusinessUnitName = 'draftBusinessUnit';
    private static final String generatedBusinessUnitName = 'generatedBusinessUnit';
    private static final String emptyBusinessUnitName = 'emptyBusinessUnit';
    private static final String sharedBusinessUnitName = 'sharedBusinessUnit';
    private static final Integer FRIsSizeForBudgetElement = 12;
    private static final Integer numberOfMonth = 12;
    private static final Integer YEAR = 2020;
    private static List<Business_Unit__c> businessUnits = new List<Business_Unit__c>();
    private static Business_Unit__c draftBusinessUnit;
    private static Business_Unit__c emptyBusinessUnit;
    private static Business_Unit__c generatedBusinessUnit;
    private static Business_Unit__c sharedBusinessUnit;
    private static Budget_Element__c parentBudgetElement;
    private static Budget_Element__c childBudgetElement;
    private static Financial_Report__c draftFinancialReport = new Financial_Report__c();
    private static Financial_Report__c generatedFinancialReport = new Financial_Report__c();
    private static Financial_Report__c sharedFinancialReport = new Financial_Report__c();
    private static Financial_Report__c generatedFinancialReportForDraft = new Financial_Report__c();
    private static Id budgetRecordTypeId = LA_BP_TestSetup.getBudgetElementRecordTypeId(LA_BP_Constants.GLOBAL_RECORD_TYPE);
    private static List<Financial_Report_Item__c> financialReportItems = new List<Financial_Report_Item__c>();
    private static final Date startDate = Date.newInstance(YEAR, LA_BP_Constants.JANUARY_MONTH, LA_BP_Constants.FIRST_DAY_OF_MONTH);
    private static final Date endDate = Date.newInstance(YEAR, LA_BP_Constants.DECEMBER_MONTH, LA_BP_Constants.LAST_DAY_OF_DECEMBER);


    @TestSetup
    static void setup() {
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

        sharedBusinessUnit = LA_BP_TestSetup.getBusinessUnit(sharedBusinessUnitName);
        sharedBusinessUnit.Start_Date__c = startDate;
        sharedBusinessUnit.Responsible_User__c = UserInfo.getUserId();
        businessUnits.add(sharedBusinessUnit);

        insert businessUnits;


        draftFinancialReport = LA_BP_FinancialReportManager.getNewFinancialReport(draftBusinessUnit.Id, YEAR);
        draftFinancialReport.Report_Version_Number__c = 1;
        sharedFinancialReport.Status__c = LA_BP_Constants.DRAFT;
        insert draftFinancialReport;

        generatedFinancialReport = LA_BP_FinancialReportManager.getNewFinancialReport(generatedBusinessUnit.Id, YEAR);
        generatedFinancialReport.Status__c = LA_BP_Constants.GENERATED;
        generatedFinancialReport.Report_Version_Number__c = 1;
        insert generatedFinancialReport;

        generatedFinancialReportForDraft = LA_BP_FinancialReportManager.getNewFinancialReport(draftBusinessUnit.Id, YEAR);
        generatedFinancialReportForDraft.Status__c = LA_BP_Constants.GENERATED;
        generatedFinancialReportForDraft.Report_Version_Number__c = 1;
        insert generatedFinancialReportForDraft;

        sharedFinancialReport = LA_BP_FinancialReportManager.getNewFinancialReport(sharedBusinessUnit.Id, YEAR);
        sharedFinancialReport.Status__c = LA_BP_Constants.DRAFT;
        sharedFinancialReport.Report_Version_Number__c = 345;
        insert sharedFinancialReport;


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
            Financial_Report_Item__c sharedFinancialReportItem = new Financial_Report_Item__c();
            Financial_Report_Item__c generatedFinancialReportItemForDraft = new Financial_Report_Item__c();

            draftFinancialReportItem.Cost_Center__c = draftBusinessUnit.Id;
            draftFinancialReportItem.GlobalStatus__c = LA_BP_Constants.DRAFT;
            draftFinancialReportItem.Budget_Element__c = childBudgetElement.Id;
            draftFinancialReportItem.Financial_Report__c = draftFinancialReport.Id;
            draftFinancialReportItem.Sum__c = sum;
            draftFinancialReportItem.StartDate__c = startDate;
            draftFinancialReportItem.EndDate__c = endDate;

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

            generatedFinancialReportItemForDraft.Cost_Center__c = draftBusinessUnit.Id;
            generatedFinancialReportItemForDraft.GlobalStatus__c = LA_BP_Constants.AUTO_COPY;
            generatedFinancialReportItemForDraft.Budget_Element__c = childBudgetElement.Id;
            generatedFinancialReportItemForDraft.Financial_Report__c = generatedFinancialReport.Id;
            generatedFinancialReportItemForDraft.Sum__c = sum;
            generatedFinancialReportItemForDraft.StartDate__c = startDate;
            generatedFinancialReportItemForDraft.EndDate__c = endDate;

            sharedFinancialReportItem.Cost_Center__c = sharedBusinessUnit.Id;
            sharedFinancialReportItem.GlobalStatus__c = LA_BP_Constants.SHARED;
            sharedFinancialReportItem.Budget_Element__c = childBudgetElement.Id;
            sharedFinancialReportItem.Financial_Report__c = sharedFinancialReport.Id;
            sharedFinancialReportItem.Sum__c = sum;
            sharedFinancialReportItem.StartDate__c = startDate;
            sharedFinancialReportItem.EndDate__c = endDate;

            financialReportItems.add(draftFinancialReportItem);
            financialReportItems.add(emptyFinancialReportItem);
            financialReportItems.add(generatedFinancialReportItem);
            financialReportItems.add(sharedFinancialReportItem);
            financialReportItems.add(generatedFinancialReportItemForDraft);
        }

        insert financialReportItems;
    }

    @IsTest
    static void getMonthTest() {
        List<String> months = LA_BudgetPlanningController.getMonths();
        System.assertEquals(numberOfMonth, months.size());
    }

    @IsTest
    static void setCurrentFlowTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        draftBusinessUnit = businessUnits[0];
        Test.stopTest();
        for (Business_Unit__c businessUnit : businessUnits) {
            if (businessUnit.Name == draftBusinessUnitName) {
                draftBusinessUnit = businessUnit;
            }
        }

        LA_BudgetPlanningController.setCurrentFlow(LA_BP_Constants.DRAFT, draftBusinessUnit.Id, YEAR, LA_BP_Constants.GLOBAL_PLANNING);
        System.assertEquals(draftBusinessUnit.Id, LA_BudgetPlanningController.currentCostCenterId);
        System.assertEquals(YEAR, LA_BudgetPlanningController.selectedYear);
    }

    @IsTest
    static void editActionTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        Test.stopTest();

        for (Business_Unit__c businessUnit : businessUnits) {
            if (businessUnit.Name == draftBusinessUnitName) {
                draftBusinessUnit = businessUnit;
            }
        }

        LA_BudgetPlanningController.setCurrentFlow(LA_BP_Constants.DRAFT, draftBusinessUnit.Id, YEAR, LA_BP_Constants.GLOBAL_PLANNING);
        LA_BudgetPlanningController.editAction(YEAR, draftBusinessUnit.Id);
        List<Financial_Report_Item__c> financialReportItemsAfterEdit = [
                SELECT Id
                FROM Financial_Report_Item__c
                WHERE Financial_Report__c = null
                AND Cost_Center__c = :draftBusinessUnit.Id
        ];
        System.assertEquals(FRIsSizeForBudgetElement, financialReportItemsAfterEdit.size());
    }

    @IsTest
    static void editActionForCostCenterTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        Test.stopTest();

        for (Business_Unit__c businessUnit : businessUnits) {
            if (businessUnit.Name == generatedBusinessUnitName) {
                generatedBusinessUnit = businessUnit;
            }
        }

        LA_BudgetPlanningController.setCurrentFlow(LA_BP_Constants.DRAFT, generatedBusinessUnit.Id, YEAR, LA_BP_Constants.GLOBAL_PLANNING);
        LA_BudgetPlanningController.editCostCenterAction(YEAR, generatedBusinessUnit.Id);
        List<Financial_Report_Item__c> financialReportItemsAfterEdit = [
                SELECT Id
                FROM Financial_Report_Item__c
                WHERE Financial_Report__c = null
                AND Cost_Center__c = :generatedBusinessUnit.Id
        ];
        System.assertEquals(FRIsSizeForBudgetElement, financialReportItemsAfterEdit.size());
    }

    @IsTest
    static void generateActionTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        for (Business_Unit__c businessUnit : businessUnits) {
            if (businessUnit.Name == sharedBusinessUnitName) {
                sharedBusinessUnit = businessUnit;
            }
        }

        Test.stopTest();

        LA_BudgetPlanningController.generateAction(new List<Id>{
                sharedBusinessUnit.Id
        }, YEAR);
        String status = [SELECT Status__c FROM Financial_Report__c WHERE Cost_Center__c = :sharedBusinessUnit.Id].Status__c;
        System.assertEquals(LA_BP_Constants.GENERATED, status);
    }

    @IsTest
    static void generateValidationActionTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        for (Business_Unit__c businessUnit : businessUnits) {
            if (businessUnit.Name == sharedBusinessUnitName) {
                sharedBusinessUnit = businessUnit;
            }
        }

        Test.stopTest();

        LA_BudgetPlanningController.MessageFromValidation msg = LA_BudgetPlanningController.generateValidationAction(new List<Id>{
                sharedBusinessUnit.Id
        }, '1');
        System.assertEquals(true, msg.isPassValidation);
    }

    @IsTest
    static void generateValidationActionFailedTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        for (Business_Unit__c businessUnit : businessUnits) {
            if (businessUnit.Name == sharedBusinessUnitName) {
                sharedBusinessUnit = businessUnit;
            }
        }
        delete [SELECT id FROM Financial_Report_Item__c WHERE Cost_Center__c = :sharedBusinessUnit.Id];

        Test.stopTest();

        LA_BudgetPlanningController.MessageFromValidation msg = LA_BudgetPlanningController.generateValidationAction(new List<Id>{
                sharedBusinessUnit.Id
        }, '1');
        System.assertEquals(false, msg.isPassValidation);
    }

    @IsTest
    static void generateValidationActionFailed2Test() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        for (Business_Unit__c businessUnit : businessUnits) {
            if (businessUnit.Name == sharedBusinessUnitName) {
                sharedBusinessUnit = businessUnit;
            }
        }
        List<Financial_Report_Item__c> financialReportItems = [SELECT id FROM Financial_Report_Item__c WHERE Cost_Center__c = :sharedBusinessUnit.Id];
        financialReportItems[0].GlobalStatus__c = LA_BP_Constants.AUTO_COPY;
        update financialReportItems[0];
        Test.stopTest();

        LA_BudgetPlanningController.MessageFromValidation msg = LA_BudgetPlanningController.generateValidationAction(new List<Id>{
                sharedBusinessUnit.Id
        }, '1');
        System.assertEquals(false, msg.isPassValidation);
    }

    @IsTest
    static void shareActionTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        for (Business_Unit__c businessUnit : businessUnits) {
            if (businessUnit.Name == draftBusinessUnitName) {
                draftBusinessUnit = businessUnit;
            }
        }
        List<Financial_Report_Item__c> financialReportItems = [SELECT id FROM Financial_Report_Item__c WHERE Cost_Center__c = :draftBusinessUnit.Id];
        financialReportItems[0].GlobalStatus__c = LA_BP_Constants.AUTO_COPY;
        update financialReportItems[0];
        Test.stopTest();

        List<String> businessUnits = LA_BudgetPlanningController.shareAction(new List<Id>{
                draftBusinessUnit.Id
        });
        System.assertEquals(2, businessUnits.size());
    }

    @IsTest
    static void deleteActionGlobalTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        for (Business_Unit__c businessUnit : businessUnits) {
            if (businessUnit.Name == draftBusinessUnitName) {
                draftBusinessUnit = businessUnit;
            }
        }

        Test.stopTest();

        Boolean isDeleted = LA_BudgetPlanningController.deleteActionGlobal(String.valueOf(draftBusinessUnit.Id), new List<String>{
                'Draft'
        });

        List<Financial_Report_Item__c> financialReportItems = [SELECT Id,Sum__c FROM Financial_Report_Item__c WHERE Cost_Center__c = :draftBusinessUnit.Id];

        System.assertEquals(null, financialReportItems[0].Sum__c);
    }

    @IsTest
    static void deleteActionGlobal2Test() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        for (Business_Unit__c businessUnit : businessUnits) {
            if (businessUnit.Name == draftBusinessUnitName) {
                draftBusinessUnit = businessUnit;
            }
        }

        Test.stopTest();
        Boolean isDeleted = LA_BudgetPlanningController.deleteActionGlobal(String.valueOf(draftBusinessUnit.Id), new List<String>{
                'Draft', 'Shared'
        });
        List<Financial_Report_Item__c> financialReportItemsAfter = [
                SELECT Id,Sum__c
                FROM Financial_Report_Item__c
                WHERE Cost_Center__c = :draftBusinessUnit.Id
                AND GlobalStatus__c = :LA_BP_Constants.DRAFT
                AND Previous_Financial_Report_Item__c != null
        ];

        System.assertEquals(0, financialReportItemsAfter.size());
    }

    @IsTest
    static void deleteActionCostCenterTest() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        for (Business_Unit__c businessUnit : businessUnits) {
            if (businessUnit.Name == draftBusinessUnitName) {
                draftBusinessUnit = businessUnit;
            }
        }

        Test.stopTest();
        Boolean isDeleted = LA_BudgetPlanningController.deleteActionCostCenter(String.valueOf(draftBusinessUnit.Id), '0');

    }

    @IsTest
    static void deleteActionCostCenterTest2() {
        Test.startTest();
        businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        for (Business_Unit__c businessUnit : businessUnits) {
            if (businessUnit.Name == draftBusinessUnitName) {
                draftBusinessUnit = businessUnit;
            }
        }
        Financial_Report__c financialReport = [
                SELECT Report_Version_Number__c
                FROM Financial_Report__c
                WHERE Cost_Center__c =: draftBusinessUnit.Id
                AND Status__c =: LA_BP_Constants.DRAFT
        ];
        financialReport.Report_Version_Number__c = 2;
        update financialReport;


        Test.stopTest();
        Boolean isDeleted = LA_BudgetPlanningController.deleteActionCostCenter(String.valueOf(draftBusinessUnit.Id), '1');

    }

    @IsTest
    static void getCurrencyValuesTest() {
        List<String> currencies = LA_BudgetPlanningController.getCurrencyValues();
        System.assert(currencies.size() > 0);
    }
}