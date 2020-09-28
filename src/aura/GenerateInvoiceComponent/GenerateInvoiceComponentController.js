/**
 * Created by MaxymMirona on 12.03.2020.
 */

({
    onInit : function (component, event, helper){
        helper.doInit(component, event);
    },

    onGenerateInvoice : function (component, event, helper) {
        helper.doGenerateInvoice(component, event);
    },

    onFilterMonthlyReports : function (component, event, helper) {
        helper.handleFilterMonthlyReports(component, event);
    }
});