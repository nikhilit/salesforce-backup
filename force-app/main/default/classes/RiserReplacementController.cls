public without sharing class RiserReplacementController {



    @AuraEnabled
    public static List<Account> getBPBasedOnConnectionNumber(String recordId ){



        try {

            WorkOrder wo = [select Id,Connection__r.Name from workorder where Id=: recordId];

            List<Account> lstAccounts = [select id,Connection_Object__c,FirstName__c, LastName__c,BP_Number__c   from account where Connection_Object__c=: wo.Connection__r.Name];

          system.debug('Returing list of accounts::'+ lstAccounts);

            return lstAccounts;

        }

        catch(Exception e){

            system.debug('Error get BP ::'+ e.getLineNumber() + e.getMessage());
            return new List<Account>();
        }
    }

    @AuraEnabled
    public static void updateAccounts(List<Map<String, Object>> updatedData, String recordId){

        try {

            system.debug('inside update accounts::'+ updatedData);


              updateWorkStepStatus(recordId,'CO Execution Detail');


             List<Account> accountsToUpdate = new List<Account>();

        for (Map<String, Object> accData : updatedData) {

    //         if (!accData.containsKey('Id') || accData.get('Id') == null) {
    //     continue; 
    // }
            Id accId = (Id) accData.get('Id');
            Account acc = new Account(Id = accId);

            if (accData.containsKey('meterNumber'))
                acc.Meter_Number__c = (String) accData.get('meterNumber');

            if (accData.containsKey('meterReading'))
                acc.Meter_Reading__c = (String) accData.get('meterReading');

            if (accData.containsKey('regulatorMake'))
                acc.Regulator_Make__c = (String) accData.get('regulatorMake');

            if (accData.containsKey('connectionDone'))
                acc.Connection_Done_Or_Not__c = (String) accData.get('connectionDone');

            accountsToUpdate.add(acc);
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }

        system.debug('after update records data ::'+ accountsToUpdate);
    }
        

        catch(Exception e){

            system.debug('Error update accounts ::'+ e.getLineNumber() + e.getMessage());
        }


    }

    @AuraEnabled
    public static void saveImage(List<FileWrapper> listFiles,String recordId){
        try {
                       
         
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            for (FileWrapper fw : listFiles) {
                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName +'.jpg';
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                contentVersions.add(cv);
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
                LinkedEntityId = recordId,
                ShareType = 'V', // View permission
                Visibility = 'AllUsers'
                    ));
            }
            
            insert links;

            

         // updateWorkStepStatus(recordId,'CO Execution Detail');




        } catch (Exception ex) {
             System.debug('❌ Exception: ' + ex.getMessage() + ' ' + ex.getLineNumber());
          //  throw new AuraHandledException('Error updating work order: ' + ex.getMessage());

        }
    }

    public class FileWrapper{
        @AuraEnabled public String base64Data{get;set;}
        @AuraEnabled public String fileName{get;set;}
        @AuraEnabled public String label{get;set;}
    }



    @AuraEnabled
    public static void saveCustomerDetails(Id accountId, Decimal giLength, Decimal copperLength, String meterShifted) {
        try {
            Account acc = [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
            acc.GI_Lateral_Installed_Length__c = giLength;
            acc.Copper_Pipe_Installed_Length__c = copperLength;
            acc.Meter_Shifted__c = meterShifted;
            update acc;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to save customer details: ' + e.getMessage());
        }
    }

    

@AuraEnabled
public static void saveRiserTestingDetails(
    String workOrderId,
    List<RiserWrapper> riserDataList,
    String instrumentType,
    String certificateNo,
    Date calibrationDate,
    Date calibrationDueDate,
    Integer noOfFloors,
    Integer noOfRisers,
    String meterReading,
    String meterNumber,
    String regulatorMake,
    String riserPickListValue,
    String gipipeerectionlength


)
{
   try {
    List<Riser_Details__c> riserRecords = new List<Riser_Details__c>();
   // System.debug('Received RiserWrapper list: ' + JSON.serializePretty(riserDataList));


    for (Integer i = 0; i < riserDataList.size(); i++) {
        RiserWrapper data = riserDataList[i];

        Riser_Details__c rd = new Riser_Details__c();
        rd.Work_Order__c = workOrderId;
        rd.Copper_Pipe_Length__c = String.valueOf(data.copperPipeLength);
       // rd.Test_Pressure__c = data.testPressure;
      //  rd.Satabalization_Time__c = parseTimeSafely(data.stabilizationTime);
       // rd.Testing_Time__c = parseTimeSafely(data.testingTime);
       // rd.Testing_Status__c = data.testingStatus;
       // rd.Leakage_Observed_In__c = data.leakageObserved;
       // rd.Length_Rectified__c = data.lengthRectified;
       // rd.Type_of_Riser__c = data.riserType;
        rd.Riser_Index__c = i + 1;

        // Common data
        rd.Instrument_Type_and_Range__c = instrumentType;
        rd.No_of_Floors__c = noOfFloors;
        rd.No_of_Risers__c = noOfRisers;
       // rd.Meter_Reading__c = meterReading;
       // rd.Meter_No__c = meterNumber;
        rd.Type_of_Riser__c = riserPickListValue;
       // rd.Regulator_Make__c = regulatorMake;

        if (String.isNotBlank(certificateNo) && Pattern.matches('^[0-9.]+$', certificateNo)) {
            rd.Calibration_Certificate_No__c = Decimal.valueOf(certificateNo);
        }

        rd.Calibration_Date__c = calibrationDate;
        rd.Calibration_Due_Date__c = calibrationDueDate;

        riserRecords.add(rd);
    }

    if (!riserRecords.isEmpty()) {
        insert riserRecords;
        System.debug('Inserted Riser Testing Records: ' + riserRecords);
    }
} catch (Exception e) {
    System.debug('Line: ' + e.getLineNumber());
    throw new AuraHandledException('Failed to save riser testing details: ' + e.getMessage());
}

}



    @AuraEnabled
public static void saveGaugeCalibrationDetails(
    Id workOrderId,
    String instrumentType,
    String certificateNo,
    Date calibrationDate,
    Date calibrationDueDate
) {
    if (workOrderId == null) {
        throw new AuraHandledException('Work Order ID is required.');
    }

    try {
        List<Riser_Details__c> rdList = [
            SELECT Id FROM Riser_Details__c WHERE Work_Order__c = :workOrderId
        ];

        if (rdList.isEmpty()) {
            throw new AuraHandledException('No riser records found for this Work Order.');
        }

        for (Riser_Details__c rd : rdList) {
            rd.Instrument_Type_and_Range__c = instrumentType;

            if (String.isNotBlank(certificateNo) && Pattern.matches('^[0-9.]+$', certificateNo)) {
                rd.Calibration_Certificate_No__c = Decimal.valueOf(certificateNo);
            }

            if (calibrationDate != null) {
                rd.Calibration_Date__c = calibrationDate;
            }

            if (calibrationDueDate != null) {
                rd.Calibration_Due_Date__c = calibrationDueDate;
            }
        }

        update rdList;

        	//  updateWorkStepStatus(workOrderId,'CO Execution Detail');



    } catch (Exception e) {
        throw new AuraHandledException('Failed to save gauge calibration details: ' + e.getMessage());
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



    @AuraEnabled
    public static void updateAppointmentStatus(Id woId) {
        try {
            WorkOrder wo = [SELECT Id, (SELECT Id, Status FROM WorkOrderLineItems) FROM WorkOrder WHERE Id = :woId LIMIT 1];
            Boolean isComplete = true;

            for (WorkOrderLineItem woli : wo.WorkOrderLineItems) {
                if (woli.Status != 'Completed') {
                    isComplete = false;
                    break;
                }
            }

            wo.Status = isComplete ? 'Completed' : 'In Progress';
            update wo;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to update appointment status: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Id getServiceAppointmentId(Id workOrderId) {
        try {
            List<ServiceAppointment> saList = [SELECT Id FROM ServiceAppointment WHERE ParentRecordId = :workOrderId LIMIT 1];
            return saList.isEmpty() ? null : saList[0].Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching service appointment ID: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveFloorCount(Id workOrderId, Integer floors) {
        try {
            WorkOrder wo = [SELECT Id FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
            wo.Number_of_Floors__c = floors;
            update wo;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to save floor count: ' + e.getMessage());
        }
    }

//     @AuraEnabled
// public static void saveMaterialDetails(Id workOrderId, List<MaterialWrapper> materialList) {
    
//     System.debug('Work Order Id: ' + workOrderId);
//     System.debug('Received Material List: ' + JSON.serializePretty(materialList));

//     List<Material_Consumption__c> toInsert = new List<Material_Consumption__c>();

//     for (MaterialWrapper wrapper : materialList) {
//         System.debug('Processing MaterialWrapper: ' + JSON.serializePretty(wrapper));

//         Material_Consumption__c record = new Material_Consumption__c(
//             Work_Order__c = workOrderId,
//             //Item_Code__c = wrapper.itemCode,
//             Item_Description__c = wrapper.itemDescription,
//             Unit__c = wrapper.unit,
//             Quantity__c = Decimal.valueOf(wrapper.quantity)
//         );

//         System.debug('Constructed Material_Consumption__c record: ' + record);
//         toInsert.add(record);
//     }

//     if (!toInsert.isEmpty()) {
//         insert toInsert;
//         System.debug('Inserted Material Consumption records: ' + toInsert);
//     } else {
//         System.debug('No Material Consumption records to insert.');
//     }

//     System.debug('--- Exiting saveMaterialDetails ---');
// }

    @AuraEnabled
    public static void saveMaterialDetails(Id workOrderId, List<MaterialWrapper> materialList) {
        System.debug('--- Entered saveMaterialDetails ---');
        System.debug('Work Order Id: ' + workOrderId);
        System.debug('Received Material List: ' + materialList);



        List<Material_Consumption__c> toInsert = new List<Material_Consumption__c>();

        for (MaterialWrapper wrapper : materialList) {
            System.debug('Processing MaterialWrapper: ' + JSON.serializePretty(wrapper));
            
            Material_Consumption__c record = new Material_Consumption__c(
                Work_Order__c = workOrderId,
                Item_Description__c = wrapper.itemDescription,
                Unit__c = wrapper.unit,
                Quantity__c = wrapper.quantity
            );
            toInsert.add(record);
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
            System.debug('Inserted Material Consumption records: ' + toInsert);
        }
    }


// public class MaterialWrapper {
//     @AuraEnabled public String itemCode;
//     @AuraEnabled public String itemDescription;
//     @AuraEnabled public String unit;
//     @AuraEnabled public String quantity;
// }




@AuraEnabled
public static List<String> getItemDescriptionOptions() {
    List<String> options = new List<String>();

    // This is the correct way to get the picklist entries for a field
    Schema.DescribeFieldResult fieldResult = Material_Consumption__c.Item_Description__c.getDescribe();
    List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

    for (Schema.PicklistEntry pe : picklistValues) {
        options.add(pe.getValue());
    }

    return options;
}




    // Utility method to safely parse HH:mm or HH:mm:ss to Time
    private static Time parseTimeSafely(String inputTime) {
        try {
            if (String.isNotBlank(inputTime)) {
                List<String> parts = inputTime.split(':');
                Integer h = Integer.valueOf(parts[0]);
                Integer m = Integer.valueOf(parts[1]);
                Integer s = parts.size() > 2 ? Integer.valueOf(parts[2]) : 0;
                return Time.newInstance(h, m, s, 0);
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Invalid time format: ' + inputTime);
        }
        return null;
    }

    public class MaterialWrapper {
        // @AuraEnabled public String itemCode;
        @AuraEnabled public String itemDescription{get;set;}
        @AuraEnabled public String unit{get;set;}
        @AuraEnabled public Integer quantity{get;set;} // or Decimal if you're always passing a number
    }

    public class RiserWrapper {
    @AuraEnabled public Decimal copperPipeLength { get; set; }
    @AuraEnabled public String testPressure { get; set; }
    @AuraEnabled public String stabilizationTime { get; set; }
    @AuraEnabled public String testingTime { get; set; }
    @AuraEnabled public String testingStatus { get; set; }
    @AuraEnabled public String leakageObserved { get; set; }
    @AuraEnabled public String lengthRectified { get; set; }
    @AuraEnabled public String riserType { get; set; }
}


@AuraEnabled
public static String savePhotoUploadsReversal(Id recordId, List<PhotoWrapper> listFiles) {

    try {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        //List<Document__c> documents = new List<Document__c>();

        for (PhotoWrapper file : listFiles) {
            if (String.isNotBlank(file.base64Data) && String.isNotBlank(file.fileName)) {
                // Create ContentVersion
                ContentVersion cv = new ContentVersion();
                cv.Title = file.label != null ? file.label : file.fileName;
                cv.PathOnClient = '/' + file.fileName;
                cv.VersionData = EncodingUtil.base64Decode(file.base64Data);
                contentVersions.add(cv);
                System.debug('Added ContentVersion for: ' + file.fileName);

            } else {
                System.debug('Skipping file due to missing data: ' + file.fileName);
            }
        }

        if (contentVersions.isEmpty()) return 'No valid files to upload.';

        insert contentVersions;
        System.debug('Inserted ContentVersion records: ' + contentVersions.size());

        // Map to ContentDocument
        Map<Id, Id> versionToDocMap = new Map<Id, Id>();
        for (ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions]) {
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
        System.debug('Linked documents to WorkOrder: ' + recordId);

        // updateWorkStepStatus(recordId, 'CO Execution Detail');

        return 'SUCCESS';

    } catch (Exception e) {
        System.debug('Error during photo upload: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        return 'ERROR: ' + e.getMessage();
    }
}

@AuraEnabled
public static String savePhotoUploadsLPG(Id recordId, List<PhotoWrapper> listFiles) {
    System.debug('Starting savePhotoUploads for Record Id: ' + recordId);

        try {
            List<ContentVersion> contentVersions = new List<ContentVersion>();

            for (PhotoWrapper file : listFiles) {
                if (String.isNotBlank(file.base64Data) && String.isNotBlank(file.fileName)) {
                    ContentVersion cv = new ContentVersion();
                    cv.Title = file.label;
                    cv.PathOnClient = '/' + file.fileName;
                    cv.VersionData = EncodingUtil.base64Decode(file.base64Data);
                    contentVersions.add(cv);
                    System.debug('Added ContentVersion for: ' + file.label);
                } else {
                    System.debug('Skipping file due to missing base64Data or fileName');
                }
            }

            if (contentVersions.isEmpty()) {
                System.debug('No valid files to insert. Exiting early.');
                return 'No valid files to upload.';
            }

            insert contentVersions;
            System.debug('Inserted ContentVersions: ' + contentVersions);

            // Map ContentVersion Id to ContentDocumentId
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE Id IN :contentVersions
            ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
                System.debug('Mapped ContentVersion ' + cv.Id + ' to Document ' + cv.ContentDocumentId);
            }

            // Create ContentDocumentLinks
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                    LinkedEntityId = recordId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
                System.debug('Created ContentDocumentLink for doc: ' + versionToDocMap.get(versionId));
            }

            insert links;
            System.debug('Linked documents to record: ' + recordId);

            // Optionally update status of related step
          //  updateWorkStepStatus(recordId, 'CO Execution Detail');

            return 'SUCCESS';

        } catch (Exception e) {
            System.debug('Error saving photos: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            return 'ERROR: ' + e.getMessage();
        }
}

public class PhotoWrapper {
    @AuraEnabled public Integer id { get; set; }
    @AuraEnabled public Integer index { get; set; }
    @AuraEnabled public String label { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String fileName { get; set; }
    @AuraEnabled public Boolean uploaded { get; set; }
    @AuraEnabled public String previewUrl { get; set; }
    @AuraEnabled public String base64Data { get; set; }
    @AuraEnabled public String fileBody { get; set; }
    @AuraEnabled public String fileType { get; set; }
}

@AuraEnabled
public static String savePhotoUploadsMeter(Id recordId, List<PhotoWrapper> listFiles) {
    System.debug('Starting savePhotoUploads Meter for Record Id: ' + recordId);
   // System.debug('Total Files Received: ' + (listFiles != null ? listFiles.size() : 0));
   // System.debug('Received Files: ' + JSON.serializePretty(listFiles));

    try {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        //List<Document__c> documents = new List<Document__c>();

        for (PhotoWrapper file : listFiles) {
            if (String.isNotBlank(file.base64Data) && String.isNotBlank(file.fileName)) {
                // Create ContentVersion
                ContentVersion cv = new ContentVersion();
                cv.Title = file.label != null ? file.label : file.fileName;
                cv.PathOnClient = '/' + file.fileName;
                cv.VersionData = EncodingUtil.base64Decode(file.base64Data);
                contentVersions.add(cv);
                System.debug('Added ContentVersion for: ' + file.fileName);

            } else {
                System.debug('Skipping file due to missing data: ' + file.fileName);
            }
        }

        if (contentVersions.isEmpty()) return 'No valid files to upload.';

        insert contentVersions;
        System.debug('Inserted ContentVersion records: ' + contentVersions.size());

        // Map to ContentDocument
        Map<Id, Id> versionToDocMap = new Map<Id, Id>();
        for (ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions]) {
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
        System.debug('Linked documents to WorkOrder: ' + recordId);

        // updateWorkStepStatus(recordId, 'CO Execution Detail');

        return 'SUCCESS';

    } catch (Exception e) {
        System.debug('Error during photo upload: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        return 'ERROR: ' + e.getMessage();
    }
}


}