public with sharing class TechnicianImageUploadController {
    @AuraEnabled
public static String saveIPDisconnectionDetails(String recordId, List<FileWrapper> listFiles) {

    System.debug('INSIDE PHOTOS::::');
    try {
        List<ContentVersion> contentVersions = new List<ContentVersion>();

        for (FileWrapper fw : listFiles) {
            ContentVersion cv = new ContentVersion();
            cv.Title = fw.label;
            cv.PathOnClient = fw.fileName;
            cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
            contentVersions.add(cv);
        }

        insert contentVersions;

        Map<Id, Id> versionToDocMap = new Map<Id, Id>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :contentVersions
        ]) {
            versionToDocMap.put(cv.Id, cv.ContentDocumentId);
        }

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Id versionId : versionToDocMap.keySet()) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = versionToDocMap.get(versionId),
                LinkedEntityId = recordId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }

        insert links;

        // ✅ Store metadata in custom Document__c
        List<Document__c> documentsToInsert = new List<Document__c>();
        for (Integer i = 0; i < contentVersions.size(); i++) {
            ContentVersion version = contentVersions[i];
            FileWrapper fw = listFiles[i];

            Id contentDocId = versionToDocMap.get(version.Id);
            if (contentDocId != null) {
    Document__c doc = new Document__c();
    doc.ContentDocumentId__c = contentDocId;
    doc.Work_Order__c = recordId;

    if (fw.latitude != null && fw.longitude != null) {
        doc.Location_IP_Disconnection__latitude__s = Decimal.valueOf(fw.latitude);
        doc.Location_IP_Disconnection__longitude__s = Decimal.valueOf(fw.longitude);
    }

    doc.Captured_Timestamp__c = fw.capturedTime;
    documentsToInsert.add(doc);
}


        }

        insert documentsToInsert;

        updateWorkStepStatus(recordId, 'Work Order Execution Detail');
        return 'Success';

    } catch(Exception e) {
        system.debug('Error ::'+ e.getMessage() + ' ' + e.getLineNumber());
        throw new AuraHandledException('Error saving image data: ' + e.getMessage());
    }
}

    
    public static void updateWorkStepStatus(Id workOrderId,String name){
        List<WorkStep> steps = [
			SELECT Id, Status
			FROM WorkStep
			WHERE ParentRecordId = :workOrderId
			AND Name = :name
			LIMIT 1
		];
        
        if (!steps.isEmpty()) {
            WorkStep ws = steps[0];
            ws.Status = 'Completed'; // Or whatever picklist value you use
            update ws;
        }
     }

	public class FileWrapper {
    @AuraEnabled public String base64Data { get; set; }
    @AuraEnabled public String fileName { get; set; }
    @AuraEnabled public String label { get; set; }

    @AuraEnabled public Double latitude { get; set; }
    @AuraEnabled public Double longitude { get; set; }
    @AuraEnabled public Datetime capturedTime { get; set; }
}

}