/**
 *
 * @author: pz - Customertimes Corp.
 * @created: 25.04.2019
 * @version: 0.1
 */
@IsTest
private class CVTemplateControllerTest {
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
    static void doGenVF() {
        Contractor__c contr = [
            SELECT
                Id
                ,Name
                ,Certification__c
                ,Detailed_Technical_Skills__c
                ,Resource_Type__c
            FROM Contractor__c LIMIT 1
        ];
        System.Test.startTest();

        ApexPages.currentPage().getParameters().put(CVTemplateController.PROJECT_IDS_PARAM,null);
        ApexPages.currentPage().getParameters().put(CVTemplateController.DOC_TYPE_PARAM,'vf');

        ApexPages.StandardController std = new ApexPages.StandardController(contr);

        CVTemplateController ext = new CVTemplateController(std);

        System.assertNotEquals(null,ext.certs,'Should be initialized');
        System.assertNotEquals(true,ext.isWord,'Should not be Word');
        System.assertNotEquals(null,ext.projs,'Should be initialized');
//        System.assertNotEquals(null,ext.projs[0].responsibility,'Should be initialized');
        System.assertNotEquals(null,ext.projs[0].technologies,'Should be initialized');
        System.assertEquals(null,ext.projs[0].technology,'Should be missing');
        System.assertNotEquals(null,ext.projs[0].name,'Should be initialized');
        System.assertNotEquals(null,ext.projs[0].description,'Should be initialized');
        System.assertNotEquals(null,ext.projIds,'Should be initialized');
        System.assertNotEquals(null,ext.techsKeys,'Should be initialized');
        System.assertNotEquals(null,ext.techs,'Should be initialized');
        System.assertNotEquals(null,ext.certs,'Should be initialized');
        System.assertNotEquals(null,ext.certPics,'Should be initialized');
        System.assertNotEquals(null,ext.rspnsblts,'Should be initialized');
        System.assertNotEquals(null,ext.getLogoUrl(),'Should be initialized');

        System.Test.stopTest();
    }
    @IsTest
    static void doGenWord() {
        Contractor__c contr = [
                SELECT
                        Id
                        ,Name
                        ,Certification__c
                        ,Detailed_Technical_Skills__c
                        ,Resource_Type__c
                FROM Contractor__c LIMIT 1
        ];
        System.Test.startTest();

        ApexPages.currentPage().getParameters().put(CVTemplateController.PROJECT_IDS_PARAM,null);
        ApexPages.currentPage().getParameters().put(CVTemplateController.DOC_TYPE_PARAM,'msword');

        ApexPages.StandardController std = new ApexPages.StandardController(contr);

        CVTemplateController ext = new CVTemplateController(std);

        System.assertNotEquals(null,ext.certs,'Should be initialized');
        System.assertEquals(true,ext.isWord,'Should be Word');
        System.assertNotEquals(null,ext.projs,'Should be initialized');
//        System.assertNotEquals(null,ext.projs[0].responsibility,'Should be initialized');
        System.assertNotEquals(null,ext.projs[0].technologies,'Should be initialized');
        System.assertEquals(null,ext.projs[0].technology,'Should be missing');
        System.assertNotEquals(null,ext.projs[0].name,'Should be initialized');
        System.assertNotEquals(null,ext.projs[0].description,'Should be initialized');
        System.assertNotEquals(null,ext.projIds,'Should be initialized');
        System.assertNotEquals(null,ext.techsKeys,'Should be initialized');
        System.assertNotEquals(null,ext.techs,'Should be initialized');
        System.assertNotEquals(null,ext.certs,'Should be initialized');
        System.assertNotEquals(null,ext.certPics,'Should be initialized');
        System.assertNotEquals(null,ext.rspnsblts,'Should be initialized');
        System.assertNotEquals(null,ext.getLogoUrl(),'Should be initialized');

        System.Test.stopTest();
    }
}