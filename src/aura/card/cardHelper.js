/**
 * Created by Ponomarov Vladyslav on 06.06.2019.
 */

({
    deleteCard: function (component) {
        var action = component.get("c.deleteCard");
        var card = component.get('v.card');
            action.setParams({'card':card});
            action.setCallback(this,  function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.getEvent('deleteCard').fire();
                }
            });


        $A.enqueueAction(action);
    },
    handleChangeColumn: function (component, event) {
        var action = component.get('c.changeColumn');
        var card = component.get('v.card');
        var columnName = event.getParam('value');

        action.setParams({'card': card,
                            'columnId': columnName});
        action.setCallback(this,  function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("SUCCESS");
                component.getEvent('deleteCard').fire();
            }else {
                console.log("error");

            }
        });


        $A.enqueueAction(action);

    },
});