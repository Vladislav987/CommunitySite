/**
 * Created by MaxymMirona on 23.12.2019.
 */

({
    doInit : function (component, event) {
        component.set("v.isLoading", true);
        let action = component.get("c.getRelatedListInitData");

        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let relatedListInfo = response.getReturnValue();
                this.setUpToDateRates(component, relatedListInfo);

                component.set("v.isLoading", false);
            } else if (state === "ERROR") {
                console.log(action.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },

    saveDataTable : function (component, event){
        let action = component.get("c.upsertDatedConversionRate");
        let toastEvent = $A.get("e.force:showToast");

        action.setParams({
            recordsList : event.getParam('draftValues')});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                debugger;
                if (toastEvent) {
                    if (result === "Success") {
                        toastEvent.setParams({
                            "title": "Success!",
                            "type" : "success",
                            "message": "The record has been updated successfully."
                        });
                    } else {
                        toastEvent.setParams({
                            "title": "Error",
                            "type" : "error",
                            "message": result
                        });
                    }
                    toastEvent.fire();
                }
                if ($A.get('e.force:refreshView')) {
                    $A.get('e.force:refreshView').fire();
                }
                component.set("v.isLoading", false);
            }
            else if (state === "ERROR") {
                console.log(action.getError()[0].message);
            }

        });
        $A.enqueueAction(action);

    },

    setUpToDateRates : function (component, relatedListInfo) {
        let dataTable = relatedListInfo.dataTable;
        let records = dataTable.recordsList;
        let ISOCodes = dataTable.ISOCodes;
        let corporateISOCode = relatedListInfo.corporateISOCode;
        let blockedStartDates = relatedListInfo.blockedStartDates;
        let corporateCurrencyExchangeRate;

        records = records.filter(function (rec) {
            if (rec.IsoCode === corporateISOCode){
                corporateCurrencyExchangeRate = rec.ConversionRate;                                                     //Capture corporate currency exchange rate
                return false;                                                                                           //remove corporate currency from List of Currencies
            } else {
                return true;
            }
        });

        let latestDateUntilToday = new Date(Math.max.apply(null, records.map(function(e) {
            return new Date(e.StartDate);
        }))).toLocaleDateString();

        let latestBlockedDate = new Date(Math.max.apply(null, blockedStartDates.map(function(e) {
            return new Date(e);
        }))).toLocaleDateString();

        let fieldsTypes = dataTable.fieldsTypes;
        let fieldsList = dataTable.fieldsList;
        let columns = this.getColumnsForRelatedList(fieldsList, fieldsTypes, records);

        component.set("v.records", records);
        component.set("v.columns", columns);
        component.set("v.ISOCodes", ISOCodes);
        component.set("v.latestDateUntilToday", latestDateUntilToday);
        component.set("v.latestBlockedDate", latestBlockedDate);
        component.set("v.corporateISOCode", corporateISOCode);
        component.set("v.corporateCurrencyExchangeRate", corporateCurrencyExchangeRate);
        component.set("v.blockedStartDates", blockedStartDates);
        component.set("v.isLoading", false);
    },

    getColumnsForRelatedList : function (fieldsList, fieldsTypes, records) {

        let columns = Object.keys(fieldsList).map((key) => {
            if (fieldsList[key] === 'ConversionRate') {
                return {
                    label: key,
                    fieldName: fieldsList[key],
                    type: 'number',
                    editable: true,
                    typeAttributes: { minimumFractionDigits: 6, maximumFractionDigits: 6 },
                    cellAttributes: {alignment: 'left'}
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
                    typeAttributes: { minimumFractionDigits: 5, maximumFractionDigits: 5 },
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

    createNewExchangeRates : function (component, event) {
        let records = component.get("v.records");
        let blockedStartDates = component.get("v.blockedStartDates");
        let modalBody;
        $A.createComponent("c:DatedConversionRateCreateNewComponent", {records: records, blockedStartDates : blockedStartDates},
            function(content, status) {
                if (status === "SUCCESS") {
                    modalBody = content;
                    component.find('overlayLib').showCustomModal({
                        header: "New Exchange Rates",
                        body: modalBody,
                        showCloseButton: true
                    })
                }
            });
    }
});