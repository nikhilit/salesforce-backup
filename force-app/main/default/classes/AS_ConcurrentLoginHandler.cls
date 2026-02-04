public with sharing class AS_ConcurrentLoginHandler {

    public class LoginInput {
        @InvocableVariable(required = true)
        public Id userId;
    }

    public class LoginOutput {
        @InvocableVariable
        public Boolean allowLogin;
        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label = 'Check Concurrent Login')
    public static List<LoginOutput> checkConcurrentLogin(List<LoginInput> inputs) {
        List<LoginOutput> results = new List<LoginOutput>();

        for (LoginInput input : inputs) {
            LoginOutput resp = new LoginOutput();
            resp.allowLogin = true;
            resp.message = '';

            // Fetch user info with the restriction flag
            User currentUser = [
                SELECT Id, Username, Enable_Concurrent_Login_Restriction__c
                FROM User
                WHERE Id = :input.userId
                LIMIT 1
            ];

            // Check restriction only if enabled
            if (currentUser.Enable_Concurrent_Login_Restriction__c == true) {
                // Fetch active UI or App sessions
                List<AuthSession> activeSessions = [
                    SELECT Id, CreatedDate
                    FROM AuthSession
                    WHERE UsersId = :input.userId
                    AND SessionType IN ('UI', 'App', 'ChatterNetworks')
                ];

                // Allow first session, block if already logged in elsewhere
                if (activeSessions.size() > 1) {
                    resp.allowLogin = false;
                    resp.message = 'Concurrent login not allowed. You are already logged in on another device.';
                }
            }

            results.add(resp);
        }

        return results;
    }
}