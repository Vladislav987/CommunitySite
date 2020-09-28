/**
 * Created by Lambru Dmytro on 20.03.2020.
 */

public without sharing class ProjectAttributeService {


    private ProjectAttributeSelector projectAttributeSelector = new ProjectAttributeSelector();

    public static final Schema.SObjectType PROJECT_ATTRIBUTE_SOBJECT_TYPE = Schema.Project_attribute__c.SObjectType;
    public static final Schema.SObjectField MASTER_SOBJECT_FIELD = Schema.Project_attribute__c.Master__c;
    public static final Schema.SObjectField SPECIALIZATION_SOBJECT_FIELD = Schema.Project_attribute__c.Specialization__c;

    private static final Id PROJECT_ATTRIBUTE_RECORD_TYPE_SPECIALIZATION_ID = PROJECT_ATTRIBUTE_SOBJECT_TYPE.getDescribe().getRecordTypeInfosByDeveloperName().get('Specialization').getRecordTypeId();

    private static final String PROJECT_ATTRIBUTE_API_NAME = PROJECT_ATTRIBUTE_SOBJECT_TYPE.getDescribe().getName();
    private static final String PROJECT_ATTRIBUTE_LABEL_PLURAL = PROJECT_ATTRIBUTE_SOBJECT_TYPE.getDescribe().getLabelPlural();
    private static final String PROJECT_ATTRIBUTE_LABEL = PROJECT_ATTRIBUTE_SOBJECT_TYPE.getDescribe().getLabel();
    private static final String PROJECT_ATTRIBUTE_FIELDSET_NAME = 'Related_List_Fields_For_Project';
    private static final Id PROJECT_ATTRIBUTE_RECORD_TYPE_ASSESSMENT_ID = PROJECT_ATTRIBUTE_SOBJECT_TYPE.getDescribe().getRecordTypeInfosByDeveloperName().get('Assessment').getRecordTypeId();
    private static final String PROJECT_ATTRIBUTE_RECORD_TYPE_ASSESSMENT_NAME = PROJECT_ATTRIBUTE_SOBJECT_TYPE.getDescribe().getRecordTypeInfosByDeveloperName().get('Assessment').getName();

    private static final String FIELDSET_NOT_FOUND = 'Fieldset not found.';
    private static final String FIELDSET_DOES_NOT_CONTAIN_REQUIRED_FIELDS = 'Fieldset does not contain required fields.';
    private static final String PROJECT_ID_IS_BLANK = 'Project Id is blank.';

    public MasterPicklistOption[] getCurrentMasterWithSpecializationsOptionsByProjectId(Id projectId) {
        ObjectMasterPicklistOption__mdt[] objectMasterPicklistOptionSettingsList = this.getSettingsForMasterWithDependentSpecializationFields();
        MasterPicklistOption[] masterPicklistOptionList = this.createMasterPicklistOptionsFromSettings(objectMasterPicklistOptionSettingsList);
        Project_attribute__c[] projectAttributeList = this.getProjectAttributesBasedOnPicklistOptions(projectId, masterPicklistOptionList);
        masterPicklistOptionList = this.addDataToOptionsFromProjectAttributeRecords(masterPicklistOptionList, projectAttributeList);

        return masterPicklistOptionList;
    }

    public Boolean hasSomeoneMadeChangesToAttributes(Id projectId, String beforeChangesJsonMasterPicklistOptionList) {
        MasterPicklistOption[] currentMasterPicklistOptionList = this.getCurrentMasterWithSpecializationsOptionsByProjectId(projectId);
        String currentJsonMasterPicklistOptionList = JSON.serialize(currentMasterPicklistOptionList);

        return (currentJsonMasterPicklistOptionList != beforeChangesJsonMasterPicklistOptionList);
    }

    public void changeProjectAttributes(Id projectId, MasterPicklistOption[] projectAttributeMasterOptionList) {
        Set<Id> projectAttributeIdToDeleteSet = new Set<Id>();
        Project_attribute__c[] projectAttributeToCreateList = new Project_attribute__c[]{
        };

        if (projectAttributeMasterOptionList != null && !projectAttributeMasterOptionList.isEmpty()) {

            for (MasterPicklistOption projectAttributeMasterOption : projectAttributeMasterOptionList) {

                for (SpecializationPicklistOption projectAttributeSpecializationOption : projectAttributeMasterOption.specializationPicklistOptionList) {

                    if (projectAttributeSpecializationOption.isSelected == true) {
                        Project_attribute__c projectAttributeToCreate = new Project_attribute__c(
                                RecordTypeId = PROJECT_ATTRIBUTE_RECORD_TYPE_SPECIALIZATION_ID,
                                Project__c = projectId,
                                Master__c = projectAttributeMasterOption.optionApiName,
                                Specialization__c = projectAttributeSpecializationOption.optionApiName
                        );
                        // add new attribute to create
                        projectAttributeToCreateList.add(projectAttributeToCreate);
                    } else if (projectAttributeSpecializationOption.isSelected == false
                            && Util.isValidIdForSObject(projectAttributeSpecializationOption.projectAttributeRecordId, PROJECT_ATTRIBUTE_SOBJECT_TYPE)) {
                        // add id for deleting
                        projectAttributeIdToDeleteSet.add(projectAttributeSpecializationOption.projectAttributeRecordId);
                    }
                }
            }

            if (!projectAttributeIdToDeleteSet.isEmpty()) {
                Project_attribute__c[] projectAttributeToDeleteList = projectAttributeSelector.getByIdSet(projectAttributeIdToDeleteSet);
                delete projectAttributeToDeleteList;
            }

            if (!projectAttributeToCreateList.isEmpty()) {
                insert projectAttributeToCreateList;
            }
        }
    }

    public ProjectAssessmentsComponentTitleInfo getProjectAssessmentsComponentTitleInfo() {
        ProjectAssessmentsComponentTitleInfo componentTitleInfo = new ProjectAssessmentsComponentTitleInfo();
        componentTitleInfo.assessmentRecordTypeId = PROJECT_ATTRIBUTE_RECORD_TYPE_ASSESSMENT_ID;
        componentTitleInfo.assessmentRecordTypeName = PROJECT_ATTRIBUTE_RECORD_TYPE_ASSESSMENT_NAME;
        componentTitleInfo.projectAttributeLabelPlural = PROJECT_ATTRIBUTE_LABEL_PLURAL;
        componentTitleInfo.projectAttributeLabel = PROJECT_ATTRIBUTE_LABEL;
        return componentTitleInfo;
    }

    public ProjectAssessmentsDataTableWrapper getProjectAssessmentsForRelatedList(Id projectId) {
        if (String.isBlank(projectId)) {
            throw new IllegalArgumentException(PROJECT_ID_IS_BLANK);
        }
        if (!Schema.SObjectType.Project_attribute__c.fieldSets.getMap().containsKey(PROJECT_ATTRIBUTE_FIELDSET_NAME)) {
            throw new SObjectException(FIELDSET_NOT_FOUND);
        }

        String sObjectName = PROJECT_ATTRIBUTE_SOBJECT_TYPE.getDescribe().getName();
        List<String> fieldsApiNames = getFieldApiNamesFromFieldset();
        List<String> fieldApiNamesForQuery = fieldsApiNames.clone();
        fieldApiNamesForQuery.add(Project_attribute__c.Status__c.getDescribe().getName());

        ProjectAssessmentsDataTableWrapper dataTable = new ProjectAssessmentsDataTableWrapper();
        dataTable.recordsList = projectAttributeSelector.getProjectAttributesForAssessmentRT(fieldApiNamesForQuery, projectId);
        dataTable.fieldsList = getFieldApiNamesWithLabels(PROJECT_ATTRIBUTE_FIELDSET_NAME);
        dataTable.fieldsTypes = getFieldTypesDescribe(dataTable.fieldsList.values(), sObjectName);

        return dataTable;
    }

    @TestVisible
    private Map<String, String> getFieldApiNamesWithLabels(String fieldset) {
        Map<String, String> fieldsLabelAndPath = new Map<String, String>();
        Map<String, Schema.FieldSet> fieldSetMap = Schema.getGlobalDescribe().get(PROJECT_ATTRIBUTE_API_NAME).getDescribe().fieldSets.getMap();
        for (FieldSetMember field : fieldSetMap.get(fieldset).getFields()) {
            if (field.getFieldPath().contains('.')) {
                String fieldLabel = getLabelOfFieldWithParentRelationship(field.getFieldPath());
                fieldsLabelAndPath.put(fieldLabel, field.getFieldPath());
            } else {
                fieldsLabelAndPath.put(field.getLabel(), field.getFieldPath());
            }
        }

        return fieldsLabelAndPath;
    }

    private List<String> getFieldApiNamesFromFieldset() {
        List<String> fieldApiNames = new List<String>();
        for (Schema.FieldSetMember field : Schema.SObjectType.Project_attribute__c.fieldSets.getMap().get(PROJECT_ATTRIBUTE_FIELDSET_NAME).getFields()) {
            fieldApiNames.add(field.getFieldPath());
        }
        return fieldApiNames;
    }

    @TestVisible
    private Map<String, String> getFieldTypesDescribe(List<String> fieldsApiNames, String sObjectName) {
        Map<String, String> fieldsLabelsAndType = new Map<String, String>();
        for (String fieldApi : fieldsApiNames) {
            if (fieldApi.contains('.')) {
                String fieldLabel = getLabelOfFieldWithParentRelationship(fieldApi);
                fieldsLabelsAndType.put(fieldLabel, String.valueOf(Schema.DisplayType.REFERENCE));
                continue;
            }

            Schema.DisplayType type = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().get(fieldApi).getDescribe().getType();
            String label = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().get(fieldApi).getDescribe().getLabel();
            fieldsLabelsAndType.put(label, String.valueOf(type));
        }

        return fieldsLabelsAndType;
    }

    private String getLabelOfFieldWithParentRelationship(String fieldPath) {
        String fieldAPIName = fieldPath.substringAfterLast('.');          //customobject__r.customobject2__r.Name ----> Name
        fieldPath = fieldPath.removeEnd('.' + fieldAPIName);              //customobject__r.customobject2__r.Name ----> Customobject__r.customobject2__r
        String objectTokenPath;                                           //SObject token used in SOQL
        String objectAPIName;                                             //SObject API Name
        String objectLabel;                                               //SObject Label
        String fieldLabel;                                                //Returning field label

        if (fieldPath.contains('.')) {
            objectTokenPath = fieldPath.substringAfterLast('.');          //customobject__r.customobject2__r ----> customobject2__r
        } else {
            objectTokenPath = fieldPath;
        }

        if (objectTokenPath.contains('__r')) {
            objectTokenPath = objectTokenPath.removeEnd('r') + 'c';        //customobject2__r ----> customobject2__c
        }

        if (objectTokenPath.equalsIgnoreCase('LastModifiedBy') || objectTokenPath.equalsIgnoreCase('CreatedBy')) {
            objectAPIName = Schema.getGlobalDescribe().get('User').getDescribe().getName();                             //if we fetch through standard lookup parent field, i.e 'CreatedBy',
            objectLabel = Schema.getGlobalDescribe().get('User').getDescribe().getLabel();                              //which is originally User lookup
        } else {
            objectAPIName = Schema.getGlobalDescribe().get(objectTokenPath).getDescribe().getName();
            objectLabel = Schema.getGlobalDescribe().get(objectTokenPath).getDescribe().getLabel();
        }

        fieldLabel = Schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap().get(fieldAPIName).getDescribe().getLabel();
        if (!fieldLabel.contains(objectLabel)) {
            fieldLabel = objectLabel + ' ' + fieldLabel;                                                                //If we retreive field without object label in it's own label
        }                                                                                                               //Example got 'Name' from Customobj__c and change to 'Customobj Name'
        if (objectTokenPath.equalsIgnoreCase('LastModifiedBy') || objectTokenPath.equalsIgnoreCase('CreatedBy')) {
            fieldLabel = objectTokenPath + fieldLabel;                                                                  //If we retreive field without Standard object label in it's own label
        }                                                                                                               //Example got 'First Name' from CreatedBy and change to 'CreatedBy First Name'
        return fieldLabel;
    }

    public class ProjectAssessmentsDataTableWrapper {
        @AuraEnabled
        public List<Project_attribute__c> recordsList { get; set; }
        @AuraEnabled
        public Map<String, String> fieldsList { get; set; }
        @AuraEnabled
        public Map<String, String> fieldsTypes { get; set; }
    }

    public class ProjectAssessmentsComponentTitleInfo {
        @AuraEnabled
        public Id assessmentRecordTypeId { get; set; }
        @AuraEnabled
        public String assessmentRecordTypeName { get; set; }
        @AuraEnabled
        public String projectAttributeLabelPlural { get; set; }
        @AuraEnabled
        public String projectAttributeLabel { get; set; }
    }


    /*******************/
    /* PRIVATE METHODS */
    /*******************/

    @TestVisible
    private ObjectMasterPicklistOption__mdt[] getSettingsForMasterWithDependentSpecializationFields() {

        return [
                SELECT Id,
                        ObjectApiName__c,
                        FieldApiName__c,
                        OptionApiName__c, (
                        SELECT ObjectApiName__c, FieldApiName__c, OptionApiName__c
                        FROM ObjectDependentPicklistOptions__r
                        WHERE IsActive__c = TRUE
                        AND ObjectApiName__c = :PROJECT_ATTRIBUTE_SOBJECT_TYPE.getDescribe().getName()
                        AND FieldApiName__c = :SPECIALIZATION_SOBJECT_FIELD.getDescribe().getName()
                )
                FROM ObjectMasterPicklistOption__mdt
                WHERE IsActive__c = TRUE
                AND ObjectApiName__c = :PROJECT_ATTRIBUTE_SOBJECT_TYPE.getDescribe().getName()
                AND FieldApiName__c = :MASTER_SOBJECT_FIELD.getDescribe().getName()
        ];
    }

    @TestVisible
    private MasterPicklistOption[] createMasterPicklistOptionsFromSettings(ObjectMasterPicklistOption__mdt[] objectMasterPicklistOptionSettingsList) {
        MasterPicklistOption[] masterPicklistOptionList = new MasterPicklistOption[]{
        };

        if (!objectMasterPicklistOptionSettingsList.isEmpty()) {
            Map<String, Schema.PicklistEntry> masterPicklistValueToEntryMap = Util.createMapWithPicklistValueToEntry(MASTER_SOBJECT_FIELD.getDescribe().getPicklistValues());
            Map<String, Schema.PicklistEntry> specializationPicklistValueToEntryMap = Util.createMapWithPicklistValueToEntry(SPECIALIZATION_SOBJECT_FIELD.getDescribe().getPicklistValues());

            for (ObjectMasterPicklistOption__mdt objectMasterPicklistOptionSettings : objectMasterPicklistOptionSettingsList) {
                MasterPicklistOption masterPicklistOption = new MasterPicklistOption();

                masterPicklistOption.fillDataFromSettings(objectMasterPicklistOptionSettings);
                masterPicklistOption.addCurrentOptionLabel(masterPicklistValueToEntryMap);
                masterPicklistOption.specializationPicklistOptionList = this.createSpecializationPicklistOptionsFromSettings(specializationPicklistValueToEntryMap, objectMasterPicklistOptionSettings.ObjectDependentPicklistOptions__r);

                masterPicklistOptionList.add(masterPicklistOption);
            }
        }

        return masterPicklistOptionList;
    }

    @TestVisible
    private Project_attribute__c[] getProjectAttributesBasedOnPicklistOptions(Id projectId, MasterPicklistOption[] projectAttributeMasterOptionList) {
        Project_attribute__c[] projectAttributeList = new Project_attribute__c[]{
        };
        Map<String, Set<String>> fieldNameToPicklistOptionApiNamesMap = this.createMapWithFieldNameToPicklistOptionApiNames(projectAttributeMasterOptionList);
        if (!fieldNameToPicklistOptionApiNamesMap.isEmpty()) {

            projectAttributeList = projectAttributeSelector.getWithRTSpecializationAndSpecifiedPicklistOptionsByProjectId(
                    projectId,
                    fieldNameToPicklistOptionApiNamesMap.get(MASTER_SOBJECT_FIELD.getDescribe().getName()),
                    fieldNameToPicklistOptionApiNamesMap.get(SPECIALIZATION_SOBJECT_FIELD.getDescribe().getName())
            );
        }

        return projectAttributeList;
    }

    @TestVisible
    private MasterPicklistOption[] addDataToOptionsFromProjectAttributeRecords(MasterPicklistOption[] projectAttributeMasterOptionList, Project_attribute__c[] projectAttributeList) {

        if (!projectAttributeMasterOptionList.isEmpty() && !projectAttributeList.isEmpty()) {

            for (MasterPicklistOption projectAttributeMasterOption : projectAttributeMasterOptionList) {

                for (SpecializationPicklistOption projectAttributeSpecializationOption : projectAttributeMasterOption.specializationPicklistOptionList) {

                    Project_attribute__c existingProjectAttribute = this.findProjectAttributeWithMasterAndSpecialization(
                            projectAttributeList,
                            projectAttributeMasterOption.optionApiName,
                            projectAttributeSpecializationOption.optionApiName
                    );

                    if (existingProjectAttribute != null) {
                        projectAttributeMasterOption.isSelected = true;
                        projectAttributeSpecializationOption.isSelected = true;
                        projectAttributeSpecializationOption.projectAttributeRecordId = existingProjectAttribute.Id;
                    }
                }
            }
        }

        return projectAttributeMasterOptionList;
    }

    private SpecializationPicklistOption[] createSpecializationPicklistOptionsFromSettings(Map<String, Schema.PicklistEntry> specializationPicklistValueToEntryMap, ObjectDependentPicklistOption__mdt[] objectDependentPicklistOptionSettingsList) {
        SpecializationPicklistOption[] specializationPicklistOptionList = new SpecializationPicklistOption[]{
        };

        for (ObjectDependentPicklistOption__mdt objectDependentPicklistOption : objectDependentPicklistOptionSettingsList) {
            SpecializationPicklistOption specializationPicklistOption = new SpecializationPicklistOption();

            specializationPicklistOption.fillDataFromSettings(objectDependentPicklistOption);
            specializationPicklistOption.addCurrentOptionLabel(specializationPicklistValueToEntryMap);

            specializationPicklistOptionList.add(specializationPicklistOption);
        }

        return specializationPicklistOptionList;
    }

    private Map<String, Set<String>> createMapWithFieldNameToPicklistOptionApiNames(MasterPicklistOption[] projectAttributeMasterOptionList) {
        Map<String, Set<String>> fieldNameToPicklistOptionApiNamesMap = new Map<String, Set<String>>();

        for (MasterPicklistOption projectAttributeMasterOption : projectAttributeMasterOptionList) {
            this.addOptionApiNameToSetInMap(fieldNameToPicklistOptionApiNamesMap, projectAttributeMasterOption);

            for (SpecializationPicklistOption projectAttributeSpecializationOption : projectAttributeMasterOption.specializationPicklistOptionList) {
                this.addOptionApiNameToSetInMap(fieldNameToPicklistOptionApiNamesMap, projectAttributeSpecializationOption);
            }
        }

        return fieldNameToPicklistOptionApiNamesMap;
    }

    private void addOptionApiNameToSetInMap(Map<String, Set<String>> fieldNameToPicklistOptionApiNamesMap, PicklistOption projectAttributePicklistOption) {

        if (fieldNameToPicklistOptionApiNamesMap.containsKey(projectAttributePicklistOption.fieldApiName)) {
            fieldNameToPicklistOptionApiNamesMap.get(projectAttributePicklistOption.fieldApiName).add(projectAttributePicklistOption.optionApiName);
        } else {
            Set<String> picklistOptionApiNameSet = new Set<String>{
                    projectAttributePicklistOption.optionApiName
            };
            fieldNameToPicklistOptionApiNamesMap.put(projectAttributePicklistOption.fieldApiName, picklistOptionApiNameSet);
        }
    }

    private Project_attribute__c findProjectAttributeWithMasterAndSpecialization(Project_attribute__c[] projectAttributeList, String masterOptionApiName, String specializationOptionApiName) {
        Project_attribute__c foundProjectAttribute;

        for (Project_attribute__c projectAttribute : projectAttributeList) {

            if (projectAttribute.Master__c == masterOptionApiName && projectAttribute.Specialization__c == specializationOptionApiName) {
                foundProjectAttribute = projectAttribute;
                break;
            }
        }

        return foundProjectAttribute;
    }

    /*****************/
    /* INNER CLASSES */
    /*****************/

    public abstract inherited sharing class PicklistOption extends Model.PicklistOption {

        public transient String objectApiName { get; set; }
        public transient String fieldApiName { get; set; }

        {
            isSelected = false;
        }

        public abstract void fillDataFromSettings(SObject picklistOptionSettings);

        public void addCurrentOptionLabel(Map<String, Schema.PicklistEntry> picklistValueToEntryMap) {

            if (!picklistValueToEntryMap.containsKey(this.optionApiName)) {
                throw new ProjectAttributeException(ProjectAttributeException.ERROR_CODE_OBJECT_PICKLIST_ENTRY_NOT_FOUND, this);
            }

            Schema.PicklistEntry picklistEntry = picklistValueToEntryMap.get(this.optionApiName);

            if (!picklistEntry.isActive()) {
                throw new ProjectAttributeException(ProjectAttributeException.ERROR_CODE_OBJECT_PICKLIST_ENTRY_NOT_ACTIVE, this);
            }

            this.optionLabel = picklistEntry.getLabel();
        }

    }

    public inherited sharing class MasterPicklistOption extends PicklistOption {

        public SpecializationPicklistOption[] specializationPicklistOptionList { get; set; }

        public override void fillDataFromSettings(SObject picklistOptionSettings) {
            ObjectMasterPicklistOption__mdt masterPicklistOptionSettings = (ObjectMasterPicklistOption__mdt) picklistOptionSettings;
            this.optionApiName = masterPicklistOptionSettings.OptionApiName__c;
            this.objectApiName = masterPicklistOptionSettings.ObjectApiName__c;
            this.fieldApiName = masterPicklistOptionSettings.FieldApiName__c;
        }

    }

    public inherited sharing class SpecializationPicklistOption extends PicklistOption {

        public String projectAttributeRecordId { get; set; }

        public override void fillDataFromSettings(SObject picklistOptionSettings) {
            ObjectDependentPicklistOption__mdt dependentPicklistOptionSettings = (ObjectDependentPicklistOption__mdt) picklistOptionSettings;
            this.optionApiName = dependentPicklistOptionSettings.OptionApiName__c;
            this.objectApiName = dependentPicklistOptionSettings.ObjectApiName__c;
            this.fieldApiName = dependentPicklistOptionSettings.FieldApiName__c;
        }

    }
}