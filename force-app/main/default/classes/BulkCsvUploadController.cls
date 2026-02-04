public with sharing class BulkCsvUploadController {

    /**
     * Start a Bulk API 2.0 insert job for the CSV file the user just uploaded.
     *
     * @param contentDocumentId  The ContentDocumentId returned by <lightning-file-upload>
     * @param targetObjectApiName The API name of the object you want to insert (e.g. 'WorkOrder')
     */
    @AuraEnabled
    public static String startBulkInsert(String contentDocumentId, String targetObjectApiName) {
        if (String.isBlank(contentDocumentId)) {
            throw new AuraHandledException('No file Id received from the upload component.');
        }
        if (String.isBlank(targetObjectApiName)) {
            throw new AuraHandledException('Target object API name is required.');
        }

        // ---- 1. Fetch the latest version of the uploaded file safely ----
        List<ContentVersion> cvs = [
            SELECT VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            ORDER BY VersionNumber DESC
            LIMIT 1
        ];
        if (cvs.isEmpty()) {
            throw new AuraHandledException(
                'No ContentVersion found for ContentDocumentId: ' + contentDocumentId +
                '. Ensure the running user has access to the uploaded file.'
            );
        }

        // ---- 2. Convert the file Blob to CSV string ----
        String csvBody;
        try {
            csvBody = cvs[0].VersionData.toString();
        } catch (Exception e) {
            throw new AuraHandledException('Unable to read CSV file body: ' + e.getMessage());
        }

        // ---- 3. Call Bulk API 2.0 ----
        // Requires a Named Credential called 'Salesforce_Bulk_API' pointing to your org
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Salesforce_Bulk_API/services/data/v60.0/jobs/ingest');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        // Create job definition
        Map<String, Object> job = new Map<String, Object>{
            'object' => targetObjectApiName,
            'operation' => 'insert',
            'contentType' => 'CSV',
            'lineEnding' => 'LF'
        };
        req.setBody(JSON.serialize(job));

        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() >= 300) {
            throw new AuraHandledException('Failed to create Bulk API job: ' + res.getBody());
        }

        // Parse job id
        Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
        String jobId = (String)result.get('id');

        // ---- 4. Upload CSV to the job ----
        HttpRequest uploadReq = new HttpRequest();
        uploadReq.setEndpoint('callout:Salesforce_Bulk_API/services/data/v60.0/jobs/ingest/' + jobId + '/batches');
        uploadReq.setMethod('PUT');
        uploadReq.setHeader('Content-Type', 'text/csv');
        uploadReq.setBody(csvBody);
        HttpResponse uploadRes = http.send(uploadReq);
        if (uploadRes.getStatusCode() >= 300) {
            throw new AuraHandledException('Failed to upload CSV: ' + uploadRes.getBody());
        }

        // ---- 5. Close the job ----
        HttpRequest closeReq = new HttpRequest();
        closeReq.setEndpoint('callout:Salesforce_Bulk_API/services/data/v60.0/jobs/ingest/' + jobId);
        closeReq.setMethod('PATCH');
        closeReq.setHeader('Content-Type', 'application/json');
        closeReq.setBody('{"state":"UploadComplete"}');
        HttpResponse closeRes = http.send(closeReq);
        if (closeRes.getStatusCode() >= 300) {
            throw new AuraHandledException('Failed to close Bulk API job: ' + closeRes.getBody());
        }

        return 'Bulk insert job created successfully. Job Id: ' + jobId;
    }
}