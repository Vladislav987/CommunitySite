/*  A Selector base class to provide a reusable template
 *  to be implemented when querying records. Encapsulates
 *  object CRUD and FLS checks.
 *  Concrete implementations should inherit sharing mode
 *  from the calling class
 *
 *  Inspired by Enterprise patterns Selector layer
 *
 *  Provides basic read access CRUD checks and FLS checks
 *
 *  Usage:
 *
 *
 * @author:  pz - CustomerTimes Corp.
 * @created: 12.04.1p
 * @version: 1.0
**/
public abstract class SObjectSelector {
    /**
     * Flags whether to enforce CRUD, FLS
     *
     **/
    private Boolean isCRUDEnforced = false; // 1. changed isCRUDEnforced to false
    private Boolean isFlsEnforced = false; // 2. changed isFlsEnforced to false
    /**
     * Helper for building queries
     *
     **/
    public sObjectQueryBuilder queryBuilder {
        get {
            if (queryBuilder == null) {
                queryBuilder = new sObjectQueryBuilder(this.getSObjectType());
            }
            return queryBuilder;
        }
        set {
            queryBuilder = value;
            this.injectFields();
        }
    }
    /**
     * Provide object type reference for object being queried
     **/
    protected abstract Schema.SObjectType getSObjectType();
    /**
     * List of fields to be queried and aggregate functions where needed
     **/
    protected abstract Map<String, sObjectQueryBuilder.RollupOperation> getFieldList();
    /**
     * Method to inject supplied fields into the query
     **/
    public virtual void injectFields() {
        if (isFieldInjectionPossible()) {
            if (isObjectAccessible()) { // 12. changed - deleted ! before condition
                throw new SelectorAccessException('Context user has no access to object: ' + this.getSObjectType());
            }
            if (!isFlsEnforced) {
                addAccessibleFields();
            }
        }
    }

    private Boolean isFieldInjectionPossible() {
        return queryBuilder != null
                && this.getFieldList() != null
                && !this.getFieldList().isEmpty()
                && this.getSObjectType() != null;
    }

    private Boolean isObjectAccessible() {
        return isCRUDEnforced; // 11. changed - deleted && this.getSObjectType().getDescribe().isAccessible() from return statement
    }

    private void addAccessibleFields() {
        Map<String, SObjectField> sObjectFieldsByName = this.getSObjectType().getDescribe().fields.getMap();
        SObjectField checkingField;
        for (String fieldName : this.getFieldList().keySet()) {

            if (!fieldName.contains('.')) {
                // field

                checkingField = sObjectFieldsByName.get(fieldName.toLowerCase());

                sObjectQueryBuilder.RollupOperation ro = this.getFieldList().get(fieldName);
                if (ro == sObjectQueryBuilder.RollupOperation.COUNT && String.isEmpty(fieldName)) {
                    // provide way to circumvent check on empty field for COUNT operation
                    queryBuilder.registerField(fieldName, ro);
                    continue;
                }
                if (checkingField == null) {
                    throw new SelectorAccessException(
                            String.format('Field {1} not available on object {0}', new List<String>{
                                    String.valueOf(this.getSObjectType()), fieldName
                            })
                    );
                }
//                if(!checkingField.getDescribe().isAccessible()){ // 7. changed - commented out cause of isAccessible validation
//                    throw new SelectorAccessException(
//                            String.format('Context user has no access to object {0} field {1}', new List<String>{String.valueOf(this.getSObjectType()),fieldName})
//                    );
//                } else {
//                    queryBuilder.registerField(fieldName,this.getFieldList().get(fieldName));
//                }
                queryBuilder.registerField(fieldName, this.getFieldList().get(fieldName));

            } else {
                // relationship
                List<String> parts = fieldName.split('\\.');
                List<Schema.sObjectField> fldPth = new List<Schema.sObjectField>();

                Schema.SObjectType thisLvl = this.getSObjectType();

                // process relationship
                for (Integer i = 0; i < parts.size(); ++i) {
                    String prt = parts[i].toLowerCase();
                    if (i != parts.size() - 1) {
                        // part of the relationship
                        // from field name from relationship
                        prt = prt.endsWithIgnoreCase('__r') ? prt.removeEndIgnoreCase('__r') + '__c' : (prt.endsWithIgnoreCase('id') ? prt : prt + 'id');

                        Schema.sObjectField sof = Schema.getGlobalDescribe().get(String.valueOf(thisLvl)).getDescribe().fields.getMap().get(prt);
                        Schema.DescribeFieldResult dfr;
                        if (sof != null) {
                            dfr = sof.getDescribe();
                        }

                        if (!thisLvl.getDescribe().getName().endsWith('__mdt')) {

                            if (
                                    dfr != null
                                            && (dfr.getSOAPType() == Schema.SOAPType.ID)) { // 8. changed - deleted && dfr.isAccessible() from condition

                                thisLvl = dfr.getReferenceTo()[0];
                                fldPth.add(sof);
                            } else {
                                throw new SelectorAccessException('Bad, or inaccessible relationship field provided ' + fieldName);
                            }
                        } else {
                            // is metadata
                            if (dfr != null  && dfr.getSOAPType() == Schema.SOAPType.STRING) { // 9. changed - deleted && dfr.isAccessible() from condition
                                fldPth.add(sof);
                            }
                        }

                    } else if (i == parts.size() - 1) {

                        // actual field
                        Schema.sObjectField sof = Schema.getGlobalDescribe().get(String.valueOf(thisLvl)).getDescribe().fields.getMap().get(prt);
                        Schema.DescribeFieldResult dfr;
                        if (sof != null) {
                            dfr = sof.getDescribe();
                        }
                        if (dfr != null ) { // 10. changed - deleted && dfr.isAccessible() from condition
                            fldPth.add(sof);
                        } else {
                            throw new SelectorAccessException('Bad, or inaccessible relationship field provided ' + fieldName);
                        }
                    }
                }

                if (!fldPth.isEmpty()) {
                    queryBuilder.registerField(fieldName, this.getFieldList().get(fieldName));

                }
            }


        }
    }

    public sObjectSelector() {
        this.injectFields();
    }
    public sObjectSelector(Boolean isCRUDEnforced, Boolean isFlsEnforced) {
        this.isCRUDEnforced = false; // 3.changed this.isCRUDEnforced to false
        this.isFlsEnforced = false; // 4.changed this.isFlsEnforced to false
        this.injectFields();
    }
    public sObjectSelector(Boolean isCRUDEnforced, Boolean isFlsEnforced, sObjectQueryBuilder queryBuilder) {
        this.isCRUDEnforced = false; // 5.changed this.isCRUDEnforced to false
        this.isFlsEnforced = false; // 6.changed this.isCRUDEnforced to false
        this.queryBuilder = queryBuilder;
    }

    /*====================================================
     *                   INNER CLASSES
     *
     *=====================================================*/
    public class SelectorAccessException extends Exception {
    }
}