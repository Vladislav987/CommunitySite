/**
 *
 * @author: pz
 * @created: 15.04.2019
 * @version: 0.1
 */
public with sharing class CVGeneratorController {

    private static final List<Schema.sObjectField> flds = new List<Schema.sObjectField>{
        Project__c.Id
        // Allocation info
        , Project__c.Name
        , Project__c.Current_status__c
        , Project__c.Start_date__c
        , Project__c.End_date__c
    };


    @AuraEnabled
    public static CVGeneratorController.Context getContext(String searchTerm, Integer pNo, Integer perP, List<String> extrFlds, Id cId, List<Id> sels) {
        return new CVGeneratorController.Context(new CVGeneratorController.ProjectSelector(searchTerm,pNo,perP,flds,extrFlds,cId, sels));
    }


    public inherited sharing class Context{
        @AuraEnabled
        public String lds {
            get {
                return sel.stringifyRecords();
            }
            private set;
        }
        @AuraEnabled
        public PicklistVal spec {
            get{
                for(PicklistVal pv: this.specs){
                    if(pv.selected){
                        this.spec = pv;
                        break;
                    }
                }
                return this.spec;
            }
            private set;
        }
        @AuraEnabled
        public List<PicklistVal> specs {
            get {
                if(this.specs == null){
                    this.specs = new List<PicklistVal>();
                    this.specs.add(new PicklistVal('--','', true));
                    Schema.DescribeFieldResult fieldResult = Responsibilities__mdt.Specialization__c.getDescribe();
                    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                    Boolean setSel = false;
                    for( Schema.PicklistEntry pickListVal : ple){
                        this.specs.add(new PicklistVal(pickListVal.getLabel(),pickListVal.getValue(), false));
                        setSel = false;
                    }
                }
                return this.specs;
            }
            private set;
        }

        @AuraEnabled
        public Integer pageSize {
            get {
                return sel.getPerPage();
            }
            private set;
        }

        @AuraEnabled
        public Integer page {
            get{
                return sel.getPNo();
            }
            private set;
        }

        @AuraEnabled
        public Integer total {
            get{
                return sel.getCount();
            }

            private set;
        }

        @AuraEnabled
        public Set<Id> sels {
            get{
                return sel.getSelecteds();
            }

            private set;
        }

        private CVGeneratorController.Selector sel;

        public Context(CVGeneratorController.Selector sel){
            this.sel = sel;
        }
    }

    public abstract class QueryBuilder{

        final String qTempl = 'SELECT {0} FROM {1} {2} {3} {4} {5}';
        private final String sTerm;
        private Integer pNo;
        private Integer perP;

        public Integer offset{
            public get {
                if(offset == null){
                    if(pNo != null && pNo > 0 && perP != null && perP > 0){
                        this.offset = (pNo - 1)*perP;
                    }
                }
                return offset;
            }
            private set;
        }

        private final Id cId;
        private final List<Schema.sObjectField> flds;
        private final List<String> extrFlds;

        public String whereCond {
            get{
                if(whereCond == null){
                    this.whereCond = 'WHERE Name LIKE \'\'%{0}%\'\'';
                }
                return whereCond;
            }
            set;
        }


        private abstract Schema.sObjectType getsObjectType();

        /* Builds where clause
        */
        private virtual String formWhere(){

            String whereCl = '';
            if(!String.isEmpty(this.sTerm)){
                whereCl = String.format(this.whereCond, new List<String>{String.escapeSingleQuotes(this.sTerm)});
            }

            return whereCl;
        }

        private virtual String formLimit(){
            String lmtCl = '';
            if(perP != null){
                lmtCl = 'LIMIT '+perP;
            }
            return lmtCl;
        }
        private virtual String formOffset(){
            String offsetCl = '';

            if(this.offset != null){
                offsetCl = 'OFFSET '+this.offset;
            }
            if (this.offset >= 2000){
                throw new AuraHandledException('Offset should not exceed 2000');
            }

            return offsetCl;
        }
        private virtual String formFields(){
            Set<String> fldSt = new Set<String>();

            for(Schema.sObjectField fld : flds){
                fldSt.add(fld.getDescribe().getName());
            }

            if(this.extrFlds != null && !this.extrFlds.isEmpty()){
                for(String fld: this.extrFlds){
                    if(!String.isEmpty(fld)){
                        Schema.SObjectField fldTk = Schema.getGlobalDescribe().get(this.getsObjectType().getDescribe().getName()).getDescribe().fields.getMap().get(fld.toLowerCase());
                        if(fldTk != null){
                            fldSt.add(fldTk.getDescribe().getName());
                        }
                    }
                }
            }

            return String.join(new List<String>(fldSt),',');
        }
        private virtual String formOrder(){
            return 'ORDER BY CreatedDate DESC';
        }

        public abstract String getQuery();
        public abstract String getCountQuery();

        public QueryBuilder(String searchTerm, Integer pNo, Integer perP, List<Schema.sObjectField> flds, List<String> extrFlds, Id cId){
            this.sTerm = searchTerm;
            this.pNo = pNo;
            this.perP = perP;
            this.flds = flds;
            this.extrFlds = extrFlds;
            this.cId = cId;
        }
    }
    public class AllocationQueryBuilder extends QueryBuilder{

        public override Schema.sObjectType getsObjectType() {
            return Allocation__c.sObjectType;
        }

        private override String formWhere(){
            String whereCl = '';
            if(!String.isEmpty(this.cId)){
                whereCl = String.format(this.whereCond, new List<String>{String.escapeSingleQuotes(this.cId)});
            }
            return whereCl;
        }

        public override String getQuery(){
            String q = String.format(
                    qTempl
                    , new List<String>{
                            this.formFields()
                            , this.getsObjectType().getDescribe().getName()
                            , this.formWhere()
                            , ''
                            , this.formLimit()
                            , this.formOffset()
                    }
            );
            return q.trim();
        }

        public override String getCountQuery(){
            String q = String.format(
                    qTempl
                    , new List<String>{
                            'count()'
                            , this.getsObjectType().getDescribe().getName()
                            , this.formWhere()
                            , ''
                            , ''
                            , ''
                    }
            );

            return q.trim();
        }
        public String getSelectedProjs(){
            return 'SELECT Project__c FROM Allocation__c WHERE Contractor__c = \''+this.cId+'\'';
        }
        public AllocationQueryBuilder(String searchTerm, Integer pNo, Integer perP, List<Schema.sObjectField> flds, List<String> extrFlds, Id cId){
            super(searchTerm,pNo,perP,flds,extrFlds,cId);
            this.whereCond = 'WHERE Contractor__c = \'\'{0}\'\'';
        }
    }

    public class ProjectQueryBuilder extends QueryBuilder{

        private CVGeneratorController.QueryBuilder qbA;
        private Set<Id> sels;

        public override Schema.sObjectType getsObjectType() {
            return Project__c.sObjectType;
        }

        private override String formWhere(){

            String whereCl = '';
            String cond = this.sels != null ? ':selsIds' :  ('( ' + this.qbA.getQuery()+' )');

            whereCl = String.format(
                    this.whereCond
                    , new List<String>{cond}
            );

            if(!String.isEmpty(this.sTerm)){
                whereCl += String.format(' AND Name LIKE \'\'%{0}%\'\'', new List<String>{String.escapeSingleQuotes(this.sTerm)});
            }

            return whereCl;
        }
        private String formCountWhere(){
            String whereCl = '';
            if(this.sTerm != null && ! String.isEmpty(this.sTerm) ){
                whereCl = String.format(' WHERE Name LIKE \'\'%{0}%\'\'', new List<String>{String.escapeSingleQuotes(this.sTerm)});
            }
            return whereCl;
        }

        public override String getQuery(){
            String q = String.format(
                    qTempl
                    , new List<String>{
                            this.formFields()
                            , this.getsObjectType().getDescribe().getName()
                            , this.formWhere()
                            , this.formOrder()
                            , this.formLimit()
                            , this.formOffset()
                    }
            );
            return q.trim();
        }

        public override String getCountQuery(){
            String q = String.format(
                    qTempl
                    , new List<String>{
                            'count()'
                            , this.getsObjectType().getDescribe().getName()
                            , this.formCountWhere()
                            , ''
                            , ''
                            , ''
                    }
            );

            return q.trim();
        }

        public ProjectQueryBuilder(String searchTerm, Integer pNo, Integer perP, List<Schema.sObjectField> flds, List<String> extrFlds, Id cId, CVGeneratorController.QueryBuilder qbA, Set<Id> sels){
            super(searchTerm,pNo,perP,flds,extrFlds,cId);
            this.qbA = qbA;
            this.whereCond = 'WHERE Id IN {0}';
            if(sels != null && !sels.isEmpty()){
                this.sels = sels;
            }
        }
    }

    public interface Selector{
        Set<Id> getSelecteds();
        List<sObject> getRecords();
        String stringifyRecords();
        Integer getCount();
        Integer getPNo();
        Integer getPerPage();
    }

    public class ProjectSelector implements Selector{

        private CVGeneratorController.QueryBuilder qbP; // project
        private CVGeneratorController.AllocationQueryBuilder qbA;
        private Set<Id> sels;
        private Integer perP;
        private Integer pNo;

        public Integer getPNo(){
            return this.pNo;
        }
        public Integer getPerPage(){
            return this.perP;
        }
        public Set<Id> getSelecteds(){
            if(sels == null){
                sels = new Set<Id>();
                for(Allocation__c al : (List<Allocation__c>)Database.query(qbA.getSelectedProjs()) ){
                    sels.add(al.Project__c);
                }
            }
            return sels;
        }

        public List<sObject> getRecords(){

            String q1 = this.qbP.getQuery();
            List<sObject> sels = new List<sObject>();
            List<sObject> projs = new List<sObject>();

			List<Id> selsIds = new List<Id>(this.getSelecteds());
            System.debug('q1 '+q1);
            sels = Database.query(q1);

            if(sels.size() < this.qbP.perP){

                Integer recsShown = selsIds.size();


                this.qbP.perP = this.qbP.perP - sels.size();
                this.qbP.offset = (this.pNo - 1)*this.perP - selsIds.size() < 0 ? 0 : (this.pNo - 1)*this.perP - selsIds.size();
                this.qbP.whereCond = 'WHERE Id NOT IN {0}';


                String q2 = this.qbP.getQuery();

                projs = Database.query(q2);

            }

            List<sObject> ret = new List<sObject>();
            ret.addAll(sels);
            ret.addAll(projs);

            return ret;

        }

        public Integer getCount(){
            // selsIds is reference in count query string, do not remove
            List<Id> selsIds = new List<Id>(this.getSelecteds());
            return Database.countQuery(this.qbP.getCountQuery());
        }
        public String stringifyRecords(){
            List<Project__c> alcs = (List<Project__c>)this.getRecords();
            List<ProjectDTO> allocs = new List<ProjectDTO>();

            for(Project__c alc :alcs){
                /*
                for(Schema.sObjectField fld : flds){
                    if(alc.get(fld) == null){
                        alc.put(fld,null);
                    }
                }
                */
                allocs.add( new ProjectDTO(alc));
            }
            // serialize manually to preserve null value fields to be passed into the workflow
            return JSON.serialize(allocs);
        }

        public ProjectSelector(String searchTerm, Integer pNo, Integer perP, List<Schema.sObjectField> flds, List<String> extrFlds, Id cId, List<Id> sels){
            if(sels != null && !sels.isEmpty()){
                this.sels = new Set<Id>(sels);
            }
            List<Schema.sObjectField> fldsA = new List<Schema.sObjectField>{Allocation__c.Project__c};
            CVGeneratorController.QueryBuilder qbA = (CVGeneratorController.QueryBuilder)new CVGeneratorController.AllocationQueryBuilder(null,0,null,fldsA,null,cId);
            this.qbP = (CVGeneratorController.QueryBuilder)new CVGeneratorController.ProjectQueryBuilder(searchTerm,pNo,perP,flds,extrFlds,cId,qbA,this.sels);
            this.qbA = (CVGeneratorController.AllocationQueryBuilder)qbA;
            this.perP = perP;
            this.pNo = pNo;
        }

    }

    public class PicklistVal {
        @AuraEnabled
        public String value {
            get;
            private set;
        }
        @AuraEnabled
        public String label {
            get;
            private set;
        }
        @AuraEnabled
        public Boolean selected {
            get;
            private set;
        }

        public PicklistVal(String label, String value, Boolean selected){
            this.label = label;
            this.value = value;
            this.selected = selected;
        }
    }
    public class ProjectDTO {

        private Project__c p;

        @AuraEnabled
        public String name {
            get {
                return p.Name;
            }
            private set;
        }
        @AuraEnabled
        public String id {
            get {
                return p.Id;
            }
            private set;
        }
        @AuraEnabled
        public String status {
            get {
                return p.Current_status__c;
            }
            private set;
        }

        @AuraEnabled
        public String projName {
            get {
                return p.Name;
            }
            private set;
        }

        @AuraEnabled
        public Date startDate {
            get {
                return p.Start_date__c;
            }
            private set;
        }

        @AuraEnabled
        public Date endDate {
            get {
                return p.Start_date__c;
            }
            private set;
        }

        public ProjectDTO(Project__c p){
            this.p = p;
        }

    }

}