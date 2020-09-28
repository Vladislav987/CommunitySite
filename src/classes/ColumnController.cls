/**
 * Created by Ponomarov Vladyslav on 04.06.2019.
 */

public with sharing class ColumnController {
    @AuraEnabled
    public static List<Card__c> getCardsList(){
        List<Card__c> cards = [SELECT Id,
                                Description__c,
                                Comments__c,
                                Date_to_close__c,
                                Column__c,
                                Card_owner__c
                                FROM Card__c
        ];
        return cards;
    }

    @AuraEnabled
    public static List<Column__c> getColumnsList(){
        List<Column__c> columns = [SELECT Id,
                Name,
                (SELECT Id, Name, Description__c, Column__c, Comments__c, Card_owner__r.Name, Date_to_close__c FROM Cards__r)
                FROM Column__c
        ];
        return columns;
    }
}