/**
 * Created by Ponomarov Vladyslav on 05.06.2019.
 */
public with sharing class TestController {
    @AuraEnabled
    public static List<Column__c> getColumnsList(){
        List<Column__c> columns = [SELECT Id, Name FROM Column__c];
        return columns;
    }

}