/**
 * Created by MaxymMirona on 02.05.2020.
 */

({
    onInit : function (component, event, helper) {
        helper.init(component, event);
    },

    onPicklistChange : function (component, event, helper) {
        helper.handlePicklistChange(component, event);
    }
});