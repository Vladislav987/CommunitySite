/**
 * Created by sh on 2019-03-19.
 */
({
    request : function(component, event){ 
        var args= event.getParam("arguments");
        if($A.util.isEmpty(args.actionName)){
            throw "Action name is not populated";
        }
        var request = component.get("v.context").get(args.actionName);
        if(!$A.util.isEmpty(args.params)){
            request.setParams(args.params);
        }
        if(args.isBackground === "true"){
            request.setBackground(true);
        }
        return new Promise((resolve, reject) => {
            if(component.get("v.body").length > 0){
                component.set("v.isSpinnerEnabled", true);
            }
            request.setCallback(this, (response) => {
                if(response.getState() == "SUCCESS"){
                    resolve(response.getReturnValue());
                }else{
                    console.log(this.PromiseRejectReactions);
                    let errors = response.getError().map(e => e.message);
                    reject(errors);
                }
                component.set("v.isSpinnerEnabled", false);
            })
            $A.enqueueAction(request);
        });
    }
})