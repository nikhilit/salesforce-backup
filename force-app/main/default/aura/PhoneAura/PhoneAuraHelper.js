({
    startPolling : function(component) {

        console.log("⏳ Polling started...");

       /* window.setInterval($A.getCallback(() => {
            this.checkForNewCalls(component);
        }), 7000);*/
    },


    checkForNewCalls : function(component) {

        const agentId = component.get("v.currentUserAgentId");

        if (!agentId) {
            console.warn("⚠ Agent ID missing. Poll skipped.");
            return;
        }

        console.log("🔄 Checking for new inbound calls for:", agentId);

        const action = component.get("c.getLatestInboundCall");
        action.setParams({ agentId: agentId });

        action.setCallback(this, (response) => {

            const state = response.getState();
            console.log("⬅ Poll Response:", state);

            if (state !== "SUCCESS") {
                console.error("❌ Apex error:", JSON.stringify(response.getError()));
                return;
            }

            const callRecord = response.getReturnValue();
            console.log("📞 Call Record:", callRecord);

            if (!callRecord) {
                console.log("ℹ No new calls for this agent.");
                return;
            }

            const phone = callRecord.PhoneNumber__c;
            console.log("📱 Phone:", phone);

            // Query accounts
            const accAction = component.get("c.getAccountIdByPhone");
            accAction.setParams({ phone: phone, agentId: agentId });

            accAction.setCallback(this, (resp) => {

                const accState = resp.getState();
                console.log("⬅ Account Lookup Response:", accState);

                if (state === "SUCCESS") {
                const accounts = resp.getReturnValue();
                console.log("⬅ accounts:", accounts);
               /* if ((accounts && accounts.length > 1)||accounts.length ==0) {
                    const navEvt = $A.get("e.force:navigateToURL");
                    navEvt.setParams({
                        "url": "/lightning/n/CIC0?c__teleNumber=" + encodeURIComponent(phone)
                    });
                    navEvt.fire();
                }
                else if(accounts && accounts.length ==1){
                    const accountId = accounts[0].Id; 
                    const navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        recordId: accountId,
                        slideDevName: "related"
                    });
                    navEvt.fire();
                } */
                if ((accounts && accounts.length > 1)||accounts.length ==0) {
    const navEvt = $A.get("e.force:navigateToURL");
    navEvt.setParams({
        "url": "/lightning/n/CIC0?c__teleNumber=" + encodeURIComponent(phone)
    });
    navEvt.fire();
}
else if (accounts && accounts.length ==1) {
    const accountId = accounts[0].Id; 
    const navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
        recordId: accountId,
        slideDevName: "related"
    });
    navEvt.fire();
}
            } else {
                helper.showToast("Failed to call Apex: " + response.getError()[0].message, "error");
            }

                // Mark call as SHOWN
                this.markCallAsShown(component, callRecord.Id);
            });

            $A.enqueueAction(accAction);
        });

        $A.enqueueAction(action);
    },


    markCallAsShown : function(component, callId) {
        console.log("📝 Marking call as Shown:", callId);

        const action = component.get("c.markCallAsShown");
        action.setParams({ callId: callId });

        $A.enqueueAction(action);
    },


    showToast : function(message, type) {
        const toast = $A.get("e.force:showToast");
        toast.setParams({
            title: type === "error" ? "Error" : "Info",
            message: message,
            type: type
        });
        toast.fire();
    }
})