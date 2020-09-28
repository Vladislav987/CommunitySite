/**
 * Created by Lambru Dmytro on 26.03.2020.
 */

@IsTest
private class UtilTest {

    @IsTest
    static void testTrackException() {
        String jsonException = '{}';

        try {
            Integer result = 0 / 0;
        }
        catch (Exception exc) {
            jsonException = Util.trackException(true, exc, UtilTest.class);
        }

        Util.ExceptionData exceptionData = (Util.ExceptionData) JSON.deserialize(jsonException, Util.ExceptionData.class);

        System.assertEquals('UtilTest', exceptionData.classType);
        System.assertEquals('System.MathException', exceptionData.exceptionType);
    }

    @IsTest
    static void testGetMapWithActiveMasterValueToDependentPicklistEntries() {
        Map<Object, Schema.PicklistEntry[]> masterValueToSpecializationPicklistEntriesMap = Util.getMapWithActiveMasterValueToDependentPicklistEntries(ProjectAttributeSelector.SPECIALIZATION_SOBJECT_FIELD);

        System.assertEquals(true, (masterValueToSpecializationPicklistEntriesMap.keySet().size() > 0));
    }

    @IsTest
    static void testCreateMapWithPicklistValueToEntry() {
        Map<String, Schema.PicklistEntry> picklistValueToEntryMap = Util.createMapWithPicklistValueToEntry(Account.Type.getDescribe().getPicklistValues());

        System.assertEquals(true, (picklistValueToEntryMap.keySet().size() > 0));
    }

    @IsTest
    static void testIsValidIdForSObject_positive() {
        Case caseRecord = (Case)TestDataFactory.createSObject(new Case(),true);

        Boolean result = Util.isValidIdForSObject(caseRecord.Id, Schema.Case.SObjectType);

        System.assertEquals(true, result);
    }

    @IsTest
    static void testIsValidIdForSObject_negative() {
        Boolean result = Util.isValidIdForSObject('INVALID_ID', Schema.Case.SObjectType);

        System.assertEquals(false, result);
    }
}