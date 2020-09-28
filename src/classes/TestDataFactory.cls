/**
*  A utility class to ease test data creation
*  by providing preset defaults for sObject.
*
*
*  Usage:
*
*	instantiate a desired sObject, fill non-default fields:
*
*		User newUser = new User(Phone = '123-12-13', MobilePhone = null);
*
*	call default filling method:
*
*		User tempUser = (User) TestDataFactory.createsObject(newUser,true);
*
*  tempUser.Phone = '123-12-13';
*  tempUser.Name = 'Name from defaults';
*
*  @author:  pz - Customertimes Corp.
*  @created: 12.04.19
*  @version: 0.1
*/
@isTest
public class TestDataFactory {

    private static String getIndex(Integer i) {
        String s = String.valueOf(i);
        return '0'.repeat(4 - s.length()) + s;
    }
    /**
     * Simulates Id in proper format for the SObject Type
     *
     *  @param sobjectType     - SObject Type
     *  @return String         - spoofed id in proper format
     */
    public static String getGeneratedId(sObjectType sobjectType) {
        return getGeneratedId(String.valueOf(sobjectType));
    }
    /**
     * Simulates Id in proper format for the SObject Type
     *
     *  @param sot     - SObject Type
     *  @return String - spoofed id in proper format
     */
    public static String getGeneratedId(String sobjectType) {
        Type t = Type.forName(sobjectType);
        if (t == null) return null;
        SObject so = (SObject) t.newInstance();
        String result = String.valueOf(genRndStrFast(5));
        return so.getSObjectType().getDescribe().getKeyPrefix() +
                '0'.repeat(12-result.length()) + result;
    }

    // static var for generating random a-zA-Z0-9 strings
    static Integer[] charset;
    // static initialization brace for random string generation
    static {
        charset = new Integer[0];
        for(Integer i = 48; i < 58; i++) charset.add(i);
        for(Integer i = 65; i < 91; i++) charset.add(i);
        for(Integer i = 97; i < 123; i++) charset.add(i);
    }

    /**
    *  A utility method for returning a randomized
    *  a-zA-Z0-9 strings of specified length
    *
    *  @param  len    - requested string length
    *  @return String - randomized string
    */
    public static String genRndStrFast(Integer len) {
        Integer[] chars = new Integer[len];
        Integer key, size = charset.size();

        for(Integer idx = 0; idx < len; idx++) {
            chars[idx] = charset[Math.mod(Math.abs(Crypto.getRandomInteger()), size)];
        }

        return String.fromCharArray(chars);
    }
    // dummy user for test user creation
    private static User dummyUser {
        get {
            if (dummyUser==null) {
                dummyUser = [select TimeZoneSidKey, LocaleSidKey,
                        EmailEncodingKey, ProfileId, LanguageLocaleKey
                from User WHERE isActive = true limit 1];
            }
            System.assertNotEquals(null, dummyUser);
            return dummyUser ;
        }
        set {
            System.assert(true);
        }
    }

    /**
    *  Low level utility method to connect sObject <=> field defaults
    *
    *   @param sObj             - sObject to replicate
    *   @param defaultClassName - string name of the object holding defaults
    *	@return SObject         - the object that was created
    */
    public static SObject createSObject(SObject sObj, String defaultClassName) {
        // Create an instance of the defaults class so we can get the Map of field defaults
        Type t = Type.forName(defaultClassName);
        if (t == null) {
            throw new TestFactoryException('No test data defaults found');
        }
        // instantiating field defaults for this object
        FieldDefaults defaults = (FieldDefaults)t.newInstance();
        // putting defaults into the sObject deep clone
        sObject tempObj = sObj.clone(true,true,true,true);
        addFieldDefaults(tempObj, defaults.getFieldDefaults());
        System.assert(true);
        return tempObj;
    }
    /**
    *  Low level utility method to fill sObject with field defaults
    *
    *   @param sObj         - sObject to replicate
    *   @param defaults     - string name of the object holding defaults
    *	@return SObject     - the user that was created
    */
    private static void addFieldDefaults(SObject sObj, Map<String, Object> defaults) {
        // Loop through the map of fields and if they are null on the object, fill them.
        for (String field : defaults.keySet()) {
            if (sObj.get(field) == null) {
                sObj.put(field, defaults.get(field));
            }
        }
        System.assert(true);
    }

