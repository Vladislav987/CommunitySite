({getBrandsList: function (component, event, helper) {
        var action = component.get("c.getBrandsList");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.productList", response.getReturnValue());
            }
            var input = component.get("v.productList");
            var brandsList = input.map(function(product) {
                return product.Brand__c;
            });
            var result = brandsList.filter(function(product, index, self) {
                return self.indexOf(product) === index;
            });
            component.set("v.brandList", result)
        });
        $A.enqueueAction(action);
    },
    getSelectedProducts: function (component, event, helper) {
        var appEvent = $A.get("e.c:selectBrandappEvent");
        var action = component.get("c.getSelectedProducts");
        var Brand = event.getSource().get("v.label");
        action.setParam("Brand", Brand);
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.productList", response.getReturnValue());
                appEvent.setParams({
                    filteredList: response.getReturnValue()
                });
                appEvent.fire();
            }});

        $A.enqueueAction(action);

    }
})