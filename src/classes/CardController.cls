/**
 * Created by Ponomarov Vladyslav on 06.06.2019.
 */

public with sharing class CardController {
    @AuraEnabled
    public static void deleteCard(Card__c card){
        Card__c cardForDelete = Selector.getCard(card);
        delete cardForDelete;
    }

    @AuraEnabled
    public static void changeColumn(Card__c card, Id columnId){
        Card__c cardForUpdate = Selector.getCard(card);
        cardForUpdate.Column__c = columnId;

        update cardForUpdate;

    }

}