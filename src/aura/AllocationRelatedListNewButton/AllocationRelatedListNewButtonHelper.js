/**
 * Created by MaxymMirona on 10.01.2020.
 */

({
    onInit : function(component, event){
        let action = component.get("c.getAllocationRecordTypes");

        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let allocationRecordTypes = response.getReturnValue();

                allocationRecordTypes = Object.keys(allocationRecordTypes).map(function (key) {
                    return {
                        value : key,
                        label : allocationRecordTypes[key]
                    }
                });
                this.getRelationshipFieldApiNameFromAllocationsMapping(component);

                component.set("v.selectedAllocationRecordType", allocationRecordTypes[0].value);
                component.set("v.allocationRecordTypes", allocationRecordTypes);
                component.set("v.isLoading", false);
            }  else if (state === "ERROR") {
                console.log(action.getError()[0].message);
            }
        });

        $A.enqueueAction(action);
    },

    getRelationshipFieldApiNameFromAllocationsMapping : function(component){
        let action = component.get("c.getRelationshipFieldApiNameFromAllocationsMapping");

        action.setParams({
            "sObjectId" : component.get("v.sObjectId")
        });

        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let relationshipFieldApiName = response.getReturnValue();
                component.set("v.relationshipFieldApiName", relationshipFieldApiName);
            } else {
                console.log(action.getError()[0].message);
            }
        });

        $A.enqueueAction(action);
    },

    onCancel : function(component, event){
        component.find("overlayLib").notifyClose();
    },

    onCreateNewRecord : function (component, event) {
        let createRecordEvent = $A.get("e.force:createRecord");
        let params = this.constructCreateNewRecordPrepopulateFieldsObject(component);

        createRecordEvent.setParams(params);

        createRecordEvent.fire();
    },

    constructCreateNewRecordPrepopulateFieldsObject : function (component) {
        let params = {};
        let relationshipFieldApiName = component.get("v.relationshipFieldApiName");

        params['entityApiName'] = 'Allocation__c';
        params['defaultFieldValues'] = {};
        params['defaultFieldValues']['RecordTypeId'] = component.get("v.selectedAllocationRecordType");
        params['defaultFieldValues'][relationshipFieldApiName] = component.get("v.sObjectId");

        return params;
    }
});