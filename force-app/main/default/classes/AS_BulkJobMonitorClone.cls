public without sharing class AS_BulkJobMonitorClone {
    
    private static final String NAMED_CRED = 'Salesforce_Internal';
    private static final String API_VERSION = '62.0';
    
    @AuraEnabled
    public static Map<String,Object> pollJobProgress(Id bulkImportId) {
        Map<String,Object> resultMap = new Map<String,Object>();
        
        try {
            list<BulkImportStatus__c> recList = [
                SELECT Id, BatchJobId__c, Status__c, ContentVersionId__c,
                       Success_Count__c, Processed_Rows__c, Total_Rows__c
                FROM BulkImportStatus__c
                WHERE Id = :bulkImportId
                LIMIT 1
            ];
            
            if (recList.isEmpty()) throw new AuraHandledException('BulkImportStatus__c record not found');
            
            BulkImportStatus__c rec = recList[0];
            
            if (String.isBlank(rec.BatchJobId__c)) {
                resultMap.put('status','IN_PROGRESS');
                resultMap.put('progress',0);
                resultMap.put('message','Batch Job not yet started');
                return resultMap;
            }
            
            // Fetch job info from Bulk API 2.0
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:' + NAMED_CRED + '/services/data/v' + API_VERSION + '/jobs/ingest/' + rec.BatchJobId__c);
            req.setMethod('GET');
            req.setHeader('Content-Type','application/json');
            
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() != 200) throw new AuraHandledException(res.getBody());
            
            Map<String,Object> job = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
            String jobState = String.valueOf(job.get('state'));
            
            Decimal total = rec.Total_Rows__c != null ? rec.Total_Rows__c : (job.containsKey('numberRecordsTotal') ? Decimal.valueOf(String.valueOf(job.get('numberRecordsTotal'))) : 0);
            Decimal processed = job.containsKey('numberRecordsProcessed') ? Decimal.valueOf(String.valueOf(job.get('numberRecordsProcessed'))) : 0;
            Decimal failed = job.containsKey('numberRecordsFailed') ? Decimal.valueOf(String.valueOf(job.get('numberRecordsFailed'))) : 0;
            Decimal success = job.containsKey('numberRecordsProcessed') ? Decimal.valueOf(String.valueOf(job.get('numberRecordsProcessed'))) : 0;
            
            Decimal progress = total > 0 ? (processed / total) * 100 : 0;
            
            resultMap.put('status', jobState);
            resultMap.put('progress', progress.setScale(2));
            resultMap.put('message','Processed ' + processed + ' of ' + total + ' records');
            //resultMap.put('message','Processed ' + processed);
            
            Boolean allProcessed = (total > 0 && processed == total);
            
            // ✅ Update BulkImportStatus record if job finished
            if (new List<String>{'JobComplete','Failed','Aborted'}.contains(jobState)) {
                
                rec.Status__c = allProcessed && jobState == 'JobComplete' ? 'JobComplete' : jobState;
                rec.Processed_Rows__c = processed;
                rec.Success_Count__c = processed - failed;
                rec.Total_Rows__c = total;
                
                // ⚠️ If job failed, fetch failed results
                if (jobState == 'Failed' || failed > 0) {
                    String failedUri = '/services/data/v' + API_VERSION + '/jobs/ingest/' + rec.BatchJobId__c + '/failedResults/';
                    HttpRequest failReq = new HttpRequest();
                    failReq.setEndpoint('callout:' + NAMED_CRED + failedUri);
                    failReq.setMethod('GET');
                    failReq.setHeader('Content-Type','text/csv');
                    
                    HttpResponse failRes = new Http().send(failReq);
                    if (failRes.getStatusCode() == 200) {
                        String csv = failRes.getBody();
                        Blob csvBlob = Blob.valueOf(csv);
                        ContentVersion cv = new ContentVersion(
                            Title = 'Bulk_Failed_Results_' + Datetime.now().format('yyyyMMdd_HHmmss'),
                        PathOnClient = 'failed_results.csv',
                        VersionData = csvBlob,
                        FirstPublishLocationId = rec.Id
                            );
                        insert cv;
                        rec.Failure_Count__c = failed;
                        rec.Error__c = csv.length() > 32000 ? csv.substring(0, 32000) : csv;
                    }
                }
                
                update rec;
                resultMap.put('progress', 100);
                resultMap.put('message', 'Processed ' + processed + ' of ' + total + ' records');
            }
            
        }catch(AuraHandledException ahe) {
            System.debug('pollJobProgress Exception: ' + ahe.getMessage());
            System.debug('pollJobProgress Exception Line: ' + ahe.getLineNumber());
            AS_ErrorLogger.log('AS_BulkJobMonitorClone', 'pollJobProgress', ahe, bulkImportId);
            throw ahe;
        }
        catch(Exception e) {
            System.debug('pollJobProgress Exception: ' + e.getMessage());
            System.debug('pollJobProgress Exception Line: ' + e.getLineNumber());
            AS_ErrorLogger.log('AS_BulkJobMonitorClone', 'pollJobProgress', e, bulkImportId);
            
            throw new AuraHandledException(e.getMessage());
            
            // resultMap.put('status','ERROR');
            // resultMap.put('progress',0);
            // resultMap.put('message','Error: ' + e.getMessage());
        }
        
        return resultMap;
    }
    
}