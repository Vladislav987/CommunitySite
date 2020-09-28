/**
 * Created by ArtemShevchenko on 08.11.2019.
 */

({
    doInit: function (component, event, helper) {
        let getRecords = component.get("c.getRecordsForApprove");
        getRecords.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS') {
                component.set("v.itemsForApprove", response.getReturnValue());
                if (response.getReturnValue().length > 0) {
                    component.set("v.hasRecord", true);
                }
            }
        });
        $A.enqueueAction(getRecords);
    },
    updateSelectedRecordsList: function (component, event, helper) {
        let record = event.getParam("selectedRecord");
        let selectedRecords = component.get("v.selectedRecords");
        if (selectedRecords.length === 0) {
            selectedRecords.push(record);
            component.set("v.selectedRecords", selectedRecords);
        } else {
            let addRecordsToList = true;
            for (let selectedRecord of selectedRecords) {
                if (selectedRecord.Id === record.Id) {
                    component.set("v.selectedRecords", selectedRecords.filter(r => r.Id !== record.Id));
                    addRecordsToList = false;
                }
            }
            if (addRecordsToList) {
                selectedRecords.push(record);
                component.set("v.selectedRecords", selectedRecords);
            }
        }
    },
    approve: function (component, event, helper) {
        let selected = component.get("v.selectedRecords");
        if (selected.length === 0) {
            helper.createToast(component, event, 'Sorry', 'error', 'You did not select any records for Approve');
        } else {
            let approveMethod = component.get("c.approveByTargetId");
            approveMethod.setParams({
                'recordsForApprove': selected
            });
            approveMethod.setCallback(this, function (response) {
                if (response.getState() === 'SUCCESS') {
                    helper.createToast(component, event, 'Success', 'success', 'Records approved successfully');
                    for(let record of selected){
                        component.set("v.itemsForApprove", component.get("v.itemsForApprove").filter(f => f.Id !== record.Id));
                    }
                    if(component.get("v.itemsForApprove").length === 0){
                        component.set("v.hasRecord", false);
                    }
                } else {
                    //response.getError()[0].pageErrors[0].message
                    if (response.getError()) {
                        if (response.getError()[0].pageErrors) {
                            helper.createToast(component, event, 'Error', 'error', response.getError()[0].pageErrors[0].message);
                        }
                    }
                }
            });
            $A.enqueueAction(approveMethod);
        }

    },

    reject: function (component, event, helper) {
        let selected = component.get("v.selectedRecords");
        if (selected.length === 0) {
            helper.createToast(component, event, 'Sorry', 'error', 'You did not select any records for Reject');
        } else {
            let rejectMethod = component.get("c.rejectByTargetId");
            rejectMethod.setParams({
                'recordsForReject': selected
            });
            rejectMethod.setCallback(this, function (response) {
                console.log(response.getState());
                if (response.getState() === 'SUCCESS') {
                    helper.createToast(component, event, 'Success', 'success', 'Records rejected successfully');
                    for(let record of selected){
                        component.set("v.itemsForApprove", component.get("v.itemsForApprove").filter(f => f.Id !== record.Id));
                    }
                    if(component.get("v.itemsForApprove").length === 0){
                        component.set("v.hasRecord", false);
                    }
                }
            });
            $A.enqueueAction(rejectMethod);
        }
    },
    navigateToRecords: function (component, event, helper) {
            let urlEvent = $A.get("e.force:navigateToComponent");
        urlEvent.setParams({
            componentDef : "c:ApproveRequest"
        });
        urlEvent.fire();

    }
});