public without sharing class AS_WorkOrderReceiptController {
    
    public class ReceiptData {
        public String mode {get; set;}
        public String receiptNo {get; set;}
        public String customerName {get; set;}
        public String caNumber {get; set;}
        public String bpNumber {get; set;}
        public String paymentMode {get; set;}
        public String paymentDate {get; set;}
        public String transactionId {get; set;}
        public String chequeNumber {get; set;}
        public Date chequeDate {get; set;}
        public Decimal chequeAmt {get; set;}
        public String bankName {get; set;}
        public String branchName {get; set;}
        public Decimal dueAmount {get; set;}
        public String agentName {get; set;}
        public String agencyName {get; set;}
        public Decimal amountReceived {get; set;}
        
        //Cancelled Receipt
        public Decimal cancelledAmount {get; set;}
        public Date cancelledDate {get; set;}
        public String cancelledReason {get; set;}
        public String cancelledBy {get; set;}
        public String cancellationReceiptNo {get; set;}
        public Boolean isCancelledPage {get; set;}
        
    }
    
    public List<ReceiptData> receiptList {get; set;}
    
    public AS_WorkOrderReceiptController() {
        receiptList = new List<ReceiptData>();
        
        Id workOrderId = ApexPages.currentPage().getParameters().get('id');
        String mode = ApexPages.currentPage().getParameters().get('mode');
        Boolean isCancelledFlag =
            ApexPages.currentPage().getParameters().get('isCancelled') == 'true';
        
        Boolean isCancelledReceipt = (mode == 'Cheque' && isCancelledFlag);
        
        if(mode == 'Cheque'){
            
            String paymentStatusCondition = isCancelledReceipt
                ? 'Payment_Status__c = \'Cancelled\''
                : 'Payment_Status__c != \'Cancelled\'';
            
            List<Payment__c> payments = Database.query(
                'SELECT Id, Work_Order__r.WorkOrderNumber, Work_Order__r.Customer_Full_Name__c,' +
                ' Work_Order__r.Account.CA_Number__c, Work_Order__r.Account.BP_Number__c,' +
                ' Work_Order__r.Payment_Mode__c, Cheque_Number__c, Work_Order__r.Due_Amount__c,' +
                ' Work_Order__r.Agent_Name_Formula__c, Work_Order__r.Agency_Name_Formula__c,' +
                ' Work_Order__r.Amount_Received__c, Bank_Name__c, Cheque_Date__c,' +
                ' Branch_Name__c, Work_Order__r.Payment_Date__c, Cheque_Amount__c, Receipt_Number__c,' +
                ' Work_Order__r.R_T_Agency__r.AgencyCode__c, Work_Order__r.Agent__r.Agent_ID__c,' +
                ' Cancel_Reason_c__c, Payment_Mode__c, Payment_Date__c, CancelledByUser__c, CancelledByUser__r.Name, CAN_Receipt_No__c, Cancelled_Date_Time__c' +
                ' FROM Payment__c' +
                ' WHERE Work_Order__c = :workOrderId AND ' + paymentStatusCondition +
                ' ORDER BY CreatedDate DESC LIMIT 10'
                );
            
            for (Payment__c payment : payments) {
                
                ReceiptData rd = new ReceiptData();
                rd.mode = 'Cheque';
                
                rd.receiptNo = getReceiptNo(
                    payment.Work_Order__r.R_T_Agency__r.AgencyCode__c,
                payment.Work_Order__r.Agent__r.Agent_ID__c,
                payment.Receipt_Number__c
                    );
                
                rd.customerName   = payment.Work_Order__r.Customer_Full_Name__c;
                rd.caNumber       = payment.Work_Order__r.Account.CA_Number__c;
                rd.bpNumber       = payment.Work_Order__r.Account.BP_Number__c;
                rd.paymentMode    = isCancelledReceipt
                    ? 'Cheque'
                    : payment.Work_Order__r.Payment_Mode__c;
                rd.paymentDate    = String.valueOf(
                    isCancelledFlag
                    ? String.valueOf(payment.Payment_Date__c)
                    : String.valueOf(payment.Work_Order__r.Payment_Date__c)
                    );
                rd.transactionId  = '';
                rd.chequeNumber   = payment.Cheque_Number__c;
                rd.chequeDate     = payment.Cheque_Date__c;
                rd.bankName       = payment.Bank_Name__c;
                rd.branchName     = payment.Branch_Name__c;
                rd.chequeAmt      = payment.Cheque_Amount__c;
                rd.dueAmount      = payment.Work_Order__r.Due_Amount__c;
                rd.agentName      = payment.Work_Order__r.Agent_Name_Formula__c;
                rd.agencyName     = payment.Work_Order__r.Agency_Name_Formula__c;
                rd.amountReceived = payment.Cheque_Amount__c;
                
                // Cancelled-specific fields
                if (isCancelledReceipt) {
                    rd.cancelledDate = payment.Cancelled_Date_Time__c != null
                        ? payment.Cancelled_Date_Time__c.date()
                        : null;
                    rd.cancelledReason = payment.Cancel_Reason_c__c;
                    rd.cancelledBy     = payment.CancelledByUser__r.Name;
                    rd.cancellationReceiptNo = payment.CAN_Receipt_No__c;
                    rd.isCancelledPage = true;
                } else {
                    rd.cancelledDate   = null;
                    rd.cancelledReason = null;
                    rd.cancelledBy     = null;
                    rd.cancellationReceiptNo = null;
                    rd.isCancelledPage = false;
                }
                
                receiptList.add(rd);
            }
        } else {
            for(WorkOrder wOrder : [
                SELECT Id, WorkOrderNumber, Customer_Full_Name__c, Account.CA_Number__c,
                       Account.BP_Number__c, Payment_Mode__c, Transaction_Id__c,
                       Due_Amount__c, Agent_Name_Formula__c, Agency_Name_Formula__c,
                       Amount_Received__c, Payment_Date__c, R_T_Agency__r.AgencyCode__c,
                	   Agent__r.Agent_ID__c
                FROM WorkOrder
                WHERE Id = :workOrderId
                LIMIT 1
            ]){
                ReceiptData rd = new ReceiptData();
                rd.mode = 'Online';
                rd.receiptNo = getReceiptNo(
                    wOrder.R_T_Agency__r.AgencyCode__c,
                wOrder.Agent__r.Agent_ID__c,
                wOrder.WorkOrderNumber
                    );
                rd.customerName = wOrder.Customer_Full_Name__c;
                rd.caNumber = wOrder.Account.CA_Number__c;
                rd.bpNumber = wOrder.Account.BP_Number__c;
                rd.paymentMode = wOrder.Payment_Mode__c;
                rd.paymentDate = String.valueOf(wOrder.Payment_Date__c);
                rd.transactionId = wOrder.Transaction_Id__c;
                rd.chequeNumber = '';
                rd.chequeDate = null;
                rd.bankName = '';
                rd.branchName = '';
                rd.chequeAmt = null;
                rd.dueAmount = wOrder.Due_Amount__c;
                rd.agentName = wOrder.Agent_Name_Formula__c;
                rd.agencyName = wOrder.Agency_Name_Formula__c;
                rd.amountReceived = wOrder.Amount_Received__c;
                
                //Cancelled Receipt
                rd.cancelledDate = null;
                rd.cancelledReason = null;
                rd.cancelledBy = null;
                rd.cancellationReceiptNo = null;
                rd.isCancelledPage = false;
                receiptList.add(rd);
            }
        }
    }
    
    public String getReceiptNo(String agencyCode, String agentCode, String autoNum){
        string series = autoNum.contains('-') ? autoNum.split('-')[1] : autoNum;
        return agencyCode +'/'+ agentCode +'/'+ series;
    }
}