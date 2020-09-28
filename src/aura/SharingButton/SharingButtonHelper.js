/**
 * Created by ArtemShevchenko on 15.11.2019.
 */

({
    createToast: function(cmp, title, type, msg){
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type": type,
            "message": msg
        });
        toastEvent.fire();
    }
});