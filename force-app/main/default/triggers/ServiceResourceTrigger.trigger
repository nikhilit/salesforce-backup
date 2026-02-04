/**
 * @description       : Handles ServiceResource automation for MGL R&T, including agent freeze/unfreeze and work order reassignment.
 * @author            : Shruthi Appstrail
 * @last modified on  : 25-06-2025
 * @last modified by  : OpenAI (Modified per Anupama's request)
 * Modifications Log
 * Ver   Date         Author                Modification
 * 1.0   23-05-2025   Shruthi, Appstrail    Initial Version
 * 2.0   25-06-2025   OpenAI                Added freeze/unfreeze, WO reassignment, and In Progress validation
**/
trigger ServiceResourceTrigger on ServiceResource (before update, after insert, after update) {
    // Fetch RecordTypeId for 'MGL R&T' only once
    Id mglRtRecordTypeId = Schema.SObjectType.ServiceResource.getRecordTypeInfosByName().get('MGL R&T').getRecordTypeId();

    // Prepare lists for handling logic
    List<ServiceResource> filteredNewList = new List<ServiceResource>();
    Map<Id, ServiceResource> filteredOldMap = new Map<Id, ServiceResource>();

    for (ServiceResource sr : Trigger.new) {
        if (sr.RecordTypeId == mglRtRecordTypeId) {
            filteredNewList.add(sr);
            if (Trigger.isUpdate && Trigger.oldMap.containsKey(sr.Id)) {
                filteredOldMap.put(sr.Id, Trigger.oldMap.get(sr.Id));
            }
        }
    }

    if (!filteredNewList.isEmpty()) {
         if (Trigger.isAfter && Trigger.isUpdate) {
       			 ServiceResourceHandler.handleFreezeActions(filteredNewList, filteredOldMap);
  		 }
        // (insert/update): create territory members
        if (Trigger.isAfter) {
            ServiceResourceHandler.createServiceTerritoryMembers(filteredNewList, filteredOldMap);
        }
    }
}