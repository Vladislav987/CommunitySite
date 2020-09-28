/**
* Created by Lambru Dmytro on 28.04.2020.
*/

@IsTest
private class LA_OvertimeControllerTest {

    private static Date DEFAULT_DATE = Date.newInstance(2020, 1, 1);
    private static Date DATE_ON_PREVIOUS_MONTH = Date.newInstance(System.now().year(), System.now().addMonths(-1).month(), 1);
    private static final String CORPORATE_CURRENCY_ISO_CODE = [SELECT IsoCode FROM CurrencyType WHERE IsCorporate = TRUE LIMIT 1].IsoCode;
    private static final String DEFAULT_PROJECT_NAME = 'PROJECT_FOR_TEST';

    @TestSetup
    static void doSetup() {
        ContractorTestDataFactory.createPortalContractorsForOvertimes();

        // disable triggers
        SObjectDomain.isEnabled = false;

        // create Projects
        Project__c project_1 = new Project__c(
            Name = DEFAULT_PROJECT_NAME + '1',
            Contract_type__c = ProjectSelector.CONTRACT_TYPE_PICKLIST_VALUES_MAP.get(ProjectSelector.ContractTypePicklistKey.FIXED_COST),
            Project_type__c = ProjectSelector.PROJECT_TYPE_PICKLIST_VALUES_MAP.get(ProjectSelector.ProjectTypePicklistKey.OUTSTAFF),
            Start_date__c = DEFAULT_DATE,
            End_date__c = DateUtils.getLastDayOfMonth(DEFAULT_DATE)
        );

        Project__c project_2 = new Project__c(
            Name = DEFAULT_PROJECT_NAME + '2',
            Contract_type__c = ProjectSelector.CONTRACT_TYPE_PICKLIST_VALUES_MAP.get(ProjectSelector.ContractTypePicklistKey.FIXED_COST),
            Project_type__c = ProjectSelector.PROJECT_TYPE_PICKLIST_VALUES_MAP.get(ProjectSelector.ProjectTypePicklistKey.OUTSTAFF),
            Start_date__c = DEFAULT_DATE,
            End_date__c = DateUtils.getLastDayOfMonth(DEFAULT_DATE)
        );

        insert new Project__c[]{ project_1, project_2 };

        Contractor__c[] contractorList = [
            SELECT Id,
                CurrencyIsoCode
            FROM Contractor__c
            WHERE Name LIKE :ContractorTestDataFactory.DEFAULT_MANAGER_NAME + '%'
            OR Name LIKE :ContractorTestDataFactory.DEFAULT_PM_NAME + '%'
            OR Name LIKE :ContractorTestDataFactory.DEFAULT_TEAM_LEADER_NAME + '%'
            OR Name LIKE :ContractorTestDataFactory.DEFAULT_CONTRACTOR_NAME + '%'
        ];

        // create Salary Histories for Contractors
        Salary_History__c[] salaryHistoryList = createContractorSalaryHistories(contractorList);
        insert salaryHistoryList;

        // create Allocations with Contractors for Projects
        Allocation__c[] allocationList = createAllocations(contractorList, project_1.Id, project_2.Id);
        insert allocationList;

        Monthly_Report__c[] monthlyReportList = createMonthlyReports(allocationList);
        insert monthlyReportList;

        // enable triggers
        SObjectDomain.isEnabled = true;
    }

    @IsTest
    static void testGetAllOvertimeParts_errorCode_400() {

        Test.startTest();
            Model.LightningResponse response = LA_OvertimeController.getAllOvertimeParts(null, null);
        Test.stopTest();

        System.assertEquals(false, response.success, 'Response must not be successful.');
        System.assertEquals(400, response.code, 'Response code must be 400.');
    }

    @IsTest
    static void testGenerateOvertimes_errorCode_400() {

        Test.startTest();
            Model.LightningResponse response_1 = LA_OvertimeController.generateOvertimes(null, null, null);
            Model.LightningResponse response_2 = LA_OvertimeController.generateOvertimes(DATE_ON_PREVIOUS_MONTH.year(), DATE_ON_PREVIOUS_MONTH.month(), '[]');
        Test.stopTest();

        System.assertEquals(false, response_1.success, 'Response must not be successful.');
        System.assertEquals(400, response_1.code, 'Response code must be 400.');

        System.assertEquals(false, response_2.success, 'Response must not be successful.');
        System.assertEquals(400, response_2.code, 'Response code must be 400.');
    }

