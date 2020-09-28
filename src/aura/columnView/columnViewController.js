/**
 * Created by Ponomarov Vladyslav on 04.06.2019.
 */

({

    doInit: function(component, event, helper){
        helper.getCardsList(component);
    },
    showModalWindow: function (component) {
        component.set('v.showModalWindow', true);
    },


})