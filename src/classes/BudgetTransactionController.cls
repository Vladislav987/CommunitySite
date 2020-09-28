/**
 * Created by MaxymMirona on 12.03.2020.
 */

public without sharing class BudgetTransactionController {
    static MonthlyReportService monthlyReportService = new MonthlyReportService();

    @AuraEnabled
    public static ModalInfo getInitDataForModal(Id recordId, Boolean generateInvoice){

        return new ModalInfo(
                monthlyReportService.getMonthsNames(),
                monthlyReportService.getYearsRangeWithOneYearAgo(recordId),
                Date.today(),
                monthlyReportService.getMonthlyReportsForGenerateInvoiceComponent(recordId, generateInvoice)
        );
    }

    @AuraEnabled
    public static BudgetTransactionService.BudgetTransactionSaveResultsBuilder recalculateBudgetTransaction(Id recordId){
        BudgetTransactionService budgetTransactionService = new BudgetTransactionService();

        return budgetTransactionService.recalculateBudgetTransaction(recordId);
    }

    @AuraEnabled
    public static BudgetTransactionService.BudgetTransactionSaveResultsBuilder generateBudgetTransaction(Id recordId, List<Object> reports, Boolean isInvoice){
        BudgetTransactionService budgetTransactionService = new BudgetTransactionService();

        return budgetTransactionService.generateBudgetTransaction(recordId, reports, isInvoice);
    }

    public class ModalInfo {
        @AuraEnabled
        public List<String> months { get; set; }
        @AuraEnabled
        public List<String> years { get; set; }
        @AuraEnabled
        public Date today { get; set; }
        @AuraEnabled
        public MonthlyReportService.DataTableWrapper dataTable { get; set; }
        public ModalInfo(List<String> months, List<String> years, Date today, MonthlyReportService.DataTableWrapper dataTable) {
            this.months = months;
            this.years = years;
            this.today = today;
            this.dataTable = dataTable;
        }
    }

}