/**
 * Created by ArtemShevchenko on 08.11.2019.
 */

({
    createToast: function (component, event, title, type, msg) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type": type,
            "message": msg
        });
        toastEvent.fire();
    }
});