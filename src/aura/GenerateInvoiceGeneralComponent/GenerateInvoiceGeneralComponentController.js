/**
 * Created by MaxymMirona on 19.06.2020.
 */

({
    onGenerateInvoice : function (component, event, helper) {
        helper.doOpenComponent(component, event, true);
    },

    onGenerateAccrual : function (component, event, helper) {
        helper.doOpenComponent(component, event, false);
    },
});