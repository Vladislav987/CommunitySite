({
    handleCreateChatter : function(component, event) {
        component.set("v.body", []);
        let costCenterId = event.getParam("costCenterId");

        $A.createComponent(
        "forceChatter:publisher", {
            "context": "RECORD",
            "recordId": costCenterId
        },

        function(recordFeed) {
            if (component.isValid()) {
                var body = component.get("v.body");
                body.push(recordFeed);
                component.set("v.body", body);
            }
        });

        $A.createComponent(
        "forceChatter:feed", {
            "type": "Record",
            "subjectId": costCenterId
        },

        function(recordFeed) {
            if (component.isValid()) {
                var body = component.get("v.body");
                body.push(recordFeed);
                component.set("v.body", body);
            }
        });
    },

    pushChatterComponent : function(record) {
         if (component.isValid()) {
             var body = component.get("v.body");
             body.push(recordFeed);
             component.set("v.body", body);
         }
    },

    clearPreviousChatter : function(cmp) {
        console.log('clear method');
        component.set("v.body", []);
    },

    openForm: function (cmp) {
        document.getElementById("chatForm").style.display = "block";
        document.getElementById("chatterIcon").style.display = "none";
    },

    closeForm: function (cmp) {
        document.getElementById("chatForm").style.display = "none";
        document.getElementById("chatterIcon").style.display = "block";
    },


});