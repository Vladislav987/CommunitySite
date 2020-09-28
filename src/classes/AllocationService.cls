/**
 * Created by MaxymMirona on 17.12.2019.
 */

public without sharing class AllocationService {

    public static final String ALLOCATIONS_RELATED_LIST_FIELDSET_TEMPLATE = 'RelatedListFieldsFor';
    public static final String RESTRICT_DELETION_FOR_NOT_ADMIN_USER_ERROR = 'You cannot delete this Allocation. Please, contact your System Administrator';
    public static final String EMPTY_CONTRACTOR_IN_APPROVAL_PROCESS_ERROR_MESSAGE = 'Contractor field cannot be empty, fill it please';
    public static final String CHANGE_BILLED_AS_FOR_ALLOCATION_WITH_PENDING_OR_APPROVED_BUDGET_TRANSACTION_ERROR =
            'You cannot change Billed as field value, ' +
                    'because this Allocation has related Monthly Reports with Approved or Pending Budget Transactions';
    public static final String CHANGE_ALLOCATION_WITH_BOUNDED_RELATED_ACCRUAL =
            'You cannot change Allocation that has related Monthly Reports with related Accrual binded with Invoice';
    public static final String DUPLICATE_ALLOCATION_OF_SOME_TYPE_FOR_PROJECT =
            'This type of Allocation already exists for this Contractor in this Project with such combination of Resource Type and Rate in this period: {0} to {1}.' +
            ' Please, contact your System Administrator';
    public static final String DUPLICATE_ALLOCATION_OF_SOME_TYPE_IN_SAME_PROJECT =
            'This Project or it\'\'s children contains multiple Allocations of the same Type with the same Contractor with the same combination of Resource Type and Rate in this period: {0} to {1}.' +
                    ' Please, contact your System Administrator';
    public static final String DUPLICATE_ALLOCATIONS_OF_SOME_TYPE_EXIST_IN_PROJECT =
            'This Project or it\'s children Projects contains Allocations of the same Type for the same Contractor. ' +
                    'Please, resolve these Allocations first and then proceed';
    public static final String ALREADY_IN_APPROVAL_PROCESS_ERROR = 'This record is currently in an approval process. A record can be in only one approval' +
            ' process at a time. Please, contact your System Administrator';
    public static final String COMMENTS_FOR_ALLOCATION_CREATED_FROM_COMPONENT = 'This Allocation was created from Allocation & Contractors component.' +
            ' Date created : ' + System.today().format();
    public static final String ALLOCATION_STATUS_FIELD_TOKEN_PATH = 'Status__c';
    public static final String ALLOCATIONS_TYPE_FIELD_TOKEN_PATH = 'Allocation_Type__c';
    public static final String ALLOCATIONS_OVERRUN_TYPE_FIELD_TOKEN_PATH = 'Overrun_Type__c';
    public static final List<String> EXCLUDED_ALLOCATION_TYPES = new List<String>{'Leave'};
    public static final List<String> EXCLUDED_ALLOCATION_STATUSES = new List<String>{'New', 'Pending', 'Rejected', 'Finished'};
    public static final List<String> ALLOWED_DUPLICATE_ALLOCATIONS_TYPES = new List<String>{''};
    public static final List<String> ALLOWED_DUPLICATE_ALLOCATIONS_STATUSES = new List<String>{'Rejected', 'Finished'};
    public static final String NO_APPLICABLE_PROCESS_ERROR = 'There is no applicable Approval process found.';
    public static final String UPDATE_ALLOCATION_RATE_ERROR =
            'You cannot change Allocation\'s Expected Rate, Currency or Billing Type, because it has related Monthly Reports. Please, create new Allocation';
    public static Savepoint savepoint;
    public static final Id NEW_RESOURCE_REQUEST_ALLOCATION_RECORD_TYPE_ID = Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('New_resource_Request').getRecordTypeId();
    public static final Id PARENT_PROJECT_RECORD_TYPE_ID = Schema.Project__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Parent').getRecordTypeId();
    public static final Id BOOKING_REQUEST_ALLOCATION_RECORD_TYPE_ID = Schema.Allocation__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Booking').getRecordTypeId();
    public static final List<Schema.SObjectField> FIELDS_FOR_ALLOCATION_VALIDATION = new List<SObjectField>{
            Schema.Allocation__c.fields.Project__c,
            Schema.Allocation__c.fields.Contractor__c,
            Schema.Allocation__c.fields.Allocation_Type__c,
            Schema.Allocation__c.fields.Expected_Rate__c,
            Schema.Allocation__c.fields.Resource_Type__c
    };

    AllocationSelector allocationSelector = new AllocationSelector();
    ProjectSelector projectSelector = new ProjectSelector();
    ContractorService contractorService = new ContractorService();
    MonthlyReportService monthlyReportServiceObject = new MonthlyReportService();

    public List<String> getStatuses(){
        List<String> allocationStatuses = new List<String>();
        List<Schema.PicklistEntry> statusList = Schema.getGlobalDescribe().get('Allocation__c').getDescribe().fields.getMap().get(ALLOCATION_STATUS_FIELD_TOKEN_PATH).getDescribe().getPicklistValues();

        for (Schema.PicklistEntry status : statusList){
            if (status.isActive()) {
                allocationStatuses.add(status.getValue());
            }
        }

        return allocationStatuses;
    }

    public List<String> getStatusesWithoutExcluded(){
        List<String> allStatuses = getStatuses();

        for (String excludedType : EXCLUDED_ALLOCATION_STATUSES){
            if (allStatuses.contains(excludedType)){
                allStatuses.remove(allStatuses.indexOf(excludedType));
            }
        }

        return allStatuses;
    }

    public List<String> getTypes(){
        List<String> allocationTypes = new List<String>();
        List<Schema.PicklistEntry> typesList = Schema.getGlobalDescribe().get('Allocation__c').getDescribe().fields.getMap().get(ALLOCATIONS_TYPE_FIELD_TOKEN_PATH).getDescribe().getPicklistValues();

        for (Schema.PicklistEntry type : typesList){
            if (type.isActive()) {
                allocationTypes.add(type.getValue());
            }
        }

        return allocationTypes;
    }

    public List<String> getTypesWithoutExcluded(){
        List<String> allTypes = getTypes();

        for (String excludedType : EXCLUDED_ALLOCATION_TYPES){
            if (allTypes.contains(excludedType)){
                allTypes.remove(allTypes.indexOf(excludedType));
            }
        }

        return allTypes;
    }

    public List<String> getOverrunTypes(){
        List<String> OverrunTypes = new List<String>();
        List<Schema.PicklistEntry> statusList = Schema.getGlobalDescribe().get('Allocation__c').getDescribe().fields.getMap().get(ALLOCATIONS_OVERRUN_TYPE_FIELD_TOKEN_PATH).getDescribe().getPicklistValues();

        for (Schema.PicklistEntry status : statusList){
            OverrunTypes.add(status.getValue());
        }

        return OverrunTypes;
    }

    public Map<Id, String> getAllocationRecordTypes(){
        Map<Id, String> allocationRecordTypes = new Map<Id, String>();
        List<RecordTypeInfo> allocationRecordTypesInfo = Schema.getGlobalDescribe().get('Allocation__c').getDescribe().getRecordTypeInfos();

        for (RecordTypeInfo recordType : allocationRecordTypesInfo){
            if (recordType.isAvailable() && !recordType.isMaster() && recordType.isActive()){
                allocationRecordTypes.put(recordType.getRecordTypeId(), recordType.getName());
            }
        }

        return allocationRecordTypes;
    }

    public DataTableWrapper getAllocationsForRelatedList(Id sObjectId){
        String sObjectName = sObjectId.getSobjectType().getDescribe().getName();
        String query = constructQueryForAllocationsRelatedList(sObjectName, sObjectId);

        DataTableWrapper dataTable = new DataTableWrapper();

        dataTable.recordsList = Database.query(query);
        dataTable.fieldsList = getFieldSetFieldsDescribe(ALLOCATIONS_RELATED_LIST_FIELDSET_TEMPLATE + sObjectName.removeEnd('__c'));
        dataTable.fieldsTypes = getFieldTypesDescribe(dataTable.fieldsList.values());
        dataTable.contractorsList = getContractorsOfAllocations(dataTable.recordsList);

        return dataTable;
    }

    public String constructQueryForAllocationsRelatedList(String sObjectName, Id sObjectId){
        String query = 'SELECT id, (SELECT id FROM Monthly_Reports__r), {0} FROM Allocation__c WHERE {1} = :sObjectId';
        List<Object> queryParams = new List<Object>();
        List<String> requiredFields = new List<String>{
                'Contractor__r.Name', 'RecordTypeId', 'RecordType.Name', 'Status__c', 'Allocation_Type__c',
                'Contractor__c', 'Allocation__c', 'Start_date__c', 'End_date__c', 'Overrun_Type__c', 'Project__c'
        };
        List<String> fieldSetFields = getFieldsTokenPathFromFieldSet(sObjectName);

        for (String requiredField : requiredFields){
            if (!fieldSetFields.contains(requiredField)){
                fieldSetFields.add(requiredField);
            }
        }

        queryParams.add(String.join(fieldSetFields, ','));
        queryParams.add(getRelationshipFieldForSObject(sObjectName));

        query = String.format(query, queryParams);

        return query;
    }

    public String getRelationshipFieldForSObject(String sObjectName){
        List<Relationship_mapping_for_Allocations__mdt> settings = [
                SELECT Object_Name__c, Relationship_field_API_name__c
                FROM Relationship_mapping_for_Allocations__mdt
                WHERE Object_Name__c  = :sObjectName.removeEnd('__c')
        ];

        if (settings != null && settings.size() > 0){
            return settings[0].Relationship_field_API_name__c;
        } else {
            throw new AllocationException('There is no mapping for current object. Make sure you provided the correct API name');
        }
    }

    public List<String> getFieldsTokenPathFromFieldSet(String sObjectName){
        List<String> fieldTokenPaths;
        fieldTokenPaths = new List<String>();
        Schema.FieldSet fieldset = Schema.SObjectType.Allocation__c.fieldSets.getMap().get(ALLOCATIONS_RELATED_LIST_FIELDSET_TEMPLATE + sObjectName.removeEnd('__c'));

        if (fieldset == null){
            throw new AllocationException('There is no fieldset for this object. Make sure it\' named in format \'RelatedListFieldsForObjectName\'');
        }

        if (fieldset != null) {
            for (Schema.FieldSetMember field : fieldset.getFields()) {
                fieldTokenPaths.add(field.getFieldPath());
            }
        }

        return fieldTokenPaths;
    }

    public Boolean validateForFilledContractorInApprovalProcess(List<Allocation__c> allocations){
        for (Allocation__c allocation : allocations){
            if (allocation.Approval_process_second_step__c){
                if (allocation.Contractor__c == null){
                    allocation.addError(EMPTY_CONTRACTOR_IN_APPROVAL_PROCESS_ERROR_MESSAGE);

                    return false;
                }

                allocation.Approval_process_second_step__c = false;
            }
        }

        return true;
    }

    public String validateForSingleAllocationOfSomeTypeForParentProject(List<Allocation__c> allocations, Boolean fromProject){
        List<Allocation__c> allocationsWithUnifiedCurrency = allocationSelector.getAllocationsWithUnifiedCurrencyString(allocations);
        Map<Id, String> newAllocationsKeyStringByAllocationIds =
                constructSetOfCompositeStringByFieldsWithoutEmptyFieldsByIds(allocationsWithUnifiedCurrency, FIELDS_FOR_ALLOCATION_VALIDATION);
        Set<Id> allocationProjectIds = new Set<Id>();
        List<Allocation__c> filteredAllocations = new List<Allocation__c>();

        for (Allocation__c allocation : allocations){
            if (!ALLOWED_DUPLICATE_ALLOCATIONS_TYPES.contains(allocation.Allocation_Type__c) && !ALLOWED_DUPLICATE_ALLOCATIONS_STATUSES.contains(allocation.Status__c)){
                filteredAllocations.add(allocation);
            }
        }

        for (Allocation__c allocation : filteredAllocations){
            allocationProjectIds.add(allocation.Project__c);
        }

        List<Project__c> projectsWithRelatedAllocations = projectSelector.getProjectsWithAllUniqueAllocationsByProjectIds(
                new List<Id>(allocationProjectIds),
                filteredAllocations,
                ALLOWED_DUPLICATE_ALLOCATIONS_TYPES,
                ALLOWED_DUPLICATE_ALLOCATIONS_STATUSES
        );

        if (fromProject) {
            return validateForSingleAllocationFromProject(projectsWithRelatedAllocations, filteredAllocations, newAllocationsKeyStringByAllocationIds);
        } else {
            return validateForSingleAllocationFromAllocations(projectsWithRelatedAllocations, filteredAllocations, newAllocationsKeyStringByAllocationIds);
        }
    }

    public String validateForSingleAllocationFromAllocations(List<Project__c> projectsWithRelatedAllocations, List<Allocation__c> filteredAllocations, Map<Id, String> newAllocationsKeyStringByAllocationIds){
        if (!projectsWithRelatedAllocations.isEmpty()) {

            for (Project__c project : projectsWithRelatedAllocations) {
                Map<Id, Allocation__c> existingAllocationsMap = new Map<Id, Allocation__c>(project.Allocations__r);

                Map<String, List<Id>> existingAllocationsIdsByKeyStrings =
                        constructSetOfCompositeStringByFieldsWithoutEmptyFields(existingAllocationsMap.values(), FIELDS_FOR_ALLOCATION_VALIDATION);

                for (Allocation__c newAllocation : filteredAllocations) {
                    String newAllocationCompositeString = newAllocationsKeyStringByAllocationIds.get(newAllocation.Id);

                    if (existingAllocationsIdsByKeyStrings.containsKey(newAllocationCompositeString)) {

                        for (Id existingAllocationId : existingAllocationsIdsByKeyStrings.get(newAllocationCompositeString)) {
                            Allocation__c existingAllocation = existingAllocationsMap.get(existingAllocationId);

                            if (!(newAllocation.Start_date__c > existingAllocation.End_date__c ||
                                    newAllocation.End_date__c < existingAllocation.Start_date__c)) {

                                newAllocation.addError(String.format(
                                        DUPLICATE_ALLOCATION_OF_SOME_TYPE_FOR_PROJECT,
                                        new List<Object>{
                                                existingAllocation.Start_date__c.format(),
                                                existingAllocation.End_date__c.format()
                                        }
                                ));
                                return DUPLICATE_ALLOCATION_OF_SOME_TYPE_FOR_PROJECT;
                            }
                        }
                    }
                }
            }
        }

        return 'Success';
    }

    public String validateForSingleAllocationFromProject(List<Project__c> projectsWithRelatedAllocations, List<Allocation__c> filteredAllocations, Map<Id, String> newAllocationsKeyStringByAllocationIds) {

        if (!projectsWithRelatedAllocations.isEmpty()) {

            for (Project__c project : projectsWithRelatedAllocations) {
                for (Allocation__c newAllocation : filteredAllocations) {
                    for (Allocation__c nestedNewAllocation : filteredAllocations) {
                        if (nestedNewAllocation != newAllocation) {
                            if (
                                newAllocationsKeyStringByAllocationIds.get(newAllocation.Id) == newAllocationsKeyStringByAllocationIds.get(nestedNewAllocation.Id) &&
                                newAllocationsKeyStringByAllocationIds.get(nestedNewAllocation.Id) != null
                                ) {
                                if (!(nestedNewAllocation.Start_date__c > newAllocation.End_date__c ||
                                        nestedNewAllocation.End_date__c < newAllocation.Start_date__c)) {
                                    return String.format(
                                            DUPLICATE_ALLOCATION_OF_SOME_TYPE_IN_SAME_PROJECT,
                                            new List<Object>{
                                                    newAllocation.Start_date__c.format(),
                                                    newAllocation.End_date__c.format()
                                            }
                                    );
                                }
                            }
                        }
                    }
                }
            }
        }

        return 'Success';
    }

    public static String addConvertCurrencyFieldsToSOQL(List<Schema.sObjectField> currencyFields, String query) {

        for (Schema.sObjectField currencyField : currencyFields){
            if (currencyField.getDescribe().getType() == Schema.DisplayType.CURRENCY){
                String currencyFieldName = currencyField.getDescribe().getName();

                if (query.indexOf(',' + currencyFieldName) != -1){
                    query = query.replace(',' + currencyFieldName, ',convertCurrency(' + currencyFieldName + ')');
                } else if (query.indexOf(currencyFieldName + ',') != -1){
                    query = query.replace(currencyFieldName + ',', ',convertCurrency(' + currencyFieldName + ')');
                }
            }
        }

        return query;
    }

    public void fillAllocationFields(List<Allocation__c> allocations) {
        fillDepartmentPField(allocations);
    }

    public void fillDepartmentPField(List<Allocation__c> allocations) {

        for (Allocation__c allocation : allocations) {
            if (allocation.Department__c != null) {
                allocation.DepartmentP__c = allocation.Department__c;
            }
        }
    }
    private Map<String, List<Id>> filterAllocationsForValidationByEmptyFieldsByString(Map<Id, Map<String, Boolean>> allocationsHaveEmptyFieldsCompositeStringsByAllocationIds){
        Map<String, List<Id>> allocationsCompositeStringsByAllocationIds = new Map<String, List<Id>>();

        for (Id allocationId : allocationsHaveEmptyFieldsCompositeStringsByAllocationIds.keySet()){
            Boolean haveEmptyFields = allocationsHaveEmptyFieldsCompositeStringsByAllocationIds.get(allocationId).values()[0];
            String compositeString = new List<String>(allocationsHaveEmptyFieldsCompositeStringsByAllocationIds.get(allocationId).keySet())[0];

            if (!haveEmptyFields){
                if (allocationsCompositeStringsByAllocationIds.containsKey(compositeString)){
                    allocationsCompositeStringsByAllocationIds.get(compositeString).add(allocationId);
                } else {
                    allocationsCompositeStringsByAllocationIds.put(compositeString, new List<Id>{allocationId});
                }
            }
        }

        return allocationsCompositeStringsByAllocationIds;
    }

    public static Map<Id, String> filterRecordsCompositeStringsByEmptyFieldsByIds(Map<Id, Map<String, Boolean>> recordsHaveEmptyFieldsCompositeStringsByAllocationIds){
        Map<Id, String> recordsCompositeStringsByAllocationIds = new Map<Id, String>();

        for (Id recordId : recordsHaveEmptyFieldsCompositeStringsByAllocationIds.keySet()){
            Boolean haveEmptyFields = recordsHaveEmptyFieldsCompositeStringsByAllocationIds.get(recordId).values()[0];
            String compositeString = new List<String>(recordsHaveEmptyFieldsCompositeStringsByAllocationIds.get(recordId).keySet())[0];

            if (!haveEmptyFields){
                recordsCompositeStringsByAllocationIds.put(recordId, compositeString);
            }
        }

        return recordsCompositeStringsByAllocationIds;
    }

    /**

    * Method is used to construct Composite Strings of records by provided field's values.
    *
    * @param sObjects - List of SObjects
    * @param fields - List of Schema.SObjectField that represents set of fields that form uniqueness of the SObject
    *
    * @return Map<Id, Map<String, Boolean>> - Map of Composite Strings to Boolean value,
    * which shows if Composite String has empty fields by SObject Ids
    */
    public static Map<Id, Map<String, Boolean>> constructSetOfCompositeStringByFields(List<SObject> sObjects, List<Schema.SObjectField> fields) {
        Map<Id, Map<String, Boolean>> sObjectCompositeStrings = new Map<Id, Map<String, Boolean>>();

        if (!sObjects.isEmpty()) {
            Map<String, Boolean> fieldsAPINames = new Map<String, Boolean>();

            for (Schema.SObjectField field : fields) {
                String fieldsAPIName = field.getDescribe().getName();
                Boolean isPercent = field.getDescribe().getType() == Schema.DisplayType.PERCENT;

                try {
                    sObjects[0].get(fieldsAPIName);
                    fieldsAPINames.put(fieldsAPIName, isPercent);
                } catch (Exception e){
                    throw new AllocationException(fieldsAPIName + ' field can\'t be processed. Maybe you didn\'t query it');
                }
            }

            for (SObject sObj : sObjects) {
                String allocationCompositeString = '';
                Boolean haveEmptyField = false;

                for (String fieldsAPIName : fieldsAPINames.keySet()) {
                    if (sObj.get(fieldsAPIName) != null) {
                        Object fieldValue = sObj.get(fieldsAPIName);

                        if (fieldsAPINames.get(fieldsAPIName)){
                            fieldValue = Integer.valueOf(fieldValue).format();
                        }

                        allocationCompositeString += fieldValue;
                    } else {
                        haveEmptyField = true;
                    }
                }

                sObjectCompositeStrings.put(sObj.Id, new Map<String, Boolean>{
                        allocationCompositeString => haveEmptyField
                });
            }
        }

        return sObjectCompositeStrings;
    }

    public Map<String, List<Id>> constructSetOfCompositeStringByFieldsWithoutEmptyFields(List<SObject> sObjects, List<Schema.SObjectField> fields){
        return filterAllocationsForValidationByEmptyFieldsByString(constructSetOfCompositeStringByFields(sObjects, fields));
    }

    public Map<Id, String> constructSetOfCompositeStringByFieldsWithoutEmptyFieldsByIds(List<SObject> sObjects, List<Schema.SObjectField> fields){
        return filterRecordsCompositeStringsByEmptyFieldsByIds(constructSetOfCompositeStringByFields(sObjects, fields));
    }

    public Boolean validateForSingleAllocationOfSomeTypeForProject(List<Allocation__c> allocations){
        List<Allocation__c> allocationsToValidate = new List<Allocation__c>();
        Map<Id, Allocation__c> allocationsWithProjectRecordTypeId = new Map<Id, Allocation__c>(
                allocationSelector.getSameAllocationsWithAdditionalFields(allocations)
        );

        for (Allocation__c allocation : allocations){

            if (
                    allocationsWithProjectRecordTypeId.get(allocation.Id).Project__r.RecordTypeId == PARENT_PROJECT_RECORD_TYPE_ID ||
                    allocationsWithProjectRecordTypeId.get(allocation.Id).Project__r.Parent_Project__r.RecordTypeId == PARENT_PROJECT_RECORD_TYPE_ID
               ){
                if (!ALLOWED_DUPLICATE_ALLOCATIONS_STATUSES.contains(allocation.Status__c) && !ALLOWED_DUPLICATE_ALLOCATIONS_TYPES.contains(allocation.Allocation_Type__c)) {
                    allocationsToValidate.add(allocation);
                }
            }
        }

        if (!allocationsToValidate.isEmpty()){
            return validateForSingleAllocationOfSomeTypeForParentProject(allocationsToValidate, false) == 'Success';
        }

        return true;
    }

    public void sortNeededRecords(List<Allocation__c> newAllocations, Map<Id, Allocation__c> oldAllocationsByIds){
        List<Allocation__c> sortedAllocations = new List<Allocation__c>();
        for (Allocation__c allocation: newAllocations){
            if (areNeededFieldsChanged(allocation, oldAllocationsByIds)) {
                    sortedAllocations.add(allocation);
                    sortedAllocations.add(oldAllocationsByIds.get(allocation.Id));
            }
        }

        this.sortAllocationForRollUp(sortedAllocations);
    }

    public void sortAllocationForRollUp(List<Allocation__c> allocations) {
        Set<Id> contractorsIds = new Set<Id>();
        Date inTwoWeek = Date.today().addDays(14);

        for (Allocation__c allocation: allocations){
            if ((allocation.Start_date__c  <= inTwoWeek && allocation.End_date__c >= inTwoWeek)
                    || (allocation.Start_date__c <= Date.today() && allocation.End_date__c >= Date.today())
                    && (allocation.Status__c != 'Rejected' || allocation.Status__c != 'Finished')) {
                contractorsIds.add(allocation.Contractor__c);
            }
        }
        contractorService.recalculateAllocationFields(contractorsIds);
//        System.enqueueJob(new ContractorRollUpServiceQueue(contractorsIds));
    }

    private Map<Id, Map<String, Map<Id, Allocation__c>>> constructMapOfUniqueAllocations(List<Allocation__c> allocations){
        Map<Id, Map<String, Map<Id, Allocation__c>>> allocationsByAllocationsTypeByContractorIdMapByProjectIds = new Map<Id, Map<String, Map<Id, Allocation__c>>>();

        for (Allocation__c allocation : allocations){
            if (!ALLOWED_DUPLICATE_ALLOCATIONS_TYPES.contains(allocation.Allocation_Type__c) && !ALLOWED_DUPLICATE_ALLOCATIONS_STATUSES.contains(allocation.Status__c)) {
                if (allocationsByAllocationsTypeByContractorIdMapByProjectIds.containsKey(allocation.Project__c)) {
                    Map<String, Map<Id, Allocation__c>> allocationsByContractorIdByType = allocationsByAllocationsTypeByContractorIdMapByProjectIds.get(allocation.Project__c);

                    if (allocationsByContractorIdByType.containsKey(allocation.Allocation_Type__c)) {
                        Map<Id, Allocation__c> allocationsByContractorIds = allocationsByContractorIdByType.get(allocation.Allocation_Type__c);

                        if (allocationsByContractorIds.containsKey(allocation.Contractor__c)) {
                            Trigger.new[0].addError(DUPLICATE_ALLOCATIONS_OF_SOME_TYPE_EXIST_IN_PROJECT);
                        } else {
                            if (allocation.Contractor__c != null) {
                                allocationsByAllocationsTypeByContractorIdMapByProjectIds.get(allocation.Project__c).get(allocation.Allocation_Type__c).put(allocation.Contractor__c, allocation);
                            }
                        }
                    } else {
                        if (allocation.Allocation_Type__c != null && allocation.Contractor__c != null) {
                            Map<Id, Allocation__c> allocationsByAllocationContractorId = new Map<Id, Allocation__c>();

                            allocationsByAllocationContractorId.put(allocation.Contractor__c, allocation);

                            allocationsByContractorIdByType.put(allocation.Allocation_Type__c, allocationsByAllocationContractorId);
                        }
                    }
                } else {
                    if (allocation.Allocation_Type__c != null && allocation.Contractor__c != null && allocation.Project__c != null) {
                        Map<String, Map<Id, Allocation__c>> allocationsByAllocationsType = new Map<String, Map<Id, Allocation__c>>();
                        Map<Id, Allocation__c> allocationsByAllocationContractor = new Map<Id, Allocation__c>();

                        allocationsByAllocationContractor.put(allocation.Contractor__c, allocation);
                        allocationsByAllocationsType.put(allocation.Allocation_Type__c, allocationsByAllocationContractor);

                        allocationsByAllocationsTypeByContractorIdMapByProjectIds.put(allocation.Project__c, allocationsByAllocationsType);
                    }
                }
            }
        }

        return allocationsByAllocationsTypeByContractorIdMapByProjectIds;
    }

    public void checkAllocationsForPossibilityToDelete(List<Allocation__c> allocations){
        Id systemAdministratorProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        Boolean isCurrentUserSystemAdministrator = systemAdministratorProfileId == UserInfo.getProfileId() ? true : false;

        if (!isCurrentUserSystemAdministrator){

            for (Allocation__c allocation : allocations){

                if (
                        (allocation.Allocation__c == 0 && allocation.Allocation_Type__c == 'Leave') ||
                        (allocation.Allocation__c == 0 && allocation.Allocation_Type__c == 'Overrun') ||
                        (allocation.Status__c == 'New' && allocation.Contractor__c == null && allocation.CreatedDate.isSameDay(System.today()))
                   ){
                    continue;
                } else {
                    allocation.addError(RESTRICT_DELETION_FOR_NOT_ADMIN_USER_ERROR);
                }
            }
        }

    }

    public Boolean validateForSingleAllocationOfSomeTypeForProject(Map<Id, Allocation__c> allocationsOldMap, List<Allocation__c> allocationsNew){
        List<Allocation__c> allocationsToValidate = new List<Allocation__c>();

        for (Allocation__c newAllocation : allocationsNew){
            Allocation__c oldAllocation = allocationsOldMap.get(newAllocation.Id);
            if (
                oldAllocation.Allocation_Type__c != newAllocation.Allocation_Type__c ||
                oldAllocation.Contractor__c != newAllocation.Contractor__c ||
                oldAllocation.Project__c != newAllocation.Project__c ||
                oldAllocation.Resource_Type__c != newAllocation.Resource_Type__c ||
                oldAllocation.Expected_Rate__c != newAllocation.Expected_Rate__c ||
                oldAllocation.Start_date__c != newAllocation.Start_date__c ||
                oldAllocation.End_date__c != newAllocation.End_date__c ||
                oldAllocation.CurrencyIsoCode != newAllocation.CurrencyIsoCode ||
                oldAllocation.Status__c != newAllocation.Status__c
            ){
                allocationsToValidate.add(newAllocation);
            }
        }

        if (!allocationsToValidate.isEmpty()){
            return validateForSingleAllocationOfSomeTypeForProject(allocationsToValidate);
        }

        return true;
    }

    public Boolean validateForChangeAllocationExpectedRate(Map<Id, Allocation__c> oldAllocations, List<Allocation__c> newAllocations){
        Map<Id, Allocation__c> allocationsMap = new Map<Id, Allocation__c>(newAllocations);

        for (Allocation__c allocation : [SELECT Expected_Rate__c, Billing_type__c, CurrencyIsoCode, (SELECT Id FROM Monthly_reports__r) FROM Allocation__c WHERE Id IN :newAllocations]){
            Allocation__c oldAllocation = oldAllocations.get(allocation.Id);

            if (
                    (
                        (oldAllocation.Expected_Rate__c != null && allocation.Expected_Rate__c != null && oldAllocation.Expected_Rate__c.setScale(2) != allocation.Expected_Rate__c.setScale(2)) ||
                        oldAllocation.Billing_type__c != allocation.Billing_type__c ||
                        oldAllocation.CurrencyIsoCode != allocation.CurrencyIsoCode
                    ) &&
                    !allocation.Monthly_Reports__r.isEmpty()
                ){
                allocationsMap.get(allocation.Id).addError(UPDATE_ALLOCATION_RATE_ERROR);

                return false;
            }
        }

        return true;
    }

    public Boolean validateForChangeSOW(Map<Id, Allocation__c> oldAllocations, List<Allocation__c> newAllocations){



        return true;
    }

    public Boolean validateForChangeBilledAs(Map<Id, Allocation__c> oldAllocations, List<Allocation__c> newAllocations){

        for (Allocation__c allocation : newAllocations) {
            if (oldAllocations.get(allocation.Id).Billed_as__c != allocation.Billed_as__c){
                if (doAllocationsHavePendingOrApprovedBudgetTransactions(newAllocations)) {
                    newAllocations[0].addError(CHANGE_BILLED_AS_FOR_ALLOCATION_WITH_PENDING_OR_APPROVED_BUDGET_TRANSACTION_ERROR);

                    return false;
                }
            }
        }

        return true;
    }

    public Boolean validateForChangeAllocationWithRelatedBindedAccrual(Map<Id, Allocation__c> oldAllocations, List<Allocation__c> newAllocations) {
        List<Allocation__c> changedAllocations = new List<Allocation__c>();

        for (Allocation__c newAllocation : newAllocations) {
            Allocation__c oldAllocation = oldAllocations.get(newAllocation.Id);

            if (
                    oldAllocation.Expected_Rate_Monthly__c != newAllocation.Expected_Rate_Monthly__c ||
                    oldAllocation.Expected_Rate_Daily__c != newAllocation.Expected_Rate_Daily__c ||
                    oldAllocation.Expected_Rate__c != newAllocation.Expected_Rate__c ||
                    oldAllocation.Billed_as__c != newAllocation.Billed_as__c ||
                    oldAllocation.CurrencyIsoCode != newAllocation.CurrencyIsoCode ||
                    oldAllocation.Billing_type__c != newAllocation.Billing_type__c
                ) {
                changedAllocations.add(newAllocation);
            }
        }

        for (Allocation__c allocation : [SELECT (SELECT Id, Budget_transaction_item__r.Budget_transaction_item__c FROM Monthly_Reports__r) FROM Allocation__c WHERE Id IN : changedAllocations]) {
            for (Monthly_Report__c relatedReport : allocation.Monthly_Reports__r) {
                if (relatedReport.Budget_transaction_item__r.Budget_transaction_item__c != null) {
                    newAllocations[0].addError(CHANGE_ALLOCATION_WITH_BOUNDED_RELATED_ACCRUAL);

                    return false;
                }
            }
        }

        return true;
    }

    public Boolean validateAllocations(Map<Id, Allocation__c> oldAllocations, List<Allocation__c> newAllocations){
        Boolean passedValidation = validateForSingleAllocationOfSomeTypeForProject(oldAllocations, newAllocations);
        passedValidation = passedValidation && validateForChangeAllocationExpectedRate(oldAllocations, newAllocations);
        passedValidation = passedValidation && validateForChangeBilledAs(oldAllocations, newAllocations);
        passedValidation = passedValidation && validateForChangeSOW(oldAllocations, newAllocations);
        passedValidation = passedValidation && validateForChangeAllocationWithRelatedBindedAccrual(oldAllocations, newAllocations);

        return passedValidation;
    }

    public Boolean doAllocationsHavePendingOrApprovedBudgetTransactions(List<Allocation__c> newAllocations) {
        Set<Id> relatedMonthlyReportsIds = new Set<Id>();

        for (Allocation__c allocation : [SELECT Billed_as__c, (SELECT Id FROM Monthly_Reports__r) FROM Allocation__c WHERE Id IN :newAllocations]){
            for (Monthly_Report__c report : allocation.Monthly_Reports__r){
                relatedMonthlyReportsIds.add(report.Id);
            }
        }

        List<Monthly_Report__c> reportsWithBudgetTransactions = [SELECT Budget_Transaction_item__c, Budget_Transaction_item__r.Budget_Transaction__c, (SELECT Id, Budget_transaction__c FROM Budget_Transaction_items__r) FROM Monthly_Report__c WHERE Id IN :relatedMonthlyReportsIds];

        return monthlyReportServiceObject.doMonthlyReportsHavePendingOrApprovedBudgetTransactions(reportsWithBudgetTransactions);
    }

    public MatrixAllocationAndContractorsData getChildAndParentProjectsWithAllocationsByParentProjectId(Id parentProjectId){
        MatrixAllocationAndContractorsData matrixData = new MatrixAllocationAndContractorsData();
        List<Allocation__c> childAndParentAllocations = new List<Allocation__c>();
        Project__c parentProjectWithAllocations = projectSelector.getProjectWithAllocations(parentProjectId, ALLOWED_DUPLICATE_ALLOCATIONS_STATUSES);
        List<Project__c> childProjectsWithAllocations = projectSelector.getChildProjectsWithAllocationsByParentProject(parentProjectId, ALLOWED_DUPLICATE_ALLOCATIONS_STATUSES);

        childProjectsWithAllocations.add(parentProjectWithAllocations);
        matrixData.parentProject = parentProjectWithAllocations;
        matrixData.childProjectsList = childProjectsWithAllocations;

        matrixData.allocationsByProjectIds = new Map<Id, List<Allocation__c>>();
        matrixData.allocationsByProjectIds.put(parentProjectWithAllocations.Id, parentProjectWithAllocations.Allocations__r);
        childAndParentAllocations.addAll(parentProjectWithAllocations.Allocations__r);

        for (Project__c project : childProjectsWithAllocations){
            childAndParentAllocations.addAll(project.Allocations__r);
            matrixData.allocationsByProjectIds.put(project.Id, project.Allocations__r);
        }

        matrixData.contractorsIdToNameOfAllAllocations = getUniqueContractorsForAllocations(childAndParentAllocations);

        return matrixData;
    }

    public Map<Id, String> getUniqueContractorsForAllocations(List<Allocation__c> allocations){
        Map<Id, String> contractorsIdToName = new Map<Id, String>();

        for (Allocation__c allocation : allocations){
            if (!contractorsIdToName.containsKey(allocation.Contractor__c)){
                contractorsIdToName.put(allocation.Contractor__c, allocation.Contractor__r.Name);
            }
        }

        return contractorsIdToName;
    }

    public List<Contractor__c> getContractorsOfAllocations(List<Allocation__c> allocations){
        Set<Contractor__c> contractorsOfAllocations = new Set<Contractor__c>();

        for (Allocation__c allocation : allocations){
            Contractor__c contractor = new Contractor__c(
                    Id = allocation.Contractor__c == null ? null : allocation.Contractor__c,
                    Name = allocation.Contractor__r.Name
            );

            contractorsOfAllocations.add(contractor);
        }

        List<Contractor__c> contractorsOfAllocationsList = new List<Contractor__c>(contractorsOfAllocations);

        contractorsOfAllocationsList.sort();

        return contractorsOfAllocationsList;
    }

    public String insertNullableAllocation(Id projectId, Allocation__c allocation, String allocationType, String overrunType){
        if (allocationType == 'leave'){
            if (allocationSelector.getAllocationsByProjectAndTypeAndContractor(projectId, allocation.Contractor__c, 'Leave', ALLOWED_DUPLICATE_ALLOCATIONS_STATUSES).size() > 0){
                return 'You already have Active \'Leave\' Allocation for this Contractor';
            }
        }

        Allocation__c nullableAllocation = new Allocation__c(
                RecordTypeId = allocation.RecordTypeId,
                Project__c = projectId,
                Contractor__c = allocation.Contractor__c,
                Allocation__c = 0,
                Allocation_Type__c = allocationType,
                Overrun_Type__c = String.isEmpty(overrunType) ? null : overrunType,
                Start_date__c = allocation.Start_date__c,
                End_date__c = allocation.End_date__c,
                Status__c = 'Active'
        );

        Database.SaveResult result;

        try {
            result = Database.insert(nullableAllocation);
        } catch (Exception e){
            return processAllocationsException(e);
        }

        return result.isSuccess() ? 'Success' : result.getErrors()[0].getMessage();
    }

    public String upsertAllocationsBaseOnAnotherRandomAllocation(List<Allocation__c> allocations, Boolean approveRequired) {
        allocations = constructAllocationBaseOnAnotherRandomAllocation(allocations, approveRequired);

        savepoint = Database.setSavepoint();

        setAllocationSkipValidation(allocations, true, false);

        List<Database.UpsertResult> upsertResults = Database.upsert(allocations, false);

        String errorMessage = processAllocationsUpsertResults(upsertResults, allocations);

        if (String.isEmpty(errorMessage)) {
            setAllocationSkipValidation(allocations, false, true);
        }

        return errorMessage;
    }

    //Method to manually skip Allocations validation
    private void setAllocationSkipValidation(List<Allocation__c> allocations, Boolean skipValidation, Boolean withUpdate){
        for (Allocation__c allocation : allocations){
            allocation.Skip_Validation__c = skipValidation;
        }

        if (withUpdate) {
            SObjectDomain.isEnabled = false;
            update allocations;
            SObjectDomain.isEnabled = true;
        }
    }

    public List<Allocation__c> constructAllocationBaseOnAnotherRandomAllocation(List<Allocation__c> allocations, Boolean approveRequired){

        for (Allocation__c allocation : allocations) {
            if (allocation.Id == null){
                allocation.RecordTypeId = approveRequired ? NEW_RESOURCE_REQUEST_ALLOCATION_RECORD_TYPE_ID : allocation.RecordTypeId;
                allocation.Status__c = approveRequired ? 'New' : allocation.Status__c;
                allocation.Comments__c = COMMENTS_FOR_ALLOCATION_CREATED_FROM_COMPONENT;
            } else {
                if (approveRequired){
                    allocation.Comments__c = 'Allocation was sent for Approve from Allocations & Contractor\'s component';
                } else {
                    allocation.Comments__c = allocation.Comments__c == null ? '.' : allocation.Comments__c + '.';
                }
            }
        }

        return allocations;
    }

    public String approveAllocations(List<Allocation__c> allocations){

        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();

        for (Allocation__c allocation : allocations) {
            if (allocation.Id != null) {
                Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                request.setObjectId(allocation.Id);
                requests.add(request);
            }
        }

        try {
            Approval.process(requests);
            return '';
        } catch (Exception e) {
            Database.rollback(savepoint);
            return processAllocationsException(e);
        }
    }

    public List<Allocation__c> parseAllocations(List<Object> allocations){
        return (List<Allocation__c>)JSON.deserialize(JSON.serialize(allocations), List<Allocation__c>.class);
    }

    public void transferAllocations(Id sowId, Id opportunityId, List<Allocation__c> selectedAllocations, Boolean isRejectUnselected){
        List<Allocation__c> updatedAllocations = new List<Allocation__c>();
        Sow__c sow = [SELECT Id, Project__c, Project__r.Project_Manager__c FROM SOW__c WHERE Id = :sowId];
        if (isRejectUnselected) {
            List<Allocation__c> unselectedAllocations = allocationSelector.getByOpportunityIdAndNotIncludedAllocations(opportunityId, new Map<Id, Allocation__c>(selectedAllocations).keySet());
            for (Allocation__c allocation: unselectedAllocations){
                allocation.Status__c = 'Rejected';
            }
            updatedAllocations.addAll(unselectedAllocations);
        }
        for (Allocation__c allocation: selectedAllocations){
            allocation.RecordTypeId = NEW_RESOURCE_REQUEST_ALLOCATION_RECORD_TYPE_ID;
            allocation.Status__c = 'New';
            allocation.OwnerId = sow.Project__r.Project_Manager__c;
            allocation.Project__c = sow.Project__c;
            allocation.Opportunity__c = null;
            allocation.Is_Opportunity__c = false;
            allocation.SOW__c = sow.Id;
        }
        updatedAllocations.addAll(selectedAllocations);
        update updatedAllocations;
    }

    public DataTableWrapper getDataForMassTransfer(Id opportunityId){
        DataTableWrapper data = new DataTableWrapper();
        String query = constructQuery('MassTransfer', opportunityId);
        List<Opportunity> opportunities = Database.query(query);
        List<String> validSowStatuses = new List<String>{'Signed','Draft'};
        List<SOW__c> sowsWithValidStatus = new List<SOW__c>();
        List<SOW__c> sowsWithValidDate = new List<SOW__c>();
        List<SOW__c> validSows = new List<SOW__c>();

        if (!opportunities[0].SOW__r.isEmpty()) {
            for (SOW__c sow : opportunities[0].SOW__r) {
                if (validSowStatuses.contains(sow.Status__c)) {
                    sowsWithValidStatus.add(sow);
                }
            }

            if (sowsWithValidStatus.isEmpty()) {
                data.sowErrorMessage = 'You don\'t have Draft or Signed SOW. Please, review you current SOW(s) or create a new one.';
            } else {
                for (SOW__c sow : sowsWithValidStatus) {
                    if (sow.End_Date__c >= System.today()) {
                        sowsWithValidDate.add(sow);
                    }
                }

                if (sowsWithValidDate.isEmpty()) {
                    data.sowErrorMessage = 'SOW(s) are expired or their dates are not defined. Please, review you current SOW(s) or create a new one.';
                } else {
                    for (SOW__c sow : sowsWithValidDate) {
                        if (sow.Project__c != null) {
                            validSows.add(sow);
                        }
                    }

                    if (validSows.isEmpty()) {
                        data.sowErrorMessage = 'You have SOWs without assigned Project';
                    }
                }
            }
        } else {
            data.sowErrorMessage = 'There is no SOW found. Please, create Draft or Signed SOW with valid dates for continue.'; //WHERE Status__c IN (\'Signed\', \'Draft\') AND End_Date__c >= TODAY),
        }

        data.sows = validSows.isEmpty() ? new List<SOW__c>() : validSows;
        data.fieldsList = getFieldSetFieldsDescribe('MassTransfer');
        data.fieldsTypes = getFieldTypesDescribe(data.fieldsList.values());
        data.recordsList  = opportunities[0].Allocations__r;

        return data;
    }

    public String constructQuery(String fieldSetName, Id opportunityId){
        List<String> requiredFields = new List<String>{
                'Contractor__r.Name', 'RecordTypeId', 'RecordType.Name', 'Status__c', 'Allocation_Type__c',
                'Contractor__c', 'Allocation__c', 'Start_date__c', 'End_date__c', 'Overrun_Type__c', 'Project__c'
        };

        List<String> fieldSetFields = new List<String>();
        Schema.FieldSet fieldset = Schema.SObjectType.Allocation__c.fieldSets.getMap().get(fieldSetName);

        if (fieldset == null){
            throw new AllocationException('There is no fieldset for this object. Make sure it\' named  \'MassTransfer\'');
        }

        if (fieldset != null) {
            for (Schema.FieldSetMember field : fieldset.getFields()) {
                fieldSetFields.add(field.getFieldPath());
            }
        }

        for (String requiredField : requiredFields){
            if (!fieldSetFields.contains(requiredField)){
                fieldSetFields.add(requiredField);
            }
        }

        String allocationSubquery = String.join(fieldSetFields, ',');
        String query = 'SELECT Id, Name, ' +
                '(SELECT Id, Project__r.Name, Project__c, Status__c, End_Date__c FROM SOW__r), ' +
                '(SELECT Id, '+allocationSubquery + ' FROM Allocations__r WHERE RecordTypeId =\'' + BOOKING_REQUEST_ALLOCATION_RECORD_TYPE_ID + '\' AND Status__c =\'New\' ) ' +
                'FROM Opportunity WHERE Id =\'' + opportunityId +'\'';

        return query;
    }

    public String processAllocationsUpsertResults(List<Database.UpsertResult> upsertResults, List<Allocation__c> allocations){
        String errorMessage = '';

        for (Integer i = 0; i < allocations.size(); i++) {
            Database.UpsertResult upsertResult = upsertResults[i];
            Allocation__c actualRecord = allocations[i];

            if (!upsertResult.isSuccess()) {
                errorMessage += 'Allocation with Id \'' + actualRecord.Id + '\' has following errors: ';

                for (Database.Error error : upsertResult.getErrors()) {
                    if (error.getStatusCode() == StatusCode.REQUIRED_FIELD_MISSING) {
                        errorMessage += 'Random Project Allocation missing such fields: ';

                        for (String field : error.getFields()) {
                            errorMessage += field + ', ';
                        }

                        errorMessage = errorMessage.removeEnd(', ');
                    } else if (error.getStatusCode() == StatusCode.INSUFFICIENT_ACCESS_OR_READONLY){
                        errorMessage += 'You don\'t have enough permissions to edit the record';
                    } else {
                        errorMessage += error.getMessage() + ', ';
                    }
                }

                errorMessage = errorMessage.removeEnd(', ') + '\n';
            }
        }

        if (!String.isEmpty(errorMessage)){
            Database.rollback(savepoint);
        }

        return errorMessage;
    }

    public String processAllocationsException(Exception e){
        String errorMessage = '';

        if (e.getTypeName() == System.DmlException.class.getName()) {
            e = (DmlException)e;

            if (e.getDmlType(0) == StatusCode.NO_APPLICABLE_PROCESS) {
                errorMessage = NO_APPLICABLE_PROCESS_ERROR;
            } else if (e.getDmlType(0) == StatusCode.ALREADY_IN_PROCESS) {
                errorMessage = ALREADY_IN_APPROVAL_PROCESS_ERROR;
            } else if (e.getDmlType(0) == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
                errorMessage = e.getDmlMessage(0);
            } else if (e.getDmlType(0) == StatusCode.INSUFFICIENT_ACCESS_OR_READONLY) {
                errorMessage = 'You don\'t have enough permissions to edit the record';
            } else {
                errorMessage = e.getMessage();
            }
        } else {
            errorMessage = e.getMessage();
        }

        return errorMessage;
    }

    public Map<String, String> getFieldSetFieldsDescribe(String fieldset){
        Map<String, String> fieldsLabelAndPath = new Map<String, String>();
        Map<String, Schema.FieldSet> fieldSetMap = Schema.getGlobalDescribe().get('Allocation__c').getDescribe().fieldSets.getMap();
        for (FieldSetMember field : fieldSetMap.get(fieldset).getFields()) {
            if (field.getFieldPath().contains('.')) {
                String fieldLabel = getLabelOfFieldWithParentRelationship(field.getFieldPath());
                fieldsLabelAndPath.put(fieldLabel, field.getFieldPath());
            }
            else {
                fieldsLabelAndPath.put(field.getLabel(), field.getFieldPath());
            }
        }

        return fieldsLabelAndPath;
    }
    private Boolean areNeededFieldsChanged(Allocation__c allocation, Map<Id, Allocation__c> oldAllocationsByIds) {
        return allocation.Allocation__c != oldAllocationsByIds.get(allocation.Id).Allocation__c
                || allocation.Status__c != oldAllocationsByIds.get(allocation.Id).Status__c
                || allocation.Start_date__c != oldAllocationsByIds.get(allocation.Id).Start_date__c
                || allocation.End_date__c != oldAllocationsByIds.get(allocation.Id).End_date__c
                || allocation.Allocation_Type__c != oldAllocationsByIds.get(allocation.Id).Allocation_Type__c
                || allocation.Project__c != oldAllocationsByIds.get(allocation.Id).Project__c
                || allocation.Contractor__c != oldAllocationsByIds.get(allocation.Id).Contractor__c;
    }


    public Map<String, String> getFieldTypesDescribe(List<String> fieldsApiNames){
        Map<String, String> fieldsLabelsAndType = new Map<String, String>();
        for (String fieldApi : fieldsApiNames) {
            if (fieldApi.contains('.')) {
                String fieldLabel = getLabelOfFieldWithParentRelationship(fieldApi);
                fieldsLabelsAndType.put(fieldLabel, String.valueOf(Schema.DisplayType.REFERENCE));
                continue;
            }

            Schema.DisplayType type = Schema.getGlobalDescribe().get('Allocation__c').getDescribe().fields.getMap().get(fieldApi).getDescribe().getType();
            String label = Schema.getGlobalDescribe().get('Allocation__c').getDescribe().fields.getMap().get(fieldApi).getDescribe().getLabel();
            fieldsLabelsAndType.put(label, String.valueOf(type));
        }

        return fieldsLabelsAndType;
    }

    private String getLabelOfFieldWithParentRelationship(String fieldPath){
        String fieldAPIName = fieldPath.substringAfterLast('.');          //customobject__r.customobject2__r.Name ----> Name
        fieldPath = fieldPath.removeEnd('.' + fieldAPIName);              //customobject__r.customobject2__r.Name ----> Customobject__r.customobject2__r
        String objectTokenPath;                                           //SObject token used in SOQL
        String objectAPIName;                                             //SObject API Name
        String objectLabel;                                               //SObject Label
        String fieldLabel;                                                //Returning field label

        if (fieldPath.contains('.')) {
            objectTokenPath = fieldPath.substringAfterLast('.');          //customobject__r.customobject2__r ----> customobject2__r
        } else {
            objectTokenPath = fieldPath;
        }

        if (objectTokenPath.contains('__r')){
            objectTokenPath = objectTokenPath.removeEnd('r') + 'c';        //customobject2__r ----> customobject2__c
        }

        if (objectTokenPath.equalsIgnoreCase('LastModifiedBy') || objectTokenPath.equalsIgnoreCase('CreatedBy')){
            objectAPIName = Schema.getGlobalDescribe().get('User').getDescribe().getName();                             //if we fetch through standard lookup parent field, i.e 'CreatedBy',
            objectLabel = Schema.getGlobalDescribe().get('User').getDescribe().getLabel();                              //which is originally User lookup
        } else {
            objectAPIName = Schema.getGlobalDescribe().get(objectTokenPath).getDescribe().getName();
            objectLabel = Schema.getGlobalDescribe().get(objectTokenPath).getDescribe().getLabel();
        }

        fieldLabel = Schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap().get(fieldAPIName).getDescribe().getLabel();
        if (!fieldLabel.contains(objectLabel)){
            fieldLabel = objectLabel + ' ' + fieldLabel;                                                                //If we retreive field without object label in it's own label
        }                                                                                                               //Example got 'Name' from Customobj__c and change to 'Customobj Name'
        if (objectTokenPath.equalsIgnoreCase('LastModifiedBy') || objectTokenPath.equalsIgnoreCase('CreatedBy')){
            fieldLabel = objectTokenPath + fieldLabel;                                                                  //If we retreive field without Standard object label in it's own label
        }                                                                                                               //Example got 'First Name' from CreatedBy and change to 'CreatedBy First Name'
        return fieldLabel;
    }

    public class DataTableWrapper {
        @AuraEnabled
        public List<Allocation__c> recordsList;
        @AuraEnabled
        public List<Contractor__c> contractorsList;
        @AuraEnabled
        public Map<String, String> fieldsList;
        @AuraEnabled
        public Map<String, String> fieldsTypes;
        @AuraEnabled
        public List<Project__c> projects;
        @AuraEnabled
        public List<SOW__c> sows;
        @AuraEnabled
        public String sowErrorMessage;
    }

    public class MatrixAllocationAndContractorsData {
        @AuraEnabled
        public List<Project__c> childProjectsList;
        @AuraEnabled
        public Project__c parentProject;
        @AuraEnabled
        public Map<Id, List<Allocation__c>> allocationsByProjectIds;
        @AuraEnabled
        public Map<Id, String> contractorsIdToNameOfAllAllocations;
    }

    public class AllocationException extends Exception{}
    
    public class MassTransferForAllocationsFromOpportunityData{
        @AuraEnabled
        public List<Project__c> projects;
        @AuraEnabled
        public List<Allocation__c> allocations;
        @AuraEnabled
        public Map<String, String> fieldNamesByLabel;
    }

}