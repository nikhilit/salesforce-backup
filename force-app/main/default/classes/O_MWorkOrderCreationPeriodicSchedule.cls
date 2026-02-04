global class O_MWorkOrderCreationPeriodicSchedule implements Schedulable   {

      global void execute(SchedulableContext sc){
       
        O_MWorkOrderCreationPeriodicBatchClass omWorkOrderPeriodic = new O_MWorkOrderCreationPeriodicBatchClass();
       
        Database.executeBatch(omWorkOrderPeriodic);
    }
}