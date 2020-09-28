/**
 * Created by Ponomarov Vladyslav on 10.06.2020.
 */

import {LightningElement, api, track} from "lwc";
import isShow from '@salesforce/apex/LW_SalaryComponentController.getValue';


export default class SalaryComponent extends LightningElement {
    @api recordId;
    @api objectApiName;

    @track areDetailsVisible = true;
    @track value;
    @track fieldName;
    @track showTable = false;
    @track columns;

    connectedCallback() {
        this.init();
    }

    init() {
        isShow({recordId: this.recordId})
            .then(result => {
                console.log('SHOW');
                this.fieldName = this.objectApiName === 'Contractor__c' ? 'Salary' : 'Hourly Rate';
                this.value = result;
                console.error('result---> ' + JSON.stringify(this.value));
                if (result.recordsList && this.objectApiName === 'Contractor__c'){
                    this.columns = this.getColumns();
                    this.showTable = true;
                }


            })
            .catch(error => {
                console.error('Error---> ' + JSON.stringify(error));
            })

    }
    getColumns(){
        let fieldsList = this.value.fieldsList;
        let columns = Object.keys(fieldsList).map((key) => {
            return {
                label: key,
                fieldName: fieldsList[key],
                type: 'text',
                editable: false,
                cellAttributes: {alignment: 'center'}
            }
        });
        return columns;
    }

}