/**
 *
 * @author: pz - Customertimes Corp.
 * @created: 26.04.2019
 * @version: 0.1
 */
@IsTest
private class sObjectDomainTest {
    @IsTest
    static void doTest() {
        System.Test.startTest();
        sObjectDomain.triggerHandler(sObjectDomain.class,true,true,true,true,true,true,new List<Account>{new Account()},new Map<Id,Account>());
        sObjectDomain.triggerHandler(sObjectDomain.class,false,true,true,true,true,true,new List<Account>{new Account()},new Map<Id,Account>());
        sObjectDomain.triggerHandler(sObjectDomain.class,true,true,false,true,true,true,new List<Account>{new Account()},new Map<Id,Account>());
        sObjectDomain.triggerHandler(sObjectDomain.class,true,true,false,false,true,true,new List<Account>{new Account()},new Map<Id,Account>());
        sObjectDomain.triggerHandler(sObjectDomain.class,true,true,false,false,false,true,new List<Account>{new Account()},new Map<Id,Account>());
        sObjectDomain.triggerHandler(sObjectDomain.class,true,true,false,false,false,false,new List<Account>{new Account()},new Map<Id,Account>());

        sObjectDomain.triggerHandler(sObjectDomain.class,false,true,false,true,true,true,new List<Account>{new Account()},new Map<Id,Account>());
        sObjectDomain.triggerHandler(sObjectDomain.class,false,true,false,false,true,true,new List<Account>{new Account()},new Map<Id,Account>());
        sObjectDomain.triggerHandler(sObjectDomain.class,false,true,false,false,false,true,new List<Account>{new Account()},new Map<Id,Account>());
        sObjectDomain.triggerHandler(sObjectDomain.class,false,true,false,false,false,false,new List<Account>{new Account()},new Map<Id,Account>());
        SObjectDomain sod = new SObjectDomain(new List<Account>{new Account()});
        sod.handleBeforeInsert();
        sod.handleBeforeUpdate(new Map<Id,sObject>());
        sod.handleBeforeDelete();

        sod.handleAfterInsert();
        sod.handleAfterUpdate(new Map<Id,sObject>());
        sod.handleAfterDelete();
        sod.handleAfterUnDelete();

        System.assertEquals(Account.sObjectType.getDescribe(),sod.sObjectDescribe,'Should be intialized with accounts');
        System.assertEquals(true,sObjectDomain.isRunOnce(),'Should have run');
        System.Test.stopTest();
    }
}