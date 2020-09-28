/**
 * Created by Lambru Dmytro on 20.03.2020.
 * @description - class with reusable methods and independent of metadata or data.
 */

public inherited sharing class Util {

    public static Map<Object, Schema.PicklistEntry[]> getMapWithActiveMasterValueToDependentPicklistEntries(Schema.SObjectField dependedFieldToken) {
        Schema.DescribeFieldResult depend = dependedFieldToken.getDescribe();
        Schema.SObjectField controlToken = depend.getController();

        if (controlToken == null) return null;

        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries = (
            control.getType() == Schema.DisplayType.BOOLEAN
            ? null
            : control.getPicklistValues()
        );

        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<Object, Schema.PicklistEntry[]> dependentPicklistValues = new Map<Object, Schema.PicklistEntry[]>();

        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {

            if (entry.isActive()) {
                String[] base64chars = String.valueOf(
                    ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')
                ).split('');

                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue = (
                        controlEntries == null
                        ? (Object) (index == 1)
                        : (Object) (controlEntries[index].isActive() ? controlEntries[index].getValue() : null)
                    );

                    Integer bitIndex = index / 6, bitShift = 5 - Math.mod(index, 6);

                    if (controlValue == null || (base64map.indexOf(base64chars[bitIndex]) & (1 << bitShift)) == 0) {
                        continue;
                    }

                    if (!dependentPicklistValues.containsKey(controlValue)) {
                        dependentPicklistValues.put(controlValue, new Schema.PicklistEntry[]{entry});
                    }
                    else {
                        dependentPicklistValues.get(controlValue).add(entry);
                    }

                }
            }
        }

        return dependentPicklistValues;
    }

    public static Map<String, Schema.PicklistEntry> createMapWithPicklistValueToEntry(Schema.PicklistEntry[] picklistEntryList) {
        Map<String, Schema.PicklistEntry> picklistValueToEntryMap = new Map<String, Schema.PicklistEntry>();

        for (Schema.PicklistEntry picklistEntry : picklistEntryList) {
            picklistValueToEntryMap.put(picklistEntry.value, picklistEntry);
        }

        return picklistValueToEntryMap;
    }

    /**
     * @description Test a String to see if it is a valid ID and ID for the specified SObject
     * @param  idStringToCheck The ID to test.
     * @param  sObjectType     The SObjectType of the sObject to compare against.
     * @return                 Returns true if the ID is valid, false if it is not.
     */
    public static Boolean isValidIdForSObject(String idStringToCheck, Schema.SObjectType sObjectType) {
        Boolean result = false;

        try {
            Id id = idStringToCheck;

            result = (sObjectType == id.getSobjectType());
        }
        catch (Exception exc) {
            // StringException, TypeException
        }

        return result;
    }

    /**
     * @description - for easy tracking of exceptions.
     * @param leaveDebug
     * @param exc
     * @param t
     *
     * @return - JSON with exception data.
     */
    public static String trackException(Boolean leaveDebug, Exception exc, Type t) {
        ExceptionData exceptionData = new ExceptionData(exc, t);
        String serializedExc = JSON.serialize(exceptionData);

        if (leaveDebug) {
            System.debug('EXCEPTION DATA: ' + JSON.serializePretty(serializedExc));
        }

        return serializedExc;
    }

    /**
     * @description - class created to keep exceptions data and can be serialized.
     */
    public class ExceptionData {

        public String classType { get; set; }
        public String exceptionType { get; set; }
        public Integer lineNumber { get; set; }
        public String message { get; set; }
        public String stackTraceString { get; set; }

        public ExceptionData(Exception exc, Type t) {
            this.classType = t.getName();
            this.exceptionType = exc.getTypeName();
            this.lineNumber = exc.getLineNumber();
            this.message = exc.getMessage();
            this.stackTraceString = exc.getStackTraceString();
        }
    }
}