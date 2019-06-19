({
    addToCard: function (component) {
        let componentEvent = component.getEvent('addToCard');
        let item = component.get('v.item');
        console.log('FOR VLAD' + component);

        let inputNumber = component.find('inputNumber').get('v.value');
        console.log('FOR VLAD' + inputNumber);
        componentEvent.setParams({
            'orderItem': {
                'sobjectType': 'Order_Product_Lines__c',
                'Product__c': item.Id,
                'Model__c': item.Name,
                'Brand__c': item.Brand__c,
                'Image__c': item.Image__c,
                'Price__c': item.Price__c,
                'Quantity__c': inputNumber
            }
        });
        componentEvent.fire();
    }
});