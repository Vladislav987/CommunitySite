public without sharing class LW_PayrollModificationController {

    private static Payroll_Component_Configuration_Field__mdt[] configFieldList;

    @TestVisible
    private static final String RECURRENT = 'Recurrent';
    @TestVisible
    private static final String NON_RECURRENT = 'Non recurrent';
    private static final String NAME = 'Name';
    private static final String CREATED_BY = 'Created by';
    private static final String STATUS = 'Status';
    @TestVisible
    private static final String DEACTIVATED = 'Deactivated';
    private static final String CURRENCY_VALUE = 'Currency';
    private static final String START_DATE = 'start date';
    private static final String END_DATE = 'end date';
    private static final String DETAILS = 'Detail';
    private static final String ERROR_MESSAGE = 'Sorry, something went wrong. Please contact your administrator.';

    @AuraEnabled
    public static Map<String, PayslipContainerWrapper> getPayrollComponents(
        Payroll_Component_Configurations__mdt payRollCmpConfig,
        Payroll_Component_Configuration_Field__mdt[] payRollCmpConfigFieldList
    ) {
        Map<String, PayslipContainerWrapper> payslipContainerWrappersByType = new Map<String, PayslipContainerWrapper>();
        configFieldList = payRollCmpConfigFieldList;

        try {
            composeColumns(payslipContainerWrappersByType);
            Set<Id> pcOwnerIdSet = getPcOwnerIds(payRollCmpConfig.Additional_Available_Stations__c);

            for (Payroll_Component__c payrollComponent : getFilteredPayrollComponents(payRollCmpConfig.RecordType__c, pcOwnerIdSet)) {
                composeData(payrollComponent, payslipContainerWrappersByType);
            }

            if (payRollCmpConfig.RecordType_recurrent__c != null) {

                for (Payroll_Component__c payrollComponent : getFilteredPayrollComponents(payRollCmpConfig.RecordType_recurrent__c, pcOwnerIdSet)) {
                    composeData(payrollComponent, payslipContainerWrappersByType);
                }
            }

            return payslipContainerWrappersByType;
        }
        catch (Exception ex) {
            return getErrorWrapper(ex, payslipContainerWrappersByType);
        }
    }

    private static Set<Id> getPcOwnerIds(String additionalStations) {
        Set<Id> pcOwnerIdSet = new Set<Id>{UserInfo.getUserId()};
        Util_ContractorHierarchy.ContractorHierarchyInfo contractorHierarchyInfo
            = Util_ContractorHierarchy.getInfo().updateSubordinatesByUserIdAndAdditionalStations(UserInfo.getUserId(), additionalStations);

        pcOwnerIdSet.addAll(contractorHierarchyInfo.subordinateUserIdSet);

        return pcOwnerIdSet;
    }

    private static Map<String, PayslipContainerWrapper> composeData(Payroll_Component__c payrollComponent, Map<String, PayslipContainerWrapper> payslipContainerWrappersByType) {
        PayslipWrapper payslipWrapper = new PayslipWrapper();

        payslipWrapper.Id = payrollComponent.Id;
        payslipWrapper.Sum = payrollComponent.Sum__c;
        payslipWrapper.currencyIsoCode = payrollComponent.CurrencyIsoCode;
        payslipWrapper.reason = payrollComponent.Reason__c;
        payslipWrapper.startDate = payrollComponent.StartDate__c;
        payslipWrapper.sumType = payrollComponent.SumType__c;
        payslipWrapper.status = payrollComponent.Approval_Status__c;
        payslipWrapper.insurance = payrollComponent.Insurance__c;
        payslipWrapper.name = payrollComponent.Contractor__r.Name;
        payslipWrapper.isPayrollEmpty = payrollComponent.Payroll__c == null;
        payslipWrapper.createdByName = payrollComponent.CreatedBy.Name;
        payslipWrapper.isDeactivated = payrollComponent.Approval_Status__c == DEACTIVATED;

        if (payrollComponent.Recurrent__c) {
            payslipWrapper.endDate = payrollComponent.EndDate__c;
            addPayslipWrapper(payslipContainerWrappersByType, payslipWrapper, RECURRENT);
        }
        else {
            addPayslipWrapper(payslipContainerWrappersByType, payslipWrapper, NON_RECURRENT);
        }

        return payslipContainerWrappersByType;
    }

    private static Map<String, PayslipContainerWrapper> composeColumns(Map<String, PayslipContainerWrapper> payslipContainerWrappersByType) {
        payslipContainerWrappersByType.put(NON_RECURRENT, fillPayslipColumnsWrapperNonRecurrent());
        payslipContainerWrappersByType.put(RECURRENT, fillPayslipColumnsWrapperRecurrent());

        return payslipContainerWrappersByType;
    }

    private static PayslipContainerWrapper fillPayslipColumnsWrapperRecurrent() {
        PayslipContainerWrapper payslipContainerWrapperForRecurrent = new PayslipContainerWrapper();

        PayslipColumnsWrapper payslipColumnsWrapper = new PayslipColumnsWrapper(NAME, true);
        payslipContainerWrapperForRecurrent.payslipColumnsWrappers.add(payslipColumnsWrapper);

        for (ConfigFieldInfo configFieldInfo : getPayrollComponentConfigurationFieldsForRecurrent()) {

            if (configFieldInfo.field.Title__c == CURRENCY_VALUE) continue;

            payslipContainerWrapperForRecurrent.payslipColumnsWrappers.add(fillPayslipColumnsWrapperField(configFieldInfo.field));
        }

        payslipContainerWrapperForRecurrent.payslipColumnsWrappers.add(new PayslipColumnsWrapper(STATUS));
        payslipContainerWrapperForRecurrent.payslipColumnsWrappers.add(new PayslipColumnsWrapper(CREATED_BY));
        payslipContainerWrapperForRecurrent.payslipColumnsWrappers.add(new PayslipColumnsWrapper(DETAILS));

        return payslipContainerWrapperForRecurrent;
    }

    private static PayslipContainerWrapper fillPayslipColumnsWrapperNonRecurrent() {
        PayslipContainerWrapper payslipContainerWrapperForNonRecurrent = new PayslipContainerWrapper();

        PayslipColumnsWrapper payslipColumnsWrapper = new PayslipColumnsWrapper(NAME, true);
        payslipContainerWrapperForNonRecurrent.payslipColumnsWrappers.add(payslipColumnsWrapper);

        for (ConfigFieldInfo configFieldInfo : getPayrollComponentConfigurationFieldsForNonRecurrent()) {

            if (configFieldInfo.field.Title__c == CURRENCY_VALUE) continue;

            payslipContainerWrapperForNonRecurrent.payslipColumnsWrappers.add(fillPayslipColumnsWrapperField(configFieldInfo.field));
        }

        payslipContainerWrapperForNonRecurrent.payslipColumnsWrappers.add(new PayslipColumnsWrapper(CREATED_BY));
        payslipContainerWrapperForNonRecurrent.payslipColumnsWrappers.add(new PayslipColumnsWrapper(DETAILS));

        return payslipContainerWrapperForNonRecurrent;
    }

    private static PayslipColumnsWrapper fillPayslipColumnsWrapperField(Payroll_Component_Configuration_Field__mdt componentConfigurationField) {
        PayslipColumnsWrapper payslipColumnsWrapperField = new PayslipColumnsWrapper(componentConfigurationField.Title__c);

        if (componentConfigurationField.Title__c.contains(START_DATE) || componentConfigurationField.Title__c.contains(END_DATE)) {
            payslipColumnsWrapperField.isSortable = true;
        }

        if (componentConfigurationField.Title__c.contains(START_DATE)) {
            payslipColumnsWrapperField.isAsc = true;
        }

        return payslipColumnsWrapperField;
    }

    private static Map<String, PayslipContainerWrapper> getErrorWrapper(Exception ex, Map<String, PayslipContainerWrapper> payslipContainerWrappersByType) {
        PayslipContainerWrapper payslipContainerWrapper = new PayslipContainerWrapper();

        payslipContainerWrapper.error = ex.getMessage() + ' ' + ex.getStackTraceString();
        payslipContainerWrapper.errorMessage = ERROR_MESSAGE;

        payslipContainerWrappersByType.put('400', payslipContainerWrapper);

        return payslipContainerWrappersByType;
    }

    @AuraEnabled
    public static void deletePayrollComponents(List<Id> payrollComponentsIds) {
        delete getPayrollComponentsByIds(payrollComponentsIds);
    }

    @AuraEnabled
    public static void deactivatePayrollComponents(List<Id> payrollComponentsIds) {
        List<Payroll_Component__c> payrollComponents = getPayrollComponentsByIdsToUpdate(payrollComponentsIds);

        for (Payroll_Component__c payrollComponent : payrollComponents) {
            payrollComponent.Approval_Status__c = DEACTIVATED;
        }

        update payrollComponents;
    }

    private static Map<String, PayslipContainerWrapper> addPayslipWrapper(Map<String, PayslipContainerWrapper> payslipContainerWrappersByType, PayslipWrapper payslipWrapper, String type) {

        if (payslipContainerWrappersByType.get(type).payslipWrappers == null) {
            PayslipContainerWrapper payslipContainerWrapper = payslipContainerWrappersByType.get(type);
            payslipContainerWrapper.payslipWrappers = new List<PayslipWrapper>{payslipWrapper};

            payslipContainerWrappersByType.put(type, payslipContainerWrapper);
        }
        else {
            PayslipContainerWrapper payslipContainerWrapper = payslipContainerWrappersByType.get(type);
            payslipContainerWrapper.payslipWrappers.add(payslipWrapper);

            payslipContainerWrappersByType.put(type, payslipContainerWrapper);
        }

        return payslipContainerWrappersByType;
    }

    private static List<Payroll_Component__c> getFilteredPayrollComponents(String recordType, Set<Id> subordinateUserIdSet) {

        return [
            SELECT
                Id
                , Sum__c
                , CurrencyIsoCode
                , Reason__c
                , StartDate__c
                , EndDate__c
                , Recurrent__c
                , SumType__c
                , Approval_Status__c
                , Payroll__c
                , CreatedBy.Name
                , Insurance__c
                , Contractor__r.Name
            FROM Payroll_Component__c
            WHERE Project__c = NULL
            AND StartDate__c = THIS_MONTH
            AND OwnerId IN :subordinateUserIdSet
            AND RecordTypeId = :Schema.SObjectType.Payroll_Component__c.getRecordTypeInfosByDeveloperName().get(recordType).getRecordTypeId()
            ORDER BY StartDate__c ASC
        ];
    }

    private static List<Payroll_Component__c> getPayrollComponentsByIds(List<Id> payrollComponentsIds) {

        return [
            SELECT
                Id
            FROM Payroll_Component__c
            WHERE Id IN :payrollComponentsIds
        ];
    }

    private static List<Payroll_Component__c> getPayrollComponentsByIdsToUpdate(List<Id> Ids) {

        return [
            SELECT
                Approval_Status__c
            FROM Payroll_Component__c
            WHERE Id IN :Ids
            FOR UPDATE
        ];
    }

    private static ConfigFieldInfo[] getPayrollComponentConfigurationFieldsForNonRecurrent() {
        ConfigFieldInfo[] configFieldInfoList = new ConfigFieldInfo[]{};

        for (Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField : configFieldList) {

            if (
                payrollComponentConfigurationField.Recurrent_Only__c == false
                && payrollComponentConfigurationField.Is_Hidden__c == false
            ) {
                ConfigFieldInfo configFieldInfo = new ConfigFieldInfo(payrollComponentConfigurationField);

                configFieldInfoList.add(configFieldInfo);
            }
        }

        configFieldInfoList.sort();
        return configFieldInfoList;
    }

    private static ConfigFieldInfo[] getPayrollComponentConfigurationFieldsForRecurrent() {
        ConfigFieldInfo[] configFieldInfoList = new ConfigFieldInfo[]{};

        for (Payroll_Component_Configuration_Field__mdt payrollComponentConfigurationField : configFieldList) {

            if (payrollComponentConfigurationField.Is_Hidden__c == false ) {
                ConfigFieldInfo configFieldInfo = new ConfigFieldInfo(payrollComponentConfigurationField);

                configFieldInfoList.add(configFieldInfo);
            }
        }

        configFieldInfoList.sort();
        return configFieldInfoList;
    }

    @TestVisible
    class PayslipContainerWrapper {

        @AuraEnabled public List<PayslipWrapper> payslipWrappers;
        @AuraEnabled public List<PayslipColumnsWrapper> payslipColumnsWrappers = new List<PayslipColumnsWrapper>();
        @AuraEnabled public String error;
        @AuraEnabled public String errorMessage;
    }

    class PayslipWrapper {

        @AuraEnabled public Id Id;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal Sum;
        @AuraEnabled public String currencyIsoCode;
        @AuraEnabled public String reason;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public String sumType;
        @AuraEnabled public String status;
        @AuraEnabled public Boolean isPayrollEmpty;
        @AuraEnabled public Boolean isDeactivated;
        @AuraEnabled public String createdByName;
        @AuraEnabled public String insurance;
    }

    class PayslipColumnsWrapper {

        @AuraEnabled public String name;
        @AuraEnabled public Boolean isSortable;
        @AuraEnabled public Boolean isAsc = false;

        PayslipColumnsWrapper(String name) {
            this.name = name;
        }

        PayslipColumnsWrapper(String name, Boolean isSortable) {
            this.name = name;
            this.isSortable = isSortable;
        }
    }

    class ConfigFieldInfo implements Comparable {
        Payroll_Component_Configuration_Field__mdt field;

        public ConfigFieldInfo(Payroll_Component_Configuration_Field__mdt field) {
            this.field = field;
        }

        public Integer compareTo(Object objToCompare) {

            if (field.Order__c == null && ((ConfigFieldInfo)objToCompare).field.Order__c != null) {
                return -1;
            }
            else if (field.Order__c != null && ((ConfigFieldInfo)objToCompare).field.Order__c == null) {
                return 1;
            }
            else if (field.Order__c > ((ConfigFieldInfo)objToCompare).field.Order__c) {
                return 1;
            }
            else if (field.Order__c < ((ConfigFieldInfo)objToCompare).field.Order__c) {
                return -1;
            }

            return 0;
        }
    }
}