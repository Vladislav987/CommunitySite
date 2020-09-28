({
    doInit: function (cmp, event, helper) {
        helper.loadInitDate(cmp);
    },

    updateVersion: function (cmp,event,helper) {
        helper.getAvailableVersion(cmp,event,cmp.get("v.headerWrapper").selectedBusinessUnit);
    },

    handleClick: function (cmp, event, helper) {
        cmp.set("v.showSpinner",false);
        let button = event.getSource();
        let buttonValue = button.get("v.label");
        if (buttonValue == 'Cost Centers Planning') {
            button.set('v.disabled', true);
            cmp.find("Global planning").set('v.disabled', false);
            cmp.set("v.changeGlobalStatus", false);
            cmp.set("v.currentForm", buttonValue);
            cmp.set("v.isShareActionDone", true);
            helper.loadInitDate(cmp);
            let appEvent = $A.get("e.c:accessForYear");
            appEvent.setParams({ "readOnlyAccess" : false });
            appEvent.fire();
        }
        if (buttonValue == 'Global planning') {
            button.set('v.disabled', true);
            cmp.find("Cost Centers Planning").set('v.disabled', false);
            cmp.set("v.changeGlobalStatus", true);
            cmp.set("v.currentForm", buttonValue);
            helper.loadInitDate(cmp);
            let appEvent = $A.get("e.c:accessForYear");
            appEvent.setParams({ "readOnlyAccess" : false });
            appEvent.fire();
        }
    },

    getSelectedOption: function (cmp, event, helper) {
        var selectedValue = event.getSource();
        if (selectedValue.get("v.name") == "version") {
            cmp.set("v.headerWrapper.selectedVersion",selectedValue.get("v.value"));
            if (selectedValue.get("v.value") == 'Shared' || selectedValue.get("v.value").includes('Generated')) {
                helper.isSharedVersion(cmp,event,true);
            } else {
                helper.isSharedVersion(cmp, event, false);
            }
            helper.fireHeaderWrapperEvent(cmp);
        }

        if (selectedValue.get("v.name") == "year") {
            cmp.set("v.headerWrapper.selectedYear", selectedValue.get("v.value"));
            let action = cmp.get('c.getHeaderWrapper');
            action.setParams({ "currentForm" : cmp.get("v.currentForm")});
            action.setParams({ "year" :  selectedValue.get("v.value")});
            ///
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
            ///
            helper.checkYear(cmp);

        }

        if (selectedValue.get("v.name") == "businessUnit") {
            cmp.set("v.showSpinner",false);
            helper.getAvailableVersion(cmp, event, selectedValue.get("v.value"));
            cmp.set("v.headerWrapper.selectedBusinessUnit", selectedValue.get("v.value"));
            cmp.set("v.headerWrapper.currentBusinessUnit", selectedValue.get("v.value"));
            helper.fireCostCostCenterChangeEvent(cmp, helper);
        }
    }
});