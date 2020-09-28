import {LightningElement, wire, track} from 'lwc';
import getContractorPayslips from '@salesforce/apex/LW_ContractorPayslipsController.getContractorPayslips';
import {NO_PAYSLIPS_FOUND} from './constants';

export default class ContractorPayslips extends LightningElement {

    @track payslipsForCurrentYear;
    @track allPayslips = [];
    @track years;
    error;
    noPayslipsFound = NO_PAYSLIPS_FOUND;
    errorMessage = '';
    selectedYear = '';

    @wire(getContractorPayslips)
    wiredPayrolls({error, data}) {
        if (data) {
            this.allPayslips = data;
            this.fillYears(Object.keys(this.allPayslips));
            this.years = this.years.reverse();
            this.selectedYear = this.years[0].value;
            this.fillPayslipsForCurrentYear();
            if (this.allPayslips[400] !== undefined) {
                this.error = this.allPayslips[400].error;
                this.errorMessage = this.allPayslips[400].errorMessage;
            }
        } else if (error) {
            this.error = error;
        }
    }


    changeYear(event) {
        this.selectedYear = event.detail.value;
        this.fillPayslipsForCurrentYear();
    }

    fillYears(yearsWithAtLeastOnePayslip) {
        this.years = [];
        yearsWithAtLeastOnePayslip.forEach(yearWithAtLeastOnePayslip => {
            this.years.push({
                value: yearWithAtLeastOnePayslip,
                label: yearWithAtLeastOnePayslip
            });
        });
    }

    fillPayslipsForCurrentYear() {
        this.payslipsForCurrentYear = [];
        this.payslipsForCurrentYear = this.allPayslips[this.selectedYear];
        console.log('payslipsForCurrentYear' + JSON.stringify(this.payslipsForCurrentYear));
    }
}