/**
 * Created by MaxymMirona on 02.05.2020.
 */

({
    onInit : function (component, event, helper) {
        helper.init(component, event);
    },

    getSelectedRows : function (component, event, helper) {
        return helper.handleGetSelectedRows(component, event);
    },

    onChangeSelectAll : function (component, event, helper) {
        helper.handleChangeSelectAll(component, event);
    },

    onPreselectAll : function (component, event, helper) {
        helper.handlePreselectAll(component, event);
    }
});