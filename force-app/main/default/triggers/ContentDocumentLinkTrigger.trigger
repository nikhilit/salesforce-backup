/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 15-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   15-01-2026   Kartik Patkar, Appstrail   Initial Version
**/
//trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
  // Map<Id, List<Id>> recordToDocs = new Map<Id, List<Id>>();

    //for (ContentDocumentLink cdl : Trigger.new) {
       // Id recordId = cdl.LinkedEntityId;
        //if (recordId != null) {
            //if (!recordToDocs.containsKey(recordId)) {
                //recordToDocs.put(recordId, new List<Id>());
            //}
            //recordToDocs.get(recordId).add(cdl.ContentDocumentId);
        //}
    //}

  //  ImageAssignmentService.assignImages(recordToDocs);
//}

trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {

  if (!TriggerController.isTriggerActive('ContentDocumentLinkTrigger')) {
      return;
  }
  //  ContentDocumentLinkHandler.handleAfterInsert(Trigger.new);
    if (Trigger.isAfter && Trigger.isInsert) {
      ContentDocumentLinkHelper.afterInsert(Trigger.new);
      ContentDocumentLinkHandler.handleAfterInsert(Trigger.new);
        ContentDocumentLinkHelper.sharewithpartnerusers(Trigger.new);
		//ContentDocumentLinkHandler.linkRelatedDocuments(Trigger.new);
		//ContentDocumentLinkHandler.handleOfflineImageLinking(Trigger.new);
    }
}