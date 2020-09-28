/**
 * Created by Ponomarov Vladyslav on 06.06.2019.
 */

public with sharing class Selector {
    public static Card__c getCard(Card__c card){
        return [SELECT Id,
                Name,
                Card_owner__c,
                Date_to_close__c,
                Description__c,
                Comments__c,
                Column__c
                FROM Card__c
                WHERE Id = :card.Id
        ];

    }

}