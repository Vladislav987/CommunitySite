/**
 * Created by Lambru Dmytro on 25.03.2020.
 */

@IsTest
private class ProjectAttributeControllerTest {
    private static final String DEFAULT_PROJECT_NAME = 'FOR_TEST';
    private static final String AURA_HANDLED_EXCEPTION_TYPE_NAME = 'System.AuraHandledException';

    @TestSetup
    static void doSetup() {
        TestDataFactory.createSObject(new Project__c(Name = DEFAULT_PROJECT_NAME), true);
    }

    @IsTest
    static void testGetMasterWithSpecializationsOptionsByProjectId() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];
        Map<Object, Schema.PicklistEntry[]> masterValueToSpecializationPicklistEntriesMap = Util.getMapWithActiveMasterValueToDependentPicklistEntries(ProjectAttributeSelector.SPECIALIZATION_SOBJECT_FIELD);

        Test.startTest();
        Model.LightningResponse response = ProjectAttributeController.getMasterWithSpecializationsOptionsByProjectId(project.Id);
        Test.stopTest();

        ProjectAttributeService.MasterPicklistOption[] masterPicklistOptionList = (ProjectAttributeService.MasterPicklistOption[]) JSON.deserialize(response.data, ProjectAttributeService.MasterPicklistOption[].class);

        for (ProjectAttributeService.MasterPicklistOption masterPicklistOption : masterPicklistOptionList) {
            System.assertEquals(true, masterValueToSpecializationPicklistEntriesMap.containsKey((Object) masterPicklistOption.optionApiName), 'Map must contain option API name!');

            if (!masterPicklistOption.specializationPicklistOptionList.isEmpty()) {
                Schema.PicklistEntry[] picklistEntryList = masterValueToSpecializationPicklistEntriesMap.get((Object) masterPicklistOption.optionApiName);

                Boolean isExistSpecializationOptionApiName = false;
                for (ProjectAttributeService.SpecializationPicklistOption specializationPicklistOption : masterPicklistOption.specializationPicklistOptionList) {

                    for (Schema.PicklistEntry picklistEntry : picklistEntryList) {
                        if (picklistEntry.getValue() == specializationPicklistOption.optionApiName) {
                            isExistSpecializationOptionApiName = true;
                        }
                    }
                }

                System.assertEquals(true, isExistSpecializationOptionApiName, 'Specialization picklist option must exist!');
            }
        }


        System.assertEquals(true, response.success, 'Response must be successful!');
    }

    @IsTest
    static void testChangeProjectAttributes_Create() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];
        Model.LightningResponse response = ProjectAttributeController.getMasterWithSpecializationsOptionsByProjectId(project.Id);
        ProjectAttributeService.MasterPicklistOption[] masterPicklistOptionList = (ProjectAttributeService.MasterPicklistOption[]) JSON.deserialize(response.data, ProjectAttributeService.MasterPicklistOption[].class);

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
        Model.LightningResponse responseAfterChange = ProjectAttributeController.changeProjectAttributes(project.Id, response.data, JSON.serialize(masterPicklistOptionList));
        Test.stopTest();

        Project_attribute__c[] afterChange_projectAttributeList = [SELECT Id FROM Project_attribute__c];

        System.assertEquals(toCreateRecordCount, afterChange_projectAttributeList.size(), 'Attributes should have been created!');
        System.assertEquals(true, responseAfterChange.success, 'Response must be successful!');
    }

    @IsTest
    static void testChangeProjectAttributes_DeletePart() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];
        createAttributesForAllOptionsFromSettings();

        Model.LightningResponse response = ProjectAttributeController.getMasterWithSpecializationsOptionsByProjectId(project.Id);
        ProjectAttributeService.MasterPicklistOption[] masterPicklistOptionList = (ProjectAttributeService.MasterPicklistOption[]) JSON.deserialize(response.data, ProjectAttributeService.MasterPicklistOption[].class);

        Integer toDeleteRecordCount = 0;
        ProjectAttributeService.MasterPicklistOption[] toDelete_masterPicklistOptionList = new ProjectAttributeService.MasterPicklistOption[]{
        };
        for (ProjectAttributeService.MasterPicklistOption masterPicklistOption : masterPicklistOptionList) {
            ProjectAttributeService.MasterPicklistOption toDelete_masterPicklistOption = masterPicklistOption.clone();

            if (!masterPicklistOption.specializationPicklistOptionList.isEmpty()) {

                for (ProjectAttributeService.SpecializationPicklistOption specializationPicklistOption : masterPicklistOption.specializationPicklistOptionList) {
                    // delete first only
                    specializationPicklistOption.isSelected = false;
                    ProjectAttributeService.SpecializationPicklistOption toDelete_specializationPicklistOption = specializationPicklistOption.clone();
                    toDelete_masterPicklistOption.specializationPicklistOptionList = new ProjectAttributeService.SpecializationPicklistOption[]{
                            toDelete_specializationPicklistOption
                    };
                    toDeleteRecordCount++;
                    break;
                }
            }

            toDelete_masterPicklistOptionList.add(toDelete_masterPicklistOption);
        }

        Project_attribute__c[] beforeChange_projectAttributeList = [SELECT Id FROM Project_attribute__c];

        Test.startTest();
        Model.LightningResponse responseAfterChange = ProjectAttributeController.changeProjectAttributes(project.Id, response.data, JSON.serialize(toDelete_masterPicklistOptionList));
        Test.stopTest();

        Project_attribute__c[] afterChange_projectAttributeList = [SELECT Id FROM Project_attribute__c];

        System.assertEquals(beforeChange_projectAttributeList.size() - toDeleteRecordCount, afterChange_projectAttributeList.size(), 'Attributes should have been changed!');
        System.assertEquals(true, responseAfterChange.success, 'Response must be successful!');
    }

    @IsTest
    static void testChangeProjectAttributes_Delete() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];
        createAttributesForAllOptionsFromSettings();

        Model.LightningResponse response = ProjectAttributeController.getMasterWithSpecializationsOptionsByProjectId(project.Id);
        ProjectAttributeService.MasterPicklistOption[] masterPicklistOptionList = (ProjectAttributeService.MasterPicklistOption[]) JSON.deserialize(response.data, ProjectAttributeService.MasterPicklistOption[].class);

        for (ProjectAttributeService.MasterPicklistOption masterPicklistOption : masterPicklistOptionList) {

            if (!masterPicklistOption.specializationPicklistOptionList.isEmpty()) {

                for (ProjectAttributeService.SpecializationPicklistOption specializationPicklistOption : masterPicklistOption.specializationPicklistOptionList) {
                    // to delete all attributes
                    specializationPicklistOption.isSelected = false;
                }
            }
        }

        Test.startTest();
        Model.LightningResponse responseAfterChange = ProjectAttributeController.changeProjectAttributes(project.Id, response.data, JSON.serialize(masterPicklistOptionList));
        Test.stopTest();

        Project_attribute__c[] projectAttributeList = [SELECT Id FROM Project_attribute__c];

        System.assertEquals(0, projectAttributeList.size(), 'Attributes should have been deleted!');
        System.assertEquals(true, responseAfterChange.success, 'Response must be successful!');
    }

    /**
     * @description Test that someone has already made changes.
     */
    @IsTest
    static void testErrorCodeOnAttributesAlreadyChanged() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];
        Model.LightningResponse response = ProjectAttributeController.getMasterWithSpecializationsOptionsByProjectId(project.Id);
        ProjectAttributeService.MasterPicklistOption[] masterPicklistOptionList = (ProjectAttributeService.MasterPicklistOption[]) JSON.deserialize(response.data, ProjectAttributeService.MasterPicklistOption[].class);

        for (ProjectAttributeService.MasterPicklistOption masterPicklistOption : masterPicklistOptionList) {

            if (!masterPicklistOption.specializationPicklistOptionList.isEmpty()) {

                for (ProjectAttributeService.SpecializationPicklistOption specializationPicklistOption : masterPicklistOption.specializationPicklistOptionList) {
                    specializationPicklistOption.isSelected = true;
                }
            }
        }

        Test.startTest();
        Model.LightningResponse afterChange_response = ProjectAttributeController.changeProjectAttributes(project.Id, JSON.serialize(masterPicklistOptionList), JSON.serialize(masterPicklistOptionList));
        Test.stopTest();

        System.assertEquals(
                ProjectAttributeException.ERROR_CODE_ATTRIBUTES_ALREADY_CHANGED,
                afterChange_response.code,
                'Error code must be ' + ProjectAttributeException.ERROR_CODE_ATTRIBUTES_ALREADY_CHANGED + ' for this exception!'
        );
    }

    @IsTest
    static void dummyInnerClassLightningResponseTest() {
        ProjectAttributeController.LightningResponse lightningResponse = new ProjectAttributeController.LightningResponse();
        lightningResponse.setResult('data');
        lightningResponse.setError(1234);
        lightningResponse.setError('msg');
        lightningResponse.setError(1234, 'msg');
    }

    @IsTest
    static void testGetProjectAssessmentsRelatedListInitData() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];
        Project_attribute__c[] projectAttributeList = (Project_attribute__c[]) TestDataFactory.createSObjectList(new Project_attribute__c(Project__c = project.Id, RecordTypeId = ProjectAttributeSelector.PROJECT_ATTRIBUTE_RECORD_TYPE_ASSESSMENT_ID), 10, true);


        Test.startTest();
        ProjectAttributeController.ProjectAssessmentsRelatedListInfo selectedProjectAttributeList = ProjectAttributeController.getProjectAssessmentsRelatedListInitData(project.Id);
        Test.stopTest();

        System.assertEquals(projectAttributeList.size(), selectedProjectAttributeList.dataTable.recordsList.size(), 'Lists must be the same size!');
        System.assertEquals(ProjectAttributeSelector.PROJECT_ATTRIBUTE_SOBJECT_TYPE.getDescribe().getLabel(), selectedProjectAttributeList.componentTitleInfo.projectAttributeLabel, 'Values must be the same size!');

    }

    @IsTest
    private static void getProjectAssessmentsRelatedListInitDataErrorTest() {
        Account acc = new Account(Name = 'acc name 1');

        String exceptionTypeName;
        Test.startTest();

        try {
            ProjectAttributeController.ProjectAssessmentsRelatedListInfo selectedProjectAttributeList = ProjectAttributeController.getProjectAssessmentsRelatedListInitData(acc.Id);
        } catch (Exception e) {
            exceptionTypeName = e.getTypeName();
        }

        Test.stopTest();
        System.assertEquals(AURA_HANDLED_EXCEPTION_TYPE_NAME, exceptionTypeName);
    }

    /******************/
    /* HELPER METHODS */
    /******************/

    static void createAttributesForAllOptionsFromSettings() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :DEFAULT_PROJECT_NAME];
        Model.LightningResponse response = ProjectAttributeController.getMasterWithSpecializationsOptionsByProjectId(project.Id);

        ProjectAttributeService.MasterPicklistOption[] masterPicklistOptionList = (ProjectAttributeService.MasterPicklistOption[]) JSON.deserialize(response.data, ProjectAttributeService.MasterPicklistOption[].class);

        for (ProjectAttributeService.MasterPicklistOption masterPicklistOption : masterPicklistOptionList) {

            if (!masterPicklistOption.specializationPicklistOptionList.isEmpty()) {

                for (ProjectAttributeService.SpecializationPicklistOption specializationPicklistOption : masterPicklistOption.specializationPicklistOptionList) {
                    // create all attributes
                    specializationPicklistOption.isSelected = true;
                }
            }
        }

        // create attributes for all options
        ProjectAttributeController.changeProjectAttributes(project.Id, response.data, JSON.serialize(masterPicklistOptionList));
    }
}