({
    changeColor: function (cmp, event, helper) {
        let finItemsForUpdate = cmp.get("v.finItemsForUpdate");
        let indexVar = event.getSource();
        let finReportItem = event.getSource().get("v.name");
        var trigger = false;
        for (var i = 0; i < finItemsForUpdate.length; i ++) {
            if (finItemsForUpdate[i].Id == finReportItem.Id) {
                trigger = true;
                finItemsForUpdate[i].Sum__c = finReportItem.Sum__c;
            }
        }
        if (trigger == false) {
            finItemsForUpdate.push(finReportItem);
        }
        cmp.set("v.finItemsForUpdate",finItemsForUpdate);
        if (finReportItem.Previous_Financial_Report_Item__c != null || finReportItem.Previous_Financial_Report_Item__c != undefined) {
            if (finReportItem.Sum__c > finReportItem.Previous_Financial_Report_Item__r.Sum__c) {
                indexVar.set("v.style", "color:red;");
            } else if (finReportItem.Sum__c == finReportItem.Previous_Financial_Report_Item__r.Sum__c) {
                indexVar.set("v.style", "color:black;");
            } else {
                indexVar.set("v.style", "color:green;");
            }
        }
    },

    changeCurrency: function (cmp, event, helper) {
        var selectedBudget = event.getSource().get("v.name");
        var selectedCurrency = event.getSource().get("v.value");
        let itemsForAdd = [];
        for (var i = 0; i < selectedBudget.financialReportItems.length; i++) {
            selectedBudget.financialReportItems[i].CurrencyIsoCode = selectedCurrency;
            itemsForAdd.push(selectedBudget.financialReportItems[i]);
        }
        let appEvent = $A.get("e.c:updateCurrencyEvent");
        appEvent.setParams({ "finItemsForUpdate" : itemsForAdd});
        appEvent.fire();
    }

});