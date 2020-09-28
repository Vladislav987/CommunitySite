/**
 * Created by MaxymMirona on 07.07.2020.
 */

public without sharing class LA_ContractorsPMTabController {

    public static LA_ContractorsPMTabService service = new LA_ContractorsPMTabService();

    @AuraEnabled
    public static TabDataWrapper getInitData(String period) {
        return new TabDataWrapper(
                service.getGridData(period),
                service.getGridMonths(),
                service.getGridYears()
        );
    }

    public class TabDataWrapper {
        @AuraEnabled
        public LA_ContractorsPMTabService.GridDataWrapper gridDataWrapper;

        @AuraEnabled
        public List<String> months;

        @AuraEnabled
        public List<String> years;

        public TabDataWrapper(LA_ContractorsPMTabService.GridDataWrapper gridDataWrapper, List<String> months, List<String> years) {
            this.gridDataWrapper = gridDataWrapper;
            this.months = months;
            this.years = years;
        }
    }
}