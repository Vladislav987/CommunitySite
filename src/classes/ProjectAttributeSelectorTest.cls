/**
 * Created by Lambru Dmytro on 25.03.2020.
 */

@IsTest
private class ProjectAttributeSelectorTest {
    private static final String DEFAULT_PROJECT_NAME = 'FOR_TEST';

    @TestSetup
    static void doSetup() {
        TestDataFactory.createSObject(new Project__c(Name = DEFAULT_PROJECT_NAME),true);
    }

    @IsTest
    static void testGetWithRTSpecializationAndSpecifiedPicklistOptionsByProjectId() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];
        Map<Object, Schema.PicklistEntry[]> masterValueToDependentPicklistEntriesMap = Util.getMapWithActiveMasterValueToDependentPicklistEntries(ProjectAttributeSelector.SPECIALIZATION_SOBJECT_FIELD);

        Project_attribute__c[] projectAttributeList = ProjectAttributeTestService.createPAsWithRTSpecializationForAllPicklistOptions(project.Id, masterValueToDependentPicklistEntriesMap);
        insert projectAttributeList;

        Set<String> masterPicklistOptionApiNameSet = createSetWithMasterPicklistOptionApiNames(masterValueToDependentPicklistEntriesMap);
        Set<String> specializationPicklistOptionApiNameSet = createSetWithSpecializationPicklistOptionApiNames(masterValueToDependentPicklistEntriesMap);

        Test.startTest();
            ProjectAttributeSelector projectAttributeSelector = new ProjectAttributeSelector();
            Project_attribute__c[] selectedProjectAttributeList = projectAttributeSelector.getWithRTSpecializationAndSpecifiedPicklistOptionsByProjectId(project.Id, masterPicklistOptionApiNameSet, specializationPicklistOptionApiNameSet);
        Test.stopTest();

        System.assertEquals(projectAttributeList.size(), selectedProjectAttributeList.size(), 'Lists must be the same size!');
    }

    @IsTest
    static void testGetByIdSet() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];
        Project_attribute__c[] projectAttributeList = (Project_attribute__c[])TestDataFactory.createSObjectList(new Project_attribute__c(Project__c = project.Id), 10, true);

        Set<Id> projectAttributeIdSet = new Set<Id>();
        for (Project_attribute__c projectAttribute : projectAttributeList) {
            projectAttributeIdSet.add(projectAttribute.Id);
        }

        Test.startTest();
            ProjectAttributeSelector projectAttributeSelector = new ProjectAttributeSelector();
            Project_attribute__c[] selectedProjectAttributeList = projectAttributeSelector.getByIdSet(projectAttributeIdSet);
        Test.stopTest();

        System.assertEquals(projectAttributeList.size(), selectedProjectAttributeList.size(), 'Lists must be the same size!');
    }

    @IsTest
    static void testGetWithRTAssessmentAndSpecifiedFieldsSetByProjectId() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];
        Project_attribute__c[] projectAttributeList = (Project_attribute__c[])TestDataFactory.createSObjectList(new Project_attribute__c(Project__c = project.Id,RecordTypeId = ProjectAttributeSelector.PROJECT_ATTRIBUTE_RECORD_TYPE_ASSESSMENT_ID), 10, true);

        List<String> projectAttributeFieldList = new List<String>{
                'Id', 'Status__c','CreatedById','Project__r.Name','Project__r.CreatedById'
        };

        Test.startTest();
        ProjectAttributeSelector projectAttributeSelector = new ProjectAttributeSelector();
        Project_attribute__c[] selectedProjectAttributeList = projectAttributeSelector.getProjectAttributesForAssessmentRT(projectAttributeFieldList,project.Id);
        Test.stopTest();

        System.assertEquals(projectAttributeList.size(), selectedProjectAttributeList.size(), 'Lists must be the same size!');

    }

    /******************/
    /* HELPER METHODS */
    /******************/

    static Set<String> createSetWithMasterPicklistOptionApiNames(Map<Object, Schema.PicklistEntry[]> masterValueToDependentPicklistEntriesMap) {
        Set<String> masterPicklistOptionApiNameSet = new Set<String>();

        for (Object masterPicklistValue : masterValueToDependentPicklistEntriesMap.keySet()) {
            masterPicklistOptionApiNameSet.add((String)masterPicklistValue);
        }

        return masterPicklistOptionApiNameSet;
    }

    static Set<String> createSetWithSpecializationPicklistOptionApiNames(Map<Object, Schema.PicklistEntry[]> masterValueToDependentPicklistEntriesMap) {
        Set<String> specializationPicklistOptionApiNameSet = new Set<String>();

        for (Schema.PicklistEntry[] dependentEntryList : masterValueToDependentPicklistEntriesMap.values()) {

            for (Schema.PicklistEntry dependentEntry : dependentEntryList) {
                specializationPicklistOptionApiNameSet.add(dependentEntry.getValue());
            }
        }

        return specializationPicklistOptionApiNameSet;
    }
}