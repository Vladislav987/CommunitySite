import {LightningElement, track, wire} from 'lwc';
import getOvertimes from '@salesforce/apex/LW_ContractorOvertimesController.getOvertimes';

export default class ContractorOvertimes extends LightningElement {

    @track overtimesForCurrentYear = [];
    overtimeWrappers = new Map();
    years;
    selectedYear = '';

    @wire(getOvertimes)
    wiredOvertimes({error, data}) {
        if (data) {
            this.overtimeWrappers = data;
            this.fillYears(Object.keys(this.overtimeWrappers));
            this.selectedYear = this.years[0].value;
            this.fillOvertimesForCurrentYear();
        } else if (error) {
            this.error = error;
        }
    }

    fillYears(yearsWithAtLeastOneOvertime) {
        this.years = [];
        yearsWithAtLeastOneOvertime.forEach(yearWithAtLeastOneOvertime => {
            this.years.push({
                value: yearWithAtLeastOneOvertime,
                label: yearWithAtLeastOneOvertime
            });
        });
    }

    fillOvertimesForCurrentYear() {
        this.overtimesForCurrentYear = [];

        for(let key in this.overtimeWrappers[this.selectedYear]) {
            this.overtimesForCurrentYear.push({key: key, value: this.overtimeWrappers[this.selectedYear][key]})
        }
    }

    changeYear(event) {
        this.selectedYear = event.detail.value;
        this.fillOvertimesForCurrentYear();
    }

    get isEmptyOvertimes() {
        return this.overtimesForCurrentYear.length === 0;
    }
}