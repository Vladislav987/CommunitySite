/**
 * Created by MaxymMirona on 07.07.2020.
 */

public without sharing class LA_ContractorsPMTabService {

    public ProjectSelector projectSelectorObject = new ProjectSelector();
    public ContractorSelector contractorSelectorObject = new ContractorSelector();
    public static Datetime CURRENT_DATETIME = System.now();

    public GridDataWrapper getGridData(String stringPeriod) {
        Id userId = UserInfo.getUserId();
        Set<Contractor__c> contractors = new Set<Contractor__c>();
        Map<Id, Set<Allocation__c>> allocationsByContractors = new Map<Id, Set<Allocation__c>>();
        Map<Id, List<Allocation__c>> allocationsListByContractors = new Map<Id, List<Allocation__c>>();
        Map<Id, Map<Id, Decimal>> allocationsPercentByProjectIdsByContractorIds = new Map<Id, Map<Id, Decimal>>();
        Map<Id, Map<Id, Decimal>> factHoursByAllocationIdsByContractorIds = new Map<Id, Map<Id, Decimal>>();
        Map<Id, Decimal> factHoursByContractorIds = new Map<Id, Decimal>();
        Date datePeriod = Date.parse(stringPeriod.replace('.', '/'));
        Date startDate = Date.newInstance(datePeriod.year(), datePeriod.month(), 1);
        Date endDate = Date.newInstance(datePeriod.year(), datePeriod.month() + 1 , 1).addDays(-1);
        Util_ContractorCalculation contractorCalculation = new Util_ContractorCalculation(endDate.year(), endDate.month());

        List<Contractor__c> userContractors = contractorSelectorObject.getContractorsByPrimaryPM(userId, startDate, endDate);

        for (Contractor__c contractor : userContractors) {
            Map<Id, Decimal> allocationsPercentByProjectId = new Map<Id, Decimal>();
            contractors.add(contractor);

            if (!contractor.Allocations__r.isEmpty()) {
                for (Allocation__c allocation : contractor.Allocations__r) {
                    if (allocationsByContractors.containsKey(contractor.Id)) {
                        allocationsByContractors.get(contractor.Id).add(allocation);
                    } else {
                        allocationsByContractors.put(contractor.Id, new Set<Allocation__c>{
                                allocation
                        });
                    }
                }
            }
            System.debug(contractor.Name);
            System.debug(contractor.Allocations__r.size());
            allocationsPercentByProjectIdsByContractorIds.put(contractor.Id, allocationsPercentByProjectId);

            if (!contractor.Monthly_Reports__r.isEmpty()) {
                Map<Id, Decimal> factHoursByAllocationIds = new Map<Id, Decimal>();

                for (Monthly_Report__c report : contractor.Monthly_Reports__r) {
                    Allocation__c reportsAllocation = /*allocationsByContractors.get(contractor.Id).contains(report.Allocation__r) ? report.Allocation__r : */null;

                    for (Allocation__c allocation : allocationsByContractors.get(contractor.Id)) {
                        if (allocation.Id == report.Allocation__r.Id) {
                            reportsAllocation = report.Allocation__r;

                            break;
                        }
                    }

                    if (reportsAllocation != null) {
                        if (factHoursByAllocationIds.containsKey(reportsAllocation.Id)) {
                            factHoursByAllocationIds.put(reportsAllocation.Id, factHoursByAllocationIds.get(reportsAllocation.Id) + (report.Fact_hours__c == null ? 0 : report.Fact_hours__c));
                        } else {
                            factHoursByAllocationIds.put(reportsAllocation.Id, report.Fact_hours__c == null ? 0 : report.Fact_hours__c);
                        }
                    }
                }

                factHoursByAllocationIdsByContractorIds.put(contractor.Id, factHoursByAllocationIds);
            }
        }

        for (Id contractorId : allocationsByContractors.keySet()) {
            Decimal totalFactHours = 0;

            if (factHoursByAllocationIdsByContractorIds.containsKey(contractorId)) {
                Map<Id, Decimal> contractorFactHoursByAllocationIds = factHoursByAllocationIdsByContractorIds.get(contractorId);

                for (Id projectId : contractorFactHoursByAllocationIds.keySet()) {
                    totalFactHours += contractorFactHoursByAllocationIds.get(projectId) == null ? 0 : contractorFactHoursByAllocationIds.get(projectId);
                }

                factHoursByContractorIds.put(contractorId, totalFactHours);
            } else {
                factHoursByContractorIds.put(contractorId, 0);
            }
        }

        List<Contractor__c> contractorsList = new List<Contractor__c>(contractors);

        Map<Id, Decimal> expectedHoursByContractorIds = contractorCalculation.getWorkingHoursForContractors(contractorsList);

        for (Id contractor : allocationsByContractors.keySet()) {
            allocationsListByContractors.put(contractor, new List<Allocation__c>(allocationsByContractors.get(contractor)));
        }

        return new GridDataWrapper(contractorsList, allocationsListByContractors, expectedHoursByContractorIds, factHoursByAllocationIdsByContractorIds, factHoursByContractorIds);
    }

    public List<String> getGridMonths() {
        return new List<String>{
                CURRENT_DATETIME.format('MMMM'),
                CURRENT_DATETIME.addMonths(-1).format('MMMM')
        };
    }

    public List<String> getGridYears() {
        return new List<String>{
                String.valueOf(CURRENT_DATETIME.year())
        };
    }

    public class GridDataWrapper {
        @AuraEnabled
        public List<Contractor__c> contractors;

        @AuraEnabled
        public Map<Id, List<Allocation__c>> allocationsByContractors;

        @AuraEnabled
        public Map<Id, Decimal> expectedHoursByContractorIds;

        @AuraEnabled
        public Map<Id, Map<Id, Decimal>> factHoursByAllocationIdsByContractorIds;

        @AuraEnabled
        public Map<Id, Decimal> factHoursByContractorIds;

        public GridDataWrapper(
                List<Contractor__c> contractors,
                Map<Id, List<Allocation__c>> allocationsByContractors,
                Map<Id, Decimal> expectedHoursByContractorIds,
                Map<Id, Map<Id, Decimal>> factHoursByAllocationIdsByContractorIds,
                Map<Id, Decimal> factHoursByContractorIds
        ) {
            this.contractors = contractors;
            this.allocationsByContractors = allocationsByContractors;
            this.expectedHoursByContractorIds = expectedHoursByContractorIds;
            this.factHoursByAllocationIdsByContractorIds = factHoursByAllocationIdsByContractorIds;
            this.factHoursByContractorIds = factHoursByContractorIds;
        }
    }
}