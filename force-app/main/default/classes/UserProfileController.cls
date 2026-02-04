public with sharing class UserProfileController {
    @AuraEnabled(cacheable=true)
    public static String getUserProfileName() {
        return [
            SELECT Profile.Name 
            FROM User 
            WHERE Id = :UserInfo.getUserId()
        ].Profile.Name;
    }
}