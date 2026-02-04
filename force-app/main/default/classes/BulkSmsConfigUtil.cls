public class BulkSmsConfigUtil {
    
    public static Bulk_SMS_Config__mdt getBulkSmsConfig() {
        List<Bulk_SMS_Config__mdt> configs = [
            SELECT Endpoint__c, Sender__c, Api_Key__c, Is_Active__c
            FROM Bulk_SMS_Config__mdt 
            WHERE Is_Active__c = true 
            LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            throw new BulkSmsException('No active Bulk SMS configuration found');
        }
        
        return configs[0];
    }
    
    public class BulkSmsException extends Exception {}
}