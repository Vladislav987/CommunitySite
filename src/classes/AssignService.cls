/** Created by D.Yasinskyi on 16.04.2019 */
public virtual with sharing class AssignService {
    public static final Map<String, AssignSetting__mdt> SETTINGS_BY_OBJ_NAME = getSettingsByObjectName();
    public static final Map<SObjectType, Type> STRATEGY_BY_SOBJECT_TYPE = new Map<SObjectType, Type>{
            Lead.getSObjectType() => LeadStrategy.class, Opportunity.getSObjectType() => OpportunityStrategy.class
    };
    //=========================================STATIC===================================================================
//    public static AssignSetting__mdt getSettings(String objectName) {
//        return SETTINGS_BY_OBJ_NAME.get(objectName);
//    }

    public static Map<String, AssignSetting__mdt> getSettingsByObjectName() {
        Map<String, AssignSetting__mdt> mdtsByObjectName = new Map<String, AssignSetting__mdt>();
        List<AssignSetting__mdt> mdts = [
                SELECT Id
                        , EnterpriseAssigneeRole__c
                        , ObjectAPIName__c
                        , SelfServiceAssigneeRole__c
                        , SDR_User_assignee_role__c
                FROM AssignSetting__mdt
        ];

        for (AssignSetting__mdt mdt : mdts) {
            mdtsByObjectName.put(mdt.ObjectAPIName__c, mdt);
        }

        return mdtsByObjectName;
    }
    //=========================================INTERFACES===============================================================
    public interface AssignStrategy {
        void initialize(List<SObject> records);
        List<SObject> assign();
    }
    //=========================================EXCEPTION================================================================
    public class NoAssignStrategyException extends Exception {}
    //=========================================CLASSES==================================================================
    public class AssignProcessor {
        List<SObject> records;
        AssignStrategy strategy;

        public AssignProcessor(List<SObject> records) {
            this.records = records;
            setStrategy();
        }

        public void setStrategy() {
            strategy = (records == null || records.isEmpty()) ?
                    null : (AssignStrategy) STRATEGY_BY_SOBJECT_TYPE.get(records[0].getSObjectType()).newInstance();
            strategy.initialize(records);

        }

        public List<SObject> assign() {
            if (strategy == null) throw new NoAssignStrategyException();
            return strategy.assign();
        }
    }
}