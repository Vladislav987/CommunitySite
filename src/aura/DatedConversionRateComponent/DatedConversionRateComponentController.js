/**
 * Created by MaxymMirona on 23.12.2019.
 */

({
    doInit : function (component, event, helper) {
        helper.doInit(component, event);
    },

    onSaveDataTable : function (component, event, helper) {
        component.set("v.isLoading", true);
        helper.saveDataTable(component, event);
        helper.doInit(component, event);
    },

    onNewExchangeRates : function (component, event, helper) {
        helper.createNewExchangeRates(component, event);
    }
});