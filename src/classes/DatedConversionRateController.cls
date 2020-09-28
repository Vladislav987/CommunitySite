/**
 * Created by MaxymMirona on 23.12.2019.
 */

public with sharing class DatedConversionRateController {

    static DatedConversionRateService datedConversionRateService = new DatedConversionRateService();

    @AuraEnabled
    public static RelatedListInfo getRelatedListInitData(){
        return new RelatedListInfo(
                datedConversionRateService.getDatedConversionRatesForRelatedList(),
                datedConversionRateService.getBlockedStartDates(),
                datedConversionRateService.getCorporateISOCode()
        );
    }

    @AuraEnabled
    public static List<DatedConversionRate> getDatedConversionRatesToInsert(List<DatedConversionRate> records){
        return datedConversionRateService.getDatedConversionRatesToInsert(records);
    }

    @AuraEnabled
    public static String upsertDatedConversionRate(List<DatedConversionRate> recordsList){

        if (recordsList == null || recordsList.isEmpty()) {
            throw new AuraHandledException('Sorry, but you have to select Rates');
        }
        return datedConversionRateService.upsertDatedConversionRateFromRelatedList(recordsList);
    }

    public class RelatedListInfo {
        @AuraEnabled
        public DatedConversionRateService.DataTableWrapper dataTable { get; set; }
        @AuraEnabled
        public List<Date> blockedStartDates {get; set;}
        @AuraEnabled
        public String corporateISOCode {get; set;}
        public RelatedListInfo(DatedConversionRateService.DataTableWrapper dataTable, List<Date> blockedStartDates, String corporateISOCode) {
            this.dataTable = dataTable;
            this.blockedStartDates = blockedStartDates;
            this.corporateISOCode = corporateISOCode;
        }
    }

}