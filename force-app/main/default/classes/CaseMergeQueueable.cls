/**
* @File Name : CaseMergeQueueable.cls
* @Description : Merging Duplicate Cases
* @Author : Shruthi S D
* @Last Modified By :
* @Last Modified On : April 7, 2025
* @Modification Log :
*==============================================================================
* Ver | Date        | Author      | Modification
*==============================================================================
* 1.0 | April 7, 2025 | Shruthi S D | Initial Version
**/
public class CaseMergeQueueable implements Queueable {
    Set<Id> casestodelete = new Set<Id>();
    public CaseMergeQueueable(Set<Id> casestodelete) {
        this.casestodelete = casestodelete;
    }
    public void execute(QueueableContext context) {
    	List<case> casestodelete =[SELECT Id FROM Case WHERE Id IN:casestodelete];
        delete casestodelete;
    }
}