    @IsTest
    static void testGenerateOvertimes_errorCode_403() {

        Test.startTest();
            Model.LightningResponse response = LA_OvertimeController.generateOvertimes(DATE_ON_PREVIOUS_MONTH.year(), DATE_ON_PREVIOUS_MONTH.addMonths(-1).month(), '[]');
        Test.stopTest();

        System.assertEquals(
            false,
            response.success,
            'Response must not be successful. Overtimes can only be generated for the previous month with the start and end date of the current month'
        );
        System.assertEquals(403, response.code, 'Response code must be 403.');
    }

    @IsTest
    static void testGetCmpConfig() {

        Test.startTest();
            Model.LightningResponse response = LA_OvertimeController.getCmpConfig();
        Test.stopTest();

        LA_OvertimeController.ComponentConfig componentConfig = (LA_OvertimeController.ComponentConfig) JSON.deserialize(response.data, LA_OvertimeController.ComponentConfig.class);

        System.assertEquals(false, componentConfig.yearDropdownOptionList.isEmpty(), 'The list should not be empty!');
        System.assertEquals(false, componentConfig.monthDropdownOptionList.isEmpty(), 'The list should not be empty!');
    }

    @IsTest
    static void testGetAllOvertimeParts_as_manager1() {
        User manager1 = [SELECT Id FROM User WHERE LastName = :ContractorTestDataFactory.DEFAULT_MANAGER_NAME + '1' LIMIT 1];

        // set specific date to test 'Planned Hours' (working hours) calculation for that date
        Contractor__c projectManagerContractor1 = [SELECT Id, Name FROM Contractor__c WHERE Name = :ContractorTestDataFactory.DEFAULT_PM_NAME + '1' LIMIT 1];
        Contractor__c teamLeaderContractor1 = [SELECT Id, Name FROM Contractor__c WHERE Name = :ContractorTestDataFactory.DEFAULT_TEAM_LEADER_NAME + '1' LIMIT 1];
        projectManagerContractor1.Exit_Date__c = DATE_ON_PREVIOUS_MONTH.addDays(6);
        teamLeaderContractor1.Joining_Date__c = DATE_ON_PREVIOUS_MONTH.addDays(9);

        update new Contractor__c[]{projectManagerContractor1, teamLeaderContractor1};

        Test.startTest();

            System.runAs(manager1) {
                // gets overtime parts of Manager subordinates
                LA_OvertimeController.OvertimePart[] overtimePartList = getAllOvertimePartsFromController(DATE_ON_PREVIOUS_MONTH);

                System.assertEquals(
                    4, overtimePartList.size(),
                    'Must be 4 for Contractors (Manager 1, Project Manager 1, Team Leader 1, Contractor 1 and Contractor 2) with different departments and sub-departments'
                );

                for (LA_OvertimeController.OvertimePart overtimePart : overtimePartList) {
                    System.assertEquals(false, String.isBlank(overtimePart.id));
                    System.assertEquals(false, String.isBlank(overtimePart.label));
                    System.assertEquals(false, overtimePart.overtimeInfoList.isEmpty());

                    // validate overtimes
                    for (LA_OvertimeController.OvertimeInfo overtime : overtimePart.overtimeInfoList) {
                        System.assertEquals(false, String.isBlank(overtime.contractorId));
                        System.assertEquals(false, String.isBlank(overtime.contractorName));
                        System.assertEquals(false, String.isBlank(overtime.contractorDepartment));
                        System.assertEquals(false, overtime.isPayrollCmpExist);
                        System.assertEquals(true, overtime.isSelected);
                        System.assertEquals(CORPORATE_CURRENCY_ISO_CODE, overtime.contractorCurrencyIsoCode);
                        System.assertEquals(200, overtime.factHours, 'Must be 200. The sum of Fact_hours on the Monthly Reports.');
                        System.assert(overtime.overtimeRate > 1, 'Must be greater than 0. The calculated value on the Contractor taking into account the Station and the Contractor’s salary.');

                        if (overtime.contractorName == projectManagerContractor1.Name) {
                            System.assertEquals(
                                ContractorSelector.SUB_DEPARTMENT_PICKLIST_VALUES_MAP.get(ContractorSelector.SubDepartmentPicklistKey.SFDC_PMO),
                                overtime.contractorSubDepartment
                            );

                            // Contractor.Exit_Date = 7th of the previous month
                            System.assert(overtime.expectedHours <= 40, 'Must be 40 or less (5 work days * 8 hours). Since the calculation of the hours was until 7th of the previous month.');
                            System.assert(overtime.overtimeDelta >= 160, 'Must be 160 or greater. Delta between "Fact Hours" and "Planned Hours".');
                            System.assert(overtime.overtimeHours >= 160, 'A predefined number for the future generation from the delta.');
                        }
                        else {
                            System.assert(overtime.expectedHours > 50);
                            System.assertEquals(overtime.overtimeDelta, (overtime.factHours - overtime.expectedHours), 'Delta between "Fact Hours" and "Planned Hours".');
                            System.assertEquals(overtime.overtimeHours, (overtime.factHours - overtime.expectedHours), 'A predefined number for the future generation from the delta.');
                        }

                    }
                }
            }
        Test.stopTest();
    }

