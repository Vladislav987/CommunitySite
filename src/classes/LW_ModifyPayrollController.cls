/**
 * Created by admin on 16.07.2020.
 */

public with sharing class LW_ModifyPayrollController {

    private static LightningResponse response = new LightningResponse();
    private static final String EMPLOYEE_API_NAME = 'Account__c';
    private static final String START_DATE_API_NAME = 'StartDate__c';
    private static final String EMPLOYEE_LABEL_NAME = 'Employee Name';

    @AuraEnabled
    public static LightningResponse getLayoutConfigFields(String recordIdPayroll,
                                                          List<Payroll_Component_Configuration_Field__mdt> payRollCmpConfigFields,
                                                          Boolean isReadOnlyMode) {

        Payroll_Component__c payrollComponent = [
                SELECT Id, Recurrent__c
                FROM Payroll_Component__c
                WHERE Id = :recordIdPayroll
                LIMIT 1
        ];


        List<LayoutConfigFields> layoutConfigFieldsList = new List<LayoutConfigFields>();

        try {
            LayoutConfigFields layoutConfigFieldsForName = new LayoutConfigFields(EMPLOYEE_LABEL_NAME, EMPLOYEE_API_NAME, 0, false);
            layoutConfigFieldsList.add(layoutConfigFieldsForName);


            for (Payroll_Component_Configuration_Field__mdt obj : payRollCmpConfigFields) {
                LayoutConfigFields layoutConfigFields;
                if (obj.Is_Hidden__c) continue;

                if (obj.Field_API_Name__c.equals(START_DATE_API_NAME)) {
                    layoutConfigFields = new LayoutConfigFields(obj.Title__c, obj.Field_API_Name__c, obj.Order__c, false);
                    layoutConfigFieldsList.add(layoutConfigFields);
                    continue;
                }

                if (obj.Recurrent_Only__c) {

                    if(!payrollComponent.Recurrent__c) continue;

                    if(payrollComponent.Recurrent__c) {
                        layoutConfigFields = new LayoutConfigFields(obj.Title__c, obj.Field_API_Name__c, obj.Order__c, false);
                        layoutConfigFieldsList.add(layoutConfigFields);
                        continue;
                    }
                }

                Boolean isInputType = !isReadOnlyMode;
                layoutConfigFields = new LayoutConfigFields(obj.Title__c, obj.Field_API_Name__c, obj.Order__c, isInputType);
                layoutConfigFieldsList.add(layoutConfigFields);

            }


            layoutConfigFieldsList.sort();

            response.setResult(JSON.serialize(layoutConfigFieldsList));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LW_ModifyPayrollController.class));
        }

        return response;
    }

    public class LayoutConfigFields implements Comparable {

        @AuraEnabled public  String label { get; set; }
        @AuraEnabled public  String value { get; set; }
        @AuraEnabled public  Decimal order { get; set; }
        @AuraEnabled public  Boolean isInputType { get; set; }

        public LayoutConfigFields(String label, String value, Decimal order, Boolean isInputType) {
            this.label = label;
            this.value = value;
            this.order = order;
            this.isInputType = isInputType;
        }

        public Integer compareTo(Object objToCompare) {
            LayoutConfigFields layoutConfigFields = (LayoutConfigFields)objToCompare;

            if (order > layoutConfigFields.order) {
                return 1;
            }
            else if (order < layoutConfigFields.order) {
                return -1;
            }

            return 0;
        }
    }

    public class LightningResponse extends Model.LightningResponse {

        /* For success response with JSON data  */
        public void setResult(String data) {
            this.data = data;
            this.success = true;
        }

        /* For error response with message */
        public void setError(String message) {
            this.message = message;
            this.success = false;
        }
    }
}