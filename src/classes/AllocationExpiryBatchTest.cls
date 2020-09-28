/**
 *
 * @author: pz - Customertimes Corp.
 * @created: 16.04.2019
 * @version: 0.1
 */
@IsTest
private class AllocationExpiryBatchTest {

    private static final Id PROJECT_RECORD_TYPE_COMMERCIAL =
            Schema.Project__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Commercial').getRecordTypeId();
    private static final Integer EXPIRED_NUMBER = 5;
    private static final Integer VALID_NUMBER = 5;

    @TestSetup
    static void genData(){
        Profile p = [SELECT Id FROM Profile WHERE Name='CT_Project Manager'];
        User u = new User(Alias = 'standt', Email='test123987528@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='test123987528@testorg.com');

        insert u;

        Project__c project = new Project__c();
        project.Name = 'project name';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.Start_date__c = Date.today().addMonths(-5);
        project.End_date__c = Date.today().addMonths(5);
        project.RecordTypeId = PROJECT_RECORD_TYPE_COMMERCIAL;
        project.Project_Manager__c = u.Id;
        project.CurrencyIsoCode = 'USD';

        insert project;


        List<Allocation__c> allocs = new List<Allocation__c>();
        for(Integer i = 0; i< EXPIRED_NUMBER; i++){
            Integer stat = Math.mod(i,AllocationExpiryBatch.FLIP_STATUSES.size());
            Integer rt = Math.mod(i,AllocationExpiryBatch.FLIP_RTS.size());


            Allocation__c alloc = new Allocation__c(
                	Start_date__c = System.today().addDays(-i-3)
                    ,Project__c = project.Id
                    ,End_date__c = System.today().addDays(-i-1)
                    ,Status__c = AllocationExpiryBatch.FLIP_STATUSES[stat]
                    ,RecordTypeId = Schema.SObjectType.Allocation__c.getRecordTypeInfosByDeveloperName().get(AllocationExpiryBatch.FLIP_RTS[rt]).getRecordTypeId()
            );
            alloc = (Allocation__c)TestDataFactory.createsObject(alloc,false);
            allocs.add(alloc);
        }
        for(Integer i = 0; i< VALID_NUMBER; i++){
            Integer stat = Math.mod(i,AllocationExpiryBatch.FLIP_STATUSES.size());
            Integer rt = Math.mod(i,AllocationExpiryBatch.FLIP_RTS.size());

            Allocation__c alloc = new Allocation__c(
                    Project__c = project.Id
                    ,Status__c = AllocationExpiryBatch.FLIP_STATUSES[stat]
                    ,RecordTypeId = Schema.SObjectType.Allocation__c.getRecordTypeInfosByDeveloperName().get(AllocationExpiryBatch.FLIP_RTS[rt]).getRecordTypeId()
            );
            alloc = (Allocation__c)TestDataFactory.createsObject(alloc,false);
            allocs.add(alloc);
        }

        if(!allocs.isEmpty()){
            insert allocs;
        }
    }
    @IsTest
    static void runBatchSuccess() {
        System.Test.startTest();
        AllocationExpiryBatch b = new AllocationExpiryBatch();
        database.executebatch(b,AllocationExpiryBatch.CHUNK_SIZE);
        System.Test.stopTest();

        String q = 'SELECT count() FROM Allocation__c WHERE ';
        for(Schema.sObjectField fld :AllocationExpiryBatch.INACTIVITY_FLAGS.keySet()){
            q += fld.getDescribe().getName() +' = \'' + String.escapeSingleQuotes(String.valueOf(AllocationExpiryBatch.INACTIVITY_FLAGS.get(fld))) + '\' AND ';
        }

        if(q.endsWith('AND ')){
            q = q.removeEnd('AND ');
        }

        System.assertEquals(EXPIRED_NUMBER,Database.countQuery(q),'All expired allocations should have been set as "Finished"');
    }
    @IsTest
    static void runBatchFail() {
        System.Test.startTest();

        AllocationExpiryBatch b = new AllocationExpiryBatch(true);
        database.executebatch(b,AllocationExpiryBatch.CHUNK_SIZE);
        System.Test.stopTest();

        String q = 'SELECT count() FROM Allocation__c WHERE ';
        for(Schema.sObjectField fld :AllocationExpiryBatch.INACTIVITY_FLAGS.keySet()){
            q += fld.getDescribe().getName() +' = \'' + String.escapeSingleQuotes(String.valueOf(AllocationExpiryBatch.INACTIVITY_FLAGS.get(fld))) + '\' AND ';
        }

        if(q.endsWith('AND ')){
            q = q.removeEnd('AND ');
        }
        System.assertEquals(0,Database.countQuery(q),'No allocations should have been updated');
        System.assertEquals(EXPIRED_NUMBER,[SELECT count() FROM FeedItem],'Feed items with errors should have been created for each expired allocation');

    }

}