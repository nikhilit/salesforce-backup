/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 02-02-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   30-07-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class WorkOrderVisitController {
    @AuraEnabled
    public static void updateVisitInfo(Id workOrderId, String comments, Date followUpDate, String followUpRemarks, String reason) {
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
        
        wo.Comments__c = comments;
        wo.Follow_Up_Appointment_Date__c = followUpDate;
        wo.Follow_up_Remarks__c = followUpRemarks;
        // wo.Reason_for_Unavailability__c = reason;
        
        update wo;
    }
    
    public class PicklistWrapper {
        @AuraEnabled public List<String> remarkTypes;
        @AuraEnabled public List<String> appointmentTypes;
        
        public PicklistWrapper() {
            remarkTypes = new List<String>();
            appointmentTypes = new List<String>();
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static PicklistWrapper getPicklistValues() {
        System.debug('Fetching picklist values for identification and appointment types.');
        PicklistWrapper wrapper = new PicklistWrapper();
        
        Schema.DescribeFieldResult idTypeFieldResult = WorkOrder.CNG_Remark__c.getDescribe();
        for (Schema.PicklistEntry entry : idTypeFieldResult.getPicklistValues()) {
            wrapper.remarkTypes.add(entry.getLabel());
        }
        return wrapper;
    }
    
    @AuraEnabled
    Public static WorkOrderWrapper getWorkOrder(String recordId){
        WorkOrder workOrderRec=[SELECT Id,Account.Name,Account.Phone,Account.Representative_Company__c,Account.Zone__c,
                                    Account.Location__c,Account.Geolocation__c FROM WorkOrder WHERE Id=:recordId];
        WorkOrderWrapper wo = new WorkOrderWrapper(workOrderRec);
        wo.geoFenceConfig=[SELECT Id,For_CNG__c,For_CNG_Distance_in_Meter__c,For_Domestic__c,
                                For_Domestic_Distance_in_Meter__c,For_MRS__c,
                                For_MRS_Distance_in_Meter__c,For_Non_MRS_Distance_in_Meter__c              
                            FROM Metering_GEO_Fence_Config__mdt 
                            WHERE Active__c=true LIMIT 1];
        
        List<WorkStep> steps = [
                SELECT Id, Status
                FROM WorkStep
                WHERE ParentRecordId = :recordId
                AND Name = 'Start Metering' AND Status = 'Completed'
                LIMIT 1
            ];
        
        if (!steps.isEmpty()) {
            wo.jointVisitDone = true;
        }
        return wo;
    }
    
    public class WorkOrderWrapper{
        @AuraEnabled public WorkOrder wo;
        @AuraEnabled public String customerName;
        @AuraEnabled public String zone;
        @AuraEnabled public String phone;
        @AuraEnabled public String location;
        @AuraEnabled public String repComp;
        @AuraEnabled public Boolean jointVisitDone;
        @AuraEnabled public Metering_GEO_Fence_Config__mdt geoFenceConfig;
        
        public WorkOrderWrapper(){
            wo = new WorkOrder();
            customerName ='';
            zone = '';
            phone = '';
            location = '';
            repComp = '';
            jointVisitDone = false;
        }
        
        public WorkOrderWrapper(WorkOrder wo){
            this.wo = wo;
            this.customerName =wo.Account.Name;
            this.zone = wo.Account.Zone__c;
            this.phone =wo.Account.Phone;
            this.location =wo.Account.Location__c;
            this.repComp =wo.Account.Representative_Company__c;
            this.jointVisitDone = false;
        }
    }
    
    @AuraEnabled
    public static void insertDispenserPoint(Dispenser_Point__c dispenser, Id workOrderId) {
        system.debug('dispenser::'+dispenser);
        // Step 1: Get latest dispenser number globally (for Dispenser_Number__c)
        List<Dispenser_Point__c> latestDispenser = [
                SELECT Dispenser_Number__c 
                FROM Dispenser_Point__c 
                WHERE Dispenser_Number__c LIKE 'DIS-%' 
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];
        
        Integer nextNumber = 1;
        if (!latestDispenser.isEmpty()) {
            String latestNumberStr = latestDispenser[0].Dispenser_Number__c.replace('DIS-', '');
            if (Pattern.matches('\\d+', latestNumberStr)) {
                nextNumber = Integer.valueOf(latestNumberStr) + 1;
            }
        }
        
        // Pad number to 5 digits: 00001, 00002, etc.
        String paddedNumber = String.valueOf(nextNumber);
        while (paddedNumber.length() < 5) {
            paddedNumber = '0' + paddedNumber;
        }
        
        dispenser.Dispenser_Number__c = 'DIS-' + paddedNumber;
        
        // Step 2: Count how many dispenser points already exist for this work order
        Integer countForWorkOrder = [
                SELECT COUNT() 
                FROM Dispenser_Point__c 
                WHERE WorkOrderId__c = :workOrderId
            ];
        
        // Step 1: Extract base name like 'Point_1' from current dispenser name
        String baseDispenserName = 'Point_' + extractLastNumber(dispenser.Dispenser_Name__c);
        
        // Step 2: Query how many dispenser points already exist for this work order with this base name
        List<Dispenser_Point__c> existingPoints = [
                SELECT Dispenser_Name__c 
                FROM Dispenser_Point__c 
                WHERE WorkOrderId__c = :workOrderId 
                AND Dispenser_Name__c LIKE :baseDispenserName + '_New_%'
            ];
        List<Dispenser_Point__c> existingPointsAll = [
                SELECT Dispenser_Name__c 
                FROM Dispenser_Point__c 
                WHERE WorkOrderId__c = :workOrderId 
            ];
        // Step 3: Determine next index
        Integer newIndex = existingPoints.size() + 1;
        
        // Step 4: Create updated dispenser name
        String newDispenserName = baseDispenserName + '_New_' + String.valueOf(newIndex);
        
        // Step 5: Set fields
        dispenser.Dispenser_Name__c = newDispenserName;
        // dispenser.CNG_Meter_reading__c = 'a1mfs0000000GeHAAU';
        dispenser.WorkOrderId__c = workOrderId;
        Integer value=extractLastNumber(newDispenserName)+newIndex;
        system.debug('value::'+value);
        system.debug('newIndex::'+newIndex);
        dispenser.Dispenser_Number_Value__c = existingPointsAll.size()+1;
        dispenser.Live__c = true;
        
        // Step 6: Insert
        insert dispenser;
        
    }
    
    @AuraEnabled
    public static string deleteDispenserPoints(String recordId) {
        try {
            List<Dispenser_Point__c> listDispenserPoints = [SELECT Id, WorkOrderId__c, Dispenser_Name__c FROM Dispenser_Point__c WHERE Id = :recordId];
            
            if (listDispenserPoints.isEmpty()) {
                return 'Record not found';
            }
            
            Dispenser_Point__c recordToDelete = listDispenserPoints[0];
            String dispenserName = recordToDelete.Dispenser_Name__c;
            Id workOrderId = recordToDelete.WorkOrderId__c;
            
            // Parse name: Point_2_New_3 -> baseName: Point_2, newNumber: 3
            Pattern p = Pattern.compile('^(.+)_New_(\\d+)$');
            Matcher m = p.matcher(dispenserName);
            
            if (m.matches()) {
                String baseName = m.group(1);
                Integer currentNewNumber = Integer.valueOf(m.group(2));
                Integer previousNewNumber = currentNewNumber - 1;
                
                if (previousNewNumber > 0) {
                    // Find the previous _New_ variant
                    String previousName = baseName + '_New_' + String.valueOf(previousNewNumber);
                    List<Dispenser_Point__c> previousRecords = [
                        SELECT Id, Live__c 
                        FROM Dispenser_Point__c 
                        WHERE WorkOrderId__c = :workOrderId 
                        AND Dispenser_Name__c = :previousName
                        LIMIT 1
                    ];
                    
                    if (!previousRecords.isEmpty()) {
                        previousRecords[0].Live__c = true;
                        update previousRecords[0];
                    }
                }
            }
            
            delete recordToDelete;
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static Integer extractlastNumber(String name) {
        if (String.isBlank(name)) return null;
        
        // Regex to find number right after 'Point_' or 'Point__'
        Pattern p = Pattern.compile('Point[_]*([0-9]+)');
        Matcher m = p.matcher(name);
        
        if (m.find()) {
            return Integer.valueOf(m.group(1));
        }
        return null;
    }
    
    
    @AuraEnabled
    public static void checkInWorkOrder(Id workOrderId, Double latitude, Double longitude) {
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
        wo.Check_In_Date_Time__c = System.now();
        // wo.Attendance_Status__c = 'Present';
        wo.Status = 'In Progress';
        wo.Check_In_Location__Latitude__s = latitude;
        wo.Check_In_Location__Longitude__s = longitude;
        wo.Check_In__c=true;
        // wo.Check_In_Location__c = Location.newInstance(latitude, longitude);
        
        try {
            update wo;
        } catch (Exception ex) {
            System.debug('Update failed: ' + ex.getMessage());
            throw new AuraHandledException('Check-In failed: ' + ex.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static List<Dispenser_Point__c> getDispenserPoints(Id workOrderId) {
        return [
                SELECT Id, Name, Remark__c,Dispenser_Name__c,Progressive_Remark__c, Dispenser_Number__c, WorkOrderID__c, Opening_Reading__c, Closing_Reading__c, Difference_Of_Open_and_Close_Reading__c,
                Calibration_Qty__c, Calibration_Reason__c,Account_Dispensor__r.Average_Consumption__c,
                Jumping_Qty__c, Jumping_Reason__c, Other_Qty__c, Other_Reason__c,Dispenser_Number_Value__c
                FROM Dispenser_Point__c
                WHERE WorkOrderID__c = :workOrderId 
                ORDER BY Dispenser_Number_Value__c asc
            ];
    }
    
    @AuraEnabled
    public static void saveVisitDetails(List<Dispenser_Point__c> updates, Id workOrderId, Decimal latitude, Decimal longitude, String remarks,String fromDate,String toDate) {
        for (Dispenser_Point__c dp : updates) {
            // dp.Difference_Of_Open_and_Close_Reading__c = Math.floor(dp.Closing_Reading__c) - dp.Opening_Reading__c;
        }
        update updates;
        
        WorkOrder wo = [SELECT Id, Status, Remarks__c, Check_Out_Date_Time__c FROM WorkOrder WHERE Id = :workOrderId];
        // wo.Attendance_Status__c = 'Day Out';
        // wo.Status = 'Completed';
        // wo.Appointment_Status__c='Completed';
        wo.Remarks__c = remarks;
        if(fromDate!='')
            wo.From_Date__c=Date.valueOf(fromDate);
        if(toDate!='')
            wo.To_Date__c=Date.valueOf(toDate);
        wo.Check_Out_Date_Time__c = DateTime.now();
        wo.Check_Out_Location__Latitude__s = latitude;
        wo.Check_Out_Location__Longitude__s = longitude;
        wo.Check_Out__c=true;
        // wo.Check_In_Location__c = Location.newInstance(latitude, longitude);
        update wo;
        updateWorkStepStatus(workOrderId,'Start Metering');
    }
    @AuraEnabled
    public static void updateLiveDetails(List<Dispenser_Point__c> updates, Id workOrderId, Decimal latitude, Decimal longitude, String remarks,String fromDate,String toDate) {
        update updates;
        
        WorkOrder wo = [SELECT Id, Status, Remarks__c, Check_Out_Date_Time__c FROM WorkOrder WHERE Id = :workOrderId];
        wo.Remarks__c = remarks;
        if(fromDate!=''){
            Date inputDate=Date.valueOf(fromDate);
            Time currentTime = System.now().time();  // current time
            
            // Combine into DateTime
            DateTime finalDateTime = DateTime.newInstance(inputDate, currentTime);
            
            // Save
            wo.Live_Reading_Date_Time__c = finalDateTime;
        }
        wo.Live_Reading_Location__Latitude__s = latitude;
        wo.Live_Reading_Location__Longitude__s = longitude;
        // wo.Live_Reading_Check_Out_Date_Time__c = DateTime.now();
        wo.Status = 'Completed';
        wo.Appointment_Status__c='Completed';
        // wo.Check_In_Location__c = Location.newInstance(latitude, longitude);
        update wo;
        
        ServiceAppointment sa = [
                SELECT Id,ParentRecordId,Status
                FROM ServiceAppointment 
                WHERE ParentRecordId = :workOrderId
                LIMIT 1
            ];
        
        sa.Status = 'Completed';
        update sa;
        
        updateWorkStepStatus(workOrderId,'Live Reading');
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
    public static string uploadImage(String fileName, String base64Data, Id recordId) {
        if (String.isBlank(base64Data) || String.isBlank(fileName) || recordId == null) {
            throw new AuraHandledException('Invalid input data.');
        }
        
        Blob fileBody = EncodingUtil.base64Decode(base64Data);
        
        String fileTile=System.Label.CNG_PDF_Signature_File_Name;
        // Query existing files with the same title linked to the record
        List<ContentDocumentLink> existingLinks = [
            SELECT Id, ContentDocumentId FROM ContentDocumentLink 
            WHERE LinkedEntityId = :recordId AND ContentDocument.Title = :fileTile
        ];
        
        // Collect the ContentDocumentIds for deletion
        Set<Id> contentDocIds = new Set<Id>();
        for(ContentDocumentLink link : existingLinks) {
            contentDocIds.add(link.ContentDocumentId);
        }
        
        // If any existing files found, delete their links and content versions
        if (!contentDocIds.isEmpty()) {
            
            // Optionally, delete the ContentDocument records if no other links exist
            List<ContentDocument> docsToDelete = [
                SELECT Id FROM ContentDocument WHERE Id IN :contentDocIds
        ];
            if (!docsToDelete.isEmpty()) {
                delete docsToDelete;
            }
        }
        
        ContentVersion cv = new ContentVersion();
        cv.Title = SYSTEM.Label.CNG_PDF_Signature_File_Name;
        cv.PathOnClient = 'Signature.png';
        cv.VersionData = fileBody;
        insert cv;
        
        cv = [
                SELECT ContentDocumentId,VersionDataUrl FROM ContentVersion WHERE Id = :cv.Id
            ];
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'V';
        insert cdl;
        return cv.VersionDataUrl;
    }
    
    @AuraEnabled
    public static string uploadSelfieImage(String fileName, String base64Data, Id recordId) {
        if (String.isBlank(base64Data) || String.isBlank(fileName) || recordId == null) {
            throw new AuraHandledException('Invalid input data.');
        }
        
        Blob fileBody = EncodingUtil.base64Decode(base64Data);
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Selfie Image';
        cv.PathOnClient = 'SelfieImage.png';
        cv.VersionData = fileBody;
        insert cv;
        
        cv = [
                SELECT ContentDocumentId,VersionDataUrl FROM ContentVersion WHERE Id = :cv.Id
            ];
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'V';
        insert cdl;
        return cv.VersionDataUrl;
    }
    
    @AuraEnabled(cacheable=false)
    public static void replaceDispenserPoint(
        Dispenser_Point__c newDispenser,
        Id oldDispenserId
    ) {
        if (oldDispenserId == null) {
            throw new AuraHandledException('Old Dispenser Id is required.');
        }
        
        try {
            System.debug('newDispenser:: ' + newDispenser);
            System.debug('oldDispenserId:: ' + oldDispenserId);
            
            // 1️⃣ Fetch old dispenser
            Dispenser_Point__c oldDispenser = [
                SELECT Id, Dispenser_Name__c, WorkOrderId__c, Live__c
                FROM Dispenser_Point__c
                WHERE Id = :oldDispenserId
                LIMIT 1
            ];
            
            // 🔥 Validation: Check if this is the latest version for the base point
            String baseName = extractBaseName(oldDispenser.Dispenser_Name__c);
            List<Dispenser_Point__c> latestVersion = [
                SELECT Id
                FROM Dispenser_Point__c
                WHERE WorkOrderId__c = :oldDispenser.WorkOrderId__c
                AND Dispenser_Name__c LIKE :baseName + '%'
                ORDER BY Dispenser_Name__c DESC
                LIMIT 1
            ];
            
            if (latestVersion.isEmpty() || latestVersion[0].Id != oldDispenserId) {
                throw new AuraHandledException('Cannot replace this dispenser. It is not the latest version.');
            }
            
            // 2️⃣ Generate next Dispenser Number (Optimized)
            Integer maxNumber = 0;
            
            List<AggregateResult> arList = [
                SELECT MAX(Dispenser_Number__c) maxVal
                FROM Dispenser_Point__c
                WHERE Dispenser_Number__c LIKE 'DIS-%'
            ];
            
            if (!arList.isEmpty() && arList[0].get('maxVal') != null) {
                String maxStr = String.valueOf(arList[0].get('maxVal')).replace('DIS-', '');
                maxNumber = Integer.valueOf(maxStr);
            }
            
            Integer nextNumber = maxNumber + 1;
            newDispenser.Dispenser_Number__c =
                'DIS-' + String.valueOf(nextNumber).leftPad(5, '0');
            
            // 3️⃣ Build new Dispenser Name
            Integer baseNumber = extractLastNumber(oldDispenser.Dispenser_Name__c);
            
            if (baseNumber == null) {
                throw new AuraHandledException(
                    'Invalid Dispenser Name format: ' + oldDispenser.Dispenser_Name__c
                );
            }
            
            String baseDispenserName = 'Point_' + baseNumber;
            
            Integer existingCount = [
                SELECT COUNT()
                FROM Dispenser_Point__c
                WHERE WorkOrderId__c = :oldDispenser.WorkOrderId__c
                AND Dispenser_Name__c LIKE :baseDispenserName + '_New_%'
            ];

            List<Dispenser_Point__c> existingPointsAll = [
                SELECT Dispenser_Name__c 
                FROM Dispenser_Point__c 
                WHERE WorkOrderId__c = :oldDispenser.WorkOrderId__c 
            ];
            
            String newDispenserName =
                baseDispenserName + '_New_' + (existingCount + 1);
            
            newDispenser.Dispenser_Name__c = newDispenserName;
            newDispenser.WorkOrderId__c = oldDispenser.WorkOrderId__c;
            newDispenser.Live__c = true;
            newDispenser.Dispenser_Number_Value__c = existingPointsAll.size() + 1;
            
            // 4️⃣ DML
            insert newDispenser;
            
            oldDispenser.Live__c = false;
            update oldDispenser;
            
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static Boolean canReplaceDispenser(Id dispenserId) {
        try {
            if (dispenserId == null) {
                throw new AuraHandledException('Dispenser Id is required.');
            }
            
            Dispenser_Point__c dispenser = [
            SELECT Id, Live__c, Dispenser_Name__c, WorkOrderId__c
            FROM Dispenser_Point__c
            WHERE Id = :dispenserId
            LIMIT 1
        ];
            
            // Check if dispenser is marked as Live (not yet replaced)
            // if (dispenser.Live__c == false) {
            //     return false;
            // }
            
            // Extract base name (e.g., "Point_1" from "Point_1_New_2")
            String baseName = extractBaseName(dispenser.Dispenser_Name__c);
            
            // Query all dispensers with same base name from same work order
            List<Dispenser_Point__c> allVersions = [
            SELECT Id, Dispenser_Name__c
            FROM Dispenser_Point__c
            WHERE WorkOrderId__c = :dispenser.WorkOrderId__c
            AND Dispenser_Name__c LIKE :baseName + '%'
            ORDER BY Dispenser_Name__c DESC
            LIMIT 1
        ];
            
            if (allVersions.isEmpty()) {
                return false;
            }
            
            // Return true only if selected dispenser is the latest version
            return allVersions[0].Id == dispenserId;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    private static String extractBaseName(String dispenserName) {
        // Extract base name from patterns like:
        // "Point_1" -> "Point_1"
        // "Point_1_New_1" -> "Point_1"
        // "Point_1_New_2" -> "Point_1"
        Pattern p = Pattern.compile('^(Point_\\d+)(?:_New_\\d+)?$');
        Matcher m = p.matcher(dispenserName);
        
        if (m.matches()) {
            return m.group(1);
        }
        
        return dispenserName;
    }
    
}