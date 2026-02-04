({
    init : function(component, event, helper) {
        var action = component.get("c.generateAndAttachPDFs");
        var selectedRecords = component.get("v.recordIds");
        action.setParams({ workOrderIds: selectedRecords });

        action.setCallback(this, function(response) {
            var state = response.getState();
            var toast = component.find("notifLib");

            if (state === "SUCCESS") {
                toast.showToast({
                    "variant": "success",
                    "title": "Success",
                    "message": "PDFs generated and attached to records."
                });
            } else {
                toast.showToast({
                    "variant": "error",
                    "title": "Error",
                    "message": "An error occurred while generating PDFs."
                });
            }

            $A.get("e.force:closeQuickAction").fire();
        });

        $A.enqueueAction(action);
    }
})