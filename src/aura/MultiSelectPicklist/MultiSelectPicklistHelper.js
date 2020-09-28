/**
 * Created by MaxymMirona on 23.04.2020.
 */

({
    init : function (component, event) {
        this.initializeItemsToIterate(component);
    },

    expandOrCollapseListBox : function (component, event) {
        let isCalledFromCombobox = event.target.classList.contains('slds-combobox__input');

        if (isCalledFromCombobox) {
            this.toggleCollapseListBox(component);
        }
    },

    leaveListBox : function (component, event) {
        this.toggleCollapseListBox(component, false);
    },

    toggleCollapseListBox : function (component, value) {
        let element = component.find("combobox").getElement();

        if (value != undefined) {
            if (value) {
                $A.util.addClass(element, "slds-is-open");
            } else {
                $A.util.removeClass(element, "slds-is-open");
            }
        } else {
            $A.util.toggleClass(element, "slds-is-open");
        }
    },

    initializeItemsToIterate : function (component) {
        let items = component.get("v.items");
        let itemsToIterate = [];

        items.forEach(item => {
            itemsToIterate.push({
                value : item,
                isSelected : false
            });
        });

        component.set("v.itemsToIterate", itemsToIterate);
    },

    selectPicklistOption : function (component, event) {
        let optionElement = event.currentTarget;
        let isSelected = optionElement.classList.contains('slds-is-selected');

        this.toggleHighlightOption(optionElement);

        if (isSelected) {
            this.toggleAddOptionToSelectedOptions(component, optionElement, false);
            this.toggleAddOptionSelectionFromItemsToIterate(component, optionElement, false);
        } else {
            this.toggleAddOptionToSelectedOptions(component, optionElement, true);
            this.toggleAddOptionSelectionFromItemsToIterate(component, optionElement, true);
        }

        this.handleNoneOption(component);

        this.toggleCollapseListBox(component, true);
    },

    removePillOption : function (component, event) {
        let option = event.currentTarget.id;
        let optionElement = this.getOptionElementByIndex(component, this.getOptionId(component, option));

        this.toggleHighlightOption(optionElement, false);
        this.toggleAddOptionToSelectedOptions(component, optionElement, false);
        this.toggleAddOptionSelectionFromItemsToIterate(component, optionElement, false);

        this.handleNoneOption(component);
    },

    getOptionId : function (component, optionValue) {
        return component.get("v.items").indexOf(optionValue);
    },

    getOptionElementByIndex : function (component, index) {
        let options = component.find("option");

        if (Array.isArray(options)) {
            return options.filter(option => {
                return option.getElement().id == index;
            })[0].getElement();
        }

        return options.getElement().id == index ? options.getElement() : null;
    },

    selectNoneOption : function (component, event) {
        this.removeAllOptionsSelection(component);
        this.toggleHighlightOption(component.find("none-option").getElement(), true);
    },

    removeAllOptionsSelection : function (component) {
        let itemsToIterate = component.get("v.itemsToIterate");

        for (let i = 0; i < itemsToIterate.length; ++i) {
            let element = this.getOptionElementByIndex(component, i);

            if (element) {
                this.toggleHighlightOption(element, false);
                itemsToIterate[i].isSelected = false;
            }
        }

        component.set("v.itemsToIterate", itemsToIterate);
        component.set("v.selectedOptions", []);
    },

    handleNoneOption : function (component) {
        let selectedOptions = component.get("v.selectedOptions") ;
        let noneOptionElement = component.find("none-option").getElement();

        if (selectedOptions.length == 0 || selectedOptions == null) {
            this.toggleHighlightOption(noneOptionElement, true);
        } else {
            this.toggleHighlightOption(noneOptionElement, false);
        }
    },

    toggleHighlightOption : function (element, value) {
        if (value != undefined) {
            if (value) {
                $A.util.addClass(element, "slds-is-selected");
                $A.util.addClass(element, "slds-has-focus");
            } else {
                $A.util.removeClass(element, "slds-is-selected");
                $A.util.removeClass(element, "slds-has-focus");
            }
        } else {
            $A.util.toggleClass(element, "slds-is-selected");
            $A.util.toggleClass(element, "slds-has-focus");
        }
    },

    toggleAddOptionToSelectedOptions : function (component, element, add) {
        let optionId = element.id;
        let selectedOptions = component.get("v.selectedOptions");
        let items = component.get("v.items");

        if (add) {
            selectedOptions.push(items[optionId]);
        } else {
            selectedOptions = this.removeItemFromList(selectedOptions, items[optionId]);
        }

        component.set("v.selectedOptions", selectedOptions);
    },

    toggleAddOptionSelectionFromItemsToIterate : function (component, element, add) {
        let optionId = element.id;
        let itemsToIterate = component.get("v.itemsToIterate");

        itemsToIterate[optionId].isSelected = add;

        component.set("v.itemsToIterate", itemsToIterate);
    },

    removeItemFromList : function (array, value) {
        return array.filter(item => {
            return item != value
        });
    }
});