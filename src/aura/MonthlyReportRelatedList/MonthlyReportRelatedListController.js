({
    doInit : function (component, event, helper) {
        helper.init(component, event);
    },

    onFilterMonthlyReports : function (component, event, helper) {
        helper.filterMonthlyReports(component, event);
    },

    onGetUpdatedReports : function (component, event, helper) {
        helper.getUpdatedReportsAndApplyFilter(component, event);
    },

    onSaveDataTable : function (component, event, helper) {
        component.set("v.isLoading", true);
        helper.saveDataTable(component, event);
        var action = component.get('c.onGetUpdatedReports');
        $A.enqueueAction(action);
    }
});