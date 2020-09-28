public with sharing class LA_BP_BudgetHierarchyWrapper {
    @AuraEnabled
    public Budget_Element__c budgetElement { get; set; }

    @AuraEnabled
    public List<LA_BP_BudgetHierarchyWrapper> budgetHierarchyItems { get; set; }

    @AuraEnabled
    public List<Financial_Report_Item__c> financialReportItems { get; set; }

    @AuraEnabled
    public Integer sumOfAllFinancialReports { get; set; }

    @AuraEnabled
    public String currentCurrency { get; set; }

    public LA_BP_BudgetHierarchyWrapper() {

    }

    public LA_BP_BudgetHierarchyWrapper(Budget_Element__c budgetElement) {
        this.financialReportItems = new List<Financial_Report_Item__c>();
        this.budgetElement = budgetElement;
        this.budgetHierarchyItems = new List<LA_BP_BudgetHierarchyWrapper>();
        this.sumOfAllFinancialReports = 0;
    }

    public static void setSumOfAllFinancialReports(LA_BP_BudgetHierarchyWrapper budgetHierarchyWrapper) {
        for (Financial_Report_Item__c financialReportItem : budgetHierarchyWrapper.financialReportItems) {
            budgetHierarchyWrapper.sumOfAllFinancialReports += (Integer) financialReportItem.Sum__c;
        }
    }


    public static List<LA_BP_BudgetHierarchyWrapper> getBudgetHierarchyWrappers(String currentForm) {

        Map<Id, Budget_Element__c> budgetElementsMap = new Map<Id, Budget_Element__c>(LA_BP_DataSelector.getAllBudgetElements());
        List<LA_BP_BudgetHierarchyWrapper> budgetHierarchyWrappersList = new List<LA_BP_BudgetHierarchyWrapper>();

        for (Budget_Element__c budgetElement : budgetElementsMap.values()) {
            setChildHierarchy(budgetElement, budgetElementsMap, budgetHierarchyWrappersList, currentForm);
        }
        return budgetHierarchyWrappersList;
    }

    private static void setChildHierarchy(Budget_Element__c budgetElement, Map<Id, Budget_Element__c> budgetElementsMap, List<LA_BP_BudgetHierarchyWrapper> budgetHierarchyWrappersList, String currentForm) {
        if (budgetElement.Parent_Cost_Element__c == null) {
            LA_BP_BudgetHierarchyWrapper hierarchyItem = new LA_BP_BudgetHierarchyWrapper(budgetElement);
            budgetElementsMap.remove(budgetElement.Id);
            hierarchyItem.budgetHierarchyItems = getChildHierarchy(budgetElement.Id, budgetElementsMap, currentForm);
            if (!hierarchyItem.budgetHierarchyItems.isEmpty()) {
                if(isHierarchyItemHasChilds(hierarchyItem) == true) {
                    budgetHierarchyWrappersList.add(hierarchyItem);
                }
            }
        }
    }

    private static Boolean isHierarchyItemHasChilds(LA_BP_BudgetHierarchyWrapper hierarchyItem) {
        if (!hierarchyItem.budgetHierarchyItems.isEmpty()) {
            for (LA_BP_BudgetHierarchyWrapper wrapper :hierarchyItem.budgetHierarchyItems) {
                if(!wrapper.budgetHierarchyItems.isEmpty()) {
                    isHierarchyItemHasChilds(wrapper);
                } else {
                    if(wrapper.budgetElement.RecordType.DeveloperName == 'Parent') {
                        return false;
                    }
                }
            }
        }

        return true;
    }

    private static List<LA_BP_BudgetHierarchyWrapper> getChildHierarchy(String parentId, Map<Id, Budget_Element__c> budgetElementsMap, String currentForm) {
        List<LA_BP_BudgetHierarchyWrapper> hierarchyItems = new List<LA_BP_BudgetHierarchyWrapper>();
        for (Budget_Element__c budgetElement : budgetElementsMap.values()) {
            if (isBudgetElementFilterRequired(currentForm, budgetElement)) {
                if (isUserHasAccessToBudgetElement(budgetElement)) {
                    if (budgetElement.Parent_Cost_Element__c == parentId) {
                        LA_BP_BudgetHierarchyWrapper hierarchyItem = new LA_BP_BudgetHierarchyWrapper(budgetElement);
                        hierarchyItems.add(hierarchyItem);
                        budgetElementsMap.remove(budgetElement.Id);
                        hierarchyItem.budgetHierarchyItems = getChildHierarchy(budgetElement.Id, budgetElementsMap, currentForm);
                    }
                }
            } else {
                if (budgetElement.Parent_Cost_Element__c == parentId) {
                    LA_BP_BudgetHierarchyWrapper hierarchyItem = new LA_BP_BudgetHierarchyWrapper(budgetElement);
                    hierarchyItems.add(hierarchyItem);
                    budgetElementsMap.remove(budgetElement.Id);
                    hierarchyItem.budgetHierarchyItems = getChildHierarchy(budgetElement.Id, budgetElementsMap, currentForm);
                }
            }
        }

        return hierarchyItems;
    }

    private static Boolean isUserHasAccessToBudgetElement(Budget_Element__c budgetElement) {
        return budgetElement.Responsible_User__c == UserInfo.getUserId();
    }

    private static Boolean isBudgetElementFilterRequired(String currentForm, Budget_Element__c budgetElement) {
        return currentForm == LA_BP_Constants.GLOBAL_PLANNING && budgetElement.RecordType.DeveloperName != 'Parent';
    }

}