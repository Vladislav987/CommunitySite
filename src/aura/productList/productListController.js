({
    doInit : function(component, event, helper){
        helper.getListProducts(component);
    },
    handleAddToCard: function (component, event, helper) {
        helper.addToCard(component, event);
        helper.resetInputField(event);
    },
    handleBrandAppEvent : function(component, event, helper){
        helper.getSelectedProduct(component, event);
    },
    handleFindProducts: function (component, event, helper) {
        helper.getSearchProduct(component, event);
        console.error('controller');
    }
})