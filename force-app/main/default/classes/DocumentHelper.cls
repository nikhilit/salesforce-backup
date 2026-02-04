/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 06-10-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   18-07-2025   Kartik Patkar, Appstrail   Initial Version
**/
public with sharing class DocumentHelper {
    
    public static String generateDocumentKey(String meterDocNo, String bpNumber, Datetime billDate, String workOrderNumber) {
        // Determine the primary ID (Meter Doc No or Work Order No)
        String primaryId;
        if (String.isNotBlank(meterDocNo)) {
            primaryId = meterDocNo;
        } else if (String.isNotBlank(workOrderNumber)) {
            primaryId = workOrderNumber;
        } else {
            primaryId = '';
        }

        // BP Number fallback
        String safeBpNumber = String.isNotBlank(bpNumber) ? bpNumber : '';

        // Bill Date formatting
        String formattedBillDate = (billDate != null) ? billDate.format('dd.MM.yyyy') : '';

        // System Timestamp (always present)
        String timestamp = Datetime.now().format('yyyyMMddHHmmssSSS');

        // Final key
        return String.join(new List<String>{primaryId, safeBpNumber, formattedBillDate, timestamp}, '_');
    }
}