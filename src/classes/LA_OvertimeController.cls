/*
 * Created by Dmytro Lambru
 */
public without sharing class LA_OvertimeController {

    private static LightningResponse response = new LightningResponse();
    private static Integer FIELD_DIGIT_LIMIT_HOURS;
    @TestVisible
    private static Integer FIELD_MAX_NUMBER_HOURS;
    @TestVisible
    private static final String FORMAT_MONTH_AND_YEAR = 'MMMM YYYY';

    static {
        FIELD_DIGIT_LIMIT_HOURS = PayrollComponentSelector.DESCRIBE_FIELD_RESULT_HOURS.getPrecision() - PayrollComponentSelector.DESCRIBE_FIELD_RESULT_HOURS.getScale();
        FIELD_MAX_NUMBER_HOURS = getMaxFieldNumber(FIELD_DIGIT_LIMIT_HOURS);
    }

    /**
     * @description Forms an object with settings for the component.
     *
     * @return Response with config object for component.
     */
    @AuraEnabled
    public static LightningResponse getCmpConfig() {

        try {

            ComponentConfig componentConfig = generateComponentConfig();

            response.setResult(JSON.serialize(componentConfig, true));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_OvertimeController.class));
        }

        return response;
    }

    /**
     * @description Overtime data generation divided into parts based on the (sub)department of the Contractor.
     *
     * @param year  Year number for period.
     * @param month Month number for period.
     *
     * @return Response with data about overtime parts.
     */
    @AuraEnabled
    public static LightningResponse getAllOvertimeParts(Integer year, Integer month) {

        if (year == null || month == null) {
            return response.setError(400); // 400 - Bad request.
        }

        Id currentUserId = UserInfo.getUserId();
        Date dateNow = Date.valueOf(System.now()).toStartOfMonth();
        Date requestedDate = Date.newInstance(year, month, 1);

        try {
            Set<Id> contractorIdSet = getContractorAndSubordinatesIdsByUserId(currentUserId);
            Map<Id, Salary_History__c> contractorIdToSalaryHistoryMap = getSalaryHistoryOnDateByContractorIds(contractorIdSet, requestedDate);
            Map<Id, Monthly_Report__c[]> contractorIdToMonthlyReportsMap = getMonthlyReportsByContractorIds(contractorIdSet, requestedDate);
            Map<Id, Decimal> contractorIdToWorkingHoursMap = new Util_ContractorCalculation(year, month).getWorkingHoursForContractors(contractorIdToMonthlyReportsMap.keySet());
            OvertimeInfo[] overtimeList = createOvertimeInfos(year, month, contractorIdToSalaryHistoryMap, contractorIdToMonthlyReportsMap, contractorIdToWorkingHoursMap);
            OvertimePart[] overtimePartList = createOvertimeParts(overtimeList);

            response.isUserBlockedForGeneration = ( dateNow == requestedDate.addMonths(1) && isBlockedForGenerationBasedOnUser() );
            response.isReadOnlyMode = ( response.isUserBlockedForGeneration || dateNow != requestedDate.addMonths(1) );

            response.setResult(JSON.serialize(overtimePartList));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_OvertimeController.class));
        }

        return response;
    }

    /**
    * @description Generates overtime based on the received data.
    *
    * @param year  Year number for period.
    * @param month Month number for period.
    * @param jsonOvertimePartList  JSON string with changed overtime parts.
    *
    * @return Response with successful or not operation result.
    */
    @AuraEnabled
    public static LightningResponse generateOvertimes(Integer year, Integer month, String jsonOvertimePartList) {

        if (year == null || month == null || jsonOvertimePartList == null) {
            return response.setError(400); // 400 - Bad request.
        }
        else if (Date.newInstance(year, month, 1) != System.today().addMonths(-1).toStartOfMonth()) {
            // overtime can only be generated for the previous month with the start and end date of the current month
            return response.setError(403); // 403 - Forbidden.
        }

        try {
            OvertimePart[] overtimePartList = (OvertimePart[]) JSON.deserialize(jsonOvertimePartList, OvertimePart[].class);
            OvertimeInfo[] selectedOvertimeInfoList = getSelectedOvertimesFromParts(overtimePartList);

            if (selectedOvertimeInfoList.isEmpty()) {
                return response.setError(400);
            }

            Payroll_Component__c[] payrollComponentList = overtimesToPayrollComponents(year, month, selectedOvertimeInfoList);

            upsert(payrollComponentList);

            response.success = true;
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_OvertimeController.class));
        }

        return response;
    }

    /**
     * @description Calculation of the maximum allowed number for the field.
     *
     * @param digitLimit Number of digits.
     *
     * @return Max value for the field
     */
    private static Integer getMaxFieldNumber(Integer digitLimit) {
        String stringMaxNumber = '';

        for (Integer i = 0; i < digitLimit; i++) {
            stringMaxNumber += '9';
        }

        return Integer.valueOf(stringMaxNumber);
    }

    /**
     * @description Forms an object with settings for the component.
     *
     * @return Object with settings.
     */
    private static ComponentConfig generateComponentConfig() {
        ComponentConfig componentConfig = new ComponentConfig();

        componentConfig.monthDropdownOptionList = createMonthOptions();
        componentConfig.yearDropdownOptionList = createYearOptions();

        return componentConfig;
    }

    /**
    * @description Forms a list with options for dropdown with months.
    *
    * @return List with options.
    */
    private static Model.PicklistOption[] createMonthOptions() {
        Model.PicklistOption[] optionList = new Model.PicklistOption[]{};
        Integer previousMonthNumber = System.today().addMonths(-1).month();

        for (Integer monthNumber = 1; monthNumber <= 12; monthNumber++) {
            Model.PicklistOption option = new Model.PicklistOption();

            option.optionLabel = Util.getFullMonthLabelByMonthNumberForCurrentLanguage(monthNumber);
            option.optionApiName = String.valueOf(monthNumber);
            option.isSelected = (monthNumber == previousMonthNumber);

            optionList.add(option);
        }

        return optionList;
    }

    /**
    * @description Forms a list with options for dropdown with years.
    *
    * @return List with options.
    */
    private static Model.PicklistOption[] createYearOptions() {
        Integer currentYear = System.today().year();

        Model.PicklistOption[] optionList = new Model.PicklistOption[]{};

        for (Integer year = currentYear, lowerLimitYear = (currentYear - 10); year > lowerLimitYear; year--) {
            Model.PicklistOption option = new Model.PicklistOption();

            option.optionLabel = String.valueOf(year);
            option.optionApiName = String.valueOf(year);
            option.isSelected = (year == currentYear);

            optionList.add(option);
        }

        return optionList;
    }

    /**
    * @description Generates a set with the ID of the user's contractor and its subordinate contractors down the hierarchy.
    *
    * @param userId User ID.
    *
    * @return Set with user's contractor and its subordinate IDs.
    */
    private static Set<Id> getContractorAndSubordinatesIdsByUserId(Id userId) {
        Set<Id> subordinateIdSet = new Set<Id>();
        Map<Id, User[]> managerIdToSubordinateUsersMap = new Map<Id, User[]>();
        Map<String, Account> accountIdToPersonAccountMap = new Map<String, Account>();
        Map<Id, User> userIdToRecordMap = getAllActiveUsersWithEmployeeAccountId();

        createHelperMapsForSubordinatesGenerationBasedOnUsers(userIdToRecordMap, managerIdToSubordinateUsersMap, accountIdToPersonAccountMap);

        // add user's Contractor ID
        if (userIdToRecordMap.containsKey(userId)) {
            User currentUser = userIdToRecordMap.get(userId);

            if (accountIdToPersonAccountMap.containsKey(currentUser.Employee_AccountId__c)) {
                subordinateIdSet.add(accountIdToPersonAccountMap.get(currentUser.Employee_AccountId__c).Contractor__c);
            }
        }

        addSubordinateIdsToSetByUserId(userId, subordinateIdSet, managerIdToSubordinateUsersMap, accountIdToPersonAccountMap);

        return subordinateIdSet;
    }

    /**
    * @description Gets all active users with existing Person Account.
    *
    * @return Map with key: User ID | value: User record
    */
    private static Map<Id, User> getAllActiveUsersWithEmployeeAccountId() {

        return new Map<Id, User>([
            SELECT Id,
                Name,
                ManagerId,
                Employee_AccountId__c
            FROM User
            WHERE IsActive = TRUE
            AND Employee_AccountId__c <> NULL
            LIMIT 10000
        ]);
    }

    /**
    * @description Creates helper maps based on all active users with 'Person Account' in the system.
    *
    * @param userIdToRecordMap              Map with user ID to active user with Person Account.
    * @param managerIdToSubordinateUsersMap Map with user manager ID to list with subordinates users.
    * @param accountIdToPersonAccountMap    Map with account ID to Person Account.
    */
    private static void createHelperMapsForSubordinatesGenerationBasedOnUsers(Map<Id, User> userIdToRecordMap, Map<Id, User[]> managerIdToSubordinateUsersMap, Map<String, Account> accountIdToPersonAccountMap) {

        if (!userIdToRecordMap.isEmpty()) {
            Set<String> contractorPersonAccountIdSet = new Set<String>();

            for (User userRecord : userIdToRecordMap.values()) {
                contractorPersonAccountIdSet.add(userRecord.Employee_AccountId__c);

                if (String.isBlank(userRecord.ManagerId)) continue;

                if (!managerIdToSubordinateUsersMap.containsKey(userRecord.ManagerId)) {
                    managerIdToSubordinateUsersMap.put(userRecord.ManagerId, new User[]{});
                }

                managerIdToSubordinateUsersMap.get(userRecord.ManagerId).add(userRecord);
            }

            accountIdToPersonAccountMap.putAll(new AccountSelector().getActualPersonAccountsByIds(contractorPersonAccountIdSet));
        }
    }

    /**
    * @description Adds the IDs of all subordinates contractors by user ID.
    *              Participates in recursive calls.
    *
    * @param userId                         User ID.
    * @param subordinateIdSet               Set with the ID of the contractors.
    * @param managerIdToSubordinateUsersMap Map with user manager ID to list with subordinates users.
    * @param accountIdToPersonAccountMap    Map with account ID to Person Account.
    */
    private static void addSubordinateIdsToSetByUserId(Id userId, Set<Id> subordinateIdSet, Map<Id, User[]> managerIdToSubordinateUsersMap, Map<String, Account> accountIdToPersonAccountMap) {

        if (managerIdToSubordinateUsersMap.containsKey(userId)) {

            for (User subordinateUser : managerIdToSubordinateUsersMap.get(userId)) {

                if (accountIdToPersonAccountMap.containsKey(subordinateUser.Employee_AccountId__c)) {
                    Account contractorPersonAccount = accountIdToPersonAccountMap.get(subordinateUser.Employee_AccountId__c);

                    subordinateIdSet.add(contractorPersonAccount.Contractor__c);
                }

                addSubordinateIdsToSetByUserId(subordinateUser.Id, subordinateIdSet, managerIdToSubordinateUsersMap, accountIdToPersonAccountMap);
            }
        }
    }

    /**
     * @description Getting the latest actual salary for the specified period.
     *
     * @param contractorIdSet Set with Contractor IDs.
     * @param requestedDate   Date for the period.
     *
     * @return Map with key: Contractor ID | value: Salary_History record
     */
    private static Map<Id, Salary_History__c> getSalaryHistoryOnDateByContractorIds(Set<Id> contractorIdSet, Date requestedDate) {
        Map<Id, Salary_History__c> contractorIdToSalaryHistoryMap = new Map<Id, Salary_History__c>();

        for (Salary_History__c salaryHistory : [
            SELECT
                Contractor__c,
                Overtime_Rate__c
            FROM Salary_History__c
            WHERE Contractor__c IN :contractorIdSet
            AND (Start_Date__c <= :requestedDate AND End_Date__c >= :requestedDate)
            ORDER BY Start_Date__c DESC , End_Date__c DESC , CreatedDate DESC
            LIMIT 10000
        ]) {

            if (!contractorIdToSalaryHistoryMap.containsKey(salaryHistory.Contractor__c)) {
                // put only first salary history
                contractorIdToSalaryHistoryMap.put(salaryHistory.Contractor__c, salaryHistory);
            }
        }

        return contractorIdToSalaryHistoryMap;
    }

    /**
    * @description Getting all Monthly_Report records for contractors for the period.
    *
    * @param contractorIdSet Set with the ID of the user's contractor and its subordinate contractors down the hierarchy.
    * @param requestedDate    Period for query, e.g. string with "March 2020"
    *
    * @return Map with key: Contractor ID | value: List with Monthly_Report records
    */
    private static Map<Id, Monthly_Report__c[]> getMonthlyReportsByContractorIds(Set<Id> contractorIdSet, Date requestedDate) {
        Map<Id, Monthly_Report__c[]> contractorIdToMonthlyReportsMap = new Map<Id, Monthly_Report__c[]>();
        // Period for query, e.g. string with "March 2020"
        String reportPeriod = ((Datetime)requestedDate).formatGmt(FORMAT_MONTH_AND_YEAR);

        for (Monthly_Report__c monthlyReport : [
            SELECT Id,
                Contractor__c,
                Contractor__r.Name,
                Contractor__r.CurrencyIsoCode,
                Contractor__r.Department__c,
                Contractor__r.Sub_Department__c,
                Project__c,
                Project__r.Name,
                Allocation__c,
                Allocation_percentage__c,
                Fact_hours__c,
                Monthly_Report_Period__c
            FROM Monthly_Report__c
            WHERE Contractor__c IN :contractorIdSet
            AND Monthly_Report_Period__c = :reportPeriod
            AND Allocation__c <> NULL
            AND Fact_hours__c <> NULL
            LIMIT 10000
        ]) {

            if (!contractorIdToMonthlyReportsMap.containsKey(monthlyReport.Contractor__c)) {
                contractorIdToMonthlyReportsMap.put(monthlyReport.Contractor__c, new Monthly_Report__c[]{});
            }

            contractorIdToMonthlyReportsMap.get(monthlyReport.Contractor__c).add(monthlyReport);
        }

        return contractorIdToMonthlyReportsMap;
    }

    /**
    * @description Generates a list with overtime information.
    *
    * @param year                            Year number for period.
    * @param month                           Month number for period.
    * @param contractorIdToSalaryHistoryMap  Map with contractor ID to Salary_History record.
    * @param contractorIdToMonthlyReportsMap Map with contractor ID to Monthly_Report records.
    * @param contractorIdToWorkingHoursMap   Map with contractor ID to total working hours per month.
    *
    * @return List with overtime information.
    */
    private static OvertimeInfo[] createOvertimeInfos(Integer year,
                                                        Integer month,
                                                        Map<Id, Salary_History__c> contractorIdToSalaryHistoryMap,
                                                        Map<Id, Monthly_Report__c[]> contractorIdToMonthlyReportsMap,
                                                        Map<Id, Decimal> contractorIdToWorkingHoursMap) {

        OvertimeInfo[] overtimeList = new OvertimeInfo[]{};

        for (Id contractorId : contractorIdToMonthlyReportsMap.keySet()) {
            Decimal overtimeRate = contractorIdToSalaryHistoryMap.get(contractorId).Overtime_Rate__c;
            Monthly_Report__c[] monthlyReportList = contractorIdToMonthlyReportsMap.get(contractorId);
            Decimal contractorWorkingHours = contractorIdToWorkingHoursMap.get(contractorId);
            Decimal totalFactHours = getTotalFactHours(monthlyReportList);

            if (!monthlyReportList.isEmpty() && (totalFactHours > contractorWorkingHours)) {
                overtimeList.add(new OvertimeInfo(monthlyReportList, overtimeRate, contractorWorkingHours, totalFactHours));
            }
        }

        addInformationFromExistingPayrollComponents(year, month, overtimeList);

        return overtimeList;
    }

    /**
    * @description Getting all fact hours from Monthly_Report records.
    *
    * @param monthlyReportList List with Monthly_Report records
    *
    * @return Total value.
    */
    private static Decimal getTotalFactHours(Monthly_Report__c[] monthlyReportList) {
        Decimal totalHours = 0;

        for (Monthly_Report__c report : monthlyReportList) {
            totalHours += report.Fact_hours__c;
        }

        return totalHours;
    }

    /**
    * @description Fills data from existing Payroll_Component records.
    *
    * @param year         Year number for period.
    * @param month        Month number for period.
    * @param overtimeList List with overtime information.
    */
    private static void addInformationFromExistingPayrollComponents(Integer year, Integer month, OvertimeInfo[] overtimeList) {
        Date dateOnFirstDayOfNextMonth = Date.newInstance(year, month, 1).addMonths(1);
        Id[] contractorIds = new Id[]{};

        for (OvertimeInfo ovt : overtimeList) {
            contractorIds.add(ovt.contractorId);
        }

        Payroll_Component__c[] existingOvertimes = [
            SELECT Id,
                Contractor__c,
                Hours__c
            FROM Payroll_Component__c
            WHERE Contractor__c IN :contractorIds
            AND RecordTypeId = :PayrollComponentSelector.RECORD_TYPE_INFO_OVERTIME.getRecordTypeId()
            AND StartDate__c >= :dateOnFirstDayOfNextMonth
            AND EndDate__c <= :DateUtils.getLastDayOfMonth(dateOnFirstDayOfNextMonth)
        ];

        Map<Id, Payroll_Component__c> contractorIdToPayrollComponentMap = new Map<Id, Payroll_Component__c>();

        for (Payroll_Component__c payrollComponent : existingOvertimes) {
            contractorIdToPayrollComponentMap.put(payrollComponent.Contractor__c, payrollComponent);
        }

        for (OvertimeInfo overtimeInfo : overtimeList) {

            if (contractorIdToPayrollComponentMap.containsKey(overtimeInfo.contractorId)) {
                Payroll_Component__c existingOvertimePayrollComponent = contractorIdToPayrollComponentMap.get(overtimeInfo.contractorId);
                overtimeInfo.overtimeHours = existingOvertimePayrollComponent.Hours__c;
                overtimeInfo.setIsPayrollCmpExist();
            }
        }
    }

    /**
     * @description Creates a list with parts based on the (sub)department of the Contractor.
     *
     * @param overtimeInfoList List with overtime information.
     *
     * @return List with overtime parts.
     */
    private static OvertimePart[] createOvertimeParts(OvertimeInfo[] overtimeInfoList) {
        OvertimePart[] overtimePartList = new OvertimePart[]{};
        Map<String, OvertimeInfo[]> subDepartmentToOvertimesMap = new Map<String, OvertimeInfo[]>();
        Map<String, OvertimeInfo[]> departmentToOvertimesMap = new Map<String, OvertimeInfo[]>();

        mapOvertimesByContractorDepartments(overtimeInfoList, subDepartmentToOvertimesMap, departmentToOvertimesMap);

        overtimePartList.addAll(createOvertimePartsByDepartmentName(subDepartmentToOvertimesMap));
        overtimePartList.addAll(createOvertimePartsByDepartmentName(departmentToOvertimesMap));

        return overtimePartList;
    }

    /**
     * @description Fills maps with information based on the (sub)department of the Contractor.
     *
     * @param overtimeInfoList List with overtime information.
     * @param subDepartmentToOvertimesMap Map with Contractor Sub-department name to overtime information.
     * @param departmentToOvertimesMap Map with Contractor Department name to overtime information.
     */
    private static void mapOvertimesByContractorDepartments(OvertimeInfo[] overtimeInfoList, Map<String, OvertimeInfo[]> subDepartmentToOvertimesMap, Map<String, OvertimeInfo[]> departmentToOvertimesMap) {

        for (OvertimeInfo overtimeInfo : overtimeInfoList) {

            if (overtimeInfo.contractorSubDepartment != null) {

                if (!subDepartmentToOvertimesMap.containsKey(overtimeInfo.contractorSubDepartment)) {
                    subDepartmentToOvertimesMap.put(overtimeInfo.contractorSubDepartment, new OvertimeInfo[]{});
                }

                subDepartmentToOvertimesMap.get(overtimeInfo.contractorSubDepartment).add(overtimeInfo);
            }
            else if (overtimeInfo.contractorDepartment != null) {

                if (!departmentToOvertimesMap.containsKey(overtimeInfo.contractorDepartment)) {
                    departmentToOvertimesMap.put(overtimeInfo.contractorDepartment, new OvertimeInfo[]{});
                }

                departmentToOvertimesMap.get(overtimeInfo.contractorDepartment).add(overtimeInfo);
            }
        }
    }

    /**
     * @description Creates overtime parts by (sub)department name.
     *
     * @param departmentNameToOvertimesMap Map with Contractor (sub)department name to overtime information.
     *
     * @return List with overtime parts.
     */
    private static OvertimePart[] createOvertimePartsByDepartmentName(Map<String, OvertimeInfo[]> departmentNameToOvertimesMap) {
        OvertimePart[] overtimePartList = new OvertimePart[]{};

        for (String departmentName : departmentNameToOvertimesMap.keySet()) {
            OvertimePart overtimePart = new OvertimePart();

            overtimePart.label = departmentName;
            overtimePart.overtimeInfoList = departmentNameToOvertimesMap.get(departmentName);

            overtimePartList.add(overtimePart);
        }

        return overtimePartList;
    }

    /**
     * @description Check whether overtime generation is blocked for the user in the current month or not.
     *
     * @return Boolean - blocked or not.
     */
    private static Boolean isBlockedForGenerationBasedOnUser() {
        PayrollDateRulesService.PayrollBlockingDaysInfo payrollBlockingDaysInfo = new PayrollDateRulesService().getBlockingDaysInfoByUserAndUserRoleIds(
            UserInfo.getUserId(),
            UserInfo.getUserRoleId()
        );

        // to avoid dependence on settings
        if (Test.isRunningTest()) return false;

        // block if there is no setting for the current user or the day is not specified
        if ( !payrollBlockingDaysInfo.isAvailable() || payrollBlockingDaysInfo.getSalarySupplementsDay() == null) return true;

        // block if current day greater than day from settings
        return Date.valueOf(System.now()).day() > payrollBlockingDaysInfo.getSalarySupplementsDay();
    }

    /**
     * @description Filters all selected overtime from the parts.
     *
     * @param overtimePartList List with overtime parts.
     *
     * @return List with selected overtimes.
     */
    private static OvertimeInfo[] getSelectedOvertimesFromParts(OvertimePart[] overtimePartList) {
        OvertimeInfo[] selectedOvertimeInfoList = new OvertimeInfo[]{};

        for (OvertimePart overtimePart : overtimePartList) {

            for (OvertimeInfo overtimeInfo : overtimePart.overtimeInfoList) {

                if (overtimeInfo.isSelected) {
                    selectedOvertimeInfoList.add(overtimeInfo);
                }
            }
        }

        return selectedOvertimeInfoList;
    }

    /**
    * @description Generates a list with overtime information based Payroll_Component records.
    *
    * @param year         Year number for period.
    * @param month        Month number for period.
    * @param overtimeList List with overtime information.
    *
    * @return List with generated Payroll_Component records.
    */
    private static Payroll_Component__c[] overtimesToPayrollComponents(Integer year, Integer month, OvertimeInfo[] overtimeList) {
        Payroll_Component__c[] payrollComponentList = new Payroll_Component__c[]{};
        Id overtimeRecordTypeId = PayrollComponentSelector.RECORD_TYPE_INFO_OVERTIME.getRecordTypeId();
        String approvalStatusApproved = PayrollComponentSelector.APPROVAL_STATUS_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.ApprovalStatusPicklistKey.APPROVED);
        String sumTypeIncrement = PayrollComponentSelector.SUM_TYPE_PICKLIST_VALUES_MAP.get(PayrollComponentSelector.SumTypePicklistKey.INCREMENT);
        Date dateOnFirstDateOfNextMonth = Date.newInstance(year, month, 1).addMonths(1);

        Map<Id, Account> contractorIdToPersonAccountMap = getMapFromOvertimesWithContractorIdToPersonAccount(overtimeList);
        Map<Id, Payroll_Component__c> contractorIdToExistingPayrollComponentMap = mapContractorIdToExistingPayrollComponentFromOvertimes(overtimeList, dateOnFirstDateOfNextMonth);

        for (OvertimeInfo overtime : overtimeList) {
            Payroll_Component__c payrollComponent;

            if (contractorIdToExistingPayrollComponentMap.containsKey(overtime.contractorId)) {
                payrollComponent = contractorIdToExistingPayrollComponentMap.get(overtime.contractorId);

                payrollComponent.CurrencyIsoCode = overtime.contractorCurrencyIsoCode;
                payrollComponent.Hours__c = overtime.overtimeHours;
                payrollComponent.Overtime_Rate__c = overtime.overtimeRate;
                payrollComponent.Sum__c = overtime.overtimeHours * overtime.overtimeRate;
            }
            else {
                payrollComponent = new Payroll_Component__c();

                payrollComponent.RecordTypeId = overtimeRecordTypeId;
                payrollComponent.Approval_Status__c = approvalStatusApproved;
                payrollComponent.Contractor__c = overtime.contractorId;
                payrollComponent.Account__c = contractorIdToPersonAccountMap.get(overtime.contractorId).Id;
                payrollComponent.CurrencyIsoCode = overtime.contractorCurrencyIsoCode;
                payrollComponent.Hours__c = overtime.overtimeHours;
                payrollComponent.Overtime_Rate__c = overtime.overtimeRate;
                payrollComponent.Sum__c = overtime.overtimeHours * overtime.overtimeRate;
                payrollComponent.SumType__c = sumTypeIncrement;
                payrollComponent.StartDate__c = dateOnFirstDateOfNextMonth;
                payrollComponent.EndDate__c = dateOnFirstDateOfNextMonth;
            }

            payrollComponentList.add(payrollComponent);
        }

        return payrollComponentList;
    }

    /**
    * @description Generates a map with the person accounts of contractors.
    *
    * @param overtimeList List with overtime information.
    *
    * @return Map with key: Contractor ID | value: Contractor Person Account
    */
    private static Map<Id, Account> getMapFromOvertimesWithContractorIdToPersonAccount(OvertimeInfo[] overtimeList) {
        Set<Id> contractorIdSet = new Set<Id>();

        for (OvertimeInfo overtime : overtimeList) {
            contractorIdSet.add(overtime.contractorId);
        }

        Account[] contractorPersonAccountList = new AccountSelector().getActualPersonAccountsByContractorIds(contractorIdSet);

        return mapContractorIdToAccount(contractorPersonAccountList);
    }

    /**
    * @description Map formation with Contractor ID to the Contractor person account.
    *
    * @param contractorPersonAccountList List with Contractor's person accounts
    *
    * @return Map with key: Contractor ID | value: Contractor's person account
    */
    private static Map<Id, Account> mapContractorIdToAccount(Account[] contractorPersonAccountList) {
        Map<Id, Account> contractorIdToPersonAccountMap = new Map<Id, Account>();

        for (Account contractorPersonAccount : contractorPersonAccountList) {
            contractorIdToPersonAccountMap.put(contractorPersonAccount.Contractor__c, contractorPersonAccount);
        }

        return contractorIdToPersonAccountMap;
    }

    /**
    * @description Generates a map with existing Payroll_Component record for contractor.
    *
    * @param overtimeList              List with overtime information.
    * @param payrollComponentStartDate StartDate of Payroll_Component record.
    *
    * @return Map with key: Contractor ID | value: existing Payroll_Component record
    */
    private static Map<Id, Payroll_Component__c> mapContractorIdToExistingPayrollComponentFromOvertimes(OvertimeInfo[] overtimeList, Date payrollComponentStartDate) {
        Map<Id, Payroll_Component__c> contractorIdToExistingPayrollComponentMap = new Map<Id, Payroll_Component__c>();
        Set<Id> contractorIdSet = new Set<Id>();

        for (OvertimeInfo overtime : overtimeList) {
            contractorIdSet.add(overtime.contractorId);
        }

        Payroll_Component__c[] existingPayrollComponentList = [
            SELECT Contractor__c, Hours__c, CurrencyIsoCode, Sum__c, Overtime_Rate__c, StartDate__c, EndDate__c
            FROM Payroll_Component__c
            WHERE Contractor__c IN :contractorIdSet
            AND StartDate__c >= :payrollComponentStartDate
            AND EndDate__c <= :DateUtils.getLastDayOfMonth(payrollComponentStartDate)
            AND RecordTypeId = :PayrollComponentSelector.RECORD_TYPE_INFO_OVERTIME.getRecordTypeId()
            LIMIT 10000
        ];


        for (Payroll_Component__c payrollComponent : existingPayrollComponentList) {
            contractorIdToExistingPayrollComponentMap.put(payrollComponent.Contractor__c, payrollComponent);
        }

        return contractorIdToExistingPayrollComponentMap;
    }

    /**
     * @description Class to keep settings for the component.
     */
    public class ComponentConfig {

        public Model.PicklistOption[] monthDropdownOptionList { get; set; }
        public Model.PicklistOption[] yearDropdownOptionList { get; set; }
    }

    /**
    * @description Wrapper to keep the part of information about overtimes.
    */
    public class OvertimePart {

        public String id;
        public String label;
        public Boolean isOpen = true;
        public Boolean isDisabled = false;
        public Boolean isAllSelected = false;
        public OvertimeInfo[] overtimeInfoList = new OvertimeInfo[]{};

        {
            this.id = String.valueOf(Crypto.getRandomLong());
        }
    }

    /**
    * @description Wrapper for overtime information.
    */
    public class OvertimeInfo {

        @AuraEnabled public String contractorId;
        @AuraEnabled public String contractorName;
        @AuraEnabled public String contractorCurrencyIsoCode;
        @AuraEnabled public String contractorDepartment;
        @AuraEnabled public String contractorSubDepartment;
        @AuraEnabled public Decimal factHours;
        @AuraEnabled public Decimal expectedHours;
        @AuraEnabled public Decimal overtimeDelta;
        @AuraEnabled public Decimal overtimeHours;
        @AuraEnabled public Decimal overtimeRate;
        @AuraEnabled public ProjectInfo[] projectInfoList;
        @AuraEnabled public Boolean isPayrollCmpExist = false;
        @AuraEnabled public Boolean isSelected = true;

        public OvertimeInfo(Monthly_Report__c[] monthlyReportList, Decimal overtimeRate, Decimal contractorWorkingHours, Decimal totalFactHours) {
            this.addContractorDataFromMonthlyReport(monthlyReportList[0].Contractor__r);
            this.addDataFromMonthlyReports(monthlyReportList);
            this.overtimeRate = overtimeRate;
            this.expectedHours = contractorWorkingHours;
            this.factHours = totalFactHours;
            this.overtimeDelta = this.factHours - this.expectedHours;
            this.overtimeHours = this.factHours - this.expectedHours;

            if ((this.overtimeHours.precision() - this.overtimeHours.scale()) > FIELD_DIGIT_LIMIT_HOURS) {
                this.overtimeHours = FIELD_MAX_NUMBER_HOURS;
            }
        }

        // custom setter to avoid problems on deserialization
        public void setIsPayrollCmpExist() {
            this.isPayrollCmpExist = true;
            this.isSelected = false;
        }

        private void addContractorDataFromMonthlyReport(Contractor__c contractor) {
            this.contractorId = contractor.Id;
            this.contractorName = contractor.Name;
            this.contractorCurrencyIsoCode = contractor.CurrencyIsoCode;
            this.contractorDepartment = contractor.Department__c;
            this.contractorSubDepartment = contractor.Sub_Department__c;
        }

        /**
        * @description Adds information about the projects from Monthly_Report records.
        *
        * @param monthlyReportList List with Monthly_Report records
        */
        private void addDataFromMonthlyReports(Monthly_Report__c[] monthlyReportList) {
            Map<Id, ProjectInfo> allocationIdToProjectInfoMap = new Map<Id, ProjectInfo>();
            Map<Id, ProjectInfo> projectIdToInfoMap = new Map<Id, ProjectInfo>();

            for (Monthly_Report__c monthlyReport : monthlyReportList) {

                if (!allocationIdToProjectInfoMap.containsKey(monthlyReport.Allocation__c)) {
                    ProjectInfo projectInfo = new ProjectInfo();

                    projectInfo.id = monthlyReport.Project__c;
                    projectInfo.name = monthlyReport.Project__r.Name;
                    projectInfo.factHours += monthlyReport.Fact_hours__c;
                    projectInfo.allocationPercentage = monthlyReport.Allocation_percentage__c;

                    allocationIdToProjectInfoMap.put(monthlyReport.Allocation__c, projectInfo);
                    continue;
                }

                allocationIdToProjectInfoMap.get(monthlyReport.Allocation__c).factHours += monthlyReport.Fact_hours__c;
            }

            for (ProjectInfo projectInfo : allocationIdToProjectInfoMap.values()) {

                if (!projectIdToInfoMap.containsKey(projectInfo.id)) {
                    projectIdToInfoMap.put(projectInfo.id, projectInfo);
                    continue;
                }

                ProjectInfo sumProjectInfo = projectIdToInfoMap.get(projectInfo.id);
                sumProjectInfo.factHours += projectInfo.factHours;
                sumProjectInfo.allocationPercentage += projectInfo.allocationPercentage;
            }

            this.projectInfoList = projectIdToInfoMap.values();
        }
    }

    /**
    * @description Wrapper for project information.
    */
    public class ProjectInfo {

        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal factHours = 0;
        @AuraEnabled public Decimal allocationPercentage = 0;
    }

    /**
     * @description Wrapper for sending a response to a Lightning component
     */
    public class LightningResponse extends Model.LightningResponse {

        @AuraEnabled public Boolean isUserBlockedForGeneration;
        @AuraEnabled public Boolean isReadOnlyMode;

        /* For success response with JSON data  */
        public void setResult(String data) {
            this.data = data;
            this.success = true;
        }

        /* For error response with message */
        public void setError(String message) {
            this.message = message;
            this.success = false;
        }

        /* For error response with code */
        public LightningResponse setError(Integer code) {
            this.code = code;
            this.success = false;
            return this;
        }
    }
}