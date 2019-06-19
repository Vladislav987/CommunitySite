({
    findProducts: function (component, event) {
        var appEvent = $A.get("e.c:findProductsEvent");
        var action = component.get("c.searchProducts");
        var findString = component.get('v.searchString');
        action.setParams({'parametr': findString});
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                  appEvent.setParams({
                      findProduct: response.getReturnValue()
                });
                appEvent.fire();
            }
        });

        $A.enqueueAction(action);



    }
})