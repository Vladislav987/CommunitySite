public with sharing class LA_HeaderOfFinReportController {

    public class HeaderWrapper {
        @AuraEnabled
        public Boolean isGlobalAvailable { get; set; }

        @AuraEnabled
        public Boolean isCostCenterAvailable { get; set; }

        @AuraEnabled
        public String selectedBusinessUnit { get; set; }

        @AuraEnabled
        public String selectedVersion { get; set; }

        @AuraEnabled
        public Integer selectedYear { get; set; }

        @AuraEnabled
        public List<Business_Unit__c> businessUnitsList { get; set; }

        @AuraEnabled
        public List<Integer> yearsList { get; set; }

        @AuraEnabled
        public List<String> versionsList { get; set; }

        public HeaderWrapper() {
            this.yearsList = new List<Integer>();
            this.businessUnitsList = new List<Business_Unit__c>();
            this.versionsList = new List<String>();
        }

    }

    @AuraEnabled
    public static List<Integer> getListOfYear(Id businessUnitId) {
        Date currentDate = System.Today();
        List<Integer> availableYears = new List<Integer>();
        AggregateResult[] yearRange = LA_BP_DataSelector.getMaxAndMinYear(businessUnitId);
        if (yearRange[0].get('max') != null) {
            Datetime maxDate = (Datetime) yearRange[0].get('max');
            Integer maxYear = maxDate.year();
            Datetime minDate = (Datetime) yearRange[0].get('min');
            Integer minYear = minDate.year();
            do {
                availableYears.add(minYear);
                minYear++;
            } while ((maxYear - minYear) >= 0);

            if (currentDate.month() > LA_BP_Constants.JULY_MONTH) {
                availableYears.add(maxYear + 1);
            }
            availableYears = sortInDESC(availableYears);
        } else {
            if (currentDate.month() > LA_BP_Constants.JULY_MONTH) {
                availableYears.add(currentDate.year() + 1);
            }
            availableYears.add(currentDate.year());
        }

        return availableYears;
    }

    @AuraEnabled
    public static HeaderWrapper getHeaderWrapper(String currentForm, Integer year) {
        HeaderWrapper headerWrapper = new HeaderWrapper();
        List<Business_Unit__c> businessUnits = LA_BP_DataSelector.getBusinessUnitsByRecordType(LA_BP_Constants.COST_CENTER_RECORD_TYPE);
        headerWrapper.yearsList = getListOfYear(headerWrapper.selectedBusinessUnit);
        headerWrapper.selectedYear = getSelectedYear(year, headerWrapper);
        headerWrapper.businessUnitsList = getFilteredBusinessUnits(currentForm, businessUnits, headerWrapper.selectedYear);
        headerWrapper.selectedBusinessUnit = headerWrapper.businessUnitsList[0].Id;
        headerWrapper.versionsList = getVersion(headerWrapper.selectedBusinessUnit, currentForm);
        headerWrapper.selectedVersion = headerWrapper.versionsList[0];
        headerWrapper.isGlobalAvailable = getIsUserHasAccessToTab(LA_BP_Constants.GLOBAL_GROUP);
        headerWrapper.isCostCenterAvailable = getIsUserHasAccessToTab(LA_BP_Constants.COST_CENTER_GROUP);
        return headerWrapper;

    }

    private static Integer getSelectedYear(Integer year, HeaderWrapper headerWrapper ) {
        return year != null ? year : headerWrapper.yearsList[0];
    }

    @AuraEnabled
    public static List<String> getVersion(Id businessUnitId, String currentForm) {
        List<String> versionList = new List<String>();
        List<Financial_Report_Item__c> financialReportItems =
                LA_BP_DataSelector.getFinancialReportItemsForCostCenter(businessUnitId,currentForm);
        String draftVersion = null;
        String sharedVersion = null;

        if (currentForm == LA_BP_Constants.GLOBAL_PLANNING) {
            Set<String> setVersions = new Set<String>();
            if (financialReportItems.size() > 0) {
                for (Financial_Report_Item__c financialReportItem : financialReportItems) {
                    if (isStatusesFit(financialReportItem, LA_BP_Constants.SHARED, LA_BP_Constants.GENERATED)) {
                        setVersions.add(LA_BP_Constants.GENERATED_VERSION + financialReportItem.Financial_Report__r.Report_Version_Number__c);
                    }
                    if (isStatusesFit(financialReportItem, LA_BP_Constants.AUTO_COPY, LA_BP_Constants.GENERATED)) {
                        setVersions.add(LA_BP_Constants.GENERATED_VERSION + financialReportItem.Financial_Report__r.Report_Version_Number__c);
                    }
                    if (isStatusesFit(financialReportItem, LA_BP_Constants.SHARED, LA_BP_Constants.DRAFT)) {
                        sharedVersion = LA_BP_Constants.SHARED;
                    }
                    if (isStatusesFit(financialReportItem, LA_BP_Constants.DRAFT, LA_BP_Constants.DRAFT)) {
                        draftVersion = LA_BP_Constants.DRAFT;
                    }
                    if (isStatusesFit(financialReportItem, LA_BP_Constants.DRAFT, null)) {
                        draftVersion = LA_BP_Constants.DRAFT;
                    }
                }
            } else {
                versionList.add(LA_BP_Constants.DRAFT);
            }

            versionList.addAll(setVersions);
        } else {
            Set<String> setVersions = new Set<String>();
            for (Financial_Report_Item__c financialReportItem : financialReportItems) {
                if (isStatusesFit(financialReportItem, LA_BP_Constants.SHARED, LA_BP_Constants.DRAFT)) {
                    draftVersion = LA_BP_Constants.DRAFT;
                }
                if (isStatusesFit(financialReportItem, LA_BP_Constants.SHARED, LA_BP_Constants.GENERATED)) {
                    setVersions.add(LA_BP_Constants.GENERATED_VERSION + financialReportItem.Financial_Report__r.Report_Version_Number__c);
                }
                if (isStatusesFit(financialReportItem, LA_BP_Constants.AUTO_COPY, LA_BP_Constants.GENERATED)) {
                    setVersions.add(LA_BP_Constants.GENERATED_VERSION + financialReportItem.Financial_Report__r.Report_Version_Number__c);
                }
                if (isStatusesFit(financialReportItem, LA_BP_Constants.AUTO_COPY, LA_BP_Constants.DRAFT)) {
                    draftVersion = LA_BP_Constants.DRAFT;
                }
            }
            versionList.addAll(setVersions);
        }
        versionList.sort();
        versionList = sortVersionList(versionList);
        if (sharedVersion != null) {
            if (!versionList.isEmpty()) {
                versionList.add(0, sharedVersion);
            } else {
                versionList.add(sharedVersion);
            }

        }

        if (draftVersion != null) {
            if (!versionList.isEmpty()) {
                versionList.add(0, draftVersion);
            } else {
                versionList.add(draftVersion);
            }
        }
        if (versionList.isEmpty()) {
            versionList.add(LA_BP_Constants.DRAFT);
        }
        return versionList;
    }


    private static Boolean isStatusesFit(Financial_Report_Item__c financialReportItem, String friStatus, String frStatus) {
        return financialReportItem.GlobalStatus__c == friStatus
                && financialReportItem.Financial_Report__r.Status__c == frStatus;
    }

    private static List<Business_Unit__c> getFilteredBusinessUnits(String currentForm, List<Business_Unit__c> businessUnits, Integer year) {
        List<Business_Unit__c> filteredBusinessUnits = new List<Business_Unit__c>();
        filteredBusinessUnits = getFilteredBusinessUnitsByYear(year, businessUnits);
        if (currentForm == LA_BP_Constants.COST_CENTER_PLANNING) {
            filteredBusinessUnits = getFilteredBusinessUnitsByUser(filteredBusinessUnits);
        }

        return filteredBusinessUnits;
    }

    private static List<Business_Unit__c> getFilteredBusinessUnitsByUser(List<Business_Unit__c> businessUnits) {
        List<Business_Unit__c> filteredBusinessUnits = new List<Business_Unit__c>();
        for (Business_Unit__c businessUnit : businessUnits) {
            if (businessUnit.Responsible_User__c == UserInfo.getUserId()) {
                filteredBusinessUnits.add(businessUnit);
            }
        }
        return filteredBusinessUnits;
    }

    public static List<Business_Unit__c> getFilteredBusinessUnitsByYear(Integer year, List<Business_Unit__c> businessUnits) {
        Date minDate = Date.newInstance(year, LA_BP_Constants.JANUARY_MONTH, LA_BP_Constants.FIRST_DAY_OF_MONTH);
        Date maxDate = Date.newInstance(year,LA_BP_Constants.DECEMBER_MONTH,LA_BP_Constants.LAST_DAY_OF_DECEMBER);
        List<Business_Unit__c> filteredBusinessUnits = new List<Business_Unit__c>();

        for(Business_Unit__c businessUnit : businessUnits) {
            if(businessUnit.Start_Date__c >= minDate && businessUnit.Start_Date__c <= maxDate) {
                filteredBusinessUnits.add(businessUnit);
            }
        }

        return filteredBusinessUnits;
    }

    public static List<Integer> sortInDESC(List<Integer> beforeSort) {
        List<Integer> afterSort = new List<Integer>();
        for (Integer i = beforeSort.size() - 1; i >= 0; i--) {
            afterSort.add(beforeSort.get(i));
        }
        return afterSort;
    }

    public static List<String> sortVersionList(List<String> beforeSort) {
        List<String> afterSort = new List<String>();
        for (Integer i = beforeSort.size() - 1; i >= 0; i--) {
            afterSort.add(beforeSort.get(i));
        }
        return afterSort;
    }

    @AuraEnabled
    public static Boolean getIsUserHasAccessToTab(String tabName) {
        List<GroupMember> groupMembers = LA_BP_DataSelector.getGroupsOfCurrentUser();
        Boolean isUserHasAccessToTab = false;
        for(GroupMember groupMember : groupMembers) {
            if(groupMember.Group.Name == tabName) {
                isUserHasAccessToTab = true;
                break;
            }
        }
        return isUserHasAccessToTab;
    }

    @AuraEnabled
    public static Boolean pendingUI() {
        return LA_BP_Validator.isShareActionDone();
    }

}