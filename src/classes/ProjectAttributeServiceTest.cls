/**
 * Created by Lambru Dmytro on 25.03.2020.
 */

@IsTest
private class ProjectAttributeServiceTest {
    private static final String DEFAULT_PROJECT_NAME = 'FOR_TEST';
    private static final Schema.SObjectType PROJECT_ATTRIBUTE_SOBJECT_TYPE = Schema.Project_attribute__c.SObjectType;

    @TestSetup
    static void doSetup() {
        TestDataFactory.createSObject(new Project__c(Name = DEFAULT_PROJECT_NAME), true);
    }

    @IsTest
    static void tesGetSettingsForMasterWithDependentSpecializationFields() {

        Test.startTest();
        ProjectAttributeService projectAttributeService = new ProjectAttributeService();
        ObjectMasterPicklistOption__mdt[] objectMasterPicklistOptionList = projectAttributeService.getSettingsForMasterWithDependentSpecializationFields();
        Test.stopTest();

        for (ObjectMasterPicklistOption__mdt objectMasterPicklistOptionSettings : objectMasterPicklistOptionList) {
            System.assertEquals(true, objectMasterPicklistOptionSettings.ObjectApiName__c.length() > 0);
            System.assertEquals(true, objectMasterPicklistOptionSettings.FieldApiName__c.length() > 0);
            System.assertEquals(true, objectMasterPicklistOptionSettings.OptionApiName__c.length() > 0);

            if (!objectMasterPicklistOptionSettings.ObjectDependentPicklistOptions__r.isEmpty()) {

                for (ObjectDependentPicklistOption__mdt dependentPicklistOptionSettings : objectMasterPicklistOptionSettings.ObjectDependentPicklistOptions__r) {
                    System.assertEquals(true, dependentPicklistOptionSettings.ObjectApiName__c.length() > 0);
                    System.assertEquals(true, dependentPicklistOptionSettings.FieldApiName__c.length() > 0);
                    System.assertEquals(true, dependentPicklistOptionSettings.OptionApiName__c.length() > 0);
                }
            }
        }

        System.assertEquals(true, objectMasterPicklistOptionList.size() > 0, 'List size must be greater than 0');
    }

    @IsTest
    static void testCreateMasterPicklistOptionsFromSettings() {

        Test.startTest();
        ProjectAttributeService projectAttributeService = new ProjectAttributeService();
        ObjectMasterPicklistOption__mdt[] objectMasterPicklistOptionList = projectAttributeService.getSettingsForMasterWithDependentSpecializationFields();
        ProjectAttributeService.MasterPicklistOption[] masterPicklistOptionList = projectAttributeService.createMasterPicklistOptionsFromSettings(objectMasterPicklistOptionList);
        Test.stopTest();

        for (ProjectAttributeService.MasterPicklistOption masterPicklistOption : masterPicklistOptionList) {
            System.assertEquals(true, masterPicklistOption.optionApiName.length() > 0);

            if (!masterPicklistOption.specializationPicklistOptionList.isEmpty()) {

                for (ProjectAttributeService.SpecializationPicklistOption specializationPicklistOption : masterPicklistOption.specializationPicklistOptionList) {
                    System.assertEquals(true, specializationPicklistOption.optionApiName.length() > 0);
                }
            }
        }

        System.assertEquals(true, masterPicklistOptionList.size() > 0, 'List size must be greater than 0');
    }

