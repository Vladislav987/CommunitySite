public without sharing class LW_ContractorOvertimesController {

    private static final String APPROVED = 'Approved';

    private static Map<Integer, String> monthNameByNumber = new Map<Integer, String>{
            1 => 'January'
            , 2 => 'February'
            , 3 => 'March'
            , 4 => 'April'
            , 5 => 'May'
            , 6 => 'June'
            , 7 => 'July'
            , 8 => 'August'
            , 9 => 'September'
            , 10 => 'October'
            , 11 => 'November'
            , 12 => 'December'
    };

    @AuraEnabled(Cacheable = true)
    public static Map<Integer, Map<String, OvertimeWrapper>> getOvertimes() {
        Map<Integer, Map<String, OvertimeWrapper>> overtimeWrapperByMonthByYear = new Map<Integer, Map<String, OvertimeWrapper>>();
        Id contractorId = getContractorId();

        overtimeWrapperByMonthByYear = fillOvertimeWrapper(contractorId, overtimeWrapperByMonthByYear);

        return getOvertimeWrappers(contractorId, overtimeWrapperByMonthByYear);
    }

    private static Map<Integer, Map<String, OvertimeWrapper>> getOvertimeWrappers(Id contractorId, Map<Integer, Map<String, OvertimeWrapper>> overtimeWrapperByMonthByYear) {
        Util_ContractorCalculation contractorCalculationService = new Util_ContractorCalculation();

        for (Monthly_Report__c monthlyReport : getMonthlyReports(contractorId)) {
            Integer year = monthlyReport.Monthly_Report_Start_Date__c.addMonths(1).year();
            String month = monthNameByNumber.get(monthlyReport.Monthly_Report_Start_Date__c.addMonths(1).month());

            if (
                String.isBlank(monthlyReport.Monthly_Report_Period__c)
                || !overtimeWrapperByMonthByYear.containsKey(year)
                || !overtimeWrapperByMonthByYear.get(year).containsKey(month)
            ) {
                continue;
            }

            contractorCalculationService.setNewPeriod(monthlyReport.Monthly_Report_Start_Date__c.year(), monthlyReport.Monthly_Report_Start_Date__c.month());
            Map<Id, Decimal> contractorIdToWorkingHoursMap = contractorCalculationService.getWorkingHoursForContractors(new Contractor__c[]{ monthlyReport.Contractor__r });

            OvertimeWrapper overtimeWrapper = overtimeWrapperByMonthByYear.get(year).get(month);
            overtimeWrapper.expectedHours = contractorIdToWorkingHoursMap.get(monthlyReport.Contractor__c);
            overtimeWrapper.factHours += monthlyReport.Fact_hours__c;
            overtimeWrapper.delta = overtimeWrapper.factHours - overtimeWrapper.expectedHours;

            if (overtimeWrapper.projectForOvertimeWrappers == null) {
                ProjectForOvertimeWrapper projectForOvertimeWrapper = new ProjectForOvertimeWrapper();
                projectForOvertimeWrapper.Id = monthlyReport.Allocation__r.Project__r.Id;
                projectForOvertimeWrapper.projectName = monthlyReport.Allocation__r.Project__r.Name;
                projectForOvertimeWrapper.factHours = monthlyReport.Fact_hours__c;
                overtimeWrapper.projectForOvertimeWrappers = new List<ProjectForOvertimeWrapper>{ projectForOvertimeWrapper };
            }
            else {
                List<ProjectForOvertimeWrapper> existedProjectForOvertimeWrapper = overtimeWrapper.projectForOvertimeWrappers;
                Boolean isExistedProject = false;

                for (ProjectForOvertimeWrapper projectForOvertimeWrapper : existedProjectForOvertimeWrapper) {

                    if (projectForOvertimeWrapper.projectName == monthlyReport.Allocation__r.Project__r.Name) {
                        isExistedProject = true;
                        projectForOvertimeWrapper.factHours += monthlyReport.Fact_hours__c;
                    }
                }

                if (isExistedProject) {
                    overtimeWrapper.projectForOvertimeWrappers = existedProjectForOvertimeWrapper;
                }
                else {
                    ProjectForOvertimeWrapper projectForOvertimeWrapper = new ProjectForOvertimeWrapper();
                    projectForOvertimeWrapper.Id = monthlyReport.Allocation__r.Project__r.Id;
                    projectForOvertimeWrapper.projectName = monthlyReport.Allocation__r.Project__r.Name;
                    projectForOvertimeWrapper.factHours = monthlyReport.Fact_hours__c;

                    existedProjectForOvertimeWrapper.add(projectForOvertimeWrapper);
                    overtimeWrapper.projectForOvertimeWrappers = existedProjectForOvertimeWrapper;
                }
            }
        }

        return overtimeWrapperByMonthByYear;
    }

    private static Map<Integer, Map<String, OvertimeWrapper>> fillOvertimeWrapper(Id contractorId, Map<Integer, Map<String, OvertimeWrapper>> overtimeWrapperByMonthByYear) {

        for (Payroll_Component__c payrollComponent : getPayrollComponents(contractorId)) {

            if (payrollComponent.StartDate__c == null) continue;

            OvertimeWrapper overtimeWrapper = new OvertimeWrapper();
            overtimeWrapper.Id = payrollComponent.Id;
            overtimeWrapper.approvedHours = payrollComponent.Hours__c;
            overtimeWrapper.overtimeRate = payrollComponent.Overtime_Rate__c;
            overtimeWrapper.totalCost = payrollComponent.Sum__c;

            if (payrollComponent.Approval_Status__c == APPROVED) {
                overtimeWrapper.isApproved = true;
            }

            Integer year = payrollComponent.StartDate__c.year();
            String month = monthNameByNumber.get(payrollComponent.StartDate__c.month());

            if (overtimeWrapperByMonthByYear.containsKey(year)) {
                overtimeWrapperByMonthByYear.get(year).put(month, overtimeWrapper);
            }
            else {
                overtimeWrapperByMonthByYear.put(year, new Map<String, OvertimeWrapper>{
                        month => overtimeWrapper
                });
            }
        }

        return overtimeWrapperByMonthByYear;
    }

    private static List<Payroll_Component__c> getPayrollComponents(Id contractorId) {

        return [
            SELECT Id
                    , StartDate__c
                    , Hours__c
                    , Overtime_Rate__c
                    , Sum__c
                    , CurrencyIsoCode
                    , Approval_Status__c
            FROM Payroll_Component__c
            WHERE Contractor__c = :contractorId
            AND RecordTypeId = :PayrollComponentSelector.RECORD_TYPE_INFO_OVERTIME.getRecordTypeId()
            ORDER BY StartDate__c
        ];
    }

    private static Id getContractorId() {
        Id contractorPersonAccId;
        User currentUser = [SELECT Employee_AccountId__c FROM User WHERE Id = :UserInfo.getUserId()];
        
        Account[] contractorPersonAccList = [
            SELECT
            	Contractor__c
            FROM Account
            WHERE Id = :currentUser.Employee_AccountId__c
            LIMIT 1
        ];
        
        if (!contractorPersonAccList.isEmpty()) {
            contractorPersonAccId = contractorPersonAccList[0].Contractor__c;
        }
        
        return contractorPersonAccId;
    }

    private static List<Monthly_Report__c> getMonthlyReports(Id contractorId) {

        return [
            SELECT Id,
                Contractor__c,
                Contractor__r.Name,
                Contractor__r.Station__c,
                Contractor__r.Joining_Date__c,
                Contractor__r.Exit_Date__c,
                Contractor__r.Overtime_Rate__c,
                Contractor__r.CurrencyIsoCode,
                Contractor__r.Department__c,
                Contractor__r.Sub_Department__c,
                Allocation_percentage__c,
                Allocation__r.Project__r.Id,
                Allocation__r.Project__r.Name,
                Fact_hours__c,
                Monthly_Report_Start_Date__c,
                Monthly_Report_Period__c
            FROM Monthly_Report__c
            WHERE Contractor__c = :contractorId
            AND Allocation__c != NULL
            AND Fact_hours__c != NULL
            LIMIT 10000
        ];
    }
    
    @TestVisible
    class OvertimeWrapper {

        @AuraEnabled public Id Id;
        @AuraEnabled public Decimal expectedHours;
        @AuraEnabled public Decimal factHours = 0;
        @AuraEnabled public Decimal delta;
        @AuraEnabled public Decimal approvedHours;
        @AuraEnabled public Decimal overtimeRate;
        @AuraEnabled public Decimal totalCost;
        @AuraEnabled public String currencyIsoCode;
        @AuraEnabled public Boolean isApproved;
        @AuraEnabled public List<ProjectForOvertimeWrapper> projectForOvertimeWrappers;
        @AuraEnabled public List<String> columnsForOvertimesTable = new List<String>{'Expected hours', 'Fact hours', 'Delta', 'Approved hours', 'Overtime rate', 'Total cost'};
        @AuraEnabled public List<String> columnsForProjectsTable = new List<String>{'PROJECT NAME', 'FACT HOURS'};
    }

    class ProjectForOvertimeWrapper {

        @AuraEnabled public String Id;
        @AuraEnabled public String projectName;
        @AuraEnabled public Decimal factHours = 0;
    }
}