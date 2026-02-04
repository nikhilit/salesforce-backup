/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 19-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   19-11-2025   Kartik Patkar, Appstrail   Initial Version
**/
public with sharing class CameraUploadTestController {
    public CameraUploadTestController() {
        
    }
    
    @AuraEnabled
    public static string getImageURL(String albumId){
        try {
            String token = sharinpix.Client.getInstance().token(
                new Map<String, Object> {
                    'user_id' => UserInfo.getUserId(),
                    'email' => UserInfo.getUserEmail(),
                    'name' => '',
                    'album_id' => albumId,
                    'exp' => 0 //the value 0 means non expiring token
                }
            );

            return token;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // public static String generateMobileUploadToken(Id recordId, String permissionId) {

    //     // 1. Query Album for the record
    //     sharinpix__Album__c album = [
    //         SELECT Id 
    //         FROM sharinpix__Album__c 
    //         WHERE sharinpix__Salesforce_Id__c = :recordId
    //         LIMIT 1
    //     ];

    //     // 2. Generate token using SharinPix generator
    //     String token = sharinpix__SharinPixTokenGenerator.generateToken(
    //         permissionId,
    //         album.Id
    //     );

    //     return token;
    // }
}