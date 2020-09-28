/**    A Domain class to provide a reusable interface
    *  to be implemented in triggers
    *  Inspired by Andrew Fawcetts's Enterprise patterns
    *  Domain layer
    *
    *  Usage:
    *       In appropriate tigger give reference to
    *       working sObjectDomain class for required object:
    *
    *       SObjectDomain.triggerHandler(ChangeRequestHandler.class);
    *
    *  @author:  pz - Customertimes Corp.
    *  @created: 12.04.19
    *  @version: 0.1
 */
public virtual with sharing class SObjectDomain {

    @TestVisible private static Boolean isRun = true;
    @TestVisible public static Boolean isEnabled = true;
    @TestVisible public static Map<String, Boolean> isEnabledMap = new Map<String, Boolean>();

    public List<SObject> records {get;
        private set{
            // this setter is similar to a constructor,
            // as is called when creating instances of sObjectDomain with records
            // so maintain valid state
            records = value;
            sObjectDescribe = null;
            skipValidation = false;
            skipOlsCheck = true;
        }
    }

    public Schema.DescribeSObjectResult sObjectDescribe     {
        get {
            if(sObjectDescribe == null){
                if(records != null && records.size()>0){
                    // get describe from object in list, list when initialized from deserialization
                    // doesn't retain the type?
                    sObjectDescribe = records[0].getSObjectType().getDescribe();
                }
            }
            return sObjectDescribe;
        }
        private set;}

    public Boolean skipValidation                           {
        get {
            if(skipValidation == null){
                skipValidation = false;
            }
            return skipValidation;
        }
        set;
    }

    public Boolean skipOlsCheck                           {
        get {
            if(skipOlsCheck == null){
                skipOlsCheck = false;
            }
            return skipOlsCheck;
        }
        set;
    }

    /*====================================================
	*                   CONSTRUCTOR
	*
	*=====================================================*/
    /* Retain empty constructor for extending
    *
    */
    public SObjectDomain()
    {

    }

    public SObjectDomain(List<sObject> records)
    {
        this.records = records;
    }
    /**
     * Override this to apply defaults to the records, this is called by the handleBeforeInsert method
     **/
    public virtual void onApplyDefaults() { }
    /**
     * Override this to apply general validation to be performed during insert or update, called by the handleAfterInsert and handleAfterUpdate methods
     **/
    public virtual void onValidate() {	}
    /**
	 * Override this to apply validation to be performed during insert, called by the handleAfterUpdate method
	 **/
    public virtual void onValidate(Map<Id,SObject> existingRecords)	{ }

    /*====================================================
	*                     BEFORE
	*
	*=====================================================*/
    /**
     * Override this to perform processing during the before insert phase, this is called by the handleBeforeInsert method
     **/
    public virtual void onBeforeInsert() { }
    /**
	 * Override this to perform processing during the before update phase, this is called by the handleBeforeUpdate method
	 **/
    public virtual void onBeforeUpdate(Map<Id,SObject> existingRecords) { }
    /**
     * Override this to perform processing during the before delete phase, this is called by the handleBeforeDelete method
     **/
    public virtual void onBeforeDelete() { }

    /*====================================================
	*                     AFTER
	*
	*=====================================================*/
    /**
     * Override this to perform processing during the after insert phase, this is called by the handleAfterInsert method
     **/
    public virtual void onAfterInsert() { }
    /**
     * Override this to perform processing during the after update phase, this is called by the handleAfterUpdate method
     **/
    public virtual void onAfterUpdate(Map<Id,SObject> existingRecords) { }
    /**
	 * Override this to perform processing during the after delete phase, this is called by the handleAfterDelete method
	 **/
    public virtual void onAfterDelete() { }
    /**
	 * Override this to perform processing during the after undelete phase, this is called by the handleAfterUnDelete method
	 **/
    public virtual void onAfterUnDelete() { }

    /*====================================================
	*                     HANDLERS
	*
	*=====================================================*/
    /**
     * Base handler for the Apex Trigger event Before Insert, calls the onApplyDefaults method, followed by onBeforeInsert
     **/
    public void handleBeforeInsert()
    {
        onApplyDefaults();
        onBeforeInsert();
    }
    /**
    * Base handler for the Apex Trigger event Before Update, calls the onBeforeUpdate method
    **/
    public void handleBeforeUpdate(Map<Id,SObject> existingRecords)
    {
        onBeforeUpdate(existingRecords);
    }
    /**
    * Base handler for the Apex Trigger event Before Delete, calls the onBeforeDelete method
    **/
    public void handleBeforeDelete()
    {
        onBeforeDelete();
    }

    /**
    * Base handler for the Apex Trigger event After Insert, checks object security and calls the onValidate and onAfterInsert methods
    *
    * @throws DomainException if the current user context is not able to create records
    **/
    public void handleAfterInsert()
    {
        if(!skipOlsCheck && !SObjectDescribe.isCreateable()){
            throw new DomainException('Permission to create an ' + SObjectDescribe.getName() + ' denied.');
        }
        if(!skipValidation){
            onValidate();
        }
        onAfterInsert();
    }

    /**
    * Base handler for the Apex Trigger event After Update, checks object security and calls the onValidate, onValidate(Map<Id,SObject>) and onAfterUpdate methods
    *
    * @throws DomainException if the current user context is not able to update records
    **/
    public void handleAfterUpdate(Map<Id,SObject> existingRecords)
    {
        if(!skipOlsCheck && !SObjectDescribe.isUpdateable()){
            throw new DomainException('Permission to udpate an ' + SObjectDescribe.getName() + ' denied.');
        }
        if(!skipValidation) {
            onValidate();
            onValidate(existingRecords);
        }
        onAfterUpdate(existingRecords);
    }
    /**
     * Base handler for the Apex Trigger event After Delete, checks object security and calls the onAfterDelete method
     *
     * @throws DomainException if the current user context is not able to delete records
     **/
    public void handleAfterDelete()
    {
        if(!skipOlsCheck && !SObjectDescribe.isDeletable()){
            throw new DomainException('Permission to delete an ' + SObjectDescribe.getName() + ' denied.');
        }
        if(!skipValidation) {
            onValidate();
        }
        onAfterDelete();
    }
    /**
     * Base handler for the Apex Trigger event After UnDelete, checks object security and calls the onUnAfterDelete method
     *
     * @throws DomainException if the current user context is not able to undelete records
     **/
    public void handleAfterUnDelete()
    {
        if(!skipOlsCheck && !SObjectDescribe.isUndeletable()){
            throw new DomainException('Permission to undelete an ' + SObjectDescribe.getName() + ' denied.');
        }
        if(!skipValidation) {
            onValidate();
        }
        onAfterUnDelete();
    }
    /**
     * Method constructs the given Domain class with the current Trigger context
     * before calling the applicable override methods such as beforeInsert, beforeUpdate etc.
     **/
    public static void triggerHandler(System.Type domainClass)
    {
        // Process the runtime Apex Trigger context
        triggerHandler(domainClass,
                Trigger.isBefore,
                Trigger.isAfter,
                Trigger.isInsert,
                Trigger.isUpdate,
                Trigger.isDelete,
                Trigger.isUnDelete,
                Trigger.new,
                Trigger.oldMap);
    }

    /**
     * Check is trigger run once to avoid recursive invocation.
     * Has to be used in trigger directly.
     */
    public static Boolean isRunOnce() {
        if (isRun) {
            isRun = false;
            return true;
        } else {
            return isRun;
        }
    }

    /**
     * Calls the applicable override methods such as beforeInsert, beforeUpdate etc. based on a Trigger context
     **/
    @TestVisible
    private static void triggerHandler(System.Type domainClass, Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUnDelete, List<SObject> newRecords, Map<Id, SObject> oldRecordsMap)
    {
        if (!isEnabledMap.containsKey(domainClass.getName())){
            isEnabledMap.put(domainClass.getName(), true);
        }

        if (isEnabledMap.get(domainClass.getName()) && isEnabled) {
            if (isBefore) {
                if (isInsert) {
                    initDomain(domainClass, newRecords).handleBeforeInsert();
                } else if (isUpdate) {
                    initDomain(domainClass, newRecords).handleBeforeUpdate(oldRecordsMap);
                } else if (isDelete) {
                    initDomain(domainClass, oldRecordsMap.values()).handleBeforeDelete();
                }
            } else {
                if (isInsert) {
                    initDomain(domainClass, newRecords).handleAfterInsert();
                } else if (isUpdate) {
                    initDomain(domainClass, newRecords).handleAfterUpdate(oldRecordsMap);
                } else if (isDelete) {
                    initDomain(domainClass, oldRecordsMap.values()).handleAfterDelete();
                } else if (isUnDelete) {
                    initDomain(domainClass, newRecords).handleAfterUnDelete();
                }
            }
        }
    }
    /* Initializes correct domain class and populates necessary records
    *
    *  @param domainClass       - type for the domain class
    *  @param records           - required records
    *  @return sObjectDomain    - class that carries the trigger logic payload
    */
    private static sObjectDomain initDomain(System.Type domainClass,List<sObject> records){
        // uses deserealize with records as parameter
        //sObjectDomain dom = (sObjectDomain)JSON.deserialize('{"records":'+JSON.serialize(records)+'}', domainClass);
        sObjectDomain dom = (sObjectDomain)domainClass.newInstance();
        dom.records = records;

        if(dom == null){
            throw new DomainException('Illegal domain class: '+String.valueOf(domainClass)+' passed');
        }
        return dom;
    }

    /*====================================================
	*                     EXCEPTIONS
	*
	*=====================================================*/
    public class DomainException extends Exception{}
}