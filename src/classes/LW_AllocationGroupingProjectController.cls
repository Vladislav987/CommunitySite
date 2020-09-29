public without sharing class LW_AllocationGroupingProjectController {
    public static final String FIELD_SET_FOR_GROUPING_PROJECT = System.Label.AllocationFieldSetForGroupingProject;
    private static ProjectSelector PROJECT_SELECTOR = new ProjectSelector();
    @AuraEnabled
    public static GroupingDataWrapper getData(Id projectId) {
        if (String.isBlank(projectId)) {
            throw new AuraHandledException('Not valid record Id arrived');

        }
        try {
            return createDataWrapper(projectId);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());

        }


    }
    private static GroupingDataWrapper createDataWrapper(Id projectId) {
        Map<String, String> fieldApiByLabel = new Map<String, String>();
        Set<Contractor__c> contractors = new Set<Contractor__c>();
        Set<String> statuses = new Set<String>();
        List<String> teams = new List<String>();
        Set<String> types = new Set<String>();
        List<String> columnName;

        fieldApiByLabel = getFieldSetFieldsLabel(FIELD_SET_FOR_GROUPING_PROJECT, 'Allocation__c');
        List<Project__c> projects = PROJECT_SELECTOR.getChildProjectsWithAllocationsByParentId(projectId, fieldApiByLabel.values());
        for (Project__c project : projects) {
            teams.add(project.Name);
            if (project.Allocations__r.size() > 0) {
                for (Allocation__c allocation : project.Allocations__r) {
                    if (String.isNotEmpty(allocation.Status__c)) {
                        statuses.add(allocation.Status__c);
                    }
                    if (String.isNotEmpty(allocation.Allocation_Type__c)) {
                        types.add(allocation.Allocation_Type__c);
                    }
                    if (String.isNotEmpty(allocation.Contractor__c)) {
                        Contractor__c contractor = new Contractor__c();
                        contractor.Id = allocation.Contractor__c;
                        contractor.Name = allocation.Contractor__r.Name;
                        contractors.add(contractor);
                    }
                }
            }
        }
        columnName = new List<String>(fieldApiByLabel.keySet());
        return new GroupingDataWrapper(projects, teams, new List<String>(statuses), new List<String>(types), new List<Contractor__c>(contractors), fieldApiByLabel);

    }

    public class GroupingDataWrapper {
        @AuraEnabled public List<Project__c> childProjects;
        @AuraEnabled public List<String> teams;
        @AuraEnabled public List<String> statuses;
        @AuraEnabled public List<String> types;
        @AuraEnabled public List<Contractor__c> contractors;
        @AuraEnabled public Map<String, String> fieldsList;
        public GroupingDataWrapper(List<Project__c> childProjects
                , List<String> teams, List<String> statuses
                , List<String> types, List<Contractor__c> contractors, Map<String, String> fieldsList) {
            this.childProjects = childProjects;
            this.teams = teams;
            this.statuses = statuses;
            this.types = types;
            this.contractors = contractors;
            this.fieldsList = fieldsList;
        }

    }

    public static Map<String, String> getFieldSetFieldsLabel(String fieldset, String targetObjectAPI) {
        Map<String, String> fieldsLabelAndPath = new Map<String, String>();
        Map<String, Schema.FieldSet> fieldSetMap = Schema.getGlobalDescribe().get(targetObjectAPI).getDescribe().fieldSets.getMap();
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
    private static String getLabelOfFieldWithParentRelationship(String fieldPath) {
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


}