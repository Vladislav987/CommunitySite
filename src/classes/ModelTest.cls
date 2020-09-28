/**
 * Created by Lambru Dmytro on 26.03.2020.
 */

@IsTest
private class ModelTest {
    static String DUMMY_STRING = 'DUMMY_STRING';
    static Integer DUMMY_INTEGER = 123456789;
    static Boolean DUMMY_BOOLEAN_TRUE = true;

    @IsTest
    static void testCreatingDummyClasses() {
        Model.PicklistOption picklistOption = new Model.PicklistOption();
        picklistOption.optionLabel = DUMMY_STRING;
        picklistOption.optionApiName = DUMMY_STRING;
        picklistOption.isSelected = DUMMY_BOOLEAN_TRUE;

        Model.LightningResponse lightningResponse = new Model.LightningResponse();
        lightningResponse.success = DUMMY_BOOLEAN_TRUE;
        lightningResponse.data = DUMMY_STRING;
        lightningResponse.code = DUMMY_INTEGER;
        lightningResponse.message = DUMMY_STRING;
    }
}