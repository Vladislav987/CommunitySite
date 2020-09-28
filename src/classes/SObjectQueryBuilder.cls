/*  A query builder implementation to be used
 *  when building queries.
 *  Abstracts away query creation for
 *  easier implementation of selectors
 *
 *  Usage:
 *       Possible to do following:
 *
 *       new sObjectQueryBuilder(Account.sObjectType)
 *          .registerField('Name')
 *          .registerField('BillTo__r.Name',sObjectQueryBuilder.RollupOperation.MIN)
 *          .registerSubquery( new sObjectQueryBuilder('Contacts',Account.sObjectType)
 *                             .registerField('Name')
 *                             .registerSubquery('Notes', new List<String>{'Title'})
 *           ).toString();
 *
 *      Use with discretion, as above example will return an illegal query:
 *
 *           SELECT Id,Name,MIN(BillTo__r.Name),(SELECT Name,(SELECT Title FROM Notes) FROM Contacts) FROM Account
 *
 *       Nested query depth IS NOT checked, aggregate function validity is not checked
 *       Field validity and reference validity IS checked
 *
 * @author:  pz - CustomerTimes Corp.
 * @created: 12.04.19
 * @version: 1.0
**/
public class SObjectQueryBuilder {
    // TODO: implement additional clauses
    /**
     * Basic query template to be filled with
     * {0} - fields and subqueries
     * {1} - sObject api name
     * {2} - WHERE clause
     * {3} - other clauses (i.e. GROUP BY, etc)
     * {4} - LIMIT clause
     * {5}  -OFFSET clause
     **/
    private static final String SOQL_QUERY_TEMPLATE = 'SELECT {0} FROM {1} {2} {3} {4} {5}';
    /**
     * Query base object type
     **/
    private Schema.SObjectType objectType {
        get {
            if(objectType == null){
                if(childRelation != null){
                    objectType = this.childRelation.getChildSObject();
                }
            }
            return objectType;
        }
        private set {
            if(value != null){
                //this.fields.add(new sObjectField(value.getDescribe().fields.getMap().get('id')));
            } else {
                this.fields = new Set<sObjectField>();
            }
            objectType = value;
        }
    }
    /**
     * Hold all conditional expressions
     */
    private List<WhereExpression> whereExpressions = new List<WhereExpression>();
    /**
     * Uses for building conditional expressions.
     */
    private Boolean isWhere = true;


    public static final NullValue NULL_VALUE = new NullValue();

    /**
     * Subquery relationship field
     **/
    private Schema.ChildRelationship childRelation;
    /**
     * Parent type for subquery
     **/
    private Schema.SObjectType pType;
    /**
     * Set of fields to take part in the query
     **/
    private Set<sObjectField> fields = new Set<sObjectField>();
    /**
     * Set of sub-queries
     **/
    private Set<sObjectQueryBuilder> subqueries = new Set<sObjectQueryBuilder>();
    /**
     * WHERE clause
     **/
    private String whereClause {
        get{
            if(String.isEmpty(whereClause)){
                if(whereExpressions.isEmpty()) {
                    return '';
                } else {
                    return buildConditions();
                }
            } else {
                return whereClause.normalizeSpace().leftPad(whereClause.length()+1,' ');
            }
        }
        private set;
    }
    /**
     * other clauses (i.e. GROUP BY, etc)
     **/
    private String otherClauses {
        get{
            if(String.isEmpty(otherClauses)){
                return '';
            } else {
                return otherClauses.normalizeSpace().leftPad(otherClauses.length()+1,' ');
            }
        }
        private set;
    }
    /**
     * limit number
     **/
    private Integer limitNumber;
    private Integer offsetNumber;
    /**
     * limit clause
     **/
    private String limitClause{
        get {
            String ret = '';
            if(limitNumber != null && limitNumber >= 0){
                ret = String.format(
                        ' LIMIT {0}',
                        new List<String>{String.valueOf(limitNumber)}
                );
            }
            return ret;
        }
        private set;
    }

