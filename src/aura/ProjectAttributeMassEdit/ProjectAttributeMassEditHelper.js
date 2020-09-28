/**
 * Created by Lambru Dmytro on 20.03.2020.
 */

({
    setCmpConstants: function (cmp) {
        cmp.ANCHOR_BREAK_PROMISE_CHAIN = 'ANCHOR_BREAK_PROMISE_CHAIN';
    },

    doInit: function (cmp, helper) {

        $LightningUtil.sendPromiseRequest(cmp, 'getMasterWithSpecializationsOptionsByProjectId', {
            projectId: cmp.get('v.recordId')
        })
        .then($A.getCallback((response) => {
            return helper.handleResponseData(helper, response);
        }))
        .then($A.getCallback((data) => {

            if (data && data.length > 0) {
                helper.saveComponentData(cmp, helper, data);
                helper.openAccordionsWithSelectedMasterOption(cmp, helper, data);
            }
        }))
        .catch($A.getCallback((error) => {
            $LightningUtil.handleErrorInPromiseCatch(error);
        }));
    },

    saveComponentData: function (cmp, helper, data) {
        cmp.set('v.masterWithSpecializationsOptionList', data);
        data = $LightningUtil.cloneAndBreakAllReferences(data);

        const masterWithSpecializationsOptionList_TMP1 = data.slice(0, Math.floor(data.length / 2));
        const masterWithSpecializationsOptionList_TMP2 = data.slice(Math.floor(data.length / 2), data.length);

        cmp.set('v.masterWithSpecializationsOptionList_TMP1', masterWithSpecializationsOptionList_TMP1);
        cmp.set('v.masterWithSpecializationsOptionList_TMP2', masterWithSpecializationsOptionList_TMP2);
    },

    openAccordionsWithSelectedMasterOption: function (cmp, helper, masterWithSpecializationsOptionList) {
        setTimeout($A.getCallback(() => {
            const accordionCmpList = cmp.find('#util_accordion');
            const nameOfSelectedOptionSet = helper.getSetWithNamesOfSelectedMasterOption(masterWithSpecializationsOptionList);

            for (const accordionCmp of accordionCmpList) {
                const masterOptionApiName = accordionCmp.get('v.name');

                if (nameOfSelectedOptionSet.has(masterOptionApiName)) {
                    accordionCmp.open();
                }
            }
        }),1000);
    },

    getSetWithNamesOfSelectedMasterOption: function (masterWithSpecializationsOptionList) {
        const nameOfSelectedOptionSet = new Set();

        for (const masterOptionMap of masterWithSpecializationsOptionList) {

            if (masterOptionMap.isSelected) nameOfSelectedOptionSet.add(masterOptionMap.optionApiName);
        }

        return nameOfSelectedOptionSet;
    },

    addToOrRemoveFromListWithChangedOptions: function (cmp, helper, checkboxElement) {
        const masterOptionApiName = checkboxElement.dataset.masterOptionApiName;
        const specializationOptionApiName = checkboxElement.dataset.specializationOptionApiName;
        const specializationOptionIsSelected = JSON.parse(checkboxElement.dataset.specializationOptionIsSelected);
        const currentSelectionState = checkboxElement.checked;

        if (specializationOptionIsSelected !== currentSelectionState) {
            helper.addToChangedList(cmp, helper, masterOptionApiName, specializationOptionApiName);
        }
        else {
            helper.removeFromChangedList(cmp, helper, masterOptionApiName, specializationOptionApiName);
        }
    },

    addToChangedList: function (cmp, helper, masterOptionApiName, specializationOptionApiName) {
        const masterWithSpecializationsOptionList = cmp.get('v.masterWithSpecializationsOptionList');
        const changedMasterWithSpecializationsOptionList = cmp.get('v.changedMasterWithSpecializationsOptionList');

        let masterPicklistOptionMap = masterWithSpecializationsOptionList.find((masterPicklistOptionMap) => {
            return masterPicklistOptionMap.optionApiName === masterOptionApiName;
        });

        masterPicklistOptionMap = $LightningUtil.cloneAndBreakAllReferences(masterPicklistOptionMap);

        const specializationPicklistOptionMap = masterPicklistOptionMap.specializationPicklistOptionList.find((specializationPicklistOptionMap) => {
            return specializationPicklistOptionMap.optionApiName === specializationOptionApiName;
        });

        // set new selection state
        specializationPicklistOptionMap.isSelected = !specializationPicklistOptionMap.isSelected;
        masterPicklistOptionMap.specializationPicklistOptionList = [specializationPicklistOptionMap];
        changedMasterWithSpecializationsOptionList.push(masterPicklistOptionMap);

        cmp.set('v.changedMasterWithSpecializationsOptionList', changedMasterWithSpecializationsOptionList);
    },

    removeFromChangedList: function (cmp, helper, masterOptionApiName, specializationOptionApiName) {
        const changedMasterWithSpecializationsOptionList = cmp.get('v.changedMasterWithSpecializationsOptionList');

        const filteredList = changedMasterWithSpecializationsOptionList.filter((masterPicklistOptionMap) => {

            if (masterPicklistOptionMap.optionApiName !== masterOptionApiName) return true;

            const isExistSpecializationPicklistOption = masterPicklistOptionMap.specializationPicklistOptionList.some((specializationPicklistOptionMap) => {
                return specializationPicklistOptionMap.optionApiName === specializationOptionApiName;
            });

            return !isExistSpecializationPicklistOption;
        });

        cmp.set('v.changedMasterWithSpecializationsOptionList', filteredList);
    },

    openOrCloseAllAccordions: function (cmp, isOpenAll) {
        const accordionCmpList = cmp.find('#util_accordion');

        for (const accordionCmp of accordionCmpList) {

            if (isOpenAll) {
                accordionCmp.open();
            }
            else {
                accordionCmp.close();
            }
        }
    },

    showCardSpinner: function (cmp) {
        $A.util.removeClass(cmp.find('#card_spinner'),'slds-hide');
    },

    hideCardSpinner: function (cmp) {
        $A.util.addClass(cmp.find('#card_spinner'),'slds-hide');
    },

    saveChanges: function (cmp, helper) {
        const beforeChangesMasterPicklistOptionList = cmp.get('v.masterWithSpecializationsOptionList');
        const changedMasterWithSpecializationsOptionList = cmp.get('v.changedMasterWithSpecializationsOptionList');

        if (changedMasterWithSpecializationsOptionList.length === 0) {
            $LightningUtil.showToast(cmp.get('v.ERROR_TOAST_TITLE_NOTHING_TO_SAVE'), cmp.get('v.ERROR_TOAST_MSG_NOTHING_TO_SAVE'), 'info');
            helper.hideCardSpinner(cmp);
            return;
        }

        $LightningUtil.sendPromiseRequest(cmp, 'changeProjectAttributes', {
            projectId: cmp.get('v.recordId'),
            beforeChangesJsonMasterPicklistOptionList: JSON.stringify(beforeChangesMasterPicklistOptionList),
            changedJsonMasterPicklistOptionList: JSON.stringify(changedMasterWithSpecializationsOptionList)
        })
        .then($A.getCallback((response) => {
            helper.hideCardSpinner(cmp);

            if (response.success) {
                cmp.set('v.isEditMode', false);
            }
            else if (!response.success && response.code === 1003) {
                $LightningUtil.showToast(cmp.get('v.ERROR_TOAST_TITLE_ALREADY_CHANGED'), cmp.get('v.ERROR_TOAST_MSG_ALREADY_CHANGED'), 'info');
                return Promise.reject(cmp.ANCHOR_BREAK_PROMISE_CHAIN);
            }
            else {
                helper.handleErrorInResponseFromApex(response, true);
                return Promise.reject(cmp.ANCHOR_BREAK_PROMISE_CHAIN);
            }
        }))
        .then($A.getCallback(() => {
            return $LightningUtil.sendPromiseRequest(cmp, 'getMasterWithSpecializationsOptionsByProjectId', {
                projectId: cmp.get('v.recordId')
            })
        }))
        .then($A.getCallback((response) => {
            return helper.handleResponseData(helper, response);
        }))
        .then($A.getCallback((data) => {

            if (data && data.length > 0) {
                $LightningUtil.showToast(cmp.get('v.SUCCESS_TOAST_TITLE_CHANGES_SAVED'));
                helper.updateComponentData(cmp, helper, data);
            }
        }))
        .catch($A.getCallback((error) => {

            if (error === cmp.ANCHOR_BREAK_PROMISE_CHAIN) return;

            $LightningUtil.handleErrorInPromiseCatch(error);
        }));
    },

    updateComponentData: function (cmp, helper, updatedMasterWithSpecializationsOptionList) {
        cmp.set('v.masterWithSpecializationsOptionList', updatedMasterWithSpecializationsOptionList);

        const masterWithSpecializationsOptionList_TMP1 = cmp.get('v.masterWithSpecializationsOptionList_TMP1');
        const masterWithSpecializationsOptionList_TMP2 = cmp.get('v.masterWithSpecializationsOptionList_TMP2');

        helper.updateChangedSpecializationOptions(masterWithSpecializationsOptionList_TMP1, updatedMasterWithSpecializationsOptionList);
        helper.updateChangedSpecializationOptions(masterWithSpecializationsOptionList_TMP2, updatedMasterWithSpecializationsOptionList);

        cmp.set('v.masterWithSpecializationsOptionList_TMP1', masterWithSpecializationsOptionList_TMP1);
        cmp.set('v.masterWithSpecializationsOptionList_TMP2', masterWithSpecializationsOptionList_TMP2);
    },

    updateChangedSpecializationOptions: function (masterWithSpecializationsOptionList, updatedMasterWithSpecializationsOptionList) {

        for (let masterOptionMap of masterWithSpecializationsOptionList) {

            const updatedMasterPicklistOptionMap = updatedMasterWithSpecializationsOptionList.find((masterPicklistOptionMap) => {
                return masterPicklistOptionMap.optionApiName === masterOptionMap.optionApiName;
            });

            for (let i = 0, length = masterOptionMap.specializationPicklistOptionList.length; i < length; i++) {

                const updatedSpecializationPicklistOptionMap = updatedMasterPicklistOptionMap.specializationPicklistOptionList.find((specializationPicklistOptionMap) => {
                    return specializationPicklistOptionMap.optionApiName === masterOptionMap.specializationPicklistOptionList[i].optionApiName;
                });

                if (masterOptionMap.specializationPicklistOptionList[i].isSelected !== updatedSpecializationPicklistOptionMap.isSelected) {
                    masterOptionMap.specializationPicklistOptionList[i] = Object.assign({}, updatedSpecializationPicklistOptionMap);
                }
            }
        }
    },

    handleResponseData: function (helper, response) {
        let data;

        if (!!response && response.success === true) {
            data = JSON.parse(response.data);
        }
        else {
            helper.handleErrorInResponseFromApex(response, true);
        }

        return data;
    },

    /**
     * @description handle errors from wrapper LightningResponse
     * @param response {Object}: wrapper LightningResponse class
     * @param isShowToast {Boolean}
     */
    handleErrorInResponseFromApex: function (response, isShowToast) {

        if (isShowToast) {
            $LightningUtil.showCriticalErrorToast();
        }

        if (!!response && response.hasOwnProperty('code') && !!response.code) {
            console.error('APEX ERROR CODE:', response.code);
        }

        if (!!response && response.hasOwnProperty('message') && !!response.message) {
            console.error('APEX ERROR MSG:', response.message);
        }
    },
});