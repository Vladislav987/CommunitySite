public with sharing class ProductBrandController {
    @AuraEnabled
    public static List<Product2> getBrandsList() {
        List<Product2> productList = new List<Product2>();
        productList = [
                SELECT Brand__c
                FROM Product2
        ];
        return productList;
    }

    @AuraEnabled
    public static List<Product2> getSelectedProducts(String Brand) {
        List<Product2> productList = new List<Product2>();
        If (Brand == 'Select All') {
            productList = [
                    SELECT Id, Name, Quantity__c, Battery_Capacity__c,Brand__c, Camera__c, Code_of_Product__c,
                            Image__c, Network__c, Price__c, Screen_Size__c, Sim_Card_Type__c,
                            Storage__c, Weight__c, Description
                    FROM Product2
            ];
        }

        else {
            productList = [
                    SELECT Id, Name, Quantity__c, Battery_Capacity__c,Brand__c, Camera__c, Code_of_Product__c,
                            Image__c, Network__c, Price__c, Screen_Size__c, Sim_Card_Type__c,
                            Storage__c, Weight__c, Description
                    FROM Product2
                    WHERE Brand__c = :Brand
            ];
        }
        return productList;
    }

    @AuraEnabled
    public static AggregateResult[] getCountByBrands() {
            AggregateResult[] CountByBrandsList = [
                    SELECT Brand__c, COUNT(NAME)cnt
                    FROM Product2
                    GROUP BY Brand__c
            ];
        return CountByBrandsList;
    }
}