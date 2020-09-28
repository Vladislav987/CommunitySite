/**
 * Created by IlliaLuhovyi on 4/16/2020.
 */
import {LightningElement, track} from 'lwc';
import getContractorProjects from '@salesforce/apex/LW_ReimbursementsController.getContractorProjects';
import createCurrencyOptions from '@salesforce/apex/LW_ReimbursementsController.getCurrencyTypes';
import constants from './constans';
import {showToastError} from 'c/toastify';

export default class ReimbursementsComponent extends LightningElement {

    @track filter_projects_value = 'true';
    @track isLoaderShown = true;
    @track projects;
    @track currOptions = [];
    constants = constants;

    connectedCallback() {
        getContractorProjects({status: true})
            .then(result => {
                this.projects = result;
                this.isLoaderShown = false;
            })
            .catch(err => this.customErrorHandler(err));

        createCurrencyOptions()
            .then(result => {
                result.forEach(item => {
                    this.currOptions = [...this.currOptions, {label: item.IsoCode, value: item.IsoCode}]
                })
            })
            .catch(err => this.customErrorHandler(err));
    }

    get filter_projects_options() {
        return [
            { label: 'Show all projects', value: 'true' },
            { label: 'Show active projects', value: 'false' },
        ];
    }

    onFilterChange(e) {
        this.filter_projects_value = e.detail.value;

        getContractorProjects({status: String(true) === e.detail.value})
            .then(response => {
                this.projects = response;
            })
            .catch(err => this.customErrorHandler(err))

    }


    openEditModal(e) {
        const id = e.target.dataset.id,
                projectId = e.target.dataset.project;

        this.template
            .querySelector('c-reimbursements-component-edit-modal')
            .openModal(id, projectId);
    }

    openSubmitModal(e) {
        const parent = e.target.parentElement,
            projectId = e.target.name,
            travelRequestId = parent.name;

        this.template
            .querySelector('c-reimbursements-component-submit-modal')
            .openModal(travelRequestId, projectId);
    }

    onEditModalSubmit(response) {
        const data = response.detail;

        const project = this.projects.find(item => item.Id === data.projectId),
            travelRequest = project.travelArray.find(item => item.Id === data.TravelId),
            payrollComponent = travelRequest.payrollComponentArray.find(item => item.Id === data.Id);

        payrollComponent.CurrencyCode = data.CurrencyCode;
        payrollComponent.Sum = data.Sum;
        payrollComponent.Status = data.Status;
        payrollComponent.rejectionReason = data.rejectionReason;
    }

    onSubmitModal(response) {
        const data = response.detail[0];

        const project = this.projects.find(item => item.Id === data.projectId),
            travelRequest = project.travelArray.find(item => item.Id === data.TravelId);

        travelRequest.payrollComponentArray = [...travelRequest.payrollComponentArray, data];
    }

    customErrorHandler(err) {
        showToastError({cmp: this, message: constants.ERROR_MSG, mode: 'sticky'});

        const message = `Status: ${err.status} | Message: ${err.body.message}`;
        console.error(message)
    }
}