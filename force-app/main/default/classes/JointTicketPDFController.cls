/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 22-09-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   05-08-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class JointTicketPDFController {
    public WorkOrder ticket { get; set; }
    public Boolean useDualColumn { get; set; }
    public String fileDownloadUrl { get; set; }
    public String approvarDate { get; set; }
    public String approvarTime { get; set; }
    public String startDate { get; set; }
    public String checkInDate { get; set; }
    public String checkInTime { get; set; }
    public String formattedFromDate { get; set; }
    public String formattedToDate { get; set; }
    public Decimal totalSale { get; set; }
    public List<String> remarks { get; set; }
    public Boolean yesNo { get; set; }
    public Decimal totalReading { get; set; }
    public Decimal totalConsumption { get; set; }
    public Decimal totalCalibration { get; set; }
    public Decimal totalJumping { get; set; }
    public Decimal totalOthers { get; set; }
    public Decimal totalReadingJump { get; set; }
    public Decimal overallQuantity { get; set; }
    public List<DispenserData> dispenserListLeft { get; set; }
    public List<DispenserData> dispenserListRight { get; set; }
    public List<DispenserData> liveDispenserListLeft { get; set; }
    public List<DispenserData> liveDispenserListRight { get; set; }
    public String checkOutDate { get; set; }
    public String checkOutTime { get; set; }
    public String liveReadingDate { get; set; }
    public String liveReadingTime { get; set; }
    
    public List<Integer> getROW_COUNT() {
        List<Integer> rows = new List<Integer>();
        for (Integer i = 1; i <= 11; i++) {
            rows.add(i);
        }
        return rows;
    }
    
    public JointTicketPDFController() {
        Id recordId = ApexPages.currentPage().getParameters().get('id');
        
        // Load main ticket record
        ticket = [
            SELECT Customer_Name__c,Assigned_Meter_Reader__r.RelatedRecord.Name,Account.Representative_Company__c,Check_In_Date_Time__c,Approvar_Date__c,Approvar_User__r.Name,Account.Location__c,Assigned_Meter_Reader__r.Name,From_Date__c,To_Date__c,Account.Name, Current_Meter_Reading__c,Check_Out_Date_Time__c,
            Turbine_Meter_Reading__c, Final_Meter_Reading__c,Approval_Date_Time__c,Live_Reading_Date_Time__c,
            TotalPrice, StartDate, EndDate
            FROM WorkOrder
            WHERE Id = :recordId
            LIMIT 1
        ];
        if (ticket.From_Date__c != null) {
            Date d = ticket.From_Date__c;
            String dayStr = (d.day() < 10 ? '0' : '') + d.day();
            String monthStr = (d.month() < 10 ? '0' : '') + d.month();
            String yearStr = String.valueOf(d.year());
            
            formattedFromDate = dayStr + '-' + monthStr + '-' + yearStr;
        }
        if (ticket.To_Date__c != null) {
            Date d = ticket.To_Date__c;
            String dayStr = (d.day() < 10 ? '0' : '') + d.day();
            String monthStr = (d.month() < 10 ? '0' : '') + d.month();
            String yearStr = String.valueOf(d.year());
            
            formattedToDate = dayStr + '-' + monthStr + '-' + yearStr;
        }
        if (ticket.StartDate != null) {
            Date d = Date.valueOf(ticket.StartDate);
            String dayStr = String.valueOf(d.day());
            String monthStr = String.valueOf(d.month());
            String yearStr = String.valueOf(d.year());
            
            startDate = dayStr + '-' + monthStr + '-' + yearStr;
        }
        if (ticket.Check_In_Date_Time__c != null) {
            DateTime dt = ticket.Check_In_Date_Time__c;
            // Format Date Part
            String dayStr = (dt.day() < 10 ? '0' : '') + dt.day();
            String monthStr = (dt.month() < 10 ? '0' : '') + dt.month();
            String yearStr = String.valueOf(dt.year());
            checkInDate = dayStr + '-' + monthStr + '-' + yearStr;
            
            // Format Time Part (HH:mm:ss)
            String hourStr = (dt.hour() < 10 ? '0' : '') + dt.hour();
            String minuteStr = (dt.minute() < 10 ? '0' : '') + dt.minute();
            String secondStr = (dt.second() < 10 ? '0' : '') + dt.second();
            checkInTime = hourStr + ':' + minuteStr + ':' + secondStr;
        }
        if (ticket.Check_Out_Date_Time__c != null) {
            DateTime dt = ticket.Check_Out_Date_Time__c;
            
            // Convert to IST directly using format
            String formattedDateTime = dt.format('dd-MM-yyyy HH:mm:ss');
            
            // Split into Date and Time
            checkOutDate = formattedDateTime.substring(0, 10);   // dd-MM-yyyy
            checkOutTime = formattedDateTime.substring(11);      // HH:mm:ss
        }
        if (ticket.Approval_Date_Time__c != null) {
            // Date d = ticket.To_Date__c;
            // String dayStr = (d.day() < 10 ? '0' : '') + d.day();
            // String monthStr = (d.month() < 10 ? '0' : '') + d.month();
            // String yearStr = String.valueOf(d.year());
            
            // approvarDate = dayStr + '-' + monthStr + '-' + yearStr;

            DateTime dt = ticket.Approval_Date_Time__c;
            
            // Convert to IST directly using format
            String formattedDateTime = dt.format('dd-MM-yyyy HH:mm:ss');
            
            // Split into Date and Time
            approvarDate = formattedDateTime.substring(0, 10);   // dd-MM-yyyy
            approvarTime = formattedDateTime.substring(11); 
        }
        if(ticket.Live_Reading_Date_Time__c != null) {
            DateTime dt = ticket.Live_Reading_Date_Time__c;
            
            // Convert to IST directly using format
            String formattedDateTime = dt.format('dd-MM-yyyy HH:mm:ss');
            
            // Split into Date and Time
            liveReadingDate = formattedDateTime.substring(0, 10);   // dd-MM-yyyy
            liveReadingTime = formattedDateTime.substring(11);      // HH:mm:ss

        }
        
        // Load dispenser readings
        List<Dispenser_Point__c> dispensers = [
            SELECT Dispenser_Number__c,Dispenser_Name__c,Remark__c,Is_Progressive__c,Live_Reading__c, Opening_Reading__c,Jumping_Qty__c,Other_Qty__c,Calibration_Qty__c, Closing_Reading__c, Difference_Of_Open_and_Close_Reading__c,
            Progressive_Remark__c,Live__c
            FROM Dispenser_Point__c
            WHERE WorkOrderID__c = :recordId
            ORDER BY Dispenser_Number_Value__c asc
        ];

        List<Dispenser_Point__c> liveDispensersRec = [
            SELECT Dispenser_Number__c,Dispenser_Name__c,Remark__c,Is_Progressive__c,Live_Reading__c, Opening_Reading__c,Jumping_Qty__c,Other_Qty__c,Calibration_Qty__c, Closing_Reading__c, Difference_Of_Open_and_Close_Reading__c,
            Progressive_Remark__c,Live__c,Point_Number__c,Dispensor__c
            FROM Dispenser_Point__c
            WHERE WorkOrderID__c = :recordId AND Live__c = true
            ORDER BY Point_Number__c asc
        ];
        System.debug('dispensers::'+dispensers);
        if (recordId != null) {
            // Step 1: Get all ContentDocumentLinks for this Work Order
            List<ContentDocumentLink> docLinks = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
            ];
            
            Set<Id> docIds = new Set<Id>();
            for (ContentDocumentLink link : docLinks) {
                docIds.add(link.ContentDocumentId);
            }
            
            // Step 2: Query ContentVersion by title and document IDs
            if (!docIds.isEmpty()) {
                String fileTitle = System.Label.CNG_PDF_Signature_File_Name;
                List<ContentVersion> versions = [
                    SELECT Id, Title
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :docIds AND Title = :fileTitle
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                System.debug('Authorised Signature:'+versions);
                if (!versions.isEmpty()) {
                    fileDownloadUrl ='/sfc/servlet.shepherd/version/download/' + versions[0].Id;
                }
                System.debug('fileDown::'+fileDownloadUrl);
            }
        }
        // Prepare totals
        totalSale = 0;
        List<DispenserData> allDispensers = new List<DispenserData>();
        List<DispenserData> liveDispensers = new List<DispenserData>();
        totalCalibration=0;
        totalJumping = 0;
        totalOthers = 0;
        yesNo=true;
        remarks= new List<String>();
        for (Dispenser_Point__c dp : dispensers) {
            // if(dp.Is_Progressive__c=='No' && dp.Live__c==true){
            //     yesNo=false;
            //     if(dp.Progressive_Remark__c!=null)
            //         remarks.add(dp.Progressive_Remark__c);
            // }
            Decimal open = dp.Opening_Reading__c != null ? dp.Opening_Reading__c : 0;
            Decimal close = dp.Closing_Reading__c != null ? dp.Closing_Reading__c : 0;
            Decimal diff = dp.Difference_Of_Open_and_Close_Reading__c != null
                ? dp.Difference_Of_Open_and_Close_Reading__c
                : (close - open);
            
            Decimal calibration = dp.Calibration_Qty__c != null ? dp.Calibration_Qty__c : 0;
            Decimal jumping = dp.Jumping_Qty__c != null ? dp.Jumping_Qty__c : 0;
            Decimal others = dp.Other_Qty__c != null ? dp.Other_Qty__c : 0;
            
            totalCalibration += calibration;
            totalJumping += jumping;
            totalOthers += others;
            
            allDispensers.add(new DispenserData(dp.Dispenser_Name__c, open, close, diff,dp.Live_Reading__c));
            // if(dp.Live__c==true){
            //     liveDispensers.add(new DispenserData(dp.Dispenser_Name__c, open, close, diff,dp.Live_Reading__c));
            // }
            totalSale += diff;
        }
        System.debug('allDispensers::'+allDispensers);
        totalReadingJump=totalCalibration+totalJumping+totalOthers;
        overallQuantity=totalSale-totalReadingJump;
        // Force dual column mode always
        useDualColumn = true;
        dispenserListLeft = new List<DispenserData>();
        dispenserListRight = new List<DispenserData>();
        
        Integer totalCount = allDispensers.size();
        
        for (Integer i = 0; i < 11; i++) {
            if (i < totalCount) {
                dispenserListLeft.add(allDispensers[i]);
            } else {
                dispenserListLeft.add(new DispenserData('', null, null, null,null));
            }
        }
        
        for (Integer i = 11; i < 22; i++) {
            if (i < totalCount) {
                dispenserListRight.add(allDispensers[i]);
            } else {
                dispenserListRight.add(new DispenserData('', null,null,null,null));
            }
        }
        
        totalReading = ticket.Final_Meter_Reading__c != null ? ticket.Final_Meter_Reading__c : 0;
        totalConsumption = totalSale - totalReading;

        for (Dispenser_Point__c dp : liveDispensersRec) {
            if(dp.Is_Progressive__c=='No'){
                yesNo=false;
                if(dp.Progressive_Remark__c!=null)
                    remarks.add(dp.Progressive_Remark__c);
            }
            
            liveDispensers.add(new DispenserData(dp.Dispensor__c, null, null, null,dp.Live_Reading__c));
        }

        liveDispenserListLeft = new List<DispenserData>();
        liveDispenserListRight = new List<DispenserData>();
        Integer liveCount = liveDispensers.size();

        for (Integer i = 0; i < 11; i++) {
            if (i < liveCount) {
                liveDispenserListLeft.add(liveDispensers[i]);
            } else {
                liveDispenserListLeft.add(new DispenserData('', null, null, null,null));
            }
        }

        for( Integer i = 11; i < 22; i++) {
            if (i < liveCount) {
                liveDispenserListRight.add(liveDispensers[i]);
            } else {
                liveDispenserListRight.add(new DispenserData('', null,null,null,null));
            }
        }
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
}