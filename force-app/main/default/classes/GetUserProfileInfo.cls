public without sharing class GetUserProfileInfo {
    @AuraEnabled(cacheable=true)
    public static String getCurrentUserProfileName() {
        try {
            System.debug('insideProfile');
            // Query the current user's Profile Name
            return [
                SELECT Profile.Name
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ].Profile.Name;
        } catch (Exception e) {
            // Log and handle any errors gracefully
            System.debug('Error fetching profile name: ' + e.getMessage());
            return null;
        }
    }
}