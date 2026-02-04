public class DocumentContentVersionHandler {
  
    public static void afterInsert(List<ContentVersion> newVersions) {

       if (newVersions == null || newVersions.isEmpty()) {
            return;
        }

        List<Document__c> documentsToInsert = new List<Document__c>();

        for (ContentVersion cv : newVersions) {

            // Safety checks
            if (cv.ContentDocumentId == null) continue;
            if (cv.Work_Order__c == null) continue;

            Document__c doc = new Document__c();
            doc.ContentVersion_ID__c   = cv.Id;
            doc.Content_Document_Id__c = cv.ContentDocumentId;
            doc.Work_Order__c          = cv.Work_Order__c;

            documentsToInsert.add(doc);
        }

        if (!documentsToInsert.isEmpty()) {
            insert documentsToInsert;
        } 
    } 
}