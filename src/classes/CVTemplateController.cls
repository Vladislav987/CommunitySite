/**
 *
 * @author: pz - Customertimes Corp.
 * @created: 22.04.2019
 * @version: 0.1
 */
public with sharing class CVTemplateController {
    /* URL params
    *
    */
    @TestVisible
    private static final String PROJECT_IDS_PARAM = 'pIds';
    @TestVisible
    private static final String DOC_TYPE_PARAM = 'rType';
    @TestVisible
    private static final String SPECIALIZATION_PARAM = 'spec';

    private static final String CV_LOGO = 'CV_Logo';

    /* Page rendering setup
    *  returns renderAs => contentType
    *
    */
    private static final Map<String,Map<String,String>> TYPE_INFOS = new Map<String,Map<String,String>> {
            'pdf' => new Map<String,String>{ 'pdf' => ''}
            ,'msword' => new Map<String,String>{ '' => 'application/vnd.msword'}
            ,'msword1' => new Map<String,String>{ '' => 'application/msword'}
            ,'vf' => new Map<String,String>{ '' => ''}
    };
    /* Standard controller
    *
    */
    private final ApexPages.StandardController ctrl;
    public Boolean isWord{
        public get {
            if (this.isWord == null ){
                this.isWord = false;
            }
            return this.isWord;
        }
        private set;
    }
    /* Value of specialization parameter
    *
    */
    public String spec {
        public get;
        private set;
    }
    /* Value of renderAs attribute
    *
    */
    public String rendAs{
        public get;
        private set;
    }
    /* Value of content type attribute
    *
    */
    public String contType {
        public get;
        private set;
    }

    /* Relevant projects
    *
    */
    public List<ProjectDTO> projs {
        public get{
            if(this.projs == null){
                this.projs = new List<ProjectDTO>();

                for( Project__c prj :[
                    SELECT Id
                        ,Name
                        ,Account__r.Name
                        ,Project_description__c
                        ,(SELECT Id,Reason__c FROM Allocations__r)
                        ,Technologies__c
                    FROM Project__c
                    WHERE Id IN:projIds
                ]) {
                    projs.add(new ProjectDTO(prj,this));
                }
            }
            return this.projs;
        }
        private set;
    }

    public Set<Id> projIds {
        get{
            if(this.projIds == null){
                this.projIds = new Set<Id>();
                for( Allocation__c alloc :[SELECT Project__c FROM Allocation__c WHERE Contractor__c =: ctrl.getId()] ){
                    this.projIds.add(alloc.Project__c);
                }
            }
            return this.projIds;
        }
        private set;
    }
    public Set<String> techsKeys {
        public get{
            return techs.keySet();
        }
        private set;
    }
    public Map<String,Set<String>> techs {
        get{
            if(this.techs == null){
                this.techs = new Map<String,Set<String>>();
                Contractor__c thisCont = (Contractor__c)ctrl.getRecord();
                Set<String> contrTechs;
                if(!String.isEmpty(thisCont.Detailed_Technical_Skills__c)){
                    contrTechs = new Set<String>(thisCont.Detailed_Technical_Skills__c.split(';'));
                }

                if(contrTechs == null || contrTechs.isEmpty()){
                    return this.techs;
                } else {

                }

                // form indexes from metadata
                Map<String,Set<String>> index = new Map<String,Set<String>>();
                for(Technical_Skill_Caregories__mdt tsc :[SELECT Id,Category__c,SubCategories__c FROM Technical_Skill_Caregories__mdt]){
                    if(!String.isEmpty(tsc.Category__c) && !String.isEmpty(tsc.SubCategories__c)){
                        Set<String> sbcats = new Set<String>(tsc.SubCategories__c.split(','));
                        Set<String> editSbCats = new Set<String>();

                        for(String sbcat :sbcats){
                            if(!String.isEmpty(sbcat)){
                                editSbCats.add(sbcat.trim());
                            }
                        }
                        index.put(tsc.Category__c,editSbCats);
                    }
                }
                Set<String> found = new Set<String>();
                // sort tech skills
                for(String tech : contrTechs){
                    for(String cat :index.keySet()){
                        Set<String> subCats = index.get(cat);
                        if(subCats.contains(tech)){
                            Set<String> contrSubCats = this.techs.get(cat);
                            if(contrSubCats == null){
                                this.techs.put(cat,new Set<String>());
                            }
                            this.techs.get(cat).add(tech);
                            found.add(tech);
                            break;
                        }
                    }
                }
                contrTechs.removeAll(found);
                if(!contrTechs.isEmpty()){
                    this.techs.put('Other',contrTechs);
                }

            }
            return this.techs;
        }
        private set;
    }

    public List<String> certs {
        get{
            if(this.certs == null){
                this.certs = new List<String>();
                Contractor__c thisCont = (Contractor__c)ctrl.getRecord();
                if(!String.isEmpty(thisCont.Certification__c)){
                    certs = thisCont.Certification__c.split(';');
                }
            }
            return this.certs;
        }
        private set;
    }

    public List<String> certPics {
        get{
            if(this.certPics == null){
                this.certPics = new List<String>();
                if(this.certs != null && !this.certs.isEmpty()){
                    this.certPics = this.getDocumentUrls(this.certs);
                }
            }
            return this.certPics;
        }
        private set;
    }

    public Map<String,Responsibilities__mdt> rspnsblts {
        get{
            if(rspnsblts == null){
                rspnsblts = new Map<String,Responsibilities__mdt>();
                Contractor__c thisCont = (Contractor__c)ctrl.getRecord();
                for(Responsibilities__mdt resp :[SELECT Id,Responsibilities__c,Role__c,Specialization__c FROM Responsibilities__mdt WHERE Role__c =:thisCont.Resource_Type__c]){
                    if(!String.isEmpty(resp.Specialization__c)){
                        rspnsblts.put(resp.Role__c+resp.Specialization__c,resp);
                    } else {
                        rspnsblts.put(resp.Role__c,resp);
                    }
                }
            }
            return rspnsblts;
        }
        private set;
    }

    public String getDocumentUrl(String docName) {
        String docUrl = '';
        if(!String.isEmpty(docName)){
            List<String> docUrls = this.getDocumentUrls(new List<String>{docName});
            if(!docUrls.isEmpty()){
                docUrl = docUrls[0];
            }
        }
        return docUrl;
    }

    public List<String> getDocumentUrls(List<String> docNames) {
        List<String> docUrls = new List<String>();
        if(docNames != null && !docNames.isEmpty()){
            List<Document> docs = new List<Document>([SELECT Id,Name FROM Document WHERE Name IN :docNames]);
            Map<String,Document> docsByName = new Map<String,Document>();
            for(Document doc :docs){
                docsByName.put(doc.Name.toLowerCase(),doc);
            }
            for(String docName :docNames){
                if(!String.isEmpty(docName)){
                    Document thisDoc = docsByName.get(docName.toLowerCase());
                    if(thisDoc != null){
                        docUrls.add(URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.ImageServer?id='+thisDoc.Id+'&oid='+UserInfo.getOrganizationId());
                    }
                }
            }
        }
        return docUrls;
    }
    public String getLogoUrl() {
        return this.getDocumentUrl(CV_LOGO);
    }

    public CVTemplateController(ApexPages.StandardController ctrl){
        if(!System.Test.isRunningTest()){
            ctrl.addFields(
                    new List<String>{
                            Contractor__c.Certification__c.getDescribe().getName()
                            ,Contractor__c.Detailed_Technical_Skills__c.getDescribe().getName()
                    }
            );
        }
        this.ctrl = ctrl;

        final String rParam =  System.currentPageReference().getParameters().get(DOC_TYPE_PARAM);
        Map<String,String> stup = TYPE_INFOS.get(rParam);

        String docName = '';
        if(stup == null){
            stup = TYPE_INFOS.get(new List<String>( TYPE_INFOS.keySet() )[0]);
        } else {
            if(!String.isEmpty(rParam) && rParam.startsWith('msword')){
                Contractor__c thisCont = (Contractor__c)ctrl.getRecord();
                String dynamic = (''+thisCont.Name+System.today()).replaceAll('[^a-zA-Z0-9]', '-');
                docName = '#'+dynamic+'.doc';
                this.isWord = true;
            }
        }
        this.rendAs = new List<String>(stup.keySet())[0];
        this.contType = stup.get(new List<String>(stup.keySet())[0])+docName;

        final String pjsParam =  System.currentPageReference().getParameters().get(PROJECT_IDS_PARAM);
        final String specParam =  System.currentPageReference().getParameters().get(SPECIALIZATION_PARAM);

        if(!String.isEmpty(pjsParam)){
            try{
                projIds = (Set<Id>)JSON.deserialize(pjsParam,Set<Id>.class);
            } catch (Exception ex){
                System.debug('Bad project id array passed '+ex.getMessage());
            }
        }
        if(!String.isEmpty(specParam)){
            this.spec = specParam;
        }
    }

    public class ProjectDTO{

        public Project__c pj{
            get;
            private set;
        }
        private CVTemplateController ctxt;

        public List<String> technologies {
            get{
                List<String> techs = new List<String>();
                if(!String.isEmpty(pj.Technologies__c)){
                    techs = pj.Technologies__c.split(';');
                }
                return techs;
            }
            private set;
        }
        public String technology {
            get{
                return pj.Technologies__c;
            }
            private set;
        }
        public String name {
            get{
                return pj.Name;
            }
            private set;
        }
        public String description {
            get{
                return pj.Project_description__c;
            }
            private set;
        }

        public Responsibilities__mdt responsibility {
            get{
                Contractor__c thisCont = (Contractor__c)ctxt.ctrl.getRecord();
                if(ctxt.rspnsblts.get(thisCont.Resource_Type__c+ctxt.spec) != null){
                    // try to find combo on resource type + spec
                    return ctxt.rspnsblts.get(thisCont.Resource_Type__c+ctxt.spec);
                } else {
                    // if no combo, return default responsibility for role
                    return ctxt.rspnsblts.get(thisCont.Resource_Type__c);
                }
            }
            private set;
        }

        public ProjectDTO(Project__c pj, CVTemplateController ctxt){
            this.pj = pj;
            this.ctxt = ctxt;
        }
    }
}