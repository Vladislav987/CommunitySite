/**
 * Created by MaxymMirona on 28.01.2020.
 */

({
    onInit : function (component, event) {
        component.set("v.isLoading", true);
        let action = component.get("c.getMatrixAllocationAndContractorsInitData");

        action.setParams({
            projectId : component.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let MatrixInfo = response.getReturnValue();

                let types = MatrixInfo.types.map((item, index) => {
                    let typeInList = {};
                    typeInList.label = item;
                    typeInList.value = (index).toString();
                    return typeInList;
                });
                component.set("v.types", types);
                component.set("v.selectedType", types[0].label);

                let matrixData = MatrixInfo.matrixData;
                let contractorsIdToNameOfAllAllocations = matrixData.contractorsIdToNameOfAllAllocations;
                if (Object.keys(contractorsIdToNameOfAllAllocations).length != 0) {
                    let contractors = Object.keys(matrixData.contractorsIdToNameOfAllAllocations).map(function (key) {
                        return {
                            Id: key,
                            Name: matrixData.contractorsIdToNameOfAllAllocations[key]
                        }
                    });

                    component.set("v.contractors", contractors);
                    component.set("v.selectedContractorId", contractors[0].Id);

                    this.initializeMatrix(component, matrixData);
                }

                component.set("v.isLoading", false);
            }  else if (state === "ERROR") {
                if (action.getError().length > 0) {
                    if (action.getError()[0] != null) {
                        console.log(action.getError());
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },

    initializeMatrix : function (component, matrixData) {
        let parentProject = matrixData.parentProject;
        let childProjects = matrixData.childProjectsList;
        let allocationsByProjectIds = matrixData.allocationsByProjectIds;
        let selectedContractorId = component.get("v.selectedContractorId");
        let filteredAllocations = [];
        let allocationsToIterateMap = new Map();
        let allocationsByContractorIds = new Map();
        let allocationsToIterate = [];

        allocationsByProjectIds = Object.keys(allocationsByProjectIds).map(function (key) {
            let today = new Date();

            allocationsByProjectIds[key].forEach(allocation => {
                let allocationStartDate = new Date(allocation.Start_date__c);
                let allocationEndDate = new Date(allocation.End_date__c);

                if (allocationStartDate <= today && allocationEndDate >= today) {
                    if (allocationsByContractorIds.has(allocation.Contractor__c)) {
                        allocationsByContractorIds.get(allocation.Contractor__c).push(allocation);
                    } else {
                        allocationsByContractorIds.set(allocation.Contractor__c, [allocation]);
                    }
                }
            });
        });

        allocationsByContractorIds.forEach((allocations, contractorId, map) => {
            if (contractorId == selectedContractorId) {
                filteredAllocations = allocations;
            }
        })

        filteredAllocations.forEach(allocation => {
            let keyString = allocation.Resource_Type__c + allocation.Expected_Rate__c + allocation.CurrencyIsoCode;

            if (allocationsToIterateMap.has(keyString)) {
                allocationsToIterateMap.get(keyString).push(allocation);
            } else {
                allocationsToIterateMap.set(keyString, [allocation]);
            }
        });

        allocationsToIterateMap.forEach((allocations, keyString, map) => {
            allocationsToIterate.push(allocations);
        });

        component.set("v.allocationsByContractorIds", allocationsByContractorIds);
        component.set("v.childProjects", childProjects);
        component.set("v.parentProject", parentProject);
        component.set("v.filteredAllocations", filteredAllocations);
        component.set("v.allocationsToIterate", allocationsToIterate);
    },

    doHandleSendApproveRequiredToParent : function (component, event) {
        let approveRequired = event.getParam("approveRequiredForContractor").approveRequired;
        let contractor = event.getParam("approveRequiredForContractor").contractor;
        let isInit = event.getParam("isInit");
        let allIsValid = event.getParam("allIsValid");
        let approveList = component.get("v.approveRequiredList");
        let contractors = component.get("v.contractors");
        let needToShowSaveAndApproveAllButton = false;

        if (allIsValid) {
            if (isInit) {
                if (approveList.length == contractors.length) {
                    approveList = [];
                }
                approveList.push({
                    "approveRequired": approveRequired,
                    "contractor": contractor
                });

            } else {
                approveList.forEach(function (item) {
                    if (item.contractor == contractor) {
                        item.approveRequired = approveRequired
                    }
                });

                let hasItemsThatRequireApprove = approveList.length == 1 ? approveList[0].approveRequired : approveList.reduce(function (initialValue, currentItem) {
                    return initialValue.approveRequired == undefined ? (initialValue || currentItem.approveRequired) : (initialValue.approveRequired || currentItem.approveRequired);
                });

                needToShowSaveAndApproveAllButton = true;
                component.set("v.approveRequired", hasItemsThatRequireApprove);
            }
            component.set("v.approveRequiredList", approveList);
            component.set("v.showSaveButton", needToShowSaveAndApproveAllButton);
            component.set("v.allIsValid", true);
        } else {
            component.set("v.allIsValid", allIsValid);
            component.set("v.showSaveButton", true);
        }
    },

    onSave : function (component, event) {
        component.set("v.isLoading", true);
        let saveAction = component.get("c.upsertAllocationsBaseOnRandomAllocation");
        let childComponents = component.find("MatrixRowComponent");
        let emptyAllocationsToUpsertObject = null;
        let allocations = this.formListFromChildComponent(childComponents, false);

        if (allocations.length == 0){
            this.OnInitMatrixOnly(component);
            this.showToast("Error", "warning", 'There is nothing to Save');
            component.set("v.isLoading", false);
            return;
        }

        saveAction.setParams({
            allocations : allocations
        });

        saveAction.setCallback(this, function (response) {
            let state = response.getState();
            let responseMessage = response.getReturnValue();

            if (state === "SUCCESS") {
                if (responseMessage === 'Success') {
                    this.OnInitMatrixOnly(component);
                    this.refreshChildComponentsLists(childComponents);
                    this.showToast("Success!", "success", "Allocations has been saved");
                    component.set("v.allocationsByParentProjectAllocationForSave", emptyAllocationsToUpsertObject);
                } else {
                    this.refreshChildComponentsLists(childComponents);
                    this.showToast("Error", "error", responseMessage);
                    this.OnInitMatrixOnly(component);
                }
            } else if (state === "ERROR") {
                this.refreshChildComponentsLists(childComponents);
                this.OnInitMatrixOnly(component);
                this.showToast("Error", "error", responseMessage);
            }
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(saveAction);
    },

    onApproveAll : function (component, event) {
        component.set("v.isLoading", true);
        let saveAction = component.get("c.upsertAndApproveAllocations");
        let childComponents = component.find("MatrixRowComponent");
        let allocations = this.formListFromChildComponent(childComponents, true);

        if (allocations.length == 0){
            this.OnInitMatrixOnly(component);
            this.showToast("Error", "warning", 'There is nothing to Approve');
            component.set("v.isLoading", false);
            return;
        }

        saveAction.setParams({
            allocations : allocations
        });

        saveAction.setCallback(this, function (response) {
            let state = response.getState();
            let responseMessage = response.getReturnValue();

            if (state === "SUCCESS") {
                if (responseMessage === 'Success') {
                    this.OnInitMatrixOnly(component);
                    this.showToast("Success!", "success", "Allocations has been sent for approve");
                } else {
                    this.showToast("Error", "error", responseMessage);
                    this.OnInitMatrixOnly(component);
                    this.refreshChildComponentsLists(childComponents);
                }
            } else if (state === "ERROR") {
                this.showToast("Error", "error", responseMessage);
                this.OnInitMatrixOnly(component);
                this.refreshChildComponentsLists(childComponents);
            }
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(saveAction);
    },

    formListFromChildComponent : function(childComponents, approveRequired){
        let allocations = [];
        let neededListName;
        let self = this;

        if (!approveRequired){
            neededListName = "v.allocationsToSave";
        } else {
            neededListName = "v.allocationsToSaveAndApprove";
        }

        if (Array.isArray(childComponents)) {
            childComponents.forEach(function (childComponent) {
                self.formListForChildComponentItem(childComponent, neededListName, allocations, approveRequired);
            });
        } else {
            self.formListForChildComponentItem(childComponents, neededListName, allocations, approveRequired);
        }

        return allocations;
    },

    formListForChildComponentItem : function(childComponent, neededListName, allocations, approveRequired){
        let allocationsList = childComponent.get(neededListName);
        if (allocationsList.length != 0) {
            allocationsList.forEach(allocation => {
                if (!approveRequired) {
                    if (allocation.New_Allocation__c != undefined || allocation.New_Allocation__c != null) {
                        allocation.Allocation__c = allocation.New_Allocation__c;
                        allocation.New_Allocation__c = null;
                    }
                }
                allocations.push(allocation);
            });
        }
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

    OnInitMatrixOnly : function (component, event) {
        let self = this;
        component.set("v.isLoading", true);

        let action = component.get("c.getMatrixAllocationAndContractorsInitData");

        action.setParams({
            projectId: component.get("v.recordId")
        });

        action.setCallback(self, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let matrixData = response.getReturnValue().matrixData;
                this.initializeMatrix(component, matrixData);
            } else if (state === "ERROR") {
                console.log(action.getError()[0].message);
            }

            component.set("v.isLoading", false);
        });

        $A.enqueueAction(action);
    },

    refreshChildComponentsLists : function (childComponents) {
        let allocationsToSaveListName = "v.allocationsToSave";
        let allocationsToSaveAndApproveListName = "v.allocationsToSaveAndApprove";

        childComponents.forEach(function (childComponent) {
            childComponent.set(allocationsToSaveListName, []);
            childComponent.set(allocationsToSaveAndApproveListName, []);
        });
    }
});