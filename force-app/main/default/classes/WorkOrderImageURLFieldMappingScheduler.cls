/**
 * @description       : Scheduler to run WorkOrderImageURLFieldMappingBatch every 5 minutes
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 27-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   27-01-2026   Kartik Patkar, Appstrail   Initial Version
 **/
public with sharing class WorkOrderImageURLFieldMappingScheduler implements Schedulable {
    
    private Integer batchSize;
    private String whereClause;
    
    public WorkOrderImageURLFieldMappingScheduler() {
        this.batchSize = 200; // Default batch size
        this.whereClause = 'WHERE Indirect_Reading_Received__c=true AND ImageUrl1__c =null';
    }
    
    public WorkOrderImageURLFieldMappingScheduler(Integer batchSize, String whereClause) {
        this.batchSize = batchSize;
        this.whereClause = whereClause;
    }
    
    public void execute(SchedulableContext sc) {
        // Execute the batch
        WorkOrderImageURLFieldMappingBatch batch = new WorkOrderImageURLFieldMappingBatch(this.whereClause);
        Database.executeBatch(batch, batchSize);
    }
    
    /**
     * @description Schedule the job to run every 5 minutes by creating 12 separate scheduled jobs
     * Note: Salesforce doesn't support comma-separated minutes in cron expressions,
     * so we create 12 jobs (one for each 5-minute interval within an hour)
     * Example usage in Anonymous Apex:
     * WorkOrderImageURLFieldMappingScheduler.scheduleEvery5Minutes();
     */
    public static void scheduleEvery5Minutes() {
        // Schedule 12 jobs - one for each 5-minute mark (0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55)
        List<Integer> minutes = new List<Integer>{0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55};
        
        for (Integer minute : minutes) {
            // Cron format: Seconds Minutes Hours Day_of_month Month Day_of_week
            String cronExp = '0 ' + minute + ' * * * ?';
            String jobName = 'WO Image URL Mapping - Every Hour at :' + String.valueOf(minute).leftPad(2, '0');
            
            System.schedule(jobName, cronExp, new WorkOrderImageURLFieldMappingScheduler());
            System.debug('Scheduled: ' + jobName);
        }
        
        System.debug('Total jobs scheduled: ' + minutes.size());
    }
    
    /**
     * @description Abort all scheduled jobs for this scheduler
     * Example usage in Anonymous Apex:
     * WorkOrderImageURLFieldMappingScheduler.abortAllScheduledJobs();
     */
    public static void abortAllScheduledJobs() {
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name LIKE 'WO Image URL Mapping%'
        ];
        
        for (CronTrigger job : jobs) {
            System.abortJob(job.Id);
            System.debug('Aborted: ' + job.CronJobDetail.Name);
        }
        
        System.debug('Total jobs aborted: ' + jobs.size());
    }
}