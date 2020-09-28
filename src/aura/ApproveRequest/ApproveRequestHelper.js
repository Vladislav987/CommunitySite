/**
 * Created by ArtemShevchenko on 11.11.2019.
 */

({
    fetchNewData: function (component, event, objectName) {
        let actions = [
            {label: 'Show details', name: 'view'},
            {label: 'Edit', name: 'edit'},
            {label: 'Show request', name: 'request'}
        ];
        let getRecords = component.get("c.initData");
        getRecords.setParams({'objectName': objectName});
        getRecords.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS') {
                let records = response.getReturnValue().recordsList;
                records.forEach(function(record){
                    record.linkName = '/'+record.Id;
                    record.projectLinkName = '/' + record.Project__c;
                });
                component.set("v.data", records);
                if (response.getReturnValue().recordsList.length === 0) {
                    component.set("v.hasRecords", false);
                } else {
                    component.set("v.hasRecords", true);
                }
                let data = response.getReturnValue().fieldsList;
                let fieldsTypes = response.getReturnValue().fieldsTypes;
                let columns = this.getColumnsForRelatedList(data, fieldsTypes, records);
                columns.push({
                    type: 'action',
                    typeAttributes: { rowActions: actions }});
                component.set("v.columns", columns);
            }
        });
        $A.enqueueAction(getRecords);
    },
    createToast: function (component, event, title, type, msg) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type": type,
            "message": msg
        });
        toastEvent.fire();
    },
    checkForEmptySelectedRows: function (cmp, evt, hlp) {
        if(cmp.find('dataTable').getSelectedRows().length === 0){
            hlp.createToast(cmp, evt, 'Sorry', 'error', 'You did not select any records');
            return false;
        }
        return true;
    },

    getColumnsForRelatedList : function (fieldsList, fieldsTypes, records) {
        let columns = Object.keys(fieldsList).map((key) => {
            if (fieldsList[key] === 'Name') {
                return {
                    label: 'Name', fieldName: 'linkName', type: 'url',
                    typeAttributes: {label: {fieldName: 'Name'}, tooltip:{fieldName: 'Name'}, target: '_blank'}
                };
            } if (fieldsList[key] === 'ProjectName__c') {
                return {
                    label: 'Project Name', fieldName: 'projectLinkName', type: 'url',
                    typeAttributes: {tooltip: {fieldName: 'ProjectName__c'}, label: {fieldName: 'ProjectName__c'}, target: '_blank'},

                };
            } else if (fieldsTypes[key] === 'CURRENCY') {
                return {
                    label: key,
                    fieldName: fieldsList[key],
                    type: 'currency',
                    editable: false,
                    typeAttributes: {maximumSignificantDigits: 5},
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
            } else if (fieldsTypes[key] === 'BOOLEAN'){
                return {
                    label: key,
                    fieldName: fieldsList[key],
                    type: 'boolean',
                    editable: false,
                    cellAttributes: {alignment: 'center'}
                }
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
    }
});