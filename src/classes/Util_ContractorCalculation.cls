/**
 * Created by Lambru Dmytro on 07.07.2020.
 */

public inherited sharing class Util_ContractorCalculation {

    // Number of working hours per day
    public Integer workingHoursPerDay;
    // Map with key: Station picklist value | value: Country prefix e.g. 'UA'
    public Map<String, String> stationToCountryPrefixMap = new Map<String, String>();
    // Map with key: Country prefix e.g. 'UA' | value: Set with dates of holiday days
    public Map<String, Set<Date>> countryPrefixToHolidayDatesMap = new Map<String, Set<Date>>();
    // Map with key: Station picklist value | value: total working days
    public Map<String, Integer> stationToWorkingDaysMap = new Map<String, Integer>();

    // Year number for period
    private Integer year;
    // Month number for period
    private Integer month;

    {
        this.workingHoursPerDay = 8;
        createHelperMapsForCalculatingWorkingDays();
    }

    /**
     * @description Sets with the current period by default.
     */
    public Util_ContractorCalculation() {
        Date dateNow = Date.valueOf(System.now());

        this.setNewPeriod(dateNow.year(), dateNow.month());
    }

    public Util_ContractorCalculation(Integer year, Integer month) {
        this.setNewPeriod(year, month);
    }

    /**
     * @description Sets a new period and calculates working days for each station.
     *
     * @param year  Year number for period.
     * @param month Month number for period.
     */
    public void setNewPeriod(Integer year, Integer month) {
        this.year = year;
        this.month = month;

        this.mapStationToWorkingDays();
    }

    /**
    * @description Obtaining working hours for each contractor based on the working days in the month and its joining or(and) exit dates.
    *
    * @param contractorIdSet Set with Contractor IDs
    *
    * @return Map with key: Contractor ID | value: Total working hours per month
    */
    public Map<Id, Decimal> getWorkingHoursForContractors(Set<Id> contractorIdSet) {
        Contractor__c[] contractorList = [
            SELECT
                Station__c,
                Joining_Date__c,
                Exit_Date__c
            FROM Contractor__c
            WHERE Id IN :contractorIdSet
            LIMIT 10000
        ];

        return this.getWorkingHoursForContractors(contractorList);
    }

    /**
    * @description Obtaining working hours for each contractor based on the working days in the month and its joining or(and) exit dates.
    *
    * @param contractorList List with Contractors
    *
    * @return Map with key: Contractor ID | value: Total working hours per month
    */
    public Map<Id, Decimal> getWorkingHoursForContractors(Contractor__c[] contractorList) {
        Map<Id, Decimal> contractorIdToWorkingHoursMap = new Map<Id, Decimal>();
        Contractor__c[] contractorWithNotFullMonthList = new Contractor__c[]{};
        Date lastDayOfMonth = DateUtils.getLastDayOfMonth(Date.newInstance(this.year, this.month, 1));

        for (Contractor__c contractor : contractorList) {
            Decimal workingHours = 0;

            if (contractor.Joining_Date__c > lastDayOfMonth) {
                contractorIdToWorkingHoursMap.put(contractor.Id, workingHours);
            }
            else if (isJoinOrExitMonth(contractor)) {
                contractorWithNotFullMonthList.add(contractor);
            }
            else {
                workingHours = this.stationToWorkingDaysMap.get(contractor.Station__c) * this.workingHoursPerDay;
                contractorIdToWorkingHoursMap.put(contractor.Id, workingHours);
            }
        }

        contractorIdToWorkingHoursMap.putAll(this.getWorkingHoursForContractorsWithNotFullMonth(contractorWithNotFullMonthList));

        return contractorIdToWorkingHoursMap;
    }

    /**
    * @description Fills the maps that are needed to calculate the working days.
    */
    private void createHelperMapsForCalculatingWorkingDays() {

        for (Station_by_Country_prefix__mdt stationByCountryPrefix : this.getStationByCountryPrefixes()) {
            this.stationToCountryPrefixMap.put(stationByCountryPrefix.Station__c, stationByCountryPrefix.Country_prefix__c);
        }

        for (String countryPrefix : new Set<String>(this.stationToCountryPrefixMap.values())) {
            this.countryPrefixToHolidayDatesMap.put(countryPrefix, new Set<Date>());
        }

        for (Holiday holiday : this.getHolidays()) {

            if (holiday.Name.contains('_')) {
                String countryPrefix = holiday.Name.substring(0, holiday.Name.indexOf('_'));

                if (this.countryPrefixToHolidayDatesMap.containsKey(countryPrefix)) {
                    this.countryPrefixToHolidayDatesMap.get(countryPrefix).add(holiday.ActivityDate);
                }
            }
        }
    }

    private List<Station_by_Country_prefix__mdt> getStationByCountryPrefixes() {

        return [
            SELECT
                Station__c,
                Country_prefix__c
            FROM Station_by_Country_prefix__mdt
        ];
    }

    private List<Holiday> getHolidays() {

        return [
            SELECT
                Name,
                ActivityDate
            FROM Holiday
        ];
    }

    /**
    * @description Obtaining working days for each station based on the working days in the month.
    */
    private void mapStationToWorkingDays() {
        Map<String, Integer> countryPrefixToWorkingDaysMap = new Map<String, Integer>();
        Date firstDayOfMonth = Date.newInstance(this.year, this.month, 1);
        Date lastDayOfMonth = DateUtils.getLastDayOfMonth(firstDayOfMonth);

        for (String countryPrefix : this.countryPrefixToHolidayDatesMap.keySet()) {
            Set<Date> holidaysSet = this.countryPrefixToHolidayDatesMap.get(countryPrefix);
            Integer workingDays = 0;

            for (Integer i = 0; i <= firstDayOfMonth.daysBetween(lastDayOfMonth); i++) {
                Date nextWorkingDate = firstDayOfMonth + i;
                Integer weekdayNumber = this.getWeekdayNumberFromDate(nextWorkingDate);

                if ( // skip on saturday, sunday and public holidays
                    weekdayNumber != 6
                    && weekdayNumber != 7
                    && (holidaysSet == null || !holidaysSet.contains(nextWorkingDate))
                ) {
                    workingDays++;
                }
            }

            countryPrefixToWorkingDaysMap.put(countryPrefix, workingDays);
        }

        for (String station : this.stationToCountryPrefixMap.keySet()) {
            String countryPrefix = this.stationToCountryPrefixMap.get(station);

            this.stationToWorkingDaysMap.put(station, countryPrefixToWorkingDaysMap.get(countryPrefix));
        }
    }

    /**
     * @description Obtaining working hours for contractors who entered(Joining_Date) or(and) leaves(Exit_Date) the company during the specified period.
     *
     * @param contractorWithNotFullMonthList List with Contractors
     *
     * @return Map with key: Contractor ID | value: Total working hours per month
     */
    private Map<Id, Decimal> getWorkingHoursForContractorsWithNotFullMonth(Contractor__c[] contractorWithNotFullMonthList) {
        Map<Id, Decimal> contractorIdToWorkingHoursMap = new Map<Id, Decimal>();

        if (contractorWithNotFullMonthList.isEmpty()) return contractorIdToWorkingHoursMap;

        Map<Id, Integer> contractorIdToWorkingDaysMap = this.getWorkingDaysForContractorsWithNotFullMonth(contractorWithNotFullMonthList);

        for (Contractor__c contractor : contractorWithNotFullMonthList) {
            Decimal workingHours = contractorIdToWorkingDaysMap.get(contractor.Id) * this.workingHoursPerDay;
            contractorIdToWorkingHoursMap.put(contractor.Id, workingHours);
        }

        return contractorIdToWorkingHoursMap;
    }

    /**
    * @description Obtaining working days for each contractor based on the working days in the month and its join or(and) exit dates.
    *
    * @param contractorWithNotFullMonthList    Contractor record with joining date or exit date in period.
    *
    * @return Map with key: contractor ID | value: total working days
    */
    private Map<Id, Integer> getWorkingDaysForContractorsWithNotFullMonth(Contractor__c[] contractorWithNotFullMonthList) {
        Map<Id, Integer> contractorIdToWorkingDaysMap = new Map<Id, Integer>();

        for (Contractor__c contractor : contractorWithNotFullMonthList) {
            Date firstDayOfMonth = this.getFirstDayOfPeriodForContractor(contractor);
            Date lastDayOfMonth = this.getLastDayOfPeriodForContractor(contractor);

            String countryPrefix = this.stationToCountryPrefixMap.get(contractor.Station__c);
            Set<Date> holidaysSet = this.countryPrefixToHolidayDatesMap.get(countryPrefix);
            Integer workingDays = 0;

            for (Integer i = 0, daysBetween = firstDayOfMonth.daysBetween(lastDayOfMonth); i <= daysBetween; i++) {
                Date nextWorkingDate = firstDayOfMonth + i;
                Integer weekdayNumber = this.getWeekdayNumberFromDate(nextWorkingDate);

                if ( // skip on saturday, sunday and public holidays
                    weekdayNumber != 6
                    && weekdayNumber != 7
                    && (holidaysSet == null || !holidaysSet.contains(nextWorkingDate))
                ) {
                    workingDays++;
                }
            }

            contractorIdToWorkingDaysMap.put(contractor.Id, workingDays);
        }

        return contractorIdToWorkingDaysMap;
    }

    // TODO: Move it to DateUtils when SFDX development is implemented
    private Integer getWeekdayNumberFromDate(Date fromDate) {
        return Integer.valueOf(((Datetime) fromDate).format('u'));
    }

    private Boolean isJoinOrExitMonth(Contractor__c contractor) {
        return (contractor.Joining_Date__c.year() == this.year && contractor.Joining_Date__c.month() == this.month)
               || (contractor.Exit_Date__c != null && contractor.Exit_Date__c.year() == this.year && contractor.Exit_Date__c.month() == this.month);
    }

    private Date getFirstDayOfPeriodForContractor(Contractor__c contractor) {
        return isDateInPeriod(contractor.Joining_Date__c)
               ? contractor.Joining_Date__c
               : Date.newInstance(this.year, this.month, 1);
    }

    private Date getLastDayOfPeriodForContractor(Contractor__c contractor) {
        return contractor.Exit_Date__c != null && isDateInPeriod(contractor.Exit_Date__c)
               ? contractor.Exit_Date__c
               : DateUtils.getLastDayOfMonth(Date.newInstance(this.year, this.month, 1));
    }

    private Boolean isDateInPeriod(Date checkingDate) {
        return checkingDate.year() == this.year && checkingDate.month() == this.month;
    }
}