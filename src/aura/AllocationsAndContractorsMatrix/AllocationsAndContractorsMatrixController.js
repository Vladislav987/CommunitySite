/**
 * Created by MaxymMirona on 28.01.2020.
 */

({
    doInit : function (component, event, helper) {
        helper.onInit(component, event);
    },

    doSave : function (component, event, helper) {
        helper.onSave(component, event);
    },

    doApproveAll : function (component, event, helper) {
        helper.onApproveAll(component, event);
    },

    handleSendApproveRequiredToParent : function (component, event, helper) {
        helper.doHandleSendApproveRequiredToParent(component, event);
    },

    doInitMatrixOnly : function (component, event, helper) {
        helper.OnInitMatrixOnly(component, event);
    }
});