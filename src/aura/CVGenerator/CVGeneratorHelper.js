/**
 * Created by pz
 */
({
    doSearch: function (component, event, helper, pnNo) {
        let request = component.find("request");

        let st = component.get("v.searchTerm");
        let pNo = $A.util.isEmpty(pnNo) ? component.get("v.pageNumber") : pnNo;
        let perP = component.get("v.pageSize");
        let clmns = component.get("v.columns");
        let cId = component.get("v.recordId");
        let sels = component.get("v.sels");

        let tbl = component.find("pTable");                
        tbl.set("v.selectedRows", []);

        let flds = [];

        flds = clmns.map(function(clmn){
            return clmn.fieldName;
        });

        //String searchTerm, Integer pNo, Integer perP
        request.enqueue("c.getContext", {searchTerm: st, pNo:pNo, perP: perP, extrFlds:flds, cId: cId, sels: sels})
            .then(function (resp) {
                component.set("v.lds",JSON.parse(resp.lds));
                component.set("v.total",JSON.parse(resp.total));

                let tbl = component.find("pTable");
                tbl.set("v.selectedRows", resp.sels);
                component.set("v.sels", resp.sels );

                if($A.util.isEmpty(component.get("v.specs"))) {
                    component.set("v.specs", resp.specs);
                }
                if($A.util.isEmpty(component.get("v.spec"))){
                    component.set("v.spec", resp.spec.value);
                }

            })
            .catch(function (error) {
                console.log('error fetching projects :', error);
                helper.doShowToast(component, 'Oops...','Could not search projects '+error,'error');

                throw new Error ("Could not search "+error);
            });

    },

    getRowActions: function (component, row, doneCallback) {
        var acts = [{
            'label': 'Edit',
            'iconName': 'utility:edit',
            'name': 'edit'
        }];

        if (row['Status'] === 'Converted') {
            acts[0]['disabled'] = 'true';
        }

        doneCallback(acts);

    },

    doShowToast: function (component, ttl, msg, lvl) {
        component.find("notifLib").showToast({
            "title": ttl,
            "message": msg,
            "variant": lvl,
            "duration": 500
        });
    },
    doSaveLead: function (component, ld) {
        let request = component.find("request");
        let _this = this;
        request.enqueue("c.upsertLead", {ldStr: JSON.stringify(ld)})
            .then(function (resp) {
                // refresh view
                window.setTimeout(
                    $A.getCallback(() => {
                        _this.doSearch(component, event, _this);
                    }),
                    1
                );

            })
            .catch(function (error) {
                _this.doShowToast(component, 'Oops...','Could not save lead: '+error,'error');
                console.log('error saving leads :', error);
            });

    },
    doGenerateCV : function (component, event, helper) {
       
        let ifr = component.get("v.iFrameURL");
        let sels = component.get("v.sels");

        ifr = ifr + '?id='+encodeURI(component.get("v.recordId"));

        ifr = ifr + '&rType='+encodeURI(event.getParam("value"));

        if(typeof sels !== 'undefined' && sels.length > 0) {
            ifr = ifr + '&pIds=' + encodeURI(JSON.stringify(sels));
        }
        if(!$A.util.isEmpty(component.get("v.spec"))){
            ifr = ifr + '&spec='+encodeURI(component.get("v.spec"));
        }


        console.log('==> Setting url '+ifr);

        component.set("v.iFrameURL",ifr);
        component.set("v.wStep",1);
        if(event.getParam("value") === 'msword'){
            component.set("v.isDownload",true);
        }
    },

    launchFlow : function (component, event, helper) {
        let flwVars = [
            { name : "Is_Community", type : "Boolean", value: true }
            ,{ name : "Context_Lead", type : "SObject", value: {
                    "Id" : "",
                    "FirstName" : ""
                }
            }
        ];

        if(event){

            let ld = event.getParam('row');

            if(ld){
                let bdStr = $A.util.isEmpty(ld.HealthCloudGA__BirthDate__c) ? '' : ld.HealthCloudGA__BirthDate__c ;
                ld.HealthCloudGA__BirthDate__c = null;
                //ld.HealthCloudGA__BirthDate__c = new Date(ld.HealthCloudGA__BirthDate__c);

                flwVars[1] = {
                    name : "Context_Lead", type : "SObject", value: ld
                };
                flwVars[2] = { name : "Birth_Date_String", type : "String", value: bdStr };
            }


        }

        $A.createComponent("lightning:flow", {"aura:id":"flowData","onstatuschange":component.getReference("c.handleStatusChange")},
            function(content, status) {
                if (status === "SUCCESS") {

                    content.startFlow(component.get("v.createFlow"),flwVars);

                    component.find("overlayLib").showCustomModal({
                        header: "New Enrollment",
                        body: content,
                        showCloseButton: true,
                        closeCallback: function() {
                            // destroy flow component to avoid conflicts on consequent calls
                            content.destroy();
                        }
                    }).then(function (overlay) {
                        component.set("v.overlayPanel", overlay);
                    });
                }
            }
        );
    }
})