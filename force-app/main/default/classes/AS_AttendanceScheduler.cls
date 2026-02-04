/**
* @File Name : AS_AttendanceScheduler.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 15, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 15, 2025 |   | Initial Version
**/
global class AS_AttendanceScheduler implements Schedulable {

    private String cronExp;

    public AS_AttendanceScheduler(String cronExpression) {
        this.cronExp = cronExpression;
    }

    public AS_AttendanceScheduler() {
        // Default: 11:45 PM IST (23:45 IST = 18:15 GMT)
        this.cronExp = '0 15 18 * * ?';
    }

    global void execute(SchedulableContext sc) {
        AS_AttendanceProcessor.processAttendance();
    }

    public static void scheduleJob(String jobName, String cronExpression) {
        if (String.isBlank(cronExpression)) {
            // Fallback to default (11:45 PM IST)
            cronExpression = '0 15 18 * * ?';
        }
        System.schedule(jobName, cronExpression, new AS_AttendanceScheduler(cronExpression));
    }
}