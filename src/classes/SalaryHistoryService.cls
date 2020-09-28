public without sharing class SalaryHistoryService {
    private MonthlyReportService monthlyReportService = new MonthlyReportService();
    private SalaryHistorySelector salaryHistorySelector = new SalaryHistorySelector();
    private final Date END_DATE = Date.parse('01/12/2099');

    public void createRecords(List<Contractor__c> contractors) {
        List<Salary_History__c> salaryHistories = new List<Salary_History__c>();

        for (Contractor__c contractor : contractors) {

            Salary_History__c salaryHistory = new Salary_History__c();
            salaryHistory.Contractor__c = contractor.Id;
            salaryHistory.CurrencyIsoCode = contractor.CurrencyIsoCode;
            salaryHistory.Salary__c = contractor.Salary__c;
            salaryHistory.Date_of_creation__c = Datetime.now().format('MMMMM') + ' ' + Datetime.now().format('YYYY');
            salaryHistory.Start_Date__c = Date.today().toStartOfMonth();
            salaryHistory.End_Date__c = END_DATE;
            if (contractor.Salary__c == null) {
                salaryHistory.Salary__c = 0;
            }
            salaryHistories.add(salaryHistory);
        }
        if (!salaryHistories.isEmpty()) {
            insert salaryHistories;
        }
    }

    public void closeOldSalaryHistory(List<Contractor__c> contractors) {
        Map<Id, Salary_History__c> salaryHistoriesByIds = new Map<Id, Salary_History__c>();

        List<Salary_History__c> salaryHistories = [
                SELECT Id
                        , Name
                        , Contractor__c
                FROM Salary_History__c
                WHERE Contractor__c = :contractors
                AND End_Date__c = :END_DATE
                ORDER BY Name ASC
        ];


        for (Salary_History__c salaryHistory : salaryHistories) {
            if (!salaryHistoriesByIds.containsKey(salaryHistory.Contractor__c)) {
                salaryHistory.End_Date__c = Date.today().toStartOfMonth();

                salaryHistoriesByIds.put(salaryHistory.Contractor__c, salaryHistory);
            }
        }

        if (!salaryHistoriesByIds.values().isEmpty()) {

            monthlyReportService.getReportsBySalaryHistoryAndUpdateThem(salaryHistoriesByIds.values());

        }
    }
    /**
     * If Salary or Date on is changed then we need to update Monthly Report fields
     *
     * @param newSalaryHistories
     * @param oldSalaryHistoriesByIds
     */

    public void checkSalaryAndUpdateReports(List<Salary_History__c> newSalaryHistories, Map<Id, Salary_History__c> oldSalaryHistoriesByIds) {
        List<Salary_History__c> salaryHistories = new List<Salary_History__c>();

        for (Salary_History__c salaryHistory : newSalaryHistories) {
            if (salaryHistory.Salary__c != oldSalaryHistoriesByIds.get(salaryHistory.Id).Salary__c
                    || salaryHistory.End_Date__c != oldSalaryHistoriesByIds.get(salaryHistory.Id).End_Date__c) {

                salaryHistories.add(salaryHistory);
            }
        }


        monthlyReportService.getReportsBySalaryHistoryAndUpdateThem(salaryHistories);
    }

    public void checkForEmptySalary(Salary_History__c newSalaryHistory) {
        if (newSalaryHistory.Salary__c == null) {
            newSalaryHistory.addError('Salary field can not be Empty');
        }
    }
    public void validateAndCreate(List<Salary_History__c> salaryHistories) {
        for (Salary_History__c salaryHistory : salaryHistories) {
            if (salaryHistory.Start_Date__c < Date.today().toStartOfMonth()) {
                salaryHistory.addError('You can not create the Salary History record not for the current month!');
            } else if (salaryHistory.Start_Date__c == null) {
                salaryHistory.addError('You forgot to fill the Start Date field!');
            } else if (salaryHistory.Salary__c == null) {
                salaryHistory.addError('The Salary field can not be Empty!');
            } else if (salaryHistory.Start_Date__c > Date.today().toStartOfMonth().addMonths(1).addDays(-1)) {
                salaryHistory.addError('Start Day in this record not for the current month that why you cannot create Salary History record for future period');
            } else if (salaryHistory.Start_Date__c > salaryHistory.End_Date__c) {
                salaryHistory.addError('End Date cannot be early than Start Day!');
            } else {
                salaryHistory.Start_Date__c = Date.today().toStartOfMonth();
                salaryHistory.End_Date__c = END_DATE;
            }
        }
    }

    public void updatePreviousAndCreateNew(List<Salary_History__c> newSalaryHistories) {
        List<Salary_History__c> salaryHistoriesForUpdate = new List<Salary_History__c>();
        List<Contractor__c> contractorsForUpdate = new List<Contractor__c>();
        Set<Id> contractorsIds = new Set<Id>();
        Map<Id, Salary_History__c> lastSalaryByContractorId = new Map<Id, Salary_History__c>();
        List<Salary_History__c> salaryForUpdateReports = new List<Salary_History__c>();

        for (Salary_History__c salaryHistory : newSalaryHistories) {
            contractorsIds.add(salaryHistory.Contractor__c);
        }

        List<Salary_History__c> existSalaryHistories = salaryHistorySelector.getByContractorsIds(contractorsIds, new Map<Id, Salary_History__c>(newSalaryHistories).keySet());

        for (Salary_History__c salaryHistory : existSalaryHistories) {
            if (salaryHistory.End_Date__c == END_DATE) {
                lastSalaryByContractorId.put(salaryHistory.Contractor__c, salaryHistory);
            }
        }

        for (Salary_History__c newSalaryHistory : newSalaryHistories) {
            if (lastSalaryByContractorId.containsKey(newSalaryHistory.Contractor__c)) {
                Salary_History__c salaryHistory = lastSalaryByContractorId.get(newSalaryHistory.Contractor__c);
                salaryHistory.End_Date__c = newSalaryHistory.Start_Date__c;
                salaryHistoriesForUpdate.add(salaryHistory);
                salaryForUpdateReports.add(salaryHistory);
                Contractor__c contractor = salaryHistory.Contractor__r;
                contractor.Salary__c = newSalaryHistory.Salary__c;
                contractorsForUpdate.add(contractor);
            } else {
                salaryForUpdateReports.add(newSalaryHistory);
            }
        }

        SObjectDomain.isEnabledMap.put(SalaryHistoryTriggerHandler.class.getName(), false);
        SObjectDomain.isEnabledMap.put(ContractorTriggerHandler.class.getName(), false);
        update salaryHistoriesForUpdate;
        update contractorsForUpdate;

        monthlyReportService.getReportsBySalaryHistoryAndUpdateThem(salaryForUpdateReports);
    }


    public void validateUpdatedRecords(List<Salary_History__c> newSalaryHistories, Map<Id, Salary_History__c> oldSalaryHistories) {
        List<Contractor__c> contractorsForUpdate = new List<Contractor__c>();
        List<Id> newSalaryHistoriesContractorsIds = new List<Id>();
        for (Salary_History__c salaryHistory : newSalaryHistories) {
            newSalaryHistoriesContractorsIds.add(salaryHistory.Contractor__c);
        }
        List<Salary_History__c> existSalaryHistories = [SELECT Id, Start_Date__c, End_Date__c, Contractor__r.Salary__c FROM Salary_History__c WHERE Contractor__c IN :newSalaryHistoriesContractorsIds];
        for (Salary_History__c newSalaryHistory : newSalaryHistories) {
            if (newSalaryHistory.Start_Date__c != oldSalaryHistories.get(newSalaryHistory.Id).Start_Date__c) {
                newSalaryHistory.addError('You can not change the value of Start Date field');
            } else if (newSalaryHistory.End_Date__c != oldSalaryHistories.get(newSalaryHistory.Id).End_Date__c) {
                newSalaryHistory.addError('You can not change the value of End Date field');
            } else if (newSalaryHistory.Salary__c != oldSalaryHistories.get(newSalaryHistory.Id).Salary__c) {
                if (newSalaryHistory.End_Date__c == END_DATE) {
                    for (Salary_History__c salaryHistory : existSalaryHistories) {
                        if (newSalaryHistory.Contractor__c == salaryHistory.Contractor__c) {
                            Contractor__c currentContractor = salaryHistory.Contractor__r;
                            currentContractor.Salary__c = newSalaryHistory.Salary__c;
                            contractorsForUpdate.add(currentContractor);
                            break;
                        }
                    }
                } else if (newSalaryHistory.End_Date__c != END_DATE) {
                    newSalaryHistory.addError('You can not change Salary field for inactive Salary History record');
                }

            }
        }

        SObjectDomain.isEnabledMap.put(ContractorTriggerHandler.class.getName(), false);
        update contractorsForUpdate;
    }
}