    /**
    *  Utility method to create a new generic sObject
    *
    *   @param sObj           - sObject to replicate
    *	@return SObject       - the user that was created
    */
    public static SObject createSObject(SObject sObj) {
        // Check what type of object we are creating and add any defaults that are needed.
        String objectName = String.valueOf(sObj.getSObjectType());
        // Construct the default values class. Salesforce doesn't allow '__' in class names
        List<String> nameSegs = objectName.split('__');
        if(nameSegs.size() >= 3){
            //have namespace
            objectName = nameSegs.get(1);
        } else {
            // no namespace
            objectName = nameSegs.get(0);
            if(nameSegs.size() == 2){
                // custom object
                // append __c back
                objectName = objectName + '__'+nameSegs.get(1);
            }
        }
        // replace the custom object suffix for single underscore
        // to differentiate custom obj from standard ex. Account__c and Account
        String defaultClassName = 'TestDataFactory.' + objectName.replace('__c', '_') + 'Defaults';
        // If there is a class that exists for the default values, then use them
        if (Type.forName(defaultClassName) != null) {

            sObj = createSObject(sObj, defaultClassName);

        }
        System.assert(true);
        return sObj;
    }
    /**
    *  Utility method to create a new generic sObject
    *  and insert it if required
    *
    *   @param sObj           - sObject to replicate
    *   @param doInsert       - flag indicating whether to insert the sObj
    *	@return SObject       - the object that was created
    */
    public static SObject createSObject(SObject sObj, Boolean doInsert) {
        SObject retObject = createSObject(sObj);
        if (doInsert) {
            insert retObject;
        }
        System.assertNotEquals(null, retObject);

        return retObject;
    }
    /**
    *  Utility method to create list of generic sObjects
    *
    *
    *   @param sObj                  - sObject to replicate
    *   @param numberOfObjects       - number of times to replicate
    *   @return SObject[]            - list of replicated sObjects
    */
    public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects,Boolean doInsert) {
        return createSObjectList(sObj,numberOfObjects,null,doInsert);
    }

    /**
    *  Utility method to create list of generic sObjects
    *
    *
    *   @param sObj                  - sObject to replicate
    *   @param numberOfObjects       - number of times to replicate
    *   @param defaultClassName      - the string identifying the defaults implementation
    *	@return SObject[]       	 - list of replicated sObjects
    */
    public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects, String defaultClassName) {
        SObject[] sObjs = new SObject[] {};

        // Recreate the object the number of times requested
        for (Integer i = 0; i < numberOfObjects; i++) {
            // clone original passed in object to avoid duplicate objects in returned list
            sObject cln = sObj.clone(false,true,false,false);

            SObject newObj;
            if (defaultClassName == null) {
                newObj = createSObject(cln);
            } else {
                newObj = createSObject(cln, defaultClassName);
            }
            sObjs.add(newObj);
        }
        System.assert(true);
        return sObjs;
    }
    /**
    *  Utility method to handle insertion
    *  of a list of generic sObjects
    *
    *
    *   @param sObj                  - sObject to replicate
    *   @param numberOfObjects       - number of times to replicate
    *   @param defaultClassName      - the string identifying the defaults implementation
    *   @param doInsert              - boolean flag to indicate the need to insert replicated data
    *	@return SObject[]       	 - list of replicated sObjects
    */
    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, String defaultClassName, Boolean doInsert) {
        SObject[] retList = createSObjectList(sObj, numberOfObjects, defaultClassName);
        if (doInsert) {
            insert retList;
        }
        System.assert(true);
        return retList;
    }

    /**
    *  Interface for sObj field standard values
    *
    */
    public interface FieldDefaults {
        Map<String, Object> getFieldDefaults();
    }

    /**
    *  User standard values
    *
    */
    public class UserDefaults implements FieldDefaults {
        String lastName = genRndStrFast(10);
        String email = lastName+'@hotmail.com';
        String alias = genRndStrFast(5);
        String nick = genRndStrFast(5);
        Profile standartProfile = [SELECT ID FROM Profile WHERE Name='Standard User' LIMIT 1];
        public Map<String, Object> getFieldDefaults() {

            return new Map<String, Object> {
                    'FirstName' => 'TestFName',
                    'LastName' => lastName,
                    'Email' => email,
                    'Username' => email,
                    'ProfileId' => standartProfile.ID,
                    'Alias' => alias,
                    'CommunityNickname' => nick,
                    'TimeZoneSidKey' => (String)dummyUser.get('TimeZoneSidKey'),
                    'LocaleSidKey' => dummyUser.LocaleSidKey,
                    'EmailEncodingKey' => dummyUser.EmailEncodingKey,
                    'LanguageLocaleKey' => dummyUser.LanguageLocaleKey
            };
        }
    }

    /**
    *  Opportunity standard values
    *
    */
    public class OpportunityDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                    'Name' => genRndStrFast(7),
                    'StageName' => 'Discovery',
                    'CloseDate' => System.now().date().addDays(1)
            };
        }
    }
    /**
    *  Contact standard values
    *
    */
    public class ContactDefaults implements FieldDefaults {
        String lastName = genRndStrFast(10);
        String email = lastName+'@hotmail.com';

        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                    'FirstName' => 'First',
                    'LastName' => lastName,
                    'Email' => email
            };
        }
    }
    /**
    *  Lead standard values
    *
    */
    public class LeadDefaults implements FieldDefaults {
        String lastName = genRndStrFast(10);
        String email = lastName+'@hotmail.com';
        String company = genRndStrFast(10);
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                    'FirstName' => 'First',
                    'LastName' => lastName,
                    'Email' => email,
                    'Company' => company
            };
        }
    }
    /**
    *  Case standard values
    *
    */
    public class CaseDefaults implements FieldDefaults {

        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                    'Origin' => 'Email'
            };
        }
    }
    /**
    *  Allocation standard values
    *
    */
    public class Allocation_Defaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                    Allocation__c.Allocation_Type__c.getDescribe().getName() => Allocation__c.Allocation_Type__c.getDescribe().getPicklistValues()[0].getValue()
                    , Allocation__c.Allocation__c.getDescribe().getName() => Math.random()
                    , Allocation__c.Start_date__c.getDescribe().getName() => System.now().dateGmt().addDays(-1)
                    , Allocation__c.End_date__c.getDescribe().getName() => System.now().dateGmt().addDays(1)
            };
        }
    }
    /**
    *  Contractor standard values
    *
    */
    public class Contractor_Defaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                    Contractor__c.Name.getDescribe().getName() => genRndStrFast(10)
                    , Contractor__c.Resource_Level__c.getDescribe().getName() =>  Contractor__c.Resource_Level__c.getDescribe().getPicklistValues()[0].getValue()
                    , Contractor__c.Resource_Type__c.getDescribe().getName() => Contractor__c.Resource_Type__c.getDescribe().getPicklistValues()[0].getValue()
            };
        }
    }
    /**
    *  Project standard values
    *
    */
    public class Project_Defaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object> {
                    Project__c.Name.getDescribe().getName() => genRndStrFast(10)
                    , Project__c.Contract_type__c.getDescribe().getName() =>  Project__c.Contract_type__c.getDescribe().getPicklistValues()[0].getValue()
                    , Project__c.Project_type__c.getDescribe().getName() => Project__c.Project_type__c.getDescribe().getPicklistValues()[0].getValue()
                    , Project__c.Start_date__c.getDescribe().getName() => System.now().dateGmt().addDays(-1)
                    , Project__c.Project_Manager__c.getDescribe().getName() => UserInfo.getUserId()
            };
        }
    }
    /**
    *  Exception types
    *
    */
    public class TestFactoryException extends Exception {}

}