({
    init:function (component) {
        let action = component.get("c.getProjects");
        let opportunityId = component.get("v.recordId");

        action.setParam(
            "opportunityId", opportunityId
        );

        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let resp = response.getReturnValue();
                let projects = resp["projects"];
                let allocations = resp["recordsList"];
                let fieldSet = resp["fieldsList"];
                let fieldsTypes = resp["fieldsTypes"];
                if (projects.length > 0 && allocations.length > 0) {
                    let columns = this.getColumnsForRelatedList1(fieldSet, fieldsTypes, allocations);

                    component.set("v.projects", projects);
                    component.set("v.allocations", allocations);
                    component.set("v.columns", columns);
                    component.set("v.showSpinner", false);
                }else if (allocations.length === 0){
                    this.showMessage(component, 'warning', 'You don`t have any related Allocations with record type `Booking Request` and status `New`');
                    component.find("overlayLib").notifyClose();

                }else{
                    this.showMessage(component, 'warning', 'You don`t have any related `Projects`!');
                    component.find("overlayLib").notifyClose();

                }
            }
        });
        $A.enqueueAction(action);
    },

    getColumnsForRelatedList1 : function (fieldsList, fieldsTypes, records) {
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
                    label: 'Name', fieldName: 'Name', type: 'String',
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

        return columns;
    },

    updateAllocations: function (component) {
        let action = component.get("c.transferAllocations");
        let selectedAllocations = component.find("dataTable").getSelectedRows();
        let projectId = component.find('select').get('v.value');
        let opportunityId = component.get("v.recordId");
        let showStep = component.get("v.showStep");
        let isRejectAllocation;

        if (projectId === 'choose'){
            this.showMessage(component, 'warning', 'You forgot to select Project!')
            return;

        } else if (selectedAllocations.length === 0){
            this.showMessage(component, 'warning', 'You forgot to select any Allocation!')
            return;

        } else if (showStep) {
            isRejectAllocation = component.find('answer').get('v.value');

            if (isRejectAllocation === 'choose') {
                this.showMessage(component, 'warning', 'You forgot to choose what we need to do with unselected Allocations!')
                return;
            }
        }
            let isRejectedUnselected = showStep === false ? false : component.find('answer').get('v.value');

        action.setParams({
                "projectId": projectId,
                "opportunityId": opportunityId,
                "allocations": selectedAllocations,
                "isRejectUnselected": isRejectedUnselected

            });

            action.setCallback(this, function (response) {
                let state = response.getState();
                if (state === 'SUCCESS'){
                    this.showMessage(component,'success', 'We successfully transferred allocations.')
                    component.find("overlayLib").notifyClose();


                }else {
                    console.error(response.getError()[0].message);
                    this.showMessage(component,'error', 'An unexpected error, please contact an administrator.')

                }

            });
            $A.enqueueAction(action);

    },

    checkUnselectedRows:function (component) {
        let selectedRows = component.find("dataTable").getSelectedRows();
        let allocations = component.get("v.allocations");

        if(selectedRows.length === allocations.length){
            component.set("v.showStep", false);

        }else{
            component.set("v.showStep", true);

        }
    },

    showMessage:function (component, variant, message) {
        component.find('notifLib').showToast({
            "variant": variant,
            "header": "Something has gone wrong!",
            "message": message
        });
    },

});