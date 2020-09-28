/**
 * Created by MaxymMirona on 01.07.2020.
 */

public abstract without sharing class CustomMetadataDAO {
    private static final String SETTINGS_NOT_FOUND_ERROR = 'Settings were not found. Please, check the identifier';
    private static final String EMPTY_IDENTIFIER_ERROR = 'Identifier is empty';
    private static final String NO_MAPPING_FOR_SOBJECT = '{0} object has no mapping with identifier in ApproverAssignerSettingsService class';
    private static final Map<Schema.SObjectType, String> IDENTIFIER_STRINGS_BY_SOBJECT = new Map<SObjectType, String>{
            Schema.Allocation__c.getSObjectType() => 'New Allocation'
    };

    public String identifier { get; set; }
    public List<SObject> targetRecords { get; set; }

    public abstract List<SObject> fetchMetadataSettings();

    public abstract ICustomMetadataDAOWrapper getWrapperBySettings(SObject settings, List<SObject> targetRecords);

    public virtual ICustomMetadataDAOWrapper getWrapperBySettings(SObject settings) {
        return getWrapperBySettings(settings, new List<SObject>());
    }

    public static ICustomMetadataDAOWrapper getSettings(System.Type metadataServiceClass, List<SObject> targetRecords) {
        if (!targetRecords.isEmpty()) {
            if (IDENTIFIER_STRINGS_BY_SOBJECT.containsKey(targetRecords[0].getSObjectType())) {
                return getSettings(
                        metadataServiceClass,
                        IDENTIFIER_STRINGS_BY_SOBJECT.get(targetRecords[0].getSObjectType()),
                        targetRecords
                );
            } else {
                throw new CustomMetadataDAOException(NO_MAPPING_FOR_SOBJECT);
            }
        }

        return null;
    }

    public static ICustomMetadataDAOWrapper getSettings(System.Type metadataServiceClass, String identifier) {

        if (!String.isEmpty(identifier)) {
            CustomMetadataDAO serviceClass = initServiceClass(metadataServiceClass);

            serviceClass.identifier = identifier;

            List<SObject> metadataSettings = serviceClass.fetchMetadataSettings();

            if (!metadataSettings.isEmpty()) {
                return serviceClass.getWrapperBySettings(metadataSettings[0]);
            } else {
                throw new CustomMetadataDAOException(SETTINGS_NOT_FOUND_ERROR);
            }
        } else {
            throw new CustomMetadataDAOException(EMPTY_IDENTIFIER_ERROR);
        }
    }

    public static ICustomMetadataDAOWrapper getSettings(System.Type metadataServiceClass, String identifier, List<SObject> targetRecords) {

        if (!String.isEmpty(identifier)) {
            CustomMetadataDAO serviceClass = initServiceClass(metadataServiceClass);

            serviceClass.identifier = identifier;
            serviceClass.targetRecords = targetRecords;

            List<SObject> metadataSettings = serviceClass.fetchMetadataSettings();

            if (!metadataSettings.isEmpty()) {
                return serviceClass.getWrapperBySettings(metadataSettings[0], targetRecords);
            } else {
                throw new CustomMetadataDAOException(SETTINGS_NOT_FOUND_ERROR);
            }
        } else {
            throw new CustomMetadataDAOException(EMPTY_IDENTIFIER_ERROR);
        }
    }

    private static CustomMetadataDAO initServiceClass(System.Type metadataServiceClass) {
        CustomMetadataDAO metadataServiceClassInstance = (CustomMetadataDAO)metadataServiceClass.newInstance();

        if (metadataServiceClass == null){
            throw new CustomMetadataDAOException('Illegal Service class: ' + String.valueOf(metadataServiceClass) + ' passed');
        }

        return metadataServiceClassInstance;
    }

    public interface ICustomMetadataDAOWrapper {

        List<SObject> getRecords();
    }

    public class CustomMetadataDAOException extends Exception {}
}