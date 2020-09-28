({
    doInit: function(component, event, helper) {
        helper.init(component);
    },

    onCreateReports: function(component, event, helper){
        helper.onReportGenerationStart1(component);
    },

    onSelectCheckbox : function (component, event, helper) {
        helper.doSelectCheckbox(component, event);
    },

    onAllocationFilter : function (component, event, helper) {
        helper.doHandleFilterAllocations(component, event);
    },

    onSelectAllColumnAllocations : function (component, event, helper) {
        helper.doSelectAllColumnAllocations(component, event);

    }

});