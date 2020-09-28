/**
 * Created by Lambru Dmytro on 21.03.2020.
 */

public without sharing class ProjectAttributeException extends Exception {

    public static transient final String OPTION_API_NAME_WILDCARD = '%%OPTION_API_NAME%%';
    public static transient final String FIELD_API_NAME_WILDCARD = '%%FIELD_API_NAME%%';
    public static transient final String OBJECT_API_NAME_WILDCARD = '%%OBJECT_API_NAME%%';
    // can be moved to Custom Labels
    public static transient final String ERROR_MSG_OBJECT_PICKLIST_ENTRY_NOT_FOUND = 'A picklist entry with API name "' +OPTION_API_NAME_WILDCARD+ '" was not found on the field "' +FIELD_API_NAME_WILDCARD+ '" from the object "' +OBJECT_API_NAME_WILDCARD+ '"';
    public static transient final String ERROR_MSG_OBJECT_PICKLIST_ENTRY_NOT_ACTIVE = 'A picklist entry with API name "' +OPTION_API_NAME_WILDCARD+ '" is not active on the field "' +FIELD_API_NAME_WILDCARD+ '" from the object "' +OBJECT_API_NAME_WILDCARD+ '"';

    public static transient final Integer ERROR_CODE_OBJECT_PICKLIST_ENTRY_NOT_FOUND = 1001;
    public static transient final Integer ERROR_CODE_OBJECT_PICKLIST_ENTRY_NOT_ACTIVE = 1002;
    public static transient final Integer ERROR_CODE_ATTRIBUTES_ALREADY_CHANGED = 1003;

    public Integer errorCode { get; set; }
    private ProjectAttributeService.PicklistOption projectAttributePicklistOption { get; set; }

    public ProjectAttributeException(Integer errorCode, ProjectAttributeService.PicklistOption projectAttributePicklistOption) {
        this.errorCode = errorCode;
        this.projectAttributePicklistOption = projectAttributePicklistOption;
    }

    public String getErrorMsg() {
        String errorMsg = '';

        if (this.errorCode == ERROR_CODE_OBJECT_PICKLIST_ENTRY_NOT_FOUND) {
            errorMsg = this.replaceWildcards(ERROR_MSG_OBJECT_PICKLIST_ENTRY_NOT_FOUND);
        }
        else if (this.errorCode == ERROR_CODE_OBJECT_PICKLIST_ENTRY_NOT_ACTIVE) {
            errorMsg = this.replaceWildcards(ERROR_MSG_OBJECT_PICKLIST_ENTRY_NOT_ACTIVE);
        }

        return errorMsg;
    }

    private String replaceWildcards(String errorMsg) {
        errorMsg = errorMsg.replace(OPTION_API_NAME_WILDCARD, this.projectAttributePicklistOption.optionApiName);
        errorMsg = errorMsg.replace(FIELD_API_NAME_WILDCARD, this.projectAttributePicklistOption.fieldApiName);
        errorMsg = errorMsg.replace(OBJECT_API_NAME_WILDCARD, this.projectAttributePicklistOption.objectApiName);

        return errorMsg;
    }
}