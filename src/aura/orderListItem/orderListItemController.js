({

    handleDeleteFromOrder: function (component, event, helper) {
        helper.deleteFromOrder(component, event);
    },

    recalculateTotalPrice: function (component, event, helper) {
        helper.recalculateTotalPrice(component);
    },
    saveOrder: function (component, event, helper) {
        helper.saveOrder(component);
    },

    clearCard: function (component, event, helper) {
        helper.clearCard(component);
    }


});