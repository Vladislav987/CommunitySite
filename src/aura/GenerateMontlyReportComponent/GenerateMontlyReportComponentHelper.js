/**
 * Created by Mychailo Hamdzii on 16.04.2019.
 */
({
    init: function(component) {
        component.set("v.isLoading", true);
        let self = this;
        let action = component.get("c.getInitData");

        action.setParams({
            recordId : component.get("v.recordId")
        });
        let closeModal = false;

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === "SUCCESS") {
                let modalInfo = response.getReturnValue();

                let months = modalInfo.months.map((item, index) => {
                    let monthInList = {};
                    monthInList.label = item;
                    //+ 1 due to Salesforce month number system, where Jan is 1
                    monthInList.value = (index + 1).toString();
                    return monthInList;
                });

                let years = modalInfo.years.map(item => {
                    let yearInList = {};
                    yearInList.label = item;
                    yearInList.value = item;
                    return yearInList;
                });

                component.set("v.months", months);
                component.set("v.years", years);
            }  else if (state === "ERROR") {
                self.showNotif(
                    component,
                    false,
                    "Error",
                    action.getError()[0].message,
                    "error"
                );

                closeModal = true;
            }

            component.set("v.isLoading", false);
            if (closeModal) {
                component.find("overlayLib").notifyClose();
            }
        });

        $A.enqueueAction(action);
    },

    generateReport: function(component, months, years) {
        component.set("v.isLoading", true);
        let action = component.get("c.tryToGenerateReport");

        action.setParams({
            recordId: component.get("v.recordId"),
            months: months,
            years: years
        });

        let self = this;
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === "SUCCESS") {
                let result = response.getReturnValue();

                if (result.isSuccessful) {
                    self.showNotif(
                        component,
                        true,
                        'Success',
                        result.message,
                        'success'
                    );

                    component.find("overlayLib").notifyClose();
                } else {
                    self.showNotif(
                        component,
                        false,
                        'Error',
                        result.message,
                        'error'
                    )
                }
                component.set("v.isLoading", false);
            }
        });

        $A.enqueueAction(action);
    },

    showNotif: function(component, isToast, title, message, variant) {
        let lib = component.find("notifLib");
        debugger;
        if (isToast) {
            lib.showToast({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable'
            });
        } else {
            lib.showToast({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable'
            });
        }
    },
})