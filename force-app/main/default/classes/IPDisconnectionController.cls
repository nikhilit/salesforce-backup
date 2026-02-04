public without sharing class IPDisconnectionController {

    @AuraEnabled
    public static string getBPMeterNumber(string recordId){

        try {

        WorkOrder wo = [Select id,AccountId from WorkOrder where id=: recordId];

        Account acc = [Select id,Meter_Number__c from Account where id=: wo.AccountId];

        return acc.Meter_Number__c;
        }
        catch(Exception e){

            system.debug('Error ::'+ e.getLineNumber() + e.getMessage());
            return 'Error';
        }
    }

    @AuraEnabled
public static void saveDisconnectionDetails(
    string workOrderId,
    String meterNumber,
    String finalReading,
    String plugFromValue,
    String finalRemarks,
    String remarksText,
    String meterMake,
  String gasLeakageStatus,List<FileWrapper> listFiles


) {
    System.debug('workOrderId: ' + workOrderId);
    System.debug('meterNumber: ' + meterNumber);
    System.debug('finalReading: ' + finalReading);
    System.debug('plugFromValue: ' + plugFromValue);
    System.debug('finalRemarks: ' + finalRemarks);
    System.debug('remarksText: ' + remarksText);

    if (String.isBlank(workOrderId)) {
        throw new AuraHandledException('Work Order Id is required.');
    }

    WorkOrder wo = [
        SELECT Id, Meter_Number__c,Final_Meter_Reading__c,Plug_From__c, Final_Remark__c,Reason_Other_Remark__c,New_Meter_Make__c,
        Ensure_No_Gas_Leakage_Before_LeavingSit__c,Check_Customer_Availability__c
        FROM WorkOrder WHERE Id = :workOrderId LIMIT 1
    ];

    try {
        if (!String.isBlank(meterNumber)) {
            wo.Meter_Number__c = Decimal.valueOf(meterNumber);
        }

        if (!String.isBlank(finalReading)) {
            wo.Final_Meter_Reading__c = Decimal.valueOf(finalReading);
             

        }

        wo.Plug_From__c = plugFromValue;
        wo.Final_Remark__c = finalRemarks;
        wo.New_Meter_Make__c  = meterMake; // <-- SAVE HERE
        wo.Check_Customer_Availability__c='Yes';
          if (!String.isBlank(gasLeakageStatus)) {
                wo.Ensure_No_Gas_Leakage_Before_LeavingSit__c = gasLeakageStatus;
            }

        if (finalRemarks == 'Other' && !String.isBlank(remarksText)) {
            wo.Reason_Other_Remark__c = remarksText;
        }

        update wo;

         List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            for (FileWrapper fw : listFiles) {

                  if(fw.base64Data !=''){

              system.debug('inside listfile found');

                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName +'.jpg';
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                contentVersions.add(cv);
            }
            }
            
            insert contentVersions;
            
            // Map ContentVersion Id to ContentDocumentId
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :contentVersions
        ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
            }
            
            // Create ContentDocumentLinks to associate files with the given record
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                LinkedEntityId = workOrderId,
                ShareType = 'V', // View permission
                Visibility = 'AllUsers'
                    ));
            }
            
            insert links;

                  updateWorkStepStatus(workOrderId, 'BP Execution Details');


    } catch (Exception e) {
        System.debug('❌ Error during WorkOrder update: ' + e.getMessage());
    }
}



 

    @AuraEnabled
    public static void saveMaterialDetails(Map<String, String> materialMap) {
        System.debug('🧰 [saveMaterialDetails] Start');
        Id workOrderId = (Id)materialMap.get('workOrderId');
        System.debug('workOrderId: ' + workOrderId);

      Material_Consumption__c matDetail = new Material_Consumption__c();

        matDetail.Meter_Bracket__c = materialMap.get('meterBracket');
        matDetail.Meter_Regulator__c = materialMap.get('meterRegulator');
        matDetail.Meter_Control_Valve__c = materialMap.get('meterControlValve');
        matDetail.Appliance_Valve__c = materialMap.get('applianceValve');
        matDetail.Copper_Pipe_12mm_In_meter__c = materialMap.get('copperPipe12mm');
        matDetail.Br_Disconnection_Union_1_2_x_12mm__c = materialMap.get('brDisconnectionUnion1');
        matDetail.Br_Disconnection_Union_3_4_x_12mm__c = materialMap.get('brDisconnectionUnion2');
        matDetail.Meter_Inlet_Adaptor_3_4_x_3_4__c = materialMap.get('meterInletAdaptor');
        matDetail.Meter_Outlet_Adaptor_3_4_x_12mm__c = materialMap.get('meterOutletAdaptor');
        matDetail.GI_Pipe__c = materialMap.get('giPipe');
        matDetail.Barrel_Nipple__c = materialMap.get('barrelNipple');
        matDetail.PRE_SLEEVED_GI_HOLE_PIECE__c = materialMap.get('preSleevedGi');
        matDetail.Anaconda__c = materialMap.get('anaconda');
        matDetail.Br_Fitting_1_2_x_1_2__c = materialMap.get('brFitting');
        matDetail.MLC_Pipe_Length__c = materialMap.get('mlcPipeLength');
        matDetail.Work_Order__c	 = workOrderId;

        insert matDetail;


          updateWorkStepStatus(workOrderId, 'BP Execution Details');

        System.debug('✅ [saveMaterialDetails] Material fields updated for WorkOrder ' + workOrderId);
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
            ws.Status = 'Completed'; 
            update ws;
        }
    }

    public class FileWrapper{
        @AuraEnabled public String base64Data{get;set;}
        @AuraEnabled public String fileName{get;set;}
        @AuraEnabled public String label{get;set;}
    }

   
}