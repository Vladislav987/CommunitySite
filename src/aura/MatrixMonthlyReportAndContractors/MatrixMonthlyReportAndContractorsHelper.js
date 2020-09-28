({
    init: function (component) {



        let action = component.get("c.getMatrix");
        let self = this;
        let months = [
            "January",
            "February",
            "March",
            "April",
            "May",
            "June",
            "July",
            "August",
            "September",
            "October",
            "November",
            "December"
        ];
        let years = [
            2018,
            2019,
            2020,
            2021,
            2022,
            2023
        ];
        action.setParam(
            "recordId", component.get("v.recordId")
        );

        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let resp = response.getReturnValue();
                let allocations = resp["allocations"];

                let allocationTypes  = [];

                for (let i = 0; i < allocations.length; i++){
                    if (!allocationTypes.includes(allocations[i].Allocation_Type__c)){
                        allocationTypes.push(allocations[i].Allocation_Type__c);
                    }
                }

                let projects = resp["projects"];

                component.set("v.allocationTypes", allocationTypes);
                component.set("v.allocations", allocations);
                component.set("v.filteredAllocations", allocations);
                component.set("v.projects", projects);
                component.set("v.months", months);
                component.set("v.years", years);
                component.set("v.isLoading", false);


            } else if (state === "ERROR") {

                self.showNotif(
                    component,
                    false,
                    "Error",
                    action.getError()[0].message,
                    "error"
                );
                component.find("overlayLib").notifyClose();
            }
        });

        $A.enqueueAction(action);
    },

    onReportGenerationStart1: function (component) {
        let action = component.get('c.createReport');
        let checkboxes = component.find('checkbox');
        let month = component.find('select').get('v.value');
        let year = component.find("selectYear").get("v.value");
        let notSelected = 'choose one...';
        let selectedCheckbox = [];
        //let map = new Map();
        let self = this;
        let allocationIds = [];

        if (!Array.isArray(checkboxes) && checkboxes.get('v.checked')==true){
            selectedCheckbox.push(checkboxes.get('v.value'));
        } else{
            for (let i = 0; i < checkboxes.length; i++) {
                if (checkboxes[i].get('v.checked') == true) {
                    selectedCheckbox.push(checkboxes[i].get('v.value'));
                }
            }
        }

        for (let i = 0; i < selectedCheckbox.length; i++) {
            let allocationId = selectedCheckbox[i].split('/')[1];
            /*let value = selectedCheckbox[i].split('/')[0];
            let key = selectedCheckbox[i].split('/')[1];
            if (map.has(key)) {
                map.get(key).push(value);
            } else {
                map.set(key, new Array(value));
            }*/
            allocationIds.push(allocationId);
        }

        /*let mapToSend = {};
        for (let key of map.keys()) {
            mapToSend[key] = map.get(key);
        }*/


        if ((selectedCheckbox.length > 0) && month != notSelected && year != notSelected) {
            action.setParams({
                "mapIds": allocationIds,
                "projectId": component.get("v.recordId"),
                "month": month,
                "year": year

            });
            action.setCallback(this, function (response) {
                let state = response.getState();
                if (state === "SUCCESS") {
                    let result = response.getReturnValue();
                    if (result.isSuccessful) {
                        let generateMonthlyReportEvent = $A.get("e.c:GenerateMonthlyReportEvent");
                        generateMonthlyReportEvent.fire();
                        self.showNotif(
                            component,
                            true,
                            'Success',
                            result.message,
                            'success'

                        );
                        component.find("overlayLib").notifyClose();

                    } else {

                        self.showNotif(
                            component,
                            false,
                            'Error',
                            result.message,
                            'error'
                        );
                    }
                }

            });
        } else {

            self.showNotif(
                component,
                false,
                'Sorry',
                'Sorry, but you have to choose Project/Allocation/Period of Monthly reports',
                'error')

        }
        $A.enqueueAction(action);

    },

    showNotif: function (component, isToast, title, message, variant) {

        let lib = component.find("notifLib");
        if (isToast) {
            lib.showToast({
                title: title,
                message: message,
                variant: variant
            });
        } else {
            lib.showNotice({
                header: title,
                message: message,
                variant: variant
            });
        }
    },

    doSelectCheckbox : function (component, event) {
        let checkbox = event.getSource();
        let checkboxValue = checkbox.get("v.value");
        let checkboxChecked = checkbox.get("v.checked");
        let currentRecordId = component.get("v.recordId");
        let checkboxAllocation = checkboxValue.split('/').pop();

        if (!checkboxValue.includes(currentRecordId) && checkboxChecked){                                               //if checkbox checked and it isn't parent
            let checkboxes = component.find("checkbox");

            checkboxes.forEach(function (item, i, arr) {
                let itemValue = item.get("v.value");
                if (itemValue.includes(currentRecordId) && itemValue.includes(checkboxAllocation)){                     //find parent project checkbox
                    item.set("v.checked", true);
                    item.set("v.disabled", true);
                }
            });
        }
        else if (!checkboxValue.includes(currentRecordId)) {                                                            //if checkbox unchecked and it isn't parent
            let checkboxes = component.find("checkbox");

            for (let i = 0; i < checkboxes.length; i++){
                let checkboxValue = checkboxes[i].get("v.value");
                let checkboxChecked = checkboxes[i].get("v.checked");

                if (!checkboxValue.includes(currentRecordId) && checkboxValue.includes(checkboxAllocation) && checkboxChecked){ //if other checkbox in a line is selected
                    break;
                }
                else if (checkboxValue.includes(currentRecordId) && checkboxValue.includes(checkboxAllocation)){        //find parent project checkbox
                    checkboxes[i].set("v.checked", false);
                    checkboxes[i].set("v.disabled", false);
                }
            }
        }
    },

    doHandleFilterAllocations : function(component, event){
        let selectedMonth = component.get("v.selectedMonth");
        let selectedYear = component.get("v.selectedYear");
        let selectedType = component.get("v.selectedType");
        let allocations = component.get("v.allocations");
        let filteredAllocations = component.get("v.filteredAllocations");

        if (selectedType !== "choose one..."){
            filteredAllocations = this.doFilterAllocations(component, allocations, 'Type', selectedType);
            if (selectedYear !== "choose one..." && selectedMonth !== "choose one...") {
                filteredAllocations = this.doFilterAllocations(component, filteredAllocations, 'Date Range');
            }
            component.set("v.haveActiveFilter", true);
        } else if (selectedYear !== "choose one..." && selectedMonth !== "choose one..."){
            filteredAllocations = this.doFilterAllocations(component, allocations, 'Date Range');
            component.set("v.haveActiveFilter", true);
        }

        if ((selectedYear === "choose one..." || selectedMonth === "choose one...") && selectedType === "choose one..."){
            component.set("v.haveActiveFilter", false);
            filteredAllocations = allocations;
        }

        component.set("v.filteredAllocations", filteredAllocations);
    },

    doFilterAllocations : function(component, allocations, filterCriteria, selectedValue){
        let filteredAllocations = [];

        filteredAllocations = allocations.filter(function (record) {
            if (filterCriteria === 'Date Range') {
                let selectedDate = new Date(
                    component.get("v.selectedYear"),
                    component.get("v.months").indexOf(component.get("v.selectedMonth")),
                    1);
                let allocationStartDate = new Date(record.Start_date__c);
                let allocationEndDate = new Date(record.End_date__c);

                if (allocationStartDate.getFullYear() < selectedDate.getFullYear() && allocationEndDate.getFullYear() > selectedDate.getFullYear()){
                    return true;
                } else if (allocationStartDate.getFullYear() == allocationEndDate.getFullYear() && allocationStartDate.getFullYear() == selectedDate.getFullYear()){
                    return allocationStartDate.getMonth() <= selectedDate.getMonth() && allocationEndDate.getMonth() >= selectedDate.getMonth()
                } else if (allocationStartDate.getFullYear() == selectedDate.getFullYear()){
                    return allocationStartDate.getMonth() <= selectedDate.getMonth()
                } else if (allocationEndDate.getFullYear() == selectedDate.getFullYear()){
                    return allocationEndDate.getMonth() >= selectedDate.getMonth()
                }
            } else if (filterCriteria === 'Type'){
                return record.Allocation_Type__c == selectedValue;
            }
        });

        return filteredAllocations;
    },

    doSelectAllColumnAllocations : function (component, event) {
        let checkboxes = component.find("checkbox");
        let selectedColumnProjectId = event.getSource().get("v.name");
        let checked = event.getParam("checked");
        let parentProjectId = component.get("v.recordId");
        let selectAllCheckboxes = component.find("select-all-column-checkboxes");
        let selectedColumnCheckboxes;
        let parentProjectCheckboxes;
        let selectedChildProjectCheckboxes;

        if (checkboxes !== undefined && selectAllCheckboxes !== undefined) {
            if (Array.isArray(selectAllCheckboxes)) {
                selectedColumnCheckboxes = checkboxes.filter(function (checkbox) {
                    return checkbox.get("v.value").includes(selectedColumnProjectId)
                });

                parentProjectCheckboxes = checkboxes.filter(function (checkbox) {
                    return checkbox.get("v.value").includes(parentProjectId)
                });

                let haveSelectedColumns = selectAllCheckboxes.reduce(function (accumulator, item) {
                    if (item.get("v.name") !== parentProjectId && item.get("v.name") !== selectedColumnProjectId) {
                        return accumulator || item.get("v.checked");
                    } else {
                        return accumulator;
                    }
                }, false);

                selectedChildProjectCheckboxes = component.find("checkbox").filter(function (item) {
                    let selectedCheckboxProjectId = item.get("v.value").split('/')[0];

                    if (selectedCheckboxProjectId != parentProjectId && selectedCheckboxProjectId != selectedColumnProjectId) {
                        return item.get("v.checked");
                    } else {
                        return false;
                    }
                });

                selectedColumnCheckboxes.forEach(function (item) {
                    item.set("v.checked", checked);
                });

                if (!haveSelectedColumns) {
                    parentProjectCheckboxes.forEach(function (item) {
                        item.set("v.checked", checked);
                        item.set("v.disabled", checked);
                    });
                }

                if (selectedChildProjectCheckboxes !== undefined) {

                    selectedChildProjectCheckboxes.forEach(function (item) {
                        let selectedCheckboxAllocation = item.get("v.value").split('/').pop();

                        parentProjectCheckboxes.forEach(function (item) {
                            let parentProjectCheckboxAllocation = item.get("v.value").split('/').pop();

                            if (parentProjectCheckboxAllocation === selectedCheckboxAllocation) {
                                item.set("v.checked", true);
                                item.set("v.disabled", true);
                            }
                        });
                    });
                }

                if (!haveSelectedColumns && parentProjectId !== selectedColumnProjectId) {
                    selectAllCheckboxes.forEach(function (item) {
                        if (item.get("v.name") === parentProjectId) {
                            item.set("v.checked", checked);
                            item.set("v.disabled", checked);
                        }
                    });
                }

            } else {
                if (Array.isArray(checkboxes)) {
                    checkboxes.forEach(function (item) {
                        item.set("v.checked", checked);
                    });
                } else {
                    checkboxes.set("v.checked", checked);
                }
            }
        }
    }
});