({

    handleYES : function(component, event, helper) {
        console.log('Yes');
        let parent = component.get("v.parent");
        parent.deleteDraft();
        component.set('v.showDeleteConfirmPopUp', false);
    },

    handleNO : function(component, event, helper) {
        console.log('No');
        component.set('v.showDeleteConfirmPopUp', false);
    },
});