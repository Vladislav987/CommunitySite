/**
 * Created by MaxymMirona on 02.06.2020.
 */

({
    recalculateInvoice : function (component, event) {
        component.set("v.loading", true);

        let action = component.get("c.recalculateBudgetTransaction");

        action.setParams({
            recordId : component.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            let state = response.getState();
            let result = response.getReturnValue();
            let resultMessage = result.resultMessage;

            if (state === "SUCCESS") {
                if (result.isSuccessful){
                    this.showToast('Success', 'success', resultMessage);
                } else {
                    this.showToast('Error', 'error', resultMessage);
                }
            } else {
                this.showToast('Error', 'error', resultMessage);
            }

            component.set("v.loading", false);
            $A.get("e.force:closeQuickAction").fire();
        });

        $A.enqueueAction(action);
    },

    showToast : function (title, type, message) {
        let toastEvent = $A.get("e.force:showToast");

        if (toastEvent){
            toastEvent.setParams({
                "title": title,
                "message": message == null ? 'Unexpected error' : message,
                "type" : type
            });

            toastEvent.fire();
        }
    }
});