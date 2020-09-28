/**
 * Created by pz on 2019-04-15.
 */
({
    doInit: function (component, event, helper) {

        let rowActions = helper.getRowActions.bind(this, component);

        component.set('v.columns', [
            {label: 'Name', fieldName: 'name', type: 'text', editable: false, typeAttributes: { required: true }},
            {label: 'Status', fieldName: 'status', type: 'text', editable: false },
            {label: 'Project', fieldName: 'projName', type: 'text', editable: false},
            {label: 'Start Date', fieldName: 'startDate', type: 'Date', editable: false},
            {label: 'End Date', fieldName: 'endDate', type: 'Date', editable: false}
            //,{ type: 'action', typeAttributes: { rowActions: rowActions } }

        ]);

        helper.doSearch(component, event, helper);

    },
    doRefresh: function (component, event, helper) {
        helper.doSearch(component, event, helper);
    },
    reloadFrame: function (component, event, helper) {
        let ifrmURL = component.get("v.iFrameURL");
        component.set("v.iFrameURL","");
        component.set("v.iFrameURL",ifrmURL);
    },

    genCV: function (component, event, helper) {
        helper.doGenerateCV(component, event, helper);
    },
    updateSelected : function (component, event, helper) {
        let selectedRows = event.getParam("selectedRows");
        let selectedRowsSet = new Set();
        
		let lds = component.get("v.lds");        
        let ldsSet = new Set();
        
        for(let j = 0; j < lds.length; j++){
            ldsSet.add(lds[j].id);
        }
        for(let k = 0; k < selectedRows.length; k++){
            selectedRowsSet.add(selectedRows[k].id);
        }
        
        let sels = component.get("v.sels");
        let selsSet = new Set(sels);

        for(let i = 0; i < Array.from(ldsSet).length; i++){     
             
            let ldId = Array.from(ldsSet)[i];

            if(selectedRowsSet.has(ldId) && !selsSet.has(ldId)){
                selsSet.add(ldId);
            } else if (selsSet.has(ldId) && !selectedRowsSet.has(ldId)) {
                selsSet.delete(ldId);
            }            
        }
        component.set("v.sels", Array.from(selsSet));
        helper.doSearch(component, event, helper);        
    },
    launchFlow : function (component, event, helper) {
        helper.launchFlow(component, event, helper);
    },
    handleStatusChange: function(component, event, helper) {
        if(event.getParam("status") === "FINISHED") {

            let outputVariables = event.getParam("outputVariables");

            for(var i = 0; i < outputVariables.length; i++) {
                let outputVar = outputVariables[i];
                // Pass the values to the component's attributes
                if(outputVar.name === "Context_Lead") {
                    helper.doSaveLead(component,outputVar.value);
                }
            }
            // trigger modal close, will run destroying callback for flow element
            component.get("v.overlayPanel")[0].close();
        }
    },

    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');

        switch (action.name) {
            case 'edit':
                helper.launchFlow(component, event, helper);
                break;
            case 'delete':
                break;
        }
    },
    //Function for finding the records as for given search input
    searchRecords : function (component,event,helper) {
        let timer = component.get("v.timer");
        if(timer){
            clearTimeout(timer);
        }

        // Set new timeout
        timer = window.setTimeout(
            $A.getCallback(() => {
                // Send search request
                helper.doSearch(component, event, helper, 1);
                // Clear timeout
                component.set("v.timer", null);
            }),
            300 // Wait for 300 ms before sending search request
        );
        component.set("v.timer", timer);
    },

    handleNext : function (component,event,helper) {
        let pn = component.get("v.pageNumber");
        // hack to prevent additional onchange event on page flip
        let tbl = component.find("pTable");
        tbl.set("v.selectedRows", []);
        try{
            helper.doSearch(component, event, helper, pn+1);
            component.set("v.pageNumber",pn+1);
        } catch(e){

        }

    },
    handlePrev : function (component,event,helper) {
        let pn = component.get("v.pageNumber");
        // hack to prevent additional onchange event on page flip
        let tbl = component.find("pTable");
        tbl.set("v.selectedRows", []);
        if(pn -1 > 0){
            try{
                helper.doSearch(component, event, helper,pn-1);
                component.set("v.pageNumber",pn-1);
            } catch(e){

            }

        }
    }
})