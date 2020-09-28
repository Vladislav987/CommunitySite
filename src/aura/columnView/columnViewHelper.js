/**
 * Created by Ponomarov Vladyslav on 04.06.2019.
 */

({
    getCardsList: function (component, event, helper) {
        var action = component.get("c.getCardsList");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.cards", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
});