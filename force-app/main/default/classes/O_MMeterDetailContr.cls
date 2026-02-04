public class O_MMeterDetailContr {

    public String bpNumber { get; set; }

    public String rubberHoseExpiry { get; set; }

    public String workDone { get; set; }

    public String customerName { get; set; }

    public String mobileNumber { get; set; }

    public String meterNumber { get; set; }

    public String meterReading { get; set; }

    public String inspectionDate { get; set; }

    public String technicianName { get; set; }

    public String feedBack {get;set;}

    public List<ContentDocumentLink> docLinks { get; set; }

 
    public O_MMeterDetailContr() {

      String workOrderId = ApexPages.currentPage().getParameters().get('id');

        if (String.isNotBlank(workOrderId)) {
            try {
                WorkOrder wOrder = [
                    SELECT Id, BP_Number__c,New_Rubber_Hose__c,Account.FirstName__c, Account.LastName__c, Account.Customer_Contact_no__c,
                          Agent__r.Name,
                           The_Work_Done__c,Satisfactory__c,Not_Satisfactory__c ,Meter_Reading_RH__c,Meter_Number_RH__c
                    FROM WorkOrder
                    WHERE Id = :workOrderId
                    LIMIT 1
                ];
                
                // Rubber_Hose_Expiry_Date__c,Account.Meter_Number__c,Meter_Reading_SR__c,Old_Rubber_Hose_Expiry__c

               List<ContentDocumentLink> conDocLink = [SELECT Id, ContentDocumentId, LinkedEntityId, ContentDocument.LatestPublishedVersion.Title 
                                                            FROM ContentDocumentLink WHERE LinkedEntityId =: workOrderId and
                                                             (ContentDocument.LatestPublishedVersion.Title='New Rubber Hose Image' or ContentDocument.LatestPublishedVersion.Title = 'Meter Counter Photo')];


                inspectionDate =  DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0)).format('dd-MM-yyyy');

                bpNumber         = wOrder.BP_Number__c;
                 customerName     = wOrder.Account.FirstName__c + ' ' + wOrder.Account.LastName__c;
                mobileNumber     = wOrder.Account.Customer_Contact_no__c;
                technicianName   = wOrder.Agent__r.Name;

                rubberHoseExpiry = DateTime.newInstance(wOrder.New_Rubber_Hose__c, Time.newInstance(0, 0, 0, 0)).format('dd-MM-yyyy');
                workDone         = wOrder.The_Work_Done__c;
                meterNumber      = wOrder.Meter_Number_RH__c;
                meterReading     = wOrder.Meter_Reading_RH__c;
                docLinks = conDocLink;
                if(wOrder.Satisfactory__c){
                feedBack = 'Satisfactory';
                }
                else if(wOrder.Not_Satisfactory__c){
                    feedBack = 'Not Satisfactory';
                }
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error loading Work Order details.'));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Work Order ID provided.'));
        }
    }



 
}