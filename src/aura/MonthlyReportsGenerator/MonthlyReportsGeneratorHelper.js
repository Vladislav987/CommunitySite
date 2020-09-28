({
    toggleTwoStep: function (component) {
        let stepTwo = component.find("stepTwo1");
        $A.util.toggleClass(stepTwo, 'slds-hide');
    },
    toggleOneStep: function (component) {
        component.set("v.progressIndicatorFlag", "2");
        let stepOne = component.find("stepOne");
        $A.util.toggleClass(stepOne, 'slds-hide');
        let stepTwo = component.find("stepTwo1");
        $A.util.toggleClass(stepTwo, "slds-hide");
    },

    init: function (component) {
        let action = component.get("c.getInitAllocations");
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
            2019,
            2020,
            2021,
            2022,
            2023,
            2024
        ];
        let numbers = [2, 3, 4, 5];
        component.set("v.numbers", numbers);
        action.setParam(
            "recordId", component.get("v.recordId")
        );

        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let allocations = response.getReturnValue();
                let allocationTypes = [];

                for (let i = 0; i < allocations.length; i++) {
                    if (!allocationTypes.includes(allocations[i].Allocation_Type__c)) {
                        allocationTypes.push(allocations[i].Allocation_Type__c);
                    }
                }

                component.set("v.allocationTypes", allocationTypes);
                component.set("v.allocations", allocations);
                component.set("v.filteredAllocations", allocations);
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

    doHandleFilterAllocations: function (component, event) {
        let selectedMonth = component.get("v.selectedMonth");
        let selectedYear = component.get("v.selectedYear");
        let selectedType = component.get("v.selectedType");
        let allocations = component.get("v.allocations");
        let filteredAllocations = component.get("v.filteredAllocations");
        let childTable = component.find("firstTable");

        if (selectedType !== "choose one...") {
            filteredAllocations = this.doFilterAllocations(component, allocations, 'Type', selectedType);
            if (selectedYear !== "choose one..." && selectedMonth !== "choose one...") {
                filteredAllocations = this.doFilterAllocations(component, filteredAllocations, 'Date Range');
            }
            component.set("v.haveActiveFilter", true);
            childTable.uncheckAll();
        } else if (selectedYear !== "choose one..." && selectedMonth !== "choose one...") {
            filteredAllocations = this.doFilterAllocations(component, allocations, 'Date Range');
            component.set("v.haveActiveFilter", true);
            childTable.uncheckAll();
        }

        if ((selectedYear === "choose one..." || selectedMonth === "choose one...") && selectedType === "choose one...") {
            component.set("v.haveActiveFilter", false);
            filteredAllocations = allocations;
        }

        component.set("v.filteredAllocations", filteredAllocations);
        component.set("v.selectedAllocationsPageOne", []);
    },

    doFilterAllocations: function (component, allocations, filterCriteria, selectedValue) {
        let filteredAllocations = [];

        filteredAllocations = allocations.filter(function (record) {
            if (filterCriteria === 'Date Range') {
                let selectedDate = new Date(
                    component.get("v.selectedYear"),
                    component.get("v.months").indexOf(component.get("v.selectedMonth")),
                    1);
                let allocationStartDate = new Date(record.Start_date__c);
                let allocationEndDate = new Date(record.End_date__c);

                if (allocationStartDate.getFullYear() < selectedDate.getFullYear() && allocationEndDate.getFullYear() > selectedDate.getFullYear()) {
                    return true;
                } else if (allocationStartDate.getFullYear() == allocationEndDate.getFullYear() && allocationStartDate.getFullYear() == selectedDate.getFullYear()) {
                    return allocationStartDate.getMonth() <= selectedDate.getMonth() && allocationEndDate.getMonth() >= selectedDate.getMonth()
                } else if (allocationStartDate.getFullYear() == selectedDate.getFullYear()) {
                    return allocationStartDate.getMonth() <= selectedDate.getMonth()
                } else if (allocationEndDate.getFullYear() == selectedDate.getFullYear()) {
                    return allocationEndDate.getMonth() >= selectedDate.getMonth()
                }
            } else if (filterCriteria === 'Type') {
                return record.Allocation_Type__c == selectedValue;
            }
        });

        return filteredAllocations;
    },
    activateStepOne: function (component) {
        component.set("v.progressIndicatorFlag", "1");
        let stepOne = component.find("stepOne");
        $A.util.toggleClass(stepOne, 'slds-hide');
        let stepTwo = component.find("stepTwo1");
        $A.util.toggleClass(stepTwo, "slds-hide");
        let emptyList = [];
        component.set("v.allocationsWithoutReports", emptyList);
        component.set("v.allocationsWithOneReport", emptyList);
        component.set("v.allocationsWithMultipleReports", emptyList);
        component.set("v.allocationsWithBudgetTransactions", emptyList);
    },
    onStepTwo: function (component) {
        let action = component.get('c.getInfoAboutAllocations');
        let allocationsIds = component.get('v.selectedAllocationsPageOne');
        let month = component.find('select').get('v.value');
        let year = component.find("selectYear").get("v.value");
        let notSelected = 'choose one...';
        let self = this;

        if (allocationsIds.length === 0) {
            self.showNotif(
                component,
                false,
                'Sorry',
                'Sorry, but you didn`t select any allocations!',
                'warning');
            return;
        }

        if (month === notSelected || year === notSelected) {
            self.showNotif(
                component,
                false,
                'Sorry',
                'Sorry, but you didn`t select Month or Year!',
                'warning');
            return;
        }

        action.setParams({
            "allocationsIds": allocationsIds,
            "projectId": component.get("v.recordId"),
            "month": month,
            "year": year

        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                component.set("v.allocationsWithoutReports", result.withoutReports);
                component.set("v.allocationsWithOneReport", result.withOneReport);
                component.set("v.allocationsWithMultipleReports", result.withMultipleReports);
                component.set("v.allocationsWithBudgetTransactions", result.withBudgetTransactions);

                this.toggleOneStep(component);
            } else {
                self.showNotif(
                    component,
                    false,
                    'Error',
                    result.message,
                    'error'
                );
            }
        });
        $A.enqueueAction(action);
    },

    tryToCreate: function (component) {
        component.set("v.isLoading", true);
        let action = component.get('c.generateReports');
        let selectedAllocationsIdWithoutReports = component.get("v.selectedAllocationsWithoutReports");
        let selectedAllocationsIdWithOneReports = component.get("v.selectedAllocationsWithOneReports");
        let selectedAllocationsIn2Tables = [];
        let datesValues = [];
        let month = component.find('select').get('v.value');
        let year = component.find("selectYear").get("v.value");
        let projectId = component.get("v.recordId");
        let selectedNumber = component.find("selectNumber").get("v.value");
        let self = this;
        let idsInString = '';

        if (selectedAllocationsIdWithoutReports.length > 0) {
            selectedAllocationsIn2Tables.push(selectedAllocationsIdWithoutReports);
        }
        if (selectedAllocationsIdWithOneReports.length > 0) {
            selectedAllocationsIn2Tables.push(selectedAllocationsIdWithOneReports);
        }

        for (let i = 1; i < 5; i++) {
            if (component.find("input" + i).get("v.value").length > 0) {
                datesValues.push(component.find("input" + i).get("v.value"));
            }
        }
        datesValues.sort(function (a,b) {
            return new Date(a) - new Date(b);
        });

        //  an unexpected error occurred while transferring the array to apex, so we pass the string
        if ((datesValues.length + 1) < selectedNumber) {
            self.showNotif(
                component,
                false,
                'Sorry',
                'Sorry, you didn`t fill all End days!',
                'warning');
            component.set("v.isLoading", false);
            return;
        }

        if (selectedAllocationsIn2Tables.length === 0) {
            self.showNotif(
                component,
                false,
                'Sorry',
                'Sorry, you didn`t select any allocation!',
                'warning');
            component.set("v.isLoading", false);
            return;
        }

        selectedAllocationsIn2Tables.forEach(function (item) {
            idsInString += item + ',';
        })

        action.setParams({
            "allocationsIds": idsInString,
            "projectId": component.get("v.recordId"),
            "month": month,
            "year": year,
            "dates": datesValues

        });

        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                console.log('callback SUCCESS');
                let result = response.getReturnValue();
                self.showNotif(
                    component,
                    true,
                    'Success',
                    result.message,
                    'success'
                );
                let generateMonthlyReportEvent = $A.get("e.c:GenerateMonthlyReportEvent");
                generateMonthlyReportEvent.fire();
                component.set("v.isLoading", false);
                component.find("overlayLib").notifyClose();

            } else {
                console.error('callback Error');
                component.set("v.isLoading", false);
                self.showNotif(
                    component,
                    false,
                    'Error',
                    result.message,
                    'error'
                );

            }
        });
        $A.enqueueAction(action);


    },
    changeSegmentValue: function (component) {
        let segment = component.find("selectNumber").get("v.value");
        let childTable = component.find("table");
        component.set("v.segment", segment);
        if (segment > 1) {
            component.set("v.isChanged", false);
        } else {
            component.set("v.isChanged", true);
            childTable.uncheckAll();
        }
        component.find("input1").set("v.value","");
        component.find("input2").set("v.value","");
        component.find("input3").set("v.value","");
        component.find("input4").set("v.value","");
    },
    checkSelectedDay: function (component, event) {
        let date = event.getSource().get("v.value");
        let inputId = event.getSource().getLocalId();
        let input = component.find(inputId);
        let month = component.get("v.selectedMonth");
        let year = component.get("v.selectedYear");
        if (month !== new Date(date).toLocaleString("en-us", {month: "long"}) || year !=new Date(date).getFullYear()) {
            input.setCustomValidity('you can`t choose ' + date + '. This date not for month and year that have been selected!');
            input.set("v.value", null);
        } else {
            input.setCustomValidity('');

        }
        input.reportValidity();
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
});