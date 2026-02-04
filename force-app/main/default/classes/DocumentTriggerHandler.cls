/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 21-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   04-07-2025   Kartik Patkar, Appstrail   Initial Version
**/
public with sharing class DocumentTriggerHandler {

    @TestVisible
    public static Boolean disableUploadsInTests = false;
    
    public static void afterInsert(List<Document__c> newList){
        checkUploadStatusChange(newList, null);
    }

    public static void afterUpdate(List<Document__c> newList, Map<Id, Document__c> oldMap){
        checkUploadStatusChange(newList, oldMap);
    }

    public static void checkUploadStatusChange(List<Document__c> newList, Map<Id, Document__c> oldMap){
        Set<Id> docIds = new Set<Id>();
        for(Document__c doc : newList){
            if(doc.Upload_Status__c=='Pending' && (oldMap==null || doc.Upload_Status__c!=oldMap.get(doc.Id).Upload_Status__c)){
                docIds.add(doc.Id);
            }
        }

        if (!docIds.isEmpty()) {
            if (Test.isRunningTest() && disableUploadsInTests) return; 
            checkDocumentUpload(docIds); 
        }
    }

    @future(callout=true)
    public static void checkDocumentUpload(Set<Id> recordIds){
        Set<Id> setContVerIds=new Set<Id>();
        Map<Id,Id> mapRecordIdVSVersionId = new Map<Id,Id>();
        
        List<IntegrationLogHelper.IntegrationLogWrapper> listIntegrationLogWrap = new List<IntegrationLogHelper.IntegrationLogWrapper>();
        if (!recordIds.isEmpty()) {
            for(ContentDocumentLink contDocRec: [SELECT Id, LinkedEntityId, ContentDocumentId,ContentDocument.LatestPublishedVersionId
                                                FROM ContentDocumentLink 
                                                WHERE LinkedEntityId IN:recordIds AND ContentDocumentId!=null]){
                
                if(!mapRecordIdVSVersionId.containsKey(contDocRec.LinkedEntityId)){
                    mapRecordIdVSVersionId.put(contDocRec.LinkedEntityId,contDocRec.ContentDocument.LatestPublishedVersionId);
                }
            }
        }
        
        if(!mapRecordIdVSVersionId.values().isEmpty()){
            Map<Id,ContentVersion> mapContVersionIdVSVersion = new Map<Id,ContentVersion>([SELECT Id,ContentDocumentId,VersionData,Title,
                                                                                                PathOnClient,FileExtension 
                                                                                            FROM ContentVersion 
                                                                                            WHERE Id IN:mapRecordIdVSVersionId.values()]);

            List<Document__c> documentToUpdate = new List<Document__c>();
            for(Document__c docRec:[SELECT Id,BP_Number__c,Upload_Status__c,S3_Key__c,File_Name__c 
                                                FROM Document__c WHERE Id IN:recordIds]){
                
                if(mapRecordIdVSVersionId.containsKey(docRec.Id)
                    && mapContVersionIdVSVersion.containsKey(mapRecordIdVSVersionId.get(docRec.Id))){
                    
                    ContentVersion contentVersionRec=mapContVersionIdVSVersion.get(mapRecordIdVSVersionId.get(docRec.Id));
                    docRec.File_Name__c=contentVersionRec.PathOnClient;
                    AWSS3FileUploadAPI.ResponseBodyWrapper responseData=AWSS3FileUploadAPI.getPresignedURL(docRec.Id,docRec.File_Name__c,docRec.BP_Number__c,false,false);
                    if(responseData!=null){
                        docRec.S3_Key__c=responseData.s3Key;
                        Blob fileBlob = contentVersionRec.VersionData;
                        Map<String,Object> resultMap=AWSS3FileUploadAPI.sendDocument(docRec.Id,responseData,fileBlob,contentVersionRec.FileExtension,false);
                        if(resultMap!=null && resultMap.get('status')=='success'){
                            docRec.View_URL__c=responseData.viewURL;
                            docRec.S3_Bucket_Name__c=responseData.bucket;
                            docRec.Upload_Status__c='Uploaded';
                        }else{
                            docRec.Upload_Status__c='Failed';
                        }
                        documentToUpdate.add(docRec);
                    }
                }
                listIntegrationLogWrap.addAll(AWSS3FileUploadAPI.listIntegrationLogWrap);
            }
            
            if(!documentToUpdate.isEmpty()){
                update documentToUpdate;
            }
        }
        
        if(!listIntegrationLogWrap.isEmpty()){
            IntegrationLogHelper.createListIntegrationLog(listIntegrationLogWrap);
        }
        
    }
}