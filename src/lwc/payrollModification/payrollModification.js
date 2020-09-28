import {LightningElement, api, track} from 'lwc';
import getPayrollComponents from '@salesforce/apex/LW_PayrollModificationController.getPayrollComponents';
import {constants} from './constants';

export default class PayrollModification extends LightningElement {

    @api payRollCmpConfig;

    @track nonRecurrentPayslips = [];
    @track recurrentPayslips = [];
    payslipTypes = [];
    error;
    errorMessage;
    isRecurrentSelected;
    selectedPayslipType;

    PAYSLIP_TYPES = constants.PAYSLIP_TYPES;
    SELECT_PAYSLIP_TYPES = constants.SELECT_PAYSLIP_TYPES;

    connectedCallback() {
        this.payslipTypes.push({
            value: constants.NON_RECURRENT,
            label: constants.NON_RECURRENT
        });
        this.payslipTypes.push({
            value: constants.RECURRENT,
            label: constants.RECURRENT
        });
        this.selectedPayslipType = constants.NON_RECURRENT;
        this.isRecurrentSelected = false;
        this.getPayrollComponents();
    }

    renderedCallback() {
        let payslipTypesCombobox = this.template.querySelector('[data-id="payslipTypesCombobox"]');
        payslipTypesCombobox.disabled = this.payRollCmpConfig.QualifiedApiName.includes('Adjustment');
    }

    getPayrollComponents() {
        getPayrollComponents({
            payRollCmpConfig: this.payRollCmpConfig,
            payRollCmpConfigFieldList : this.payRollCmpConfig.Payroll_Component_Configuration_Fields__r
        }).then(
            result => {
                this.nonRecurrentPayslips = result[constants.NON_RECURRENT];
                this.recurrentPayslips = result[constants.RECURRENT];
                if (result['400'] !== undefined) {
                    this.error = result['400'].error;
                    this.errorMessage = result['400'].errorMessage;
                }
            },
            error => {
                this.error = error;
            }
        )
    }

    changePayslipType(event) {
        this.selectedPayslipType = event.detail.value;
        this.isRecurrentSelected = constants.RECURRENT === this.selectedPayslipType;
    }
}