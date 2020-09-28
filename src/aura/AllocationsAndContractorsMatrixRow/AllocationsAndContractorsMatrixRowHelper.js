/**
 * Created by MaxymMirona on 28.01.2020.
 */

({
    onInitRow : function (component, event) {
        let allocationsByContractorIds = component.get("v.allocationsByContractorIds");
        let contractorId = component.get("v.selectedContractorId");
        let projects = component.get("v.projects");
        let selectedType = component.get("v.type");
        let sentToApprove = false;
        let totalAmount = 0;
        let haveChildAllocations = false;
        let allocations = [];

        projects.forEach(function (project, index, array) {
            let isLastItem = index === array.length - 1;
            let filteredAllocation = allocationsByContractorIds.filter(function (allocation) {
                if (allocation.Project__c == project.Id) {
                    if (allocation.Contractor__c == contractorId) {
                        if (allocation.Status__c === 'Pending' && allocation.Allocation_Type__c === selectedType) {
                            sentToApprove = true;
                            return true;
                        } else if (allocation.Allocation_Type__c === selectedType) {
                            return true;
                        }
                    }
                }
            })[0];

            if (filteredAllocation != undefined){
                allocations.push(filteredAllocation);
                if (filteredAllocation.New_Allocation__c !== undefined){
                    totalAmount += parseInt(filteredAllocation.New_Allocation__c);
                } else {
                    totalAmount += parseInt(filteredAllocation.Allocation__c);
                }
                if (isLastItem) {
                    if (!haveChildAllocations){
                        if (filteredAllocation.New_Allocation__c !== undefined){
                            totalAmount = parseInt(filteredAllocation.New_Allocation__c);
                        } else {
                            totalAmount = parseInt(filteredAllocation.Allocation__c);
                        }
                    }
                } else {
                    haveChildAllocations = true;
                }
                if (filteredAllocation.Status__c === 'Pending'){
                    component.set("v.sentToApprove", true);
                }
            } else {
                let blankAllocation = {
                    Id: null,
                    Project__c: project.Id,
                    Allocation__c: 0,
                    Allocation_Type__c: selectedType,
                    Contractor__c: contractorId
                };
                allocations.push(blankAllocation);
            }
        });

        component.set("v.sentToApprove", sentToApprove);
        component.set("v.totalAmount", totalAmount);
        component.set("v.newTotalAmount", totalAmount);
        component.set("v.allocations", allocations);
        component.set("v.approveRequired", false);

        this.sendApproveRequiredToParent(component, contractorId, false, true, true);
    },

    onChangeAllocationPercent : function (component, event) {
        let allocationPercent = parseInt(event.getSource().get("v.value"));
        let allocationJSON = event.getSource().get("v.name") + '}';                                                     //append '}' as we can't do it in Lightning
        let allocationObject = JSON.parse(allocationJSON);
        let contractorId = component.get("v.selectedContractorId");
        let allocationPercents = component.find("allocationPercent");
        let selectedType = component.get("v.type");
        let newTotalAmount = 0;
        let totalAmount = component.get("v.totalAmount");
        let allIsValid = true;
        let allocation;
        let randomExistingAllocation = component.get("v.allocations").filter(function (allocation) {
            return allocation.Id != null;
        })[0];

        if (randomExistingAllocation == undefined){
            this.showToast("Error", "error", "You don't have any existing Allocation in row. Please, create it manually");
            return;
        }

        if (Array.isArray(allocationPercents)) {
            allocationPercents.forEach(function (item) {
                newTotalAmount += isNaN(parseInt(item.get("v.value"))) ? allIsValid = false : parseInt(item.get("v.value"), 10);
            });
        } else {
            newTotalAmount += isNaN(parseInt(allocationPercents.get("v.value"))) ? allIsValid = false : parseInt(allocationPercents.get("v.value"), 10);
        }


        let approveRequired = newTotalAmount - totalAmount !== 0;

        if (allocationObject.Id == "") {
            allocation = {
                Id: null,
                Project__c: allocationObject.Project__c,
                Contractor__c: contractorId,
                Allocation_Type__c: selectedType,
                Start_date__c: randomExistingAllocation.Start_date__c,
                End_date__c: randomExistingAllocation.End_date__c,
                CurrencyIsoCode: randomExistingAllocation.CurrencyIsoCode,
                Overrun_Type__c: selectedType === 'Overrun' ? randomExistingAllocation.Overrun_Type__c : null,
                Status__c: randomExistingAllocation.Status__c,
                RecordTypeId: randomExistingAllocation.RecordTypeId,
                Allocation__c: allocationPercent,
                Resource_Type__c: randomExistingAllocation.Resource_Type__c,
                Expected_Rate__c: randomExistingAllocation.Expected_Rate__c,

            };
        } else {
            allocation = this.findAllocationInListById(component, allocationObject);

            if (allocation.Allocation__c != allocationPercent) {
                allocation.New_Allocation__c = allocationPercent;
            } else {
                allocation.Allocation__c = allocationPercent;
                allocation.New_Allocation__c = null;
            }
        }

        let existingAllocation = this.findAllocationInListByContractorAndProject(component, allocation);

        if (existingAllocation.Allocation__c != allocationPercent) {
            if (allIsValid) {
                if (!approveRequired) {
                    this.addAllocationToList(component, allocation, true);                                       //To move updated changed allocations from one list to another
                    this.moveAllocationsFromSaveAndApproveListToSaveList(component);
                } else {
                    this.addAllocationToList(component, allocation, approveRequired);
                }
            }
        } else {
            this.removeAllocationFromLists(component, allocation);
        }

        this.sendApproveRequiredToParent(component, contractorId, approveRequired, false, allIsValid);

        component.set("v.newTotalAmount", newTotalAmount);
        component.set("v.approveRequired", approveRequired && allIsValid);

        console.log("allocationsToSaveAndApprove ---> ");
        console.log(component.get("v.allocationsToSaveAndApprove"));
        console.log("allocationsToSave ---> ");
        console.log(component.get("v.allocationsToSave"));
    },

    removeAllocationFromLists : function (component, allocation){
        let allocationsToSaveAndApprove = component.get("v.allocationsToSaveAndApprove");
        let allocationsToSave = component.get("v.allocationsToSave");

        allocationsToSave = allocationsToSave.filter(item => {
            return (item.Contractor__c == allocation.Contractor__c && item.Project__c != allocation.Project__c) ||
                   (item.Contractor__c != allocation.Contractor__c && item.Project__c == allocation.Project__c)
        });

        allocationsToSaveAndApprove = allocationsToSaveAndApprove.filter(item => {
            return (item.Contractor__c == allocation.Contractor__c && item.Project__c != allocation.Project__c) ||
                   (item.Contractor__c != allocation.Contractor__c && item.Project__c == allocation.Project__c)
        });

        component.set("v.allocationsToSaveAndApprove", allocationsToSaveAndApprove);
        component.set("v.allocationsToSave", allocationsToSave);
    },

    findAllocationInListById : function (component, allocationObject){
      return component.get("v.allocations").filter(function (allocationInList) {
          return allocationInList.Id == allocationObject.Id;
      })[0];
    },

    findAllocationInListByContractorAndProject : function (component, allocationObject){
        return component.get("v.allocations").filter(function (allocationInList) {
            return allocationInList.Contractor__c == allocationObject.Contractor__c && allocationInList.Project__c == allocationObject.Project__c;
        })[0];
    },

    onApprove : function (component, event) {
        component.set("v.sentToApprove", true);
        component.set("v.isLoading", true);
        let contractorId = component.get("v.selectedContractorId");

        this.sendApproveRequiredToParent(component, contractorId, false, false, true);

        let allocationsToSaveAndApprove = this.getAllocationsForApprove(component);

        let approveAction = component.get("c.upsertAndApproveAllocations");
        approveAction.setParams({
            allocations : allocationsToSaveAndApprove
        });

        approveAction.setCallback(this, function (response) {
            let state = response.getState();
            let responseMessage = response.getReturnValue();

            if (state === "SUCCESS") {
                if (responseMessage === 'Success') {
                    this.refreshListsForApproveAndSave(component);
                    this.sendApproveRequiredToParent(component, contractorId, false, false, true);
                    this.showToast("Success!", "success", "Allocations has been sent for Approve");
                } else {
                    component.set("v.sentToApprove", false);
                    component.set("v.approveRequired", true);
                    this.sendApproveRequiredToParent(component, contractorId, true, false, true);
                    this.refreshListsForApproveAndSave(component);
                    this.onInitRow(component);
                    this.showToast("Error", "error", responseMessage);
                }
            } else if (state === "ERROR") {
                component.set("v.sentToApprove", false);
                component.set("v.approveRequired", true);
                this.sendApproveRequiredToParent(component, contractorId, true, false, true);
                this.refreshListsForApproveAndSave(component);
                this.showToast("Error", "error", responseMessage);
            }
            component.set("v.isLoading", false);
        });

        $A.enqueueAction(approveAction);
    },

    getAllocationsForApprove : function (component){
        let self = this;
        let allocationsToSave = component.get("v.allocationsToSave");

        allocationsToSave.forEach(function (allocation) {
            if (allocation.Allocation__c != allocation.New_Allocation__c){
                self.addAllocationToList(component, allocation, true);
            }
        });

        return component.get("v.allocationsToSaveAndApprove");
    },

    addAllocationToList : function (component, allocation, approveRequired) {
        let allocationsToSaveAndApprove = component.get("v.allocationsToSaveAndApprove");
        let allocationsToSave = component.get("v.allocationsToSave");
        let allocationsList;
        let neededListName;

        if (approveRequired) {
            allocationsList = allocationsToSaveAndApprove;
            neededListName = "v.allocationsToSaveAndApprove";
        } else {
            allocationsList = allocationsToSave;
            neededListName = "v.allocationsToSave";
        }

        let foundAllocation = this.findAllocationInList(allocationsList, allocation);

        if (foundAllocation == undefined){
            allocationsList.push(allocation);
        }

        component.set(neededListName, allocationsList);
    },

    findAllocationInList : function (allocations, allocation) {
        let addedAllocation = allocations.find(function (allocationFromList, index, array) {
            if (allocationFromList.Contractor__c == allocation.Contractor__c && allocationFromList.Project__c == allocation.Project__c){
                array[index] = allocation;
                return true;
            } else {
                return false;
            }
        });

        return addedAllocation;
    },

    sendApproveRequiredToParent : function (component, contractorId, approveRequired, isInit, allIsValid) {
        let event = component.getEvent("sendApproveRequiredToParent");
        let approveRequiredForContractorObject = this.constructObjectForSendApproveRequiredToParentEvent(approveRequired, contractorId);

        event.setParams({
            "approveRequiredForContractor" : approveRequiredForContractorObject,
            "isInit" : isInit,
            "allIsValid" : allIsValid
        });

        event.fire();
    },

    constructObjectForSendApproveRequiredToParentEvent : function (approveRequired, contractorId) {
        let approveRequiredForContractorObject = {};

        approveRequiredForContractorObject.approveRequired = approveRequired;
        approveRequiredForContractorObject.contractor = contractorId;

        return approveRequiredForContractorObject;
    },

    moveAllocationsFromSaveAndApproveListToSaveList : function (component) {
        let allocationsToSaveAndApprove = component.get("v.allocationsToSaveAndApprove");

        component.set("v.allocationsToSave", allocationsToSaveAndApprove);
        component.set("v.allocationsToSaveAndApprove", []);
    },

    showToast : function (title, type, message) {
        let toastEvent = $A.get("e.force:showToast");

        if (toastEvent){
            toastEvent.setParams({
                "title": title,
                "message": message == null ? 'Unexpected error' : message,
                "type" : type,
                "mode" : type === 'error' ? 'sticky' : 'dismissible'
            });
            toastEvent.fire();
        }
    },

    refreshListsForApproveAndSave : function (component) {
        let emptyList = [];

        component.set("v.allocationsToSaveAndApprove", emptyList);
        component.set("v.allocationsToSave", emptyList);
    }

});