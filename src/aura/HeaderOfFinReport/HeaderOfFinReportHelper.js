({

    loadInitDate: function (cmp,helper) {
        // We need to set a flow if we have only one button
        let getTabAccess = cmp.get('c.getIsUserHasAccessToTab');
        getTabAccess.setParams({ "tabName" : "BudgetPlanning Global"});
        getTabAccess.setCallback(this, function(response){
            if(response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                if(result == false) {
                    cmp.set("v.currentForm", 'Cost Centers Planning');
                    let costButton = cmp.find("Cost Centers Planning");
                    costButton.set('v.disabled', true);
                }
                if (cmp.get("v.currentForm") == 'Global planning') {
                    this.pendingUI(cmp);
                }
                this.loadAfterSelectionTab(cmp);
            }
        });
        $A.enqueueAction(getTabAccess);
    },

    loadAfterSelectionTab: function (cmp) {
        let action = cmp.get('c.getHeaderWrapper');
        let currentForm = cmp.get("v.currentForm");

        action.setParams({ "currentForm" : cmp.get("v.currentForm")});
        action.setCallback(this, function(response){
            if(response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                let appEvent = $A.get("e.c:updateHeaderWrapperEvent");
                appEvent.setParams({ "headerWrapper" : result});
                appEvent.fire();
                window.setTimeout(
                    $A.getCallback( function() {
                        var versionList = result.versionsList;
                        var maxGenerated = null;
                        for (var i = 0; i < versionList.length;i++) {
                            if (versionList[i].includes('Generated')) {
                                if (maxGenerated == null) {
                                    maxGenerated = versionList[i];
                                } else if (maxGenerated < versionList[i]) {
                                    maxGenerated = versionList[i];
                                }
                            }
                        }
                        cmp.set("v.maxVersion",maxGenerated);
                        cmp.find("year").set("v.value", result.yearsList[1]);
                        cmp.find("version").set("v.value", result.selectedVersion);
                        if (currentForm == 'Cost Centers Planning')  {
                            if (versionList.length == 1 && versionList[0] == 'Draft') {
                                let appEvent = $A.get("e.c:accessForYear");
                                appEvent.setParams({ "readOnlyAccess" : false });
                                appEvent.fire();
                            }
                        }
                        if (result.selectedVersion == 'Shared' || result.selectedVersion.includes('Generated')) {
                            let appEvent = $A.get("e.c:accessForYear");
                            appEvent.setParams({ "readOnlyAccess" : true });
                            appEvent.fire();
                        }
                        cmp.find("businessUnit").set("v.value", result.selectedBusinessUnit);
                        cmp.set("v.currentBusinessUnit", result.selectedBusinessUnit);
                        let costCenterChanged = $A.get("e.c:getCostCenterId");
                        costCenterChanged.setParams({ "costCenterId" :  cmp.get("v.headerWrapper.selectedBusinessUnit")});
                        costCenterChanged.fire();
                    }));
                cmp.set('v.headerWrapper', result);
            }
        });
        $A.enqueueAction(action);
    },

    fireHeaderWrapperEvent: function (cmp) {
        let appEvent = $A.get("e.c:updateHeaderWrapperEvent");
        appEvent.setParams({ "headerWrapper" : cmp.get("v.headerWrapper")});
        appEvent.fire();
    },

    fireCostCostCenterChangeEvent: function (cmp, helper) {
        let costCenterChanged = $A.get("e.c:getCostCenterId");
        costCenterChanged.setParams({ "costCenterId" :  cmp.get("v.headerWrapper.selectedBusinessUnit")});
        costCenterChanged.fire();
    },

    checkYear: function (cmp) {
        let setParam = false;
        if (cmp.get('v.headerWrapper').selectedYear < cmp.get('v.headerWrapper').yearsList[1]) {
            setParam = true;
        }
        let appEvent = $A.get("e.c:accessForYear");
        appEvent.setParams({ "readOnlyAccess" : setParam });
        appEvent.fire();
    },


    getAvailableVersion:function (cmp,event,selectedBU) {
        let action = cmp.get('c.getVersion');
        let currentForm = cmp.get("v.currentForm");
        action.setParams({ "businessUnitId" : selectedBU,"currentForm":currentForm});
        action.setCallback(this, function(response){
            if(response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                let maxGenerated = null;
                cmp.set("v.headerWrapper.selectedBusinessUnit", selectedBU);
                cmp.set("v.headerWrapper.versionsList", result);
                cmp.set("v.headerWrapper.selectedVersion", result[0]);
                for (var i = 0; i < result.length;i++) {
                    if (result[i].includes('Generated')) {
                        if (maxGenerated == null) {
                            maxGenerated = result[i];
                        } else if (maxGenerated < result[i]) {
                            maxGenerated = result[i];
                        }
                    }
                }
                cmp.set("v.maxVersion",maxGenerated);
                if (result[0] == 'Shared' || result[0].includes('Generated')) {
                    this.isSharedVersion(cmp,event,true);
                } else {
                    this.isSharedVersion(cmp,event,false);
                }
                this.fireHeaderWrapperEvent(cmp);
                window.setTimeout(
                    $A.getCallback( function() {
                        cmp.find("version").set("v.value", result[0]);
                    }));
            }
        });

        $A.enqueueAction(action);
    },

    isSharedVersion : function(cmp,event,access) {
        let appEvent = $A.get("e.c:accessForYear");
        appEvent.setParams({ "readOnlyAccess" : access });
        appEvent.fire();
    },

    sendCurrentCostCenterId : function(cmp) {
        let costCenterChanged = $A.get("e.c:getCostCenterId");
        costCenterChanged.setParams({ "costCenterId" :  cmp.get("v.headerWrapper.selectedBusinessUnit")});
        costCenterChanged.fire();
    },

    getAvailableYear:function (cmp,selectedBU) {
        let action = cmp.get('c.getListOfYear');
        action.setParams({ "businessUnitId" : selectedBU});
        action.setCallback(this, function(response){
            if(response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                cmp.set("v.headerWrapper.selectedYear",new Date().getFullYear());
                cmp.set("v.headerWrapper.yearsList",result);
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
});