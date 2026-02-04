({
    doInit : function(component, event, helper) {

        console.log("🔥 doInit started");

        // 1. Get Current User Agent ID
        const action = component.get("c.getCurrentUserAgentId");
        console.log("➡ Calling Apex: getCurrentUserAgentId");

        action.setCallback(this, function(response) {
            const state = response.getState();
            const userAgentId = response.getReturnValue();

            console.log("⬅ Response:", state, userAgentId);

            if (state === "SUCCESS") {
                component.set("v.currentUserAgentId", userAgentId);
                console.log("✅ Logged in Agent ID:", userAgentId);

                // Start Polling AFTER user ID is known
                helper.startPolling(component);

            } else {
                console.error("❌ Error:", JSON.stringify(response.getError()));
            }
        });

        $A.enqueueAction(action);

        console.log("🏁 doInit completed");
    }
});