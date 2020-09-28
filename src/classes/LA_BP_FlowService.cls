public with sharing class LA_BP_FlowService {
    public String version;
    public Id costCenterId;
    public Integer year;
    public List<LA_BP_BudgetHierarchyWrapper> budgetHierarchyWrappers;
    public String name;
    public String currentForm;


    public LA_BP_FlowService(String version, Id costCenterId, Integer year, String currentForm) {
        this.version = version;
        this.costCenterId = costCenterId;
        this.year = year;
        this.currentForm = currentForm;

        setCurrentFlow(this.currentForm);
    }

    public void setCurrentFlow(String currentForm) {
        List<Id> costCenterIds = new List<Id>{
                costCenterId
        };
        budgetHierarchyWrappers = LA_BP_BudgetHierarchyWrapper.getBudgetHierarchyWrappers(currentForm);
        List<Financial_Report_Item__c> currentFinancialReportItems = new List<Financial_Report_Item__c>();
        if (currentForm == LA_BP_Constants.GLOBAL_PLANNING) {
            if (version == LA_BP_Constants.DRAFT) {
                currentFinancialReportItems = LA_BP_DataSelector.getDraftFinancialReportItemsByResponsibleUser(costCenterIds);
                
                if (currentFinancialReportItems.size() > 0) {
                    name = 'Work with draft';
                } else {
                    String currencyFromBU = LA_BP_DataSelector.getCurrencyFromBU(costCenterId);
                    currentFinancialReportItems = LA_BP_FinancialReportItemManager.getDraftFRIsForEveryBudgetElement(costCenterId, year, budgetHierarchyWrappers, currencyFromBU);
                    insert currentFinancialReportItems;
                    name = 'Work with Draft';
                }
            } else {
                if (version == LA_BP_Constants.SHARED) {
                    currentFinancialReportItems = LA_BP_FinancialReportItemManager.getLastNotFinalizedSharedVersion(costCenterIds);
                    if (currentFinancialReportItems.size() > 0) {
                        if (LA_BP_DataSelector.getDraftFromShared(costCenterId).size() > 0 && version == 'Draft') {
                            currentFinancialReportItems = LA_BP_DataSelector.getDraftFromShared(costCenterId);
                            name = 'Work with last shared version';
                        }
                    }
                } else {

                    if (version.contains(LA_BP_Constants.GENERATED)) {
                        List<Financial_Report__c> generatedFinancialReports = getGeneratedFinancialReports(costCenterIds, version);
                        if (generatedFinancialReports.size() > 0) {
                            currentFinancialReportItems = LA_BP_DataSelector.getFinancialReportItemsByFinancialReport(new List<Id>{
                                    generatedFinancialReports[0].Id
                            });
                            name = 'Work with generated version';
                        }
                    }
                }
            }
        } else if (currentForm == LA_BP_Constants.COST_CENTER_PLANNING) {
            if (version == LA_BP_Constants.DRAFT) {
                List<Financial_Report__c> draftFinancialReports =
                        LA_BP_FinancialReportManager.getFinancialReportsByYear(
                                year
                                , costCenterIds
                                , new List<String>{
                                        LA_BP_Constants.DRAFT
                                });
                if (draftFinancialReports.size() > 0) {
                    List<Id> financialReportsIds = new List<Id>();
                    for (Financial_Report__c financialReport : draftFinancialReports) {
                        financialReportsIds.add(financialReport.Id);
                    }
                    currentFinancialReportItems = LA_BP_DataSelector.getFinancialReportItemsByFinancialReport(financialReportsIds);

                    name = 'Work with draft';
                } else {
                    List<Budget_Element__c> allChildBudgetElements = LA_BudgetPlanningController.getChildBudgetElements();
                    String currencyFromBU = LA_BP_DataSelector.getCurrencyFromBU(costCenterId);
                    Financial_Report__c newFinancialReport = LA_BP_FinancialReportManager.getNewFinancialReport(costCenterId, year);
                    newFinancialReport.Report_Version_Number__c = 1;
                    newFinancialReport.Is_Report_Last__c = true;
                    insert newFinancialReport;

                    List<Financial_Report_Item__c> draftFinancialReportItems =
                            LA_BP_FinancialReportItemManager.getFinancialReportItemsForEveryBudgetElement(
                                    year
                                    , newFinancialReport
                                    , null
                                    , allChildBudgetElements
                                    , currencyFromBU);

                    insert draftFinancialReportItems;
                    currentFinancialReportItems = draftFinancialReportItems;
                }
            } else {
                if (version.contains(LA_BP_Constants.GENERATED)) {
                    List<Financial_Report__c> generatedFinancialReports = getGeneratedFinancialReports(costCenterIds, version);

                    if (generatedFinancialReports.size() > 0) {

                        currentFinancialReportItems = LA_BP_DataSelector.getFinancialReportItemsByFinancialReport(new List<Id>{
                                generatedFinancialReports[0].Id
                        });

                        name = 'Work with generated version';
                    }
                }
            }
        }
        LA_BP_FinancialReportItemManager.setFinancialReportItemsForBudgetElements(budgetHierarchyWrappers, currentFinancialReportItems);
    }

    private static List<Financial_Report__c> getGeneratedFinancialReportsByVersion(List<Id> costCenterIds, Decimal versionNumber) {
        return [
                SELECT Id,
                        Cost_Center__c,
                        Status__c,
                        StartDate__c,
                        EndDate__c,
                        Report_Version_Number__c, (
                        SELECT Id,
                                StartDate__c,
                                EndDate__c,
                                Budget_Element__c,
                                Sum__c,
                                Count__c,
                                Cost_Center__c,
                                CurrencyIsoCode,
                                Budget_Element__r.RecordType.DeveloperName
                        FROM Financial_Report_Items__r
                )
                FROM Financial_Report__c
                WHERE Cost_Center__c IN :costCenterIds
                AND Status__c = :LA_BP_Constants.GENERATED
                AND Report_Version_Number__c = :versionNumber
                LIMIT 1
        ];
    }

    private static Boolean isVersionContainsNumber(String version) {
        return version.replaceAll('[^0-9]', '') != '';
    }

    private static List<Financial_Report__c> getGeneratedFinancialReports(List<Id> costCenterIds, String version) {
        List<Financial_Report__c> generatedFinancialReports = new List<Financial_Report__c>();
        Decimal versionNumber = 1;
        if (isVersionContainsNumber(version)) {
            versionNumber = Decimal.valueOf(version.replaceAll('[^0-9]', ''));
            generatedFinancialReports = getGeneratedFinancialReportsByVersion(costCenterIds, versionNumber);
        }

        return generatedFinancialReports;
    }

}