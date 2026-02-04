public with sharing class AccountDetailsController1 {
    public class AccountWrapper {
        @AuraEnabled public Account account;
        @AuraEnabled public DeviceAllocationWrapper deviceAllocation;
        @AuraEnabled public Identification_Number__c idnumber;
        @AuraEnabled public Identification_Number__c domId;
        @AuraEnabled public MoveInOutWrapper servicecontract;
        @AuraEnabled public Chronology__c lastamountpaid;
        @AuraEnabled public Installation__c minimumcharges;
        @AuraEnabled public DeviceWrapper device;
        @AuraEnabled public ServiceContract serviceContractRec;
        @AuraEnabled public ServiceContract serviceContractNumber;
    }
    
    public class MoveInOutWrapper {
        @AuraEnabled 
        public String moveInDate;
        @AuraEnabled 
        public String moveOutDate; 
        @AuraEnabled 
        public String contractAccount;
        @AuraEnabled
        public String premiseId;
    }
    
    public class DeviceAllocationWrapper {
        @AuraEnabled 
        public String lastMeterReading;
        @AuraEnabled 
        public String latestMeterReadingType;
        @AuraEnabled 
        public Date lastMeterDate;
        @AuraEnabled 
        public String mrPerson;
    }

    // ✅ Added DeviceWrapper class
    public class DeviceWrapper {
        @AuraEnabled 
        public String deviceNumber;
        
        @AuraEnabled 
        public String meterNumber;
    }

    @AuraEnabled(cacheable=true)
    public static AccountWrapper getAccountDetails(Id accrcaseId) {
        AccountWrapper wrapper = new AccountWrapper();

        Id accountId;
        Id leadId;

        if (accrcaseId != null && accrcaseId.getSObjectType() == Case.SObjectType) {
            Case relatedCase = [
                SELECT Id, AccountId, Lead__c, Lead__r.Lead_No__c
                FROM Case
                WHERE Id = :accrcaseId
                LIMIT 1
            ];
            accountId = relatedCase.AccountId;
            leadId = relatedCase.Lead__c;
        } else {
            accountId = accrcaseId;
        }

        if (accountId == null && leadId == null) {
            return wrapper;
        }

        if (accountId != null) {
            wrapper.account = [
                SELECT Id, Name, Account_Email__c,Building_Name_Conn__c, Room__c, City__c, Postal_Code__c,Security_Deposit__c,Open__c,Credit__c,Last_Amount_Paid__c,Due__c,
                       Street__c, Street_Line_2__c, Street_Line_3__c, Street_Line_4__c, Street_Line_5__c,Secondary_Telephone__c,Type_Desc__c,
                       BP_Number__c, Connection_Object__c, Phone,VIP_Customer__c,Remarks__c,Installation__c,Floor__c,Building_Code__c,LMC__c, EBill__c,Last_Paid_Date__c  
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];

        List<ServiceContract> scList = [
    SELECT Id, AccountId, Contract_Account_Number__c
    FROM ServiceContract
    WHERE AccountId = :accountId
    ORDER BY CreatedDate ASC
    LIMIT 1
];

wrapper.serviceContractNumber = scList.isEmpty() ? null : scList[0];



            List<Move_In_Out__c> moveInOutRecords = [
                SELECT Id, Move_In_Date__c, Move_Out_Date__c,Contract_Account__c, Premise__c,
                    Latest_Meter_Reading__c, Latest_MR_Date__c, Latest_MR_Person__c,Installation_Name__c,Installation__c,Latest_MR_Type__c
                FROM Move_In_Out__c 
                WHERE Business_Partner__c = :wrapper.account.BP_Number__c AND Move_Out__c != null
                ORDER BY Move_Out__c DESC
                LIMIT 1
            ];

            // Convert first record into wrapper directly
            if (!moveInOutRecords.isEmpty()) {
                Move_In_Out__c mio = moveInOutRecords[0];
                wrapper.servicecontract = new MoveInOutWrapper();
                wrapper.servicecontract.moveInDate      = String.valueOf(mio.Move_In_Date__c);
                wrapper.servicecontract.moveOutDate     = String.valueOf(mio.Move_Out_Date__c);
                wrapper.servicecontract.contractAccount = mio.Contract_Account__c;
                wrapper.servicecontract.premiseId = mio.Premise__c;
            }

            // Initialize DeviceWrapper early
            wrapper.device = new DeviceWrapper();
            
            // Get Device Allocation data and Device data through Device Allocation
            if (!moveInOutRecords.isEmpty() && moveInOutRecords[0].Installation__c != null) {
                DeviceAllocationWrapper deviceAllocWrapper = new DeviceAllocationWrapper();
                deviceAllocWrapper.lastMeterReading = String.valueOf(moveInOutRecords[0].Latest_Meter_Reading__c);
                deviceAllocWrapper.lastMeterDate = moveInOutRecords[0].Latest_MR_Date__c;
                deviceAllocWrapper.mrPerson = moveInOutRecords[0].Latest_MR_Person__c;
                deviceAllocWrapper.latestMeterReadingType = moveInOutRecords[0].Latest_MR_Type__c;

                List<Device_Allocation__c> deviceAllocationList = [
                    SELECT Id,Installation_Number__c, Device__c, Device__r.Name, Device__r.Manuf_Serial_No__c
                    FROM Device_Allocation__c
                    WHERE Installation_Number__c = :moveInOutRecords[0].Installation__c
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                wrapper.deviceAllocation = deviceAllocWrapper;

                // ✅ Get Device data through Device Allocation
                if (!deviceAllocationList.isEmpty() && deviceAllocationList[0].Device__c != null) {
                    wrapper.device.deviceNumber = deviceAllocationList[0].Device__r.Name; // Device__c.Name
                    wrapper.device.meterNumber = deviceAllocationList[0].Device__r.Manuf_Serial_No__c; // Device__c.manuf_serial_no__c
                }
            }

            List<Chronology__c> lastamountpaid = [
                SELECT Id, Credit_Amt__c,Posting_Date__c 
                FROM Chronology__c
                WHERE Credit_Amt__c != null
                AND Credit_Amt__c != '0.0000'
                AND Business_Partner__c = :accountId
                AND Text__c ='Check Lot'
                ORDER BY Net_Due_Date__c DESC
                LIMIT 1
            ];

            wrapper.lastamountpaid = lastamountpaid.isEmpty() ? null : lastamountpaid[0];

            if (!moveInOutRecords.isEmpty() && moveInOutRecords[0].Installation_Name__c != null) {
                List<Installation__c> minimumcharges = [
                    SELECT Id, Charges_Valid_From__c, Charges_Valid_To__c, Minimum_Charges__c,Blocking_Reason__c,Blocking_Reason_Text__c,Sch_BD__c,Disconnection__c,disc_person__c,disc_date__c
                    FROM Installation__c 
                    WHERE Id = :moveInOutRecords[0].Installation_Name__c
                    LIMIT 1
                ];
                wrapper.minimumcharges = minimumcharges.isEmpty() ? null : minimumcharges[0];
            }

            List<Identification_Number__c> idList = [
                SELECT Id, ID_Number__c
                FROM Identification_Number__c
                WHERE BP__c = :accountId AND Type_Desc__c = 'Application Form'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            wrapper.idnumber = idList.isEmpty() ? null : idList[0];
            
            List<Identification_Number__c> domList = [
                SELECT Id, Type__c, Payment_Scheme__c
                FROM Identification_Number__c
                WHERE BP__c = :accountId AND Type__c LIKE '%DOM%'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            wrapper.domId = domList.isEmpty() ? null : domList[0];
        }
        
        if (wrapper.servicecontract != null && String.isNotBlank(wrapper.servicecontract.contractAccount)) {
            List<ServiceContract> scList = [
                SELECT Id, Name, StartDate, EndDate, Status, AccountId,Debit_Limit__c
                FROM ServiceContract
                WHERE Contract_Account_Number__c = :wrapper.servicecontract.contractAccount
                LIMIT 1
            ];
            
            if (!scList.isEmpty()) {
                // attach ServiceContract record to wrapper
                wrapper.serviceContractRec = scList[0];
                
                // Or map only needed fields
                wrapper.servicecontract.contractAccount = scList[0].Name; // Or keep Id
            }
        }

        return wrapper;
    }
    
    @AuraEnabled
    public static Decimal getTotalCashAmount(Id accountId) {
        // Use aggregate query instead of looping in Apex
        AggregateResult[] results = [
            SELECT SUM(Cash_Amount__c) total
            FROM Security_Deposit__c
            WHERE BP_Number__c = :accountId
            AND Status__c = 'Paid'
        ];
        
        // Handle null safely
        if (!results.isEmpty() && results[0].get('total') != null) {
            return (Decimal) results[0].get('total');
        }
        return 0;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getOpenCaseCount(Id accountId) {
        if (String.isBlank(accountId)) return 0;
        return [
            SELECT COUNT()
            FROM Case
            WHERE AccountId = :accountId
            AND IsClosed = false
        ];
    }
}