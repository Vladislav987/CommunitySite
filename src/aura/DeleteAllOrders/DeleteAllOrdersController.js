({
    deleteAll: function (component, event, helper) {
        var action = component.get("c.deleteAllrecords");
        action.setCallback(this, function (response) {
        });
        $A.enqueueAction(action);
    }
})