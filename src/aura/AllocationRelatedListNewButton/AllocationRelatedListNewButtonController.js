/**
 * Created by MaxymMirona on 10.01.2020.
 */

({
    doInit : function (component, event, helper){
        helper.onInit(component, event);
    },

    doCancel : function (component, event, helper){
        helper.onCancel(component, event);
    },

    doCreateNewRecord : function (component, event, helper) {
        helper.onCreateNewRecord(component, event)
    }
});