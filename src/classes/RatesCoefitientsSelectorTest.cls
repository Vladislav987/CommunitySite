/**
 * Created by Mychailo Hamdzii on 24.04.2019.
 */
@IsTest
private class RatesCoefitientsSelectorTest {

    private static final Date TEST_DATE_START = Date.newInstance(1900, 1, 1);
    private static final Date TEST_DATE_END = Date.newInstance(1901, 1, 1);
    private static final Integer SINGLE_RECORD = 1;
    private static final String MDT_RECORD_LABEL = 'mdt label';
    private static final String ALLOCATION_STATUS_ACTIVE = 'Active';
    @TestSetup
    private static void setup() {
        Project__c project = new Project__c();
        project.Name = 'project name';
        project.Project_type__c = 'Outsource';
        project.Contract_type__c = 'Fixed cost';
        project.Start_date__c = TEST_DATE_START;
        project.End_date__c = TEST_DATE_END;

        insert project;

        Contractor__c contractor = new Contractor__c();
        contractor.Name = 'zdarova';
        contractor.Resource_Type__c = 'SFDC Developer';
        contractor.Resource_Level__c = 'Trainee';

        insert contractor;

        Allocation__c allocation = new Allocation__c();
        allocation.Project__c = project.Id;
        allocation.Contractor__c = contractor.Id;
        allocation.Allocation__c = 100;
        allocation.Allocation_Type__c = 'Billable';
        allocation.Start_date__c = TEST_DATE_START;
        allocation.End_date__c = TEST_DATE_END;
        allocation.Status__c = ALLOCATION_STATUS_ACTIVE;

        insert allocation;
    }

    @IsTest
    private static void getCoefitientsFromMdtCorrectFlow() {
        RatesCoefitientsSelector mockedRates =
            (RatesCoefitientsSelector)Test.createStub(RatesCoefitientsSelector.class, new MetadataMockProvider());

        Test.startTest();

        List<Rates_Coefitients__mdt> rates = mockedRates.getCoefitientsFromMdt(MDT_RECORD_LABEL);

        Test.stopTest();

        Decimal value = rates[0].Value__c;
        System.assertEquals(SINGLE_RECORD, rates.size());
        System.assert(value != null && value != 0);
    }
}