trigger AttachmentTrigger on Attachment (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        // Filter only email message attachments that aren't from the email service
        List<Attachment> eligibleAttachments = new List<Attachment>();
        for (Attachment att : Trigger.new) {
            if (att.ParentId != null && 
                String.valueOf(att.ParentId.getSObjectType()) == 'EmailMessage' &&
                !att.Name.startsWith('ATT') // Skip email service temp files
               ) {
                eligibleAttachments.add(att);
            }
        }
        
        if (!eligibleAttachments.isEmpty()) {
            EmailAttachmentHandler.convertEmailAttachments(eligibleAttachments);
        }
    }
}