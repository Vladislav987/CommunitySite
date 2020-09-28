/**
 * Created by Mychailo Hamdzii on 25.04.2019.
 */

public with sharing class AllocationRateCountService {
    static RatesCoefitientsSelector mdtSelector = new RatesCoefitientsSelector();
    private static final String WORKING_DAYS_MDT_LABEL = 'Working Days';
    private static final String MDT_RECORD_WORKING_DAYS_PROBLEM = 'There was problem with working days from mdt';
    private static final Integer WORKING_HOURS_IN_DAY = 8;

    private enum RateField { HOURLY, DAILY, MONTHLY }
    /**
     * Checking records for rates fields changes and after sending them for setting rates correctly
     *
     * @param allocations - Trigger.new from before update context, new field values
     * @param prevAllocationsByIds Trigger.oldMap, previous values from before update context
     */
    public void prepareRecordsForUpdate(List<Allocation__c> allocations, Map<Id, Allocation__c> prevAllocationsByIds) {
        List<RateChange> rateChanges = new List<RateChange>();
        for (Allocation__c allocation : allocations) {

            switch on getRateField(allocation, prevAllocationsByIds.get(allocation.Id)) {
                when HOURLY {

                    rateChanges.add(
                        new RateChange(allocation, RateField.HOURLY, allocation.Expected_Rate__c)
                    );
                }

                when DAILY {

                    rateChanges.add(
                        new RateChange(allocation, RateField.DAILY, allocation.Expected_Rate_Daily__c)
                    );
                }

                when MONTHLY {

                    rateChanges.add(
                        new RateChange(
                            allocation,
                            RateField.MONTHLY,
                            allocation.Expected_Rate_Monthly__c
                        )
                    );
                }
            }
        }

        if (!rateChanges.isEmpty()) {
            setRateFields(rateChanges);
        }
    }
    /**
     * Selecting core Rate and recount other rates, based on this
     *
     * @param allocations - Trigger.new, allocation to inseert
     */
    public void prepareRecordsForInsert(List<Allocation__c> allocations) {
        List<RateChange> rateChanges = new List<RateChange>();
        Decimal value;
        for (Allocation__c allocation : allocations) {
            RateField rateField = getRateField(allocation);
            switch on rateField{

                when HOURLY {
                    value = allocation.Expected_Rate__c;
                }

                when DAILY {
                    value = allocation.Expected_Rate_Daily__c;
                }

                when MONTHLY {
                    value = allocation.Expected_Rate_Monthly__c;
                }

                when null {
                    value = null;
                }
            }
            rateChanges.add(new RateChange(allocation, rateField, value));
        }

        if (!rateChanges.isEmpty()) {
            setRateFields(rateChanges);
        }
    }

    private void setRateFields(List<RateChange> rateChanges) {
        List<Rates_Coefitients__mdt> workingDaysInMonth = mdtSelector.getCoefitientsFromMdt(WORKING_DAYS_MDT_LABEL);
        if (workingDaysInMonth.isEmpty() || workingDaysInMonth[0].Value__c == null) {
            rateChanges[0].allocation.addError(MDT_RECORD_WORKING_DAYS_PROBLEM);
        }
        Decimal workingDays = workingDaysInMonth[0].Value__c;

        for (RateChange rateChange : rateChanges) {
            if (rateChange.value == null) {

                rateChange.allocation.Expected_Rate__c = null;
                rateChange.allocation.Expected_Rate_Daily__c = null;
                rateChange.allocation.Expected_Rate_Monthly__c = null;

            } else {

                switch on rateChange.field {

                    when HOURLY {
                        rateChange.allocation.Expected_Rate_Daily__c = rateChange.value * WORKING_HOURS_IN_DAY;
                        rateChange.allocation.Expected_Rate_Monthly__c =
                            rateChange.value * WORKING_HOURS_IN_DAY * workingDays;
                    }

                    when DAILY {
                        rateChange.allocation.Expected_Rate__c = rateChange.value / WORKING_HOURS_IN_DAY;
                        rateChange.allocation.Expected_Rate_Monthly__c = rateChange.value * workingDays;
                    }

                    when MONTHLY {
                        rateChange.allocation.Expected_Rate__c = rateChange.value / (workingDays * WORKING_HOURS_IN_DAY);
                        rateChange.allocation.Expected_Rate_Daily__c = rateChange.value / workingDays;
                    }
                }
            }
        }
    }

    private RateField getRateField(Allocation__c allocationAfterUpdate, Allocation__c allocationBeforeUpdate) {
        if (convertIntoFineForm(allocationAfterUpdate.Expected_Rate__c) !=
            convertIntoFineForm(allocationBeforeUpdate.Expected_Rate__c)) {

            return RateField.HOURLY;
        }
        if (convertIntoFineForm(allocationAfterUpdate.Expected_Rate_Daily__c) !=
            convertIntoFineForm(allocationBeforeUpdate.Expected_Rate_Daily__c)) {

            return RateField.DAILY;
        }
        if (convertIntoFineForm(allocationAfterUpdate.Expected_Rate_Monthly__c) !=
            convertIntoFineForm(allocationBeforeUpdate.Expected_Rate_Monthly__c)) {

            return RateField.MONTHLY;
        }


        if(hasEmptyFieldRate(allocationAfterUpdate)){

            if (convertIntoFineForm(allocationAfterUpdate.Expected_Rate__c)  != null){

                return RateField.HOURLY;
            }

            if (convertIntoFineForm(allocationAfterUpdate.Expected_Rate_Daily__c) != null) {

                return RateField.DAILY;
            }

            if (convertIntoFineForm(allocationAfterUpdate.Expected_Rate_Monthly__c) != null){

                return RateField.MONTHLY;
            }

        }
        return null;
    }

    private Boolean hasEmptyFieldRate(Allocation__c allocationAfterUpdate) {
        return convertIntoFineForm(allocationAfterUpdate.Expected_Rate__c) == null ||
                convertIntoFineForm(allocationAfterUpdate.Expected_Rate_Daily__c) == null ||
                convertIntoFineForm(allocationAfterUpdate.Expected_Rate_Monthly__c) == null;
    }

    private Decimal convertIntoFineForm(Decimal value) {
        if (value != null) {

            return value.setScale(4);
        } else {

            return null;
        }
    }

    private RateField getRateField(Allocation__c allocation) {
        if (allocation.Expected_Rate__c != null && allocation.Expected_Rate__c != 0) {

            return RateField.HOURLY;
        }

        if (allocation.Expected_Rate_Daily__c != null && allocation.Expected_Rate_Daily__c != 0) {

            return RateField.DAILY;
        }

        if (allocation.Expected_Rate_Monthly__c != null && allocation.Expected_Rate_Monthly__c != 0) {

            return RateField.MONTHLY;
        }

        return null;
    }

    private class RateChange {
        Allocation__c allocation { get; set; }
        RateField field { get; set; }
        Decimal value { get; set; }
        public RateChange(Allocation__c allocation, RateField field, Decimal value) {
            this.allocation = allocation;
            this.field = field;
            this.value = value;
        }
    }
}