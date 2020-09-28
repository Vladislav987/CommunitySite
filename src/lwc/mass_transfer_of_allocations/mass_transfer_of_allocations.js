/**
 * Created by Ponomarov Vladyslav on 01.06.2020.
 */

import {LightningElement, api, track, wire} from "lwc";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getDataWrapper from '@salesforce/apex/LA_MassTransferOfAllocationsController.getProjects';
import transferAllocations from '@salesforce/apex/LA_MassTransferOfAllocationsController.transferAllocations';
import {getColumnForRelatedListTemplate} from 'c/common_methods';


export default class MassTransferOfAllocations extends LightningElement {
    @api recordId;
    @track projects = [];
    @track allocations = [];

    @track showSpinner = true;
    @track showStep = false;
    @track selectedProject = '';
    @track selectedAction = '';
    @track showButton = false;
    @track columns;

    sowErrorMessage;
    isRowSelected = false;

    connectedCallback() {
        this.init();
    }

    init() {
        getDataWrapper({opportunityId: this.recordId})
            .then(result => {
                this.handleInitData(result);
                if (!this.sowErrorMessage) {
                    if (this.allocations.length === 0) {
                        this.closeModal();
                        this.showToast('Attention', 'You don`t have any related Allocations with record type `Booking Request` and status `New`', 'warning');
                    } else if (this.projects.length === 0) {
                        this.closeModal();
                        this.showToast('Attention', 'You don`t have any related SOWs with status `Signed` and End day after today ', 'warning');
                    }
                }

                this.showSpinner = false;
            })
            .catch(error => {
                this.showToast((!!error.body && !!error.body.message) ? error.body.message : 'Unknown error');
                this.closeModal();
            })
    }

    handleInitData(data) {
        let {sows, fieldsList, fieldsTypes, recordsList, sowErrorMessage} = JSON.parse(JSON.stringify(data));

        if (sowErrorMessage) {
            this.sowErrorMessage = sowErrorMessage;

            this.showToast('Error', sowErrorMessage, 'error');

            this.closeModal();
        } else {
            this.prepareRecordsForTable(fieldsList, fieldsTypes, recordsList);
            this.projects = sows.map(record => ({value: record.Id, label: record.Project__r.Name}));
        }
    }

    prepareRecordsForTable(fieldsList, fieldsTypes, recordsList) {
        recordsList = recordsList.map(record => {
            record.linkName = `/${record.Id}`;
            return record;
        });
        this.columns = getColumnForRelatedListTemplate(fieldsList, fieldsTypes, recordsList);
        this.allocations = recordsList;
    }

    get actions() {
        return [
            {label: 'Skip', value: 'false'},
            {label: 'Reject', value: 'true'},
        ];
    }

    transferAllocations() {
        this.showSpinner = true;
        let table = this.template.querySelector('lightning-datatable');
        let selectedRows = table.getSelectedRows();
        transferAllocations(({
            sowId: this.selectedProject,
            opportunityId: this.recordId,
            allocations: selectedRows,
            isRejectUnselected: this.selectedAction
        }))
            .then(result => {
                this.showToast('Success', 'We successfully transferred allocations.', 'success');
                this.closeModal();
            })
            .catch(error => {
                this.showToast('Unknown error', 'Unexpected error, contact your administrator, please');
                console.error('Error--> ' + JSON.stringify(error));

            })
        this.showSpinner = false;
    }

    handleSelectRow(evt) {
        let table = this.template.querySelector('lightning-datatable');
        let selectedRows = table.getSelectedRows();
        if (selectedRows.length === this.allocations.length) {
            this.showStep = false;
            this.selectedAction = '';
        } else {
            this.showStep = true;
        }

        this.isRowSelected = selectedRows.length > 0;
        this.checkButton();

    }

    handleSelectProject(event) {
        this.selectedProject = event.detail.value;
        this.checkButton();
    }

    handleSelectAction(event) {
        this.selectedAction = event.detail.value;
        this.checkButton();
    }

    showToast(title = 'Unknown error', message = '', variant = 'error') {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    checkButton() {
        this.showButton = (this.isRowSelected && this.selectedProject.length > 0)
            && (!this.showStep || (this.showStep && this.selectedAction.length > 0));
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

}