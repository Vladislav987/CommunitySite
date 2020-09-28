/**
 * Created by Lambru Dmytro on 19.03.2020.
 */
({
    handleInit: function (cmp, event, helper) {
        helper.setCmpConstants(cmp);
        helper.doInit(cmp, helper);
    },

    handleCheckboxChange: function (cmp, event, helper) {
        const checkboxElement = event.currentTarget;
        helper.addToOrRemoveFromListWithChangedOptions(cmp, helper, checkboxElement);
    },

    handleExpandBtnClick: function (cmp, event, helper) {
        helper.openOrCloseAllAccordions(cmp, true);
    },

    handleCollapseBtnClick: function (cmp, event, helper) {
        helper.openOrCloseAllAccordions(cmp, false);
    },

    handleEditBtnClick: function (cmp, event, helper) {
        cmp.set('v.isEditMode', true);
        // clear list before new changes
        cmp.set('v.changedMasterWithSpecializationsOptionList', []);
    },

    handleSaveBtnClick: function (cmp, event, helper) {
        helper.showCardSpinner(cmp);
        helper.saveChanges(cmp, helper);
    },

    handleCancelBtnClick: function (cmp, event, helper) {
        cmp.set('v.isEditMode', false);
    },

});