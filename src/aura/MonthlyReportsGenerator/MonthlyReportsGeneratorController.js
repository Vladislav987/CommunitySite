({
    doInit: function(component, event, helper) {
        helper.toggleTwoStep(component);
        helper.init(component);
    },
    goToStepTwo: function (component, event, helper) {
        helper.onStepTwo(component);
    },
    onAllocationFilter : function (component, event, helper) {
        helper.doHandleFilterAllocations(component, event);
    },
    goToStepOne: function(component, event, helper) {
        helper.activateStepOne(component);
    },
    tryToCreateReports: function(component, event, helper) {
        let selectedAllocationsWithReports = component.get("v.selectedAllocationsWithOneReports");
        if (selectedAllocationsWithReports.length > 0){
            component.set("v.isModalOpen", true);
        }else{
            helper.tryToCreate(component);
        }
    },
    changeSegmentValue: function(component, event, helper) {
        helper.changeSegmentValue(component);
    },
    checkSelectedDay: function (component, event, helper) {
        helper.checkSelectedDay(component, event);
    },
    openModel: function(component, event, helper) {
        // Set isModalOpen attribute to true
        component.set("v.isModalOpen", true);
    },

    closeModel: function(component, event, helper) {
        // Set isModalOpen attribute to false
        component.set("v.isModalOpen", false);
    },

    submitDetails: function(component, event, helper) {
        // Set isModalOpen attribute to false
        //Add your code to call apex method or do some processing
        component.set("v.isModalOpen", false);
        helper.tryToCreate(component);
    },

});