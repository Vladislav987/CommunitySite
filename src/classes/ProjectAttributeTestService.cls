/**
 * Created by Lambru Dmytro on 26.03.2020.
 */

@IsTest
public class ProjectAttributeTestService {

    public static Project_attribute__c[] createPAsWithRTSpecializationForAllPicklistOptions(Id projectId, Map<Object, Schema.PicklistEntry[]> masterValueToDependentPicklistEntriesMap) {
        Project_attribute__c[] projectAttributeList = new Project_attribute__c[]{};

        for (Object masterPicklistValue : masterValueToDependentPicklistEntriesMap.keySet()) {

            for (Schema.PicklistEntry dependentEntry : masterValueToDependentPicklistEntriesMap.get(masterPicklistValue)) {
                Project_attribute__c projectAttribute = new Project_attribute__c(
                    RecordTypeId = ProjectAttributeSelector.PROJECT_ATTRIBUTE_RECORD_TYPE_SPECIALIZATION_ID,
                    Project__c = projectId,
                    Master__c = (String)masterPicklistValue,
                    Specialization__c = dependentEntry.getValue()
                );

                projectAttributeList.add(projectAttribute);
            }
        }

        return projectAttributeList;
    }
}