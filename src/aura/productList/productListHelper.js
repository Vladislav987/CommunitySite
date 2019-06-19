({
    getListProducts: function (component, event, helper) {
        var action = component.get("c.getAllProducts");
                action.setCallback(this, function (response) {
                    var state = response.getState();
                    if (state === "SUCCESS"){
                        component.set("v.productList", response.getReturnValue());
                    }
        });
        $A.enqueueAction(action);
    },



    addToCard: function (component, event) {
        let orderItem = event.getParam('orderItem');
        let orders = component.get('v.orders');
        let isProcessed = false;

        orders.forEach(order=>{
            if (order.Product__c === orderItem.Product__c) {
            order.Quantity__c = Number.parseInt(order.Quantity__c) + Number.parseInt(orderItem.Quantity__c);
            isProcessed = true;
        }
    });
        if (!isProcessed === true) {
            orders.push(orderItem);
        }
        component.set('v.orders', orders);
    },
    resetInputField: function (event) {
        let inputField = event.getSource().find('inputNumber');
        inputField.set('v.value', '1');
    },
    //Added by Igor Babych
    getSelectedProduct: function (component, event, helper) {
        var filteredList = event.getParam('filteredList');
        component.set('v.productList', filteredList);
    },

    //Added by Ponomarov Vladyslav
    getSearchProduct: function (component, event){
        var products = event.getParam('findProduct');
        component.set('v.productList', products);
    },




})