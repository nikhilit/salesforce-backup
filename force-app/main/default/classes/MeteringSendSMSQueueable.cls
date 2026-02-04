/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 07-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   08-09-2025   Kartik Patkar, Appstrail   Initial Version
**/
public without sharing class MeteringSendSMSQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> workOrderIds;
    public MeteringSendSMSQueueable(Set<Id> ids) {
        this.workOrderIds = ids;
    }

    public void execute(QueueableContext context) {
        MeteringCommunicationHelper.sendMRSApprovalSMS_Future(workOrderIds);
    }

}