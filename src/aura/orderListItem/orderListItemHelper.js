({
    deleteFromOrder: function (component, event) {
        let orderToDeleteIndex = event.getParam('index');
        let orderLineItems = component.get('v.orderLineItems');
        orderLineItems.splice(orderToDeleteIndex, 1);
        component.set('v.orderLineItems', orderLineItems);
    },
    recalculateTotalPrice: function (component) {
        let totalPrice = 0;
        let orderLineItems = component.get('v.orderLineItems');
        orderLineItems.forEach(orderLineItem => {
            totalPrice += orderLineItem.Price__c * orderLineItem.Quantity__c;
    });
        component.set('v.totalPrice', totalPrice);
    },

    saveOrder: function (component) {
        let self  = this;
        let orderLineItems = component.get('v.orderLineItems');
        let totalPrice =component.get('v.totalPrice');

        let orderLineItemsToSave = [];
        orderLineItems.forEach(orderLineItem => {
            orderLineItemsToSave.push({
            'sobjectType': 'Order_Product_Lines__c',


            'Product__c': orderLineItem.Product__c,
            'Model__c':orderLineItem.Model__c,
            'Brand__c':orderLineItem.Brand__c,
            'Image__c':orderLineItem.Image__c,
            'Price__c': orderLineItem.Price__c,
            'Quantity__c': orderLineItem.Quantity__c

        });
    });
        let saveOrderMethod = component.get('c.saveOrderLineItems');

        saveOrderMethod.setParams({"orderLineItems": orderLineItemsToSave, "totalPrice":totalPrice});
        saveOrderMethod.setCallback(this, response => {
            let state = response.getState();
        if (state === 'SUCCESS') {
            self.clearCard(component);
            self.showMyToast();
        }
    });
        $A.enqueueAction(saveOrderMethod);
    },


    clearCard: function (component) {
        component.set('v.orderLineItems', []);
    },
    showMyToast : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'sticky',
            message: 'This is a required message',
            messageTemplate: 'You made a order! Our manager will call you. Thank you:)',
            messageTemplateData: ['Salesforce', {
                url: 'http://www.salesforce.com/',
                label: 'here',
            }
            ]
        });
        toastEvent.fire();

    },



});