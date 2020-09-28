/**
 * Created by MaxymMirona on 04.05.2020.
 */

({
    afterRender : function (component, helper) {
        this.superAfterRender();
        helper.handleRowStyle(component);
    },

    rerender : function (component, helper) {
        this.superRerender();
        helper.handleRowStyle(component);
    }
});