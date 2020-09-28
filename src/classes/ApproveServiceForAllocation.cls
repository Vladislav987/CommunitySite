public without sharing class ApproveServiceForAllocation {
    public void fillApproverManagerField(List<Allocation__c> allocations) {
        ApproverAssignerSettingsDAO.ApproverAssignerSettingsWrapper settingsWrapper =
                (ApproverAssignerSettingsDAO.ApproverAssignerSettingsWrapper)CustomMetadataDAO.getSettings(ApproverAssignerSettingsDAO.class, allocations);

        if (settingsWrapper != null) {
            if (!String.isEmpty(settingsWrapper.getErrorMessage())) {
                allocations[0].addError(settingsWrapper.getErrorMessage());
            } else {
                settingsWrapper.updateRecords();
            }
        }
    }

    public void checkForFilledApproverField(List<Allocation__c> allocations) {
        List<Allocation__c> allocationsWithEmptyApproverField = new List<Allocation__c>();

        for (Allocation__c allocation : allocations) {
            if (allocation.Approver_Manager__c == null) {
                allocationsWithEmptyApproverField.add(allocation);
            }
        }

        SupportCaseServiceDAO.SupportCaseServiceWrapper settingsWrapper =
                (SupportCaseServiceDAO.SupportCaseServiceWrapper)CustomMetadataDAO.getSettings(SupportCaseServiceDAO.class, 'OneLevelApprovalProcess_Invoice', allocationsWithEmptyApproverField);

        settingsWrapper.handleAction(SupportCaseServiceDAO.ACTION_TYPE.SENDEMAIL);
    }

    public void fillApproverManagerField(Map<Id, Allocation__c> existingAllocations, List<Allocation__c> newAllocations) {
        List<Allocation__c> changedAllocations = new List<Allocation__c>();

        for (Allocation__c newAllocation : newAllocations) {
            Allocation__c oldAllocation = existingAllocations.get(newAllocation.Id);

            if (oldAllocation.Contractor__c != newAllocation.Contractor__c
                    || oldAllocation.Station__c != newAllocation.Station__c
                    || (oldAllocation.Resource_Type__c != newAllocation.Resource_Type__c
                    && newAllocation.Contractor__c == null)
                    ||  ((  oldAllocation.New_End_Date__c != newAllocation.New_End_Date__c
                    ||  oldAllocation.New_Start_Date__c != newAllocation.New_Start_Date__c
                    ||  oldAllocation.New_Allocation__c != newAllocation.New_Allocation__c)
                    && newAllocation.Status__c == 'Active')
                    ) {
                changedAllocations.add(newAllocation);
            }
        }

        fillApproverManagerField(changedAllocations);
    }

}