({
    loadCustomMetadata: function (cmp) {
        cmp.set('v.showSpinner', false);
        let action = cmp.get('c.setCurrentFlow');
        let version = cmp.get("v.headerWrapper").selectedVersion;
        let currentForm = cmp.get("v.currentForm");
        let costCenterId = cmp.get("v.headerWrapper").selectedBusinessUnit;
        let year = cmp.get("v.headerWrapper").selectedYear;
        action.setParams({
            version: version
            , costCenterId: costCenterId
            , year: year
            , currentForm: currentForm
        });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                cmp.set('v.budgetHierarchyItemList', result);
                cmp.set('v.showSpinner', true);
            }
        });

        $A.enqueueAction(action);
    },

    iniMonths: function (cmp) {
        let action = cmp.get('c.getMonths');
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                cmp.set('v.months', result);
            }
        });

        $A.enqueueAction(action);
    },

    shareButtonHelper: function (cmp) {
        cmp.set("v.showSpinner", false);
        let action = cmp.get('c.shareAction');
        let bsList = cmp.get("v.headerWrapper").businessUnitsList;
        cmp.set("v.finItemsForUpdate", []);

        var idBsList = [];
        for (var i = 0; i < bsList.length; i++) {
            idBsList.push(bsList[i].Id);
        }
        action.setParams({businessUnitList: idBsList});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                if (result == null) {
                    cmp.set("v.showSpinner", true);
                    this.showErrorToastEvent();
                } else {
                    this.generateMessageForShare(cmp, result);
                }
            }
        });

        $A.enqueueAction(action);
    },

    generateMessageForShare: function (cmp, businessUnitForShare) {
        let messageForShare = '';
        if (businessUnitForShare.length <= 10) {
            messageForShare = 'Are you sure you want to share data for Cost Centers: (' + businessUnitForShare + ')?'
        } else {
            messageForShare = 'Are you sure you want to share data for ' + businessUnitForShare.length + ' Cost Centers?';
        }
        cmp.set("v.businessUnitForShare", businessUnitForShare);
        cmp.set("v.showSpinner", true);
        cmp.set("v.showPopUp", true);
        cmp.set("v.textOfPopUp", messageForShare);

    },

    generateValidationAction: function (cmp) {
        let action = cmp.get('c.generateValidationAction');
        let bsList = cmp.get("v.headerWrapper").businessUnitsList;
        cmp.set("v.finItemsForUpdate", []);
        var idBsList = [];
        for (var i = 0; i < bsList.length; i++) {
            idBsList.push(bsList[i].Id);
        }
        action.setParams({businessUnitList: idBsList,maxVersionNumber: cmp.get("v.maxVersion")});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                if (result.isPassValidation == false) {
                    this.showErrorForGenerationToastEvent(result.messageFromValidation);
                } else {
                    cmp.set("v.showPopUp", true);
                    cmp.set("v.textOfPopUp", result.messageFromValidation);
                }
            }
        });
        cmp.set("v.showPopUp", false);
        $A.enqueueAction(action);
    },

    showErrorToastEvent: function () {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: 'Error',
            message: 'Fill all Financial Report Items',
            duration: ' 5000',
            key: 'info_alt',
            type: 'error',
            mode: 'dismissible'
        });
        toastEvent.fire();
    },

    showErrorForGenerationToastEvent: function (message) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: 'Error',
            message: message,
            duration: ' 5000',
            key: 'info_alt',
            type: 'error',
            mode: 'dismissible'
        });
        toastEvent.fire();
    },

    showSuccessToastEvent: function () {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: 'Success',
            message: 'Data was successfully saved',
            duration: ' 5000',
            key: 'info_alt',
            type: 'success',
            mode: 'dismissible'
        });
        toastEvent.fire();
    },

    showBatchSuccessToastEvent: function () {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: 'Success',
            message: 'Share cost center is started. You will get an email after update finish',
            duration: ' 5000',
            key: 'info_alt',
            type: 'success',
            mode: 'dismissible'
        });
        toastEvent.fire();
    },

    saveAction: function (cmp, autosave,afterEvent) {
        if (autosave == false) {
            cmp.set("v.showSpinner", false);
        }
        let action = cmp.get('c.updateSelectedCostCenter');
        action.setParams({finItemsForUpdate: JSON.stringify(cmp.get("v.finItemsForUpdate"))});
        action.setCallback(this, function (response) {
            console.log(response.getState());
            if (response.getState() === "SUCCESS") {
                if (autosave == false && afterEvent == false) {
                    cmp.set("v.finItemsForUpdate",[]);
                    cmp.set("v.showSpinner", true);
                    this.showSuccessToastEvent();
                } else {
                    cmp.set("v.finItemsForUpdate",[]);
                    cmp.set("v.showSpinner", true);
                }

            }
        });
        $A.enqueueAction(action);
    },

    deleteButtonHelper: function (cmp) {
        cmp.set("v.showDeleteConfirmPopUp", true);
    },


    generateAction: function (cmp) {
        let action = cmp.get('c.generateAction');
        let bsList = cmp.get("v.headerWrapper").businessUnitsList;

        var idBsList = [];
        for (var i = 0; i < bsList.length; i++) {
            idBsList.push(bsList[i].Id);
        }
        action.setParams({costCenterIds: idBsList, selectedYear: cmp.get("v.headerWrapper").selectedYear});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                var childCmp = cmp.find("headerComponent");
                childCmp.updateVersion();
            }
        });
        cmp.set("v.showPopUp", false);
        $A.enqueueAction(action);
    },


    shareCostCenter: function (cmp) {
        cmp.set("v.showSpinner", false);
        let action = cmp.get('c.shareCostCenter');
        let bsListFromForm = cmp.get("v.headerWrapper").businessUnitsList;
        let bsList = cmp.get("v.businessUnitForShare");
        var idBsList = [];
        for (var i = 0; i < bsListFromForm.length; i++) {
            if (bsList.includes(bsListFromForm[i].Name)) {
                idBsList.push(bsListFromForm[i].Id);
            }

        }
        action.setParams({costCenterIds: idBsList, selectedYear: cmp.get("v.headerWrapper").selectedYear});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                this.showBatchSuccessToastEvent();
                $A.get('e.force:refreshView').fire();
            }
        });
        cmp.set("v.showPopUp", true);

        $A.enqueueAction(action);
    },

    callAutoSave: function (cmp, event, helper) {
        helper.saveAction(cmp, true,false);
    },

    getCurrencyValues: function (cmp, helper) {
        let action = cmp.get('c.getCurrencyValues');
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                cmp.set("v.currencyValues", result);
            }
        });

        $A.enqueueAction(action);
    },

    pendingUI: function (cmp) {
        let action = cmp.get('c.pendingUI');
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                cmp.set("v.isShareActionDone", result);
            }
        });

        $A.enqueueAction(action);
    },

    editAction: function (cmp) {
        cmp.set('v.showSpinner', false);

        var editAction;
        if(cmp.get('v.currentForm') == 'Cost Centers Planning') {
            editAction = 'c.editCostCenterAction';
        } else {
            editAction = 'c.editAction';
        }
        let action = cmp.get(editAction);
        action.setParams({
            selectedYear: cmp.get("v.headerWrapper").selectedYear,
            costCenterId: cmp.get("v.headerWrapper").selectedBusinessUnit
        });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                var childCmp = cmp.find("headerComponent");
                childCmp.updateVersion();
            }
        });

        $A.enqueueAction(action);


    }

});