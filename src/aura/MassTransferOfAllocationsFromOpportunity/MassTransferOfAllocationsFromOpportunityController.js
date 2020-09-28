({
    doInit: function (component, event, helper) {
        helper.init(component);
    },

    onTransferAllocations1: function (component, event, helper) {
        helper.updateAllocations(component);


    },
    handleRowAction:function (component, event, helper) {
        helper.checkUnselectedRows(component);
    },
});