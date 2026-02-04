/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 20-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   19-08-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class BulkUploadJointPdfController {
    public List<WorkOrderWrapper> tickets { get; set; }
    public Boolean useDualColumn { get; set; }
    public String fileDownloadUrl { get; set; }
    public String approvarDate { get; set; }
    public Boolean yesNo { get; set; }
    public String checkInDate { get; set; }
    public String checkInTime { get; set; }
    public String formattedFromDate { get; set; }
    public String formattedToDate { get; set; }
    public Decimal totalSale { get; set; }
    public Decimal totalReading { get; set; }
    public Decimal totalConsumption { get; set; }
    public Decimal totalCalibration { get; set; }
    public Decimal totalJumping { get; set; }
    public Decimal totalOthers { get; set; }
    public Decimal totalReadingJump { get; set; }
    public Decimal overallQuantity { get; set; }
    public List<DispenserData> dispenserListLeft { get; set; }
    public List<DispenserData> dispenserListRight { get; set; }
    
    public List<Integer> getROW_COUNT() {
        List<Integer> rows = new List<Integer>();
        for (Integer i = 1; i <= 11; i++) {
            rows.add(i);
        }
        return rows;
    }
    
    // Remote action to get image URL for a work order
    @RemoteAction
    public static String getImageUrlForWorkOrder(Id workOrderId) {
        try {
            List<ContentDocumentLink> docLinks = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :workOrderId
                LIMIT 1
            ];
            
            if (!docLinks.isEmpty()) {
                String fileTitle = System.Label.CNG_PDF_Signature_File_Name;
                List<ContentVersion> versions = [
                    SELECT Id
                    FROM ContentVersion
                    WHERE ContentDocumentId = :docLinks[0].ContentDocumentId 
                    AND Title = :fileTitle
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                
                if (!versions.isEmpty()) {
                    return '/sfc/servlet.shepherd/version/download/' + versions[0].Id;
                }
            }
            return null;
        } catch (Exception e) {
            return null;
        }
    }
    
    // Remote action to store resized images in cache
    @RemoteAction
    public static Boolean storeResizedImages(String sessionId, Map<String, String> imageDataMap) {
        try {
            // Store in Cache (Platform Cache or Custom Object)
            // Using Org Cache with 4 hour TTL
            Cache.Org.put('ResizedImages_' + sessionId, JSON.serialize(imageDataMap), 14400);
            return true;
        } catch (Exception e) {
            System.debug('Error storing resized images: ' + e.getMessage());
            return false;
        }
    }
    
    // Method to retrieve resized images from cache
    private static Map<String, String> getResizedImagesFromCache(String sessionId) {
        try {
            String cachedData = (String)Cache.Org.get('ResizedImages_' + sessionId);
            if (cachedData != null) {
                return (Map<String, String>)JSON.deserialize(cachedData, Map<String, String>.class);
            }
        } catch (Exception e) {
            System.debug('Error retrieving cached images: ' + e.getMessage());
        }
        return new Map<String, String>();
    }
    
    public BulkUploadJointPdfController() {
        String idParam = ApexPages.currentPage().getParameters().get('ids');
        String sessionId = ApexPages.currentPage().getParameters().get('sessionId');
        List<Id> recordIds = String.isNotBlank(idParam) ? idParam.split(',') : new List<Id>();
        tickets = new List<WorkOrderWrapper>();
        
        // Note: Resized images are stored in browser sessionStorage and injected via JavaScript
        // The page will need to use JavaScript to set these after DOM loads
        Map<String, String> resizedImagesCache = new Map<String, String>();
        
        // Prevent PDF size exceeding 30MB limit
        // Integer MAX_RECORDS = 20; // Reduced limit to stay safely under 30MB with images
        // if (recordIds.size() > MAX_RECORDS) {
        //     ApexPages.addMessage(new ApexPages.Message(
        //         ApexPages.Severity.ERROR, 
        //         'Cannot generate PDF for more than ' + MAX_RECORDS + ' work orders at once due to Salesforce 30MB PDF size limit. ' +
        //         'You selected ' + recordIds.size() + ' records. Please select ' + MAX_RECORDS + ' or fewer records and try again.'
        //     ));
        //     return;
        // }
        
        if (!recordIds.isEmpty()) {
            List<WorkOrder> workOrders = [
                SELECT Id, Customer_Name__c,Assigned_Meter_Reader__r.RelatedRecord.Name, Account.Representative_Company__c, Check_In_Date_Time__c, Approvar_Date__c,Approval_Date_Time__c,
                Approvar_User__r.Name, Account.Location__c, Assigned_Meter_Reader__r.Name, From_Date__c, To_Date__c,
                Account.Name, Current_Meter_Reading__c,Check_Out_Date_Time__c,
                Turbine_Meter_Reading__c, Final_Meter_Reading__c,Live_Reading_Date_Time__c,
                TotalPrice, StartDate, EndDate
                FROM WorkOrder
                WHERE Id IN :recordIds
            ];
            
            Map<Id, List<Dispenser_Point__c>> dispenserMap = new Map<Id, List<Dispenser_Point__c>>();
            for (Dispenser_Point__c dp : [
                SELECT WorkOrderID__c, Dispenser_Number__c,Is_Progressive__c,Remark__c, Dispenser_Name__c, Live_Reading__c, Opening_Reading__c,
                Jumping_Qty__c, Other_Qty__c, Calibration_Qty__c, Closing_Reading__c, Difference_Of_Open_and_Close_Reading__c,Progressive_Remark__c,
                Dispensor__c
                FROM Dispenser_Point__c
                WHERE WorkOrderID__c IN :recordIds
                // ORDER BY Dispenser_Number__c DESC
                ORDER BY Dispenser_Number_Value__c asc
            ]) {
                if (!dispenserMap.containsKey(dp.WorkOrderID__c)) {
                    dispenserMap.put(dp.WorkOrderID__c, new List<Dispenser_Point__c>());
                }
                dispenserMap.get(dp.WorkOrderID__c).add(dp);
            }
            
            Map<Id, List<Dispenser_Point__c>> dispenserLiveMap = new Map<Id, List<Dispenser_Point__c>>();
            for (Dispenser_Point__c dp : [
                SELECT WorkOrderID__c, Dispenser_Number__c,Is_Progressive__c,Remark__c, Dispenser_Name__c, Live_Reading__c, Opening_Reading__c,
                Jumping_Qty__c, Other_Qty__c, Calibration_Qty__c, Closing_Reading__c, Difference_Of_Open_and_Close_Reading__c,Point_Number__c,
                Progressive_Remark__c,Dispensor__c
                FROM Dispenser_Point__c
                WHERE WorkOrderID__c IN :recordIds AND Live__c = true
                // ORDER BY Dispenser_Number__c DESC
                ORDER BY Point_Number__c asc
            ]) {
                if (!dispenserLiveMap.containsKey(dp.WorkOrderID__c)) {
                    dispenserLiveMap.put(dp.WorkOrderID__c, new List<Dispenser_Point__c>());
                }
                dispenserLiveMap.get(dp.WorkOrderID__c).add(dp);
            }
            
            // Bulkify ContentDocumentLink and ContentVersion queries
            Map<Id, String> workOrderToFileUrlMap = new Map<Id, String>();
            
            // Query all ContentDocumentLinks for all WorkOrders at once
            List<ContentDocumentLink> allDocLinks = [
                SELECT ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :recordIds
            ];
            
            // Collect all ContentDocumentIds
            Set<Id> allDocIds = new Set<Id>();
            Map<Id, Set<Id>> workOrderToDocIdsMap = new Map<Id, Set<Id>>();
            
            for (ContentDocumentLink link : allDocLinks) {
                allDocIds.add(link.ContentDocumentId);
                
                if (!workOrderToDocIdsMap.containsKey(link.LinkedEntityId)) {
                    workOrderToDocIdsMap.put(link.LinkedEntityId, new Set<Id>());
                }
                workOrderToDocIdsMap.get(link.LinkedEntityId).add(link.ContentDocumentId);
            }
            
            // Query all ContentVersions at once
            if (!allDocIds.isEmpty()) {
                String fileTitle = System.Label.CNG_PDF_Signature_File_Name;
                
                List<ContentVersion> allContentVersions = [
                    SELECT Id, ContentDocumentId, CreatedDate
                    FROM ContentVersion 
                    WHERE ContentDocumentId IN :allDocIds 
                    AND Title = :fileTitle
                    ORDER BY CreatedDate DESC
                ];
                
                // Map ContentDocumentId to the latest ContentVersion
                Map<Id, Id> docIdToVersionIdMap = new Map<Id, Id>();
                for (ContentVersion cv : allContentVersions) {
                    if (!docIdToVersionIdMap.containsKey(cv.ContentDocumentId)) {
                        docIdToVersionIdMap.put(cv.ContentDocumentId, cv.Id);
                    }
                }
                
                // Build map of WorkOrder to file URL
                for (Id woId : workOrderToDocIdsMap.keySet()) {
                    for (Id docId : workOrderToDocIdsMap.get(woId)) {
                        if (docIdToVersionIdMap.containsKey(docId)) {
                            workOrderToFileUrlMap.put(woId, '/sfc/servlet.shepherd/version/download/' + docIdToVersionIdMap.get(docId));
                            break;
                        }
                    }
                }
            }
            
            // Process each WorkOrder
            for (WorkOrder ticket : workOrders) {
                WorkOrderWrapper wrapper = new WorkOrderWrapper();
                wrapper.ticket = ticket;
                wrapper.useDualColumn=true;
                // Dates
                if (ticket.From_Date__c != null) {
                    wrapper.formattedFromDate = formatDate(ticket.From_Date__c);
                }
                if (ticket.To_Date__c != null) {
                    wrapper.formattedToDate = formatDate(ticket.To_Date__c);
                }
                if (ticket.Approvar_Date__c != null) {
                    wrapper.approvarDate = formatDate(ticket.Approvar_Date__c);
                }
                // if (ticket.Check_In_Date_Time__c != null) {
                    //     wrapper.checkInDate = formatDate(ticket.Check_In_Date_Time__c.date());
                    //     wrapper.checkInTime = formatTime(ticket.Check_In_Date_Time__c);
                // }
                // if (ticket.Check_Out_Date_Time__c != null) {
                    //     wrapper.checkOutDate = formatDate(ticket.Check_Out_Date_Time__c.date());
                    //     wrapper.checkOutTime = formatTime(ticket.Check_Out_Date_Time__c);
                // }
                if (ticket.Check_Out_Date_Time__c != null) {
                    DateTime dt = ticket.Check_Out_Date_Time__c;
                    String formattedDateTime = dt.format('dd-MM-yyyy HH:mm:ss');
                    wrapper.checkOutDate = formattedDateTime.substring(0, 10);   // dd-MM-yyyy
                    wrapper.checkOutTime = formattedDateTime.substring(11);      // HH:mm:ss
                }
                if (ticket.Approval_Date_Time__c != null) {
                    DateTime dt = ticket.Approval_Date_Time__c;
                    String formattedDateTime = dt.format('dd-MM-yyyy HH:mm:ss');
                    wrapper.approvarDate = formattedDateTime.substring(0, 10);   // dd-MM-yyyy
                    wrapper.approvarTime = formattedDateTime.substring(11);
                }
                if(ticket.Live_Reading_Date_Time__c != null) {
                    DateTime dt = ticket.Live_Reading_Date_Time__c;
                    
                    // Convert to IST directly using format
                    String formattedDateTime = dt.format('dd-MM-yyyy HH:mm:ss');
                    
                    // Split into Date and Time
                    wrapper.liveReadingDate = formattedDateTime.substring(0, 10);   // dd-MM-yyyy
                    wrapper.liveReadingTime = formattedDateTime.substring(11);      // HH:mm:ss

                }
                if (ticket.StartDate != null) {
                    wrapper.startDate = formatDate(ticket.StartDate.date());
                }
                
                // Use resized image from cache if available, otherwise use original URL
                if (resizedImagesCache.containsKey(ticket.Id)) {
                    wrapper.fileDownloadUrl = resizedImagesCache.get(ticket.Id);
                } else if (workOrderToFileUrlMap.containsKey(ticket.Id)) {
                    wrapper.fileDownloadUrl = workOrderToFileUrlMap.get(ticket.Id);
                }
                
                // Dispensers
                wrapper.dispenserListLeft = new List<DispenserData>();
                wrapper.dispenserListRight = new List<DispenserData>();
                List<DispenserData> allDispensers = new List<DispenserData>();
                wrapper.totalCalibration = 0;
                wrapper.totalJumping = 0;
                wrapper.totalOthers = 0;
                wrapper.totalSale = 0;
                yesNo=true;
                wrapper.remarks=New List<String>();
                for (Dispenser_Point__c dp : (dispenserMap.get(ticket.Id) != null ? dispenserMap.get(ticket.Id) : new List<Dispenser_Point__c>())) {
                    // if(dp.Is_Progressive__c=='No'){
                        //     yesNo=false;
                        //     if(dp.Remark__c!=null)
                        //         wrapper.remarks.add(dp.Remark__c);
                    // }
                    Decimal open = dp.Opening_Reading__c != null ? dp.Opening_Reading__c : 0;
                    Decimal close = dp.Closing_Reading__c != null ? dp.Closing_Reading__c : 0;
                    Decimal diff = dp.Difference_Of_Open_and_Close_Reading__c != null ? dp.Difference_Of_Open_and_Close_Reading__c : (close - open);
                    Decimal calibration = dp.Calibration_Qty__c != null ? dp.Calibration_Qty__c : 0;
                    Decimal jumping = dp.Jumping_Qty__c != null ? dp.Jumping_Qty__c : 0;
                    Decimal others = dp.Other_Qty__c != null ? dp.Other_Qty__c : 0;
                    
                    wrapper.totalCalibration += calibration;
                    wrapper.totalJumping += jumping;
                    wrapper.totalOthers += others;
                    
                    allDispensers.add(new DispenserData(dp.Dispenser_Name__c, open, close, diff, dp.Live_Reading__c));
                    wrapper.totalSale += diff;
                }
                
                wrapper.totalReadingJump = wrapper.totalCalibration + wrapper.totalJumping + wrapper.totalOthers;
                wrapper.overallQuantity = wrapper.totalSale - wrapper.totalReadingJump;
                wrapper.totalReading = ticket.Final_Meter_Reading__c != null ? ticket.Final_Meter_Reading__c : 0;
                wrapper.totalConsumption = wrapper.totalSale - wrapper.totalReading;
                
                // Split columns
                Integer totalCount = allDispensers.size();
                
                for (Integer i = 0; i < 11; i++) {
                    if (i < totalCount) {
                        wrapper.dispenserListLeft.add(allDispensers[i]);
                    } else {
                        wrapper.dispenserListLeft.add(new DispenserData('', null, null, null,null));
                    }
                }
                
                for (Integer i = 11; i < 22; i++) {
                    if (i < totalCount) {
                        wrapper.dispenserListRight.add(allDispensers[i]);
                    } else {
                        wrapper.dispenserListRight.add(new DispenserData('', null, null, null,null));
                    }
                }
                
                List<DispenserData> liveDispensers = new List<DispenserData>();
                for (Dispenser_Point__c dp : (dispenserLiveMap.get(ticket.Id) != null ? dispenserLiveMap.get(ticket.Id) : new List<Dispenser_Point__c>())) {
                    if(dp.Is_Progressive__c=='No'){
                        yesNo=false;
                        if(dp.Progressive_Remark__c!=null)
                            wrapper.remarks.add(dp.Progressive_Remark__c);
                    }
                    
                    liveDispensers.add(new DispenserData(dp.Dispensor__c, null, null, null,dp.Live_Reading__c));
                }
                
                wrapper.liveDispenserListLeft  = new List<DispenserData>();
                wrapper.liveDispenserListRight = new List<DispenserData>();
                Integer liveCount = liveDispensers.size();
                
                // Fill left column: indices 0..10
                for (Integer i = 0; i < 11; i++) {
                    if (i < liveCount) {
                        wrapper.liveDispenserListLeft.add(liveDispensers[i]);
                    } else {
                        wrapper.liveDispenserListLeft.add(new DispenserData('', null, null, null, null));
                    }
                }
                
                // Fill right column: indices 11..21
                for (Integer i = 11; i < 22; i++) {
                    if (i < liveCount) {
                        wrapper.liveDispenserListRight.add(liveDispensers[i]);
                    } else {
                        wrapper.liveDispenserListRight.add(new DispenserData('', null, null, null, null));
                    }
                }
                
                tickets.add(wrapper);
            }
        }
    }
    
    private String formatDate(Date d) {
        return (d.day() < 10 ? '0' : '') + d.day() + '-' +
            (d.month() < 10 ? '0' : '') + d.month() + '-' +
            d.year();
    }
    
    private String formatTime(Datetime dt) {
        return (dt.hour() < 10 ? '0' : '') + dt.hour() + ':' +
            (dt.minute() < 10 ? '0' : '') + dt.minute() + ':' +
            (dt.second() < 10 ? '0' : '') + dt.second();
    }
    
    public class DispenserData {
        public String pointName { get; set; }
        public Decimal opening { get; set; }
        public Decimal closing { get; set; }
        public Decimal difference { get; set; }
        public Decimal live { get; set; }
        
        public DispenserData(String name, Decimal open, Decimal close, Decimal diff,Decimal liveReading) {
            pointName = name;
            opening = open;
            closing = close;
            difference = diff;
            live = liveReading;
        }
    }
    public class WorkOrderWrapper {
        public WorkOrder ticket { get; set; }
        public String checkInDate { get; set; }
        public String checkOutDate { get; set; }
        public String checkInTime { get; set; }
        public String checkOutTime { get; set; }
        public String formattedFromDate { get; set; }
        public String formattedToDate { get; set; }
        public Boolean useDualColumn { get; set; }
        public String approvarDate { get; set; }
        public String approvarTime { get; set; }
        public String liveReadingDate { get; set; }
        public String liveReadingTime { get; set; }
        public String startDate { get; set; }
        public Decimal totalSale { get; set; }
        public Decimal totalReading { get; set; }
        public Decimal totalConsumption { get; set; }
        public Decimal totalCalibration { get; set; }
        public Decimal totalJumping { get; set; }
        Public List<String> remarks{get;set;}
        public Decimal totalOthers { get; set; }
        public Decimal totalReadingJump { get; set; }
        public Decimal overallQuantity { get; set; }
        public List<DispenserData> dispenserListLeft { get; set; }
        public List<DispenserData> dispenserListRight { get; set; }
        public List<DispenserData> liveDispenserListLeft { get; set; }
        public List<DispenserData> liveDispenserListRight { get; set; }
        public String fileDownloadUrl { get; set; }
    }
}