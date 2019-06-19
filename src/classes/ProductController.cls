/*
 * Created by Vladyslav Ponomarov
 */

public with sharing class ProductController {
	@AuraEnabled
	public static List<Product2>  searchProducts(String parametr) {
		List<Product2> productsList = new List<Product2>();
		List<List<Object>> findingProducts = [FIND :parametr IN ALL FIELDS RETURNING Product2(Id, Name,
		 												Quantity__c, Battery_Capacity__c,Brand__c, Camera__c, Code_of_Product__c,
														Image__c, Network__c, Price__c, Screen_Size__c, Sim_Card_Type__c, OS_Version__c,
														Storage__c, Weight__c, Description, Ram__c, Dimensions__c)];
		 productsList = (Product2[])findingProducts[0];

		return productsList;
	}

	@AuraEnabled
	public static List<Product2> getAllProducts() {
		List<Product2> productList = new List<Product2>();
		productList = [SELECT Id, Name, Quantity__c, Battery_Capacity__c,Brand__c, Camera__c, Code_of_Product__c,
				Image__c, Network__c, Price__c, Screen_Size__c, Sim_Card_Type__c, OS_Version__c,
				Storage__c, Weight__c, Description, Ram__c, Dimensions__c
				FROM Product2];
		return productList;
	}
	//Added by Igor Babych
	@AuraEnabled
	public static List<Product2> getBrandsList() {
		List<Product2> productList = new List<Product2>();
		productList = [SELECT Brand__c
				FROM Product2];
		return productList;
	}

	@AuraEnabled
	public static List<Product2> getSelectedProducts(String Brand) {
		List<Product2> productList = new List<Product2>();
		If (Brand == 'Select All') {
			productList = [SELECT Id, Name, Quantity__c, Battery_Capacity__c,Brand__c, Camera__c, Code_of_Product__c,
					Image__c, Network__c, Price__c, Screen_Size__c, Sim_Card_Type__c,
					Storage__c, Weight__c, Description
					FROM Product2];
		}

		else {
			productList = [SELECT Id, Name, Quantity__c, Battery_Capacity__c,Brand__c, Camera__c, Code_of_Product__c,
					Image__c, Network__c, Price__c, Screen_Size__c, Sim_Card_Type__c,
					Storage__c, Weight__c, Description
					FROM Product2
					WHERE Brand__c = :Brand];
		}
		return productList;
	}
}