    private String offsetClause {
        get {
            if(offsetNumber != null && offsetNumber >= 0) {
                return ' OFFSET ' + offsetNumber;
            }
            return '';
        }
        private set;
    }
    /*====================================================
     *                   METHODS
     *
     *=====================================================*/
    /**
     * Method to return the select clause for the query
     *
     **/
    public override String toString(){
        // for some reason String.join doesn't leverage object's toString method, so iterate to build list
        List<String> fieldNames = new List<String>();
        for(sObjectField field :fields){
            fieldNames.add(field.toString());
        }

        // add subqueries like simple fields
        for(sObjectQueryBuilder queryBuilder: this.subqueries){
            fieldNames.add(queryBuilder.toString());
        }
        String query = String.format(
                SOQL_QUERY_TEMPLATE
                ,new List<String>{
                        String.join(fieldNames,',')
                        ,this.childRelation != null ? childRelation.getRelationshipName() : String.valueOf(objectType)
                        ,this.whereClause
                        ,this.otherClauses
                        ,this.limitClause
                        ,this.offsetClause
                }
        ).trim();

        if(this.childRelation != null){
            query = query.leftPad(query.length()+1,'(');
            query = query.rightPad(query.length()+1,')');
        }
        //
        this.whereExpressions = new List<WhereExpression>();
        this.isWhere = true;
        this.whereClause = '';
        this.subqueries = new Set<sObjectQueryBuilder>();
        this.offsetClause = '';
        this.otherClauses = '';
        //
        return query;
    }
    /**
     * Method to register limit clause for the query
     *
     * @param limitNo       - number of records to return
     * @return QueryBuilder - flow style return
     **/
    public sObjectQueryBuilder registerLimit(Integer limitNo){
        if(limitNo != null && limitNo > 0){
            this.limitNumber = limitNo;
        } else {
            this.limitClause = null;
        }
        return this;
    }

    public sObjectQueryBuilder registerOffset(Integer offsetNo){
        this.offsetNumber = offsetNo;
        return this;
    }
    /**
     * Method to register other clauses for the query
     *
     * @param other         - other clauses as string (i.e. GROUP BY, etc)
     * @return QueryBuilder - flow style return
     **/
    public sObjectQueryBuilder registerOther(String other){
        if(other != null){
            this.otherClauses = other;
        }
        return this;
    }
    /**
     * Method to register where clause for the query
     *
     * @param where         - where clause as string (supports scope merge variables)
     * @return QueryBuilder - flow style return
     **/
    public sObjectQueryBuilder registerWhere(String whereClause){
        if(whereClause != null){
            this.whereClause = whereClause;
        }
        return this;
    }


    private String buildConditions() {
        List<String> expressions = new List<String>();
        for (WhereExpression expression : whereExpressions) {
            expressions.add(getWhereOrAndClause());
            expressions.add(expression.toString());
        }
        return String.join(expressions, ' ');
    }

    private String getWhereOrAndClause() {
        String clause = isWhere ? 'WHERE' : 'AND';
        if(isWhere) {
            isWhere = false;
        }
        return clause;
    }
    /**
     * Method to process requested subquery
     *
     * @param  queryBuilder           - subquery to register
     * @return sObjectQueryBuilder - flow style return
     **/
    public sObjectQueryBuilder registerSubquery(sObjectQueryBuilder queryBuilder){
        if(queryBuilder == null || queryBuilder.childRelation == null || queryBuilder.pType != this.objectType){
            throw new QueryBuilderException('Bad query builder for child relationship');
        } else {
            subqueries.add(queryBuilder);
        }
        return this;
    }
    /**
     * Method to process requested subquery
     *
     * @param  relName      - string representation of the field
     * @return sObjectQueryBuilder - flow style return
     **/
    public sObjectQueryBuilder registerSubquery(String relName, List<String> fields){

        sObjectQueryBuilder queryBuilder;
        Schema.DescribeSObjectResult objectDescribe = this.objectType.getDescribe();

        for(Schema.ChildRelationship childRelation :objectDescribe.getChildRelationships()){
            if(!String.isEmpty(childRelation.getRelationshipName())
                    && childRelation.getRelationshipName().equalsIgnoreCase(relName)){
                queryBuilder = new sObjectQueryBuilder(childRelation,this.objectType);
                break;
            }
        }
        if(queryBuilder == null){
            throw new QueryBuilderException('Bad child relationship field provided for subquery '+relName);
        }
        for(String fld: fields){
            queryBuilder.registerField(fld);
        }
        subqueries.add(queryBuilder);
        return this;
    }
    /**
     * Method to process requested field into appropriate wrappers
     *
     * @param fieldNm       - string api name of the field
     * @return QueryBuilder - flow style return
     **/

    public sObjectQueryBuilder registerField(Schema.SObjectField field){
        this.registerField(field.getDescribe().getName(), null);
        return this;
    }

    public sObjectQueryBuilder registerField(String fieldNm){
        this.registerField(fieldNm,null);
        return this;
    }

