public with sharing class LA_BP_FinancialReportItemManager {

    public static List<Financial_Report_Item__c> getLastNotFinalizedSharedVersion(List<String> costCenterIds) {
        return LA_BP_DataSelector.getFinancialReportItems(costCenterIds, new List<String>{
                LA_BP_Constants.SHARED
        }, LA_BP_Constants.DRAFT);
    }

    public static List<Financial_Report_Item__c> getDraftFRIsForEveryBudgetElement(String costCenterId
            , Integer selectedYear
            , List<LA_BP_BudgetHierarchyWrapper> budgetHierarchyItems
            , String currencyFromBU) {
        List<Financial_Report_Item__c> newFinancialReportItems = new List<Financial_Report_Item__c>();
        for (LA_BP_BudgetHierarchyWrapper budgetHierarchyItem : budgetHierarchyItems) {
            if (!budgetHierarchyItem.budgetHierarchyItems.isEmpty()) {
                newFinancialReportItems.addAll(getDraftFRIsForEveryBudgetElement(costCenterId
                        , selectedYear
                        , budgetHierarchyItem.budgetHierarchyItems, currencyFromBU)
                );
            } else {
                Budget_Element__c budgetElement = budgetHierarchyItem.budgetElement;
                for (Integer month = 1; month <= 12; month++) {
                    newFinancialReportItems.add(getFinancialReportItem(costCenterId
                            , budgetElement
                            , null
                            , selectedYear
                            , month
                            , LA_BP_Constants.DRAFT, currencyFromBU)
                    );
                }
            }
        }
        return newFinancialReportItems;
    }

    public static Financial_Report_Item__c getFinancialReportItem(Id costCenterId
            , Budget_Element__c budgetElement
            , Financial_Report__c financialReport
            , Integer selectedYear
            , Integer monthNumber
            , String globalStatus
            , String currencyFromBU) {
        Financial_Report_Item__c financialReportItem = new Financial_Report_Item__c();
        financialReportItem.GlobalStatus__c = globalStatus;
        financialReportItem.Cost_Center__c = costCenterId;

        if (budgetElement != null) {
            financialReportItem.Budget_Element__c = budgetElement.Id;
            setFinancialReportItemRecordType(financialReportItem, budgetElement);
        }
        if (financialReport != null) {
            financialReportItem.Financial_Report__c = financialReport.Id;
        }

        financialReportItem.CurrencyIsoCode = currencyFromBU;

        setStartEndDates(financialReportItem, selectedYear, monthNumber);
        return financialReportItem;
    }

    public static void setFinancialReportItemRecordType(Financial_Report_Item__c financialReportItem, Budget_Element__c budgetElement) {
        List<RecordTypeInfo> recordTypeInfos = Financial_Report_Item__c.getSObjectType().getDescribe().getRecordTypeInfos();
        String budgetElementRecordTypeName = budgetElement.RecordType.DeveloperName;
        budgetElementRecordTypeName = budgetElementRecordTypeName.replace('_', ' ');
        if (recordTypeInfos != null) {
            for (RecordTypeInfo info : recordTypeInfos) {
                if (info.getName() == budgetElementRecordTypeName) {
                    financialReportItem.RecordTypeId = info.getRecordTypeId();
                }
            }
        }
    }

    public static void setStartEndDates(Financial_Report_Item__c financialReportItem
            , Integer selectedYear
            , Integer monthNumber) {
        Integer numberOfDays = Date.daysInMonth(selectedYear, monthNumber);
        financialReportItem.StartDate__c = Date.newInstance(selectedYear, monthNumber, LA_BP_Constants.FIRST_DAY_OF_MONTH);
        financialReportItem.EndDate__c = Date.newInstance(selectedYear, monthNumber, numberOfDays);
    }

    public static void setFinancialReportItemsForBudgetElements(List<LA_BP_BudgetHierarchyWrapper> budgetHierarchyItems
            , List<Financial_Report_Item__c> financialReportItems) {
        for (LA_BP_BudgetHierarchyWrapper budgetHierarchyItem : budgetHierarchyItems) {
            if (!budgetHierarchyItem.budgetHierarchyItems.isEmpty()) {
                setFinancialReportItemsForBudgetElements(budgetHierarchyItem.budgetHierarchyItems, financialReportItems);
            } else {
                for (Financial_Report_Item__c financialReportItem : financialReportItems) {
                    if (budgetHierarchyItem != null && financialReportItem.Budget_Element__c == budgetHierarchyItem.budgetElement.Id) {
                        budgetHierarchyItem.financialReportItems.add(financialReportItem);
                    }
                }
            }
        }
    }

    public static List<Financial_Report_Item__c> getUpdatedFinancialReportItems( Map<String, Financial_Report_Item__c> financialReportItemsForUpdateByKey
            , Map<String, Financial_Report_Item__c> financialReportItemsFromFormByKey
            , Boolean isEdit) {
        List<Financial_Report_Item__c> newFinancialReportItems = new List<Financial_Report_Item__c>();

        for (String key : financialReportItemsForUpdateByKey.keySet()) {
            if(financialReportItemsFromFormByKey.get(key) != null) {
                Financial_Report_Item__c financialReportItemFromForm = financialReportItemsFromFormByKey.get(key);
                Financial_Report_Item__c financialReportItemForUpdate = financialReportItemsForUpdateByKey.get(key);

                financialReportItemForUpdate.Sum__c = financialReportItemFromForm.Sum__c;
                financialReportItemForUpdate.CurrencyIsoCode = financialReportItemFromForm.CurrencyIsoCode;
                financialReportItemForUpdate.Count__c = financialReportItemFromForm.Count__c;
                financialReportItemForUpdate.GlobalStatus__c = LA_BP_Constants.SHARED;
                if(!isEdit) {
                    financialReportItemForUpdate.Id = null;
                }
                newFinancialReportItems.add(financialReportItemForUpdate);
            } else {
                newFinancialReportItems.add(financialReportItemsForUpdateByKey.get(key));
            }
        }
        return newFinancialReportItems;
    }

    public static List<Financial_Report_Item__c> getFinancialReportItemsForEveryBudgetElement(
            Integer selectedYear
            , Financial_Report__c newFinancialReport
            , Financial_Report__c prevFinancialReport
            , List<Budget_Element__c> budgetElements
            , String currencyFromBU) {

        List<Financial_Report_Item__c> newFinancialReportItems = new List<Financial_Report_Item__c>();

        for (Budget_Element__c budgetElement : budgetElements) {
            for (Integer month = 1; month <= 12; month++) {
                Financial_Report_Item__c newFinancialReportItem = new Financial_Report_Item__c();
                setFinancialReportItemRecordType(newFinancialReportItem, budgetElement);
                newFinancialReportItem.Cost_Center__c = newFinancialReport.Cost_Center__c;
                if (newFinancialReport.OwnerId != null) {
                    newFinancialReportItem.OwnerId = newFinancialReport.OwnerId;
                }
                newFinancialReportItem.Budget_Element__c = budgetElement.Id;
                newFinancialReportItem.Financial_Report__c = newFinancialReport.Id;
                if (currencyFromBU != null) {
                    newFinancialReportItem.CurrencyIsoCode = currencyFromBU;
                }
                setStartEndDates(newFinancialReportItem, selectedYear, month);
                String status;
                if (prevFinancialReport != null) {
                    setInfoFromPreviousFinReport(newFinancialReportItem, prevFinancialReport);
                    status = LA_BP_Constants.AUTO_COPY;
                } else {
                    status = LA_BP_Constants.DUMMY;
                }
                setGlobalStatus(newFinancialReportItem, budgetElement, status);

                newFinancialReportItems.add(newFinancialReportItem);
            }
        }

        return newFinancialReportItems;
    }

    public static void setInfoFromPreviousFinReport(Financial_Report_Item__c newFinancialReportItem
            , Financial_Report__c prevFinReport) {

        if (prevFinReport != null) {
            for (Financial_Report_Item__c prevFRI : prevFinReport.Financial_Report_Items__r) {
                if (isFinancialReportItemsMatch(newFinancialReportItem, prevFRI)) {
                    newFinancialReportItem.Previous_Financial_Report_Item__c = prevFRI.Id;
                    newFinancialReportItem.CurrencyIsoCode = prevFRI.CurrencyIsoCode;
                    newFinancialReportItem.Sum__c = prevFRI.Sum__c;
                    newFinancialReportItem.Count__c = prevFRI.Count__c;
                    break;
                }
            }
        }

    }

    private static Boolean isFinancialReportItemsMatch(Financial_Report_Item__c financialReportItemFirst
            , Financial_Report_Item__c financialReportItemSecond) {
        return financialReportItemFirst.Budget_Element__c == financialReportItemSecond.Budget_Element__c ?
                (financialReportItemFirst.StartDate__c == financialReportItemSecond.StartDate__c
                        && financialReportItemFirst.EndDate__c == financialReportItemSecond.EndDate__c
                        && ((financialReportItemFirst.Cost_Center__c != null && financialReportItemSecond.Cost_Center__c != null)
                        && (financialReportItemFirst.Cost_Center__c == financialReportItemSecond.Cost_Center__c)))
                : false;
    }

    public static void setGlobalStatus(Financial_Report_Item__c financialReportItem, Budget_Element__c budgetElement, String newGlobalStatus) {

        if (budgetElement.RecordType.DeveloperName == LA_BP_Constants.GLOBAL_RECORD_TYPE) {
            financialReportItem.GlobalStatus__c = newGlobalStatus;
        } else {
            if (budgetElement.RecordType.DeveloperName == LA_BP_Constants.COST_CENTER_RECORD_TYPE) {
                financialReportItem.GlobalStatus__c = '';
            }
        }
    }
}