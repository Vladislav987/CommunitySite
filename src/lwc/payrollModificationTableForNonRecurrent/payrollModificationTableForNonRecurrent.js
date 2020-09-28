import {LightningElement, api, track} from 'lwc';
import deletePayrollComponents from '@salesforce/apex/LW_PayrollModificationController.deletePayrollComponents';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {constants} from './constants';

export default class PayrollModificationTableForNonRecurrent extends LightningElement {

    @api payRollCmpConfig;
    @api recordIdPayroll;
    @api isReadOnlyMode;

    @track allSortedNonRecurrentPayslips = [];
    @track paginatedSortedNonRecurrentPayslips = [];
    @track currentPagePayslips = [];

    page = 1;
    pages = 1;
    total = 0;
    deleteValue = constants.DELETE;
    label = constants.ITEMS;
    SENTENCE_MODAL = constants.SENTENCE_MODAL;
    CLOSE = constants.CLOSE;
    QUESTION_MODAL_PART_1 = constants.QUESTION_MODAL_PART_1;
    QUESTION_MODAL_PART_2 = constants.QUESTION_MODAL_PART_2;
    isModalOpen = false;
    showComponent = false;
    checkedAmount = 0;
    errorMessage = constants.SOMETHING_WENT_WRONG_MESSAGE;
    DETAIL = constants.DETAIL;
    CANCEL = constants.CANCEL;
    showInsuranceTypeData;
    showAdjustmentTypeData;

    @api
    get nonRecurrentPayslips() {}

    set nonRecurrentPayslips(value) {
        this.showInsuranceTypeData = this.payRollCmpConfig.Title__c === 'Insurance';
        this.showAdjustmentTypeData = this.payRollCmpConfig.Title__c === 'Adjustment';
        this.allSortedNonRecurrentPayslips = JSON.parse(JSON.stringify(value));
        this.paginatedSortedNonRecurrentPayslips = this.chunkArray(this.allSortedNonRecurrentPayslips.payslipWrappers, 20);

        if (!this.allSortedNonRecurrentPayslips.payslipWrappers || !this.allSortedNonRecurrentPayslips.payslipWrappers.length) {
            this.errorMessage = constants.NO_RECORDS_FOUND;
        }
    }

    chunkArray(list, chunkSize) {
        let paginatedArray = [];
        this.currentPagePayslips = [];

        if (list && list.length) {
            this.total = list.length;

            for (let index = 0; index < list.length; index += chunkSize) {
                let chunk = list.slice(index, index + chunkSize);

                paginatedArray.push(chunk);
            }

            this.pages = paginatedArray.length;
            this.currentPagePayslips = paginatedArray[this.page - 1];
        }

        return paginatedArray;
    }

    allSelected(event) {
        let deleteBtn = this.template.querySelector('[data-id="deleteBtn"]');
        let checkboxCmpList = this.template.querySelectorAll('[data-id="payslip-checkbox"]');
        this.checkedAmount = 0;

        for (const checkboxCmp of checkboxCmpList) {
            checkboxCmp.checked = event.target.checked;

            if (checkboxCmp.checked) this.checkedAmount++;
        }

        event.target.checked = this.checkedAmount > 0;
        deleteBtn.disabled = this.checkedAmount === 0;
    }

    onSelect() {
        let deleteBtn = this.template.querySelector('[data-id="deleteBtn"]');
        deleteBtn.disabled = this.getSelectedPayslips().length === 0;
    }

    getSelectedPayslips() {
        this.selectedPayslips = [];

        let selectedRows = this.template.querySelectorAll('lightning-input');
        this.checkedAmount = 0;
        for(let i = 0; i < selectedRows.length; i++) {
            if(selectedRows[i].checked && selectedRows[i].type === 'checkbox' && !selectedRows[i].type.disabled && selectedRows[i].value) {
                this.selectedPayslips.push(selectedRows[i].value);
                this.checkedAmount++;
            }
        }
        return this.selectedPayslips;
    }

    sortColumn(event) {
        let columnName = constants.COLUMN_NAME_TO_WRAPPER_NAME[event.currentTarget.dataset.key];
        let isAsc = JSON.parse(event.currentTarget.dataset.index);
        let isReverse = isAsc ? 1 : -1;
        this.allSortedNonRecurrentPayslips.payslipColumnsWrappers.forEach(payslipColumnsWrapper => {
            if (payslipColumnsWrapper.name === event.currentTarget.dataset.key) payslipColumnsWrapper.isAsc = !isAsc;
        });
        this.paginatedSortedNonRecurrentPayslips = this.chunkArray(this.sort(columnName, isReverse, this.allSortedNonRecurrentPayslips.payslipWrappers), 20);
    }

    sort(columnName, isReverse, payslipWrappers) {
        return JSON.parse(JSON.stringify(payslipWrappers)).sort((a, b) => {
            a = a[columnName] ? a[columnName].toLowerCase() : '';
            b = b[columnName] ? b[columnName].toLowerCase() : '';
            return a > b ? isReverse : -1 * isReverse;
        });
    }

    async deletePayslips() {
        try {
            this.isModalOpen = false;
            await deletePayrollComponents({payrollComponentsIds: this.getSelectedPayslips()});
            await this.dispatchEvent(new CustomEvent('refresh'));
            const successToast = new ShowToastEvent({
                title: constants.SUCCESSFULLY_DELETED,
                variant: 'success',
            });
            this.dispatchEvent(successToast);
            let deleteBtn = this.template.querySelector('[data-id="deleteBtn"]');
            deleteBtn.disabled = true;
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

    get hasPreviousPage() {
        return this.page > 1;
    }

    get hasMorePages() {
        return this.page < this.pages;
    }

    handlePagePrevious() {
        --this.page;
        this.currentPagePayslips = this.paginatedSortedNonRecurrentPayslips[this.page - 1];
    }

    handlePageNext() {
        ++this.page;
        this.currentPagePayslips = this.paginatedSortedNonRecurrentPayslips[this.page - 1];
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    onDetail(event) {
        this.showComponent = true;
        this.recordIdPayroll = event.target.dataset.recordId;
        this.isReadOnlyMode = !JSON.parse(event.target.dataset.isPayrollEmpty);
    }

    onSavedModifyCmp() {
        this.dispatchEvent(new CustomEvent(constants.REFRESH));
    }

    onCloseModifyCmp() {
        this.showComponent = false;
    }
}