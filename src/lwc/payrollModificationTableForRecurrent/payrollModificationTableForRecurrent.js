import {LightningElement, api, track} from 'lwc';
import deactivatePayrollComponents from '@salesforce/apex/LW_PayrollModificationController.deactivatePayrollComponents';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {constants} from "./constants";

export default class PayrollModificationTableForRecurrent extends LightningElement {

    @api payRollCmpConfig;
    @api recordIdPayroll;
    @api isReadOnlyMode;

    DEACTIVATE = constants.DEACTIVATE;
    CLOSE = constants.CLOSE;
    QUESTION_MODAL_PART_1 = constants.QUESTION_MODAL_PART_1;
    QUESTION_MODAL_PART_2 = constants.QUESTION_MODAL_PART_2;
    SENTENCE_MODAL = constants.SENTENCE_MODAL;
    NOTE_MODAL = constants.NOTE_MODAL;
    CANCEL = constants.CANCEL;
    isModalOpen = false;
    page = 1;
    pages = 1;
    total = 0;
    label = constants.ITEMS;
    checkedAmount = 0;
    errorMessage = constants.SOMETHING_WENT_WRONG_MESSAGE;
    showComponent = false;
    DETAIL = constants.DETAIL;
    showInsuranceTypeData;

    @track sortedRecurrentPayslips = [];
    @track paginatedSortedRecurrentPayslips = [];
    @track currentPagePayslips;

    @api
    get recurrentPayslips() {
    }

    set recurrentPayslips(value) {
        this.showInsuranceTypeData = this.payRollCmpConfig.Title__c === 'Insurance';
        this.sortedRecurrentPayslips = JSON.parse(JSON.stringify(value));
        this.paginatedSortedRecurrentPayslips = this.chunkArray(this.sortedRecurrentPayslips.payslipWrappers, 20);

        if (!this.sortedRecurrentPayslips.payslipWrappers || !this.sortedRecurrentPayslips.payslipWrappers.length) {
            this.errorMessage = constants.NO_RECORDS_FOUND;
        }
    }

    chunkArray(list, chunkSize) {
        if (list) {
            let arrayLength = list.length;
            this.total = arrayLength;
            let paginatedArray = [];
            for (let index = 0; index < arrayLength; index += chunkSize) {
                let chunk = list.slice(index, index + chunkSize);
                paginatedArray.push(chunk);
            }
            this.pages = paginatedArray.length;
            this.currentPagePayslips = paginatedArray[this.page - 1];
            return paginatedArray;
        }
    }

    async deactivatePayslips() {
        try {
            this.isModalOpen = false;
            await deactivatePayrollComponents({payrollComponentsIds: this.getSelectedPayslips()});
            await this.dispatchEvent(new CustomEvent(constants.REFRESH));
            const successToast = new ShowToastEvent({
                title: constants.SUCCESSFULLY_DEACTIVATED,
                variant: 'success',
            });
            this.dispatchEvent(successToast);
            let deactivateBtn = this.template.querySelector('[data-id="deactivateBtn"]');
            deactivateBtn.disabled = true;
        } catch (e) {
            this.errorMessage = e;

            const failureToast = new ShowToastEvent({
                title: '',
                message: constants.SOMETHING_WENT_WRONG_MESSAGE,
                variant: 'error'
            });

            this.dispatchEvent(failureToast);
        }
    }

    allSelected(event) {
        let deactivateBtn = this.template.querySelector('[data-id="deactivateBtn"]');
        let checkboxCmpList = this.template.querySelectorAll('[data-id="payslip-checkbox"]');
        this.checkedAmount = 0;

        for (const checkboxCmp of checkboxCmpList) {
            checkboxCmp.checked = event.target.checked;

            if (checkboxCmp.checked) this.checkedAmount++;
        }

        event.target.checked = this.checkedAmount > 0;
        deactivateBtn.disabled = this.checkedAmount === 0;
    }

    onSelect() {
        let deactivateBtn = this.template.querySelector('[data-id="deactivateBtn"]');
        deactivateBtn.disabled = this.getSelectedPayslips().length === 0;
    }

    getSelectedPayslips() {
        let selectedPayslips = [];

        let selectedRows = this.template.querySelectorAll('lightning-input');
        this.checkedAmount = 0;
        for(let i = 0; i < selectedRows.length; i++) {
            if(selectedRows[i].checked && selectedRows[i].type === 'checkbox' && !selectedRows[i].type.disabled && selectedRows[i].value) {
                selectedPayslips.push(selectedRows[i].value);
                this.checkedAmount++;
            }
        }
        return selectedPayslips;
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    sortColumn(event) {
        let columnName = constants.COLUMN_NAME_TO_WRAPPER_NAME[event.currentTarget.dataset.key];
        let isAsc = JSON.parse(event.currentTarget.dataset.index);
        let isReverse = isAsc ? 1 : -1;
        this.sortedRecurrentPayslips.payslipColumnsWrappers.forEach(payslipColumnsWrapper => {
            if (payslipColumnsWrapper.name === event.currentTarget.dataset.key) payslipColumnsWrapper.isAsc = !isAsc;
        });
        this.paginatedSortedRecurrentPayslips = this.chunkArray(this.sort(columnName, isReverse, this.sortedRecurrentPayslips.payslipWrappers), 20);
    }

    sort(columnName, isReverse, payslipWrappers) {
        return JSON.parse(JSON.stringify(payslipWrappers)).sort((a, b) => {
            a = a[columnName] ? a[columnName].toLowerCase() : '';
            b = b[columnName] ? b[columnName].toLowerCase() : '';
            return a > b ? isReverse : -1 * isReverse;
        });
    }

    get hasPreviousPage() {
        return this.page > 1;
    }

    get hasMorePages() {
        return this.page < this.pages;
    }

    handlePagePrevious() {
        this.page = this.page - 1;
        this.currentPagePayslips = this.paginatedSortedRecurrentPayslips[this.page - 1];
    }

    handlePageNext() {
        this.page = this.page + 1;
        this.currentPagePayslips = this.paginatedSortedRecurrentPayslips[this.page - 1];
    }

    onDetail(event) {
        this.showComponent = true;
        this.recordIdPayroll = event.target.dataset.recordId;
        this.isReadOnlyMode = JSON.parse(event.target.dataset.isReadOnlyMode);
    }

    onSavedModifyCmp() {
        this.dispatchEvent(new CustomEvent(constants.REFRESH));
    }

    onCloseModifyCmp() {
        this.showComponent = false;
    }
}