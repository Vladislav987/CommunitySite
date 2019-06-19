({
    doInit : function(component, event, helper){
        helper.getBrandsList(component);
    },

    click : function(component, event, helper){
        helper.getSelectedProducts(component, event);
    }
})