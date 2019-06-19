({ doInit : function(component, event, helper){
        helper.getBrandsList(component);
    },
    handleBrandAppEvent : function(component, event, helper){
    helper.getSelectedProduct(component, event);
}
})