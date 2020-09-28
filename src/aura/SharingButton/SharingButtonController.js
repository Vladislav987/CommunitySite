/**
 * Created by ArtemShevchenko on 15.11.2019.
 */

({
    doInit: function (component, event, helper) {
        component.set("v.currentUserId", $A.get("$SObjectType.CurrentUser.Id"));
        component.set("v.currentRecordId", component.get("v.recordId"));
        let getEntitiesNames = component.get("c.getEntitiesNamesForSharing");
        getEntitiesNames.setParams({'entityType': 'Users'});
        getEntitiesNames.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS') {
                let entitiesNames = response.getReturnValue();
                let options = Object.keys(entitiesNames).map((key) => {
                    return {label: entitiesNames[key], value: entitiesNames[key]}
                });
                component.set("v.options", options);
            }
        });
        $A.enqueueAction(getEntitiesNames);

    },

    changeData: function (component, event, helper) {
        component.set("v.entityType", event.getSource().get("v.value"));
        let changeEntities = component.get("c.getEntitiesNamesForSharing");
        changeEntities.setParams({'entityType': event.getSource().get("v.value")});
        changeEntities.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS') {
                let entitiesNames = response.getReturnValue();
                let options = Object.keys(entitiesNames).map((key) => {
                    return {label: entitiesNames[key], value: entitiesNames[key]}
                });
                component.set("v.options", options);
            }
        });
        $A.enqueueAction(changeEntities);
    },

    handleDualListBoxChange: function (component, event, helper) {
        let selectedOptionValue = event.getParam("value");
        component.set("v.selectedEntities", selectedOptionValue);
    },
    shareRecord: function (component, event, helper) {
        if(component.get("v.selectedEntities").length === 0){
            helper.createToast(component, 'Sorry', 'error', 'You did not select any ' + component.get("v.entityType"));
            return;
        }
        let shareMethod = component.get("c.shareWithEntities");
        shareMethod.setParams({
            'entitiesNames': component.get("v.selectedEntities"),
            'entityType': component.get("v.entityType"),
            'recordId': component.get("v.currentRecordId"),
            'accessLevel': component.get("v.accessLevel")
        });
        shareMethod.setCallback(this, function (response) {
            console.log(response.getState());
            if (response.getState() === 'SUCCESS') {
                let selectedEntities = component.get("v.selectedEntities");
                component.set("v.selectedEntities", []);
                let newOptions = component.get("v.options");
                for (let selOption of selectedEntities){
                    newOptions = newOptions.filter(option => option.value !== selOption);
                }
                component.set("v.options", newOptions);
                helper.createToast(component, 'Success', 'success', 'The record has been shared successfully');
            } else {
                helper.createToast(component, 'Sorry', 'error', 'Something went wrong, please contact your administrator');
            }
        });
        $A.enqueueAction(shareMethod);
    },
    changeAccessLevel: function (component, event, helper) {
        component.set("v.accessLevel",event.getSource().get("v.value"));
    }
});