    @IsTest
    static void testGetAllOvertimeParts_as_manager2() {
        User manager2 = [SELECT Id FROM User WHERE LastName = :ContractorTestDataFactory.DEFAULT_MANAGER_NAME + '2' LIMIT 1];

        Test.startTest();

            System.runAs(manager2) {
                // gets overtimes of Manager subordinates
                LA_OvertimeController.OvertimePart[] overtimePartList = getAllOvertimePartsFromController(DATE_ON_PREVIOUS_MONTH);

                for (LA_OvertimeController.OvertimePart overtimePart : overtimePartList) {

                    // validate overtimes
                    for (LA_OvertimeController.OvertimeInfo overtime : overtimePart.overtimeInfoList) {
                        System.assertEquals(false, String.isBlank(overtime.contractorId));
                        System.assertEquals(false, String.isBlank(overtime.contractorName));
                        System.assertEquals(false, overtime.isPayrollCmpExist);
                        System.assertEquals(true, overtime.isSelected);
                        System.assertEquals(CORPORATE_CURRENCY_ISO_CODE, overtime.contractorCurrencyIsoCode);
                        System.assertEquals(200, overtime.factHours, 'Must be 200. The sum of Fact_hours on the Monthly Reports.');
                        System.assert(overtime.overtimeRate > 1, 'Must be greater than 0. The calculated value on the Contractor taking into account the Station and the Contractor’s salary.');
                        System.assert(overtime.expectedHours > 50, 'Since the calculation of the hours was from 1th to last day of previous month.');
                        System.assertEquals(overtime.overtimeDelta, (overtime.factHours - overtime.expectedHours), 'Delta between "Fact Hours" and "Planned Hours".');
                        System.assertEquals(overtime.overtimeHours, (overtime.factHours - overtime.expectedHours), 'A predefined number for the future generation from the delta.');
                    }
                }
            }
        Test.stopTest();
    }

    @IsTest
    static void testGetAllOvertimeParts_max_number_hours() {
        User manager = [SELECT Id FROM User WHERE LastName LIKE :ContractorTestDataFactory.DEFAULT_MANAGER_NAME + '%' LIMIT 1];
        Monthly_Report__c[] monthlyReportList = [SELECT Fact_hours__c FROM Monthly_Report__c];
        SObjectDomain.isEnabled = false;

        for (Monthly_Report__c monthlyReport : monthlyReportList) {
            // set unreal number
            monthlyReport.Fact_hours__c = 999;
        }

        update monthlyReportList;
        SObjectDomain.isEnabled = true;

        Test.startTest();

            System.runAs(manager) {
                // gets overtimes of Manager subordinates
                LA_OvertimeController.OvertimePart[] overtimePartList = getAllOvertimePartsFromController(DATE_ON_PREVIOUS_MONTH);

                for (LA_OvertimeController.OvertimePart overtimePart : overtimePartList) {

                    // validate overtimes
                    for (LA_OvertimeController.OvertimeInfo overtime : overtimePart.overtimeInfoList) {
                        System.assertEquals(LA_OvertimeController.FIELD_MAX_NUMBER_HOURS, overtime.overtimeHours, 'The number must be trimmed to the maximum.');
                    }
                }
            }
        Test.stopTest();
    }

