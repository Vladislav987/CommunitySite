({
    openWindow: function (component, helper, event) {
        component.set('v.isOpen', true);
    },
    closeWindow: function (component, helper, event) {
        component.set('v.isOpen', false);
    }
});