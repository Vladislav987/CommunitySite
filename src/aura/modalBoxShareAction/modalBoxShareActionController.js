({
    HideMe: function(cmp) {
        cmp.set("v.showPopUp", false);
    },

    handleYes :function (cmp,event,helper) {
        let parent = cmp.get("v.parent");
        parent.shareCostCenterMethod(cmp);
        cmp.set("v.showPopUp", false);

    }
});