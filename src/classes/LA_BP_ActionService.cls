public with sharing class LA_BP_ActionService {

    private static List<Financial_Report_Item__c> financialReportItemsForDelete = new List<Financial_Report_Item__c>();
    private static List<Financial_Report_Item__c> financialReportItemsForInsert = new List<Financial_Report_Item__c>();
    private static List<Financial_Report_Item__c> financialReportItemsForUpdate = new List<Financial_Report_Item__c>();

    public static void shareAction(List<Id> costCenterIds, Integer selectedYear, Map<Id, Id> responsibleUsersIds,String currentUserId) {
        List<Budget_Element__c> allChildBudgetElements = LA_BudgetPlanningController.getChildBudgetElements();

        List<Financial_Report__c> newFinancialReportsByCostCenter = new List<Financial_Report__c>();
        Map<Id, Financial_Report__c> draftFinancialReportsByCostCenter = new Map<Id, Financial_Report__c>();
        Map<Id, Financial_Report__c> generatedFinancialReportsByCostCenter = new Map<Id, Financial_Report__c>();
        List<Id> emptyCostCenters = new List<Id>();

        setValuesForShareCostCenter(costCenterIds, draftFinancialReportsByCostCenter, generatedFinancialReportsByCostCenter, emptyCostCenters, selectedYear);

        if (draftFinancialReportsByCostCenter.size() > 0) {
            List<Id> ids = new List<Id>(draftFinancialReportsByCostCenter.keySet());
            financialReportItemsForDelete = LA_BP_DataSelector.getFinancialReportItemsFromForm(ids,currentUserId);
            financialReportItemsForUpdate = LA_BP_DataSelector.getFinancialReportItemsForUpdate(ids);

            Map<String, Financial_Report_Item__c> financialReportItemsFromFormByKey = getFinancialReportItemsByKey(financialReportItemsForDelete);
            Map<String, Financial_Report_Item__c> financialReportItemsForUpdateByKey = getFinancialReportItemsByKey(financialReportItemsForUpdate);

            financialReportItemsForUpdate = LA_BP_FinancialReportItemManager.getUpdatedFinancialReportItems(financialReportItemsForUpdateByKey, financialReportItemsFromFormByKey, true);
        }

        if (emptyCostCenters.size() > 0) {
            setNewFinancialReports(emptyCostCenters
                    , newFinancialReportsByCostCenter
                    , null
                    , selectedYear, responsibleUsersIds);
            setNewFinancialReportItems(selectedYear
                    , newFinancialReportsByCostCenter
                    , financialReportItemsForInsert
                    , allChildBudgetElements
                    , null);
        }

        if (generatedFinancialReportsByCostCenter.size() > 0) {
            setNewFinancialReports(new List<Id>(generatedFinancialReportsByCostCenter.keySet())
                    , newFinancialReportsByCostCenter
                    , generatedFinancialReportsByCostCenter
                    , selectedYear, responsibleUsersIds);
            setNewFinancialReportItems(selectedYear
                    , newFinancialReportsByCostCenter
                    , financialReportItemsForInsert
                    , allChildBudgetElements
                    , generatedFinancialReportsByCostCenter);
        }

        if (emptyCostCenters.size() > 0 || generatedFinancialReportsByCostCenter.size() > 0) {
            List<Id> costCenterIdsForCreate = new List<Id>();
            costCenterIdsForCreate.addAll(emptyCostCenters);
            costCenterIdsForCreate.addAll(generatedFinancialReportsByCostCenter.keySet());

            financialReportItemsForDelete.addAll(LA_BP_DataSelector.getFinancialReportItemsFromForm(costCenterIdsForCreate,currentUserId));

            Map<String, Financial_Report_Item__c> financialReportItemsFromFormByKey = getFinancialReportItemsByKey(financialReportItemsForDelete);
            Map<String, Financial_Report_Item__c> financialReportItemsForInsertByKey = getFinancialReportItemsByKey(financialReportItemsForInsert);

            financialReportItemsForInsert = (LA_BP_FinancialReportItemManager.getUpdatedFinancialReportItems(financialReportItemsForInsertByKey, financialReportItemsFromFormByKey, false));
        }

    }

    public static Map<String, Financial_Report_Item__c> getFinancialReportItemsByKey(List<Financial_Report_Item__c> financialReportItems) {
        Map<String, Financial_Report_Item__c> financialReportItemsByKey = new Map<String, Financial_Report_Item__c>();
        for (Financial_Report_Item__c financialReportItem : financialReportItems) {
            String key = String.valueOf(financialReportItem.Cost_Center__c) +
                    String.valueOf(financialReportItem.Budget_Element__c) +
                    String.valueOf(financialReportItem.StartDate__c) +
                    String.valueOf(financialReportItem.EndDate__c) ;
            financialReportItemsByKey.put(key, financialReportItem);
        }

        return financialReportItemsByKey;
    }

    public static void setNewFinancialReports(
            List<Id> costCentersIds
            , List<Financial_Report__c> newFinancialReports
            , Map<Id, Financial_Report__c> generatedFinancialReports
            , Integer year, Map<Id, Id> responsibleUsersIds) {
        Boolean isGeneratedFinancialReportsNotEmpty = generatedFinancialReports != null;
        Decimal version = 1;
        Id previousFinancialReportId = null;

        for (Id costCenterId : costCentersIds) {
            Financial_Report__c newFinancialReport = LA_BP_FinancialReportManager.getNewFinancialReport(costCenterId
                    , year);
            if (isGeneratedFinancialReportsNotEmpty) {
                Financial_Report__c previousFinancialReport = generatedFinancialReports.get(costCenterId);
                version = previousFinancialReport.Report_Version_Number__c + 1;
                previousFinancialReportId = previousFinancialReport.Id;
                previousFinancialReport.Is_Report_Last__c = false;
            }
            newFinancialReport.Report_Version_Number__c = version;
            newFinancialReport.Is_Report_Last__c = true;
            newFinancialReport.OwnerId = responsibleUsersIds.get(costCenterId);
            newFinancialReport.Previous_Financial_Report__c = previousFinancialReportId;
            newFinancialReports.add(newFinancialReport);
        }
        List<Financial_Report__c> previousFinReportForUpdate = new List<Financial_Report__c>();
        if (isGeneratedFinancialReportsNotEmpty) {
            for (Financial_Report__c previousFinReport : generatedFinancialReports.values()) {
                previousFinReportForUpdate.add(previousFinReport);
            }
        }

        if (!previousFinReportForUpdate.isEmpty()) {
            update previousFinReportForUpdate;
        }
        insert newFinancialReports;
    }

    public static void setNewFinancialReportItems(
            Integer year
            , List<Financial_Report__c> newFinancialReports
            , List<Financial_Report_Item__c> financialReportItemsForInsert
            , List<Budget_Element__c> allChildBudgetElements
            , Map<Id, Financial_Report__c> generatedFinancialReports) {

        Boolean isGeneratedFinancialReportsNotEmpty = generatedFinancialReports != null;
        Financial_Report__c previousFinancialReport = null;

        for (Financial_Report__c newFinancialReport : newFinancialReports) {
            if (isGeneratedFinancialReportsNotEmpty) {
                previousFinancialReport = generatedFinancialReports.get(newFinancialReport.Cost_Center__c);
            }
            financialReportItemsForInsert.addAll(LA_BP_FinancialReportItemManager.getFinancialReportItemsForEveryBudgetElement(
                    year
                    , newFinancialReport
                    , previousFinancialReport
                    , allChildBudgetElements, null)
            );
        }
    }

    public static void setValuesForShareCostCenter(List<Id> costCenterIds
            , Map<Id, Financial_Report__c> draftFinancialReports
            , Map<Id, Financial_Report__c> generatedFinancialReports
            , List<Id> emptyCostCenters
            , Integer year) {
        List<Financial_Report__c> financialReports = LA_BP_FinancialReportManager.getFinancialReportsByYear(year
                , costCenterIds
                , new List<String>{
                        LA_BP_Constants.DRAFT, LA_BP_Constants.GENERATED
                });

        for (Financial_Report__c financialReport : financialReports) {
            if (financialReport.Status__c == LA_BP_Constants.DRAFT) {
                draftFinancialReports.put(financialReport.Cost_Center__c, financialReport);
            }
            if (financialReport.Status__c == LA_BP_Constants.GENERATED) {
                if (generatedFinancialReports.get(financialReport.Cost_Center__c) != null) {
                    if (generatedFinancialReports.get(financialReport.Cost_Center__c).Report_Version_Number__c < financialReport.Report_Version_Number__c) {
                        generatedFinancialReports.put(financialReport.Cost_Center__c, financialReport);
                    }
                } else {
                    generatedFinancialReports.put(financialReport.Cost_Center__c, financialReport);
                }
            }
        }

        for (Id costCenterId : costCenterIds) {
            if (draftFinancialReports.containsKey(costCenterId) == false
                    && generatedFinancialReports.containsKey(costCenterId) == false) {
                emptyCostCenters.add(costCenterId);
            }

            if(draftFinancialReports.containsKey(costCenterId) && generatedFinancialReports.containsKey(costCenterId)) {
                generatedFinancialReports.remove(costCenterId);
            }
        }
    }

    public static List<Financial_Report_Item__c> getFinancialReportItemsForInsert() {
        return financialReportItemsForInsert;
    }

    public static List<Financial_Report_Item__c> getFinancialReportItemsForUpdate() {
        return financialReportItemsForUpdate;
    }

    public static List<Financial_Report_Item__c> getFinancialReportItemsForDelete() {
        return financialReportItemsForDelete;
    }

}