    @IsTest
    static void testGetProjectAttributesBasedOnPicklistOptions() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];
        Map<Object, Schema.PicklistEntry[]> masterValueToDependentPicklistEntriesMap = Util.getMapWithActiveMasterValueToDependentPicklistEntries(ProjectAttributeSelector.SPECIALIZATION_SOBJECT_FIELD);

        Project_attribute__c[] projectAttributeList = ProjectAttributeTestService.createPAsWithRTSpecializationForAllPicklistOptions(project.Id, masterValueToDependentPicklistEntriesMap);
        insert projectAttributeList;

        Test.startTest();
        ProjectAttributeService projectAttributeService = new ProjectAttributeService();
        ObjectMasterPicklistOption__mdt[] objectMasterPicklistOptionList = projectAttributeService.getSettingsForMasterWithDependentSpecializationFields();
        ProjectAttributeService.MasterPicklistOption[] masterPicklistOptionList = projectAttributeService.createMasterPicklistOptionsFromSettings(objectMasterPicklistOptionList);
        Project_attribute__c[] projectAttributeBasedOnOptionsList = projectAttributeService.getProjectAttributesBasedOnPicklistOptions(project.Id, masterPicklistOptionList);
        Test.stopTest();

        System.assertEquals(true, projectAttributeBasedOnOptionsList.size() > 0, 'List size must be greater than 0');
    }

    @IsTest
    static void testAddDataToOptionsFromProjectAttributeRecords() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];
        Map<Object, Schema.PicklistEntry[]> masterValueToDependentPicklistEntriesMap = Util.getMapWithActiveMasterValueToDependentPicklistEntries(ProjectAttributeSelector.SPECIALIZATION_SOBJECT_FIELD);

        Project_attribute__c[] projectAttributeList = ProjectAttributeTestService.createPAsWithRTSpecializationForAllPicklistOptions(project.Id, masterValueToDependentPicklistEntriesMap);
        insert projectAttributeList;

        Test.startTest();
        ProjectAttributeService projectAttributeService = new ProjectAttributeService();
        ObjectMasterPicklistOption__mdt[] objectMasterPicklistOptionList = projectAttributeService.getSettingsForMasterWithDependentSpecializationFields();
        ProjectAttributeService.MasterPicklistOption[] masterPicklistOptionList = projectAttributeService.createMasterPicklistOptionsFromSettings(objectMasterPicklistOptionList);
        Project_attribute__c[] projectAttributeBasedOnOptionsList = projectAttributeService.getProjectAttributesBasedOnPicklistOptions(project.Id, masterPicklistOptionList);
        masterPicklistOptionList = projectAttributeService.addDataToOptionsFromProjectAttributeRecords(masterPicklistOptionList, projectAttributeBasedOnOptionsList);
        Test.stopTest();

        for (ProjectAttributeService.MasterPicklistOption masterPicklistOption : masterPicklistOptionList) {

            if (!masterPicklistOption.specializationPicklistOptionList.isEmpty()) {

                for (ProjectAttributeService.SpecializationPicklistOption specializationPicklistOption : masterPicklistOption.specializationPicklistOptionList) {
                    System.assertEquals(true, specializationPicklistOption.isSelected, 'Specialization picklist option must be selected!');
                }
            }
        }

        System.assertEquals(true, masterPicklistOptionList.size() > 0, 'List size must be greater than 0');
    }

    @IsTest
    static void testGetCurrentMasterWithSpecializationsOptionsByProjectId() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];

        Test.startTest();
        ProjectAttributeService projectAttributeService = new ProjectAttributeService();
        ProjectAttributeService.MasterPicklistOption[] masterPicklistOptionList = projectAttributeService.getCurrentMasterWithSpecializationsOptionsByProjectId(project.Id);
        Test.stopTest();

        for (ProjectAttributeService.MasterPicklistOption masterPicklistOption : masterPicklistOptionList) {
            System.assertEquals(true, masterPicklistOption.optionApiName.length() > 0);

            if (!masterPicklistOption.specializationPicklistOptionList.isEmpty()) {

                for (ProjectAttributeService.SpecializationPicklistOption specializationPicklistOption : masterPicklistOption.specializationPicklistOptionList) {
                    System.assertEquals(true, specializationPicklistOption.optionApiName.length() > 0);
                }
            }
        }

        System.assertEquals(true, masterPicklistOptionList.size() > 0, 'List size must be greater than 0');
    }

    @IsTest
    static void testGetProjectAssessmentsComponentTitleInfo() {
        Test.startTest();
        ProjectAttributeService projectAttributeService = new ProjectAttributeService();
        ProjectAttributeService.ProjectAssessmentsComponentTitleInfo projectAssessmentsComponentTitleInfo = projectAttributeService.getProjectAssessmentsComponentTitleInfo();
        Test.stopTest();

        System.assertEquals(PROJECT_ATTRIBUTE_SOBJECT_TYPE.getDescribe().getLabel(), projectAssessmentsComponentTitleInfo.projectAttributeLabel, 'Values must be the same size!');
    }

    @IsTest
    static void testGetProjectAssessmentsForRelatedList() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];
        Project_attribute__c[] projectAttributeList = (Project_attribute__c[]) TestDataFactory.createSObjectList(new Project_attribute__c(Project__c = project.Id, RecordTypeId = ProjectAttributeSelector.PROJECT_ATTRIBUTE_RECORD_TYPE_ASSESSMENT_ID), 10, true);

        Test.startTest();
        ProjectAttributeService projectAttributeService = new ProjectAttributeService();
        ProjectAttributeService.ProjectAssessmentsDataTableWrapper projectAssessmentsRelatedListInitData = projectAttributeService.getProjectAssessmentsForRelatedList(project.Id);
        Test.stopTest();

        System.assertEquals(projectAttributeList.size(), projectAssessmentsRelatedListInitData.recordsList.size(), 'Lists must be the same size!');

    }

    @IsTest
    static void testGetFieldTypesDescribe() {
        //TODO need refactoring
        List<String> projectAttributeFieldList = new List<String>{
                'Project__r.Name', 'Status__c'
        };

        Test.startTest();
        ProjectAttributeService projectAttributeService = new ProjectAttributeService();
        Map<String, String> fieldSetFieldsDescribe = projectAttributeService.getFieldTypesDescribe(projectAttributeFieldList, PROJECT_ATTRIBUTE_SOBJECT_TYPE.getDescribe().getName());
        Test.stopTest();

        System.assertEquals('REFERENCE', fieldSetFieldsDescribe.get('Project Name'), 'Lists must be the same size!');
        System.assertEquals('PICKLIST', fieldSetFieldsDescribe.get('Status'), 'Lists must be the same size!');

    }

    @IsTest
    static void testHasSomeoneMadeChangesToAttributes() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];

        ProjectAttributeService projectAttributeService = new ProjectAttributeService();
        ProjectAttributeService.MasterPicklistOption[] masterPicklistOptionList = projectAttributeService.getCurrentMasterWithSpecializationsOptionsByProjectId(project.Id);

        for (ProjectAttributeService.MasterPicklistOption masterPicklistOption : masterPicklistOptionList) {

            if (!masterPicklistOption.specializationPicklistOptionList.isEmpty()) {

                for (ProjectAttributeService.SpecializationPicklistOption specializationPicklistOption : masterPicklistOption.specializationPicklistOptionList) {
                    specializationPicklistOption.isSelected = true;
                }
            }
        }

        Test.startTest();
        Boolean hasSomeoneMadeChangesToAttributes = projectAttributeService.hasSomeoneMadeChangesToAttributes(project.Id, JSON.serialize(masterPicklistOptionList));
        Test.stopTest();

        System.assertEquals(true, hasSomeoneMadeChangesToAttributes, 'List size must be greater than 0');
    }

    @IsTest
    static void testChangeProjectAttributes_Create() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];
        ProjectAttributeService projectAttributeService = new ProjectAttributeService();
        ProjectAttributeService.MasterPicklistOption[] masterPicklistOptionList = projectAttributeService.getCurrentMasterWithSpecializationsOptionsByProjectId(project.Id);

        Integer toCreateRecordCount = 0;
        for (ProjectAttributeService.MasterPicklistOption masterPicklistOption : masterPicklistOptionList) {

            if (!masterPicklistOption.specializationPicklistOptionList.isEmpty()) {

                for (ProjectAttributeService.SpecializationPicklistOption specializationPicklistOption : masterPicklistOption.specializationPicklistOptionList) {
                    // create all attributes
                    specializationPicklistOption.isSelected = true;
                    toCreateRecordCount++;
                }
            }
        }

        Test.startTest();
        projectAttributeService.changeProjectAttributes(project.Id, masterPicklistOptionList);
        Test.stopTest();

        Project_attribute__c[] afterChange_projectAttributeList = [SELECT Id FROM Project_attribute__c];

        System.assertEquals(toCreateRecordCount, afterChange_projectAttributeList.size(), 'Attributes should have been created!');
    }

    @IsTest
    static void testChangeProjectAttributes_Delete() {
        //addada
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];
        ProjectAttributeService projectAttributeService = new ProjectAttributeService();

        // to create
        ProjectAttributeService.MasterPicklistOption[] toCreate_masterPicklistOptionList = projectAttributeService.getCurrentMasterWithSpecializationsOptionsByProjectId(project.Id);

        Integer toCreateRecordCount = 0;
        for (ProjectAttributeService.MasterPicklistOption masterPicklistOption : toCreate_masterPicklistOptionList) {

            if (!masterPicklistOption.specializationPicklistOptionList.isEmpty()) {

                for (ProjectAttributeService.SpecializationPicklistOption specializationPicklistOption : masterPicklistOption.specializationPicklistOptionList) {
                    // create all attributes
                    specializationPicklistOption.isSelected = true;
                    toCreateRecordCount++;
                }
            }
        }

        projectAttributeService.changeProjectAttributes(project.Id, toCreate_masterPicklistOptionList);

        Project_attribute__c[] afterCreate_projectAttributeList = [SELECT Id FROM Project_attribute__c];
        System.assertEquals(toCreateRecordCount, afterCreate_projectAttributeList.size(), 'Attributes should have been created!');

        // to delete
        ProjectAttributeService.MasterPicklistOption[] toDelete_masterPicklistOptionList = projectAttributeService.getCurrentMasterWithSpecializationsOptionsByProjectId(project.Id);

        for (ProjectAttributeService.MasterPicklistOption masterPicklistOption : toDelete_masterPicklistOptionList) {

            if (!masterPicklistOption.specializationPicklistOptionList.isEmpty()) {

                for (ProjectAttributeService.SpecializationPicklistOption specializationPicklistOption : masterPicklistOption.specializationPicklistOptionList) {
                    // delete all attributes
                    specializationPicklistOption.isSelected = false;
                }
            }
        }

        Test.startTest();
        projectAttributeService.changeProjectAttributes(project.Id, toDelete_masterPicklistOptionList);
        Test.stopTest();

        Project_attribute__c[] afterDelete_projectAttributeList = [SELECT Id FROM Project_attribute__c];
        System.assertEquals(0, afterDelete_projectAttributeList.size(), 'Attributes should have been deleted!');
    }

    @IsTest
    static void testThrowExceptionInInnerClassPicklistOption() {
        Map<String, Schema.PicklistEntry> masterPicklistValueToEntryMap = Util.createMapWithPicklistValueToEntry(ProjectAttributeSelector.MASTER_SOBJECT_FIELD.getDescribe().getPicklistValues());
        Map<String, Schema.PicklistEntry> specializationPicklistValueToEntryMap = Util.createMapWithPicklistValueToEntry(ProjectAttributeSelector.SPECIALIZATION_SOBJECT_FIELD.getDescribe().getPicklistValues());

        ProjectAttributeService.MasterPicklistOption masterPicklistOption = new ProjectAttributeService.MasterPicklistOption();
        masterPicklistOption.optionApiName = 'INVALID_API_NAME';
        masterPicklistOption.optionApiName = 'INVALID_API_NAME';
        ProjectAttributeService.SpecializationPicklistOption specializationPicklistOption = new ProjectAttributeService.SpecializationPicklistOption();
        specializationPicklistOption.optionApiName = 'INVALID_API_NAME';

        Test.startTest();
        ProjectAttributeException masterProjectAttributeException;
        ProjectAttributeException specializationProjectAttributeException;

        try {
            masterPicklistOption.addCurrentOptionLabel(masterPicklistValueToEntryMap);
        } catch (ProjectAttributeException exc) {
            masterProjectAttributeException = exc;
        }

        try {
            specializationPicklistOption.addCurrentOptionLabel(specializationPicklistValueToEntryMap);
        } catch (ProjectAttributeException exc) {
            specializationProjectAttributeException = exc;
        }
        Test.stopTest();

        System.assertEquals(
                ProjectAttributeException.ERROR_CODE_OBJECT_PICKLIST_ENTRY_NOT_FOUND,
                masterProjectAttributeException.errorCode,
                'Error code must be ' + ProjectAttributeException.ERROR_CODE_OBJECT_PICKLIST_ENTRY_NOT_FOUND + ' for this exception!'
        );

        System.assertEquals(
                ProjectAttributeException.ERROR_CODE_OBJECT_PICKLIST_ENTRY_NOT_FOUND,
                specializationProjectAttributeException.errorCode,
                'Error code must be ' + ProjectAttributeException.ERROR_CODE_OBJECT_PICKLIST_ENTRY_NOT_FOUND + ' for this exception!'
        );
    }
}