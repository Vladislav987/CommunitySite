/**
 * Created by ArtemShevchenko on 08.11.2019.
 */

({
    doInit: function (component, event, helper){
        let type = component.get("v.record").TargetObject.Type.split('__');
        let anotherType = type[0].split('_');
        let recordType = '';
        for(let word of anotherType){
            if(recordType.length === 0){
                recordType = word;
            } else {
                recordType += ' ' + word;
            }
        }
        component.set("v.type", recordType);
    },

    checkBoxController: function (component, event, helper) {
        let checked = event.getSource().get("v.checked");
        console.log(checked);
            let updateSelectedRecords = component.getEvent("RecordSelectorEvent");

            updateSelectedRecords.setParams({
                'selectedRecord': component.get("v.record")
            });
            updateSelectedRecords.fire();

    },
    navigateToRecord: function (component, event, helper){
        let navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.record.TargetObjectId"),
            "slideDevName": "related"
        });
        navEvt.fire();
    }
});