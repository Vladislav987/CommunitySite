public without sharing class ContractorRollUpServiceQueue implements Queueable{
    private Set<Id> contractorsIds;
    ContractorService contractorService = new ContractorService();

    public ContractorRollUpServiceQueue(Set<Id> contractorsIds){
        this.contractorsIds = contractorsIds;
    }

    public void execute(QueueableContext context){
        contractorService.recalculateAllocationFields(contractorsIds);
    }

}