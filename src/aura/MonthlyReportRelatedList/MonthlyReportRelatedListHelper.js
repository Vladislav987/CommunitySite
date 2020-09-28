({
    init : function (component, event) {
        component.set("v.isLoading", true);
        let action = component.get("c.getRelatedListInitData");

        action.setParams({
            projectId : component.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            let state = response.getState();
            if(state === "SUCCESS") {
                let relatedListInfo = response.getReturnValue();
                let currentDate = new Date(relatedListInfo.today);
                let currentMonth = currentDate.getMonth();
                if (currentMonth == 0){
                    component.set("v.selectedMonth", relatedListInfo.months[0]);
                }

                let months = relatedListInfo.months.map((item, index) => {
                    if ((currentMonth - 1) == index){               //Prepopulate the previous month to selected option
                        component.set("v.selectedMonth", item);
                    }
                    let monthInList = {};
                    monthInList.label = item;
                    //+ 1 due to Salesforce month number system, where Jan is 1
                    monthInList.value = (index + 1).toString();
                    return monthInList;
                });
                component.set("v.months", months);

                let years = relatedListInfo.years.map(item => {
                    let currentYear = currentDate.getFullYear();
                    if (currentYear == item){                   //Prepopulate the current year to selected option
                        component.set("v.selectedYear", item);
                        component.find("year").set("v.value", item);
                    }
                    let yearInList = {};
                    yearInList.label = item;
                    yearInList.value = item;
                    return yearInList;
                });
                component.set("v.years", years);

                this.setUpToDateReports(component, relatedListInfo);
                //this.filterMonthlyReports(component, event);                                                          //Do not filter by default
                component.set("v.isLoading", false);
            }  else if (state === "ERROR") {
                console.log(action.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },

    filterMonthlyReports : function (component){
        let selectedMonth = component.get("v.selectedMonth");
        let selectedYear = component.get("v.selectedYear");
        let selectedContractor = component.get("v.selectedContractor");
        let records = component.get("v.records");

        let filteredRecords = records.filter(function (record) {
            if (selectedContractor != null && selectedContractor != "") {
                return (record.Monthly_Report_Period__c === (selectedMonth + ' ' + selectedYear) && record.Contractor__c === selectedContractor);
            }
            else {
                return record.Monthly_Report_Period__c === (selectedMonth + ' ' + selectedYear);
            }
        });

        component.set("v.filteredRecords", filteredRecords);
    },

    saveDataTable : function (component, event){
        let action = component.get("c.updateReports");

        action.setParams({
            recordsList : event.getParam('draftValues')});

        action.setCallback(this, function(response) {
            let state = response.getState();
            let result = response.getReturnValue();

            if (state === "SUCCESS") {
                if (result === 'Success') {
                    this.showToast('Success', 'success', result);
                } else {
                    this.showToast('Error', 'error', result);
                }
                if ($A.get('e.force:refreshView')) {
                    $A.get('e.force:refreshView').fire();
                }
                component.set("v.isLoading", false);
            }
            else if (state === "ERROR") {
                this.showToast('Error', 'error', result);
                console.log(response.getError()[0].message);
            }

        });
        $A.enqueueAction(action);

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

    getUpdatedReportsAndApplyFilter : function (component, event) {
        let action = component.get("c.getRelatedListInitData");

        action.setParams({
            projectId : component.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            let state = response.getState();
            if(state === "SUCCESS") {
                this.setUpToDateReports(component, response.getReturnValue());
            }
            this.filterMonthlyReports(component);
        });

        $A.enqueueAction(action);
    },

    getColumnsForRelatedList : function (component, fieldsList, fieldsTypes, records) {
        let columns = Object.keys(fieldsList).reduce((columns, key) => {
            if (fieldsList[key] === 'Fact_hours__c') {
                columns.push( {
                    label: key,
                    fieldName: fieldsList[key],
                    type: 'number',
                    editable: true,
                    cellAttributes: {alignment: 'center'}
                });
            };
            return columns;
        },[]);
        let commonMethods = component.find('commonMethods');
        columns = commonMethods.getColumnForRelatedListTemplate(fieldsList, fieldsTypes, records, columns);
        return columns;
    },

    setUpToDateReports : function (component, relatedListInfo) {
        let dataTable = relatedListInfo.dataTable;
        let records = dataTable.recordsList;

        records.forEach(function (record) {
            record.linkName = '/' + record.Id;
        });                                                                                                             //Add link attribute to Monthly Reports array
        let contractors = records.filter(function (item){
            return item.Contractor__r != undefined && item.Contractor__c != undefined && item.Allocation__r != undefined;
        }).map(item => {
                    let contractor = {};
                    contractor.Id = item.Contractor__c;
                    contractor.Name = item.Contractor__r.Name;
                    contractor.AllocationStatus = item.Allocation__r.Status__c;
                    return contractor;                                                  //Prepopulate Contractor to filter afterwards
        });                                                                   //Map Contractors from Monthly Reports
        const filteredContractors = contractors.reduce((acc, current) => {
            const x = acc.find(item => item.Id === current.Id);
            if (!x) {
                return acc.concat([current]);
            } else {
                return acc;
            }
        }, []);                                    //Delete duplicates from Contractors

        function compare(a, b) {
            const statusA = a.AllocationStatus.toUpperCase();
            const nameA = a.Name.toUpperCase();
            const nameB = b.Name.toUpperCase();
            const statusB = b.AllocationStatus.toUpperCase();

            let comparison = 0;
            if (statusA === 'ACTIVE' && statusB !== 'ACTIVE') {
                comparison = -1;
            } else if (statusB  === 'ACTIVE' && statusA !== 'ACTIVE') {
                comparison = 1;
            } else if (statusA === statusB && statusA === 'ACTIVE'){
                if (nameA > nameB){
                    comparison = 1;
                }
                else if (nameB > nameA){
                    comparison = -1;
                }
            }
            else {
                comparison = 0;
            }
            return comparison;
        }                                                                                    //Function to compare Contractors:
        filteredContractors.sort(compare);                                                                              //put contractors with 'Active' Allocation first and sorted by Name

        let fieldsTypes = dataTable.fieldsTypes;
        let fieldsList = dataTable.fieldsList;
        let columns = this.getColumnsForRelatedList(component, fieldsList, fieldsTypes, records);
        component.set("v.contractors", filteredContractors);
        component.set("v.records", records);
        component.set("v.filteredRecords", records);
        component.set("v.columns", columns);
        component.set("v.isLoading", false);
    }
});