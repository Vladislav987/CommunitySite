/**
 * Created by MaxymMirona on 28.01.2020.
 */

({
    doInitRow : function (component, event, helper) {
        helper.onInitRow(component, event);
    },

    doChangeAllocationPercent : function (component, event, helper) {
        helper.onChangeAllocationPercent(component, event);
    },

    doApprove : function (component, event, helper) {
        helper.onApprove(component, event);
    }
});