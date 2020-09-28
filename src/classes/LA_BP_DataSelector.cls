public with sharing class LA_BP_DataSelector {

    public static List<Budget_Element__c> getAllBudgetElements() {
        return [
                SELECT Id,
                        Name,
                        Parent_Cost_Element__c,
                        CurrencyIsoCode,
                        Responsible_User__c,
                        RecordType.DeveloperName, (SELECT Name,Responsible_User__c,RecordType.DeveloperName FROM Budget_Elements__r)
                FROM Budget_Element__c
                WHERE Is_Active__c = TRUE
        ];
    }

    public static List<Business_Unit__c> getBusinessUnitsByRecordType(String recordType) {
        return [
                SELECT
                        Id,
                        Name,
                        Description__c,
                        Responsible_User__c,
                        Start_Date__c,
                        End_Date__c, (
                        SELECT Id,
                                Name,
                                GlobalStatus__c,
                                Sum__c,
                                Budget_Element__r.RecordType.DeveloperName
                        FROM Financial_Report_Items__r
                        WHERE GlobalStatus__c = :LA_BP_Constants.DRAFT
                )
                FROM    Business_Unit__c
                WHERE   RecordType.DeveloperName = :recordType
                ORDER BY Name
        ];
    }

    public static List<Financial_Report_Item__c> getDraftFinancialReportItemsByResponsibleUser(List<Id> costCenterIds) {
        return [
                SELECT Id
                        ,Sum__c
                        ,Count__c
                        ,Budget_Element__c
                        ,Cost_Center__c
                        ,StartDate__c
                        ,CurrencyIsoCode
                        ,Budget_Element__r.RecordType.DeveloperName
                        ,EndDate__c
                        ,GlobalStatus__c
                        ,Previous_Financial_Report_Item__r.Sum__c
                        ,Financial_Report__r.Report_Version_Number__c
                        , (SELECT Id, Sum__c, GlobalStatus__c FROM Financial_Report_Items__r)
                FROM Financial_Report_Item__c
                WHERE Cost_Center__c = :costCenterIds
                AND GlobalStatus__c = :LA_BP_Constants.DRAFT
                AND Budget_Element__r.Responsible_User__c = :UserInfo.getUserId()
                ORDER BY StartDate__c
        ];
    }

    public static List<Financial_Report_Item__c> getFinancialReportItemsByFinancialReport(List<Id> financialReportsIds) {
        return [
                SELECT id
                        , Sum__c
                        , Count__c
                        , Budget_Element__c
                        , Cost_Center__c
                        , StartDate__c
                        , EndDate__c
                        , GlobalStatus__c
                        , CurrencyIsoCode
                        , Budget_Element__r.RecordType.DeveloperName
                        , Financial_Report__r.Report_Version_Number__c
                        , Previous_Financial_Report_Item__r.Sum__c
                        , (SELECT Id, Sum__c, Previous_Financial_Report_Item__r.Sum__c, GlobalStatus__c FROM Financial_Report_Items__r)
                FROM Financial_Report_Item__c
                WHERE Financial_Report__c IN :financialReportsIds
                ORDER BY StartDate__c
        ];
    }

    public static List<Financial_Report_Item__c> getFinancialReportItemsForCostCenter(Id costCenterId, String currentForm) {
        String whereFinancialReportStatus = '';
        if (currentForm != LA_BP_Constants.COST_CENTER_PLANNING) {
            String userId = UserInfo.getUserId();
            whereFinancialReportStatus = ' AND Budget_Element__r.Responsible_User__c =:userId';
        }

        return Database.query('SELECT Cost_Center__r.Name' +
                ', GlobalStatus__c' + ', Cost_Center__c' +
                ', Financial_Report__r.Status__c' +
                ', Financial_Report__r.Report_Version_Number__c ' +
                'FROM Financial_Report_Item__c ' +
                'WHERE Cost_Center__c =: costCenterId' +
                whereFinancialReportStatus);
    }

    public static List<Financial_Report_Item__c> getFinancialReportItems(List<Id> costCenterIds, List<String> statuses, String finReportStatus) {
        String whereFinancialReportStatus = '';
        if (finReportStatus != null) {
            whereFinancialReportStatus = 'AND Financial_Report__r.Status__c =: finReportStatus ';
        }
        return Database.query('SELECT id,' +
                'Sum__c,' +
                'Count__c,' +
                'Budget_Element__c, ' +
                'Cost_Center__c, ' +
                'StartDate__c, ' +
                'CurrencyIsoCode, ' +
                'Budget_Element__r.RecordType.DeveloperName, ' +
                'EndDate__c, ' +
                'GlobalStatus__c, ' +
                'Previous_Financial_Report_Item__r.Sum__c, ' +
                'Financial_Report__r.Report_Version_Number__c ' +
                ',(SELECT Id , Sum__c, GlobalStatus__c FROM Financial_Report_Items__r) ' +
                'FROM Financial_Report_Item__c ' +
                'WHERE Cost_Center__c = :costCenterIds ' +
                'AND GlobalStatus__c IN :statuses ' +
                whereFinancialReportStatus
                + 'ORDER BY StartDate__c');

    }

    public static List<Financial_Report__c> getFinancialReports(List<Id> costCenterIds, List<String> statuses) {
        return [
                SELECT Id,
                        Cost_Center__c,
                        Status__c,
                        StartDate__c,
                        EndDate__c,
                        Is_Report_Last__c,
                        Report_Version_Number__c, (
                        SELECT Id,
                                StartDate__c,
                                EndDate__c,
                                Budget_Element__c,
                                Sum__c,
                                Count__c,
                                Cost_Center__c,
                                CurrencyIsoCode, GlobalStatus__c,
                                Budget_Element__r.RecordType.DeveloperName
                        FROM Financial_Report_Items__r
                )
                FROM Financial_Report__c
                WHERE Cost_Center__c IN :costCenterIds
                AND Status__c IN :statuses
        ];
    }


    public static AsyncApexJob getAsyncApexJobStatus() {
        List<AsyncApexJob> apexJob = [
                SELECT  ApexClass.Name,
                        CreatedById,
                        CreatedDate,
                        Status
                FROM    AsyncApexJob
                WHERE   ApexClass.Name = :LA_BP_Constants.NAME_OF_APEX_CLASS_FOR_SHARE
                ORDER BY CreatedDate DESC
                LIMIT   1
        ];
        if (!apexJob.isEmpty()) {
            return apexJob[0];
        }

        return null;
    }

    public static List<Financial_Report_Item__c> getDraftFromShared(Id costCenterIds) {
        return [
                SELECT id
                        , Sum__c
                        , Count__c
                        , Budget_Element__c
                        , Cost_Center__c
                        , StartDate__c, GlobalStatus__c
                        , EndDate__c,Previous_Financial_Report_Item__r.Sum__c
                        , Previous_Financial_Report_Item__c
                        , CurrencyIsoCode
                        , Budget_Element__r.RecordType.DeveloperName
                        , Financial_Report__r.Report_Version_Number__c
                        , (SELECT Id, Sum__c, GlobalStatus__c,CurrencyIsoCode,Budget_Element__r.RecordType.DeveloperName FROM Financial_Report_Items__r)
                FROM Financial_Report_Item__c
                WHERE Cost_Center__c = :costCenterIds
                AND GlobalStatus__c = 'Draft'
                ORDER BY StartDate__c
        ];
    }

    public static Financial_Report__c getDraftFinancialReportByVersionAndStatus(Id costCenterId, String status, Integer versionNumber) {
        return [
                SELECT Id,
                        Is_Report_Last__c,
                (
                        SELECT Id,
                                GlobalStatus__c,
                                Sum__c,
                                Count__c
                        FROM Financial_Report_Items__r
                )
                FROM Financial_Report__c
                WHERE Cost_Center__c = :costCenterId
                AND Status__c = :status
                AND Report_Version_Number__c = :versionNumber
        ];
    }

    public static List<Financial_Report_Item__c> getFinancialReportItemsFromForm(List<Id> costCenterIds, String currentUserId) {
        return [
                SELECT id
                        , Sum__c
                        , Count__c
                        , GlobalStatus__c
                        , Budget_Element__c
                        , Cost_Center__c
                        , StartDate__c
                        , EndDate__c
                        , CurrencyIsoCode
                        , Financial_Report__r.Report_Version_Number__c
                        , (SELECT Id, Sum__c, GlobalStatus__c FROM Financial_Report_Items__r)
                FROM Financial_Report_Item__c
                WHERE Cost_Center__c IN :costCenterIds
                AND GlobalStatus__c = :LA_BP_Constants.DRAFT
                AND Financial_Report__c = null
                AND OwnerId = :currentUserId
                ORDER BY StartDate__c
        ];
    }

    public static List<Financial_Report_Item__c> getFinancialReportItemsForUpdate(List<Id> costCenterIds) {
        List<String> statuses = new List<String>{
                LA_BP_Constants.SHARED, LA_BP_Constants.DUMMY, LA_BP_Constants.AUTO_COPY
        };
        return [
                SELECT Id,
                        Sum__c,
                        Count__c,
                        StartDate__c,
                        EndDate__c,
                        Cost_Center__c,
                        Budget_Element__c,
                        GlobalStatus__c,
                        CurrencyIsoCode,
                        Budget_Element__r.Name
                FROM Financial_Report_Item__c
                WHERE Cost_Center__c IN :costCenterIds
                AND GlobalStatus__c IN :statuses
                AND Financial_Report__c != null
                AND Financial_Report__r.Status__c != :LA_BP_Constants.GENERATED
                ORDER BY StartDate__c
        ];
    }

    public static List<BudgetPlanningBatch__c> getBudgetPlanningBatchJobs() {
        return [SELECT Id, LastBatchJobId__c FROM BudgetPlanningBatch__c];
    }

    public static AggregateResult[] getMaxAndMinYear(Id businessUnitId) {
        return [
                SELECT MAX(StartDate__c)max,
                        MIN(EndDate__c)min
                FROM Financial_Report_Item__c
                WHERE Cost_Center__c = :businessUnitId
        ];
    }

    public static String getCurrencyFromBU(Id businessUnitId) {
        return [
                SELECT Id,
                        CurrencyIsoCode
                FROM Business_Unit__c
                WHERE Id = :businessUnitId
        ].CurrencyIsoCode;
    }

    public static Integer getCountOfEmptySum(List<Id> costCIds) {
        return [
                SELECT COUNT()
                FROM Financial_Report_Item__c
                WHERE Cost_Center__c IN :costCIds
                AND GlobalStatus__c = :LA_BP_Constants.DRAFT
                AND Sum__c = null
                AND Budget_Element__r.Responsible_User__c = :UserInfo.getUserId()
        ];
    }

    public static AggregateResult[] getCostCentersForShare(String version) {
        return [
                SELECT Cost_Center__r.Name csName
                FROM Financial_Report_Item__c
                WHERE GlobalStatus__c = :version
                GROUP BY Cost_Center__r.Name
        ];
    }

    public static Integer getCountOfBUWithFillFRIs(List<Id> costCIds) {
        return [
                SELECT COUNT(Id),
                        Cost_Center__c
                FROM Financial_Report_Item__c
                WHERE Cost_Center__c IN :costCIds
                GROUP BY Cost_Center__c
        ].size();
    }


    public static Integer getCountOfAutoCopyOrDummyStatus(List<Id> costCIds) {
        return [
                SELECT COUNT()
                FROM Financial_Report_Item__c
                WHERE Cost_Center__c IN :costCIds
                AND (
                        GlobalStatus__c = :LA_BP_Constants.DUMMY
                        OR GlobalStatus__c = :LA_BP_Constants.AUTO_COPY
                )
        ];
    }

    public static Integer getCountOfEmptySumForCostCenter(List<Id> costCIds) {
        return [
                SELECT COUNT()
                FROM Financial_Report_Item__c
                WHERE Cost_Center__c IN :costCIds
                AND GlobalStatus__c = null
                AND Sum__c = null
        ];
    }

    public static AggregateResult[] getCostCentersForGeneration(String version, List<Id> costCIds) {
        return [
                SELECT Cost_Center__r.Name csName
                FROM Financial_Report_Item__c
                WHERE Cost_Center__c IN :costCIds
                AND Financial_Report__r.Status__c = :LA_BP_Constants.DRAFT
                GROUP BY Cost_Center__r.Name
        ];
    }

    public static Id getIdOfEmailTemplate() {
        return [
                SELECT Id
                FROM EmailTemplate
                WHERE DeveloperName = :LA_BP_Constants.NAME_OF_EMAIL_TEMPLATE_FOR_SHARE
        ].Id;
    }

    public static List<GroupMember> getGroupsOfCurrentUser() {
        return [
                SELECT Group.Name
                FROM GroupMember
                WHERE UserOrGroupId = :UserInfo.getUserId()
        ];
    }

}