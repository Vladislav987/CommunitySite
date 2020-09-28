/**
 * Created by MaxymMirona on 02.05.2020.
 */

({
    init : function (component, event) {
        this.initializeRowDataToIterate(component);
        this.handleInitialState(component);
    },

    handleInitialState : function (component) {
        this.handleBlockedState(component);
        this.handleCheckedState(component);
    },

    handleBlockedState : function (component) {
        let blockRow = component.get("v.rowData").BlockRow;

        if (blockRow !== undefined) {
            component.set("v.isBlocked", blockRow.isBlocked);
        }
    },

    handleCheckedState : function (component) {
        let isBlocked = component.get("v.isBlocked");

        if (isBlocked) {
            component.set("v.isRowSelected", false);
        }
    },

    handleRowStyle : function (component) {
        let isBlocked = component.get("v.isBlocked");
        let globalId = component.getGlobalId();

        let rowElement = document.getElementById("datatable-row-" + globalId);

        if (rowElement) {
            this.handleBlockedStyle(rowElement, isBlocked);
        }
    },

    handleBlockedStyle : function (element, isBlocked) {
        if (isBlocked) {
            element.classList.add('blocked-row');
        } else {
            element.classList.remove('blocked-row');
        }
    },

    initializeRowDataToIterate : function (component){

        let rowDataToIterate = this.constructRowDataToIterate(component);

        this.handleRowDataHeader(component, rowDataToIterate);
    },

    constructRowDataToIterate : function (component) {
        let rowData = component.get("v.rowData");
        let columns = component.get("v.columns");
        let rowDataToIterate = [];

        columns.forEach(column => {
            let fieldTypeColumnAttributes = this.getFieldTypeColumnAttribute(column.type);
            let rowDataToIterateObject = {};

            if (fieldTypeColumnAttributes) {
                fieldTypeColumnAttributes.forEach(attribute => {
                    let property;

                    if (attribute.properties.fromData) {
                        property = this.dynamicallyGetValueByProperty(attribute.properties.path, [rowData, column]);
                    } else {
                        property = this.dynamicallyGetValueByProperty(attribute.properties.path, [column]);
                    }

                    if (typeof property == "function"){
                        switch (column.type) {
                            case "picklist" :
                                rowDataToIterateObject['valueSet'] = property(rowData, this.getPicklistValues);
                                break;
                        }
                    } else {
                        rowDataToIterateObject[attribute.attributeName] = property;
                    }
                });

                switch (column.type) {
                    case "id" :
                        rowDataToIterateObject['value'] = '/' + rowDataToIterateObject['value'];
                        break;
                    case "picklist" : this.handlePickListAttributes(component, rowDataToIterateObject);
                        break;
                }
            }

            rowDataToIterate.push(rowDataToIterateObject);
        });

        return rowDataToIterate;
    },

    handlePickListAttributes : function (component, rowDataToIterateObject) {
        if (rowDataToIterateObject.isDefaultValueFromValueSet && rowDataToIterateObject.valueSet) {
            if (rowDataToIterateObject.defaultValueFromValueSetIndex != undefined){
                if (rowDataToIterateObject['valueSet'][rowDataToIterateObject.defaultValueFromValueSetIndex]) {
                    this.setPickListTargetField(component, rowDataToIterateObject['valueSet'][rowDataToIterateObject.defaultValueFromValueSetIndex].Id);
                }

            } else {
                this.setPickListTargetField(component, rowDataToIterateObject['valueSet'][0]);
            }
        }
    },

    getPicklistValues : function (result) {
        return result;
    },

    getFieldTypeColumnAttribute : function (type) {
        let fieldTypesColumnAttributes = {
            url : [
                {attributeName : 'value', properties : {fromData : true, path  : 'fieldName'}},
                {attributeName : 'type', properties : {fromData : false, path : 'type'}},
                {attributeName : 'label', properties : {fromData : false, path : 'label'}},
                {attributeName : 'typeAttributesLabel', properties : {fromData : true, path : 'typeAttributes.label.fieldName'}},
                {attributeName : 'target', properties : {fromData : false, path : 'typeAttributes.target'}}
            ],
            picklist : [
                {attributeName : 'valueSet', properties : {fromData : true, path  : 'fieldName'}},
                {attributeName : 'type', properties : {fromData : false, path : 'type'}},
                {attributeName : 'label', properties : {fromData : false, path : 'label'}},
                {attributeName : 'targetField', properties : {fromData : false, path : 'fieldName'}},
                {attributeName : 'isDefaultValueFromValueSet', properties : {fromData : false, path : 'defaultValueFromValueSet.isTrue'}},
                {attributeName : 'defaultValueFromValueSetIndex', properties : {fromData : false, path : 'defaultValueFromValueSet.index'}},
                {attributeName : 'getPicklistValuesCallback', properties: {fromData: false, path : 'getPicklistValuesCallback'}}
            ],
            date : [
                {attributeName : 'value', properties : {fromData : true, path  : 'fieldName'}},
                {attributeName : 'type', properties : {fromData : false, path : 'type'}},
                {attributeName : 'label', properties : {fromData : false, path : 'label'}}
            ],
            currency : [
                {attributeName : 'value', properties : {fromData : true, path  : 'fieldName'}},
                {attributeName : 'type', properties : {fromData : false, path : 'type'}},
                {attributeName : 'label', properties : {fromData : false, path : 'label'}},
                {attributeName : 'typeAttributesCurrency', properties : {fromData : false, path : 'typeAttributes.currencyCode'}},
                {attributeName : 'typeAttributesMaximumSignificantDigits', properties : {fromData : false, path : 'typeAttributes.maximumSignificantDigits'}}
            ],
            number : [
                {attributeName : 'value', properties : {fromData : true, path  : 'fieldName'}},
                {attributeName : 'type', properties : {fromData : false, path : 'type'}},
                {attributeName : 'label', properties : {fromData : false, path : 'label'}}
            ],
            text : [
                {attributeName : 'value', properties : {fromData : true, path  : 'fieldName'}},
                {attributeName : 'type', properties : {fromData : false, path : 'type'}},
                {attributeName : 'label', properties : {fromData : false, path : 'label'}}
            ],
            percent : [
                {attributeName : 'value', properties : {fromData : true, path  : 'fieldName'}},
                {attributeName : 'type', properties : {fromData : false, path : 'type'}},
                {attributeName : 'label', properties : {fromData : false, path : 'label'}},
                {attributeName : 'decimalPlaces', properties : {fromData : false, path : 'decimalPlaces'}}
            ],
            id : [
                {attributeName : 'value', properties : {fromData : true, path  : 'fieldName'}},
                {attributeName : 'type', properties : {fromData : false, path : 'type'}},
                {attributeName : 'label', properties : {fromData : false, path : 'label'}},
                {attributeName : 'typeAttributesLabel', properties : {fromData : true, path : 'typeAttributes.label.fieldName'}},
                {attributeName : 'target', properties : {fromData : false, path : 'typeAttributes.target'}}
            ]
        };

        return fieldTypesColumnAttributes[type];
    },

    dynamicallyGetValueByProperty : function (path, sources) {
        let pathMembers = path.split('.');
        let result;

        pathMembers.forEach(member => {
            result = result == null ? sources[sources.length - 1][member] : result[member];
        });

        for (let i = 0; i < sources.length - 1; ++i) {
            result = sources[i][result];
        }

        return result;
    },

    handleRowDataHeader : function (component, rowDataToIterate) {
        let rowDataHeader = rowDataToIterate[0];

        rowDataToIterate.splice(0, 1);

        component.set("v.rowDataHeader", rowDataHeader);
        component.set("v.rowDataToIterate", rowDataToIterate);
    },

    handlePicklistChange : function (component, event) {
        this.setPickListTargetField(component, event.getSource().get("v.value"));
    },

    setPickListTargetField : function (component, value) {
        let rowData = component.get("v.rowData");
        let targetFieldName = component.get("v.columns").filter(column => {
            return column.type == 'picklist'
        })[0].fieldName;

        rowData[targetFieldName] = value;

        component.set("v.rowData", rowData);
    }

});