    @IsTest
    static void testGetAllOvertimeParts_contractor_joined_future() {
        User manager = [SELECT Id FROM User WHERE LastName LIKE :ContractorTestDataFactory.DEFAULT_MANAGER_NAME + '%' LIMIT 1];
        Contractor__c[] contractorList = [SELECT Joining_Date__c FROM Contractor__c];
        Date futureJoiningDate = System.today().addMonths(1);
        SObjectDomain.isEnabled = false;

        for (Contractor__c contractor : contractorList) {
            contractor.Joining_Date__c = futureJoiningDate;
        }

        update contractorList;
        SObjectDomain.isEnabled = true;

        Test.startTest();

            System.runAs(manager) {
                // gets overtimes of Manager subordinates
                LA_OvertimeController.OvertimePart[] overtimePartList = getAllOvertimePartsFromController(DATE_ON_PREVIOUS_MONTH);

                for (LA_OvertimeController.OvertimePart overtimePart : overtimePartList) {

                    // validate overtimes
                    for (LA_OvertimeController.OvertimeInfo overtime : overtimePart.overtimeInfoList) {
                        System.assertEquals(0, overtime.expectedHours, 'The number must be 0.');
                    }
                }
            }
        Test.stopTest();
    }

    @IsTest
    static void testGenerateOvertimes() {
        User manager2 = [SELECT Id FROM User WHERE LastName = :ContractorTestDataFactory.DEFAULT_MANAGER_NAME + '2' LIMIT 1];
        String notCorporateCurrencyIsoCode = [SELECT IsoCode FROM CurrencyType WHERE IsCorporate = FALSE LIMIT 1].IsoCode;

        // set specific date to test 'Planned Hours' (working hours) calculation for that date
        Contractor__c projectManagerContractor2 = [SELECT Id, Name FROM Contractor__c WHERE Name = :ContractorTestDataFactory.DEFAULT_PM_NAME + '2' LIMIT 1];
        Contractor__c teamLeaderContractor2 = [SELECT Id, Name FROM Contractor__c WHERE Name = :ContractorTestDataFactory.DEFAULT_TEAM_LEADER_NAME + '2' LIMIT 1];
        projectManagerContractor2.CurrencyIsoCode = notCorporateCurrencyIsoCode;
        teamLeaderContractor2.CurrencyIsoCode = notCorporateCurrencyIsoCode;

        update new Contractor__c[]{projectManagerContractor2, teamLeaderContractor2};

        System.runAs(manager2) {

            LA_OvertimeController.OvertimePart[] overtimePartList = getAllOvertimePartsFromController(DATE_ON_PREVIOUS_MONTH);

            // simulate changes on UI
            for (LA_OvertimeController.OvertimePart overtimePart : overtimePartList) {

                for (LA_OvertimeController.OvertimeInfo overtime : overtimePart.overtimeInfoList) {
                    overtime.overtimeHours = 10;
                }
            }

            Test.startTest();
                // generates overtime Payroll Components
                Model.LightningResponse responseAfterGenerate = LA_OvertimeController.generateOvertimes(DATE_ON_PREVIOUS_MONTH.year(), DATE_ON_PREVIOUS_MONTH.month(), JSON.serialize(overtimePartList));
                System.assert(responseAfterGenerate.success, 'Response must be successful.');
            Test.stopTest();
        }

        Payroll_Component__c[] payrollComponentList = [
            SELECT Contractor__c,
                Contractor__r.Overtime_Rate__c,
                Contractor__r.Name,
                Account__r.Contractor__c,
                CurrencyIsoCode,
                Hours__c,
                Overtime_Rate__c,
                SumType__c,
                Sum__c,
                StartDate__c,
                EndDate__c
            FROM Payroll_Component__c
            WHERE RecordTypeId = :PayrollComponentSelector.RECORD_TYPE_INFO_OVERTIME.getRecordTypeId()
            AND Approval_Status__c = :PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED)
        ];

