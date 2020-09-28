/**
 * Created by Ponomarov Vladyslav on 06.06.2019.
 */

({
    handleSelect: function(component, event, helper) {
        helper.deleteCard(component);
    },
    handleChangeColumn: function (component, event, helper) {
        helper.handleChangeColumn(component, event);
    },
});