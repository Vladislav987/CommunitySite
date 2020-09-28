/**
 * Created by MaxymMirona on 02.05.2020.
 */

({
    init : function (component, event) {
        this.handlePreselectAll(component, event);
    },

    handlePreselectAll : function (component, event) {
        this.handleSelectAll(component, event, component.get("v.preselectAll"))
    },

    handleChangeSelectAll : function (component, event) {
        let isChecked = event.getSource().get("v.checked");

        this.handleSelectAll(component, event, isChecked);
    },

    handleGetSelectedRows : function (component, event) {
        let selectedRows = [];
        let dataTableRows = component.find("dataTableRow");

        if (dataTableRows) {
            let isArray = Array.isArray(dataTableRows);

            if (isArray) {
                dataTableRows.forEach(childComponent => {
                    if (childComponent.get("v.isRowSelected")) {
                        selectedRows.push(childComponent.get("v.rowData"));
                    }
                });
            } else {
                if (dataTableRows.get("v.isRowSelected")) {
                    selectedRows.push(dataTableRows.get("v.rowData"));
                }
            }

            component.set("v.selectedRows", selectedRows);
        }

        return selectedRows;
    },

    handleSelectAll : function (component, event, isChecked) {
        let dataTableRows = component.find("dataTableRow");

        if (dataTableRows !== undefined) {
            let isArray = Array.isArray(dataTableRows);

            if (isArray) {
                dataTableRows.forEach(childComponent => {
                    if (!childComponent.get("v.isBlocked")) {
                        childComponent.set("v.isRowSelected", isChecked);
                    }
                });
            } else {
                if (!dataTableRows.get("v.isBlocked")) {
                    dataTableRows.set("v.isRowSelected", isChecked);
                }
            }
        }

        component.set("v.selectAllValue", isChecked);
    }
});