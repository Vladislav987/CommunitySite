({
    selectAllAllocations: function (component, event) {
        let isChecked = event.getSource().get("v.checked");
        let checkboxes = component.find("checkbox");
        let selectedCheckboxes = [];
        if (Array.isArray(checkboxes)) {
            checkboxes.forEach(function (item) {
                item.set("v.checked", isChecked);
                if (isChecked) {
                    selectedCheckboxes.push(item.get("v.value"));
                }
            });
        } else {
            checkboxes.set("v.checked", isChecked);
            if (isChecked){
                selectedCheckboxes.push(checkboxes.get("v.value"));
            }
        }
        component.set("v.selectedAllocations", selectedCheckboxes);

    },
    onChange: function (component) {
        let allCheckboxes = component.find("checkbox");
        let selectedCheckboxes = [];
        if (!Array.isArray(allCheckboxes) && allCheckboxes.get('v.checked') === true) {
            selectedCheckboxes.push(allCheckboxes.get('v.value'));
        } else {
            for (let i = 0; i < allCheckboxes.length; i++) {
                if (allCheckboxes[i].get('v.checked') == true) {
                    selectedCheckboxes.push(allCheckboxes[i].get('v.value'));
                }
            }
        }
        component.set("v.selectedAllocations", selectedCheckboxes);
    },
    checkCheckBoxes: function (component) {
        if (component.get("v.allocations").length > 0) {
            let isChecked = component.get("v.checked");
            let checkboxes = component.find("checkbox");
            let selectedCheckboxes = [];
            if (Array.isArray(checkboxes)) {
                checkboxes.forEach(function (item) {
                    item.set("v.checked", isChecked);
                    if (isChecked) {
                        selectedCheckboxes.push(item.get("v.value"));
                    }
                });
            } else {
                checkboxes.set("v.checked", isChecked);
                if (isChecked) {
                    selectedCheckboxes.push(checkboxes.get("v.value"));
                }
            }
            component.set("v.selectedAllocations", selectedCheckboxes);
        }
    },
    uncheckAllCheckboxes: function (component) {
        let checkboxes = component.find("checkbox");
        if (Array.isArray(checkboxes)) {
            checkboxes.forEach(function (item) {
                item.set("v.checked", false);
            });
        } else {
            checkboxes.set("v.checked", false);
        }
        component.set('v.checked', false);
    }
});