({
    doInit: function (cmp, event, helper) {
            helper.getCurrencyValues(cmp, helper);

             let idleTimer;
             let idleInterval;

            function resetTimer() {
                clearTimeout(idleTimer);
                clearInterval(idleInterval);

                if (cmp.get("v.budgetHierarchyItemList").length != 0) {
                    idleTimer = setTimeout(doAutoSave, 5 * 1000);
                }
            }

            document.addEventListener('mousemove', resetTimer);
            resetTimer();

            function doAutoSave() {
                idleInterval = setInterval(helper.callAutoSave(cmp, event, helper));
            }

    },


    handleAccessForYear: function (cmp, event, helper) {
        cmp.set("v.readOnlyAccess", event.getParam("readOnlyAccess"));

    },

    shareButton: function (cmp, event, helper) {
        let action = cmp.get('c.updateSelectedCostCenter');
        action.setParams({finItemsForUpdate: JSON.stringify(cmp.get("v.finItemsForUpdate"))});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                helper.shareButtonHelper(cmp);
            }
        });
        $A.enqueueAction(action);

    },

    handleUpdateHeaderWrapperEvent: function (cmp, event, helper) {
        cmp.set("v.headerWrapper", event.getParam("headerWrapper"));
        helper.saveAction(cmp,false,true);
        helper.loadCustomMetadata(cmp);
        helper.iniMonths(cmp);
    },

    handleUpdateCurrencyEvent: function (cmp, event) {
        let action = cmp.get('c.updateSelectedCostCenter');
        action.setParams({finItemsForUpdate: JSON.stringify(event.getParam("finItemsForUpdate"))});
        action.setCallback(this, function (response) {

        });
        $A.enqueueAction(action);
    },

    generateButton: function (cmp, event, helper) {
        let action = cmp.get('c.updateSelectedCostCenter');
        action.setParams({finItemsForUpdate: JSON.stringify(cmp.get("v.finItemsForUpdate"))});
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                helper.generateValidationAction(cmp);
            }
        });
        $A.enqueueAction(action);

    },

    shareCostCenterPopUp: function (cmp, event, helper) {
        if (cmp.get('v.currentForm') == 'Global planning') {
            helper.shareCostCenter(cmp);
        } else {
            helper.generateAction(cmp);
        }

    },

    saveButton: function (cmp, event, helper) {
        helper.saveAction(cmp, false,false);
    },

    deleteButton: function (cmp, event, helper) {
        helper.deleteButtonHelper(cmp);
    },

    deleteDraftAction: function (cmp) {
        cmp.set("v.showSpinner", false);
        var deleteAction;
        var currentItem = cmp.get("v.budgetHierarchyItemList");
        if(cmp.get('v.currentForm') == 'Cost Centers Planning') {
            deleteAction = 'c.deleteActionCostCenter';
        } else {
            deleteAction = 'c.deleteActionGlobal';
        };
        let action = cmp.get(deleteAction);
        if (deleteAction == 'c.deleteActionCostCenter') {
            action.setParams({
                costCenterId: cmp.get('v.headerWrapper').selectedBusinessUnit,
                maxVersion: cmp.get('v.maxVersion')
            });
        } else {
            action.setParams({
                costCenterId: cmp.get('v.headerWrapper').selectedBusinessUnit,
                availableVersions: cmp.get("v.headerWrapper.versionsList")
            });
        }
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                var childCmp = cmp.find("headerComponent");
                childCmp.updateVersion();
            }
        });
        cmp.set("v.showDeleteConfirmPopUp", false);
        $A.enqueueAction(action);
    },

    editButtonAction: function (cmp, event, helper) {
        helper.editAction(cmp, event, helper);
    },


    openForm: function (cmp) {
        document.getElementById("chatForm").style.display = "block";
        document.getElementById("chatterIcon").style.display = "none";
    }
});