        System.assert(payrollComponentList.size() > 0);

        final Date dateOnFirstDayOfNextMonth = DATE_ON_PREVIOUS_MONTH.addMonths(1);
        final String sumTypeIncrement = PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.SumTypePicklistKey.INCREMENT);

        // validate generated Payroll Components
        for (Payroll_Component__c payrollComponent : payrollComponentList) {
            System.assertEquals(10, payrollComponent.Hours__c, 'Must be 10 as entered by the user on UI.');
            System.assert(payrollComponent.Contractor__c == payrollComponent.Account__r.Contractor__c);
            System.assert(payrollComponent.SumType__c == sumTypeIncrement);
            System.assert(payrollComponent.Sum__c <= payrollComponent.Hours__c * payrollComponent.Overtime_Rate__c);
            System.assert(payrollComponent.StartDate__c == dateOnFirstDayOfNextMonth);
            System.assert(payrollComponent.EndDate__c == dateOnFirstDayOfNextMonth);

            if (payrollComponent.Contractor__r.Name == projectManagerContractor2.Name
                || payrollComponent.Contractor__r.Name == teamLeaderContractor2.Name) {

                System.assertEquals(notCorporateCurrencyIsoCode, payrollComponent.CurrencyIsoCode , 'CurrencyIsoCode should be the same on the Contractor and not corporate.');
            }
            else {
                System.assertEquals(CORPORATE_CURRENCY_ISO_CODE, payrollComponent.CurrencyIsoCode , 'CurrencyIsoCode should be the same on the Contractor and corporate.');
            }
        }
    }

    @IsTest
    static void testGenerateOvertimes_upsert() {
        User manager1 = [SELECT Id FROM User WHERE LastName = :ContractorTestDataFactory.DEFAULT_MANAGER_NAME + '1' LIMIT 1];

        System.runAs(manager1) {
            Test.startTest();
                LA_OvertimeController.OvertimePart[] overtimePartList = getAllOvertimePartsFromController(DATE_ON_PREVIOUS_MONTH);

                // simulate changes on UI
                for (LA_OvertimeController.OvertimePart overtimePart : overtimePartList) {

                    for (LA_OvertimeController.OvertimeInfo overtime : overtimePart.overtimeInfoList) {
                        overtime.overtimeHours = 10;
                    }
                }

                // generates overtime Payroll Components
                Model.LightningResponse responseAfterGenerate = LA_OvertimeController.generateOvertimes(DATE_ON_PREVIOUS_MONTH.year(), DATE_ON_PREVIOUS_MONTH.month(), JSON.serialize(overtimePartList));
                System.assert(responseAfterGenerate.success, 'Response must be successful.');

                // gets overtime with existing Payroll Components
                LA_OvertimeController.OvertimePart[] overtimePartsWithGeneratedPayrollComponentsList = getAllOvertimePartsFromController(DATE_ON_PREVIOUS_MONTH);

                for (LA_OvertimeController.OvertimePart overtimePart : overtimePartsWithGeneratedPayrollComponentsList) {

                    for (LA_OvertimeController.OvertimeInfo overtime : overtimePart.overtimeInfoList) {
                        System.assert(overtime.isPayrollCmpExist);
                        System.assert(overtime.isSelected == false);

                        overtime.overtimeHours = 20;
                        overtime.isSelected = true;
                    }
                }
            Test.stopTest();

            Model.LightningResponse responseAfterGenerateWithUpdatedPayrollComponents = LA_OvertimeController.generateOvertimes(DATE_ON_PREVIOUS_MONTH.year(), DATE_ON_PREVIOUS_MONTH.month(), JSON.serialize(overtimePartsWithGeneratedPayrollComponentsList));
            System.assert(responseAfterGenerateWithUpdatedPayrollComponents.success, 'Response must be successful.');
        }

        Payroll_Component__c[] payrollComponentList = [
            SELECT Hours__c
            FROM Payroll_Component__c
            WHERE RecordTypeId = :PayrollComponentSelector.RECORD_TYPE_INFO_OVERTIME.getRecordTypeId()
            AND Approval_Status__c = :PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED)
        ];

        System.assert(payrollComponentList.size() > 0);

        // validate updated Payroll Components
        for (Payroll_Component__c payrollComponent : payrollComponentList) {
            System.assertEquals(20, payrollComponent.Hours__c, 'Must be updated 20 as entered by the user on UI.');
        }
    }

    /* ##### HELPER METHODS ##### */

    static Salary_History__c[] createContractorSalaryHistories(Contractor__c[] contractorList) {
        Salary_History__c[] salaryHistoryList = new Salary_History__c[]{};

        for (Contractor__c contractor : contractorList) {
            Salary_History__c salaryHistory_1 = createSalaryHistory(contractor, 1000, DEFAULT_DATE, DEFAULT_DATE.addMonths(1));
            Salary_History__c salaryHistory_2 = createSalaryHistory(contractor, 2000, DEFAULT_DATE.addMonths(1), DEFAULT_DATE.addMonths(1));
            Salary_History__c salaryHistory_3 = createSalaryHistory(contractor, 3000, DEFAULT_DATE.addMonths(1), DEFAULT_DATE.addMonths(2));
            Salary_History__c salaryHistory_4 = createSalaryHistory(contractor, 4000, DEFAULT_DATE.addMonths(2), DEFAULT_DATE.addYears(99));

            salaryHistoryList.addAll(new Salary_History__c[]{
                salaryHistory_1, salaryHistory_2, salaryHistory_3, salaryHistory_4
            });
        }

        return salaryHistoryList;
    }

    static Allocation__c[] createAllocations(Contractor__c[] contractorList, Id projectId_1, Id projectId_2) {
        Allocation__c[] allocationList = new Allocation__c[]{};
        Id recordTypeIdProject = AllocationSelector.RECORD_TYPE_INFO_PROJECT.getRecordTypeId();
        String allocationTypeBillable = AllocationSelector.ALLOCATION_TYPE_PICKLIST_VALUES_MAP.get(AllocationSelector.AllocationTypePicklistKey.BILLABLE);
        Date allocationEndDate = DateUtils.getLastDayOfMonth(DEFAULT_DATE.addMonths(11));
        String resourceTypeSFDev = ContractorSelector.RESOURCE_TYPE_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceTypePicklistKey.SFDC_DEVELOPER);
        String resourceTypeIOSDev = ContractorSelector.RESOURCE_TYPE_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceTypePicklistKey.IOS_DEVELOPER);
        String resourceLevelTrainee = ContractorSelector.RESOURCE_LEVEL_PICKLIST_VALUES_MAP.get(ContractorSelector.ResourceLevelPicklistKey.TRAINEE);

        for (Contractor__c contractor : contractorList) {
            Allocation__c allocationSFDev_project1 = createAllocation(recordTypeIdProject, projectId_1, contractor.Id, resourceTypeSFDev, resourceLevelTrainee, allocationTypeBillable, allocationEndDate);
            Allocation__c allocationIOS_project1 = createAllocation(recordTypeIdProject, projectId_1, contractor.Id, resourceTypeIOSDev, resourceLevelTrainee, allocationTypeBillable, allocationEndDate);
            Allocation__c allocationSFDev_project2 = createAllocation(recordTypeIdProject, projectId_2, contractor.Id, resourceTypeSFDev, resourceLevelTrainee, allocationTypeBillable, allocationEndDate);
            Allocation__c allocationIOS_project2 = createAllocation(recordTypeIdProject, projectId_2, contractor.Id, resourceTypeIOSDev, resourceLevelTrainee, allocationTypeBillable, allocationEndDate);

            allocationList.add(allocationSFDev_project1);
            allocationList.add(allocationIOS_project1);
            allocationList.add(allocationSFDev_project2);
            allocationList.add(allocationIOS_project2);
        }

        return allocationList;
    }

    static Salary_History__c createSalaryHistory(Contractor__c contractor, Decimal salary, Date startDate, Date endDate) {

        return new Salary_History__c(
            Contractor__c = contractor.Id,
            CurrencyIsoCode = contractor.CurrencyIsoCode,
            Salary__c = salary,
            Start_Date__c = startDate,
            End_Date__c = endDate
        );
    }

    static Allocation__c createAllocation(Id recordTypeId,
                                            Id projectId,
                                            Id contractorId,
                                            String resourceType,
                                            String resourceLevel,
                                            String allocationType,
                                            Date allocationEndDate) {
        return new Allocation__c(
            RecordTypeId = recordTypeId,
            Project__c = projectId,
            Contractor__c = contractorId,
            Resource_Type__c = resourceType,
            Resource_Level__c = resourceLevel,
            Allocation_Type__c = allocationType,
            Start_date__c = DEFAULT_DATE,
            End_date__c = allocationEndDate,
            Allocation__c = 25
        );
    }

    static Monthly_Report__c[] createMonthlyReports(Allocation__c[] allocationList) {
        Monthly_Report__c[] monthlyReportList = new Monthly_Report__c[]{};
        // sets the date and period of previous month for querying and generating overtime for this month
        String monthlyReportPeriod = ((Datetime) DATE_ON_PREVIOUS_MONTH).formatGmt(LA_OvertimeController.FORMAT_MONTH_AND_YEAR); // e.g. string with "March 2020"
        Date endDate_1part = DATE_ON_PREVIOUS_MONTH.addDays(15);
        Date startDate_2part = DATE_ON_PREVIOUS_MONTH.addDays(15);
        Date endDate_2part = DateUtils.getLastDayOfMonth(DATE_ON_PREVIOUS_MONTH);

        for (Allocation__c allocation : allocationList) {
            Monthly_Report__c monthlyReport_1part = createMonthlyReport(allocation, monthlyReportPeriod, DATE_ON_PREVIOUS_MONTH, endDate_1part);
            Monthly_Report__c monthlyReport_2part = createMonthlyReport(allocation, monthlyReportPeriod, startDate_2part, endDate_2part);

            monthlyReportList.add(monthlyReport_1part);
            monthlyReportList.add(monthlyReport_2part);
        }

        return monthlyReportList;
    }

    static Monthly_Report__c createMonthlyReport(Allocation__c allocation, String monthlyReportPeriod, Date monthlyReportStartDate, Date monthlyReportEndDate) {

        return new Monthly_Report__c(
            Allocation__c = allocation.Id,
            Project__c = allocation.Project__c,
            Contractor__c = allocation.Contractor__c,
            Monthly_Report_Period__c = monthlyReportPeriod,
            Monthly_Report_Start_Date__c = monthlyReportStartDate,
            Monthly_Report_End_Date__c = monthlyReportEndDate,
            Fact_hours__c = 25
        );
    }

    static LA_OvertimeController.OvertimePart[] getAllOvertimePartsFromController(Date dateForOvertimePeriod) {
        LA_OvertimeController.LightningResponse response = LA_OvertimeController.getAllOvertimeParts(dateForOvertimePeriod.year(), dateForOvertimePeriod.month());
        System.assert(response.success, 'Response must be successful.');

        LA_OvertimeController.OvertimePart[] overtimePartList = (LA_OvertimeController.OvertimePart[]) JSON.deserialize(response.data, LA_OvertimeController.OvertimePart[].class);
        System.assert(overtimePartList.size() > 0, 'The list should not be empty.');

        String requestedReportPeriod = Datetime.newInstance(dateForOvertimePeriod.year(), dateForOvertimePeriod.month(), 1).formatGmt(LA_OvertimeController.FORMAT_MONTH_AND_YEAR);
        String currentPreviousReportPeriod = Datetime.newInstance(System.today().year(), System.today().addMonths(-1).month(), 1).formatGmt(LA_OvertimeController.FORMAT_MONTH_AND_YEAR);
        System.assertEquals(response.isReadOnlyMode, requestedReportPeriod != currentPreviousReportPeriod, 'If the requested month is not the previous month, then there should be a read mode only.');

        return overtimePartList;
    }
}