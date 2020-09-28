/**
 * Created by MaxymMirona on 30.06.2020.
 */

public without sharing class ApproverAssignerSettingsDAO extends CustomMetadataDAO {

    private static final String APPROVER_MANAGER_FIELD = 'Approver_Manager__c';
    private enum LOCATION_SOURCE {RECORD, USER}
    private enum APPROVER_TYPE {ROLE, USER, MANAGER}
    private static final Map<LOCATION_SOURCE, String> LOCATION_SOURCE_PICKLIST = new Map<LOCATION_SOURCE, String>{
            LOCATION_SOURCE.RECORD => 'Record',
            LOCATION_SOURCE.USER => 'User'
    };
    private static final Map<APPROVER_TYPE, String> APPROVER_TYPE_PICKLIST = new Map<APPROVER_TYPE, String>{
            APPROVER_TYPE.ROLE => 'Role',
            APPROVER_TYPE.USER => 'User',
            APPROVER_TYPE.MANAGER => 'Manager'
    };

    public override List<SObject> fetchMetadataSettings() {
        List<String> userNames = new List<String>();
        Map<String, String> userIdByUserName = new Map<String, String>();
        List<Approval_Assigner_Settings__mdt> approvalAssignerSettings = [
                SELECT Id, Resource_type_field__c, Station_Field__c, Department_Field__c, Approver_Field__c, Approver_Process_API_Name__c, Location_Source__c,
                (SELECT Id, Resource_type__c, Station__c, Approver_Type__c, Department__c, Role__c, User_Id__c  FROM Approval_Assigner_Settings_Details__r)
                FROM Approval_Assigner_Settings__mdt
                WHERE Approval_Identifier__c = :this.identifier
        ];
        for (Approval_Assigner_Settings__mdt setting: approvalAssignerSettings){
            for (Approval_Assigner_Settings_Details__mdt detail: setting.Approval_Assigner_Settings_Details__r){
                if (String.isNotEmpty(detail.User_Id__c)
                    && detail.User_Id__c.containsIgnoreCase('@')) {
                    userNames.add(detail.User_Id__c);
                }
            }
        }
        if (!userNames.isEmpty()) {
            List<User> users = [SELECT Id, Username FROM User WHERE Username IN :userNames];
            for (User elem: users){
                userIdByUserName.put(elem.Username, elem.Id);
            }
        }
        for (Approval_Assigner_Settings__mdt setting: approvalAssignerSettings){
            for (Approval_Assigner_Settings_Details__mdt detail: setting.Approval_Assigner_Settings_Details__r){
                if (String.isNotEmpty(detail.User_Id__c)
                        && detail.User_Id__c.containsIgnoreCase('@')
                        && userIdByUserName.containsKey(detail.User_Id__c)) {
                   detail.User_Id__c = userIdByUserName.get(detail.User_Id__c);
                }
            }
        }
        return approvalAssignerSettings;
    }

    public override ICustomMetadataDAOWrapper getWrapperBySettings(SObject settings, List<SObject> targetRecords) {
        return new ApproverAssignerSettingsWrapper(settings, targetRecords);
    }

    public override ICustomMetadataDAOWrapper getWrapperBySettings(SObject settings) {
        return new ApproverAssignerSettingsWrapper(settings);
    }

    public class ApproverAssignerSettingsWrapper implements ICustomMetadataDAOWrapper {
        private String stationField;
        private String departmentField;
        private String resourceTypeField;
        private String approverField;
        private String approvalProcessAPIName;
        private List<SObject> targetRecords;
        private List<SObject> targetRecordsWithAdditionalFields;

        private Id approverId;
        private Map<SObject, Id> approverIdBySObject;
        private String errorMessage;

        public ApproverAssignerSettingsWrapper(String errorMessage) {
            this.errorMessage = errorMessage;
        }

        public ApproverAssignerSettingsWrapper(SObject metadataSettings, List<SObject> targetRecords) {
            Approval_Assigner_Settings__mdt settings = (Approval_Assigner_Settings__mdt)metadataSettings;
            this.stationField = settings.Station_Field__c;
            this.departmentField = settings.Department_Field__c;
            this.resourceTypeField = settings.Resource_type_field__c;
            this.approverField = settings.Approver_Field__c;
            this.approvalProcessAPIName = settings.Approver_Process_API_Name__c;
            this.targetRecords = getSObjectsWithAdditionalFields(targetRecords);

            if (!settings.Approval_Assigner_Settings_Details__r.isEmpty()) {
                try {
                    if (settings.Location_Source__c == LOCATION_SOURCE_PICKLIST.get(LOCATION_SOURCE.RECORD)) {

                        this.handleRecordSource(settings);
                    }
                } catch (Exception e) {
                    if (e.getTypeName() == System.DmlException.class.toString()) {
                        this.errorMessage = ((System.DmlException)e).getDmlMessage(0);
                    } else {
                        this.errorMessage = e.getMessage();
                    }
                }
            }
        }

        public ApproverAssignerSettingsWrapper(SObject metadataSettings) {
            Approval_Assigner_Settings__mdt settings = (Approval_Assigner_Settings__mdt)metadataSettings;
            this.stationField = settings.Station_Field__c;
            this.departmentField = settings.Department_Field__c;
            this.resourceTypeField = settings.Resource_type_field__c;
            this.approverField = settings.Approver_Field__c;
            this.approvalProcessAPIName = settings.Approver_Process_API_Name__c;

            if (!settings.Approval_Assigner_Settings_Details__r.isEmpty()) {
                try {
                    if (settings.Location_Source__c == LOCATION_SOURCE_PICKLIST.get(LOCATION_SOURCE.USER)) {
                        this.handleUserSource(settings);
                    }
                } catch (Exception e) {
                    if (e.getTypeName() == System.DmlException.class.toString()) {
                        this.errorMessage = ((System.DmlException)e).getDmlMessage(0);
                    } else {
                        this.errorMessage = e.getMessage();
                    }
                }
            }
        }

        private List<SObject> getSObjectsWithAdditionalFields(List<SObject> targetRecords) {
            Schema.SObjectType targetRecordSObjectType = targetRecords[0].getSObjectType();
            String query = 'SELECT Id ';
            query += this.departmentField == null ? '' : ',' + this.departmentField;
            query += this.stationField == null ? '' : ',' + this.stationField;
            query += this.resourceTypeField == null ? '' : ',' + this.resourceTypeField;
            query += targetRecordSObjectType == Schema.Allocation__c.getSObjectType() ? ', Project__r.Project_Manager__r.ManagerId' : '';

            query += ' FROM ' + targetRecordSObjectType.getDescribe().getName();
            query += ' WHERE Id IN :targetRecords';

            return Database.query(query);
        }

        public Map<SObject, Id> getApproverIdBySObject() {
            return this.approverIdBySObject;
        }

        public Id getApproverId() {
            return this.approverId;
        }

        public String getStationField() {
            return this.stationField;
        }

        public String getDepartmentField() {
            return this.departmentField;
        }

        public String getApproverField() {
            return this.approverField;
        }

        public String getApprovalProcessAPIName() {
            return this.approvalProcessAPIName;
        }

        public String getErrorMessage() {
            return this.errorMessage;
        }

        public List<SObject> getRecords() {
            return this.targetRecords;
        }

        public void updateRecords() {
            if (this.approverIdBySObject != null) {
                for (SObject record : this.approverIdBySObject.keySet()) {
                    Id approverId = this.approverIdBySObject.get(record);

                    record.put(APPROVER_MANAGER_FIELD, approverId);
                }

                update new List<SObject>(approverIdBySObject.keySet());
            }
        }

        private void handleUserSource(Approval_Assigner_Settings__mdt approverAssignerSetting) {
            User UserInfo = [SELECT Employee_AccountId__c, ManagerId FROM User WHERE Id = :UserInfo.getUserId()  LIMIT 1];
            Account account = [SELECT Id, Contractor__r.Station__c, Contractor__r.Department__c FROM Account WHERE Id = :UserInfo.Employee_AccountId__c LIMIT 1];
            String contractorInfoCompositeString = account.Contractor__r.Station__c + account.Contractor__r.Department__c;

            User[] usersRoles = [SELECT Id, UserRole.Name FROM User LIMIT 2500];
            Map<String, Id> usersRoleStrings = new Map<String, Id>();

            for(User role: usersRoles) {
                usersRoleStrings.put(role.UserRole.Name, role.Id);
            }

            for (Approval_Assigner_Settings_Details__mdt details : approverAssignerSetting.Approval_Assigner_Settings_Details__r) {
                String detailCompositeString = details.Station__c + details.Department__c;

                if(detailCompositeString == contractorInfoCompositeString ) {
                    if(details.Approver_Type__c == APPROVER_TYPE_PICKLIST.get(APPROVER_TYPE.USER)) {
                        this.approverId = details.User_Id__c;
                    } else if(details.Approver_Type__c == APPROVER_TYPE_PICKLIST.get(APPROVER_TYPE.ROLE)) {
                        this.approverId = usersRoleStrings.get(details.Role__c);
                    } else if(details.Approver_Type__c == APPROVER_TYPE_PICKLIST.get(APPROVER_TYPE.MANAGER)) {
                        this.approverId = UserInfo.ManagerId;
                    }
                }
            }
        }

        private void handleRecordSource(Approval_Assigner_Settings__mdt approverAssignerSetting) {
            Map<String, Approval_Assigner_Settings_Details__mdt> approvalAssignerSettingsDetailsByCompositeStrings = new Map<String, Approval_Assigner_Settings_Details__mdt>();
            Map<SObject, String> roleNameBySObject = new Map<SObject, String>();
            Map<SObject, String> userIdBySObject = new Map<SObject, String>();
            Map<SObject, Id> ownerIdBySObject = new Map<SObject, String>();
            this.approverIdBySObject = new Map<SObject, Id>();

            for (Approval_Assigner_Settings_Details__mdt details : approverAssignerSetting.Approval_Assigner_Settings_Details__r) {
                if (details.Station__c != null) {
                    String detailCompositeString = details.Station__c;

                    if (details.Department__c != null) {
                        detailCompositeString += details.Department__c;
                    }

                    if (details.Resource_type__c != null) {
                        detailCompositeString += details.Resource_type__c;
                    }

                    approvalAssignerSettingsDetailsByCompositeStrings.put(detailCompositeString, details);
                }
            }

            for (SObject record : this.targetRecords) {

                Approval_Assigner_Settings_Details__mdt correspondingDetail;
                if (this.stationField != null) {
                    String station = String.valueOf(record.get(this.stationField));
                    String department = this.departmentField == null ? '' : String.valueOf(record.get(this.departmentField));
                    String resourceType = this.resourceTypeField == null ? '' : String.valueOf(record.get(this.resourceTypeField));
                    String recordCompositeStringPriority4 = station;
                    String recordCompositeStringPriority3 = station + department;
                    String recordCompositeStringPriority2 = station + resourceType;
                    String recordCompositeStringPriority1 = station + department + resourceType;

                        if (approvalAssignerSettingsDetailsByCompositeStrings.containsKey(recordCompositeStringPriority1)) {
                            correspondingDetail = approvalAssignerSettingsDetailsByCompositeStrings.get(recordCompositeStringPriority1);
                        } else if (approvalAssignerSettingsDetailsByCompositeStrings.containsKey(recordCompositeStringPriority2)) {
                            correspondingDetail = approvalAssignerSettingsDetailsByCompositeStrings.get(recordCompositeStringPriority2);
                        } else if (approvalAssignerSettingsDetailsByCompositeStrings.containsKey(recordCompositeStringPriority3)) {
                            correspondingDetail = approvalAssignerSettingsDetailsByCompositeStrings.get(recordCompositeStringPriority3);
                        } else if (approvalAssignerSettingsDetailsByCompositeStrings.containsKey(recordCompositeStringPriority4)) {
                            correspondingDetail = approvalAssignerSettingsDetailsByCompositeStrings.get(recordCompositeStringPriority4);
                        }

                        if (correspondingDetail != null) {

                            if (correspondingDetail.Approver_Type__c == APPROVER_TYPE_PICKLIST.get(APPROVER_TYPE.USER)) {
                                userIdBySObject.put(record, correspondingDetail.User_Id__c);
                            } else if (correspondingDetail.Approver_Type__c == APPROVER_TYPE_PICKLIST.get(APPROVER_TYPE.ROLE)) {
                                roleNameBySObject.put(record, correspondingDetail.Role__c);
                            } else if (correspondingDetail.Approver_Type__c == APPROVER_TYPE_PICKLIST.get(APPROVER_TYPE.MANAGER)) {
                                ownerIdBySObject.put(record, Id.valueOf(String.valueOf(record.get('OwnerId'))));
                            }
                        }
                    }

                if (correspondingDetail == null) {
                    if (record.getSObject('Project__r') != null) {
                        if (record.getSObject('Project__r').getSObject('Project_Manager__r') != null) {
                            if (record.getSObject('Project__r').getSObject('Project_Manager__r').get('ManagerId') != null) {
                                this.approverIdBySObject.put(record, Id.valueOf(String.valueOf(record.getSObject('Project__r').getSObject('Project_Manager__r').get('ManagerId'))));
                            }
                        }
                    }
                }
            }

            if (!userIdBySObject.isEmpty()) {
                this.assignUserIdByUserName(userIdBySObject);
            }

            if (!roleNameBySObject.isEmpty()) {
                this.assignUserIdByRoleName(roleNameBySObject);
            }

            if (!ownerIdBySObject.isEmpty()) {
                this.assignUserIdByOwnerId(ownerIdBySObject);
            }
        }

        private void assignUserIdByUserName(Map<SObject, String> userIdBySObject) {

            for (SObject record : userIdBySObject.keySet()) {
                this.approverIdBySObject.put(record, userIdBySObject.get(record));
            }
        }

        private void assignUserIdByRoleName(Map<SObject, String> roleNameBySObject) {
            Map<String, Id> userIdByRoleName = new Map<String, Id>();

            for (User user : [SELECT Id, UserRole.DeveloperName FROM User WHERE UserRoleId IN (SELECT Id FROM UserRole WHERE DeveloperName IN :roleNameBySObject.values())]) {
                userIdByRoleName.put(user.UserRole.DeveloperName, user.Id);
            }

            for (SObject record : roleNameBySObject.keySet()) {
                this.approverIdBySObject.put(record, userIdByRoleName.get(roleNameBySObject.get(record)));
            }
        }

        private void assignUserIdByOwnerId(Map<SObject, Id> ownerManagerBySObject) {
            Map<Id, Id> userManagerIdByOwnerId = new Map<Id, Id>();

            for (User user : [SELECT Id, ManagerId FROM User WHERE Id IN :ownerManagerBySObject.values()]) {
                userManagerIdByOwnerId.put(user.Id, user.ManagerId);
            }

            for (SObject record : ownerManagerBySObject.keySet()) {
                this.approverIdBySObject.put(record, userManagerIdByOwnerId.get(ownerManagerBySObject.get(record)));
            }
        }
    }
}