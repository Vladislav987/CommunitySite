/**
 * Created by MaxymMirona on 12.03.2020.
 */

({
    doInit : function (component, event){
        component.set("v.isLoading", true);
        let action = component.get("c.getInitDataForModal");

        action.setParams({
            "recordId" : component.get("v.recordId"),
            "generateInvoice" : component.get("v.generateInvoice")
        });

        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let modalInfo = response.getReturnValue();
                let todaysDate = new Date(modalInfo.today);
                let months = modalInfo.months;
                let dataTable = modalInfo.dataTable;
                this.handleMonthlyReportsAndColumns(component, dataTable);

                component.set("v.selectedMonth", todaysDate.getMonth() + 1);
                component.set("v.months", months);

                let years = modalInfo.years.map(item => {
                    let yearInList = {};
                    yearInList.label = item;
                    yearInList.value = item;
                    return yearInList;
                });

                component.set("v.selectedYear", todaysDate.getFullYear());
                component.set("v.years", years);
            }  else if (state === "ERROR") {
                console.log(action.getError()[0].message);
            }
            component.set("v.isLoading", false);
        });

        $A.enqueueAction(action);
    },

    handleMonthlyReportsAndColumns : function (component, dataTable) {
        let isInvoice = component.get("v.generateInvoice");
        let monthlyReports = dataTable.recordsList;
        let fieldsList = dataTable.fieldsList;
        let fieldsTypes = dataTable.fieldsTypes;
        let uniqueListOfRelatedBudgetTransactions = isInvoice ? dataTable.invoiceBudgetTransactions : dataTable.accrualBudgetTransactions;

        monthlyReports.forEach(function (record) {
            record.linkName = '/' + record.Id;

            if (record.Budget_transaction_item__c !== undefined) {

                record.BlockRow = {
                    isBlocked: true,
                    BlockedTitle: 'This Monthly Report is already assigned to ' + record.Budget_transaction_item__r.Budget_transaction__r.Name
                };
            }

            monthlyReports.forEach(record => {
                record.BudgetTransactionsPicklistSet = Array.from(uniqueListOfRelatedBudgetTransactions);
            });

        });

        if (isInvoice) {
            let accrualBudgetTransactionsObjectList =
                this.constructAccrualBudgetTransactionsObjectList(component, dataTable, monthlyReports, fieldsList, fieldsTypes);

            component.set("v.accrualBudgetTransactionsObjectList", accrualBudgetTransactionsObjectList);
        }

        fieldsTypes['Budget Transaction'] = 'PICKLIST';
        fieldsList['Budget Transaction'] = 'BudgetTransactionsPicklist';

        let columns = this.getColumnsForRelatedList(fieldsList, fieldsTypes, monthlyReports);

        component.set("v.columns", columns);
        component.set("v.monthlyReports", monthlyReports);
        component.set("v.filteredMonthlyReports", monthlyReports);
    },

    constructAccrualBudgetTransactionsObjectList : function (component, dateTable, monthlyReports, fieldsList, fieldsTypes) {
        let monthlyReportsForAccordion = monthlyReports;
        let columns = this.getColumnsForRelatedList(fieldsList, fieldsTypes, monthlyReportsForAccordion);
        let accrualBudgetTransactionsObjectList = [];
        let accordionPicklistObject = this.constructAccordionPicklistObject(dateTable.invoiceBudgetTransactions);

        dateTable.accrualBudgetTransactions.forEach(accrual => {
            if (accrual.Invoice__c == null && accrual.Accrual_status__c == 'Active' && accrual.Status__c == 'Approved') {
                let label = 'Accrual ' + accrual.Name + ', ' + (new Date(accrual.Invoiced_on__c)).toLocaleDateString();
                let reports = monthlyReportsForAccordion.filter(report => {
                    if (report.Budget_transaction_item__c) {
                        return report.Budget_transaction_item__r.Budget_transaction__c == accrual.Id;
                    }
                });

                /*reports.forEach(report => {
                    report.BlockRow = {
                        isBlocked: false,
                        BlockedTitle: ''
                    };
                });*/

                accrualBudgetTransactionsObjectList.push({
                    label: label,
                    reports: reports,
                    columns: columns,
                    id: accrual.Id
                });
            }
        });

        component.set("v.accordionPicklistObject", accordionPicklistObject);

        return accrualBudgetTransactionsObjectList;
    },

    constructAccordionPicklistObject : function (uniqueListOfRelatedBudgetTransactions) {
        let accordionPicklistObject = {
            options: [{
                label: 'New',
                id: 'New'
            }]
        };

        accordionPicklistObject.options = accordionPicklistObject.options.concat(uniqueListOfRelatedBudgetTransactions.filter(budgetTransaction => {
            return budgetTransaction.Status__c == 'Draft'
        }).map(budgetTransaction => {
            return {
                label : budgetTransaction.Name,
                id : budgetTransaction.Id
            }
        }));

        return accordionPicklistObject;
    },

    doGenerateInvoice : function (component, event) {
        component.set("v.isLoadingButton", true);
        let action = component.get("c.generateBudgetTransaction");
        let isInvoice = component.get("v.generateInvoice");
        let selectedAccruals = [];

        if (isInvoice) {
            selectedAccruals = component.find("Accordion").getSelectedItems();
        }

        let selectedRows = this.constructSelectedMonthlyReports(component.find("custom-data-table").getSelectedRows(), selectedAccruals.length > 0);

        if (!Array.isArray(selectedRows)) {
            this.showToast('Warning', 'warning', selectedRows);

            component.set("v.isLoadingButton", false);
        } else {
            if (selectedRows.length == 0 && selectedAccruals.length == 0 && isInvoice) {
                this.showToast('Warning', 'warning', 'You haven\'t selected any rows');

                component.set("v.isLoadingButton", false);
            } else {

                action.setParams({
                    "recordId": component.get("v.recordId"),
                    "reports": selectedRows,
                    "isInvoice": isInvoice,
                    "selectedAccruals": selectedAccruals
                });

                action.setCallback(this, function (response) {
                    let state = response.getState();

                    if (state === "SUCCESS") {
                        let result = response.getReturnValue();
                        let resultMessage = result.resultMessage;

                        if (result.isSuccessful) {
                            this.showToast('Success', 'success', resultMessage);

                            component.find("overlayLib").notifyClose();

                            $A.get("e.force:closeQuickAction").fire();
                        } else {
                            this.showToast('Error', 'error', resultMessage);
                        }
                    } else if (state === "ERROR") {
                        this.showToast('Error', 'error', action.getError()[0].message);
                    }

                    component.set("v.isLoadingButton", false);
                });

                $A.enqueueAction(action);
            }
        }
    },

    constructSelectedMonthlyReports : function (selectedRows, accrualsSelected) {
        let monthlyReports = [];
        let monthlyReportsPeriodSet = new Set();

        selectedRows.forEach(row => {
            monthlyReportsPeriodSet.add((new Date(row.Monthly_Report_Start_Date__c)).getMonth());
            monthlyReports.push({
                Id : row.Id,
                BudgetTransactionId : row.BudgetTransactionsPicklist
            });
        });


        return accrualsSelected ?
            monthlyReportsPeriodSet.size > 1 ?
                'You cannot select Monthly Reports from different period when selecting Accrual'
                : monthlyReports
            : monthlyReports;
    },

    showToast : function (title, type, message) {
        let toastEvent = $A.get("e.force:showToast");

        if (toastEvent){
            toastEvent.setParams({
                "title": title,
                "message": message == null ? 'Unexpected error' : message,
                "type" : type
            });
            toastEvent.fire();
        }
    },

    getColumnsForRelatedList : function (fieldsList, fieldsTypes, records) {

        let columns = Object.keys(fieldsList).map((key) => {
            if (fieldsList[key] === 'Name') {
                return {
                    label: key, fieldName: 'linkName', type: 'url',
                    typeAttributes: {label: {fieldName: 'Name'}, target: '_blank'}
                };
            } else if (fieldsTypes[key] === 'CURRENCY') {
                return {
                    label: key,
                    fieldName: fieldsList[key],
                    type: 'currency',
                    editable: false,
                    typeAttributes: {currencyCode: 'USD', maximumSignificantDigits: 2},
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
                let attribute = fieldsList[key];

                let attributeNameField = this.getAttributeNameField(attribute).toString();

                for (let i = 0; i < records.length; i++) {
                    records[i][attributeNameField] = this.getNestedAttributeValue(attributeNameField, records[i]);
                }

                if (!attribute.includes('.')) {
                    return {
                        label: key, fieldName: attribute, type: 'id',
                        typeAttributes: {label: {fieldName: attributeNameField}, target: '_blank'}
                    };
                } else {
                    return {
                         label: key, fieldName: attribute, type: 'text', editable: false
                    };
                }
            } else if (fieldsTypes[key] === 'PICKLIST'){
                let pickListAttributes = {
                    label: key,
                    fieldName: fieldsList[key],
                    type: 'picklist'
                };

                if (key === 'Budget Transaction'){
                    pickListAttributes.getPicklistValuesCallback = this.getBudgetTransactionsDisplayed;
                    pickListAttributes.defaultValueFromValueSet = {isTrue : true, index : 0};
                }
                return pickListAttributes;
            } else {
                return {label: key, fieldName: fieldsList[key], type: 'text', editable: false}
            }
        });

        return columns;
    },

    getAttributeNameField : function (attribute) {
        if (!attribute.includes('.')) {
            if (attribute.includes('__c')) {
                attribute = attribute.replace('__c', '__r') + '.Name';
            } else {
                attribute += '.Name';
            }
        }

        return attribute;
    },

    getNestedAttributeValue : function (attribute, source) {
        let pathMembers = attribute.split('.');
        let result;

        pathMembers.forEach(member => {
            result = result == null ? source[member] : result[member];
        });

        return result;
    },

    getBudgetTransactionsDisplayed : function (row, doneCallback) {
        let picklistValuesMap = new Map();
        let picklistValues = [];

        if (row.BlockRow) {
            if (row.BlockRow.isBlocked) {
                picklistValuesMap.set(
                    row.Budget_transaction_item__r.Budget_transaction__c,
                    row.Budget_transaction_item__r.Budget_transaction__r.Name
                );
            }
        } else {
            let budgetTransactionsSet = row.BudgetTransactionsPicklistSet;
            let reportStartDate = new Date(row.Monthly_Report_Start_Date__c);

            picklistValuesMap.set('New', 'New');

            if (budgetTransactionsSet.length > 0) {
                budgetTransactionsSet.forEach(item => {
                    let itemStartDate = new Date(item.Invoiced_on__c);

                    if (
                        itemStartDate.getMonth() == reportStartDate.getMonth() &&
                        itemStartDate.getFullYear() == reportStartDate.getFullYear() &&
                        item.Status__c == 'Draft'
                    ) {
                            picklistValuesMap.set(item.Id, item.Name);
                    }
                });
            }
        }

        if (picklistValuesMap.size > 0) {
            picklistValuesMap.forEach((value, key) => {
                picklistValues.push({Id : key, Label : value});
            });
        }

        return doneCallback(picklistValues);
    },

    handleFilterMonthlyReports : function (component, event) {
        let multiselectPicklistComponent = component.find("MultiselectPicklist");

        if (multiselectPicklistComponent) {
            let selectedMonths = multiselectPicklistComponent.getSelectedValues();
            let selectedMonthsDates = [];
            let selectedYear = component.get("v.selectedYear");
            let monthlyReports = component.get("v.monthlyReports");

            if (selectedMonths.length > 0) {
                selectedMonths.forEach(month => {
                    selectedMonthsDates.push(new Date('1' + month + selectedYear));
                });

                monthlyReports = monthlyReports.filter(report => {
                    return selectedMonthsDates.reduce((accumulator, monthDate) => {
                        return accumulator ||
                            (
                                monthDate.getMonth() == new Date(report.Monthly_Report_Start_Date__c).getMonth() &&
                                monthDate.getFullYear() == new Date(report.Monthly_Report_Start_Date__c).getFullYear()
                            )
                    }, false);
                });
            } else {
                monthlyReports = monthlyReports.filter(report => {
                    return selectedYear == new Date(report.Monthly_Report_Start_Date__c).getFullYear()
                });
            }

            component.set("v.filteredMonthlyReports", monthlyReports);
        }
    }
});