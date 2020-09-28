/**
 * Created by Mariya Kropinova on 14.07.2020.
 */

import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PAYROLL_COMPONENT_OBJECT from '@salesforce/schema/Payroll_Component__c';
import getLayoutConfigFields from '@salesforce/apex/LW_ModifyPayrollController.getLayoutConfigFields';

export default class ModifyPayrollComponentDevelopment extends LightningElement {

    @api recordIdPayroll;
    @api payRollCmpConfig;
    @api isReadOnlyMode;
    @api isRecurrent;

    @track layoutConfigFieldsList;
    objectApiName = PAYROLL_COMPONENT_OBJECT;

    connectedCallback() {
        this.getLayoutConfigObj();
    }

    getLayoutConfigObj() {
        getLayoutConfigFields({
                        recordIdPayroll : this.recordIdPayroll,
                        payRollCmpConfigFields  : this.payRollCmpConfig.Payroll_Component_Configuration_Fields__r,
                        isReadOnlyMode : this.isReadOnlyMode
                    })
        .then(response => {
            this.layoutConfigFieldsList = JSON.parse(response.data);
            this.error = undefined;
        })
        .catch(error => {
            this.error = error;
            this.data  = undefined;
        });
    }

    onSuccess() {
        this.fireSavedEvent();
        this.closeModal();
    }

    handleReset(event) {
       const inputFields = this.template.querySelectorAll(
           'lightning-input-field'
       );
       if (inputFields) {
           inputFields.forEach(field => {
               field.reset();
           });
       }
    }

    fireSavedEvent() {
        this.dispatchEvent(new CustomEvent('saved'));
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleCancel() {
        this.closeModal();
    }
}