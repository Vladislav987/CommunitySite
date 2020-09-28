/**
 * Created by MaxymMirona on 17.12.2019.
 */

({
    doInit : function (component, event, helper) {
        helper.onInit(component, event);
    },

    onFilterAllocations : function (component, event, helper) {
        helper.doFilterAllocations(component, event);
    },

    onHandleRowAction : function (component, event, helper) {
        helper.doHandleRowAction(component, event);
    },

    doCreateNewRecord : function (component, event, helper) {
        helper.onCreateNewRecord(component, event);
    }
});