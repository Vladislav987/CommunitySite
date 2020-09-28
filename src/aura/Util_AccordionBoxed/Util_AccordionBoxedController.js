/**
 * Created by Lambru Dmytro on 19.03.2020.
 */
({
    handleInit: function (cmp, event, helper) {
        setTimeout($A.getCallback(() => {
            const buttonElement = cmp.find('#accordion_button').getElement();
            helper.openOrCloseAccordion(cmp, buttonElement);
        }),1000);
    },

    handleAccordionBtnClick: function (cmp, event, helper) {
        cmp.set('v.isOpen', !cmp.get('v.isOpen'));
        const buttonElement = event.currentTarget;
        helper.openOrCloseAccordion(cmp, buttonElement);
    },

    open: function (cmp, event, helper) {
        cmp.set('v.isOpen', true);
        const buttonElement = cmp.find('#accordion_button').getElement();
        helper.openOrCloseAccordion(cmp, buttonElement);
    },

    close: function (cmp, event, helper) {
        cmp.set('v.isOpen', false);
        const buttonElement = cmp.find('#accordion_button').getElement();
        helper.openOrCloseAccordion(cmp, buttonElement);
    },
});