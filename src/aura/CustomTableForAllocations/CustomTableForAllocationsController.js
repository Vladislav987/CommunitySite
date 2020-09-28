({
    selectAllAllocations: function (component, event, helper) {
        helper.selectAllAllocations(component, event);
    },
    onChange: function (component, event, helper) {
        helper.onChange(component)
    },
    doInit: function (component, event, helper) {
        helper.checkCheckBoxes(component);
    },
    uncheckAll: function (component, event,helper) {
        helper.uncheckAllCheckboxes(component);
    }


});