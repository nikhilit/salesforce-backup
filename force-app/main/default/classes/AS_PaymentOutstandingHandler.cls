public class AS_PaymentOutstandingHandler {
    
    public static void handleAfterUpdate(List<Payment_Outstanding__c> newList){
    
        Set<String> bpNumbers = new Set<String>();
        Map<String, Payment_Outstanding__c> bpToPaymentMap = new Map<String, Payment_Outstanding__c>();
        
        // Step 1 & 2 - filter and collect
        for(Payment_Outstanding__c po : newList){
            bpNumbers.add(po.BP_Number__c);
            bpToPaymentMap.put(po.BP_Number__c, po);
        }
        
        if(bpNumbers.isEmpty()) return;
        
        // Step 3 - Fetch WorkOrders
        List<WorkOrder> workOrders = [
            SELECT Id, Status, Customer_BP_Number__c, Account.BP_Number__c, 
            	   Amount_Received__c, Payment_Date__c, Payment_Mode__c, 
            	   Appointment_Status__c, Follow_up_Remarks__c, Other_Follow_Up_Remark__c,
            	   Due_Amount__c
            FROM WorkOrder
            WHERE (Customer_BP_Number__c IN :bpNumbers OR Account.BP_Number__c IN :bpNumbers)
              AND RecordType.DeveloperName = 'MGL_R_T'
              AND Status != 'Completed'
              AND StartDate <= TODAY
              AND EndDate >= TODAY
        ];
        
        if(workOrders.isEmpty()) return;
        
        List<WorkOrder> woToUpdate = new List<WorkOrder>();
        for(WorkOrder wo : workOrders){
            String bp = (wo.Customer_BP_Number__c != null) ? wo.Customer_BP_Number__c : 
                        (wo.Account != null ? wo.Account.BP_Number__c : null);
            
            if(bp == null || !bpToPaymentMap.containsKey(bp)) continue;
            
            Payment_Outstanding__c po = bpToPaymentMap.get(bp);
            
            //if(Decimal.valueOf(po.Total__c) == wo.Due_Amount__c){
                
                Date dt = Date.valueOf(po.Last_Payment_Date__c);
				String formattedDate = dt.format();
                
                wo.Amount_Received__c = Decimal.valueOf(po.Last_Payment_Amount_Paid__c.replace('-', ''));
                wo.Payment_Date__c = formattedDate;
                wo.Payment_Mode__c = 'Directly Paid by Customer';
                wo.Status = 'Completed'; 
                wo.Appointment_Status__c = 'Completed';
                //wo.Follow_up_Remarks__c = 'Claim Paid';
                //wo.Other_Follow_Up_Remark__c = 'Online';
                woToUpdate.add(wo);
            //}
        }
        
        if(!woToUpdate.isEmpty()){
            update woToUpdate;
        }
        
        // Step 6–9 apply only if WorkOrder was not previously completed
        Set<Id> updatedWoIds = new Map<Id, WorkOrder>(woToUpdate).keySet();
        if(updatedWoIds.isEmpty()) return;
        
        // Step 6 - ServiceAppointments
        List<ServiceAppointment> saToUpdate = [
            SELECT Id, Status, Appointment_Type__c, ParentRecordId
            FROM ServiceAppointment
            WHERE ParentRecordId IN :updatedWoIds
        ];
        for(ServiceAppointment sa : saToUpdate){
            sa.Status = 'Completed';
            sa.Appointment_Type__c = 'Completed';
        }
        
        System.debug('======saToUpdate=======>'+saToUpdate);
        
        if(!saToUpdate.isEmpty()) update saToUpdate;
        
        // Step 8 - WorkSteps
        List<WorkStep> wsToUpdate = [
            SELECT Id, Status, Name, ParentRecordId
            FROM WorkStep
            WHERE ParentRecordId IN :updatedWoIds
            AND Name IN ('Check In','Collect Payment','Check Out')
        ];
        for(WorkStep ws : wsToUpdate){
            ws.Status = 'Completed';
        }
        
        if(!wsToUpdate.isEmpty()) update wsToUpdate;
    }
}