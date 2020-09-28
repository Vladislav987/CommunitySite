/**
 * Created by Ponomarov Vladyslav on 05.06.2019.
 */

({
    getColumnsList: function (component, event, helper) {
        var action = component.get("c.getColumnsList");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.columns", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
});