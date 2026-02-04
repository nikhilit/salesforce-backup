/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 07-07-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   07-07-2025   Kartik Patkar, Appstrail   Initial Version
**/
public with sharing class DocumentUpdateAndFileDeletionBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    public String query='SELECT Id, BP_Number__c, Upload_Status__c, Work_Order__c FROM Document__c '+
                        'WHERE Upload_Status__c = \'Draft\' AND BP_Number__c!=null AND Work_Order__c!=null';

    public DocumentUpdateAndFileDeletionBatch() {}
    
    public DocumentUpdateAndFileDeletionBatch(String query) {
        this.query = query;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Document__c> scope) {
        updateDocumentStatus(scope);
    }
    
    public void finish(Database.BatchableContext BC) {
        // Optional: Add any post-processing logic here
    }

    public void updateDocumentStatus(List<Document__c> listDocuments){
        for(Document__c document : listDocuments){
            document.Upload_Status__c = 'Pending';
        }

        if(!listDocuments.isEmpty()){
            update listDocuments;
        }
    }
    
     
    
}