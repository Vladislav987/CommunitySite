/**
 * Created by IlliaLuhovyi on 6/15/2020.
 */
import {api, LightningElement, track} from 'lwc';
import setPayrollComponent from '@salesforce/apex/LW_ReimbursementsController.setPayrollComponent';
import {showToastError, showToastSuccess, showToastWarning} from 'c/toastify';
import constants from "./constants";

export default class ReimbursementsComponentSubmitModal extends LightningElement {

    @track modalClass = 'slds-modal';
    @track backdropClass = 'slds-backdrop';
    @track alertClass = 'slds-modal';
    @track backdropAlertClass = 'slds-backdrop';
    @track isModalShown = false;
    @track isAlertShown = false;
    @track isSendButtonDisabled = true;
    @track isDeleteBtnShown = false;
    @track isLoaderShown = false;
    @track fileNames = [];
    @track inputRow = [
        {
            key: 0,
            random_id: this.getRandomId(),
            sum: '',
            curr: '',
            comment: '',
            travel: ''
        }
    ];
    files = [];
    MAX_FILE_SIZE = 1500000;
    travelRequestId = '';
    projectId = '';
    constants = constants;
    @api currOptions;
    @api
    openModal(travelRequestId, projectId) {
        async function showTemplate(_this) {
            _this.isModalShown = true;
        }

        showTemplate(this)
            .then(() => {
                this.modalClass = 'slds-modal slds-fade-in-open';
                this.backdropClass = 'slds-backdrop slds-backdrop_open';
                this.travelRequestId = travelRequestId;
                this.projectId = projectId;
                this.inputRow[0].travel = travelRequestId;
            })
    }

    closeModal() {
        this.modalClass = 'slds-modal';
        this.backdropClass = 'slds-backdrop';
        this.isModalShown = false;
    }

    openAlert() {
        async function showAlert(_this) {
            _this.isAlertShown = true;
        }

        showAlert(this)
            .then(() => {
                this.alertClass = 'slds-modal slds-fade-in-open';
                this.backdropAlertClass = 'slds-backdrop slds-backdrop_open';
            })
    }

    closeAlert() {
        this.alertClass = 'slds-modal';
        this.backdropAlertClass = 'slds-backdrop';
        this.isAlertShown = false;
    }


    getRandomId() {
        return Math.random().toString(36).substr(2, 9);
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

                this.files = [...this.files, {fileName: item.name, fileData: encodeURIComponent(fileContents)}];
                this.fileNames = [...this.fileNames, item.name];

                const toastMessage = {cmp: this, message: item.name + constants.FILE_ADDED_MSG};

                showToastSuccess(toastMessage);

            });

            fileReader.readAsDataURL(item);
        });

    }

    addNewRow() {
        this.inputRow = [...this.inputRow, { key: this.inputRow.length, random_id: this.getRandomId(), sum: '', comment: '', curr: '', travel: this.travelRequestId }];
        this.isDeleteBtnShown = true;
        this.isSendButtonDisabled = true;
    }

    deleteRow(e) {
        async function deletingProcess(_this) {
            const id = e.target.parentElement.dataset.index;

            let foundIdx;

            for(let [index, item] of _this.inputRow.entries()) {
                if(item.random_id === id) {
                    foundIdx = index;
                }
            }

            _this.inputRow.splice(foundIdx, 1);

            _this.inputRow.forEach((item ,index) => {
                item.key = index;
            });

            if(_this.inputRow.length === 1) {
                _this.isDeleteBtnShown = false;
            }
        }

        deletingProcess(this)
            .then(() => {
                this.isSendButtonDisabled = !(this.validateCurrFields() && this.validateSumFields());
            });

    }

    deleteFile(e) {
        const idx = e.target.parentElement.dataset.index;

        this.files.splice(idx, 1);
        this.fileNames.splice(idx, 1);
    }

    validateSumFields() {
        const sumField = [...this.template.querySelectorAll('.r-sum')];

        return sumField.every(item => !!item.value.length);
    }

    validateCurrFields() {
        const currField = [...this.template.querySelectorAll('.r-curr')];

        return currField.every(item => !!item.value.length);
    }

    onSumChange(e) {
        const idx = e.target.parentElement.dataset.index;

        this.inputRow[idx].sum = e.target.value;
        this.isSendButtonDisabled = !(this.validateSumFields() && this.validateCurrFields());

    }

    onCommentChange(e) {
        const idx = e.target.parentElement.dataset.index;

        this.inputRow[idx].comment = e.target.value;
    }

    onCurrChange(e) {
        const idx = e.target.parentElement.dataset.index;

        this.inputRow[idx].curr = e.detail.value;
        this.isSendButtonDisabled = !(this.validateCurrFields() && this.validateSumFields());
    }

    afterSubmitHandler(data) {
        this.dispatchEvent(new CustomEvent('submit', { detail: data }));

        showToastSuccess({ cmp: this, message: constants.RECORD_CREATED_MSG });

        this.isLoaderShown = false;
        this.clearValue();
        this.closeModal();
    }

    onSubmit() {
        this.isLoaderShown = true;

        const data = JSON.stringify(this.inputRow),
            fileData = JSON.stringify(this.files);

        setPayrollComponent({
            payrollDataStrJson: data,
            travelRequestId: this.travelRequestId,
            projectId: this.projectId,
            fileData: fileData
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

    sendWithoutFiles() {
        this.closeAlert();
        this.onSubmit();
    }

    beforeSubmit() {
        this.files.length ? this.onSubmit() : this.openAlert();
    }

    clearValue() {
        const sum = this.template.querySelector('.r-sum'),
            curr = this.template.querySelector('.r-curr'),
            file = this.template.querySelector('.r-file'),
            comment = this.template.querySelector('.r-comment');

        sum.value = '';
        curr.value = '';
        file.value = '';
        comment.value = '';

        this.isSendButtonDisabled = true;
        this.isDeleteBtnShown = false;
        this.fileNames = [];
        this.files = [];
        this.inputRow = [
            {
                key: 0,
                sum: '',
                curr: '',
                comment: '',
                travel: ''
            }
        ];
    }

    customErrorHandler(err) {
        showToastError({cmp: this, message: constants.ERROR_MSG, mode: 'sticky'});

        const message = `Status: ${err.status} | Message: ${err.body.message}`;
        console.error(message)
    }

    customErrorWithApexResponse(err) {
        showToastError({cmp: this, message: constants.ERROR_MSG, mode: 'sticky'});

        console.error(err);
    }
}