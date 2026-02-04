({
    startFlow : function(component, event, helper) {
        var flow = component.find("flowData");
        
        var inputVariables = [
            {
                name : "recordId",
                type : "String",
                value : component.get("v.recordId")
            }
        ];

        flow.startFlow("UploadTBTDocument", inputVariables);
    }
})