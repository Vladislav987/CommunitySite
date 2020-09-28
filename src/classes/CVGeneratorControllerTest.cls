/**
 *
 * @author: pz - Customertimes Corp.
 * @created: 25.04.2019
 * @version: 0.1
 */
@IsTest
private class CVGeneratorControllerTest {
    @TestSetup
    static void doSetup(){
        Contractor__c contr = new Contractor__c(
                Detailed_Technical_Skills__c = Contractor__c.Detailed_Technical_Skills__c.getDescribe().getPicklistValues()[0].getValue()
        );
        contr = (Contractor__c)TestDataFactory.createSObject(contr,true);
        Project__c proj = (Project__c)TestDataFactory.createSObject(new Project__c(Project_description__c = 'Testing'),true);

        Allocation__c alloc = (Allocation__c)TestDataFactory.createSObject(
            new Allocation__c(Contractor__c = contr.Id, Project__c = proj.Id)
            ,true
        );
    }

    @IsTest
    static void doTestContextLoad() {
        final Integer pageNo = 1;
        final Integer perPage = 5;
        Contractor__c contr = [
                SELECT
                        Id
                FROM Contractor__c LIMIT 1
        ];
        System.Test.startTest();

        CVGeneratorController.Context ctxt = CVGeneratorController.getContext((String)null,pageNo,perPage,new List<String>(),contr.Id,new List<Id>());

        System.assertNotEquals(null,ctxt.lds,'Should be initialized');
        System.assertNotEquals(null,ctxt.spec,'Should be initialized');
        System.assertNotEquals(null,ctxt.specs,'Should be initialized');
        System.assertEquals(5,ctxt.pageSize,'Should be initialized');
        System.assertEquals(1,ctxt.page,'Should be initialized');
        System.assertEquals(1,ctxt.total,'Should have only projects created in test scope');
        System.assertNotEquals(null,ctxt.sels,'Should be initialized');
        System.assertEquals(1,ctxt.sels.size(),'Should have pulled only one preselected test project');

        System.Test.stopTest();
    }
}