/**
 * @description       : 
 * @author            : Shashank.shekhar@appstrail.com
 * @group             : 
 * @last modified on  : 07-05-2025
 * @last modified by  : Shashank.shekhar@appstrail.com
**/
public without sharing class PaymentReceiptController {
    public Payment__c payment { get; set; }
    public String customerName { get; set; }
    public String agentName { get; set; }
    public String agencyName { get; set; }

    public PaymentReceiptController() {
        Id paymentId = ApexPages.currentPage().getParameters().get('id');

        if (paymentId != null) {
            payment = [
                SELECT Id, CA_Number__c, Bank_Name__c, Cheque_Number__c, Cheque_Date__c, Cheque_Amount__c,Payment_Mode__c,Total_Due_Amount__c,
                       Business_Partner__r.FirstName__c, Business_Partner__r.LastName__c, Business_Partner__r.DRS__c,CreatedDate,Receipt_Number__c,
                       Work_Order__r.Agent__r.Name, Work_Order__r.R_T_Agency__r.Name
                FROM Payment__c
                WHERE Id = :paymentId
                LIMIT 1
            ];

            customerName = payment.Business_Partner__r.FirstName__c + ' ' + payment.Business_Partner__r.LastName__c;
            agentName = payment.Work_Order__r.Agent__r.Name;
            agencyName = payment.Work_Order__r.R_T_Agency__r.Name;
        }
    }
}