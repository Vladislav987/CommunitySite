public without sharing class ContractorFactHoursCalculateQueue implements Queueable{
    private Set<Id> contractorsIds;

    public ContractorFactHoursCalculateQueue(Set<Id> contractorsIds){
        this.contractorsIds = contractorsIds;
    }


    public void execute(QueueableContext context){
       ContractorService contractorService = new ContractorService();

        contractorService.recalculatePlanHours(contractorsIds);
    }
}