    /**
     * Method to process requested fields into appropriate wrappers
     *
     * @param fieldNm       - string api name of the field
     * @param operationType        - enum of the operation to be performed
     * @return sObjectQueryBuilder - flow style return
     **/
    public sObjectQueryBuilder registerField(String fieldNm, RollupOperation operationType){
        sObjectField thisFld;
        fieldNm = fieldNm.toLowerCase();
        if(!fieldNm.contains('.')){
            // field is on the base level object
            if(!String.isEmpty(fieldNm) && this.objectType.getDescribe().fields.getMap().containsKey(fieldNm)){
                this.fields.add(new sObjectField(objectType.getDescribe().fields.getMap().get(fieldNm),operationType));
            } else if(String.isEmpty(fieldNm) && operationType == RollupOperation.COUNT){
                // process COUNT() operation
                this.fields.add(new sObjectField((Schema.sObjectField)null,RollupOperation.COUNT));
            } else {
                throw new QueryBuilderException('Bad field provided '+fieldNm);
            }
        } else {
            // field is a relationship field
            List<String> parts = fieldNm.split('\\.');
            List<Schema.sObjectField> fldPth = new List<Schema.sObjectField>();

            Schema.SObjectType thisLvl = objectType;
            Boolean isMetadata = false;
            // process relationship
            for(Integer i=0; i<parts.size(); ++i){
                String prt = parts[i].toLowerCase();

                if(i != parts.size() - 1){
                    // part of the relationship
                    // from field name from relationship
                    prt = prt.endsWithIgnoreCase('__r') ? prt.removeEndIgnoreCase('__r')+'__c' : (prt.endsWithIgnoreCase('id') ? prt : prt +'id');

                    Schema.sObjectField sof = Schema.getGlobalDescribe().get(String.valueOf(thisLvl)).getDescribe().fields.getMap().get(prt);
                    Schema.DescribeFieldResult dfr;
                    if(sof != null){
                        dfr = sof.getDescribe();
                    }
                    if(!thisLvl.getDescribe().getName().endsWith('__mdt')) {
                        if (dfr != null && dfr.getSOAPType() == Schema.SOAPType.ID) {

                            thisLvl = dfr.getReferenceTo()[0];
                            fldPth.add(sof);
                        } else {
                            throw new QueryBuilderException('Bad relationship field provided ' + fieldNm);
                        }
                    } else {
                        // is metadata
                        isMetadata = true;
                        if(dfr != null && dfr.getSOAPType() == Schema.SOAPType.STRING){
                            fldPth.add(sof);
                        }
                    }
                } else if (i == parts.size() - 1) {

                    // actual field
                    Schema.sObjectField sof = Schema.getGlobalDescribe().get(String.valueOf(thisLvl)).getDescribe().fields.getMap().get(prt);
                    Schema.DescribeFieldResult dfr;
                    if(sof != null){
                        dfr = sof.getDescribe();
                    }
                    if(dfr != null){
                        fldPth.add(sof);
                    } else{
                        throw new QueryBuilderException('Bad relationship field provided '+fieldNm);
                    }
                }
            }
            if(!fldPth.isEmpty()){
                fields.add(new sObjectField(fldPth,operationType,isMetadata));
            }
        }
        return this;
    }
    public sObjectQueryBuilder addWhere(Schema.SObjectField field, ComparisonOperation op, Iterator<String> it) {
        if(it != null && it.hasNext()) {
            List<String> values = new List<String>();
            while (it.hasNext()) {
                String eachValue = it.next();
                values.add(eachValue.center(eachValue.length() + 2, '\''));
            }
            String value = '(' + String.join(values, ', ') + ')';
            return createClauseEntry(field, op, value);
        }
        return this;
    }

    public sObjectQueryBuilder addWhere(String fieldApiName, ComparisonOperation op, String value) {
        if(fieldApiName != null && value != null) {
            return createClauseEntry(fieldApiName, op, value);
        }
        return this;
    }

    private sObjectQueryBuilder createClauseEntry(Schema.SObjectField field, ComparisonOperation op, String value) {
        String fieldApiName = field.getDescribe().name;
        return createClauseEntry(fieldApiName, op, value);
    }

    private sObjectQueryBuilder createClauseEntry(String fieldApiName, ComparisonOperation op, String value) {
        String mappedOperation = COMP_OPERATIONS.get(op);
        if(!String.isEmpty(mappedOperation)){
            this.whereExpressions.add(new WhereExpression(fieldApiName, mappedOperation, value));
        }
        return this;
    }
    /*====================================================
     *                   CONSTRUCTORS
     *
     *=====================================================*/
    public sObjectQueryBuilder(Schema.SObjectType objectType){
        this.objectType = objectType;
    }
    public sObjectQueryBuilder(Schema.ChildRelationship childRelation, Schema.SObjectType pType){
        this.childRelation = childRelation;
        this.pType = pType;
    }
    public sObjectQueryBuilder(String childRelationName, Schema.SObjectType pType){
        Schema.DescribeSObjectResult objectDescribe = pType.getDescribe();
        for(Schema.ChildRelationship childRelation :objectDescribe.getChildRelationships()){
            if(!String.isEmpty(childRelation.getRelationshipName())
                    && childRelation.getRelationshipName().equalsIgnoreCase(childRelationName)){
                this.childRelation = childRelation;
                break;
            }
        }
        this.pType = pType;
    }

