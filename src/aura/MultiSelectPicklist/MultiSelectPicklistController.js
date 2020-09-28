/**
 * Created by MaxymMirona on 23.04.2020.
 */

({
    onInit : function (component, event, helper){
        helper.init(component, event);
    },

    onExpandOrCollapseListBox : function (component, event, helper) {
        helper.expandOrCollapseListBox(component, event);
    },

    onLeaveListBox : function (component, event, helper) {
        helper.leaveListBox(component, event);
    },

    onSelectPicklistOption : function (component, event, helper){
      helper.selectPicklistOption(component, event);
    },

    onRemovePillOption : function (component, event, helper){
        helper.removePillOption(component, event);
    },

    onSelectNoneOption : function (component, event, helper){
      helper.selectNoneOption(component, event);
    },

    getSelectedValues : function (component, event, helper) {
        return component.get("v.selectedOptions");
    }

});