/**
 * Created by MaxymMirona on 17.12.2019.
 */

({
    onInit : function (component, event) {
        component.set("v.isLoading", true);
        let action = component.get("c.getRelatedListInitData");

        action.setParams({
            projectId : component.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            let state = response.getState();
            if(state === "SUCCESS") {
                let relatedListInfo = response.getReturnValue();

                let statuses = relatedListInfo.statuses.map((item, index) => {
                    let statusInList = {};
                    statusInList.label = item;
                    statusInList.value = (index).toString();
                    return statusInList;
                });
                component.set("v.statuses", statuses);

                let types = relatedListInfo.types.map((item, index) => {
                    let typeInList = {};
                    typeInList.label = item;
                    typeInList.value = (index).toString();
                    return typeInList;
                });
                component.set("v.types", types);

                let contractors = relatedListInfo.dataTable.contractorsList;
                component.set("v.contractors", contractors);

                this.getAllocations(component, relatedListInfo);
                this.doFilterAllocations(component, event);
                component.set("v.isLoading", false);
            }  else if (state === "ERROR") {
                console.log(action.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },

    getAllocations : function (component, relatedListInfo) {
        let dataTable = relatedListInfo.dataTable;
        let records = dataTable.recordsList;

        records.forEach(function (record) {
            record.linkName = '/' + record.Id;
            record.monthlyReportsNumber = record.Monthly_Reports__r == undefined ? 0 : record.Monthly_Reports__r.length;
        });                                                                                                             //Add link attribute to Allocations array

        let fieldsTypes = dataTable.fieldsTypes;

        let fieldsList = dataTable.fieldsList;

        let columns = this.getColumnsForRelatedList(fieldsList, fieldsTypes, records);

        component.set("v.records", records);
        component.set("v.filteredRecords", records);
        component.set("v.columns", columns);
    },

    getColumnsForRelatedList : function (fieldsList, fieldsTypes, records) {
        console.log(fieldsList);
        let columns = Object.keys(fieldsList).map((key) => {
            if (fieldsList[key] === 'Fact_hours__c') {
                return {
                    label: key,
                    fieldName: fieldsList[key],
                    type: 'number',
                    editable: true,
                    cellAttributes: {alignment: 'center'}
                }
            } else if (fieldsList[key] === 'Name') {
                return {
                    label: 'Name', fieldName: 'linkName', type: 'url',
                    typeAttributes: {label: {fieldName: 'Name'}, target: '_blank'}
                };
            } else if (fieldsTypes[key] === 'CURRENCY') {
                return {
                    label: key,
                    fieldName: fieldsList[key],
                    type: 'currency',
                    editable: false,
                    typeAttributes: {currencyCode: 'USD', maximumSignificantDigits: 5},
                    cellAttributes: {alignment: 'left'}
                }
            } else if (fieldsTypes[key] === 'PERCENT' || fieldsTypes[key] === 'DOUBLE') {
                return {
                    label: key,
                    fieldName: fieldsList[key],
                    type: 'number',
                    editable: false,
                    cellAttributes: {alignment: 'center'}
                }
            } else if (fieldsTypes[key] === 'DATE' || fieldsTypes[key] === 'DATETIME') {
                return {label: key, fieldName: fieldsList[key], type: 'date', editable: false}
            } else if (fieldsTypes[key] === 'REFERENCE') {
                for (let i = 0; i < records.length; i++) {
                    function getPropByString(obj, propString) {
                        if (!propString)
                            return obj;

                        var prop, props = propString.split('.');

                        for (var i = 0, iLen = props.length - 1; i < iLen; i++) {
                            prop = props[i];

                            var candidate = obj[prop];
                            if (candidate !== undefined) {
                                obj = candidate;
                            } else {
                                break;
                            }
                        }
                        return obj[props[i]];
                    }

                    let rec = records[i];
                    rec[fieldsList[key]] = getPropByString(rec, [fieldsList[key]].toString());
                }
                return {label: key, fieldName: fieldsList[key], type: 'text', editable: false}
            } else {
                return {label: key, fieldName: fieldsList[key], type: 'text', editable: false}
            }
        });

        columns.push({
            type: 'action',
            typeAttributes: { rowActions: this.getRowActions }});
        return columns;
    },

    getRowActions : function(row, doneCallback){
        let action = [];

        if (
            row['Allocation__c'] != 0 &&
            row['Allocation_Type__c'] !== 'Leave' &&
            row['Allocation_Type__c'] !== 'Overrun' &&
            row['Contractor__c'] != null &&
            row['RecordType']['Name'] === 'Project' &&
            row['Status__c'] === 'Active'
        ){
            action.push(
                {label: 'Leave', name: 'leave'},
                {label: 'Overrun', name: 'overrun'}
            );
        } else if (
            (
                row['Contractor__c'] == null ||
                row['RecordType']['Name'] !== 'Project' ||
                row['Status__c'] !== 'Active' ||
                row['Allocation__c'] == 0
            ) &&
            row['Allocation_Type__c'] !== 'Leave' &&
            row['Allocation_Type__c'] !== 'Overrun'
        ){
            action.push(
                {label: 'Leave', name: 'leave', disabled: true},
                {label: 'Overrun', name: 'overrun', disabled: true}
            );
        } else if (row['Allocation_Type__c'] === 'Leave') {
            if (row['monthlyReportsNumber'] == 0 && row['Allocation__c'] == 0) {
                action.push(
                    {label: 'Delete', name: 'delete'}
                )
            } else {
                action.push(
                    {label: 'Delete', name: 'delete', disabled: true}
                )
            }
        } else if (row['Allocation_Type__c'] === 'Overrun'){
            if (row['monthlyReportsNumber'] == 0 && row['Allocation__c'] == 0) {
                action.push(
                    {label: 'Delete', name: 'delete'}
                )
            } else {
                action.push(
                    {label: 'Delete', name: 'delete', disabled: true}
                )
            }
            action.push(
                {label: 'Leave', name: 'leave'}
            );
        }
        doneCallback(action);
    },

    doFilterAllocations : function (component, event) {
        let records = component.get("v.records");
        let filterCondition = {
            Status__c: component.get("v.selectedStatus"),
            Allocation_Type__c: component.get("v.selectedType"),
            Contractor__c: component.get("v.selectedContractor")
        };

        for (let key in filterCondition) {
            if (filterCondition[key] != "" && filterCondition[key] != null){
                records = records.filter(function (record) {
                    if (filterCondition['Contractor__c'] === "Empty Contractor" && key.toString() == "Contractor__c"){
                        return record[key] === undefined;
                    }
                    else {
                        return record[key] === filterCondition[key];
                    }
                });
            }
        }

        component.set("v.filteredRecords", records);
    },

    doHandleRowAction: function (component, event) {
        const actionName = event.getParam('action').name;
        let allocation = event.getParam('row');
        let projectId = component.get("v.recordId");
        let action;
        let toastMessage;

        if (actionName == 'leave') {
            component.set("v.isLoading", true);
            action = component.get("c.createNullableAllocation");
            toastMessage = "The record has been created successfully.";

            action.setParams({
                projectId: projectId,
                allocation: allocation,
                allocationType: actionName,
                overrunType : ''
            });
        }
        else if (actionName === 'overrun'){
            let modalBody;
            $A.createComponent("c:AllocationsRelatedListOverrunButton", {projectId: projectId, allocation: allocation, allocationType: actionName},
                function(content, status) {
                    if (status === "SUCCESS") {
                        modalBody = content;
                        component.find('overlayLib').showCustomModal({
                            header: "Create Overrun Allocation",
                            body: modalBody,
                            showCloseButton: true
                        })
                    }
                });
        }
        else {
            component.set("v.isLoading", true);
            action = component.get("c.deleteNullableAllocation");
            toastMessage = "The record has been deleted successfully.";

            action.setParams({
                allocation: allocation
            });
        }
        if (action) {
            action.setCallback(this, function (response) {
                let state = response.getState();
                if (state === "SUCCESS") {
                    let result = response.getReturnValue();
                    let toastEvent = $A.get("e.force:showToast");
                    if (toastEvent) {
                        if (result === 'Success') {
                            toastEvent.setParams({
                                "title": "Success!",
                                "message": toastMessage,
                                "type": "success"
                            });
                            this.onInit(component, event);
                        } else {
                            toastEvent.setParams({
                                "title": "Failure!",
                                "message": result,
                                "type": "error"
                            });
                        }
                        toastEvent.fire();
                    }
                } else if (state === "ERROR") {
                    console.log(action.getError()[0].message);
                }
                component.set("v.isLoading", false);
            });
            $A.enqueueAction(action);
        }
    },

    onCreateNewRecord : function (component, event) {
        let projectId = component.get("v.recordId");
        let modalBody;

        $A.createComponent("c:AllocationRelatedListNewButton", {sObjectId: projectId},
            function(content, status) {
                if (status === "SUCCESS") {
                    modalBody = content;
                    component.find('overlayLib').showCustomModal({
                        header: "New Allocation",
                        body: modalBody,
                        showCloseButton: true
                    })
                }
            });
    }
});