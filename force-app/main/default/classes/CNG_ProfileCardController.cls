public with sharing class CNG_ProfileCardController {

    @AuraEnabled
    public static void updateStatus(Id recordId, String statusValue) {
        if (recordId == null || String.isBlank(statusValue)) {
            throw new AuraHandledException('Invalid input');
        }

        SObject record = recordId.getSObjectType().newSObject(recordId);
        record.put('Status__c', statusValue);

        update record;
    }

    public class BillingInfoWrapper {
        @AuraEnabled public String billingCycle;
        @AuraEnabled public List<String> existingBillingPeriods;
    }

    @AuraEnabled(cacheable=true)
    public static BillingInfoWrapper getBillingInfo(Id stationId) {
        if (stationId == null) return null;

        BillingInfoWrapper wrap = new BillingInfoWrapper();

        Account acc = [
            SELECT Billing_Cycle__c
            FROM Account
            WHERE Id = :stationId
            LIMIT 1
        ];
        wrap.billingCycle = acc.Billing_Cycle__c;

        wrap.existingBillingPeriods = new List<String>();
        for (Invoice__c inv : [
            SELECT Billing_Period__c
            FROM Invoice__c
            WHERE Station__c = :stationId
        ]) {
            wrap.existingBillingPeriods.add(inv.Billing_Period__c);
        }

        return wrap;
    }



@AuraEnabled
public static List<Map<String, Object>> getRecords(
    String objectApiName,
    String recordId,
    String filter,
    String listName
) {
    if (String.isBlank(objectApiName)) {
        return new List<Map<String, Object>>();
    }

    // Define fields based on object
    List<String> fieldApiNames = new List<String>();
    String baseQuery = '';

    if (listName == 'Technical Complaint') {
        fieldApiNames = new List<String>{
            'Id', 'Name', 'CreatedDate', 'Category__c', 'Sub_Category__c', 
            'Closed_Date__c', 'Status__c', 'CreatedBy.Name'
        };
    }
    else if(listName=='Non Technical Complaint'){
        fieldApiNames = new List<String>{
            'Id', 'Category__c', 'Sub_Category__c', 
            'Status__c', 'Complaint_Description__c'
        };
    }
    else if(listName=='Retail Outlet Compliance'){
        fieldApiNames = new List<String>{
                    'Id', 'Document_Name__c', 'CreatedDate', 'Start_Date__c', 'Expiry_Date__c', 
                    'Status__c'
                };
    }
    else if(listName=='STC Card'){
        fieldApiNames = new List<String>{
                    'Id', 'STC_Number__c', 'STC_Name__c', 'Start_Date__c', 'Expiry_Date__c', 
                    'Status__c'
                };
    }
        baseQuery = 'SELECT ' + String.join(fieldApiNames, ', ') + ' FROM '+objectApiName+' WHERE Station__c = \'' + String.escapeSingleQuotes(recordId) + '\'';

    // Apply additional filter if provided
    if (!String.isBlank(filter)) {
        baseQuery += ' AND ' + filter;
    }

    // Query records
    List<SObject> records = Database.query(baseQuery);
    List<Map<String, Object>> result = new List<Map<String, Object>>();
for (SObject rec : records) {
    Map<String, Object> row = new Map<String, Object>();

    for (String f : fieldApiNames) {

        String keyName = f.replace('.', '');
        Object fieldValue;

        if (f.contains('.')) {
            List<String> parts = f.split('\\.');
            SObject parent = rec.getSObject(parts[0]);
            fieldValue = parent != null ? parent.get(parts[1]) : null;
        } else {
            fieldValue = rec.get(f);
        }

        // 🔹 FORMAT DATE
        if (fieldValue instanceof Date) {
            Date d = (Date) fieldValue;

            Datetime dt = Datetime.newInstance(
                d,
                Time.newInstance(0, 0, 0, 0)
            );

            row.put(keyName, dt.format('dd/MM/yyyy'));

        }
        // 🔹 FORMAT DATETIME
        else if (fieldValue instanceof Datetime) {
            Datetime dt = (Datetime) fieldValue;
            row.put(keyName, dt.format('dd/MM/yyyy'));
        }
        else {
            row.put(keyName, fieldValue);
        }
    }

    result.add(row);
}



    return result;
}

    @AuraEnabled(cacheable=true)
    public static string currentDistributorDetails(){
        try {
            User us=[SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
            return UserInfo.getName();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string currentstationDetails(Id stationId){
        try {
            return stationId==null?'':[
            SELECT Id,Name
            FROM Account
            WHERE Id = :stationId].Name;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

     @AuraEnabled
    public static String stationDetails(Id stationId) {
        if(stationId==null){
            return null;
        }
        return [
            SELECT Id,Name
            FROM Account
            WHERE Id = :stationId].Name;
    }

    @AuraEnabled
    public static void saveCompliance(
        String documentName,
        Date startDate,
        Date expiryDate,
        Id uploadedFileId,
        Id stationId
    ) {
        // Create Compliance Record
        Compliance__c roc = new Compliance__c(
            Document_Name__c = documentName,
            Start_Date__c = startDate,
            Expiry_Date__c = expiryDate,
            Station__c=stationId
        );
        insert roc;

        ContentDocumentLink cdl = new ContentDocumentLink(
        ContentDocumentId = uploadedFileId,
        LinkedEntityId = roc.Id,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert cdl;
    }
    @AuraEnabled
    public static void createComplaint(
        String category,
        String subCategory,
        String description,
        Id uploadedFileId,
        Id stationId
    ) {
        RecordType rt = [
        SELECT Id
        FROM RecordType
        WHERE DeveloperName = 'Non_Technical_Complaints'
        AND SObjectType = 'Complaint__c'
        LIMIT 1
    ];
        // Create Compliance Record
        Complaint__c roc = new Complaint__c(
            Category__c = category,
            Sub_Category__c = subCategory,
            Complaint_Description__c = description,
            Station__c=stationId,
            RecordTypeId=rt.Id,
            Status__c='Open'
        );
        insert roc;

        ContentDocumentLink cdl = new ContentDocumentLink(
        ContentDocumentId = uploadedFileId,
        LinkedEntityId = roc.Id,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert cdl;
    }
    @AuraEnabled
public static void saveSTCompliance(
    String stcName,
    String stcNumber,
    Date startDate,
    Date expiryDate,
    Id uploadedFileId,
    Id stationId
) {
    // Get Record Type
    RecordType rt = [
        SELECT Id
        FROM RecordType
        WHERE DeveloperName = 'STC_Card'
        AND SObjectType = 'Compliance__c'
        LIMIT 1
    ];

    // Create Compliance Record
    Compliance__c roc = new Compliance__c(
        STC_Name__c = stcName,
        STC_Number__c = stcNumber,
        Start_Date__c = startDate,
        Expiry_Date__c = expiryDate,
        RecordTypeId = rt.Id,
        Station__c=stationId
    );
    insert roc;

    // Link uploaded file to Compliance record
    ContentDocumentLink cdl = new ContentDocumentLink(
        ContentDocumentId = uploadedFileId,
        LinkedEntityId = roc.Id,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert cdl;
}

    @AuraEnabled
    public static String generateInvoice(
        String invoiceNumber,
        Date invoiceDate,
        String billDuration,
        Id stationId
    ) {
        // Basic validations
        if (String.isBlank(invoiceNumber)) {
            throw new AuraHandledException('Invoice Number is required');
        }

        if (invoiceDate == null) {
            throw new AuraHandledException('Invoice Date is required');
        }

        if (String.isBlank(billDuration)) {
            throw new AuraHandledException('Bill Duration is required');
        }
        if (String.isBlank(stationId)) {
            throw new AuraHandledException('Select Station before generating invoice');
        }
        
        Invoice__c inv = new Invoice__c();
        inv.Name = invoiceNumber;
        inv.Due_Date__c = invoiceDate;
        inv.Billing_Period__c = billDuration;
        inv.Station__c=stationId;
        insert inv;
        Product2 prod =[SELECT Id FROM Product2 WHERE Name='CNG Filling Service Charges' LIMIT 1];
        Invoice_Line_Item__c ln=new Invoice_Line_Item__c();
        ln.Invoice__c=inv.Id;
        //ln.Quantity__c=1;
        ln.Product__c=prod.Id;
        insert ln;

        return 'Invoice generated successfully';
    }


    @AuraEnabled(cacheable=true)
    public static Invoice__c getInvoiceDetails(Id invoiceId) {
        return [
            SELECT Id,
                   Billing_Period__c,Buyer__c,Consignee__c,Due_Date__c,Total_Amount__c
            FROM Invoice__c
            WHERE Id = :invoiceId
            LIMIT 1
        ];
    }


    @AuraEnabled
    public static Account getAccountDetails(Id stationId) {
        if (stationId==null) {
            return null;
        }
        return [
            SELECT
                Id,
                Parent.Name,
                Parent.Phone,Parent.Email_Id__c,
                PAN_No__c,
                IFSC_Code__c,
                Name,
                BP_Number__c,
                Ship_To_Party_Code__c,
                Vendor_Code__c,
                GST_No__c,
                Station_Nick_Name__c,
                Account_Ref_Number__c,
                SAP_Code__c,
                Purchase_Order_Number__c,Model__c,Connectivity__c,No_of_Compressor__c,Compressor_Capacity__c,Station_Type__c,No_of_Dispensers__c,Zone__c,AccountNumber,BillingStreet,BillingState,BillingCity,BillingPostalCode,BillingCountry,(
                    SELECT Id, Capacity__c
                    FROM Compressors__r
                    ORDER BY CreatedDate
                )
            FROM Account
            WHERE Id =: stationId LIMIT 1
        ];
    }
    
    @AuraEnabled
    public static ContactWrapper getContactDetails(Id recordId) {
        if (recordId==null) {
            return null;
        }

        Account st=[
            SELECT
                Id,MIC_User__r.Name,MIC_User__r.Phone,MIC_User__r.Email,ZIC_User__r.Name,ZIC_User__r.Phone,ZIC_User__r.Email
            FROM Account
            WHERE Id =:recordId  LIMIT 1
        ];
        List<Emergency_Contact__mdt> contacts=[SELECT Id,Phone__c,Name__c FROM Emergency_Contact__mdt];

        ContactWrapper wrapper = new ContactWrapper();

        // 🔹 Level 1 - MIC
        wrapper.mic = new ContactInfo(
            st.MIC_User__r != null ? st.MIC_User__r.Name : null,
            st.MIC_User__r != null ? st.MIC_User__r.Phone : null,
            st.MIC_User__r != null ? st.MIC_User__r.Email : null
        );

        // // 🔹 Level 2 - ZIC
        wrapper.zic = new ContactInfo(
            st.ZIC_User__r != null ? st.ZIC_User__r.Name : null,
            st.ZIC_User__r != null ? st.ZIC_User__r.Phone : null,
            st.ZIC_User__r != null ? st.ZIC_User__r.Email : null
        );

        // 🔹 Other Emergency Numbers
        Map<String, String> otherEmergencyNumbers = new Map<String, String>();
        for (Emergency_Contact__mdt ec : contacts) {
            otherEmergencyNumbers.put(ec.Name__c, ec.Phone__c);
        }

        // 🔹 Dial Before Dig (Hardcoded / Metadata driven if needed)
        wrapper.dialBeforeDigPhone = otherEmergencyNumbers.get('Contact No');
        wrapper.dialBeforeDigEmail = otherEmergencyNumbers.get('Email');
        wrapper.fire = otherEmergencyNumbers.get('Fire');
        wrapper.mglcontrolroom = otherEmergencyNumbers.get('MGL Control Room');
        wrapper.ambulance = otherEmergencyNumbers.get('Ambulance');
        wrapper.police = otherEmergencyNumbers.get('Police');

        return wrapper;
    }

    public class ContactInfo {
        @AuraEnabled public String name;
        @AuraEnabled public String phone;
        @AuraEnabled public String email;
        public ContactInfo(String name, String phone, String email) {
            this.name = name;
            this.phone = phone;
            this.email = email;
        }
    }
    
    public class ContactWrapper {
        // Dial Before Dig
        @AuraEnabled public String dialBeforeDigPhone;
        @AuraEnabled public String dialBeforeDigEmail;

        // Level 1 - MIC
        @AuraEnabled public ContactInfo mic;

        // Level 2 - ZIC
        @AuraEnabled public ContactInfo zic;

        // Other Emergency Numbers
        @AuraEnabled public String fire;
        @AuraEnabled public String mglcontrolroom;
        @AuraEnabled public String ambulance;
        @AuraEnabled public String police;
    }

}