    /*====================================================
     *                   INNER CLASSES
     *
     *=====================================================*/
    /**
     * Allowed aggregations
     **/
    public enum RollupOperation {
        SUM, MAX, MIN, AVG, COUNT, COUNT_DISTINCT
    }

    public enum ComparisonOperation {
        EQUALS,
        NOT_EQUALS,
        LESS_THAN,
        LESS_OR_EQUALS,
        GREATER_THAN,
        GREATER_OR_EQUALS,
        LIKE_OPERATION,
        IN_OPERATION,
        NOT_IN_OPERATION
    }

    private static Map<ComparisonOperation, String> COMP_OPERATIONS = new Map<ComparisonOperation, String>{
            ComparisonOperation.EQUALS => '=',
            ComparisonOperation.NOT_EQUALS => '!=',
            ComparisonOperation.LESS_THAN => '<',
            ComparisonOperation.LESS_OR_EQUALS => '<=',
            ComparisonOperation.GREATER_THAN => '>',
            ComparisonOperation.GREATER_OR_EQUALS => '>=',
            ComparisonOperation.LIKE_OPERATION => 'LIKE',
            ComparisonOperation.IN_OPERATION => 'IN',
            ComparisonOperation.NOT_IN_OPERATION => 'NOT IN'
    };

    public class NullValue {

        private NullValue() {}
    }

    class WhereExpression {

        String field;
        String op;
        String value;

        public WhereExpression(String field, String operation, String value) {
            this.field = field;
            this.op = operation;
            this.value = value;
        }

        public override String toString() {
            return String.join(new String[]{field, op, value}, ' ');
        }
    }
    /**
     * Class that wraps a field that is supposed to take
     * part in the query and exposes relevant information
     *
     **/
    private class sObjectField {

        private RollupOperation operationType;
        private Schema.sObjectField field;
        private List<Schema.sObjectField> pth;
        private Boolean isMetadata = false;

        private sObjectField(Schema.sObjectField field){
            this.field = field;
        }
        private sObjectField(Schema.sObjectField field, RollupOperation operationType){
            this.field = field;
            this.operationType = operationType;
        }
        private sObjectField(List<Schema.sObjectField> path, RollupOperation operationType){
            this.pth = path;
            this.operationType = operationType;
        }
        private sObjectField(List<Schema.sObjectField> path, RollupOperation operationType, Boolean isMetadata){
            this.pth = path;
            this.operationType = operationType;
            this.isMetadata = isMetadata;
        }
        public Boolean equals(Object obj){
            if(obj instanceOf sObjectField){
                sObjectField temp = (sObjectField)obj;
                return (this.field == temp.field && this.pth == temp.pth && this.operationType == temp.operationType);
            }
            return false;
        }
        public Integer hashCode() {
            String operationTypeStr = String.isEmpty(String.valueOf(this.operationType)) ? '' : String.valueOf(this.operationType);
            String fieldStr = String.isEmpty(String.valueOf(this.field)) ? '' : String.valueOf(this.field);
            String pthStr = String.isEmpty(String.valueOf(this.pth)) ? '' : String.valueOf(this.pth);

            return operationTypeStr.hashCode()+fieldStr.hashCode()+pthStr.hashCode();
        }

        public override String toString(){
            String toReturn = '';

            if( pth == null || pth.isEmpty() ){
                // is field
                if(this.field != null){
                    toReturn = this.field.getDescribe().getName();
                }

            } else {
                // is relationship
                String path = '';
                for(Integer i=0; i<pth.size(); i++ ){
                    Schema.sObjectField pthFld = pth[i];

                    Schema.DescribeFieldResult dfr = pthFld.getDescribe();
                    if(!this.isMetadata){
                        if(dfr != null && (i != pth.size()-1) && (dfr.getSOAPType() == Schema.SOAPType.ID)){
                            path += dfr.getRelationshipName()+'.';
                        } else if(dfr != null && (i == pth.size()-1)){
                            path += dfr.getName();
                        }
                    } else {
                        if(dfr != null && (i != pth.size()-1) && (dfr.getSOAPType() == Schema.SOAPType.STRING)){
                            path += dfr.getName().replace('__c','__r')+'.';
                        } else if(dfr != null && (i == pth.size()-1)){
                            path += dfr.getName();
                        }
                    }
                }
                toReturn = path;
            }

            if(operationType != null){
                // TODO: consider providing an alias?
                // example of aliased aggregate function:
                // toReturn = String.valueOf(operationType)+'('+this.field.getDescribe().getName()+')'+this.field.getDescribe().getName();
                toReturn = String.valueOf(operationType)+'('+toReturn+')';
            }
            return toReturn;
        }
    }

    public class QueryBuilderException extends Exception {}
}