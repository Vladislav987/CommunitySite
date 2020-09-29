/**
 * Created by Ponomarov Vladyslav on 16.09.2020.
 */
import {NavigationMixin} from 'lightning/navigation';
import {api, LightningElement} from 'lwc';
import {constants} from './constants';


export default class CustomTableWithoutHeader extends NavigationMixin(LightningElement) {
    @api allocation;
    @api fieldsApiName;
    @api values = [];
    constants = constants;

    @api init() {
        let values = [];
        this.fieldsApiName.forEach(item => {
            if (this.allocation.hasOwnProperty(item)) {
                if (item === 'Name') {
                    values = [...values, {
                        'label': item,
                        'value': this.allocation[item],
                        'isLink': true
                    }];
                } else {
                    values = [...values, {
                        'label': item,
                        'value': this.allocation[item],
                        'isLink': false
                    }];
                }

            } else {
                if (item === 'Contractor__r.Name' && this.allocation.hasOwnProperty('Contractor__r')) {
                    values = [...values, {
                        'label': item,
                        'value': this.allocation['Contractor__r']['Name'],
                        'isLink': false
                    }];
                } else {
                    values = [...values, {
                        'label': item,
                        'value': '',
                        'isLink': false
                    }];
                }
            }
        })
        this.values = values;
    }

    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.allocation['Id'],
                objectApiName: 'Allocation__c',
                actionName: 'view'
            }
        });
    }
}