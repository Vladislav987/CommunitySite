/*
 * Created by Vladyslav Ponomarov
 */
public with sharing class OrderController {
	@AuraEnabled
	public static void saveOrderLineItems(List<Order_Product_Lines__c> orderLineItems, Integer totalPrice) {
		try {
			Order__c order = new Order__c();
			order.Timestamp__c = Datetime.now();
			order.Status__c = 'NEW';
			order.Total_price_of_order__c = Integer.valueOf(totalPrice);
			insert order;

			for (Order_Product_Lines__c orderLineItem : orderLineItems) {
				orderLineItem.Order__c = order.Id;
			}
			insert orderLineItems;

		} catch (DmlException ex) {
			throw new AuraHandledException(ex.getMessage());
		}

	}

}