/**
 *
 * @author: pz - Customertimes Corp.
 * @created: 26.04.2019
 * @version: 0.1
 */
@IsTest
private class sObjectSelectorTest {

    @IsTest
    static void doTest() {
        System.Test.startTest();
        TestSelector ts = new TestSelector();
        ts = new TestSelector(true,true);
        ts.testSelect();
        System.Test.stopTest();
    }

    public class TestSelector extends sObjectSelector {

        public override Schema.sObjectType getSObjectType(){
            return Account.sObjectType;
        }
        public override Map<String,sObjectQueryBuilder.RollupOperation> getFieldList(){
            return new Map<String,sObjectQueryBuilder.RollupOperation> {
                    Account.Id.getDescribe().getName() => null
                    , Account.Name.getDescribe().getName() => null
                    , 'Owner.Name' => null
            };
        }
        public void testSelect() {
            String queryString = queryBuilder.toString();
        }
        public TestSelector(){

        }
        public TestSelector(Boolean isCrud, Boolean isFls){
            super(isCrud,isFls);
        }
    }
}