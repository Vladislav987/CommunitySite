/**
 * Created by MaxymMirona on 24.12.2019.
 */

({
    doInit : function(component, event){

        let action = component.get("c.getDatedConversionRatesToInsert");

        action.setParams({
            records : component.get("v.records")
        });

        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let newExchangeRates = response.getReturnValue();
                component.set("v.newExchangeRates", newExchangeRates);
                component.set("v.isLoading", false);
            }
        });

        $A.enqueueAction(action);
    },

    doHandleSubmit : function (component, event) {
        component.set("v.isLoading", true);
        let action = component.get("c.upsertDatedConversionRate");
        let toastMessage = "Exchange Rates have been created successfully.";
        let newExchangeRates = component.get("v.newExchangeRates");
        let startDate = component.get("v.startDate");
        let createNewExchangeRatesEvent = $A.get("e.c:DatedConversionRateCreateNewEvent");

        newExchangeRates.forEach(exchangeRate => exchangeRate.StartDate = startDate);

        action.setParams({
            recordsList: component.get("v.newExchangeRates"),
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
                    createNewExchangeRatesEvent.fire();
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
    },

    onCheckStartDateForValidity : function (component, event) {
        let startDate = component.find("StartDate");
        let startDateValue = component.find("StartDate").get("v.value");
        let blockedStartDates = component.get("v.blockedStartDates");

        if (blockedStartDates.includes(startDateValue)){
            startDate.setCustomValidity("This date has already being used. Please, specify different Start Date")
        } else {
            startDate.setCustomValidity("");
        }
    },

    onCheckRatesForValidity : function (component, event) {
        let rates = component.find("Rate");
        rates.forEach(function (rate){
            let rateValue = rate.get("v.value");
            if (rateValue < 0){
                rate.setCustomValidity("Rate cannot be negative");
            }
            else {
                rate.setCustomValidity("");
            }
        });
    }
});