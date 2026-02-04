/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 12-07-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   19-05-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class CustomerAddressUpdateContr {
    @AuraEnabled
    public static Account getBusinessPartner(String recordId){
        List<WorkOrder> listWorkOrders=[SELECT Id,AccountId FROM WorkOrder WHERE Id=:recordId LIMIT 1];
        if(!listWorkOrders.isEmpty()){
            Account accRecord=[Select id,Flat__c,Floor__c,Wing__c,Plot__c,Colony__c,Road_name__c,Location__c,Building_name__c,
                                Society_Name__c,FirstName__c,LastName__c,BP_Number__c 
                                from Account where Id=:listWorkOrders[0].AccountId];
            return accRecord;
        }
        return null;
        
    }
    
    
    @AuraEnabled
    public static List<ContentVersion> getContentVersion(){
        
        return [Select Id, ContentDocumentId, Document_Type__c from ContentVersion where Document_Type__c !=null ORDER BY Document_Type__c ASC];
    }
    
    @AuraEnabled()
    public static List<OptionsWrapper> fieldPicklistValue(String objectName,String fieldName){
        List<OptionsWrapper> optionList=new List<OptionsWrapper>();
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName) ;
        Schema.DescribeSObjectResult r = s.getDescribe();
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            OptionsWrapper option=new OptionsWrapper();
            option.label=pickListVal.getLabel();
            option.value=pickListVal.getValue();
            optionList.add(option);
        }
        return optionList;
    }
    
    public class OptionsWrapper{
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String value{get;set;}
    }
    
    
    
    @AuraEnabled
    public static String uploadFiles(string recordId, List<string> fileName, List<string> base64Data, string flat, string floor,
    string wing, string plot, string colony, string roadName, string location, string buildName, string societyName,
    string customerName, string bpNumber, string remark, String workOrderId) {
        
        try {
            system.debug('inside upload file apex class');
            
            
            // Account updateAccount = [Select id,Flat__c,Floor__c,Wing__c,Plot__c,Colony__c,Road_name__c,Location__c,Building_name__c,
            //                             Society_Name__c,FirstName__c,LastName__c,BP_Number__c,Remark__c 
            //                         from Account where Id=:recordId];
            
            List<WorkOrder> listWorkOrders=[SELECT Id,Old_Flat__c,Old_Floor__c,Old_Wing__c,Old_Plot__c,Old_Colony__c,Old_Road_Name__c,
                                                Old_Location__c,Old_Building_Name_Prem__c,Old_Society_Name__c,Old_Customer_Name__c,
                                                Neighbour_BP_Number__c,New_Flat__c,New_Floor__c,New_Wing__c,New_Plot__c,New_Colony__c,
                                                New_Road_Name__c,New_Location__c,New_Building_Name_Prem__c,New_Society_Name__c,New_Customer_Name__c,
                                                AccountId,Account.Flat__c,Account.Floor__c,Account.Wing__c,Account.Plot__c,Account.Colony__c,
                                                Account.Road_Name__c,Account.Location__c,Account.Building_name__c,Account.Society_Name__c,
                                                Account.FirstName__c,Account.LastName__c,Account.BP_Number__c
                                            FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
            
            if(!listWorkOrders.isEmpty()){
                WorkOrder workRec = listWorkOrders[0];
                if(workRec.AccountId != null){
                    workRec.Old_Flat__c = workRec.Account.Flat__c;
                    workRec.Old_Floor__c = workRec.Account.Floor__c;
                    workRec.Old_Wing__c = workRec.Account.Wing__c;
                    workRec.Old_Plot__c = workRec.Account.Plot__c;
                    workRec.Old_Colony__c = workRec.Account.Colony__c;
                    workRec.Old_Road_Name__c = workRec.Account.Road_Name__c;
                    workRec.Old_Location__c = workRec.Account.Location__c;
                    workRec.Old_Building_Name_Prem__c = workRec.Account.Building_name__c;
                    workRec.Old_Society_Name__c = workRec.Account.Society_Name__c;
                    workRec.Old_Customer_Name__c = workRec.Account.FirstName__c+' '+workRec.Account.LastName__c;
                }
                
                workRec.New_Flat__c  = String.isNotBlank(flat)? flat: '';
                workRec.New_Floor__c  = String.isNotBlank(floor)? floor: '';
                workRec.New_Wing__c = String.isNotBlank(wing)? wing : '';
                workRec.New_Plot__c= String.isNotBlank(plot)? plot: '';
                workRec.New_Colony__c= String.isNotBlank(colony) ? colony: '';
                workRec.New_Road_Name__c= String.isNotBlank(roadName)? roadName: '';
                workRec.New_Location__c= String.isNotBlank(location)? location: '';
                workRec.New_Building_Name_Prem__c = String.isNotBlank(buildName) ? buildName: '';
                workRec.New_Society_Name__c = String.isNotBlank(societyName) ? societyName: '';
                workRec.New_Customer_Name__c = String.isNotBlank(customerName)? customerName : '';
                workRec.Neighbour_BP_Number__c = String.isNotBlank(bpNumber) ? bpNumber : '';
                workRec.Update_Address_Remark__c = String.isNotBlank(remark) ? remark : '';
                update workRec;
                
                updateWorkStepStatus(workOrderId, Label.Update_Customer_Address_Step_Name);
                
                List<ContentVersion> lstContentVersion = new List<ContentVersion>();
                List<ContentDocumentLink> lstContentDocumentLink = new List<ContentDocumentLink>();
                
                for (Integer i = 0; i < fileName.size(); i++) {
                    String name = fileName[i];
                    String base64 = base64Data[i];
                    Blob fileBlob = EncodingUtil.base64Decode(base64);
                    
                    
                    ContentVersion cv = new ContentVersion();
                    cv.Title = name;
                    cv.PathOnClient = name;
                    cv.VersionData = fileBlob;
                    System.debug('CV::::'+ cv);
                    lstContentVersion.add(cv);
                    
                    
                }
                
                if(!lstContentVersion.isEmpty()){
                    system.debug('ContentVersion::'+ lstContentVersion);
                    insert lstContentVersion;

                    Set<Id> contentVersionIds = new Set<Id>();
                    for (ContentVersion insertedCV : lstContentVersion) {
                        contentVersionIds.add(insertedCV.Id);
                    }
                    
                    for (ContentVersion insertedCV : [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN: contentVersionIds]) {
                        // ContentDocument cd = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :insertedCV.Id LIMIT 1];
                        
                        ContentDocumentLink link = new ContentDocumentLink();
                        link.ContentDocumentId = insertedCV.ContentDocumentId;
                        link.LinkedEntityId = workRec.Id; // Assuming you want to link it to the Work Order
                        link.ShareType = 'I';
                        lstContentDocumentLink.add(link);
                    }
                    
                    if(!lstContentDocumentLink.isEmpty()){
                        system.debug('ContentDocumentLink::::'+ lstContentDocumentLink);
                        
                        insert lstContentDocumentLink;
                        return 'success';
                    }
                }
                
                
            }
            
            // updateAccount.Remark__c = String.isNotBlank(remark)     ? remark : updateAccount.Remark__c;
            
            // update updateAccount;
            
            return 'error';
            
        } catch (Exception e) {
            System.debug('error'+e.getMessage()+e.getLineNumber());
            throw new AuraHandledException('Exception::' + e.getMessage() + '\nGet Line Number' + e.getLineNumber());
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
}