/**
 * Created by Ponomarov Vladyslav on 16.09.2020.
 */

import {LightningElement, api, wire, track} from 'lwc';
import getData from '@salesforce/apex/LW_AllocationGroupingProjectController.getData';
import RECORD_TYPE_ID from '@salesforce/schema/Project__c.RecordTypeId';
import { getRecord } from "lightning/uiRecordApi";
import {constants} from './constant';

export default class RelatedAllocationForGroupingProject extends LightningElement {

    @api childProjects;
    @api columns;
    @api fieldsApiName;
    @api recordId;    @api teams;

    @api showData;
    @api teamsOption = [];
    @api statuses;
    @api statusesOption = [];
    @api types;
    @api typesOption = [];
    @api contractors;
    @api contractorsOption = [constants.ITEM_ALL];

    constants = constants;
    fieldsApiNameByName;
    allProjects;
    selectedProject = constants.STRING_ALL;
    selectedStatus = constants.STRING_ALL;
    selectedType = constants.STRING_ALL;
    selectedContractor = constants.STRING_ALL;
    sortedDirection = constants.STRING_ALL;

    @wire(getRecord, { recordId: '$recordId', fields: [RECORD_TYPE_ID] })
    response({ data, error }) {
        if (data) {
            if (data.recordTypeInfo.name === constants.TARGET_PROJECT_RT){
                this.init();
            }
        } else if (error) {
            console.error(JSON.stringify(error));
        }
    }

    init() {
        getData({projectId: this.recordId})
            .then(result => {
                this.childProjects = this.showData = result.childProjects;
                this.allProjects = result.childProjects;
                this.teams = result.teams;
                this.columns = Object.keys(result.fieldsList);
                this.fieldsApiName = Object.values(result.fieldsList);
                this.fieldsApiNameByName = result.fieldsList;
                this.teamsOption = this.prepareData(result.teams);
                this.statuses = result.statuses;
                this.statusesOption = this.prepareData(result.statuses);
                this.types = result.types;
                this.typesOption = this.prepareData(result.types);
                this.contractors = result.contractors;
                result.contractors.forEach(item => {
                    this.contractorsOption = [...this.contractorsOption, {label: item.Name, value: item.Id}]
                });

                this.rerenderDataInChildren();
            })
            .catch(error => {
                console.error('Error--> ' + JSON.stringify(error));
            })
    }

    handleChangeProject(event) {
        this.selectedProject = event.detail.value;
    }

    handleChangeStatus(event) {
        this.selectedStatus = event.detail.value;
    }

    handleChangeType(event) {
        this.selectedType = event.detail.value;
    }

    handleChangeContractor(event) {
        this.selectedContractor = event.detail.value;
    }

    sortColumn(event) {
        let columnName = event.currentTarget.dataset.id;
        let columnApiName = this.fieldsApiNameByName[columnName];
        let reverse = this.sortedDirection === 'asc' ? 1 : -1;
        let table = [...this.childProjects];
        table.forEach(project => {
            if (project['Allocations__r']) {
                project['Allocations__r'].sort((a, b) => {
                        if (columnApiName === 'Contractor__r.Name') {
                            a = a['Contractor__r'] ? a['Contractor__r']['Name'] : '';
                            b = b['Contractor__r'] ? b['Contractor__r']['Name'] : '';
                                return a > b ? reverse : -1 * reverse;
                        } else {
                            a = a[columnApiName] ? a[columnApiName] : '';
                            b = b[columnApiName] ? b[columnApiName] : '';
                            return a > b ? reverse : -1 * reverse
                        }
                    }
                );
            }
        })
        this.sortedDirection = this.sortedDirection === 'asc' ? 'desc' : 'asc';
        this.childProjects = table;
    }

    filterAllocations() {
        let projects = [...this.allProjects];
        let project = this.selectedProject;
        let status = this.selectedStatus;
        let type = this.selectedType;
        let contractor = this.selectedContractor;
        let result = [];

        projects.reverse().forEach((item, index) => {
            if (project === 'all' || item['Name'] === project) {

                let allocations = [];
                if (item.hasOwnProperty('Allocations__r')) {
                    item['Allocations__r'].reverse().forEach(allocation => {
                        if ((status === 'all' || allocation['Status__c'] === status)
                            && (type === 'all' || allocation['Allocation_Type__c'] === type)
                            && (contractor === 'all' || allocation['Contractor__c'] === contractor)) {
                            allocations = [...allocations, allocation];
                        }
                    })
                }
                let project = {'Id': item['Id'], 'Name': item['Name'], 'Allocations__r': allocations};
                result = [...result, project];

            }
        })
        this.childProjects = result;
        this.rerenderDataInChildren();
    }

    rerenderDataInChildren() {
        setTimeout(() => this.template.querySelectorAll("c-custom-table-without-header").forEach(function (el) {
            el.init();
        }));
    }

    prepareData(data) {
        let result = [constants.ITEM_ALL];
        data.forEach(item => {
            result = [...result, {label: item, value: item}]
        });
        return result;
    }
}