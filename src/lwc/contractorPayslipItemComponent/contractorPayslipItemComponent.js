import {LightningElement, api} from 'lwc';
import {colorStyleForSum, colorStyleForSumForIncrement, colorStyleForSumForDecrement} from './constants';

export default class ContractorPayslipItemComponent extends LightningElement {

    privateContractorPayslipComponent;
    colorStyleForSum

    @api
    get contractorPayslipComponent() {
    }

    set contractorPayslipComponent(value) {
        this.privateContractorPayslipComponent = value;
        this.colorStyleForSum = colorStyleForSum;
        if (value.SumType) {
            this.colorStyleForSum += value.SumType === value.increment ? colorStyleForSumForIncrement : colorStyleForSumForDecrement;
        }
    }
}