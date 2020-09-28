/**
 * Created by IlliaLuhovyi on 6/9/2020.
 */

import {api, LightningElement, track} from 'lwc';
import getPayrollComponentWithFilesAndItems from '@salesforce/apex/LW_ReimbursementsController.getPayrollComponentWithFilesAndItems';
import updatePayrollComponent from '@salesforce/apex/LW_ReimbursementsController.updatePayrollComponent';
import {showToastError, showToastSuccess, showToastWarning} from 'c/toastify';
import constants from "./constants";

export default class ReimbursementsComponentEditModal extends LightningElement {

    MAX_FILE_SIZE = 1500000;
    @track modalClass = 'slds-modal';
    @track backdropClass = 'slds-backdrop';
    @track isModalShown = false;
    @track payrollComponentArray = [];
    @track isDeleteBtnShown = false;
    @track isLoaderShown = false;
    @track isSendButtonDisabled = false;
    projectId = '';
    constants = constants;
    @api currOptions;
    @api
    openModal(id, projectId) {
        async function showTemplate(_this) {
            _this.isModalShown = true;
        }

        showTemplate(this)
            .then(() => {
                this.getPayrollComponentItemById(id);
                this.projectId = projectId;
                this.modalClass = 'slds-modal slds-fade-in-open';
                this.backdropClass = 'slds-backdrop slds-backdrop_open';
            })
    }

    closeModal() {
        this.modalClass = 'slds-modal';
        this.backdropClass = 'slds-backdrop';
        this.isModalShown = false;
    }

    getPayrollComponentItemById(id) {
        this.isLoaderShown = true;

        getPayrollComponentWithFilesAndItems({
            payrollComponentId: id
        })
            .then(response => {
                this.isLoaderShown = false;

                if(response.data) {
                    this.payrollComponentArray = JSON.parse(response.data);

                    this.payrollComponentArray.payrollComponentItemInfo.length > 1 ? this.isDeleteBtnShown = true : this.isDeleteBtnShown = false;
                }

            })
            .catch(err => this.customErrorHandler(err))
    }

    addNewRow() {
        this.payrollComponentArray.payrollComponentItemInfo = [...this.payrollComponentArray.payrollComponentItemInfo, { key: this.payrollComponentArray.payrollComponentItemInfo.length,  sum: '', comment: '', curr: '', payrollComponentId: this.payrollComponentArray.Id, isInserted: true, isDeleted: false }];
        this.isDeleteBtnShown = true;
        this.isSendButtonDisabled = true;
    }

    deleteRow(e) {
        async function deletingProcess(_this) {
            const idx = e.target.parentElement.dataset.index,
                length = _this.payrollComponentArray.payrollComponentItemInfo.length;

            let i = 0;

            if(_this.payrollComponentArray.payrollComponentItemInfo[idx].id) {


                _this.payrollComponentArray.payrollComponentItemInfo[idx].isDeleted = true;

                _this.payrollComponentArray.payrollComponentItemInfo.forEach(item => {
                    if(item.isDeleted) {
                        i++;
                    }
                });

                length - i === 1 ? _this.isDeleteBtnShown = false : _this.isDeleteBtnShown = true;
            } else {
                _this.payrollComponentArray.payrollComponentItemInfo.splice(idx, 1);

                _this.payrollComponentArray.payrollComponentItemInfo.forEach(item => {
                    item.key = i++;
                });

                length === 1 ? _this.isDeleteBtnShown = false : _this.isDeleteBtnShown = true;
            }
        }

        deletingProcess(this)
            .then(() => {
                this.isSendButtonDisabled = !(this.validateCurrFields() && this.validateSumFields());
            });
    }

    deleteFile(e) {
        const idx = e.target.parentElement.dataset.index,
            currentFileWrapper = this.payrollComponentArray.filesWrappers[idx];

        if(currentFileWrapper.contentDocumentId) {
            currentFileWrapper.isDeleted = true;
        } else {
            this.payrollComponentArray.filesWrappers.splice(idx, 1);
        }
    }

    onFilesChange(e) {
        const uploadedFiles = e.detail.files;

        Object.values(uploadedFiles).forEach(item => {
            if (item.size > this.MAX_FILE_SIZE) {
                const toastBody = { cmp: this, message: constants.FILE_SIZE_LIMIT_MSG };

                showToastWarning(toastBody);
                return ;
            }

            let fileReader = new FileReader();

            fileReader.onloadend = (() => {
                let fileContents = fileReader.result;
                let base64 = 'base64,';
                let content = fileContents.indexOf(base64) + base64.length;
                fileContents = fileContents.substring(content);

                this.payrollComponentArray.filesWrappers = [...this.payrollComponentArray.filesWrappers, {fileName: item.name, fileData: encodeURIComponent(fileContents), isInserted: true}];

                const toastMessage = {cmp: this, message: item.name + constants.FILE_ADDED_MSG};

                showToastSuccess(toastMessage);

            });

            fileReader.readAsDataURL(item);
        });

    }

    onSumChange(e) {
        const idx = e.target.parentElement.dataset.index;

        this.payrollComponentArray.payrollComponentItemInfo[idx].sum = Number(e.target.value);
        this.payrollComponentArray.payrollComponentItemInfo[idx].isUpdated = true;
        this.isSendButtonDisabled = !(this.validateSumFields() && this.validateCurrFields());

    }

    onCommentChange(e) {
        const idx = e.target.parentElement.dataset.index;

        this.payrollComponentArray.payrollComponentItemInfo[idx].comment = e.target.value;
        this.payrollComponentArray.payrollComponentItemInfo[idx].isUpdated = true;
    }

    onCurrChange(e) {
        const idx = e.target.parentElement.dataset.index;

        this.payrollComponentArray.payrollComponentItemInfo[idx].curr = e.detail.value;
        this.payrollComponentArray.payrollComponentItemInfo[idx].isUpdated = true;
        this.isSendButtonDisabled = !(this.validateCurrFields() && this.validateSumFields());
    }

    validateSumFields() {
        const sumField = [...this.template.querySelectorAll('.r-sum')];

        return sumField.every(item => !!item.value.length);
    }

    validateCurrFields() {
        const currField = [...this.template.querySelectorAll('.r-curr')];

        return currField.every(item => !!item.value.length);
    }

    afterSubmitHandler(data) {
        this.dispatchEvent(new CustomEvent('submit', { detail: data }));

        this.isLoaderShown = false;
        this.closeModal();
        showToastSuccess({cmp: this, message: constants.RECORD_EDITED_MSG});
    }

    onSubmit() {
        this.isLoaderShown = true;

        updatePayrollComponent({
            payrollComponentId: this.payrollComponentArray.Id,
            projectId: this.projectId,
            payrollComponentJson: JSON.stringify(this.payrollComponentArray)
        })
            .then(result => {
                if(result.data) {
                    this.afterSubmitHandler(JSON.parse(result.data));
                } else {
                    this.customErrorWithApexResponse(result.message);
                }

            })
            .catch(err => this.customErrorHandler(err));
    }

    customErrorHandler(err) {
        showToastError({cmp: this, message: constants.ERROR_MSG, mode: 'sticky'});

        const message = `Status: ${err.status} | Message: ${err.body.message}`;
        console.error(message);
    }

    customErrorWithApexResponse(err) {
        showToastError({cmp: this, message: constants.ERROR_MSG, mode: 'sticky'});

        console.error(err);
    }
}