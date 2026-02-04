public class WorkOrderInspectionCtrl {
   public WorkOrder workOrder { get; set; }
    public List<RiserWrapper> risers { get; set; }
    public Integer minCols { get; set; }

    public WorkOrderInspectionCtrl() {
        String workOrderId = '0WOfs0000007yFZGAY';//ApexPages.currentPage().getParameters().get('id');
        minCols = 7;
        risers = new List<RiserWrapper>();

        if (String.isNotBlank(workOrderId)) {
            List<WorkOrder> woList = [
                select id,WorkOrderNumber,owner.Name,DRS_No__c,Location__c,Agent__r.Name,DRS__c,Account.Building_name__c,Account.Connection_Object__c,
                                         SR_Comments__c ,SR_Material_Used__c,RM_Instrument_Type_Range__c,RM_Calibration_Certificate_No__c,
                                         RM_Calibration_Due_Date__c,RM_Calibration_Date__c,Completion_Datetime__c
                              from workorder where id=:workOrderId limit 1
            ];
            if (!woList.isEmpty()) workOrder = woList[0];

            List<WorkOrderLineItem> woliList = [
                SELECT Id, Riser_Name__c, Remark__c, No_of_active_customers__c,
                       StatusCategory,
                        Number_of_Leakages__c,
                        Duration__c,
                       Test_Pressure__c, LastModifiedDate
                FROM WorkOrderLineItem
                WHERE WorkOrderId = :workOrderId
                ORDER BY CreatedDate ASC
            ];

            for (WorkOrderLineItem woli : woliList) {
                risers.add(new RiserWrapper(woli));
            }
        }

        // Pad with blank wrappers if less than 7
        while (risers.size() < minCols) {
            risers.add(new RiserWrapper());
        }
    }
    public class RiserWrapper {
    public String riserNo {get;set;}
    public Date dateVal {get;set;}
    public String testPressure {get;set;}
    public String duration {get;set;}
    public String noOfLeakages {get;set;}
    public String result {get;set;}
    public Decimal noOfConnections {get;set;}
    public String remark {get;set;}

    public RiserWrapper() {
        // initialize with nulls (which show as blank in VF)
    }
    public RiserWrapper(WorkOrderLineItem woli) {
        this.riserNo = woli.Riser_Name__c;
        this.dateVal = (Date) woli.LastModifiedDate.date(); // adjust if you have a Date field
        this.testPressure = woli.Test_Pressure__c;
        this.duration = woli.Duration__c;
        this.noOfLeakages = woli.Number_of_Leakages__c;
        this.result = woli.StatusCategory;
        this.noOfConnections = woli.No_of_active_customers__c;
        this.remark = woli.Remark__c;
    }
}

}