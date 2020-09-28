/**
 * Created by MaxymMirona on 18.12.2019.
 */

({
    doInit : function (component, event){
        let action = component.get("c.getOverrunTypes");

        action.setCallback(this, function(response) {
            let state = response.getState();
            if(state === "SUCCESS") {
                component.set("v.overrunTypes", response.getReturnValue());
                component.set("v.isLoading", false);
            }  else if (state === "ERROR") {
                console.log(action.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },

    doHandleClick : function (component, event) {
        component.set("v.isLoading", true);
        let action = component.get("c.createNullableAllocation");
        let toastMessage = "The record has been created successfully.";
        let newAllocationEvent = $A.get("e.c:AllocationRelatedListNewAllocationEvent");

        action.setParams({
            projectId: component.get("v.projectId"),
            allocation: component.get("v.allocation"),
            allocationType: component.get("v.allocationType"),
            overrunType : component.get("v.selectedOverrunType")
        });

        action.setCallback(this, function(response) {
            let state = response.getState();

            if(state === "SUCCESS") {

                let result = response.getReturnValue();
                if (result === "Success"){
                    component.find('notifLib').showToast({
                        "title": result,
                        "message": toastMessage,
                        "variant": "success"
                    });
                    component.find("overlayLib").notifyClose();
                    newAllocationEvent.fire();
                } else {
                    component.find('notifLib').showToast({
                        "title": "Error",
                        "message": result,
                        "variant": "error"
                    });
                    component.set("v.isLoading", false);
                }
            }  else if (state === "ERROR") {
                console.log(action.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    }
});