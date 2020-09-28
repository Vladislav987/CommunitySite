/**
 * Created by Lambru Dmytro on 26.03.2020.
 */

@IsTest
private class ProjectAttributeExceptionTest {

    @IsTest
    static void testThrowException() {

        ProjectAttributeService.MasterPicklistOption masterPicklistOption = new ProjectAttributeService.MasterPicklistOption();
        masterPicklistOption.optionApiName = 'INVALID_API_NAME';
        masterPicklistOption.fieldApiName = 'INVALID_API_NAME';
        masterPicklistOption.objectApiName = 'INVALID_API_NAME';

        Test.startTest();
        ProjectAttributeException masterProjectAttributeException;

        try {
            throw new ProjectAttributeException(ProjectAttributeException.ERROR_CODE_OBJECT_PICKLIST_ENTRY_NOT_ACTIVE, masterPicklistOption);
        }
        catch (ProjectAttributeException exc) {
            masterProjectAttributeException = exc;
        }
        Test.stopTest();

        System.assertEquals(
            ProjectAttributeException.ERROR_CODE_OBJECT_PICKLIST_ENTRY_NOT_ACTIVE,
            masterProjectAttributeException.errorCode,
            'Error code must be ' + ProjectAttributeException.ERROR_CODE_OBJECT_PICKLIST_ENTRY_NOT_ACTIVE + ' for this exception!'
        );

        System.assertEquals(
            true,
            masterProjectAttributeException.getErrorMsg().length() > 0,
            'Error message must be for this exception!'
        );
    }
}