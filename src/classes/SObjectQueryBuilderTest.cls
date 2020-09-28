/**
 *
 * @author: pz - Customertimes Corp.
 * @created: 12.04.2019
 * @version: 0.1
 */
@IsTest
private class SObjectQueryBuilderTest {

    /**
     * Simple use-case - build a primitive query for
     * multiple standard fields on a standard object
     */
    @IsTest
    static void registerValidFields() {
        final Schema.sObjectType tp = Account.sObjectType;

        final List<String> fldNms = new List<String>{
                Account.Id.getDescribe().getName()
                ,Account.Name.getDescribe().getName()
        };

        System.Test.startTest();
        // use query builder to process fields
        sObjectQueryBuilder qb = new sObjectQueryBuilder(Account.sObjectType);
        for(String fld :fldNms){
            qb.registerField(fld);
        }

        final String outcome = String.format(
                'SELECT {0} FROM {1}',
                new List<String> { String.join(fldNms,',') , tp.getDescribe().getName()}
        );
        final String testie = qb.toString();

        System.Test.stopTest();

        System.assertEquals(outcome,testie,'Generated query string should be as expected');

    }

    /**
     * Negative use-case - build a primitive query for
     * a mix of standard and invalid fields on a standard object
     */
    @IsTest
    static void registerInValidFields() {
        final Schema.sObjectType tp = Account.sObjectType;

        final List<String> fldNms = new List<String>{
                'IMANINVALIDFIELD'
                ,Account.Id.getDescribe().getName()
                ,Account.Name.getDescribe().getName()
        };

        System.Test.startTest();
        // use query builder to process fields
        sObjectQueryBuilder qb = new sObjectQueryBuilder(tp);

        Boolean allGood = true;
        for(String fld :fldNms){
            try{
                qb.registerField(fld);
            } catch (sObjectQueryBuilder.QueryBuilderException ex){
                allGood = false;
            }
        }

        System.Test.stopTest();

        System.assertEquals(false, allGood ,'Should fail on adding an invalid field');
    }
    /**
     * Use-case - build a query with a
     * lookup to different table
     */
    @IsTest
    static void registerValidRelationship() {
        final Schema.sObjectType tp = Account.sObjectType;

        final List<String> fldNms = new List<String>{
                Account.Id.getDescribe().getName()
                ,Account.Name.getDescribe().getName()
                ,'CreatedBy.Name'  // reference to User table
        };

        System.Test.startTest();
        // use query builder to process fields
        sObjectQueryBuilder qb = new sObjectQueryBuilder(tp);

        for(String fld :fldNms){
            qb.registerField(fld);
        }
        final String testie = qb.toString();
        System.Test.stopTest();

        final String outcome = String.format(
                'SELECT {0} FROM {1}',
                new List<String> { String.join(fldNms,',') , tp.getDescribe().getName()}
        );

        System.assertEquals(outcome,testie,'Generated query string should be as expected');
    }
    /**
     * Negative use-case - build a query with an
     * invalid lookup to different table
     */
    @IsTest
    static void registerInValidRelationship() {
        final Schema.sObjectType tp = Account.sObjectType;

        final List<String> fldNms = new List<String>{
                Account.Id.getDescribe().getName()
                ,Account.Name.getDescribe().getName()
                ,'InvalidLookup.Name'  // invalid reference to other table
        };

        System.Test.startTest();
        // use query builder to process fields
        sObjectQueryBuilder qb = new sObjectQueryBuilder(tp);
        Boolean allGood = true;
        for(String fld :fldNms){
            try{
                qb.registerField(fld);
            } catch (sObjectQueryBuilder.QueryBuilderException ex){
                allGood = false;
            }
        }

        System.Test.stopTest();

        System.assertEquals(false,allGood,'Should fail on invalid relationship');
    }
    /**
     * Form a query to be used in
     * Database.countQuery operation
     */
    @IsTest
    static void formCountQuery() {
        final Schema.sObjectType tp = Account.sObjectType;
        final sObjectQueryBuilder.RollupOperation rlup = sObjectQueryBuilder.RollupOperation.COUNT;

        final String outcome = String.format(
                'SELECT {0} FROM {1}',
                new List<String> { String.valueOf(rlup)+'()', tp.getDescribe().getName()}
        );

        System.Test.startTest();
        sObjectQueryBuilder qb = new sObjectQueryBuilder(tp);
        qb.registerField('',rlup);

        System.Test.stopTest();

        System.assertEquals(outcome,qb.toString(),'Query should be as expected');
    }

