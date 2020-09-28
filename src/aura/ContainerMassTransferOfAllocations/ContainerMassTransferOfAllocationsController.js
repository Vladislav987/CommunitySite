/**
 * Created by Ponomarov Vladyslav on 03.06.2020.
 */

({
    closeMethodInAuraController : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
});