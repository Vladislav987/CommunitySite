/**
 * Created by Mychailo Hamdzii on 16.04.2019.
 */
({
    doInit: function(component, event, helper) {
        helper.init(component);
    },

    onReportGenerationStart: function(component, event, helper) {
        let months = component.find("months").get("v.value");
        let years = component.find("years").get("v.value");
        if (months.length === 1 && years.length === 1) {
            helper.generateReport(component, months, years);
        } else {
            helper.showNotif(
                component,
                false,
                'Sorry',
                'Sorry, but you can create reports only with single Option for month/year',
                'error')
        }
    }
})