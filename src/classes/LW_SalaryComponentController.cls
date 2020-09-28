/**
 * Created by Ponomarov Vladyslav on 10.06.2020.
 */

public without sharing class LW_SalaryComponentController {
    public static AccountSelector ACCOUNT_SELECTOR = new AccountSelector();
    public static AllocationSelector ALLOCATION_SELECTOR = new AllocationSelector();
    public static MonthlyReportSelector REPORT_SELECTOR = new MonthlyReportSelector();
    public static SalaryHistorySelector SALARY_HISTORY_SELECTOR = new SalaryHistorySelector();


    @AuraEnabled
    public static DataWrapper getValue(Id recordId) {
        if (String.isBlank(recordId)) {
            throw new AuraHandledException('Not valid record Id arrived');

        }

        try {
            return getSalaryForContractorOrHourlyRate(recordId);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());

        }
    }

    public static DataWrapper getSalaryForContractorOrHourlyRate(Id recordId) {
        String objectName = recordId.getSObjectType().getDescribe().getName();
        DataWrapper dataWrapper;
        Decimal hourlyRate;
        Id contractorId;
        Boolean isNBA;
        Id reportId;

        if (objectName == 'Contractor__c') {
            Contractor__c contractor = getContractor(recordId);
            isNBA = contractor.NBA_position__c;
            contractorId = recordId;

            dataWrapper = fillDataWrapperWithAllData(contractor);

        } else if (objectName == 'Monthly_Report__c') {
            reportId = recordId;
            List<Monthly_Report__c> monthlyReport = REPORT_SELECTOR.getWithRateAndContractor(new List<Id>{
                    reportId
            });

            if (!monthlyReport.isEmpty()) {
                Monthly_Report__c report = monthlyReport[0];
                isNBA = report.Contractor__r.NBA_position__c;
                contractorId = report.Contractor__c;
                hourlyRate = report.Hourly_rate__c;

                if (isNBA) {
                    dataWrapper = new DataWrapper(
                            report.Hourly_rate__c
                            , 0.001 // use this value to show 0.00 to user
                            , 0.001 // if use 0.00 then this value will not rendering on page
                            , 0.001
                            , report.Company_monthly_cost__c
                    );

                } else {
                    dataWrapper = new DataWrapper(
                            report.Hourly_rate__c
                            , report.Hourly_cost__c
                            , report.Company_monthly_cost_with_overhead__c
                            , report.Company_monthly_cost_without_overhead__c
                            , report.Company_monthly_cost__c
                    );
                }
            }


        }
        if (String.isBlank(contractorId)) {
            return null;

        }
        if (isInPublicGroup()) {
            System.debug('isInPublicGroup--> ');
            if (isAboveInHierarchy(contractorId)) {
                System.debug('isAboveInHierarchy--> ');
                return dataWrapper;

            }
            if (isCurrentPM(contractorId) && !isNBA) {
                System.debug('isCurrentPM--> ');
                return dataWrapper;

            }
        }
        System.debug('User is not in any rules');
        return null;
    }

    private static Boolean isInPublicGroup() {
        List<GroupMember> groupMembers = [
                SELECT
                        UserorGroupId
                FROM GroupMember
                WHERE Group.Name = :System.Label.Public_group_for_Show_Salary_Hourly_Rate_Component
                AND UserOrGroupId = :UserInfo.getUserId()
        ];
        return groupMembers.size() > 0;
    }

    private static Boolean isAboveInHierarchy(String contractorId) {
        String nextManager;
        List<Id> hierarchy = new List<Id>();
        List<Account> accounts = ACCOUNT_SELECTOR.getActivePersonAccountsWithRelatedUsers(new List<Id>{
                contractorId
        });
        if (isOnlyOnePersonAccountWithRelatedUser(accounts)) {

            User user;
            try {
                user = [
                        SELECT Id
                                , ManagerId
                                , Employee_AccountId__c
                        FROM User
                        WHERE Employee_AccountId__c = :accounts[0].Id
                        LIMIT 1
                ];

            } catch (Exception e) {
                System.debug('Did`t find any user record for this Person account');

            }

            Map<Id, User> allUsers = new Map<Id, User>(new UserSelector().getAllActiveUsersWithPersonAccounts());
            if (user != null && allUsers.containsKey(user.ManagerId)) {
                nextManager = allUsers.get(user.Id).ManagerId;

            }

            while (String.isNotBlank(nextManager)) {
                hierarchy.add(nextManager);
                if (allUsers.containsKey(nextManager) && allUsers.get(nextManager).ManagerId != null) {
                    nextManager = allUsers.get(nextManager).ManagerId;
                } else {
                    nextManager = '';
                }
            }
        }
        System.debug('hierarchy--> ' + hierarchy);
        return hierarchy.contains(UserInfo.getUserId());
    }

    private static Boolean isOnlyOnePersonAccountWithRelatedUser(List<Account> accounts) {
        return accounts.size() == 1
                && !accounts.isEmpty();
    }

    private static Boolean isCurrentPM(String contractorId) {
        Set<Id> usersWithAccess = new Set<Id>();
        List<Allocation__c> allocations = new List<Allocation__c>();
        Map<String, Integer> numberOfMonthByStation = new Map<String, Integer>();
        List<Salary_Visibility_Rules__mdt> rules = [
                SELECT Station__c,
                        Allocation_In_Past_Months__c
                FROM Salary_Visibility_Rules__mdt
                ORDER BY Allocation_In_Past_Months__c DESC
        ];
        for (Salary_Visibility_Rules__mdt visibilityRules : rules) {
            numberOfMonthByStation.put(visibilityRules.Station__c, visibilityRules.Allocation_In_Past_Months__c.intValue());
        }

        if (!rules.isEmpty()) {
            Date beforeNMonth = Date.today().addMonths(-rules[0].Allocation_In_Past_Months__c.intValue());

            allocations = ALLOCATION_SELECTOR.getWithManagerAndApprover(contractorId, beforeNMonth);
            for (Allocation__c allocation : allocations) {
                if (allocation.Project__r.Station__c != null && numberOfMonthByStation.containsKey(allocation.Project__r.Station__c)) {
                    beforeNMonth = Date.today().addMonths(-numberOfMonthByStation.get(allocation.Project__r.Station__c));
                    if (allocation.End_date__c >= beforeNMonth) {
                        usersWithAccess.add(allocation.Project__r.Project_Manager__c);
                        usersWithAccess.add(allocation.Project__r.Invoice_Approver__c);
                    }
                }
            }
        }
        return usersWithAccess.contains(UserInfo.getUserId());
    }

    private static Contractor__c getContractor(String contractorId) {
        return [SELECT NBA_position__c, convertCurrency(Salary__c) FROM Contractor__c WHERE Id = :contractorId];
    }

    public static Map<String, String> getFieldSetFieldsDescribe(String fieldset) {
        Map<String, String> fieldsLabelAndPath = new Map<String, String>();
        Map<String, Schema.FieldSet> fieldSetMap = Schema.getGlobalDescribe().get('Salary_History__c').getDescribe().fieldSets.getMap();
        for (FieldSetMember field : fieldSetMap.get(fieldset).getFields()) {
            fieldsLabelAndPath.put(field.getLabel(), field.getFieldPath());
        }

        return fieldsLabelAndPath;
    }
    public static Map<String, String> getFieldTypesDescribe(List<String> fieldsApiNames) {
        Map<String, String> fieldsLabelsAndType = new Map<String, String>();
        for (String fieldApi : fieldsApiNames) {
            Schema.DisplayType type = Schema.getGlobalDescribe().get('Salary_History__c').getDescribe().fields.getMap().get(fieldApi).getDescribe().getType();
            String label = Schema.getGlobalDescribe().get('Salary_History__c').getDescribe().fields.getMap().get(fieldApi).getDescribe().getLabel();
            fieldsLabelsAndType.put(label, String.valueOf(type));
        }

        return fieldsLabelsAndType;
    }

    public class DataWrapper {
        @AuraEnabled
        public Decimal salary { get; set; }
        @AuraEnabled
        public Decimal hourlyRate { get; set; }
        @AuraEnabled
        public Decimal hourlyCost { get; set; }
        @AuraEnabled
        public Decimal companyCostWithOverhead { get; set; }
        @AuraEnabled
        public Decimal companyCostWithoutOverhead { get; set; }
        @AuraEnabled
        public Decimal companyCost { get; set; }
        @AuraEnabled
        public List<Salary_History__c> recordsList;
        @AuraEnabled
        public Map<String, String> fieldsList;
        @AuraEnabled
        public Map<String, String> fieldsTypes;
        public DataWrapper(
                Decimal hourlyRate
                , Decimal hourlyCost
                , Decimal companyCostWithOverhead
                , Decimal companyCostWithoutOverhead
                , Decimal companyCost
        ) {
            //if the value is 0 or null, LWC does not show it on the user side,
            // so we change it to 0.001 ( ex. template if:true={value.companyCostWithOverhead})
            this.hourlyRate = (hourlyRate == null || hourlyRate == 0)
                    ? 0.001 : hourlyRate;
            this.hourlyCost = (hourlyCost == null || hourlyCost == 0)
                    ? 0.001 : hourlyCost;
            this.companyCostWithOverhead = (companyCostWithOverhead == null || companyCostWithOverhead == 0)
                    ? 0.001 : companyCostWithOverhead ;
            this.companyCostWithoutOverhead = (companyCostWithoutOverhead == null || companyCostWithoutOverhead == 0)
                    ? 0.001 : companyCostWithoutOverhead;
            this.companyCost = (companyCost == null || companyCost == 0)
                    ? 0.001 : companyCost;
        }
        public DataWrapper(Decimal salary) {
            this.salary = salary;
        }
        public DataWrapper(Decimal salary, Map<String, String> fieldsList, Map<String, String> fieldsTypes, List<Salary_History__c> recordsList) {
            this.salary = salary;
            this.fieldsList = fieldsList;
            this.fieldsTypes = fieldsTypes;
            this.recordsList = recordsList;
        }
    }
    private static DataWrapper fillDataWrapperWithAllData(Contractor__c contractor) {
        List<Salary_History__c> recordsList;
        Map<String, String> fieldsList;
        Map<String, String> fieldsTypes;

        fieldsList = getFieldSetFieldsDescribe('for_salary_data_component');
        fieldsTypes = getFieldTypesDescribe(fieldsList.values());
        recordsList = SALARY_HISTORY_SELECTOR.getSalaryHistoryWithFieldSetFields(fieldsList.values(), contractor.Id);
        return new DataWrapper(contractor.Salary__c, fieldsList, fieldsTypes, recordsList);
    }
}