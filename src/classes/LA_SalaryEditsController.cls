/**
 * Created by Lambru Dmytro on 06.04.2020.
 * NOTE: "LA_" - Lightning Aura.
 */

public without sharing class LA_SalaryEditsController {

    private static LightningResponse response = new LightningResponse();
    private static LA_SalaryEditsHelper helper = new LA_SalaryEditsHelper();

    /**
     * @description Forms an object with settings for the component.
     *
     * @return Response with config object for component.
     */
    @AuraEnabled
    public static LightningResponse getCmpConfig(String projectId) {

        try {

            if ( !helper.isCurrentUserProjectOwner(projectId) ) {
                return response.setError(401);
            }

            LA_SalaryEditsService.ComponentConfig componentConfig = helper.generateComponentConfigForBonuses();

            response.setResult(JSON.serialize(componentConfig, true));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_SalaryEditsController.class));
        }

        return response;
    }

    /**
     * @description Contractor info selected by Id.
     *
     * @param contractorId ID of Contractor.
     *
     * @return Response with the list of data.
     */
    @AuraEnabled
    public static LightningResponse getContractorById(String contractorId) {
        try {
            ContractorSelector contractorSelector = new ContractorSelector();

            Contractor__c[] contractorList = contractorSelector.getNameAndCurrIsoCodeById(contractorId);

            response.setResult(JSON.serialize(contractorList));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_SalaryEditsController.class));
        }

        return response;
    }

    /**
     * @description Travel Requests selected by Contractor Id & Project Id.
     *
     * @param contractorId ID of Contractor.
     * @param projectId ID of Project.
     *
     * @return Response with the list of data.
     */
    @AuraEnabled
    public static LightningResponse getContractorTravelRequests(String contractorId, String projectId) {
        try {

            LA_SalaryEditsService.TravelRequestConfig travelRequest = helper.getTravelRequestsById(contractorId, projectId);

            response.setResult(JSON.serialize(travelRequest));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_SalaryEditsController.class));
        }

        return response;
    }

    /**
     * @description Conversion rate of currency for today.
     *
     * @return Response with the list of data.
     */
    @AuraEnabled
    public static LightningResponse getConversionRate() {
        try {

            DatedConversionRate[] lstConversionRate = [
                    SELECT Id, IsoCode, ConversionRate
                    FROM DatedConversionRate
                    WHERE NextStartDate > TODAY
                    LIMIT 1000
            ];

            response.setResult(JSON.serialize(lstConversionRate));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_SalaryEditsController.class));
        }

        return response;
    }

    /**
     * @description Forms a list based on project allocations with Contractor's data.
     *
     * @param projectId ID of Project record.
     * @param monthNumber Order number of the month.
     * @param year Year.
     *
     * @return Response with the list of data.
     */
    @AuraEnabled
    public static LightningResponse getContractorsForPeriod(String projectId, Integer monthNumber, Integer year) {

        try {

            if ( !helper.isCurrentUserProjectOwner(projectId) ) {
                return response.setError(401);
            }

            LA_SalaryEditsService.ContractorInfo[] contractorInfoList = helper.getContractorsForPeriod(projectId, monthNumber, year);

            response.setResult(JSON.serialize(contractorInfoList, true));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_SalaryEditsController.class));
        }

        return response;
    }

    /**
     * @description Forms a list based on project allocations with Contractor's data.
     *
     * @param projectId ID of Project record.
     * @param monthNumber Order number of the month.
     * @param year Year.
     *
     * @return Response with the list of data.
     */
    @AuraEnabled
    public static LightningResponse getContractorsForPeriodForReimbursement(String projectId, Integer monthNumber, Integer year) {

        try {

            if ( !helper.isCurrentUserProjectOwner(projectId) ) {
                return response.setError(401);
            }

            LA_SalaryEditsService.ContractorInfo[] contractorInfoList = helper.getContractorsForPeriodForReimbursement(projectId, monthNumber, year);

            response.setResult(JSON.serialize(contractorInfoList));
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_SalaryEditsController.class));
        }

        return response;
    }

    /**
     * @description Creates 1 "Budget_transaction" record and 1 "Payroll_Component" record based on user input.
     *
     * @param projectId ID of Project record.
     * @param jsonContractorInfoList JSON with the list of Contractor's data modified by a user.
     *
     * @return Response with success operation or not.
     */
    @AuraEnabled
    public static LightningResponse generateBonuses(String projectId, String jsonContractorInfoList) {

        try {
            LA_SalaryEditsService.ContractorInfo[] contractorInfoList = (LA_SalaryEditsService.ContractorInfo[]) JSON.deserialize(jsonContractorInfoList, LA_SalaryEditsService.ContractorInfo[].class);
            helper.generateBonusesForContractors(projectId, contractorInfoList);

            response.success = true;
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_SalaryEditsController.class));
        }

        return response;
    }

    /**
     * @description Creates 1 "Budget_transaction" record , 1 "Payroll_Component" record and several "Payroll_Component_item" records based on user input.
     *
     * @param projectId ID of Project record.
     * @param jsonPayrollComponentList JSON with the list of data for Payroll_Component.
     * @param jsonPayrollComponentItemList JSON with the list of data for Payroll_Component_item.
     * @param jsonFileList JSON with the list of files data for Payroll_Component Attachments.
     *
     * @return Response with success operation or not.
     */
    @AuraEnabled
    public static LightningResponse generateReimbursement(String projectId, String jsonPayrollComponentList, String jsonPayrollComponentItemList, String jsonFileList) {
        try {
            LA_SalaryEditsService.PayrollComponentInfo payrollComponentList =
                    (LA_SalaryEditsService.PayrollComponentInfo) JSON.deserialize(jsonPayrollComponentList, LA_SalaryEditsService.PayrollComponentInfo.class);
            LA_SalaryEditsService.PayrollComponentItemInfo[] payrollComponentItemList =
                    (LA_SalaryEditsService.PayrollComponentItemInfo[]) JSON.deserialize(jsonPayrollComponentItemList, LA_SalaryEditsService.PayrollComponentItemInfo[].class);
            LA_SalaryEditsService.AttachmentsInfo[] attachmentsList =
                    (LA_SalaryEditsService.AttachmentsInfo[]) JSON.deserialize(jsonFileList, LA_SalaryEditsService.AttachmentsInfo[].class);

            helper.generateReimbursementForContractors(projectId, payrollComponentList, payrollComponentItemList, attachmentsList);

            response.success = true;
        }
        catch (Exception exc) {
            response.setError(Util.trackException(true, exc, LA_SalaryEditsController.class));
        }

        return response;
    }

    /**
     * @description Wrapper for sending a response to a Lightning component
     */
    public class LightningResponse extends Model.LightningResponse {

        /* For success response with JSON data  */
        public void setResult(String data) {
            this.data = data;
            this.success = true;
        }

        /* For error response - set message */
        public void setError(String message) {
            this.message = message;
            this.success = false;
        }

        /* For error response - set code */
        public LightningResponse setError(Integer code) {
            this.code = code;
            this.success = false;
            return this;
        }
    }
}