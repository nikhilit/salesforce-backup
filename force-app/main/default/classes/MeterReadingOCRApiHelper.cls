/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 21-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   16-06-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class MeterReadingOCRApiHelper {
    
    public static List<IntegrationLogHelper.IntegrationLogWrapper> listIntegrationLogWrap = new List<IntegrationLogHelper.IntegrationLogWrapper>();
    
    @future(callout=true)
    public static void checkOCRDocumentProcess(Set<Id> recordIds){
        
        Set<Id> setContVerIds=new Set<Id>();
        Map<Id,Id> mapRecordIdVSVersionId = new Map<Id,Id>();
        for(ContentDocumentLink contDocRec: [SELECT Id, LinkedEntityId, ContentDocumentId,ContentDocument.LatestPublishedVersionId
                                        FROM ContentDocumentLink 
                                        WHERE LinkedEntityId IN:recordIds AND ContentDocumentId!=null]){
             
            if(!mapRecordIdVSVersionId.containsKey(contDocRec.LinkedEntityId)){
                mapRecordIdVSVersionId.put(contDocRec.LinkedEntityId,contDocRec.ContentDocument.LatestPublishedVersionId);
            }
        }
        
        if(!mapRecordIdVSVersionId.values().isEmpty()){
            Map<Id,ContentVersion> mapContVersionIdVSVersion = new Map<Id,ContentVersion>([SELECT Id,ContentDocumentId,VersionData,Title,
                                                                                                PathOnClient,FileExtension 
                                                                                            FROM ContentVersion 
                                                                                            WHERE Id IN:mapRecordIdVSVersionId.values()]);
            
            List<Meter_Reading_OCR__c> meterReadingOCRToUpdate = new List<Meter_Reading_OCR__c>();
            for(Meter_Reading_OCR__c meterReadingOCRRec:[SELECT Id,BP_Number__c,Status__c,S3_Key__c,File_Name__c,Is_Domestic__c 
                                                        FROM Meter_Reading_OCR__c WHERE Id IN:recordIds]){
                
                if(mapRecordIdVSVersionId.containsKey(meterReadingOCRRec.Id)
                    && mapContVersionIdVSVersion.containsKey(mapRecordIdVSVersionId.get(meterReadingOCRRec.Id))){
                    
                    ContentVersion contentVersionRec=mapContVersionIdVSVersion.get(mapRecordIdVSVersionId.get(meterReadingOCRRec.Id));
                    //meterReadingOCRRec.File_Name__c=contentVersionRec.PathOnClient;
                    AWSS3FileUploadAPI.ResponseBodyWrapper responseData=AWSS3FileUploadAPI.getPresignedURL(meterReadingOCRRec.Id,meterReadingOCRRec.File_Name__c,meterReadingOCRRec.BP_Number__c,true,meterReadingOCRRec.Is_Domestic__c);
                    if(responseData!=null){
                        meterReadingOCRRec.S3_Key__c=responseData.s3Key;
                        Blob fileBlob = contentVersionRec.VersionData;
                        Map<String,Object> resultMap=AWSS3FileUploadAPI.sendDocument(meterReadingOCRRec.Id,responseData,fileBlob,contentVersionRec.FileExtension,true);
                        if(resultMap.get('status')=='success'){
                            meterReadingOCRRec.Status__c='Send';
                            meterReadingOCRRec.View_URL__c=responseData.viewURL;
                            meterReadingOCRRec.S3_Bucket_Name__c=responseData.bucket;
                        }else{
                            meterReadingOCRRec.Status__c='Failed';
                        }
                        meterReadingOCRToUpdate.add(meterReadingOCRRec);
                    }
                }
                listIntegrationLogWrap.addAll(AWSS3FileUploadAPI.listIntegrationLogWrap);
            }
            
            if(!meterReadingOCRToUpdate.isEmpty()){
                update meterReadingOCRToUpdate;
            }
        }
        
        if(!listIntegrationLogWrap.isEmpty()){
            IntegrationLogHelper.createListIntegrationLog(listIntegrationLogWrap);
        }
    }
    
}