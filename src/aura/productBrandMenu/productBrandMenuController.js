({
    doInit : function(component, event, helper){
        helper.getBrandsList(component);
        helper.getCountByBrands(component);
    },

    click : function(component, event, helper){
        helper.getSelectedProducts(component, event);
    }

})