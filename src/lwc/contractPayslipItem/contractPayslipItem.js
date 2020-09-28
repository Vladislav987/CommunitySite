import {LightningElement, api} from 'lwc';
import {salaryDate, salary} from './constants';

export default class ContractPayslipItem extends LightningElement {

    @api contractorPayslip;
    salaryDate = salaryDate;
    salaryComponent;

    connectedCallback() {
        this.salaryComponent = {
            Name: salary
            , Sum: this.contractorPayslip.Salary
        };
    }
}