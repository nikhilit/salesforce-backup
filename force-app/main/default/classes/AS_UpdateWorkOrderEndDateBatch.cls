public with sharing class AS_UpdateWorkOrderEndDateBatch implements Database.Batchable<SObject>, Database.Stateful {
    private String batchLot;
    private Date endDate;

    public AS_UpdateWorkOrderEndDateBatch(String batchLot, Date endDate) {
        this.batchLot = batchLot;
        this.endDate = endDate;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, EndDate FROM WorkOrder WHERE RecordType.DeveloperName = \'MGL_R_T\' AND Batch_lot__c = :batchLot';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> scope) {
        for (WorkOrder wo : scope) {
            wo.EndDate = endDate;
        }
        Map<Id, WorkOrder> mapWorkOrder = new Map<Id, WorkOrder>(scope);
        List<ServiceAppointment> lstSA = new List<ServiceAppointment>();
        for(ServiceAppointment sa : [SELECT Id, SchedEndTime, ParentRecordId FROM ServiceAppointment WHERE ParentRecordId IN :scope]){
            sa.SchedEndTime = DateTime.newInstance(
                endDate, 
                Time.newInstance(20, 0, 0, 0) // 8:00 PM
            );
            lstSA.add(sa);
        }
        update scope;
        update lstSA;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch completed for Batch Lot: ' + batchLot);
    }
}