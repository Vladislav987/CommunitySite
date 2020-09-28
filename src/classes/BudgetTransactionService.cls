/**
 * Created by MaxymMirona on 12.03.2020.
 */

public without sharing class BudgetTransactionService {
    public static final Id INVOICE_BUDGET_TRANSACTION_RECORD_TYPE_ID = Schema.Budget_transaction__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Invoice').getRecordTypeId();
    public static final String NOT_UNIQUE_SOW_ERROR = 'To create Accrual Budget Transaction, you must select Monthly Reports with the same SOW';
    public static final String DIFFERENT_SOWS_FOR_INVOICE_AND_ACCRUALS = 'Accrual\'s and Invoice\'s should have the same SOWs';
    public static final String FIXED_COST_PROJECT_NULL_SOW_ERROR = 'Fixed Cost Projects cannot have Allocations without associated SOW';
    public static final String NOT_THE_SAME_SOW_ERROR = 'Selected Monthly Reports must have the same SOW as selected Budget Transactions';
    public static final String INVALID_STATUS_FOR_PROJECT_MANAGER_ERROR = 'Picklist values available are "Draft" and "On Customer Approval"';
    public static final Map<String, Id> BUDGET_TRANSACTION_ACCRUAL_RECORDTYPE_IDS = new Map<String, Id>{
            'Accrual FixCost' => Schema.Budget_Transaction__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Accrual_FixCost').getRecordTypeId(),
            'Accrual TnM' => Schema.Budget_Transaction__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Accrual_TnM').getRecordTypeId()
    };
    public static final Id BUDGET_TRANSACTION_INVOICE_RECORDTYPE_ID = Schema.Budget_Transaction__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Invoice').getRecordTypeId();

    public MonthlyReportSelector monthlyReportSelectorObject = new MonthlyReportSelector();
    public ProjectSelector projectSelectorObject = new ProjectSelector();
    public BudgetTransactionSelector budgetTransactionSelectorObject = new BudgetTransactionSelector();
    public BudgetTransactionItemSelector budgetTransactionItemSelectorObject = new BudgetTransactionItemSelector();
    public BudgetTransactionSaveResultsBuilder saveResultsBuilder = new BudgetTransactionSaveResultsBuilder();
    public BudgetTransactionWrapper budgetTransactionWrapperObject = new BudgetTransactionWrapper(saveResultsBuilder);

    public BudgetTransactionSaveResultsBuilder generateBudgetTransaction(Id recordId, List<Object> reports, Boolean isInvoice, List<Object> selectedAccruals){

        if (!reports.isEmpty() || !selectedAccruals.isEmpty()){
            List<Map<String, String>> reportsList = (List<Map<String, String>>) JSON.deserialize(JSON.serialize(reports), (List<Map<String, String>>.class));
            Set<Id> selectedMonthlyReportsIds = new Set<Id>();
            Set<Id> selectedBudgetTransactionIds = new Set<Id>();
            Map<Id, Monthly_Report__c> selectedMonthlyReports;
            Map<Id, Budget_transaction__c> selectedBudgetTransactions;
            Map<Integer, List<Monthly_Report__c>> reportsByMonth = new Map<Integer, List<Monthly_Report__c>>();
            Map<Budget_transaction__c, List<Monthly_Report__c>> reportsIdsByBudgetTransactionIds = new Map<Budget_transaction__c, List<Monthly_Report__c>>();
            Project__c project = projectSelectorObject.getProjectFields(recordId)[0];
            Boolean isFixCostProject = project.Contract_type__c == 'Fixed cost';
            Set<Id> selectedAccrualIds = new Set<Id>();
            List<Map<String, String>> accrualsList;
            Set<Id> accrualSOWIds = new Set<Id>();
            List<Budget_transaction__c> accrualsWithNewBudgetTransaction = new List<Budget_transaction__c>();
            Map<Budget_transaction__c, List<Budget_transaction__c>> accrualsWithExistingBudgetTransaction = new Map<Budget_transaction__c, List<Budget_transaction__c>>();
            List<Budget_transaction__c> accrualsToUpdate = new List<Budget_transaction__c>();

            if (!selectedAccruals.isEmpty()){
                accrualsList = (List<Map<String, String>>) JSON.deserialize(JSON.serialize(selectedAccruals), (List<Map<String, String>>.class));

                for (Map<String, String> reportObject : accrualsList) {
                    if (reportObject.get('id') != null) {
                        selectedAccrualIds.add((Id) String.valueOf(reportObject.get('id')));
                    }

                    if (reportObject.get('selectedPicklistOption') != 'New') {
                        selectedBudgetTransactionIds.add((Id) String.valueOf(reportObject.get('selectedPicklistOption')));
                    }
                }

                selectedBudgetTransactionIds.addAll(selectedAccrualIds);
            }

            for (Map<String, String> reportObject : reportsList) {
                if (reportObject.get('Id') != null) {
                    selectedMonthlyReportsIds.add((Id) String.valueOf(reportObject.get('Id')));
                }

                if (reportObject.get('BudgetTransactionId') != 'New') {
                    selectedBudgetTransactionIds.add((Id) String.valueOf(reportObject.get('BudgetTransactionId')));
                }
            }

            selectedMonthlyReports = new Map<Id, Monthly_Report__c>(monthlyReportSelectorObject.getReportsByIds(new List<Id>(selectedMonthlyReportsIds)));
            selectedBudgetTransactions = new Map<Id, Budget_transaction__c>(budgetTransactionSelectorObject.getBudgetTransactionsWithRelatedBudgetTransactionItems(selectedBudgetTransactionIds));

            if (!selectedAccruals.isEmpty()) {

                for (Map<String, String> accrualObject : accrualsList) {
                    Id accrualId = (Id) accrualObject.get('id');
                    Budget_transaction__c accrual = selectedBudgetTransactions.get(accrualId);

                    accrualSOWIds.add(accrual.SOW__c);

                    if (accrualObject.get('selectedPicklistOption') == 'New') {
                        accrualsWithNewBudgetTransaction.add(accrual);
                    } else {
                        Id invoiceId = (Id)accrualObject.get('selectedPicklistOption');
                        Budget_transaction__c invoice = selectedBudgetTransactions.get(invoiceId);
                        accrual.Invoice__c = invoiceId;
                        accrual.Accrual_status__c = 'Inactive';

                        accrualsToUpdate.add(accrual);

                        if (accrualsWithExistingBudgetTransaction.containsKey(invoice)) {
                            accrualsWithExistingBudgetTransaction.get(invoice).add(accrual);
                        } else {
                            accrualsWithExistingBudgetTransaction.put(invoice, new List<Budget_transaction__c>{accrual});
                        }
                    }
                }

                if (accrualSOWIds.size() > 1) {
                    saveResultsBuilder.resultMessage = NOT_UNIQUE_SOW_ERROR;
                    saveResultsBuilder.isSuccessful = false;

                    return saveResultsBuilder;
                }

                if (!accrualsWithExistingBudgetTransaction.isEmpty()) {
                    createAccrualBTICopiesForInvoices(accrualsWithExistingBudgetTransaction);
                }

                budgetTransactionWrapperObject.budgetTransactionsToUpdate.addAll(accrualsToUpdate);
                //update accrualsToUpdate;
            }

            if (!selectedMonthlyReports.isEmpty()) {
                Set<Id> sowIds = new Set<Id>();

                for (Map<String, String> reportObject : reportsList) {
                    Id reportId = (Id)reportObject.get('Id');
                    Monthly_Report__c report = selectedMonthlyReports.get(reportId);
                    sowIds.add(report.Allocation__r.SOW__c);

                    if (reportObject.get('BudgetTransactionId') == 'New') {
                        Integer reportMonthNumber = report.Monthly_Report_Start_Date__c.month();

                        if (reportsByMonth.containsKey(reportMonthNumber)) {
                            reportsByMonth.get(reportMonthNumber).add(report);
                        } else {
                            reportsByMonth.put(reportMonthNumber, new List<Monthly_Report__c>{
                                    report
                            });
                        }
                    } else {
                        Id budgetTransactionId = (Id) reportObject.get('BudgetTransactionId');
                        Budget_transaction__c budgetTransaction = selectedBudgetTransactions.get(budgetTransactionId);

                        if (report.Allocation__r.SOW__c == budgetTransaction.SOW__c) {
                            if (reportsIdsByBudgetTransactionIds.containsKey(budgetTransaction)) {
                                reportsIdsByBudgetTransactionIds.get(budgetTransaction).add(report);
                            } else {
                                reportsIdsByBudgetTransactionIds.put(budgetTransaction, new List<Monthly_Report__c>{
                                        report
                                });
                            }
                        } else {
                            saveResultsBuilder.resultMessage = NOT_THE_SAME_SOW_ERROR;
                            saveResultsBuilder.isSuccessful = false;

                            return saveResultsBuilder;
                        }
                    }
                }

                List<Id> sowIdsList = new List<Id>(sowIds);

                if (!isInvoice && isFixCostProject) {
                    if (sowIds.contains(null)){
                        saveResultsBuilder.resultMessage = FIXED_COST_PROJECT_NULL_SOW_ERROR;
                        saveResultsBuilder.isSuccessful = false;

                        return saveResultsBuilder;
                    }
                }

                if (sowIds.size() > 1) {
                    saveResultsBuilder.resultMessage = NOT_UNIQUE_SOW_ERROR;
                    saveResultsBuilder.isSuccessful = false;

                    return saveResultsBuilder;
                }

                if (!accrualSOWIds.isEmpty() && !sowIds.isEmpty() && !accrualSOWIds.equals(sowIds)) {
                    saveResultsBuilder.resultMessage = DIFFERENT_SOWS_FOR_INVOICE_AND_ACCRUALS;
                    saveResultsBuilder.isSuccessful = false;

                    return saveResultsBuilder;
                }

                if (!reportsByMonth.isEmpty()) {
                    generateNewBudgetTransactionAndItems(
                            reportsByMonth,
                            project,
                            isInvoice,
                            isFixCostProject,
                            sowIdsList[0],
                            accrualsWithNewBudgetTransaction
                    );
                }

                if (!reportsIdsByBudgetTransactionIds.isEmpty()) {
                    generateBudgetTransactionItemsForBudgetTransactions(
                            reportsIdsByBudgetTransactionIds
                    );
                }
            } else if (!accrualsWithNewBudgetTransaction.isEmpty()) {
                createAccrualBTIAndNewInvoice(accrualsWithNewBudgetTransaction, project, new List<Id>(accrualSOWIds)[0]);
            }
        }

        saveResultsBuilder.buildResultMessage(budgetTransactionWrapperObject);

        return saveResultsBuilder;
    }

    public void createAccrualBTIAndNewInvoice(List<Budget_transaction__c> accruals, Project__c project, Id sowId) {
        System.debug('createAccrualBTIAndNewInvoice');
        Map<Budget_transaction__c, List<Budget_transaction__c>> accrualsWithExistingBudgetTransaction = new Map<Budget_transaction__c, List<Budget_transaction__c>>();
        Date startDate = accruals[0].Invoiced_on__c;

        for (Budget_transaction__c accrual : accruals) {
            if (startDate < accrual.Invoiced_on__c) {
                startDate = accrual.Invoiced_on__c;
            }
        }

        Budget_transaction__c invoice = new Budget_transaction__c(
                Project__c = project.Id,
                Invoiced_on__c = startDate,
                RecordTypeId = INVOICE_BUDGET_TRANSACTION_RECORD_TYPE_ID,
                Status__c = 'Draft',
                Invoice_Approver__c = project.Invoice_approver__c,
                Account__c = project.Account__c,
                Billed_from__c = project.Billed_from__c,
                SOW__c = sowId
        );

        //budgetTransactionWrapperObject.budgetTransactionsToInsert.add(invoice);
        saveResultsBuilder.budgetTransactionSaveResults = new List<Database.SaveResult>{
                Database.insert(invoice)
        };

        accrualsWithExistingBudgetTransaction.put(invoice, accruals);

        createAccrualBTICopiesForInvoices(accrualsWithExistingBudgetTransaction);
    }

    public void createAccrualBTICopiesForInvoices(Map<Budget_transaction__c, List<Budget_transaction__c>> accrualsWithExistingBudgetTransaction){
        System.debug('createAccrualBTICopiesForInvoices');
        List<Budget_transaction_item__c> accrualBTICopies = new List<Budget_transaction_item__c>();
        List<Budget_transaction_item__c> accrualBTIsToUpdate = new List<Budget_transaction_item__c>();
        List<Budget_transaction__c> accrualsToUpdate = new List<Budget_transaction__c>();
        Map<Budget_transaction_item__c, List<Budget_transaction_item__c>> accrualBTIByCopiedBTI = new Map<Budget_transaction_item__c, List<Budget_transaction_item__c>>();

        for (Budget_transaction__c invoiceBudgetTransaction : accrualsWithExistingBudgetTransaction.keySet()){
            for (Budget_transaction__c accrualBudgetTransaction : accrualsWithExistingBudgetTransaction.get(invoiceBudgetTransaction)){
                accrualBudgetTransaction.Invoice__c = invoiceBudgetTransaction.Id;
                accrualBudgetTransaction.Accrual_status__c = 'Inactive';

                for (Budget_transaction_item__c accrualBudgetTransactionItem : accrualBudgetTransaction.Budget_transaction_items__r){
                    Budget_transaction_item__c copyAccrualBTI = accrualBudgetTransactionItem.clone(false, true, false, false);

                    copyAccrualBTI.Budget_transaction__c = invoiceBudgetTransaction.Id;

                    accrualBTICopies.add(copyAccrualBTI);

                    if (accrualBTIByCopiedBTI.containsKey(copyAccrualBTI)) {
                        accrualBTIByCopiedBTI.get(copyAccrualBTI).add(accrualBudgetTransactionItem);
                    } else {
                        accrualBTIByCopiedBTI.put(copyAccrualBTI, new List<Budget_transaction_item__c>{accrualBudgetTransactionItem});
                    }
                }

                accrualsToUpdate.add(accrualBudgetTransaction);
            }
        }

        //BudgetTransactionWrapperObject.budgetTransactionItemsToInsert.addAll(accrualBTICopies);
        BudgetTransactionWrapperObject.budgetTransactionsToUpdate.addAll(accrualsToUpdate);

        saveResultsBuilder.budgetTransactionItemSaveResult = Database.insert(accrualBTICopies);
        //update accrualsToUpdate;

        //TODO refactor system.debug
        System.debug(accrualBTIByCopiedBTI);
        for (Budget_transaction_item__c insertedItem : accrualBTICopies) {

            if (accrualBTIByCopiedBTI.containsKey(insertedItem)) {
                for (Budget_transaction_item__c accrualBTI : accrualBTIByCopiedBTI.get(insertedItem)) {
                    accrualBTI.Budget_transaction_item__c = insertedItem.Id;

                    accrualBTIsToUpdate.add(accrualBTI);
                }
            }
        }

        //BudgetTransactionWrapperObject.budgetTransactionItemsToUpdate.addAll(accrualBTIsToUpdate);

        saveResultsBuilder.budgetTransactionItemUpsertResult = Database.upsert(accrualBTIsToUpdate);
    }

    public void generateNewBudgetTransactionAndItems(
            Map<Integer, List<Monthly_Report__c>> reportsByMonth,
            Project__c project,
            Boolean isInvoice,
            Boolean isFixCostProject,
            Id sowId,
            List<Budget_transaction__c> accrualsWithNewBudgetTransaction
    ){
        System.debug('generateNewBudgetTransactionAndItems');
        List<Budget_transaction__c> budgetTransactionsToInsert = new List<Budget_transaction__c>();
        Map<Integer, Budget_transaction__c> createdBudgetTransactionByMonths = new Map<Integer, Budget_transaction__c>();
        List<Budget_transaction_item__c> invoiceItemsToInsert = new List<Budget_transaction_item__c>();

        for (Integer monthNumber : reportsByMonth.keySet()) {
            List<Monthly_Report__c> reports = reportsByMonth.get(monthNumber);
            Date reportStartDate = reports[0].Monthly_Report_Start_Date__c;
            Date startDate = Date.newInstance(reportStartDate.year(), reportStartDate.month() + 1, 1).addDays(-1);

            Budget_transaction__c invoice = new Budget_transaction__c(
                    Project__c = project.Id,
                    Invoiced_on__c = startDate,
                    RecordTypeId =
                            isInvoice ? INVOICE_BUDGET_TRANSACTION_RECORD_TYPE_ID :
                                    isFixCostProject ? BUDGET_TRANSACTION_ACCRUAL_RECORDTYPE_IDS.get('Accrual FixCost') : BUDGET_TRANSACTION_ACCRUAL_RECORDTYPE_IDS.get('Accrual TnM'),
                    Status__c = 'Draft',
                    Invoice_Approver__c = project.Invoice_approver__c,
                    Account__c = project.Account__c,
                    Billed_from__c = project.Billed_from__c,
                    Accrual_status__c = !isInvoice ? 'Active' : null,
                    SOW__c = sowId
            );

            if (!isInvoice && isFixCostProject){
                calculateBudgetUsagePercentField(invoice, sowId);
            }

            budgetTransactionsToInsert.add(invoice);
            createdBudgetTransactionByMonths.put(monthNumber, invoice);
        }

        try {
            //budgetTransactionWrapperObject.budgetTransactionsToInsert.addAll(budgetTransactionsToInsert);

            saveResultsBuilder.budgetTransactionSaveResults = Database.insert(budgetTransactionsToInsert);
        } catch (Exception e){
            saveResultsBuilder.processException(e);

            return;
        }

        if (!saveResultsBuilder.isBudgetTransactionsHaveInsertErrors()){
            Budget_transaction__c createdInvoice = budgetTransactionsToInsert[0];
            List<Budget_transaction__c> budgetTransactionsToUpdate = new List<Budget_transaction__c>();
            Map<Budget_transaction_item__c, Budget_transaction_item__c> accrualBTIByCopiedBTI = new Map<Budget_transaction_item__c, Budget_transaction_item__c>();

            Map<Integer, Map<String, MonthlyReportsWrapper>> reportsByCompositeStringByMonth = constructMonthlyReportsCompositeStringsByMonth(reportsByMonth);
            Map<Budget_transaction_item__c, List<Monthly_Report__c>> reportsByBudgetTransactionItems = new Map<Budget_transaction_item__c, List<Monthly_Report__c>>();
            Map<Id, List<Monthly_Report__c>> reportsByCustomIds = new Map<Id, List<Monthly_Report__c>>();
            Map<Id, Budget_transaction_item__c> budgetTransactionItemsByCustomIds = new Map<Id, Budget_transaction_item__c>();

            for (Integer monthNumber : reportsByCompositeStringByMonth.keySet()){
                Budget_transaction__c budgetTransaction = createdBudgetTransactionByMonths.get(monthNumber);
                Set<String> invoiceItemsISOCodes = new Set<String>();

                for (String compositeString : reportsByCompositeStringByMonth.get(monthNumber).keySet()){

                    MonthlyReportsWrapper reportsWrapper = reportsByCompositeStringByMonth.get(monthNumber).get(compositeString);

                    Budget_transaction_item__c invoiceItem = new Budget_transaction_item__c(
                            Billed_as__c = reportsWrapper.reports[0].Allocation__r.Billed_as__c,
                            CurrencyIsoCode = reportsWrapper.reports[0].Allocation__r.CurrencyIsoCode,
                            Budget_transaction__c = budgetTransaction.Id,
                            Total_Amount__c = reportsWrapper.totalAmount,
                            Hours__c = reportsWrapper.totalHours,
                            Rate__c = reportsWrapper.rate
                    );

                    invoiceItemsISOCodes.add(invoiceItem.CurrencyIsoCode);
                    invoiceItemsToInsert.add(invoiceItem);
                    reportsByBudgetTransactionItems.put(invoiceItem, reportsWrapper.reports);
                    reportsByCustomIds.put(reportsWrapper.reports[0].Id, reportsWrapper.reports);
                    budgetTransactionItemsByCustomIds.put(reportsWrapper.reports[0].Id, invoiceItem);
                }

                if (isInvoice) {
                    for (Budget_transaction__c accrual : accrualsWithNewBudgetTransaction) {

                        accrual.Invoice__c = createdInvoice.Id;
                        accrual.Accrual_status__c = 'Inactive';

                        for (Budget_transaction_item__c accrualBudgetTransactionItem : accrual.Budget_transaction_items__r) {
                            Budget_transaction_item__c copyAccrualItem = accrualBudgetTransactionItem.clone(false, true, false, false);
                            copyAccrualItem.Budget_transaction__c = createdInvoice.Id;

                            invoiceItemsToInsert.add(copyAccrualItem);
                            accrualBTIByCopiedBTI.put(copyAccrualItem, accrualBudgetTransactionItem);
                        }

                        budgetTransactionsToUpdate.add(accrual);
                    }
                }

                if (invoiceItemsISOCodes.size() > 1 || invoiceItemsISOCodes.isEmpty()) {
                    budgetTransaction.CurrencyIsoCode = project.CurrencyIsoCode;
                } else {
                    budgetTransaction.CurrencyIsoCode = invoiceItemsToInsert[0].CurrencyIsoCode;
                }

                budgetTransactionsToUpdate.add(budgetTransaction);
            }

            if (!invoiceItemsToInsert.isEmpty()){

                //budgetTransactionWrapperObject.budgetTransactionItemsToInsert.addAll(invoiceItemsToInsert);
                saveResultsBuilder.budgetTransactionItemSaveResult = Database.insert(invoiceItemsToInsert);
                List<Monthly_Report__c> reportsToUpdate = new List<Monthly_Report__c>();
                List<Budget_transaction_item__c> BTIsToUpdate = new List<Budget_transaction_item__c>();

                //TODO Fix Map
                System.debug(accrualBTIByCopiedBTI);

                for (Budget_transaction_item__c insertedItem : invoiceItemsToInsert){
                    if (isInvoice && accrualBTIByCopiedBTI.containsKey(insertedItem)) {

                        Budget_transaction_item__c accrualBTI = accrualBTIByCopiedBTI.get(insertedItem);

                        accrualBTI.Budget_transaction_item__c = insertedItem.Id;

                        BTIsToUpdate.add(accrualBTI);
                    }
                }

                for (Id customId : budgetTransactionItemsByCustomIds.keySet()) {
                    Budget_transaction_item__c invoiceItem = budgetTransactionItemsByCustomIds.get(customId);

                    for (Monthly_Report__c report : reportsByCustomIds.get(customId)) {
                        report.Budget_transaction_item__c = invoiceItem.Id;

                        reportsToUpdate.add(report);
                    }
                }

                System.debug(BTIsToUpdate);
                budgetTransactionWrapperObject.monthlyReportsToUpdate.addAll(reportsToUpdate);
                budgetTransactionWrapperObject.budgetTransactionsToUpdate.addAll(budgetTransactionsToUpdate);
                budgetTransactionWrapperObject.budgetTransactionItemsToUpdate.addAll(BTIsToUpdate);

                /*update reportsToUpdate;
                update budgetTransactionsToUpdate;
                update BTIsToUpdate;*/
            }
        }
    }


    public void generateBudgetTransactionItemsForBudgetTransactionAndAccrualBudgetTransaction(Map<Budget_transaction__c, List<Monthly_Report__c>> monthlyReportsByBudgetTransactions, Budget_transaction__c invoiceBudgetTransaction) {
        System.debug('generateBudgetTransactionItemsForBudgetTransactionAndAccrualBudgetTransaction');
        generateBudgetTransactionItemsForBudgetTransactions(monthlyReportsByBudgetTransactions);
        Set<Id> accrualBudgetTransactionIds = new Set<Id>{(new List<Budget_transaction__c>(monthlyReportsByBudgetTransactions.keySet()))[0].Id};

        createAccrualBTICopiesForInvoices(new Map<Budget_transaction__c, List<Budget_transaction__c>>{
                invoiceBudgetTransaction => budgetTransactionSelectorObject.getBudgetTransactionsWithRelatedBudgetTransactionItems(accrualBudgetTransactionIds)
        });
    }

    public void generateBudgetTransactionItemsForBudgetTransactions(
            Map<Budget_transaction__c, List<Monthly_Report__c>> reportsIdsByBudgetTransactionIds
    ){
        System.debug('generateBudgetTransactionItemsForBudgetTransactions');
        List<Budget_transaction_item__c> budgetTransactionItemsToUpdate = new List<Budget_transaction_item__c>();
        List<Budget_transaction_item__c> budgetTransactionItemsToInsert = new List<Budget_transaction_item__c>();
        Map<Id, Set<String>> invoiceItemsISOCodesByBudgetTransactionIds = new Map<Id, Set<String>>();
        List<Budget_transaction__c> budgetTransactionsToUpdate = new List<Budget_transaction__c>();
        Map<Budget_transaction_item__c, List<Monthly_Report__c>> newReportsByBudgetTransactionItems = new Map<Budget_transaction_item__c, List<Monthly_Report__c>>();
        Set<Id> existingBudgetTransactionItemsIds = new Set<Id>();
        List<Budget_transaction_item__c> existingBudgetTransactionItems = new List<Budget_transaction_item__c>();
        Map<Id, List<Budget_transaction_item__c>> existingBudgetTransactionItemsByBudgetTransactionIds = new Map<Id, List<Budget_transaction_item__c>>();
        Map<Id, List<Monthly_Report__c>> existingReportsByBudgetTransactionIds = new Map<Id, List<Monthly_Report__c>>();
        Map<Id, Budget_transaction__c> existingBudgetTransactionsWithRelatedBudgetTransactionItems = new Map<Id, Budget_transaction__c>(
                new List<Budget_transaction__c>(reportsIdsByBudgetTransactionIds.keySet())
        );

        for (Budget_transaction__c budgetTransaction : existingBudgetTransactionsWithRelatedBudgetTransactionItems.values()){
            existingReportsByBudgetTransactionIds.put(budgetTransaction.Id, new List<Monthly_Report__c>());

            for (Budget_transaction_item__c budgetTransactionItem : budgetTransaction.Budget_transaction_items__r) {
                existingBudgetTransactionItemsIds.add(budgetTransactionItem.Id);
            }
        }

        existingBudgetTransactionItems = budgetTransactionItemSelectorObject.getBudgetTransactionItemWithRelatedMonthlyReports(existingBudgetTransactionItemsIds);

        for (Budget_transaction_item__c budgetTransactionItem : existingBudgetTransactionItems){
            Id budgetTransactionId = budgetTransactionItem.Budget_transaction__c;

            for (Monthly_Report__c monthlyReport : budgetTransactionItem.Monthly_Reports__r){
                existingReportsByBudgetTransactionIds.get(budgetTransactionId).add(monthlyReport);
            }

            if (existingBudgetTransactionItemsByBudgetTransactionIds.containsKey(budgetTransactionId)){
                existingBudgetTransactionItemsByBudgetTransactionIds.get(budgetTransactionId).add(budgetTransactionItem);
            } else {
                existingBudgetTransactionItemsByBudgetTransactionIds.put(budgetTransactionId, new List<Budget_transaction_item__c>{budgetTransactionItem});
            }
        }

        for (Budget_transaction__c invoice : existingBudgetTransactionsWithRelatedBudgetTransactionItems.values()) {
            for (Budget_transaction_item__c invoiceItem : invoice.Budget_transaction_items__r) {
                if (invoiceItemsISOCodesByBudgetTransactionIds.containsKey(invoice.Id)) {
                    invoiceItemsISOCodesByBudgetTransactionIds.get(invoice.Id).add(invoiceItem.CurrencyIsoCode);
                } else {
                    invoiceItemsISOCodesByBudgetTransactionIds.put(invoice.Id, new Set<String>{invoiceItem.CurrencyIsoCode});
                }
            }
        }

        Map<Id, Map<String, MonthlyReportsWrapper>> reportsByCompositeStringByBudgetTransactionId = constructMonthlyReportsCompositeStringsByBudgetTransactionId(reportsIdsByBudgetTransactionIds);
        Map<Id, Map<String, Budget_transaction_item__c>> existingReportsByCompositeStringByBudgetTransactionId = constructBudgetTransactionItemsByCompositeStringsByBudgetTransactionId(existingBudgetTransactionItemsByBudgetTransactionIds);

        for (Id budgetTransactionId : reportsByCompositeStringByBudgetTransactionId.keySet()) {
            for (String compositeString : reportsByCompositeStringByBudgetTransactionId.get(budgetTransactionId).keySet()) {
                MonthlyReportsWrapper reportsWrapper = reportsByCompositeStringByBudgetTransactionId.get(budgetTransactionId).get(compositeString);
                Budget_transaction_item__c invoiceItem;

                if (existingReportsByCompositeStringByBudgetTransactionId.get(budgetTransactionId) != null) {

                    if (existingReportsByCompositeStringByBudgetTransactionId.get(budgetTransactionId).containsKey(compositeString)) {

                        invoiceItem = existingReportsByCompositeStringByBudgetTransactionId.get(budgetTransactionId).get(compositeString);

                        invoiceItem.Hours__c += reportsWrapper.totalHours;
                        invoiceItem.Total_Amount__c += reportsWrapper.totalAmount;

                        budgetTransactionItemsToUpdate.add(invoiceItem);
                    } else {
                        invoiceItem = new Budget_transaction_item__c(
                                Billed_as__c = reportsWrapper.reports[0].Allocation__r.Billed_as__c,
                                CurrencyIsoCode = reportsWrapper.reports[0].Allocation__r.CurrencyIsoCode,
                                Budget_transaction__c = budgetTransactionId,
                                Total_Amount__c = reportsWrapper.totalAmount,
                                Hours__c = reportsWrapper.totalHours,
                                Rate__c = reportsWrapper.rate
                        );

                        budgetTransactionItemsToInsert.add(invoiceItem);
                    }
                } else {
                    invoiceItem = new Budget_transaction_item__c(
                            Billed_as__c = reportsWrapper.reports[0].Allocation__r.Billed_as__c,
                            CurrencyIsoCode = reportsWrapper.reports[0].Allocation__r.CurrencyIsoCode,
                            Budget_transaction__c = budgetTransactionId,
                            Total_Amount__c = reportsWrapper.totalAmount,
                            Hours__c = reportsWrapper.totalHours,
                            Rate__c = reportsWrapper.rate
                    );

                    budgetTransactionItemsToInsert.add(invoiceItem);
                }

                newReportsByBudgetTransactionItems.put(invoiceItem, reportsWrapper.reports);

                Set<String> existingBudgetTransactionItemsCurrencyISOCodes = invoiceItemsISOCodesByBudgetTransactionIds.get(budgetTransactionId);

                if (existingBudgetTransactionItemsCurrencyISOCodes != null) {
                    if (existingBudgetTransactionItemsCurrencyISOCodes.size() < 2) {
                        if (!existingBudgetTransactionItemsCurrencyISOCodes.contains(invoiceItem.CurrencyIsoCode)) {
                            Budget_transaction__c existingBudgetTransaction = existingBudgetTransactionsWithRelatedBudgetTransactionItems.get(budgetTransactionId);
                            existingBudgetTransaction.CurrencyIsoCode = existingBudgetTransaction.Project__r.CurrencyIsoCode;
                            budgetTransactionsToUpdate.add(existingBudgetTransaction);
                        }
                    }
                }
            }
        }

        if (!budgetTransactionItemsToUpdate.isEmpty() || !budgetTransactionItemsToInsert.isEmpty()){

            if (!budgetTransactionItemsToUpdate.isEmpty()) {
                budgetTransactionWrapperObject.budgetTransactionItemsToUpdate.addAll(budgetTransactionItemsToUpdate);
                //saveResultsBuilder.budgetTransactionItemUpsertResult = Database.upsert(budgetTransactionItemsToUpdate);
            } else {
                //budgetTransactionWrapperObject.budgetTransactionItemsToInsert.addAll(budgetTransactionItemsToInsert);
                saveResultsBuilder.budgetTransactionItemSaveResult = Database.insert(budgetTransactionItemsToInsert);
            }

            List<Monthly_Report__c> reportsToUpdate = new List<Monthly_Report__c>();

            for (Budget_transaction_item__c insertedItem : newReportsByBudgetTransactionItems.keySet()){
                for (Monthly_Report__c relatedReport : newReportsByBudgetTransactionItems.get(insertedItem)){
                    relatedReport.Budget_transaction_item__c = insertedItem.Id;

                    reportsToUpdate.add(relatedReport);
                }
            }

            budgetTransactionWrapperObject.monthlyReportsToUpdate.addAll(reportsToUpdate);
            budgetTransactionWrapperObject.budgetTransactionsToUpdate.addAll(budgetTransactionsToUpdate);

            /*update reportsToUpdate;
            update budgetTransactionsToUpdate;*/
        }
    }

    public void calculateBudgetUsagePercentField(Budget_transaction__c invoice, Id sowId){
        Decimal totalAmount = 0;
        SOW__c relatedSOW = new SOW__c(Id = sowId);
        Map<Id, Budget_transaction__c> budgetTransactionsWithTheSameSOW =
                new Map<Id, Budget_transaction__c>([
                        SELECT Id, convertCurrency(SOW__r.Total_Cost__c), SOW__r.Budget_usage_percent__c, SOW__r.CurrencyIsoCode, convertCurrency(Total_Invoice_Amount__c)
                        FROM Budget_transaction__c
                        WHERE SOW__c = :sowId AND ((RecordTypeId IN :BUDGET_TRANSACTION_ACCRUAL_RECORDTYPE_IDS.values() AND Accrual_status__c = 'Active') OR RecordTypeId = :BUDGET_TRANSACTION_INVOICE_RECORDTYPE_ID)
                ]);

        if (!budgetTransactionsWithTheSameSOW.isEmpty()) {
            List<Budget_transaction__c> approvedOrPendingBudgetTransactions = new List<Budget_transaction__c>();
            relatedSOW = budgetTransactionsWithTheSameSOW.values()[0].SOW__r;
            List<ProcessInstance> approvedOrPendingProcessInstances = [SELECT Id, TargetObjectId FROM ProcessInstance WHERE Status IN ('Pending', 'Approved') AND TargetObjectId IN :budgetTransactionsWithTheSameSOW.keySet()];


            for (ProcessInstance processInstance : approvedOrPendingProcessInstances) {
                Budget_transaction__c approvedOrPendingBudgetTransaction = budgetTransactionsWithTheSameSOW.get(processInstance.TargetObjectId);

                totalAmount += approvedOrPendingBudgetTransaction.Total_Invoice_Amount__c == null ? 0 : approvedOrPendingBudgetTransaction.Total_Invoice_Amount__c;

                approvedOrPendingBudgetTransactions.add(approvedOrPendingBudgetTransaction);
            }

            Decimal result = (relatedSOW.Total_Cost__c == null || relatedSOW.Total_Cost__c == 0) ? 0 : totalAmount / relatedSOW.Total_Cost__c * 100;

            invoice.Budget_usage_percent__c = result;
            relatedSOW.Budget_usage_percent__c = result;
        } else {
            invoice.Budget_usage_percent__c = 0;
            relatedSOW.Budget_usage_percent__c = 0;
        }

        update relatedSOW;
    }

    public Map<Integer, Map<String, MonthlyReportsWrapper>> constructMonthlyReportsCompositeStringsByMonth(Map<Integer, List<Monthly_Report__c>> monthlyReportsByMonth){
        Map<Integer, Map<String, MonthlyReportsWrapper>> reportsByCompositeStringByMonth = new Map<Integer, Map<String, MonthlyReportsWrapper>>();

        for (Integer month : monthlyReportsByMonth.keySet()){
            Map<String, MonthlyReportsWrapper> reportsByCompositeStrings = constructMonthlyReportsWrapperByCompositeStrings(monthlyReportsByMonth.get(month));
            reportsByCompositeStringByMonth.put(month, reportsByCompositeStrings);
        }

        return reportsByCompositeStringByMonth;
    }

    public Map<Id, Map<String, MonthlyReportsWrapper>> constructMonthlyReportsCompositeStringsByBudgetTransactionId(Map<Budget_transaction__c, List<Monthly_Report__c>> monthlyReportsByBudgetTransactionId){
        Map<Id, Map<String, MonthlyReportsWrapper>> reportsByCompositeStringByBudgetTransactionId = new Map<Id, Map<String, MonthlyReportsWrapper>>();

        for (Budget_transaction__c budgetTransaction : monthlyReportsByBudgetTransactionId.keySet()){
            Map<String, MonthlyReportsWrapper> reportsByCompositeStrings = constructMonthlyReportsWrapperByCompositeStrings(monthlyReportsByBudgetTransactionId.get(budgetTransaction));
            reportsByCompositeStringByBudgetTransactionId.put(budgetTransaction.Id, reportsByCompositeStrings);
        }

        return reportsByCompositeStringByBudgetTransactionId;
    }

    public Map<Id, Map<String, Budget_transaction_item__c>> constructBudgetTransactionItemsByCompositeStringsByBudgetTransactionId(Map<Id, List<Budget_transaction_item__c>> existingBudgetTransactionItems){
        Map<Id, Map<String, Budget_transaction_item__c>> reportsByCompositeStringByMonth = new Map<Id, Map<String, Budget_transaction_item__c>>();

        for (Id budgetTransactionId : existingBudgetTransactionItems.keySet()){
            Map<String, Budget_transaction_item__c> budgetTransactionItemByCompositeString = constructBudgetTransactionItemsByCompositeStrings(existingBudgetTransactionItems.get(budgetTransactionId));

            reportsByCompositeStringByMonth.put(budgetTransactionId, budgetTransactionItemByCompositeString);
        }

        return reportsByCompositeStringByMonth;
    }

    public Map<String, MonthlyReportsWrapper> constructMonthlyReportsWrapperByCompositeStrings(List<Monthly_Report__c> reports){
        Map<String, MonthlyReportsWrapper> reportsWrapperByCompositeStrings = new Map<String, MonthlyReportsWrapper>();
        Map<String, List<Monthly_Report__c>> reportsByCompositeStrings = constructMonthlyReportsListByCompositeStrings(reports);

        for (String compositeString :reportsByCompositeStrings.keySet()){
            reportsWrapperByCompositeStrings.put(compositeString, new MonthlyReportsWrapper(reportsByCompositeStrings.get(compositeString)));
        }

        return reportsWrapperByCompositeStrings;
    }

    public Map<String, List<Monthly_Report__c>> constructMonthlyReportsListByCompositeStrings(List<Monthly_Report__c> reports){
        Map<String, List<Monthly_Report__c>> reportsByCompositeStrings = new Map<String, List<Monthly_Report__c>>();

        for (Monthly_Report__c report : reports){

            if (report.Allocation__r.Billed_as__c != null && report.Allocation__r.CurrencyIsoCode != null &&  report.Allocation__r.Expected_Rate__c != null){
                String compositeString =
                        report.Allocation__r.Billed_as__c + report.Allocation__r.CurrencyIsoCode + report.Allocation__r.Expected_Rate__c;

                if (reportsByCompositeStrings.containsKey(compositeString)){
                    reportsByCompositeStrings.get(compositeString).add(report);
                } else {
                    reportsByCompositeStrings.put(compositeString, new List<Monthly_Report__c>{report});
                }
            }
        }

        return reportsByCompositeStrings;
    }

    public Map<Budget_transaction_item__c, String> constructCompositeStringsByBudgetTransactionItems(List<Budget_transaction_item__c> budgetTransactionItems){
        Map<Budget_transaction_item__c, String> compositeStringsByBudgetTransactionItems = new Map<Budget_transaction_item__c, String>();

        for (Budget_transaction_item__c budgetTransactionItem : budgetTransactionItems){

            if (budgetTransactionItem.Billed_as__c != null && budgetTransactionItem.CurrencyIsoCode != null &&  budgetTransactionItem.Rate__c != null){
                String compositeString =
                        budgetTransactionItem.Billed_as__c + budgetTransactionItem.CurrencyIsoCode + budgetTransactionItem.Rate__c;

                compositeStringsByBudgetTransactionItems.put(budgetTransactionItem, compositeString);
            }
        }

        return compositeStringsByBudgetTransactionItems;
    }

    public Map<String, Budget_transaction_item__c> constructBudgetTransactionItemsByCompositeStrings(List<Budget_transaction_item__c> budgetTransactionItems){
        Map<String, Budget_transaction_item__c> compositeStringsByBudgetTransactionItems = new Map<String, Budget_transaction_item__c>();

        for (Budget_transaction_item__c budgetTransactionItem : budgetTransactionItems){

            if (budgetTransactionItem.Billed_as__c != null && budgetTransactionItem.CurrencyIsoCode != null &&  budgetTransactionItem.Rate__c != null){
                String compositeString =
                        budgetTransactionItem.Billed_as__c + budgetTransactionItem.CurrencyIsoCode + budgetTransactionItem.Rate__c;

                compositeStringsByBudgetTransactionItems.put(compositeString, budgetTransactionItem);
            }
        }

        return compositeStringsByBudgetTransactionItems;
    }

    public BudgetTransactionService.BudgetTransactionSaveResultsBuilder recalculateBudgetTransaction(Id recordId){

        if (recordId.getSobjectType() == Schema.Budget_transaction__c.SObjectType) {
            List<Budget_transaction__c> budgetTransactionsWithRelatedBudgetTransactionItems = budgetTransactionSelectorObject.getBudgetTransactionsWithRelatedBudgetTransactionItems(new Set<Id>{recordId});
            Boolean isInvoice = budgetTransactionsWithRelatedBudgetTransactionItems[0].RecordTypeId == INVOICE_BUDGET_TRANSACTION_RECORD_TYPE_ID;
            Budget_transaction__c selectedBudgetTransaction = budgetTransactionsWithRelatedBudgetTransactionItems[0];

            if (selectedBudgetTransaction.Status__c != 'Draft' && isInvoice) {
                saveResultsBuilder.resultMessage = 'You can recalculate only \'Draft\' Invoice';
                saveResultsBuilder.isSuccessful = false;
            } else if (!isInvoice && selectedBudgetTransaction.Accrual_status__c != 'Active') {
                saveResultsBuilder.resultMessage = 'You can recalculate only \'Active\' Accruals';
                saveResultsBuilder.isSuccessful = false;
            } else {
                Map<Budget_transaction__c, List<Monthly_Report__c>> monthlyReportsByBudgetTransactions = new Map<Budget_transaction__c, List<Monthly_Report__c>>();
                Set<Id> budgetTransactionItemsIds = new Set<Id>();
                Map<Id, Budget_transaction_item__c> existingBudgetTransactionItemsWithRelatedMonthlyReports;

                for (Budget_transaction_item__c budgetTransactionItem : selectedBudgetTransaction.Budget_transaction_items__r) {
                    budgetTransactionItemsIds.add(budgetTransactionItem.Id);
                }

                existingBudgetTransactionItemsWithRelatedMonthlyReports = new Map<Id, Budget_transaction_item__c>();

                for (Budget_transaction_item__c budgetTransactionItem : budgetTransactionItemSelectorObject.getBudgetTransactionItemWithRelatedMonthlyReports(budgetTransactionItemsIds)) {

                    if (budgetTransactionItem.Budget_transaction_items__r.isEmpty()) {
                        existingBudgetTransactionItemsWithRelatedMonthlyReports.put(budgetTransactionItem.Id, budgetTransactionItem);
                    }
                }

                monthlyReportsByBudgetTransactions = recalculateUsualInvoice(existingBudgetTransactionItemsWithRelatedMonthlyReports, selectedBudgetTransaction, isInvoice);

                generateBudgetTransactionItemsForBudgetTransactions(monthlyReportsByBudgetTransactions);
            }
        } else {
            saveResultsBuilder.resultMessage = 'You can use this button only on Budget_Transaction__c Object';
            saveResultsBuilder.isSuccessful = false;
        }

        saveResultsBuilder.buildResultMessage(budgetTransactionWrapperObject);

        return saveResultsBuilder;
    }

    public Map<Budget_transaction__c, List<Monthly_Report__c>> recalculateInvoiceFromAccruals(Map<Budget_transaction__c, List<Budget_transaction_item__c>> budgetTransactionItemsByBudgetTransactions) {
        System.debug('recalculateInvoiceFromAccruals');
        Map<Budget_transaction__c, List<Monthly_Report__c>> monthlyReportsByBudgetTransaction = new Map<Budget_transaction__c, List<Monthly_Report__c>>();

        for (Budget_transaction__c budgetTransaction : budgetTransactionItemsByBudgetTransactions.keySet()) {
            monthlyReportsByBudgetTransaction.putAll(recalculateUsualInvoice(
                    new Map<Id, Budget_transaction_item__c>(budgetTransactionItemsByBudgetTransactions.get(budgetTransaction)),
                    budgetTransaction,
                    true
            ));
        }

        return monthlyReportsByBudgetTransaction;
    }

    public Map<Budget_transaction__c, List<Monthly_Report__c>> recalculateUsualInvoice(Map<Id, Budget_transaction_item__c> existingBudgetTransactionItemsWithRelatedMonthlyReports, Budget_transaction__c selectedBudgetTransaction, Boolean isInvoice) {
        System.debug('recalculateUsualInvoice');
        Map<String, List<Monthly_Report__c>> existingMonthlyReportByCompositeStrings = new Map<String, List<Monthly_Report__c>>();
        Map<String, List<Monthly_Report__c>> newMonthlyReportByCompositeStrings = new Map<String, List<Monthly_Report__c>>();
        Map<String, Budget_transaction_item__c> existingBudgetTransactionItemsByCompositeStrings = new Map<String, Budget_transaction_item__c>();
        System.debug(existingBudgetTransactionItemsWithRelatedMonthlyReports);
        Map<Budget_transaction_item__c, String> compositeStringsByBudgetTransactionItems = constructCompositeStringsByBudgetTransactionItems(existingBudgetTransactionItemsWithRelatedMonthlyReports.values());

        for (Budget_transaction_item__c budgetTransactionItem : existingBudgetTransactionItemsWithRelatedMonthlyReports.values()) {
            String compositeString = compositeStringsByBudgetTransactionItems.get(budgetTransactionItem);

            newMonthlyReportByCompositeStrings.putAll(constructMonthlyReportsListByCompositeStrings(budgetTransactionItem.Monthly_Reports__r));
            existingBudgetTransactionItemsByCompositeStrings.put(compositeString, budgetTransactionItem);

            if (existingMonthlyReportByCompositeStrings.containsKey(compositeString)) {
                existingMonthlyReportByCompositeStrings.get(compositeString).addAll(budgetTransactionItem.Monthly_Reports__r);
            } else {
                existingMonthlyReportByCompositeStrings.put(compositeString, budgetTransactionItem.Monthly_Reports__r);
            }
        }
        System.debug(existingBudgetTransactionItemsByCompositeStrings);
         return recalculateRelatedMonthlyReports(
                existingMonthlyReportByCompositeStrings,
                newMonthlyReportByCompositeStrings,
                existingBudgetTransactionItemsByCompositeStrings,
                selectedBudgetTransaction
        );
    }

    public Map<Budget_transaction__c, List<Monthly_Report__c>> recalculateRelatedMonthlyReports(
            Map<String, List<Monthly_Report__c>> oldMonthlyReportByCompositeStrings,
            Map<String, List<Monthly_Report__c>> newMonthlyReportByCompositeStrings,
            Map<String, Budget_transaction_item__c> existingBudgetTransactionItemsByCompositeStrings,
            Budget_transaction__c budgetTransaction
    ){
        System.debug('recalculateRelatedMonthlyReports');
        System.debug(existingBudgetTransactionItemsByCompositeStrings);
        Set<Budget_transaction_item__c> budgetTransactionItemsToDelete = new Set<Budget_transaction_item__c>();
        Set<Budget_transaction_item__c> budgetTransactionItemsToUpdate = new Set<Budget_transaction_item__c>();
        Set<Monthly_Report__c> reportsToUpdate = new Set<Monthly_Report__c>();
        Set<String> compositeStringsSet = new Set<String>(oldMonthlyReportByCompositeStrings.keySet());
        Map<Id, Budget_transaction_item__c> existingBudgetTransactionItemsMap = new Map<Id, Budget_transaction_item__c>(
                existingBudgetTransactionItemsByCompositeStrings.values()
        );
        Map<Budget_transaction__c, List<Monthly_Report__c>> monthlyReportsByBudgetTransaction = new Map<Budget_transaction__c, List<Monthly_Report__c>>{
                budgetTransaction => new List<Monthly_Report__c>()
        };

        this.saveResultsBuilder.isRecalculate = true;

        compositeStringsSet.addAll(newMonthlyReportByCompositeStrings.keySet());

        for (String compositeString : compositeStringsSet){
            List<Monthly_Report__c> monthlyReportsOldList = oldMonthlyReportByCompositeStrings.get(compositeString);
            List<Monthly_Report__c> monthlyReportsNewList = newMonthlyReportByCompositeStrings.get(compositeString);
            Budget_transaction_item__c existingBudgetTransactionItem = existingBudgetTransactionItemsByCompositeStrings.get(compositeString);
            System.debug(monthlyReportsOldList);
            System.debug(monthlyReportsNewList);
            if (monthlyReportsNewList == null){
                //No such composite String in new Budget Transaction Items => Budget Transaction Item doesn't have Monthly Reports anymore => need to delete

                budgetTransactionItemsToDelete.add(existingBudgetTransactionItem);
            } else if (monthlyReportsOldList == null){
                //No such composite String in existing Budget Transaction Items => Budget Transaction Item doesn't exist => need to create

                for (Monthly_Report__c monthlyReportNew : monthlyReportsNewList){
                    if (monthlyReportNew.Budget_transaction_item__c != null){
                        Budget_transaction_item__c oldBudgetTransactionItem = existingBudgetTransactionItemsMap.get(monthlyReportNew.Budget_transaction_item__c);

                        oldBudgetTransactionItem.Hours__c -= monthlyReportNew.Fact_hours__c == null ? 0 : monthlyReportNew.Fact_hours__c;
                        oldBudgetTransactionItem.Total_Amount__c = oldBudgetTransactionItem.Hours__c * oldBudgetTransactionItem.Rate__c;

                        budgetTransactionItemsToUpdate.add(oldBudgetTransactionItem);
                    }
                }

                monthlyReportsByBudgetTransaction.get(budgetTransaction).addAll(monthlyReportsNewList);
            } else {
                monthlyReportsOldList.sort();
                monthlyReportsNewList.sort();

                if (monthlyReportsNewList.equals(monthlyReportsOldList)){
                    Decimal totalHours = 0;
                    Decimal totalAmount = 0;

                    for (Monthly_Report__c monthlyReportNew : monthlyReportsNewList){

                        totalHours += monthlyReportNew == null ? 0 : monthlyReportNew.Fact_hours__c == null ? 0 : monthlyReportNew.Fact_hours__c;
                        totalAmount += monthlyReportNew.Monthly_revenueNew__c == null ? 0 : monthlyReportNew.Monthly_revenueNew__c;
                    }

                    if (existingBudgetTransactionItem.Hours__c != totalHours){
                        existingBudgetTransactionItem.Hours__c = totalHours;
                        existingBudgetTransactionItem.Total_Amount__c = totalAmount;

                        budgetTransactionItemsToUpdate.add(existingBudgetTransactionItem);
                    }

                } else {

                    for (Monthly_Report__c newReport : monthlyReportsNewList){

                        if (!monthlyReportsOldList.contains(newReport)){
                            //Report should be in New List

                            //Subtract report hours and recalculate Total Amount
                            Budget_transaction_item__c oldBudgetTransactionItem = existingBudgetTransactionItemsMap.get(newReport.Budget_transaction_item__c);

                            oldBudgetTransactionItem.Hours__c -= newReport.Fact_hours__c == null ? 0 : newReport.Fact_hours__c;
                            existingBudgetTransactionItem.Total_Amount__c = existingBudgetTransactionItem.Hours__c * existingBudgetTransactionItem.Rate__c;

                            //Add report hours and recalculate Total Amount
                            newReport.Budget_transaction_item__c = existingBudgetTransactionItem.Id;
                            existingBudgetTransactionItem.Hours__c += newReport.Fact_hours__c == null ? 0 : newReport.Fact_hours__c;
                            existingBudgetTransactionItem.Total_Amount__c = existingBudgetTransactionItem.Hours__c * existingBudgetTransactionItem.Rate__c;

                            budgetTransactionItemsToUpdate.add(oldBudgetTransactionItem);
                            budgetTransactionItemsToUpdate.add(existingBudgetTransactionItem);

                            reportsToUpdate.add(newReport);
                        }
                    }
                }
            }
        }

        budgetTransactionWrapperObject.budgetTransactionItemsToDelete.addAll(new List<Budget_transaction_item__c>(budgetTransactionItemsToDelete));
        budgetTransactionWrapperObject.monthlyReportsToUpdate.addAll(new List<Monthly_Report__c>(reportsToUpdate));
        budgetTransactionWrapperObject.budgetTransactionItemsToUpdate.addAll(new List<Budget_transaction_item__c>(budgetTransactionItemsToUpdate));

        return monthlyReportsByBudgetTransaction;
        //generateBudgetTransactionItemsForBudgetTransactions(monthlyReportsByBudgetTransaction, isInvoice);
        /*saveResultsBuilder.budgetTransactionItemUpsertResult = Database.upsert(budgetTransactionItemsToUpdate);
        update reportsToUpdate;
        delete budgetTransactionItemsToDelete;*/
    }

    public Boolean validateBudgetTransactions(List<Budget_transaction__c> budgetTransactions) {
        Boolean passedValidation = validateBudgetTransactionStatus(budgetTransactions);

        return passedValidation;
    }

    public Boolean validateBudgetTransactions(Map<Id, Budget_transaction__c> oldBudgetTransactions, List<Budget_transaction__c> budgetTransactions) {
        Boolean passedValidation = validateBudgetTransactionStatus(oldBudgetTransactions, budgetTransactions);

        return passedValidation;
    }

    public Boolean validateBudgetTransactionStatus(Map<Id, Budget_transaction__c> oldBudgetTransactions, List<Budget_transaction__c> newBudgetTransactions) {
        List<Budget_transaction__c> changedBudgetTransactions = new List<Budget_transaction__c>();

        for (Budget_transaction__c newBudgetTransaction : newBudgetTransactions) {
            Budget_transaction__c oldBudgetTransaction = oldBudgetTransactions.get(newBudgetTransaction.Id);

            if (oldBudgetTransaction.Status__c != newBudgetTransaction.Status__c) {
                if (oldBudgetTransaction.Accrual_status__c == newBudgetTransaction.Accrual_status__c && oldBudgetTransaction.Invoice__c == newBudgetTransaction.Invoice__c) {
                    changedBudgetTransactions.add(newBudgetTransaction);
                }
            }
        }

        return validateBudgetTransactionStatus(changedBudgetTransactions);
    }

    public Boolean validateBudgetTransactionStatus(List<Budget_transaction__c> budgetTransactions) {
        Boolean isPM = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()][0].Name == 'CT_Project Manager';

        if (isPM) {
            List<String> availableStatuses = new List<String>{'Draft', 'On Customer Approval', 'Pending'};

            for (Budget_transaction__c budgetTransaction : budgetTransactions) {
                if (budgetTransaction.Status__c != null && !availableStatuses.contains(budgetTransaction.Status__c)) {
                    budgetTransactions[0].Status__c.addError(INVALID_STATUS_FOR_PROJECT_MANAGER_ERROR);

                    return false;
                }
            }
        }
        return true;
    }

    private class BudgetTransactionWrapper {
        public Set<Budget_transaction__c> budgetTransactionsToInsert { get; set; }
        public Set<Budget_transaction__c> budgetTransactionsToUpdate { get; set; }
        public Set<Budget_transaction__c> budgetTransactionsToDelete { get; set; }
        public Set<Budget_transaction_item__c> budgetTransactionItemsToInsert { get; set; }
        public Set<Budget_transaction_item__c> budgetTransactionItemsToUpdate { get; set; }
        public Set<Budget_transaction_item__c> budgetTransactionItemsToDelete { get; set; }
        public Set<Monthly_Report__c> monthlyReportsToUpdate { get; set; }
        public BudgetTransactionSaveResultsBuilder saveResultsBuilder { get; set; }

        public BudgetTransactionWrapper(BudgetTransactionSaveResultsBuilder saveResultsBuilder) {
            this.saveResultsBuilder = saveResultsBuilder;
            this.budgetTransactionsToInsert = new Set<Budget_transaction__c>();
            this.budgetTransactionsToUpdate = new Set<Budget_transaction__c>();
            this.budgetTransactionsToDelete = new Set<Budget_transaction__c>();
            this.budgetTransactionItemsToInsert = new Set<Budget_transaction_item__c>();
            this.budgetTransactionItemsToUpdate = new Set<Budget_transaction_item__c>();
            this.budgetTransactionItemsToDelete = new Set<Budget_transaction_item__c>();
            this.monthlyReportsToUpdate = new Set<Monthly_Report__c>();
        }

        public void handleLists() {
            removeNullsFromSets();

            saveResultsBuilder.budgetTransactionSaveResults = Database.insert(new List<Budget_transaction__c>(this.budgetTransactionsToInsert));
            Database.update(new List<Budget_transaction__c>(this.budgetTransactionsToUpdate));
            Database.delete(new List<Budget_transaction__c>(this.budgetTransactionsToDelete));

            saveResultsBuilder.budgetTransactionItemSaveResult = Database.insert(new List<Budget_transaction_item__c>(this.budgetTransactionItemsToInsert));
            saveResultsBuilder.budgetTransactionItemUpsertResult = Database.upsert(new List<Budget_transaction_item__c>(this.budgetTransactionItemsToUpdate));
            Database.delete(new List<Budget_transaction_item__c>(this.budgetTransactionItemsToDelete));

            Database.update(new List<Monthly_Report__c>(this.monthlyReportsToUpdate));
        }

        public void handleAddElementsToSet(Set<SObject> initialSet, Set<SObject> additionalSet) {
            for (SObject additionalObject : additionalSet) {
                if (initialSet.contains(additionalObject)) {
                    initialSet.remove(additionalObject);
                    initialSet.add(additionalObject);
                }
            }
        }

        private void removeNullsFromSets() {
            this.budgetTransactionsToInsert.remove(null);
            this.budgetTransactionsToUpdate.remove(null);
            this.budgetTransactionsToDelete.remove(null);
            this.budgetTransactionItemsToInsert.remove(null);
            this.budgetTransactionItemsToUpdate.remove(null);
            this.budgetTransactionItemsToDelete.remove(null);
            this.monthlyReportsToUpdate.remove(null);
        }
    }

    private class MonthlyReportsWrapper {
        private Decimal totalAmount = 0;
        private Decimal totalHours = 0;
        private Decimal rate = 0;
        private List<Monthly_Report__c> reports = new List<Monthly_Report__c>();

        public MonthlyReportsWrapper(List<Monthly_Report__c> reports){
            this.reports = reports;
            this.rate = reports[0].Allocation__r.Expected_Rate__c;

            for (Monthly_Report__c report : reports){
                this.totalHours += report.Fact_hours__c == null ? 0 : report.Fact_hours__c;
                this.totalAmount += report.Monthly_revenueNew__c == null ? 0 : report.Monthly_revenueNew__c;
            }
        }

    }

    public class BudgetTransactionSaveResultsBuilder {
        @AuraEnabled
        public Boolean isSuccessful { get; set; }
        @AuraEnabled
        public String resultMessage { get; set; }
        private final String SUCCESS_STRING = 'Success';
        @TestVisible
        private Integer numberOfUpdatedBudgetTransactionItems = 0;
        @TestVisible
        private Integer numberOfInsertedBudgetTransactionItems = 0;
        @TestVisible
        private Integer numberOfInsertedBudgetTransactions = 0;
        public Boolean isRecalculate = false;
        @TestVisible
        public List<Database.SaveResult> budgetTransactionSaveResults {
            private get;
            public set {
                if (value != null) {
                    if (this.budgetTransactionSaveResults != null) {
                        this.budgetTransactionSaveResults.addAll(new List<Database.SaveResult>(value));
                    } else {
                        this.budgetTransactionSaveResults = new List<Database.SaveResult>(value);
                    }

                    this.numberOfInsertedBudgetTransactions += value.size();
                    this.budgetTransactionSaveResultMessage = processSaveResult(new List<Database.SaveResult>(value));
                }
            }
        }
        public String budgetTransactionSaveResultMessage { get; private set; }
        @TestVisible
        public List<Database.SaveResult> budgetTransactionItemSaveResult{
            private get;
            public set {
                if (value != null) {
                    if (this.budgetTransactionItemSaveResult != null) {
                        this.budgetTransactionItemSaveResult.addAll(new List<Database.SaveResult>(value));
                    } else {
                        this.budgetTransactionItemSaveResult = new List<Database.SaveResult>(value);
                    }

                    this.numberOfInsertedBudgetTransactionItems += value.size();
                    this.budgetTransactionItemSaveResultMessage = processSaveResult(new List<Database.SaveResult>(value));
                }
            }
        }
        @TestVisible
        public List<Database.UpsertResult> budgetTransactionItemUpsertResult {
            private get;
            public set {
                if (value != null) {
                    if (this.budgetTransactionItemUpsertResult != null) {
                        this.budgetTransactionItemUpsertResult.addAll(new List<Database.UpsertResult>(value));
                    } else {
                        this.budgetTransactionItemUpsertResult = new List<Database.UpsertResult>(value);
                    }

                    for (Database.UpsertResult upsertResult : value) {
                        if (upsertResult.created) {
                            this.numberOfInsertedBudgetTransactionItems++;
                        } else {
                            this.numberOfUpdatedBudgetTransactionItems++;
                        }
                    }

                    this.budgetTransactionItemsUpsertResultMessage = processSaveResult(new List<Database.UpsertResult>(value));
                }
            }
        }
        public String budgetTransactionItemsUpsertResultMessage { get; private set; }
        public String budgetTransactionItemSaveResultMessage { get; private set; }

        private String processSaveResult(List<Database.SaveResult> saveResults){
            String errorMessage = '';

            for (Database.SaveResult saveResult : saveResults){
                if (!saveResult.isSuccess()){
                    errorMessage += saveResult.getErrors() + '\n\n';
                }
            }

            return String.isEmpty(errorMessage) ? this.SUCCESS_STRING : errorMessage;
        }

        private String processSaveResult(List<Database.UpsertResult> upsertResults){
            String errorMessage = '';

            for (Database.UpsertResult upsertResult : upsertResults){
                if (!upsertResult.isSuccess()){
                    errorMessage += upsertResult.getErrors() + '\n\n';
                }
            }

            return String.isEmpty(errorMessage) ? this.SUCCESS_STRING : errorMessage;
        }

        public Boolean isBudgetTransactionCreatedSuccessfully(){
            return this.numberOfInsertedBudgetTransactions != 0 && this.budgetTransactionSaveResultMessage == this.SUCCESS_STRING;
        }

        public Boolean isBudgetTransactionsHaveInsertErrors(){
            return this.numberOfInsertedBudgetTransactions != 0 && this.budgetTransactionSaveResultMessage != this.SUCCESS_STRING;
        }

        public Boolean isBudgetTransactionItemCreatedSuccessfully(){
            return this.numberOfInsertedBudgetTransactionItems != 0 && this.budgetTransactionItemSaveResultMessage == this.SUCCESS_STRING;
        }

        public Boolean isBudgetTransactionItemsHaveInsertErrors(){
            return this.numberOfInsertedBudgetTransactionItems != 0 && this.budgetTransactionItemSaveResultMessage != this.SUCCESS_STRING;
        }

        public Boolean isListsAreEmpty(){
            return
                    (
                        this.numberOfUpdatedBudgetTransactionItems == 0 &&
                        this.numberOfInsertedBudgetTransactionItems == 0 &&
                        this.numberOfInsertedBudgetTransactions == 0
                    );
        }

        public Boolean isBudgetTransactionItemUpdatedSuccessfully(){
            return this.numberOfUpdatedBudgetTransactionItems != 0 && this.budgetTransactionItemsUpsertResultMessage == this.SUCCESS_STRING;
        }

        public Boolean isBudgetTransactionItemHaveUpdateErrors(){
            return this.numberOfUpdatedBudgetTransactionItems != 0 && this.budgetTransactionItemsUpsertResultMessage != this.SUCCESS_STRING;
        }

        public void buildResultMessage(BudgetTransactionWrapper budgetTransactionWrapperObject){
            Savepoint sp = Database.setSavepoint();

            try {
                budgetTransactionWrapperObject.handleLists();
            } catch (Exception e) {
                Database.rollback(sp);

                processException(e);
            }

            if (this.resultMessage == null) {
                this.isSuccessful = false;

                if (isBudgetTransactionsHaveInsertErrors()) {
                    this.resultMessage = 'Budget Transaction have errors:' + this.budgetTransactionSaveResultMessage;
                } else if (isBudgetTransactionItemsHaveInsertErrors()) {
                    this.resultMessage = 'Budget Transaction Items have errors: ' + this.budgetTransactionItemSaveResultMessage;
                } else if (isBudgetTransactionItemHaveUpdateErrors()) {
                    this.resultMessage = 'Budget Transaction Items have errors: ' + this.budgetTransactionItemsUpsertResultMessage;
                } else {
                    this.isSuccessful = true;

                    if (isBudgetTransactionItemCreatedSuccessfully() && isBudgetTransactionCreatedSuccessfully()) {
                        this.resultMessage = 'Successfully created ' + this.numberOfInsertedBudgetTransactions + ' Budget Transaction';
                        this.resultMessage += this.numberOfInsertedBudgetTransactions == 1 ? '' : 's';
                        this.resultMessage += ' and ' + this.numberOfInsertedBudgetTransactionItems + ' Budget Transaction Item';
                        this.resultMessage += this.numberOfInsertedBudgetTransactionItems == 1 ? '!' : 's!';
                    } else if (isListsAreEmpty()) {
                        this.resultMessage = this.isRecalculate ? 'Everything is up-to-date' : 'There is nothing to create';
                        this.isSuccessful = this.isRecalculate;
                    } else if (isBudgetTransactionItemCreatedSuccessfully() && isBudgetTransactionItemUpdatedSuccessfully()) {
                        this.resultMessage = 'Successfully created ' + this.numberOfInsertedBudgetTransactionItems;
                        this.resultMessage += ' and updated ' + this.numberOfUpdatedBudgetTransactionItems + ' Budget Transaction Items';
                    } else if (isBudgetTransactionItemCreatedSuccessfully()) {
                        this.resultMessage = 'Successfully created ' + this.numberOfInsertedBudgetTransactionItems + ' Budget Transaction Item';
                        this.resultMessage += this.numberOfInsertedBudgetTransactionItems == 1 ? '!' : 's!';
                    } else if (isBudgetTransactionItemUpdatedSuccessfully()) {
                        this.resultMessage = 'Successfully updated ' + this.numberOfUpdatedBudgetTransactionItems + ' Budget Transaction Item';
                        this.resultMessage += this.numberOfUpdatedBudgetTransactionItems == 1 ? '!' : 's!';
                    } else if (isBudgetTransactionCreatedSuccessfully()) {
                        this.resultMessage = 'Successfully created Budget Transaction';
                    } else {
                        this.isSuccessful = false;
                        this.resultMessage = 'Unexpected behaviour. Please, contact your System Administrator.';
                    }
                }
            }
        }

        public String processException(Exception e){
            if (e.getTypeName() == System.DmlException.class.getName()){
                this.resultMessage = ((DmlException)e).getDmlMessage(0);
            } else {
                this.resultMessage = e.getMessage();
            }

            return this.resultMessage;
        }
    }

}