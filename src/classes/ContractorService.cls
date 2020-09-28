public without sharing class ContractorService {
    ContractorSelector contractorSelector = new ContractorSelector();

    public void checkFieldSalaryAndUpdateSalaryHistory(List<Contractor__c> contractors, Map<Id, Contractor__c> oldContractors) {
        List<Contractor__c> contractorsWithChangedSalary = new List<Contractor__c>();
        SalaryHistoryService salaryHistoryService = new SalaryHistoryService();
        for (Contractor__c contractor : contractors) {
            if (contractor.Salary__c != oldContractors.get(contractor.Id).Salary__c) {
                contractorsWithChangedSalary.add(contractor);
            }
        }
        if (!contractorsWithChangedSalary.isEmpty()) {
            salaryHistoryService.createRecords(contractorsWithChangedSalary);
        }
    }

    public void checkSalaryForNull(List<Contractor__c> newContractors, Map<Id, Contractor__c> existingRecords) {
        for (Contractor__c contractor : newContractors) {
            if (contractor.Salary__c == null && existingRecords.get(contractor.Id).Salary__c != null) {
                contractor.addError('Salary field can not be empty');
            }
        }
    }

    public void recalculateAllocationFields(Set<Id> contractorsIds) {
        Date afterTwoWeak = Date.today().addDays(14);
        List<Contractor__c> contractors = contractorSelector.getWithDataForRollUpCount(contractorsIds);

        for (Contractor__c contractor : contractors) {
            contractor.All_allocations_in_2_weeks__c = 0;
            contractor.All_billable_allocations_in_2_weeks__c = 0;
            contractor.All_active_allocations__c = 0;
            contractor.All_billable_allocations__c = 0;

            for (Allocation__c allocation : contractor.Allocations__r) {
                if (allocation.Start_date__c <= Date.today() && allocation.End_date__c >= Date.today()) {
                    contractor.All_active_allocations__c += allocation.Allocation__c;

                    if (allocation.Allocation_Type__c == 'Billable') {
                        contractor.All_billable_allocations__c += allocation.Allocation__c;

                    }
                }
                if (allocation.Start_date__c <= afterTwoWeak && allocation.End_date__c >= afterTwoWeak) {
                    contractor.All_allocations_in_2_weeks__c += allocation.Allocation__c;

                    if (allocation.Allocation_Type__c == 'Billable') {
                        contractor.All_billable_allocations_in_2_weeks__c += allocation.Allocation__c;

                    }
                }
            }
        }
        update contractors;
    }

    public void recalculatePlanHours(Set<Id> contractorsIds){
        Date startOfPreviousMonth = Date.today().toStartOfMonth().addMonths(-1);
        Date endOfPreviousMonth = Date.today().toStartOfMonth().addDays(-1);
        List<Contractor__c> contractors = new List<Contractor__c>();
        List<AggregateResult> aggregateResults = [
                SELECT Contractor__c
                        , SUM(Fact_hours__c)sumFH
                FROM Monthly_Report__c
                WHERE Contractor__c IN :contractorsIds
                AND Monthly_Report_Start_Date__c >= :startOfPreviousMonth
                AND Monthly_Report_Start_Date__c <= :endOfPreviousMonth
                GROUP BY Contractor__c
        ];

        for (AggregateResult agg: aggregateResults){

            Contractor__c contractor = new Contractor__c();
            contractor.Id = (Id)agg.get('Contractor__c');
            contractor.FacHoursLastMonth__c = (Decimal)agg.get('sumFH');
            contractors.add(contractor);
            contractorsIds.remove((Id)agg.get('Contractor__c'));
        }
        for (Id contractorId: contractorsIds){
            if (contractorId != null) {
                Contractor__c contractor = new Contractor__c();
                contractor.Id = contractorId;
                contractor.FacHoursLastMonth__c = 0;
                contractors.add(contractor);
            }
        }

        update contractors;
    }
}