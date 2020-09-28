/**
 * Created by ArtemShevchenko on 11.11.2019.
 */

({
    doInit: function (component, event, helper) {
        helper.fetchNewData(component, event, component.get("v.ObjectName"));

    },
    changeData: function (component, event, helper) {
        let option = event.getSource().get("v.value");
        component.set("v.ObjectName", option);
        helper.fetchNewData(component, event, option);

    },
    approve: function (component, event, helper) {
        if (helper.checkForEmptySelectedRows(component, event, helper)) {
            let selectedRecords = component.find('dataTable').getSelectedRows();
            let approveMethod = component.get("c.approveByTargetId");
            component.set("v.showSpinner", true);
            approveMethod.setParams({'recordsForApprove': selectedRecords});
            approveMethod.setCallback(this, function (response) {
                if (response.getState() === 'SUCCESS') {
                    if (!response.getReturnValue().isSuccessful) {

                        helper.createToast(component, event, 'Warning', 'warning', response.getReturnValue().message);
                    } else {

                        let records = component.get("v.data");
                        let newRecords = [];
                        component.set("v.data", newRecords);
                        for (let selectedRecord of selectedRecords) {
                            records = records.filter(record => record.Id !== selectedRecord.Id);
                        }
                        component.set("v.data", records);
                        if (component.get("v.data").length === 0) {
                            component.set("v.hasRecords", false);
                        }
                        helper.createToast(component, event, 'Success', 'success', 'Records approved successfully');
                    }
                }
                component.set("v.showSpinner", false);
            });
            $A.enqueueAction(approveMethod);
        }
    },
    reject: function (component, event, helper) {
        if (helper.checkForEmptySelectedRows(component, event, helper)) {
            let selectedRecords = component.find('dataTable').getSelectedRows();
            let rejectMethod = component.get("c.rejectByTargetId");
            component.set("v.showSpinner", true);
            rejectMethod.setParams({'recordsForReject': selectedRecords});
            rejectMethod.setCallback(this, function (response) {
                if (response.getState() === 'SUCCESS') {
                    let records = component.get("v.data");
                    let newRecords = [];
                    component.set("v.data", newRecords);
                    for (let selectedRecord of selectedRecords) {
                        records = records.filter(record => record.Id !== selectedRecord.Id);
                    }
                    component.set("v.data", records);
                    if (component.get("v.data").length === 0) {
                        component.set("v.hasRecords", false);
                    }
                    helper.createToast(component, event, 'Success', 'success', 'Records rejected successfully');
                }
                component.set("v.showSpinner", false);
            });
            $A.enqueueAction(rejectMethod);
        }
    },
    handleRowAction: function (component, event, helper) {
        const actionName = event.getParam('action').name;
        let record = event.getParam('row');
        if (actionName === 'view') {
            let navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": record.Id,
                "slideDevName": "related"
            });
            navEvt.fire();
        } else if (actionName === 'edit') {
            let editRecordEvent = $A.get("e.force:editRecord");
            editRecordEvent.setParams({
                "recordId": record.Id
            });
            editRecordEvent.fire();
        } else if (actionName === 'request') {
            let getRequestId = component.get("c.getApproveRequestId");
            getRequestId.setParams({'recordId': record.Id});
            getRequestId.setCallback(this, function (response) {
                if (response.getState() === 'SUCCESS') {
                    let navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": response.getReturnValue(),
                        "slideDevName": "related"
                    });
                    navEvt.fire();
                }
            });
            $A.enqueueAction(getRequestId);
        }
    }
});