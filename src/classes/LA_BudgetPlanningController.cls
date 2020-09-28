public with sharing class LA_BudgetPlanningController {
    public static List<String> months = new List<String>();
    public static List<LA_BP_BudgetHierarchyWrapper> currentBudgetHierarchyWrappers { get; set; }
    public static Id currentCostCenterId { get; set; }
    public static Integer selectedYear { get; set; }
    private static LA_BP_FlowService currentFlow;
    public static Boolean isDelete {get; set;}
    public static final Integer maxBatchSizeForShareAction = 20;

    @AuraEnabled
    public static List<String> getMonths() {
        months.add('January');
        months.add('February');
        months.add('March');
        months.add('April');
        months.add('May');
        months.add('June');
        months.add('July');
        months.add('August');
        months.add('September');
        months.add('October');
        months.add('November');
        months.add('December');

        return months;
    }

    @AuraEnabled
    public static List<LA_BP_BudgetHierarchyWrapper> setCurrentFlow(String version, Id costCenterId, Integer year, String currentForm) {
        currentFlow = new LA_BP_FlowService(version, costCenterId, year, currentForm);

        currentBudgetHierarchyWrappers = currentFlow.budgetHierarchyWrappers;
        currentCostCenterId = currentFlow.costCenterId;
        selectedYear = currentFlow.year;
        return currentBudgetHierarchyWrappers;
    }

    @AuraEnabled
    public static Boolean shareCostCenter(List<Id> costCenterIds, Integer selectedYear) {
        startBatchForFinancialReports(costCenterIds, selectedYear);
        return true;
    }

    private static void startBatchForFinancialReports(List<Id> costCenterIds, Integer selectedYear) {
        Map<Id, Id> responsibleUsersIds = new Map<Id, Id>();
        for (Business_Unit__c unit : [SELECT Id,Responsible_User__c FROM Business_Unit__c WHERE Id IN :costCenterIds]) {
            responsibleUsersIds.put(unit.Id,unit.Responsible_User__c);
        }
        LA_BP_ShareCostCenterBatch shareCostCenterBatch = new LA_BP_ShareCostCenterBatch(costCenterIds, selectedYear,responsibleUsersIds,UserInfo.getUserId());
        Database.executeBatch(shareCostCenterBatch, maxBatchSizeForShareAction);
    }

    @AuraEnabled
    public static void editAction(Integer selectedYear, Id costCenterId) {
        List<LA_BP_BudgetHierarchyWrapper> budgetHierarchyWrappers = LA_BP_BudgetHierarchyWrapper.getBudgetHierarchyWrappers(LA_BP_Constants.GLOBAL_PLANNING);
        String currencyFromBU = LA_BP_DataSelector.getCurrencyFromBU(costCenterId);
        List<Financial_Report_Item__c> financialReportItems = LA_BP_FinancialReportItemManager.getDraftFRIsForEveryBudgetElement(costCenterId, selectedYear, budgetHierarchyWrappers, currencyFromBU);
        List<Financial_Report__c> financialReports =
                LA_BP_DataSelector.getFinancialReports(new List<Id>{
                        costCenterId
                }, new List<String>{
                        LA_BP_Constants.DRAFT, LA_BP_Constants.GENERATED
                });
        Financial_Report__c lastSharedFinancialReport = LA_BP_FinancialReportManager.getLastFinancialReport(financialReports);
        for (Financial_Report_Item__c financialReportItem : financialReportItems) {
            LA_BP_FinancialReportItemManager.setInfoFromPreviousFinReport(financialReportItem, lastSharedFinancialReport);
        }
        insert financialReportItems;
    }

    @AuraEnabled
    public static void editCostCenterAction(Integer selectedYear, Id costCenterId) {
        List<Financial_Report__c> newFinancialReports = new List<Financial_Report__c>();
        List<Financial_Report__c> generatedFinancialReports = LA_BP_FinancialReportManager.getFinancialReportsByYear(selectedYear
                , new List<Id>{
                        costCenterId
                }
                , new List<String>{
                        LA_BP_Constants.GENERATED
                });
        Financial_Report__c lastSharedFinancialReport = LA_BP_FinancialReportManager.getLastFinancialReport(generatedFinancialReports);
        List<Financial_Report_Item__c> financialReportItemsForInsert = new List<Financial_Report_Item__c>();
        List<Budget_Element__c> allChildBudgetElements = getChildBudgetElements();
        Map<Id, Id> responsibleUsersIds = new Map<Id, Id>();
        for (Business_Unit__c unit : [SELECT Id,Responsible_User__c FROM Business_Unit__c WHERE Id = :costCenterId]) {
            responsibleUsersIds.put(unit.Id,unit.Responsible_User__c);
        }

        Map<Id, Financial_Report__c> mapFinancialReportsByIds = new Map<Id, Financial_Report__c>();
        mapFinancialReportsByIds.put(lastSharedFinancialReport.Cost_Center__c, lastSharedFinancialReport);

        LA_BP_ActionService.setNewFinancialReports(
                new List<Id>{
                        costCenterId
                }
                , newFinancialReports
                , mapFinancialReportsByIds
                , selectedYear,responsibleUsersIds);
        LA_BP_ActionService.setNewFinancialReportItems(selectedYear
                , newFinancialReports
                , financialReportItemsForInsert
                , allChildBudgetElements
                , mapFinancialReportsByIds);

        insert financialReportItemsForInsert;
    }

    public static List<Budget_Element__c> getChildBudgetElements() {
        List<Budget_Element__c> budgetElements = LA_BP_DataSelector.getAllBudgetElements();
        List<Budget_Element__c> childBudgetElements = new List<Budget_Element__c>();
        for (Integer i = 0; i < budgetElements.size(); i++) {
            if (budgetElements[i].Parent_Cost_Element__c == null && budgetElements[i].Budget_Elements__r.isEmpty()) {
                budgetElements.remove(i);
            }
            if (budgetElements[i].Budget_Elements__r.isEmpty()) {
                childBudgetElements.add(budgetElements[i]);
            }

        }
        return childBudgetElements;
    }

    @AuraEnabled
    public static void generateAction(List<Id> costCenterIds, Integer selectedYear) {
        List<Financial_Report__c> financialReports =
                LA_BP_FinancialReportManager.getFinancialReportsByYear(
                        selectedYear
                        , costCenterIds
                        , new List<String>{
                                LA_BP_Constants.DRAFT
                        });
        for (Financial_Report__c financialReport : financialReports) {
            financialReport.Status__c = LA_BP_Constants.GENERATED;
        }

        update financialReports;
    }

    @AuraEnabled
    public static MessageFromValidation generateValidationAction(List<Id> businessUnitList, String maxVersionNumber) {
        MessageFromValidation fromValidation = new MessageFromValidation(false,null);
        if (LA_BP_DataSelector.getCountOfBUWithFillFRIs(businessUnitList) != businessUnitList.size()
                || LA_BP_DataSelector.getCountOfEmptySumForCostCenter(businessUnitList) != 0) {
            fromValidation.isPassValidation = false;
            fromValidation.messageFromValidation = 'Fill all Financial Report Items!';
            return fromValidation;
        } else if (LA_BP_DataSelector.getCountOfAutoCopyOrDummyStatus(businessUnitList) != 0) {
            fromValidation.isPassValidation = false;
            fromValidation.messageFromValidation = 'Wait while global Share Cost Center with You!';
            return fromValidation;
        }
        List<String> businessUnitsForGeneration = new List<String>();
        for (AggregateResult result : LA_BP_DataSelector.getCostCentersForGeneration(LA_BP_Constants.SHARED, businessUnitList)) {
            businessUnitsForGeneration.add((String) result.get(LA_BP_Constants.COST_CENTER_NAME));
        }
        Integer versionNumber = 1;
        if (maxVersionNumber != null) {
            versionNumber = Integer.valueOf(maxVersionNumber.replaceAll('[^0-9]', ''));
            versionNumber++;
        }
        String message = 'Are you sure you want to generate final  V' + versionNumber + ' for Cost Centers: ' + businessUnitsForGeneration;
        fromValidation.isPassValidation = true;
        fromValidation.messageFromValidation = message;
        return fromValidation;
    }

    @AuraEnabled
    public static List<String> shareAction(List<Id> businessUnitList) {
        if (LA_BP_DataSelector.getCountOfEmptySum(businessUnitList) != 0 || LA_BP_DataSelector.getCountOfBUWithFillFRIs(businessUnitList) != businessUnitList.size()) {
            return null;
        }
        List<String> businessUnitsForShare = new List<String>();
        for (AggregateResult result : LA_BP_DataSelector.getCostCentersForShare(LA_BP_Constants.DRAFT)) {
            businessUnitsForShare.add((String) result.get(LA_BP_Constants.COST_CENTER_NAME));
        }
        return businessUnitsForShare;

    }

    @AuraEnabled
    public static Boolean deleteActionGlobal(String costCenterId, List<String> availableVersions) {
        List<Financial_Report_Item__c> financialReportItems = new List<Financial_Report_Item__c>();
        List<Financial_Report_Item__c> financialReportItemsForClean = new List<Financial_Report_Item__c>();
        List<Financial_Report_Item__c> financialReportItemsForDelete = new List<Financial_Report_Item__c>();
        if (availableVersions.size() == 1) {
            financialReportItems = [
                    SELECT id
                            , Sum__c
                            , Count__c
                    FROM Financial_Report_Item__c
                    WHERE Previous_Financial_Report_Item__c = NULL
                    AND Cost_Center__c = :costCenterId
                    AND GlobalStatus__c = :LA_BP_Constants.DRAFT
            ];

            for (Financial_Report_Item__c item : financialReportItems) {
                item.Sum__c = null;
                item.Count__c = null;
                financialReportItemsForClean.add(item);
            }
        } else {
            financialReportItems = [
                    SELECT id
                            , Sum__c
                            , Count__c
                    FROM Financial_Report_Item__c
                    WHERE Previous_Financial_Report_Item__c != NULL
                    AND Cost_Center__c = :costCenterId
                    AND GlobalStatus__c = :LA_BP_Constants.DRAFT
            ];
            for (Financial_Report_Item__c item : financialReportItems) {
                financialReportItemsForDelete.add(item);
            }
        }

        if (!financialReportItemsForClean.isEmpty()) {
            update financialReportItemsForClean;
            return true;
        }

        if (!financialReportItemsForDelete.isEmpty()) {
            delete financialReportItemsForDelete;
            return true;
        }

        return false;
    }

    @AuraEnabled
    public static Boolean deleteActionCostCenter(String costCenterId,String maxVersion) {
        Integer versionNumber = 1;
        Integer previousVersionNumber = 0;
        if (maxVersion != null) {
            versionNumber = Integer.valueOf(maxVersion.replaceAll('[^0-9]', ''));
            previousVersionNumber = versionNumber;
            versionNumber++;
        }
        Financial_Report__c financialReport = LA_BP_DataSelector.getDraftFinancialReportByVersionAndStatus(costCenterId, LA_BP_Constants.DRAFT, versionNumber);

        Financial_Report__c previousFinancialReport;
        if (previousVersionNumber != 0) {
            previousFinancialReport = LA_BP_DataSelector.getDraftFinancialReportByVersionAndStatus(costCenterId, LA_BP_Constants.GENERATED, previousVersionNumber);
            previousFinancialReport.Is_Report_Last__c = true;
        }
        List<Financial_Report_Item__c> financialReportItemsForClean = new List<Financial_Report_Item__c>();
        Boolean deleteDraft = false;
        if (financialReport != null) {
            for (Financial_Report_Item__c item : financialReport.Financial_Report_Items__r) {
                if (item.GlobalStatus__c == LA_BP_Constants.AUTO_COPY) {
                    deleteDraft = true;
                    break;
                }

                if (item.GlobalStatus__c == null) {
                    item.Sum__c = null;
                    item.Count__c = null;
                    financialReportItemsForClean.add(item);
                }
            }
        }

        if (deleteDraft) {
            delete financialReport.Financial_Report_Items__r;
            delete financialReport;
            update previousFinancialReport;
            return true;
        } else {
            update financialReportItemsForClean;
            return true;
        }

    }


    @AuraEnabled
    public static Boolean updateSelectedCostCenter(String finItemsForUpdate) {
        List<Financial_Report_Item__c> hierarchyItems1 = (List<Financial_Report_Item__c>) JSON.deserialize(finItemsForUpdate,List<Financial_Report_Item__c>.class);
        if (!hierarchyItems1.isEmpty()) {
            upsert hierarchyItems1;
            return true;
        }
        return false;
    }

    @AuraEnabled
    public static List<String> getCurrencyValues() {
        List<String> pickListValuesList = new List<String>();
        Schema.DescribeFieldResult fieldResult = Financial_Report_Item__c.CurrencyIsoCode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            pickListValuesList.add(pickListVal.getValue());
        }
        return pickListValuesList;
    }



    public static List<Financial_Report_Item__c> getChildrenFRIsForUpdate(List<LA_BP_BudgetHierarchyWrapper> hierarchyItems, List<Financial_Report_Item__c> financialReportItems, String currentForm) {
        for (LA_BP_BudgetHierarchyWrapper hierarchyItem : hierarchyItems) {
            if (!hierarchyItem.budgetHierarchyItems.isEmpty()) {
                financialReportItems = getChildrenFRIsForUpdate(hierarchyItem.budgetHierarchyItems, financialReportItems, currentForm);
            } else {
                for (Financial_Report_Item__c item : hierarchyItem.financialReportItems) {
                    if (currentForm == 'Global planning') {
                        if (item.GlobalStatus__c == LA_BP_Constants.DRAFT) {
                            financialReportItems.add(item);
                        }
                    }

                    if (currentForm == 'Cost Centers Planning') {
                        if (item.GlobalStatus__c == '') {
                            financialReportItems.add(item);
                        }
                    }
                }
            }
        }
        return financialReportItems;

    }

    public class MessageFromValidation {
        @AuraEnabled
        public Boolean isPassValidation { get; set; }

        @AuraEnabled
        public String messageFromValidation { get; set; }

        public MessageFromValidation(Boolean isPassValidation,String messageFromValidation) {
            this.isPassValidation = isPassValidation;
            this.messageFromValidation = messageFromValidation;
        }

    }
}