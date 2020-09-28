/**
 * Created by Mychailo Hamdzii on 17.04.2019.
 */

public without sharing class MonthlyReportService {
    private static final SObjectType ALLOCATION_TYPE = Schema.Allocation__c.SObjectType;
    private static final SObjectType PROJECT_TYPE = Schema.Project__c.SObjectType;
    private static final SObjectField MONTH_NAMES = Schema.Monthly_Report__c.Month_Names__c;
    private static final Id ALLOCATION_RECORD_TYPE_PROJECT_ID =
            Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Project').getRecordTypeId();
    private static final Id PROJECT_RECORD_TYPE_PARENT_ID =
            Schema.Project__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId();
    private static final Id MONTHLY_REPORT_RECORD_TYPE_GENERAL_ID =
            Schema.Monthly_Report__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Monthly_Report_General').getRecordTypeId();
    private static final Id MONTHLY_REPORT_RECORD_TYPE_DETAILED_ID =
            Schema.Monthly_Report__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Monthly_Report_Detailed').getRecordTypeId();
    private static final Id MONTHLY_REPORT_RECORD_TYPE_USUAL_ID =
            Schema.Monthly_Report__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Monthly_Report_Usual').getRecordTypeId();

    private static final String MONTHLY_REPORT_RELATED_LIST_FIELDSET = 'Fields_for_related_list_for_Project';
    private static final String MONTHLY_REPORT_GENERATE_INVOICE_COMPONENT_FIELDSET = 'Fields_for_generate_invoice_component';
    private static final String REPORTS_WITH_INVOICE_BUDGET_TRANSACTION_FROM_ACCRUAL = 'You can\'t change Monthly Report that have Invoice generated from related Accrual';
    private static final String REPORTS_BUDGET_TRANSACTION_PENDING_APPROVE_OR_APPROVED =
            'You can\'t change Fact Hours value, because this Monthly Report have related Pending or Approved Budget Transaction';
    private static final String PARENT_PROJECT_RECORD_TYPE_NAME = 'Parent';
    private static final String WORKING_DAYS_MDT_LABEL = 'Working Days';
    private static final Integer DAY_NO_IN_START_DATE = 1;
    private static final Set<String> ALLOCATION_TYPES = new Set<String>{'Leave','Overrun'};
    private static final String CODE_DEFAULT = 'UA';
    public static final Set<Id> BUDGET_TRANSACTION_ACCRUAL_RECORDTYPE_IDS = new Set<Id>{
            Schema.Budget_Transaction__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Accrual_FixCost').getRecordTypeId(),
            Schema.Budget_Transaction__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Accrual_TnM').getRecordTypeId()
    };
    public static final Id BUDGET_TRANSACTION_INVOICE_RECORDTYPE_ID = Schema.Budget_Transaction__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Invoice').getRecordTypeId();

    private static Map<String, String> mapStationByCode{
        get{
            if (mapStationByCode == null) {
                mapStationByCode = getMapStationByCode();
            }
            return mapStationByCode;
        }
        private set;
    }

    MonthlyReportSelector monthReportSelector = new MonthlyReportSelector();
    AllocationSelector allocationSelector = new AllocationSelector();
    /**
     * Checking record type for Allocation, for RecordType 'Project' only allowed report creation
     *
     * @param recordId record Id, Allocation/Project for report generation
     *
     * @return Boolean is record valid for report generation arrived
     */
    public Boolean isRecordValidForProcess(Id recordId) {

        if (recordId.getSobjectType() == PROJECT_TYPE) {

            return true;
        }

        if (recordId.getSobjectType() == ALLOCATION_TYPE) {
            List<Allocation__c> allocations = allocationSelector.getSingleAllocation(recordId);

            if (!allocations.isEmpty() && allocations[0].RecordTypeId == ALLOCATION_RECORD_TYPE_PROJECT_ID) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }
    /**
     * Checking is related Project has Record Type Parent
     *
     * @param allocationId for report generation
     *
     * @return Boolean  is Project Record Type Parent
     */
    public Boolean isProjectParen(Id allocationId) {
        List<Allocation__c> allocations = allocationSelector.getSingleAllocation(allocationId);

        Boolean isProjectParen = !allocations.isEmpty() && allocations[0].Project__r.RecordTypeId == PROJECT_RECORD_TYPE_PARENT_ID ? true : false;

        return isProjectParen ;
    }


    /**
     * Getting month names from picklist field in Monthly Report object
     *
     * @return List<String> months names
     */
    public List<String> getMonthsNames() {
        List<String> monthNames = new List<String>();
        for (PicklistEntry entry : MONTH_NAMES.getDescribe().getPicklistValues()) {
            monthNames.add(entry.getLabel());
        }

        return monthNames;
    }
    /**
     * Getting list years, based on Start/End date's year, and all years between them
     *
     * @param recordId - recordId, Allocation or Project
     *
     * @return List<String> - list of years as string
     */
    public List<String> getYearsRange(Id recordId) {
        List<SObject> fetchedRecord = new List<SObject>();
        SObjectType recordType = recordId.getSobjectType();

        fetchedRecord = new DateRangeSelector(recordId.getSobjectType()).selectRequiredSObjectWithDates(recordId);

        return generateListWithYears(getYearDiapason(fetchedRecord, recordType));
    }

    public List<String> getYearsRangeWithOneYearAgo(Id recordId) {
        List<String> yearsDiapason = getYearsRange(recordId);
        List<String> resultYearsDiapason = new List<String>();
        Integer currentYear = System.now().year();

        for (String year : yearsDiapason) {
            if (Integer.valueOf(year) >= currentYear - 1) {
                resultYearsDiapason.add(year);
            }
        }

        return resultYearsDiapason;
    }

    private List<String> generateListWithYears(YearRange range) {
        List<String> years = new List<String>();
        if (range == null) {
            return years;
        }
        Integer i = range.rangeStart;
        while (i <= range.rangeEnd) {
            years.add(String.valueOf(i));
            i++;
        }

        return years;
    }

    private YearRange getYearDiapason(List<SObject> recordToGetInfo, SObjectType recordType) {
        if (recordToGetInfo.isEmpty()) {
            return null;
        }
        YearRange range = new YearRange();

        SObject record = recordToGetInfo[0];
        range.rangeStart = ((Date) record.get(DateRangeSelector.START_DATES_BY_TYPE.get(recordType))).year();
        range.rangeEnd = ((Date) record.get(DateRangeSelector.END_DATES_BY_TYPE.get(recordType))).year();

        return range;
    }

    /**
     * Creating reports if possible and sending operation success/help message for front
     *
     * @param recordId - record Id, Project or Allocation, for which will reports be createn
     * @param months - list of month number for setting report diapason, currently working with only value selected
     * @param years - list of year number for setting report diapason, currently working with only value selected
     *
     * @return MonthlyReportController.Result - result of operation(successfull creation/no creation) and info about that
     */
    public MonthlyReportController.Result createReports(Id recordId, List<String> months, List<String> years) {

        SObjectType recordType = recordId.getSobjectType();
        String periodAsString = getDatePeriodFromInput(months, years);

        // logic for Project is deleted from this button (Generate report) and passed to
        // logic isn't deleted from the code.... only committed

//        if (recordType == PROJECT_TYPE) {
//
//            return createReportsForProject(recordId, periodAsString);
//        } else
                if (recordType == ALLOCATION_TYPE) {

            return createReportForAllocation(recordId, periodAsString);
        }

        return new MonthlyReportController.Result(false, 'Unhandled SObjectType arrived');
    }

    /**
     * Generate and update fields in Monthly report if Fact hours changed based on formulas. If related fields which are using in formula
     * have different currency then result in  to Monthly report currency by ConversionRate in CurrencyType
     *
     * @param newMonthlyReport - list of new records
     * @param oldMonthlyReportsByIds - list of old records
     */
    public void sortReportByFactHoursAndFillFields(List<Monthly_Report__c> newMonthlyReport, Map<Id, Monthly_Report__c> oldMonthlyReportsByIds) {
        Set<Id> reportsIds = new Set<Id>();
        Set<Id> contractorsIds = new Set<Id>();

        for (Monthly_Report__c report : newMonthlyReport) {
            if (isFieldsChanged(report, oldMonthlyReportsByIds)) {
                if (report.RecordTypeId == MONTHLY_REPORT_RECORD_TYPE_DETAILED_ID) {
                    reportsIds.add(report.Monthly_Report_General__c);
                } else {
                    reportsIds.add(report.Id);
                }
           }
            if(isContractorOrFactHoursChanged(report, oldMonthlyReportsByIds)){
                if(report.Id == null){
                    contractorsIds.add(report.Id);
                } else {
                    contractorsIds.add(oldMonthlyReportsByIds.get(report.Id).Contractor__c);
                }
            }
        }

        if (!reportsIds.isEmpty()) {

            this.updateFields(reportsIds);
        }
        if (!contractorsIds.isEmpty()) {
            System.enqueueJob(new ContractorFactHoursCalculateQueue(contractorsIds));
        }
    }

    private Boolean isContractorOrFactHoursChanged(Monthly_Report__c report, Map<Id, Monthly_Report__c> oldMonthlyReportsByIds) {
        return report.Fact_hours__c != oldMonthlyReportsByIds.get(report.Id).Fact_hours__c || report.Contractor__c != oldMonthlyReportsByIds.get(report.Id).Contractor__c
                && (report.Contractor__c != null || oldMonthlyReportsByIds.get(report.Id).Contractor__c != null);
    }
    public void checkContractorsAndUpdateThem(List<Monthly_Report__c> monthlyReports) {
        System.debug('Reports--> ' + monthlyReports);
        Set<Id> contractorsIds = new Set<Id>();
        for(Monthly_Report__c report: monthlyReports){
            if (report.Contractor__c != null && report.Fact_hours__c != null) {
                contractorsIds.add(report.Contractor__c);
            }
        }
        System.enqueueJob(new ContractorFactHoursCalculateQueue(contractorsIds));
    }

    /**
     * Recalculate and update fields in Monthly report if Currency changed by ConversionRate in CurrencyType
     *
     * @param monthlyReport - list of new records
     * @param oldMonthlyReportsByIds - list of old records
     */
    public void recalculateFieldByCurrency(List<Monthly_Report__c> monthlyReports, Map<Id, Monthly_Report__c> oldMonthlyReportsByIds) {
        List<Monthly_Report__c> changedMonthlyReports = new List<Monthly_Report__c>();

        for (Monthly_Report__c report: monthlyReports){
            if (report.CurrencyIsoCode != oldMonthlyReportsByIds.get(report.Id).CurrencyIsoCode) {
                changedMonthlyReports.add(report);
            }
        }

        if (!changedMonthlyReports.isEmpty()) {
//            List<Monthly_Report__c> copyMonthlyReports = monthReportSelector.getMonthlyReports(mr);
            Map<String, Decimal> currencyCoefficient = this.getCurrencyCoefficientTest(changedMonthlyReports);

            for (Monthly_Report__c monthlyReport : monthlyReports) {
                Decimal oldReportCurrencyCoefficient = currencyCoefficient.get(oldMonthlyReportsByIds.get(monthlyReport.Id).Monthly_Report_Start_Date__c.addMonths(1) + oldMonthlyReportsByIds.get(monthlyReport.Id).CurrencyIsoCode);
                Decimal newReportCurrencyCoefficient = currencyCoefficient.get(monthlyReport.Monthly_Report_Start_Date__c.addMonths(1) + monthlyReport.CurrencyIsoCode);

                if (isChangedCurrencyAndFieldsFill(monthlyReport, oldMonthlyReportsByIds)) {
                    monthlyReport.Hourly_cost__c = monthlyReport.Hourly_cost__c / oldReportCurrencyCoefficient * newReportCurrencyCoefficient;
                    monthlyReport.Company_monthly_cost_with_overhead__c = monthlyReport.Company_monthly_cost_with_overhead__c / oldReportCurrencyCoefficient
                            * newReportCurrencyCoefficient;
                    monthlyReport.Company_monthly_cost_without_overhead__c = monthlyReport.Company_monthly_cost_without_overhead__c / oldReportCurrencyCoefficient
                            * newReportCurrencyCoefficient;
                }

                if(monthlyReport.Monthly_revenueNew__c != null && !ALLOCATION_TYPES.contains(monthlyReport.Allocation_Type__c)){
                    monthlyReport.Monthly_revenueNew__c = monthlyReport.Monthly_revenueNew__c / oldReportCurrencyCoefficient
                                * newReportCurrencyCoefficient;
                }
            }
        }
    }

    /**
     * Create report by Values which we got from Matrix Project page
     *
     * @param projectsIdsByAllocationId
     * @param mainProjectId
     * @param month
     * @param year
     *
     * @return
     */
    public MonthlyReportController.Result createReports(Set<String> allocationIds, Id mainProjectId, String month, String year) {
        //Map<Id, Monthly_Report__c> monthlyReportsByAllocationId = new Map<Id, Monthly_Report__c>();
        List<Monthly_Report__c> monthlyReports = new List<Monthly_Report__c>();
        Map<String, List<String>> periodsReportByProjectIdAndAllocationId = new Map<String, List<String>>();
        //Map<String, List<String>> childReportByProjectIdAndAllocationId = new Map<String, List<String>>();
        Map<Id, Id> generalReportIdByAllocationId = new Map<Id, Id>();
        String period = month + ' ' + year;

        // check if we have created reports on this project and allocation for the selected period and add to map if has

        List<Monthly_Report__c> reportsInSystem = monthReportSelector.getReportsByProjectIdAndAllocationAndPeriod(
                mainProjectId,
                allocationIds,
                period
        );

        for (Monthly_Report__c reportInSystem : reportsInSystem) {

            String key = (String) reportInSystem.Project__c + reportInSystem.Allocation__c;

            if (periodsReportByProjectIdAndAllocationId.containsKey(key)) {

                periodsReportByProjectIdAndAllocationId.get(key).add(reportInSystem.Monthly_Report_Period__c);
            } else {

                periodsReportByProjectIdAndAllocationId.put(key, new List<String>{
                        reportInSystem.Monthly_Report_Period__c});
            }

            generalReportIdByAllocationId.put(reportInSystem.Allocation__c, reportInSystem.Id);

        // same actions we do with children report if we works with Parent Record Type Project

            /*for (Monthly_Report__c childReport: reportInSystem.Monthly_Reports__r){
                if (childReportByProjectIdAndAllocationId.containsKey(period + ' ' + year)) {

                    childReportByProjectIdAndAllocationId.get(key + reportInSystem.Monthly_Report_Period__c).add(childReport.Project__c);

                }else{

                    childReportByProjectIdAndAllocationId.put(key + reportInSystem.Monthly_Report_Period__c, new List<String>{childReport.Project__c} );

                }
            }*/
        }

        Project__c project = [
                SELECT
                        Id,
                        RecordTypeId
                FROM Project__c
                WHERE Id = :mainProjectId LIMIT 1];

        List<Allocation__c> allocations = allocationSelector.getWithDataByIds(allocationIds);
                        // create reports by selected allocations (General or Usual Record Type)
        BusinessHours bHours = [SELECT Id FROM BusinessHours WHERE Name ='WorkingDays'];

        Date dateReport = convertPeriodToDateFormat(period);

        Map<String, Map<Date, Holiday>> mapCodeByHolidays = getMapCodeByHolidays(getListHolidays(dateReport, dateReport.addMonths(1)));

        for (Allocation__c allocation : allocations) {
            String key = (String) mainProjectId + allocation.Id;
            String code = mapStationByCode.containsKey(allocation.Station__c)?
                    mapStationByCode.get(allocation.Station__c): CODE_DEFAULT;

            if ((!periodsReportByProjectIdAndAllocationId.containsKey(key) || !periodsReportByProjectIdAndAllocationId.get(key).contains(period))
                    && this.hasAllocationReportPeriod(dateReport, allocation)) {

                Map<Date, Holiday> mapHolidays = mapCodeByHolidays.containsKey(code)?
                        mapCodeByHolidays.get(code): new Map<Date, Holiday>();
                Integer workingDay = getNoOfBusinessDaysBetweenDates(allocation, bHours, mapHolidays, dateReport);

                Monthly_Report__c report = new Monthly_Report__c();
                report.Contractor__c = allocation.Contractor__c;
                report.Allocation__c = allocation.Id;
                report.Project__c = mainProjectId;
                report.Plan_hours__c = (workingDay * 8) * allocation.Allocation__c / 100;
                report.CurrencyIsoCode = allocation.Project__r.Account__r.CurrencyIsoCode;
                report.Monthly_Report_Period__c = period;
                report.Monthly_Report_Start_Date__c = convertPeriodToDateFormat(period);
                report.Monthly_Report_End_Date__c = report.Monthly_Report_Start_Date__c.addMonths(1).addDays(-1);
                report.RecordTypeId = project.RecordTypeId == PROJECT_RECORD_TYPE_PARENT_ID
                        ? MONTHLY_REPORT_RECORD_TYPE_GENERAL_ID
                        : MONTHLY_REPORT_RECORD_TYPE_USUAL_ID;

                //monthlyReportsByAllocationId.put(allocation.Id, report);
                monthlyReports.add(report);
            }
        }

        /*if (!monthlyReportsByAllocationId.keySet().isEmpty()) {

            insert monthlyReportsByAllocationId.values();
        }*/

        // create Detailed Record Type Report for General Record Type report  if Project Record Type is Parent

        /*if (project.RecordTypeId == PROJECT_RECORD_TYPE_PARENT_ID) {
            for (Allocation__c elem : allocations) {
                for (Object childProjectId : projectsIdsByAllocationId.get(elem.Id)) {
                    if (childProjectId != project.Id) {
                        String key = (String) elem.Project__c + elem.Id + month + ' ' + year;

                        if (!childReportByProjectIdAndAllocationId.containsKey(key)
                                || (!childReportByProjectIdAndAllocationId.get(key).contains((Id) childProjectId))) {

                            Monthly_Report__c report = new Monthly_Report__c();
                            report.RecordTypeId = MONTHLY_REPORT_RECORD_TYPE_DETAILED_ID;
                            report.Contractor__c = elem.Contractor__c;
                            report.Monthly_Report_Period__c = period;
                            report.Monthly_Report_Start_Date__c = convertPeriodToDateFormat(period);
                            report.Monthly_Report_End_Date__c = report.Monthly_Report_Start_Date__c.addMonths(1).addDays(-1);
                            report.Allocation__c = elem.Id;
                            report.Project__c = (Id) childProjectId;
                            report.Monthly_Report_General__c = monthlyReportsByAllocationId.containsKey(elem.Id) ? monthlyReportsByAllocationId.get(elem.Id).Id : generalReportIdByAllocationId.get(elem.Id);

                            monthlyReports.add(report);
                        }
                    }
                }
            }
        }*/

        if (!monthlyReports.isEmpty()) {
            insert monthlyReports;
        } else {
            return new MonthlyReportController.Result(false, 'There is no reports to insert');
        }/*else if (monthlyReportsByAllocationId.keySet().isEmpty()){
            return new MonthlyReportController.Result(false, 'You try to create Monthly report from Allocation without this period.');
        }*/

        return new MonthlyReportController.Result(true, 'Report was successfully created');
    }

    public Boolean validateMonthlyReports(List<Monthly_Report__c> reports){
        if (!reports.isEmpty()) {
            List<Monthly_Report__c> reportsWithBudgetTransactions = [SELECT Budget_Transaction_item__r.Budget_Transaction__c, Budget_Transaction_item__c FROM Monthly_Report__c WHERE Id IN :reports];

            Boolean havePendingOrApprovedBudgetTransactions = doMonthlyReportsHavePendingOrApprovedBudgetTransactions(reportsWithBudgetTransactions);

            if (havePendingOrApprovedBudgetTransactions) {
                reports[0].addError(REPORTS_BUDGET_TRANSACTION_PENDING_APPROVE_OR_APPROVED);

                return false;
            }
        }

        return true;
    }

    public Boolean doMonthlyReportsHavePendingOrApprovedBudgetTransactions(List<Monthly_Report__c> reports) {
        Set<Id> pendingProcessInstancesObjectIds = new Set<Id>();

        for (ProcessInstance pendingProcessInstance : [SELECT Id, TargetObjectId FROM ProcessInstance WHERE Status IN ('Pending', 'Approved')]) {
            pendingProcessInstancesObjectIds.add(pendingProcessInstance.TargetObjectId);
        }

        for (Monthly_report__c report : reports) {

            if (report.Budget_Transaction_item__c != null) {
                if (pendingProcessInstancesObjectIds.contains(report.Budget_Transaction_item__r.Budget_Transaction__c)) {
                    return true;
                }
            }
        }

        return false;
    }

    public Boolean validateMonthlyReports(Map<Id, Monthly_Report__c> oldReports, List<Monthly_Report__c> newReports){
        return
                validateChangeFactHours(oldReports, newReports) &&
                validateChangeReportWithRelatedInvoice(newReports);
    }

    public Boolean validateChangeFactHours(Map<Id, Monthly_Report__c> oldReports, List<Monthly_Report__c> newReports) {
        List<Monthly_Report__c> changedReports = new List<Monthly_Report__c>();

        for (Monthly_Report__c newReport : newReports){
            if (oldReports.get(newReport.Id).Fact_hours__c != newReport.Fact_hours__c){
                changedReports.add(newReport);
            }
        }

        if (!changedReports.isEmpty()) {
            return validateMonthlyReports(changedReports);
        }

        return true;
    }

    public Boolean validateChangeReportWithRelatedInvoice(List<Monthly_Report__c> newReports) {

        for (Monthly_Report__c report : [SELECT Budget_transaction_item__r.Budget_transaction_item__r.Budget_transaction__c FROM Monthly_Report__c WHERE Id IN :newReports]) {
            if (report.Budget_transaction_item__r.Budget_transaction_item__r.Budget_transaction__c != null) {
                newReports[0].addError(REPORTS_WITH_INVOICE_BUDGET_TRANSACTION_FROM_ACCRUAL);

                return false;
            }
        }

        return true;
    }

    public void sortAllocationWithChangedHours(List<Allocation__c> newAllocations, Map<Id, Allocation__c> oldAllocationsByIds){
        Set<Id> allocationsIds = new Set<Id>();
        for (Allocation__c allocation: newAllocations){
            if (allocation.Expected_Rate__c != oldAllocationsByIds.get(allocation.Id).Expected_Rate__c
                    || allocation.Expected_Rate_Daily__c != oldAllocationsByIds.get(allocation.Id).Expected_Rate_Daily__c
                    || allocation.Expected_Rate_Monthly__c != oldAllocationsByIds.get(allocation.Id).Expected_Rate_Monthly__c) {

                allocationsIds.add(allocation.Id);
            }
        }
        Set<Id> reportsIds = monthReportSelector.getReportsByAllocationsIds(allocationsIds);
        if (!reportsIds.isEmpty()) {

            this.updateFields(reportsIds);
        }
    }

    public void getReportsBySalaryHistoryAndUpdateThem(List<Salary_History__c> salaryHistories) {
        Set<Id> contractorsIds = new Set<Id>();
        for (Salary_History__c salaryHistory : salaryHistories) {
            contractorsIds.add(salaryHistory.Contractor__c);
        }

        Map<Id, Monthly_Report__c> reportsByIds = new Map<Id, Monthly_Report__c>([
                SELECT Id
                FROM Monthly_Report__c
                WHERE Salary_History__c IN :salaryHistories
                OR (Contractor__c IN :contractorsIds AND Salary_History__c = null)
        ]);

        if (!reportsByIds.isEmpty()) {

            this.updateFields(reportsByIds.keySet());
        }
    }

    private Boolean hasAllocationReportPeriod(Date dateReport, Allocation__c allocation) {
        return (dateReport >= allocation.Start_date__c.toStartOfMonth() && dateReport <= allocation.End_date__c);
    }


    public void updateFields(Set<Id> monthlyReport) {
        List<Monthly_Report__c> reports = monthReportSelector.getMonthlyReportsWithFieldMonthlyReports(monthlyReport);
        Map<String, Decimal> currencyCoefficient = this.getCurrencyCoefficientTest(reports);

        //reports = this.recalculateHoursByDetailedReports(reports);
        Map<Id, List<Salary_History__c>> salaryHistoryByDateAndContractor = this.getSalaryHistoriesByContractor(reports);

        //CHECK THIS
        Decimal workingDays = this.getWorkingDays();

        for (Monthly_Report__c report : reports) {

            Salary_History__c salary = new Salary_History__c();

            Boolean isSalaryHistory = true;

            if (salaryHistoryByDateAndContractor.containsKey(report.Contractor__c)) {

                salary = getSalaryByReportAndSalaryHistory(report, salaryHistoryByDateAndContractor.get(report.Contractor__c));

            }

            if((salary == null || salary.Salary__c == null) && report.Contractor__r.Salary__c != null){
                salary = new Salary_History__c(Salary__c = report.Contractor__r.Salary__c, CurrencyIsoCode = report.Contractor__r.CurrencyIsoCode);
                isSalaryHistory = false;
            }
            if (report.Fact_hours__c != null && salary.Salary__c != null) {

                Decimal contractorSalaryInMainCurrency = salary.Salary__c / currencyCoefficient.get(report.Monthly_Report_Start_Date__c.addMonths(1)  + salary.CurrencyIsoCode);
                System.debug('salary.Salary__c---> ' + salary.Salary__c);
                System.debug('report.Fact_hours__c---> ' + report.Fact_hours__c);
                System.debug('contractorSalaryInMainCurrency '+ contractorSalaryInMainCurrency);
                System.debug('currencyCoefficient ' + currencyCoefficient.get(report.Monthly_Report_Start_Date__c.addMonths(1)  + salary.CurrencyIsoCode));
                Decimal reportCurrencyCoefficient = currencyCoefficient.get(report.Monthly_Report_Start_Date__c.addMonths(1)  + report.CurrencyIsoCode);

                // calculate value in corporate currency
                report.Hourly_cost__c = ((contractorSalaryInMainCurrency / report.Coefficient_1__c) + report.Coefficient_2__c)
                        / (workingDays * 8);
                // convert value in report currency by currency rate
                report.Hourly_cost__c = report.Hourly_cost__c * reportCurrencyCoefficient;

                report.Company_monthly_cost_with_overhead__c = report.Fact_hours__c * report.Hourly_cost__c;
                report.Company_monthly_cost_without_overhead__c = (contractorSalaryInMainCurrency / (8 * workingDays))
                        * reportCurrencyCoefficient * report.Fact_hours__c;
                System.debug('workingDays ' + workingDays);
                System.debug('Company_monthly_cost_without_overhead__c ' + report.Company_monthly_cost_without_overhead__c );
                if (isSalaryHistory) {
                    report.Salary_History__c = salary.Id;
                }


            }
            if (report.Fact_hours__c != null && !ALLOCATION_TYPES.contains(report.Allocation__r.Allocation_Type__c)) {
                report.Monthly_revenueNew__c = calculateRevenueByContractType(report, currencyCoefficient);
            }
        }

        if (!reports.isEmpty()) {
            update reports;
        }
    }

    private List<Monthly_Report__c> recalculateHoursByDetailedReports(List<Monthly_Report__c> reports) {
        for (Monthly_Report__c report : reports) {
            if (report.RecordTypeId == MONTHLY_REPORT_RECORD_TYPE_GENERAL_ID) {

                report.Fact_hours__c = 0;

                for (Monthly_Report__c elem : report.Monthly_Reports__r) {
                    if (elem.Fact_hours__c != null) {

                        report.Fact_hours__c += elem.Fact_hours__c;
                    }
                }
            }
        }

        return reports;
    }

    private Map<Id, List<Salary_History__c>> getSalaryHistoriesByContractor(List<Monthly_Report__c> monthlyReports) {
        Map<Id, List<Salary_History__c>> result = new Map<Id, List<Salary_History__c>>();
        Set<Date> dates = new Set<Date>();
        Set<Id> contrIds = new Set<Id>();

        for (Monthly_Report__c monthlyReport : monthlyReports) {
            if (monthlyReport.Monthly_Report_Start_Date__c != null) {

                dates.add(monthlyReport.Monthly_Report_Start_Date__c.addMonths(1).addDays(-1));
            }

            contrIds.add(monthlyReport.Contractor__c);
        }

        List<Salary_History__c> salaryHistories = [SELECT Contractor__c
                                                        , CurrencyIsoCode
                                                        , Contractor__r.Name
                                                        , Salary__c
                                                        , Start_Date__c
                                                    FROM Salary_History__c
                                                    WHERE Contractor__c IN :contrIds
                                                    AND Start_Date__c <= :dates
                                                    ORDER BY Start_Date__c DESC, Name DESC
        ];

        System.debug('Salary---> ' + salaryHistories);

        for (Salary_History__c salaryHistory : salaryHistories) {
            if (result.containsKey(salaryHistory.Contractor__c)) {

                result.get(salaryHistory.Contractor__c).add(salaryHistory);
            } else {

                result.put(salaryHistory.Contractor__c, new List<Salary_History__c>{
                        salaryHistory
                });
            }
        }

        return result;
    }

    private Boolean isChangedCurrencyAndFieldsFill(Monthly_Report__c monthlyReport, Map<Id, Monthly_Report__c> oldMonthlyReports) {
        Boolean isFieldFill = (monthlyReport.Hourly_cost__c != null &&
                monthlyReport.Company_monthly_cost_with_overhead__c != null &&
                monthlyReport.Company_monthly_cost_without_overhead__c != null);

        return (isFieldFill);
    }


    private Decimal calculateRevenueByContractType(Monthly_Report__c report, Map<String, Decimal> currencyCoefficient) {
        if (report.Allocation__r.Billing_type__c != 'Monthly') {
            if (report.Allocation__r.Contract_Type__c == 'Cost+'
                    && report.Allocation__r.Expected_Rate__c != null
                    && report.Hourly_cost__c != null) {

                return report.Fact_hours__c * report.Hourly_cost__c / 0.75;
            } else if (report.Allocation__r.Contract_Type__c != 'Cost+'
                    && report.Allocation__r.Expected_Rate__c != null) {

                System.debug('REPORT_START_DAY---> ' + report.Monthly_Report_Start_Date__c + ' CURRENCY_OF_REPORT---> ' + report.CurrencyIsoCode);
                System.debug('ALLOCATION_CURRENCY---> ' + report.Allocation__r.CurrencyIsoCode);
                System.debug('ALLOCATION_RATE_CURRENCY---> ' + currencyCoefficient.get(report.Monthly_Report_Start_Date__c.addMonths(1) + report.Allocation__r.CurrencyIsoCode));
                System.debug('PROJECT_RATE_CURRENCY---> ' + currencyCoefficient.get(report.Monthly_Report_Start_Date__c.addMonths(1) + report.CurrencyIsoCode));

                return (report.Fact_hours__c * report.Allocation__r.Expected_Rate__c / currencyCoefficient.get(report.Monthly_Report_Start_Date__c.addMonths(1) + report.Allocation__r.CurrencyIsoCode))
                        * currencyCoefficient.get(report.Monthly_Report_Start_Date__c.addMonths(1) + report.CurrencyIsoCode);
            }
        } else if (report.Allocation__r.Billing_type__c == 'Monthly') {
            BusinessHours bHours = [SELECT Id FROM BusinessHours WHERE Name = 'WorkingDays'];

            Date dateReport = convertPeriodToDateFormat(report.Monthly_Report_Period__c);

            Map<String, Map<Date, Holiday>> mapCodeByHolidays = getMapCodeByHolidays(getListHolidays(dateReport, dateReport.addMonths(1)));

            String code = mapStationByCode.containsKey(report.Allocation__r.Station__c) ?
                    mapStationByCode.get(report.Allocation__r.Station__c) : CODE_DEFAULT;

            Map<Date, Holiday> mapHolidays = mapCodeByHolidays.containsKey(code) ?
                    mapCodeByHolidays.get(code) : new Map<Date, Holiday>();

            Decimal result =
                    report.Allocation__r.Expected_Rate_Monthly__c == null ?
                            0 :
                            report.Allocation__r.Expected_Rate_Monthly__c * ((report.Fact_hours__c / 8) / getNoOfBusinessDaysBetweenDates(new Allocation__c(Start_date__c = dateReport, End_date__c = dateReport.addMonths(1).addDays(-1)), bHours, mapHolidays, dateReport));

            /*if (report.Allocation__r.Contract_Type__c == 'Cost+'
                    && report.Allocation__r.Expected_Rate__c != null 1000 * ((184 / 8) / 21)
                    && report.Hourly_cost__c != null) {

                return result / 0.75;
            } else if (report.Allocation__r.Contract_Type__c != 'Cost+'
                    && report.Allocation__r.Expected_Rate__c != null) {*/

                return (result / currencyCoefficient.get(report.Monthly_Report_Start_Date__c.addMonths(1) + report.Allocation__r.CurrencyIsoCode))
                        * currencyCoefficient.get(report.Monthly_Report_Start_Date__c.addMonths(1) + report.CurrencyIsoCode);
            //}
        }

        return 0;
    }

    private Boolean isFieldsChanged(Monthly_Report__c monthlyReport, Map<Id, Monthly_Report__c> oldMonthlyReports) {
        return (monthlyReport.Fact_hours__c != oldMonthlyReports.get(monthlyReport.Id).Fact_hours__c
                    || monthlyReport.Allocation__c != oldMonthlyReports.get(monthlyReport.Id).Allocation__c
                    || monthlyReport.RecordTypeId != oldMonthlyReports.get(monthlyReport.Id).RecordTypeId
                    || monthlyReport.Allocation_Type__c != oldMonthlyReports.get(monthlyReport.Id).Allocation_Type__c
                    || monthlyReport.Monthly_Report_Start_Date__c != oldMonthlyReports.get(monthlyReport.Id).Monthly_Report_Start_Date__c
                    || monthlyReport.Project__c != oldMonthlyReports.get(monthlyReport.Id).Project__c
                    || monthlyReport.CurrencyIsoCode != oldMonthlyReports.get(monthlyReport.Id).CurrencyIsoCode
                    || monthlyReport.Monthly_revenueNew__c != oldMonthlyReports.get(monthlyReport.Id).Monthly_revenueNew__c
                    || monthlyReport.Salary_History__c != oldMonthlyReports.get(monthlyReport.Id).Salary_History__c
                    || monthlyReport.Name != oldMonthlyReports.get(monthlyReport.Id).Name
                    || monthlyReport.Monthly_Report_General__c != oldMonthlyReports.get(monthlyReport.Id).Monthly_Report_General__c
        );
    }

    private MonthlyReportController.Result createReportForAllocation(
            Id recordId,
            String periodAsString
    ) {
        List<Allocation__c> allocations = allocationSelector.getSingleAllocation(recordId);
        Allocation__c allocation;

        if (allocations.isEmpty()) {

            return new MonthlyReportController.Result(false, 'Sorry, but allocation was already deleted. Reload page');
        } else {
            allocation = allocations[0];
        }

        if (!isReportRangeInAllocationDateDiapason(allocation, periodAsString)) {

            return new MonthlyReportController.Result(false, 'Select report period inside Allocation Start/End Date');
        }

        if (getMapReportsByDates(recordId).containsKey(periodAsString)) {

            return new MonthlyReportController.Result(false, 'Report on this Allocation for this period already exist');
        }
        if (String.isBlank(allocations[0].Contractor__c)) {
            return new MonthlyReportController.Result(false, 'Sorry, can not find the Contractor in this Allocation');
        }else {

            generateReport(allocations, periodAsString);

            return new MonthlyReportController.Result(true, 'Report was successfully created');
        }
    }

    private Boolean isReportRangeInAllocationDateDiapason(Allocation__c allocation, String period) {
        Date periodAsDate = singleMonthReportStartDate(period);

        if ((allocation.End_date__c >= periodAsDate) && (periodAsDate >= allocation.Start_date__c)) {

            return true;
        } else if ((allocation.Start_date__c.year() == periodAsDate.year() && allocation.Start_date__c.month() == periodAsDate.month())
                        || (allocation.End_date__c.year() == periodAsDate.year() && allocation.End_date__c.month() == periodAsDate.month())) {

            return true;
        } else {

            return false;
        }
    }

    private Date singleMonthReportStartDate(String period) {
        List<String> monthAndYear = period.split(' ');

        return Date.newInstance(
                Integer.valueOf(monthAndYear[1]),
                Integer.valueOf(convertMonthNameIntoNo(monthAndYear[0])),
                DAY_NO_IN_START_DATE
        );
    }

    private List<Monthly_Report__c> generateReport(
            List<Allocation__c> allocations,
            String periodAsString
    ) {
        List<Monthly_Report__c> reports = new List<Monthly_Report__c>();
        List<Id> projectsParentRecordType = new List<Id>();
        BusinessHours bHours = [SELECT Id FROM BusinessHours WHERE Name ='WorkingDays'];
        Date dateReport = this.convertPeriodToDateFormat(periodAsString);
        Map<String, Map<Date, Holiday>> mapCodeByHolidays = getMapCodeByHolidays(getListHolidays(dateReport, dateReport.addMonths(1)));

        for (Allocation__c allocation : allocations) {
            String code = mapStationByCode.containsKey(allocation.Station__c)?
                    mapStationByCode.get(allocation.Station__c): CODE_DEFAULT;
            Map<Date, Holiday> mapHolidays = mapCodeByHolidays.containsKey(code)?
                    mapCodeByHolidays.get(code): new Map<Date, Holiday>();
            Integer workingDay = this.getNoOfBusinessDaysBetweenDates(allocation, bHours, mapHolidays, dateReport);

            Monthly_Report__c report = new Monthly_Report__c();
            report.Contractor__c = allocation.Contractor__c;
            report.Allocation__c = allocation.Id;
            report.Project__c = allocation.Project__c;
            report.Plan_hours__c = (workingDay * 8) * allocation.Allocation__c / 100;
            report.CurrencyIsoCode = allocation.Project__r.Account__r.CurrencyIsoCode;
            report.Monthly_Report_Period__c = periodAsString;
            report.Monthly_Report_Start_Date__c = convertPeriodToDateFormat(periodAsString);
            report.Monthly_Report_End_Date__c = report.Monthly_Report_Start_Date__c.addMonths(1).addDays(-1);

            if (allocation.Project__r.RecordTypeId == PROJECT_RECORD_TYPE_PARENT_ID) {

                report.RecordTypeId = MONTHLY_REPORT_RECORD_TYPE_GENERAL_ID;
                projectsParentRecordType.add(allocation.Project__c);
            } else {

                report.RecordTypeId = MONTHLY_REPORT_RECORD_TYPE_USUAL_ID;
            }

            reports.add(report);
        }
        if (!reports.isEmpty()) {

            insert reports;
        }
        if (!projectsParentRecordType.isEmpty()) {

            Map<Id, List<Project__c>> childProjectsByParentId = this.getParentProjectsWithChild(projectsParentRecordType);
            List<Monthly_Report__c> reportsDetailRecordType = this.generateReportsDetailRecordType(reports, childProjectsByParentId);

            insert reportsDetailRecordType;
        }

        return reports;
    }

    public Date convertPeriodToDateFormat(String periodAsString) {
        Integer year = Integer.valueOf(periodAsString.split(' ').get(1));
        Integer month = convertMonthNameIntoNo(periodAsString.split(' ').get(0));
        Date dateFormat = Date.newInstance(year, month, 1);

        return dateFormat;
    }

    @TestVisible
    private Map<Id, List<Project__c>> getParentProjectsWithChild(List<Id> parentId) {
        Map<Id, List<Project__c>> result = new Map<Id, List<Project__c>>();
        List<Project__c> childProjects = [SELECT Id, Parent_Project__c FROM Project__c WHERE Parent_Project__c = :parentId];

        for (Project__c project : childProjects) {
            if(!result.containsKey(project.Parent_Project__c)) {
                result.put(project.Parent_Project__c, new List<Project__c>());
            }
            result.get(project.Parent_Project__c).add(project);
        }

        return result;
    }

    @TestVisible
    private List<Monthly_Report__c> generateReportsDetailRecordType(List<Monthly_Report__c> parentReports, Map<Id, List<Project__c>> childProjects) {
        List<Monthly_Report__c> reports = new List<Monthly_Report__c>();
        for (Monthly_Report__c elem : parentReports) {
            if (childProjects.containsKey(elem.Project__c)) {
                for (Project__c project : childProjects.get(elem.Project__c)) {

                    Monthly_Report__c report = new Monthly_Report__c();

                    report.RecordTypeId = MONTHLY_REPORT_RECORD_TYPE_DETAILED_ID;
                    report.Project__c = project.Id;
                    report.Monthly_Report_General__c = elem.Id;
                    reports.add(report);

                }
            }
        }

        return reports;
    }

    private static Map<String, String> getMapStationByCode(){
        Map<String, String> mapStationByCode = new Map<String, String>();
        for(Station_by_Country_prefix__mdt scp: [
                SELECT Id, Country_prefix__c, Station__c
                FROM Station_by_Country_prefix__mdt]) {
            mapStationByCode.put(scp.Station__c, scp.Country_prefix__c);
        }
        return mapStationByCode;
    }

    private Map<String, Map<Date, Holiday>> getMapCodeByHolidays(List<Holiday> lstHolidays){
        Map<String, Map<Date, Holiday>> mapCodeByHolidays = new Map<String, Map<Date, Holiday>>();
        for(Holiday hol: lstHolidays){
            String code = hol.Name.substring(0, 2);
            if(!mapCodeByHolidays.containsKey(code)){
                mapCodeByHolidays.put(code, new Map<Date, Holiday>());
            }
            mapCodeByHolidays.get(code).put(hol.ActivityDate, hol);
        }
        return mapCodeByHolidays;
    }

    private List<Holiday> getListHolidays(Date dtStart, Date dtEnd){
        return [SELECT Id, Name, ActivityDate
                FROM Holiday
                WHERE ActivityDate>=:dtStart AND ActivityDate<=:dtEnd
        ];
    }

    private Map<String, Monthly_Report__c> getMapReportsByDates(Id allocationId) {
        Map<String, Monthly_Report__c> monthlyReportsByDates = new Map<String, Monthly_Report__c>();
        List<Monthly_Report__c> reports = monthReportSelector.getReportsByAllocationId(allocationId);

        for (Monthly_Report__c report : reports) {
            monthlyReportsByDates.put(report.Monthly_Report_Period__c, report);
        }

        return monthlyReportsByDates;
    }

    private class YearRange {
        public Integer rangeStart { get; set; }
        public Integer rangeEnd { get; set; }
    }


    private String getDatePeriodFromInput(List<String> months, List<String> years) {
        Integer monthNo = Integer.valueOf(months[0]);
        Integer i = 1;
        String monthName = '';
        for (PicklistEntry entry : MONTH_NAMES.getDescribe().getPicklistValues()) {
            if (monthNo == i) {

                monthName = entry.getLabel();
                break;
            }

            i++;
        }

        return monthName + ' ' + years[0];
    }

    private Integer convertMonthNameIntoNo(String monthName) {
        Integer i = 1;
        for (PicklistEntry entry : MONTH_NAMES.getDescribe().getPicklistValues()) {
            if (entry.getLabel() == monthName) {

                return i;
            }

            i++;
        }

        return null;
    }

    private Map<String, Decimal> getCurrencyCoefficientTest(List<Monthly_Report__c> monthlyReports) {
        Set<Date> dates = new Set<Date>();
        Map<String, Decimal> currencyRateByDateAndIsoCode = new Map<String, Decimal>();

        for (Monthly_Report__c report: monthlyReports){
            dates.add(report.Monthly_Report_Start_Date__c.addMonths(1));
        }

        List<DatedConversionRate> datedConversionRates = [
                SELECT  ConversionRate,
                        Id,
                        IsoCode,
                        NextStartDate,
                        StartDate,
                        SystemModstamp
                FROM DatedConversionRate
                WHERE StartDate  <= :dates AND NextStartDate  > :dates
        ];

        for (Monthly_Report__c report: monthlyReports){
            for (DatedConversionRate rate: datedConversionRates){

                if (report.Monthly_Report_Start_Date__c.addMonths(1) >= rate.StartDate
                        && report.Monthly_Report_Start_Date__c.addMonths(1) <= rate.NextStartDate) {
                    String key = report.Monthly_Report_Start_Date__c.addMonths(1) + rate.IsoCode;
                    currencyRateByDateAndIsoCode.put(key, rate.ConversionRate);
                }
            }
        }
        System.debug('CURRENCY_MAP-----> ' + currencyRateByDateAndIsoCode);

        return currencyRateByDateAndIsoCode;
    }


    private Decimal getWorkingDays() {
        List<Rates_Coefitients__mdt> workingDayCoefficients = new RatesCoefitientsSelector().getCoefitientsFromMdt(WORKING_DAYS_MDT_LABEL);
        Decimal workingDays = workingDayCoefficients[0].Value__c;

        return workingDays;
    }

    private Salary_History__c getSalaryByReportAndSalaryHistory(Monthly_Report__c monthlyReport, List<Salary_History__c> contractorSalaryHistories) {
        for (Salary_History__c elem : contractorSalaryHistories) {
            if (monthlyReport.Monthly_Report_Start_Date__c.addMonths(1) == elem.Start_Date__c
                    || monthlyReport.Monthly_Report_Start_Date__c.addMonths(1) > elem.Start_Date__c) {

                return elem;
            }
        }

        return null;
    }

    public Integer getNoOfBusinessDaysBetweenDates(Allocation__c allocation, BusinessHours bHours, Map<Date, Holiday> mapHolidays, Date dateReport){
        Integer count = 0;
        Date startDate = allocation.Start_date__c >= dateReport? allocation.Start_date__c :dateReport;
        Date endDate = allocation.End_date__c >= dateReport.addMonths(1).addDays(-1)? dateReport.addMonths(1).addDays(-1) :allocation.End_date__c;
        System.debug(startDate);
        System.debug(endDate);
        System.debug('@@@ mapHolidays: '+mapHolidays);
        while(startDate <= endDate){
            if(BusinessHours.isWithin(bHours.Id, startDate) && !mapHolidays.containsKey(startDate)){
                count++;
            }
            startDate = startDate.addDays(1);
        }
        System.debug('@@@ count: '+count);

        return count;
    }

    public DataTableWrapper getReportsForRelatedList(Id recordId){
        DataTableWrapper dataTable = new DataTableWrapper();

        dataTable.recordsList = monthReportSelector.getReportsByProjectAndParentProjectIdAndFieldSet(recordId, MONTHLY_REPORT_RELATED_LIST_FIELDSET);
        dataTable.fieldsList = getFieldSetFieldsDescribe(MONTHLY_REPORT_RELATED_LIST_FIELDSET);
        dataTable.fieldsTypes = getFieldTypesDescribe(dataTable.fieldsList.values()).fieldsLabelsAndType;

        return dataTable;
    }

    public DataTableWrapper getMonthlyReportsForGenerateInvoiceComponent(String projectId, Boolean generateInvoice){
        List<String> allocationStatuses = new List<String>{'Active', 'Finished'};
        List<String> allocationTypes = new List<String>{'Billable'};
        DataTableWrapper dataTable = new DataTableWrapper();

        dataTable.fieldsList = getFieldSetFieldsDescribe(MONTHLY_REPORT_GENERATE_INVOICE_COMPONENT_FIELDSET);
        MonthlyReportsTypesWrapper reportTypesWrapper = getFieldTypesDescribe(dataTable.fieldsList.values());
        dataTable.fieldsTypes = reportTypesWrapper.fieldsLabelsAndType;
        dataTable.recordsList = monthReportSelector.getMonthlyReportsWithRelatedBudgetTransaction(
                projectId,
                reportTypesWrapper.fieldsToQuery,
                MONTHLY_REPORT_GENERATE_INVOICE_COMPONENT_FIELDSET,
                allocationTypes,
                allocationStatuses
        );

        getListOfUniqueRelatedBudgetTransactions(dataTable);

        return dataTable;
    }

    public void getListOfUniqueRelatedBudgetTransactions(DataTableWrapper dataTable){
        Set<Budget_transaction__c> accrualBudgetTransactions = new Set<Budget_transaction__c>();
        Set<Budget_transaction__c> invoiceBudgetTransactions = new Set<Budget_transaction__c>();

        for (Monthly_Report__c report : dataTable.recordsList){
            Budget_transaction__c relatedBudgetTransaction;

            if (report.Budget_transaction_item__r.Budget_transaction_item__c != null) {
                Budget_transaction__c invoiceBudgetTransaction = report.Budget_transaction_item__r.Budget_transaction_item__r.Budget_transaction__r;
                Budget_transaction__c accrualBudgetTransaction = report.Budget_transaction_item__r.Budget_transaction__r;

                if (checkForInvoiceBudgetTransaction(invoiceBudgetTransaction)) {
                    invoiceBudgetTransactions.add(invoiceBudgetTransaction);
                }

                if (checkForAccrualBudgetTransaction(accrualBudgetTransaction)) {
                    accrualBudgetTransactions.add(accrualBudgetTransaction);
                }
            } else {
                relatedBudgetTransaction = report.Budget_transaction_item__r.Budget_transaction__r;
            }

            if (relatedBudgetTransaction != null) {
                if (!accrualBudgetTransactions.contains(relatedBudgetTransaction) && !invoiceBudgetTransactions.contains(relatedBudgetTransaction)) {
                    if (checkForAccrualBudgetTransaction(relatedBudgetTransaction)) {
                        accrualBudgetTransactions.add(relatedBudgetTransaction);
                    } else if (checkForInvoiceBudgetTransaction(relatedBudgetTransaction)) {
                        invoiceBudgetTransactions.add(relatedBudgetTransaction);
                    }
                }
            }
        }

        dataTable.accrualBudgetTransactions = new List<Budget_transaction__c>(accrualBudgetTransactions);
        dataTable.invoiceBudgetTransactions = new List<Budget_transaction__c>(invoiceBudgetTransactions);
    }

    public Boolean checkForInvoiceBudgetTransaction(Budget_transaction__c budgetTransaction) {
        return budgetTransaction.RecordTypeId == BUDGET_TRANSACTION_INVOICE_RECORDTYPE_ID &&
                budgetTransaction.Status__c == 'Draft';
    }

    public Boolean checkForAccrualBudgetTransaction(Budget_transaction__c budgetTransaction) {
        return BUDGET_TRANSACTION_ACCRUAL_RECORDTYPE_IDS.contains(budgetTransaction.RecordTypeId) &&
                budgetTransaction.Accrual_status__c == 'Active' &&
                budgetTransaction.Status__c != 'Rejected';
    }

    public Map<String, String> getFieldSetFieldsDescribe(String fieldset){
        Map<String, String> fieldsLabelAndPath = new Map<String, String>();
        Map<String, Schema.FieldSet> fieldSetMap = Schema.getGlobalDescribe().get('Monthly_Report__c').getDescribe().fieldSets.getMap();
        for (FieldSetMember field : fieldSetMap.get(fieldset).getFields()) {
            if (field.getFieldPath().contains('.')) {
                String fieldLabel = getLabelOfFieldWithParentRelationship(field.getFieldPath());
                fieldsLabelAndPath.put(fieldLabel, field.getFieldPath());
            }
            else {
                fieldsLabelAndPath.put(field.getLabel(), field.getFieldPath());
            }
        }

        return fieldsLabelAndPath;
    }

    public MonthlyReportsTypesWrapper getFieldTypesDescribe(List<String> fieldsApiNames){
        Map<String, String> fieldsLabelsAndType = new Map<String, String>();
        List<String> fieldsToQuery = new List<String>();

        for (String fieldApi : fieldsApiNames) {
            if (fieldApi.contains('.')) {
                String fieldLabel = getLabelOfFieldWithParentRelationship(fieldApi);
                fieldsLabelsAndType.put(fieldLabel, String.valueOf(Schema.DisplayType.REFERENCE));
                continue;
            }

            Schema.DisplayType type = Schema.getGlobalDescribe().get('Monthly_Report__c').getDescribe().fields.getMap().get(fieldApi).getDescribe().getType();
            String label = Schema.getGlobalDescribe().get('Monthly_Report__c').getDescribe().fields.getMap().get(fieldApi).getDescribe().getLabel();

            if (type == Schema.DisplayType.REFERENCE){
                if (fieldApi.contains('__c')){
                    fieldApi = fieldApi.replace('__c', '__r');
                }

                fieldApi += '.Name';

                fieldsToQuery.add(fieldApi);
            }

            fieldsLabelsAndType.put(label, String.valueOf(type));
        }

        return new MonthlyReportsTypesWrapper(fieldsLabelsAndType, fieldsToQuery);
    }

    public String updateReportsFromRelatedList(List<Monthly_Report__c> recordsList) {

        if (!recordsList.isEmpty()) {
            try {
                update recordsList;
                return 'Success';
            } catch (Exception e) {
                if (e.getTypeName() == System.DmlException.class.toString()) {
                    return ((System.DmlException)e).getDmlMessage(0);
                }
                return e.getMessage();
            }
        } else {
            return 'There is nothing to update';
        }
    }

    private String getLabelOfFieldWithParentRelationship(String fieldPath){
        String fieldAPIName = fieldPath.substringAfterLast('.');          //customobject__r.customobject2__r.Name ----> Name
        fieldPath = fieldPath.removeEnd('.' + fieldAPIName);              //customobject__r.customobject2__r.Name ----> Customobject__r.customobject2__r
        String objectTokenPath;                                           //SObject token used in SOQL
        String objectAPIName;                                             //SObject API Name
        String objectLabel;                                               //SObject Label
        String fieldLabel;                                                //Returning field label

        if (fieldPath.contains('.')) {
            objectTokenPath = fieldPath.substringAfterLast('.');          //customobject__r.customobject2__r ----> customobject2__r
        }
        else {
            objectTokenPath = fieldPath;
        }

        if (objectTokenPath.contains('__r')){
            objectTokenPath = objectTokenPath.removeEnd('r') + 'c';        //customobject2__r ----> customobject2__c
        }

        if (objectTokenPath.equalsIgnoreCase('LastModifiedBy') || objectTokenPath.equalsIgnoreCase('CreatedBy')){
            objectAPIName = Schema.getGlobalDescribe().get('User').getDescribe().getName();                             //if we fetch through standard lookup parent field, i.e 'CreatedBy',
            objectLabel = Schema.getGlobalDescribe().get('User').getDescribe().getLabel();                              //which is originally User lookup
        }
        else {
            objectAPIName = Schema.getGlobalDescribe().get(objectTokenPath).getDescribe().getName();
            objectLabel = Schema.getGlobalDescribe().get(objectTokenPath).getDescribe().getLabel();
        }

        fieldLabel = Schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap().get(fieldAPIName).getDescribe().getLabel();
        if (!fieldLabel.contains(objectLabel)){
            fieldLabel = objectLabel + ' ' + fieldLabel;                                                                //If we retreive field without object label in it's own label
        }                                                                                                               //Example got 'Name' from Customobj__c and change to 'Customobj Name'
        if (objectTokenPath.equalsIgnoreCase('LastModifiedBy') || objectTokenPath.equalsIgnoreCase('CreatedBy')){
            fieldLabel = objectTokenPath + fieldLabel;                                                                  //If we retreive field without Standard object label in it's own label
        }                                                                                                               //Example got 'First Name' from CreatedBy and change to 'CreatedBy First Name'
        return fieldLabel;
    }

    public Boolean checkAndValidatePlanHours(List<Monthly_Report__c> monthlyReports, Map<Id, Monthly_Report__c> oldMonthlyReportsByIds) {
        List<Monthly_Report__c> needValidateBlockingPlanHours = new List<Monthly_Report__c>();


        for (Monthly_Report__c report : monthlyReports) {
            if (report.Plan_hours__c != oldMonthlyReportsByIds.get(report.Id).Plan_hours__c) {
                needValidateBlockingPlanHours.add(report);

            }
        }

        if (!needValidateBlockingPlanHours.isEmpty()) {
            return this.doValidationForPlanHours(needValidateBlockingPlanHours);
        }

        return true;
    }

    public Boolean doValidationForPlanHours(List<Monthly_Report__c> reports) {
        User currentUser = [SELECT Id, UserRole.Name, (SELECT Allow_Late_Report_Editing__c FROM Monthly_Report_Editing_Rules__r ORDER BY CreatedDate DESC) FROM User WHERE Id = :UserInfo.getUserId()];
        Integer days = this.getReportBlockingDayForUser() - 1;
        Date pointDate;

        for (Monthly_Report__c report : reports) {
            pointDate = report.Monthly_Report_Start_Date__c.toStartOfMonth().addDays(days);

            if (needToStopChangingReport(pointDate, currentUser)) {
                reports[0].addError('Too late for planning change, please contact responsible person!');
                return false;
            }
        }

        return true;
    }

    private Boolean needToStopChangingReport(Date pointDate, User currentUser) {
        return Date.today() > pointDate
                && (currentUser.Monthly_Report_Editing_Rules__r.isEmpty()
                || !currentUser.Monthly_Report_Editing_Rules__r[0].Allow_Late_Report_Editing__c);
    }

    public Integer getReportBlockingDayForUser() {
        List<Constants_configurations__mdt> rules = [SELECT Monthly_report_blocking_day__c FROM Constants_configurations__mdt];

        Decimal days = 5;

        if (!rules.isEmpty() && rules[0].Monthly_Report_Blocking_Day__c != null) {
            days = rules[0].Monthly_Report_Blocking_Day__c;
        }

        return days.intValue();
    }

    public class MonthlyReportsTypesWrapper {
        public Map<String, String> fieldsLabelsAndType = new Map<String, String>();
        public List<String> fieldsToQuery = new List<String>();

        public MonthlyReportsTypesWrapper(Map<String, String> fieldsLabelsAndType, List<String> fieldsToQuery){
            this.fieldsLabelsAndType = fieldsLabelsAndType;
            this.fieldsToQuery = fieldsToQuery;
        }
    }

    public class DataTableWrapper {
        @AuraEnabled
        public List<Monthly_Report__c> recordsList;
        @AuraEnabled
        public Map<String, String> fieldsList;
        @AuraEnabled
        public Map<String, String> fieldsTypes;
        @AuraEnabled
        public List<Budget_transaction__c> uniqueListOfRelatedBudgetTransactions;
        @AuraEnabled
        public List<Budget_transaction__c> accrualBudgetTransactions;
        @AuraEnabled
        public List<Budget_transaction__c> invoiceBudgetTransactions;
    }

/*------------------------- OLD LOGIC FOR GENERATE REPORT FROM PROJECT BUTTON--------------------------*/

//    private Map<String, Decimal> getCurrencyCoefficient() {
//        Map<String, Decimal> result = new Map<String, Decimal>();
//
//        List<CurrencyType> currencies = [
//                SELECT
//                        ConversionRate,
//                        DecimalPlaces,
//                        Id,
//                        IsActive,
//                        IsoCode
//                FROM CurrencyType
//        ];
//
//        for (CurrencyType elem : currencies) {
//
//            result.put(elem.IsoCode, elem.ConversionRate);
//
//        }
//
//        return result;
//    }
    //    private MonthlyReportController.Result createReportsForProject(
//            Id recordId,
//            String periodAsString
//    ) {
//        List<Allocation__c> allocations =
//                allocationSelector.getAllocationByRecordTypeId(recordId, ALLOCATION_RECORD_TYPE_PROJECT_ID);
//
//        if (allocations.isEmpty()) {
//
//            return new MonthlyReportController.Result(false, 'No valid Allocations were found');
//        }
//
//        allocations = filterAllocationsByReportRange(allocations, periodAsString);
//
//        if (allocations.isEmpty()) {
//
//            return new MonthlyReportController.Result(false, 'No valid Allocations were found in this period');
//        }
//
//        //CHECK LOGIC
//
//        allocations = filterAllocationsWithReports(allocations, periodAsString);
//        List<Monthly_Report__c> reports = generateReport(allocations, periodAsString);
//
//        if (reports.isEmpty()) {
//
//            return new MonthlyReportController.Result(false, 'No reports were generated');
//        }
//
//        return new MonthlyReportController.Result(true, reports.size() + ' reports were created on valid Allocation');
//    }
    //    private List<Allocation__c> filterAllocationsWithReports(List<Allocation__c> allocations, String periodAsString) {
//        List<Allocation__c> allocationsWithoutReports = new List<Allocation__c>();
//
//        List<Monthly_Report__c> monthlyReports = monthReportSelector.getReportsByRangeForAllocations(allocations, periodAsString);
//
//        Map<Id, Monthly_Report__c> mapMonthlyReportsByAllocations = new Map<Id, Monthly_Report__c>();
//        for (Monthly_Report__c report : monthlyReports) {
//
//            mapMonthlyReportsByAllocations.put(report.Allocation__c, report);
//
//        }
//        for (Allocation__c allocation : allocations) {
//            if (!mapMonthlyReportsByAllocations.containsKey(allocation.Id)) {
//
//                allocationsWithoutReports.add(allocation);
//
//            }
//        }
//
//        return allocationsWithoutReports;
//
//    }

//    private List<Allocation__c> filterAllocationsByReportRange(List<Allocation__c> allocations, String periodAsString) {
//        List<Allocation__c> filteredAllocations = new List<Allocation__c>();
//
//        for (Allocation__c allocation : allocations) {
//            if (isReportRangeInAllocationDateDiapason(allocation, periodAsString)) {
//
//                filteredAllocations.add(allocation);
//
//            }
//        }
//
//        return filteredAllocations;
//
//    }




}