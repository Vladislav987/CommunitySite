/**
 * Created by Ponomarov Vladyslav on 06.06.2019.
 */

({
    openWindow: function (component, helper, event) {
        component.set('v.isOpen', true);
    },
    closeWindow: function (component, helper, event) {
        component.set('v.isOpen', false);
        component.getEvent('deleteCard').fire();

    }

});