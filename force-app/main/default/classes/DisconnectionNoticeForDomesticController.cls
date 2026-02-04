public class DisconnectionNoticeForDomesticController {
    
    public String caNumber { get; set; }
    public String bpNumber { get; set; }
    public String customerName { get; set; }
    public String flat { get; set; }
    public String floor { get; set; }
    public String building { get; set; }
    public String street { get; set; }
    public String city { get; set; }
    public String postalCode { get; set; }
    public Decimal pendingAmount { get; set; }
    public String todayDate { get; set; }
    public String referenceNumber { get; set; }

    public DisconnectionNoticeForDomesticController() {
        String woId = ApexPages.currentPage().getParameters().get('id');
        todayDate = Date.today().format();
        referenceNumber = String.valueOf(Math.mod(Crypto.getRandomInteger(), 1000000));

        if (String.isNotBlank(woId)) {
            WorkOrder wo = [
                SELECT Id, Due_Amount__c, EndDate, AccountId,
                    Account.CA_Number__c,
                    Account.BP_Number__c,
                    Account.FirstName__c,
                    Account.LastName__c,
                    Account.Flat__c,
                    Account.Floor__c,
                    Account.Building_name__c,
                    Account.Street__c,
                    Account.City__c,
                    Account.Postal_Code__c
                FROM WorkOrder
                WHERE Id = :woId
                LIMIT 1
            ];

            caNumber = wo.Account.CA_Number__c;
            bpNumber = wo.Account.BP_Number__c;
            customerName = wo.Account.FirstName__c + ' ' + wo.Account.LastName__c;
            flat = wo.Account.Flat__c;
            floor = wo.Account.Floor__c;
            building = wo.Account.Building_name__c;
            street = wo.Account.Street__c;
            city = wo.Account.City__c;
            postalCode = wo.Account.Postal_Code__c;
            pendingAmount = wo.Due_Amount__c;
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Work Order ID not provided.'));
        }
    }


}