    /**
     * Form a subquery
     */
    @IsTest
    static void formValidSubQuery() {
        final Schema.sObjectType prnt = Account.sObjectType;
        final String relNm = 'Contacts';

        final List<String> prntFldNms = new List<String>{
                Account.Id.getDescribe().getName()
                ,Account.Name.getDescribe().getName()
        };

        final List<String> chldFldNms = new List<String>{
                Contact.Id.getDescribe().getName()
                ,Contact.Name.getDescribe().getName()
        };

        System.Test.startTest();

        final sObjectQueryBuilder prntQb = new sObjectQueryBuilder(prnt);
        final sObjectQueryBuilder chldQb = new sObjectQueryBuilder(relNm,prnt);

        for(String fldNm : prntFldNms){
            prntQb.registerField(fldNm);
        }
        for(String fldNm : chldFldNms){
            chldQb.registerField(fldNm);
        }

        prntQb.registerSubquery(chldQb);
        //prntQb.registerSubquery(relNm ,chldFldNms);

        System.Test.stopTest();
        prntFldNms.add( String.format(
                '(SELECT {0} FROM {1})',
                new List<String> { String.join(chldFldNms,',') , relNm}
        ));

        final String outcome = String.format(
                'SELECT {0} FROM {1}',
                new List<String> { String.join(prntFldNms,',') , prnt.getDescribe().getName()}
        );
        System.assertEquals(outcome,prntQb.toString(),'Query should be as expected');

    }
    /**
     * Form an invalid subquery
     */
    @IsTest
    static void formInValidSubQuery() {
        final Schema.sObjectType prnt = Account.sObjectType;
        final String relNm = 'INVALID';

        final List<String> prntFldNms = new List<String>{
                Account.Id.getDescribe().getName()
                ,Account.Name.getDescribe().getName()
        };

        final List<String> chldFldNms = new List<String>{
                Contact.Id.getDescribe().getName()
                ,Contact.Name.getDescribe().getName()
        };

        System.Test.startTest();

        final sObjectQueryBuilder prntQb = new sObjectQueryBuilder(prnt);


        for(String fldNm : prntFldNms){
            prntQb.registerField(fldNm);
        }
        Boolean allGood = true;

        try{
            prntQb.registerSubquery(relNm ,chldFldNms);
        } catch (Exception ex){
            allGood = false;
        }

        System.Test.stopTest();

        System.assertEquals(false,allGood,'Should fail on bad child relationship');
    }

    /**
     * Simple use-case - build a query for
     * multiple standard fields on a standard object
     * with WHERE AND LIMIT clauses
     */
    @IsTest
    static void registerWhereAndLimitAndElse() {
        final Schema.sObjectType tp = Account.sObjectType;

        final List<String> fldNms = new List<String>{
                Account.Id.getDescribe().getName()
                ,Account.Id.getDescribe().getName()
        };

        System.Test.startTest();
        // use query builder to process fields
        sObjectQueryBuilder qb = new sObjectQueryBuilder(Account.sObjectType);

        for(String fld :fldNms){
            qb.registerField(fld);
        }

        qb.registerWhere('WHERE Id IN ('+qb.toString()+')');
        qb.registerLimit(5);
        qb.registerOther('GROUP BY Id');
        /*
        final String outcome = String.format(
                'SELECT {0} FROM {1}',
                new List<String> { String.join(fldNms,',') , tp.getDescribe().getName()}
        );
        */
        final String testie = qb.toString();
        System.debug('==> '+testie);

        System.Test.stopTest();

        //System.assertEquals(outcome,testie,'Generated query string should be as expected');

    }
}