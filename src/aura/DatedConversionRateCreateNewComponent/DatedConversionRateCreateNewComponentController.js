/**
 * Created by MaxymMirona on 24.12.2019.
 */

({
    onInit : function(component, event, helper){
        helper.doInit(component, event);
    },

    onHandleSubmit : function (component, event, helper) {
        helper.doHandleSubmit(component, event);
    },

    checkStartDateForValidity : function (component, event, helper) {
        helper.onCheckStartDateForValidity(component, event);
    },

    checkRatesForValidity : function (component, event, helper) {
        helper.onCheckRatesForValidity(component, event);
    }
});