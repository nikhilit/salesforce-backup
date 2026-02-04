public class EmailMessageTriggerHandler {
    public static void processIncomingEmails(List<EmailMessage> newEmails) {
        try {
            //System.debug('==> Starting processIncomingEmails');

            // Initialize all collections
            Set<Id> caseIds = new Set<Id>();
            List<Case> newCases = new List<Case>();
            Map<Id, Case> casesToUpdateMap = new Map<Id, Case>();
            Map<Id, Case> emailToParentCaseMap = new Map<Id, Case>();
            Map<Id, Map<String, Integer>> caseEmailCountMap = new Map<Id, Map<String, Integer>>();

            // Get Name Transfer Queue
            // List<Group> nameTransferQueues = [
            //     SELECT Id FROM Group 
            //     WHERE Type = 'Queue' AND DeveloperName = 'Name_Transfer_queue' 
            //     LIMIT 1
            // ];
            // Id nameTransferQueueId = nameTransferQueues.isEmpty() ? null : nameTransferQueues[0].Id;

            List<Group> supportQueues = [
                SELECT Id 
                FROM Group 
                WHERE Type = 'Queue' AND DeveloperName = 'Support_Queue'
                LIMIT 1
            ];
            Id supportQueueId = supportQueues.isEmpty() ? null : supportQueues[0].Id;


            // Collect Case IDs from incoming emails
            for (EmailMessage email : newEmails) {
                if (email.Incoming && email.ParentId != null && String.valueOf(email.ParentId).startsWith('500')) {
                    caseIds.add(email.ParentId);
                }
            }

            if (caseIds.isEmpty()) return;
            
            Map<Id, Integer> overallEmailCountMap = new Map<Id, Integer>();

for (AggregateResult ar : [
    SELECT ParentId pId, COUNT(Id) cnt
    FROM EmailMessage
    WHERE ParentId IN :caseIds
    GROUP BY ParentId
]) {
    overallEmailCountMap.put((Id) ar.get('pId'), (Integer) ar.get('cnt'));
}


            // Query cases
            Map<Id, Case> caseMap = new Map<Id, Case>([
                SELECT Id, CaseNumber, SuppliedEmail, Account_Email__c, OwnerId, Owner.Profile.Name, 
                       Status, is_Email_Critical__c, FRL__c, Repeated_Email_Count__c,
                       Type__c, Priority, Categorised_By__c, IsClosed
                FROM Case WHERE Id IN :caseIds
            ]);

            // Load critical words
            List<Critical_words__mdt> criticalWords = [SELECT DeveloperName	 FROM Critical_words__mdt];

            // Initialize email count maps
            for (Id caseId : caseIds) {
                caseEmailCountMap.put(caseId, new Map<String, Integer>());
            }

            // Count existing emails
            for (EmailMessage email : [
                SELECT Id, ParentId, FromAddress
                FROM EmailMessage
                WHERE ParentId IN :caseIds AND Incoming = TRUE
            ]) {
                if (email.FromAddress != null) {
                    String fromAddr = email.FromAddress.toLowerCase().trim();
                    Map<String, Integer> senderCounts = caseEmailCountMap.get(email.ParentId);
                    Integer currentCount = senderCounts.containsKey(fromAddr) ? senderCounts.get(fromAddr) : 0;
                    senderCounts.put(fromAddr, currentCount + 1);
                }
            }

            // Count new emails
            for (EmailMessage email : newEmails) {
                if (email.Incoming && email.ParentId != null && String.valueOf(email.ParentId).startsWith('500') && email.FromAddress != null) {
                    String fromAddr = email.FromAddress.toLowerCase().trim();
                    if (!caseEmailCountMap.containsKey(email.ParentId)) {
                        caseEmailCountMap.put(email.ParentId, new Map<String, Integer>());
                    }
                    Map<String, Integer> senderCounts = caseEmailCountMap.get(email.ParentId);
                    Integer currentCount = senderCounts.containsKey(fromAddr) ? senderCounts.get(fromAddr) : 0;
                    senderCounts.put(fromAddr, currentCount + 1);
                }
            }

            // Update Repeated_Email_Count__c field
            for (Id caseId : caseEmailCountMap.keySet()) {
                Map<String, Integer> senders = caseEmailCountMap.get(caseId);
                Integer maxCount = 0;
                for (Integer v : senders.values()) {
                    if (v > maxCount) maxCount = v;
                }

                if (caseMap.containsKey(caseId) && (caseMap.get(caseId).Repeated_Email_Count__c == null || 
                    caseMap.get(caseId).Repeated_Email_Count__c != maxCount)) {
                    Case existing = casesToUpdateMap.get(caseId);
                    if (existing == null) {
                        existing = new Case(Id = caseId);
                    }
                    existing.Repeated_Email_Count__c = maxCount;
                    casesToUpdateMap.put(caseId, existing);
                }
            }

            // Get latest outgoing emails
            Map<Id, EmailMessage> latestOutgoingEmails = new Map<Id, EmailMessage>();
            for (EmailMessage email : [
                SELECT Id, ParentId, CreatedDate, ToAddress
                FROM EmailMessage
                WHERE ParentId IN :caseIds AND Incoming = FALSE
                ORDER BY CreatedDate DESC
            ]) {
                if (!latestOutgoingEmails.containsKey(email.ParentId)) {
                    latestOutgoingEmails.put(email.ParentId, email);
                }
            }
            BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name = 'Default' LIMIT 1];
             
            // Process each incoming email
            for (EmailMessage email : newEmails) {
                if (email.Incoming && email.ParentId != null && String.valueOf(email.ParentId).startsWith('500')) {
                   // System.debug('Received Email' + email.ParentId);

                    EmailMessage latestOutgoing = latestOutgoingEmails.get(email.ParentId);
                    Case parentCase = caseMap.get(email.ParentId);

                    Integer totalIncomingForCase = 0;
                    if (caseEmailCountMap.containsKey(email.ParentId)) {
                        for (Integer cnt : caseEmailCountMap.get(email.ParentId).values()) {
                            totalIncomingForCase += cnt;
                        }
                    }


                    // Check for critical words
                    Boolean isCritical = false;
                    for (Critical_words__mdt word : criticalWords) {
                        if ((email.Subject != null && email.Subject.toLowerCase().contains(word.DeveloperName.toLowerCase())) ||
                            (email.TextBody != null && email.TextBody.toLowerCase().contains(word.DeveloperName.toLowerCase()))) {
                            isCritical = true;
                            break;
                        }
                    }
                        
                    // Boolean withinBusinessHours = BusinessHoursHelper.checkWithinBusinessHours(
                    //     latestOutgoing.CreatedDate, System.now(), bh
                    // );
Integer overallcount = overallEmailCountMap.get(email.ParentId);

if (overallcount == 0 || overallcount==null) {
    continue;
}

                    if (parentCase != null && parentCase.IsClosed) {
                        // case is in a closed status
                    // }


                    // if (!withinBusinessHours && (parentCase.FRL__c == true || parentCase.Status == 'On Hold' || email.Subject.contains('Name Transfer Rejected'))) {
                        Case newCase = new Case();
                        newCase.Subject = email.Subject;
                        newCase.Description = email.TextBody;
                        newCase.Status = 'New';
                        newCase.OwnerId = supportQueueId;

                        // if (email.Subject.contains('Name Transfer Rejected')) {
                        //     newCase.Status = 'New';
                        //     if (nameTransferQueueId != null) {
                        //         newCase.OwnerId = nameTransferQueueId;
                        //     }
                        // } else {
                        //     newCase.Status = (parentCase.Owner.Profile.Name != null && 
                        //                     parentCase.Owner.Profile.Name.contains('CRM')) 
                        //                     ? 'Assigned' 
                        //                     : 'New';
                        //     newCase.OwnerId = parentCase.OwnerId;
                        // }

                        newCase.Origin = '4';
                        newCase.SuppliedEmail = email.FromAddress;
                        newCase.SuppliedName = email.FromName;

                        Integer senderEmailCount = 0;
                        if (email.FromAddress != null && parentCase.Id != null) {
                            String fromAddr = email.FromAddress.trim().toLowerCase();
                            if (caseEmailCountMap.containsKey(parentCase.Id) &&
                                caseEmailCountMap.get(parentCase.Id).containsKey(fromAddr)) {
                                senderEmailCount = caseEmailCountMap.get(parentCase.Id).get(fromAddr);
                            }
                        }
                        newCase.Repeated_Email_Count__c = senderEmailCount;
                        if(parentCase.Id != null){
                            newCase.ParentId = parentCase.Id;
                        } 

                        // ✅ Mark new case critical if needed
                        if (isCritical) {
                            newCase.is_Email_Critical__c = true;
                            newCase.Priority = 'High';
                        }

                        newCases.add(newCase);

                        // Resolve parent case
                        // Case existing = casesToUpdateMap.get(email.ParentId);
                        // if (existing == null) {
                        //     existing = new Case(Id = email.ParentId);
                        // }
                        // existing.Status = 'Resolved';
                        // casesToUpdateMap.put(email.ParentId, existing);
                        emailToParentCaseMap.put(email.Id, newCase);
                    } else {
                        // Within business hours
                        if (email.FromAddress != null &&
                            ((parentCase.SuppliedEmail != null && email.FromAddress.trim().toLowerCase() == parentCase.SuppliedEmail.trim().toLowerCase()) ||
                            (parentCase.Account_Email__c != null && email.FromAddress.trim().toLowerCase() == parentCase.Account_Email__c.trim().toLowerCase()))) {
                            
                            //System.debug('Updating the existing Case Status - Customer Responded');

                            Case existing = casesToUpdateMap.get(email.ParentId);
                            if (existing == null) {
                                existing = new Case(Id = email.ParentId);
                            }
                            existing.Status = 'Customer Responded';

                            // ✅ Mark existing case critical if needed
                            if (isCritical) {
                                existing.is_Email_Critical__c = true;
                                existing.Priority = 'High';
                            }
                            // if (parentCase.Categorised_By__c  != null){
                            //     existing.ownerId = parentCase.Categorised_By__c;
                            // }

                            casesToUpdateMap.put(email.ParentId, existing);
                             
                        }else{
                           // System.debug('Skipping Status Update - Customer Responded');
                        }
                    }
                    
                }
            }

            // Perform DML
            if (!newCases.isEmpty()) insert newCases;
            if (!casesToUpdateMap.isEmpty()) update casesToUpdateMap.values();
            

            // Update email parent references
            List<EmailMessage> updatedEmails = new List<EmailMessage>();
            for (EmailMessage email : newEmails) {
                if (emailToParentCaseMap.containsKey(email.Id)) {
                    email.ParentId = emailToParentCaseMap.get(email.Id).Id;
                    updatedEmails.add(email);
                }
            }
            if (!updatedEmails.isEmpty()) update updatedEmails;

        } catch (Exception ex) {
            //System.debug('Error: ' + ex.getMessage());
            // Handle error
        }
    }
// public static void processCRMFormsAcknowledgement(List<EmailMessage> newEmails) {
//     try {
//         System.debug('==> Starting CRM Forms Acknowledgment Logic');

//         // 1. Collect OUTBOUND emails (Sent emails only)
//         Set<Id> outboundEmailIds = new Set<Id>();
//         Set<Id> accountIds = new Set<Id>();
//         Map<Id, Id> emailToAccountMap = new Map<Id, Id>();
        
//         for (EmailMessage em : newEmails) {
//             if (!em.Incoming && em.Status == '3') { // Outbound and Sent
//                 outboundEmailIds.add(em.Id);
                
//                 // Check BOTH ParentId and RelatedToId for Account reference
//                 Id accountId = null;
                
//                 // First check ParentId
//                 if (em.ParentId != null && String.valueOf(em.ParentId).startsWith('001')) {
//                     accountId = em.ParentId;
//                 }
//                 // If ParentId is null or not Account, check RelatedToId
//                 else if (em.RelatedToId != null && String.valueOf(em.RelatedToId).startsWith('001')) {
//                     accountId = em.RelatedToId;
//                 }
                
//                 if (accountId != null) {
//                     accountIds.add(accountId);
//                     emailToAccountMap.put(em.Id, accountId);
//                 }
//             }
//         }
        
//         if (outboundEmailIds.isEmpty()) {
//             System.debug('No outbound emails found.');
//             return;
//         }

//         System.debug('Outbound Emails: ' + outboundEmailIds);
//         System.debug('Account IDs found: ' + accountIds);
//         System.debug('Email to Account Map: ' + emailToAccountMap);

//         // 2. Get ContentDocumentLinks for these emails
//         List<ContentDocumentLink> cdLinks = [
//             SELECT ContentDocumentId, LinkedEntityId
//             FROM ContentDocumentLink
//             WHERE LinkedEntityId IN :outboundEmailIds
//         ];
        
//         System.debug('Found ' + cdLinks.size() + ' ContentDocumentLinks for emails');
        
//         if (cdLinks.isEmpty()) {
//             System.debug('No ContentDocumentLinks found.');
//             return;
//         }

//         // 3. Build map of EmailMessageId -> Set<ContentDocumentId>
//         Map<Id, Set<Id>> emailToDocMap = new Map<Id, Set<Id>>();
        
//         for (ContentDocumentLink cdl : cdLinks) {
//             Id emailId = cdl.LinkedEntityId;
//             if (!emailToDocMap.containsKey(emailId)) {
//                 emailToDocMap.put(emailId, new Set<Id>());
//             }
//             emailToDocMap.get(emailId).add(cdl.ContentDocumentId);
//         }

//         System.debug('Email to Document Map: ' + emailToDocMap);

//         // 4. Get all document IDs
//         Set<Id> allDocIds = new Set<Id>();
//         for (Set<Id> docSet : emailToDocMap.values()) {
//             allDocIds.addAll(docSet);
//         }

//         System.debug('Total unique document IDs: ' + allDocIds.size());

//         // 5. Check which documents are in CRM Forms library
//         String CRM_LIBRARY_ID = '058fs0000000NuHAAU';
//         Map<Id, Boolean> isCRMFormDoc = new Map<Id, Boolean>();
        
//         if (!allDocIds.isEmpty()) {
//             List<ContentWorkspaceDoc> libraryDocs = [
//                 SELECT ContentDocumentId
//                 FROM ContentWorkspaceDoc
//                 WHERE ContentDocumentId IN :allDocIds
//                 AND ContentWorkspaceId = :CRM_LIBRARY_ID
//             ];
            
//             for (ContentWorkspaceDoc doc : libraryDocs) {
//                 isCRMFormDoc.put(doc.ContentDocumentId, true);
//             }
//         }
        
//         if (isCRMFormDoc.isEmpty()) {
//             System.debug('No CRM Form documents found in library.');
//             return;
//         }

//         System.debug('CRM Form documents found: ' + isCRMFormDoc.size());

//         // 6. Process each email
//         List<Messaging.SingleEmailMessage> ackEmails = new List<Messaging.SingleEmailMessage>();
        
//         for (EmailMessage email : newEmails) {
//             if (!outboundEmailIds.contains(email.Id)) continue;
            
//             // Skip if no documents mapped to this email
//             if (!emailToDocMap.containsKey(email.Id)) continue;
            
//             // Get Account ID from map (checks both ParentId and RelatedToId)
//             Id accountId = emailToAccountMap.get(email.Id);
//             if (accountId == null) {
//                 System.debug('Email ' + email.Id + ' not linked to any Account (checked ParentId and RelatedToId)');
//                 continue;
//             }
            
//             System.debug('Processing email: ' + email.Id);
//             System.debug('Account ID: ' + accountId);
//             System.debug('To Address: ' + email.ToAddress);

//             // Check if this email has CRM Form documents
//             Boolean hasCRMFormDoc = false;
//             for (Id docId : emailToDocMap.get(email.Id)) {
//                 if (isCRMFormDoc.containsKey(docId)) {
//                     hasCRMFormDoc = true;
//                     System.debug('Found CRM Form document: ' + docId);
//                     break;
//                 }
//             }
            
//             if (!hasCRMFormDoc) {
//                 System.debug('No CRM Form documents for this email');
//                 continue;
//             }
            
//             System.debug('✅ Email has CRM Form document(s)');

//             try {
//                 // Get Account
//                 Account acc = [
//                     SELECT Id, Name, Account_Email__c
//                     FROM Account
//                     WHERE Id = :accountId
//                     LIMIT 1
//                 ];
                
//                 System.debug('Account found: ' + acc.Name);
//                 System.debug('Account email: ' + acc.Account_Email__c);

//                 if (String.isBlank(acc.Account_Email__c) || String.isBlank(email.ToAddress)) {
//                     System.debug('Missing email addresses');
//                     continue;
//                 }
                
//                 String accountEmail = acc.Account_Email__c.toLowerCase().trim();
//                 String recipientEmail = email.ToAddress.toLowerCase().trim();
                
//                 System.debug('Comparing: Account[' + accountEmail + '] vs Recipient[' + recipientEmail + ']');
                
//                 if (recipientEmail != accountEmail) {
//                     System.debug('🚨 Different emails - sending acknowledgment');
                    
//                     Messaging.SingleEmailMessage ack = new Messaging.SingleEmailMessage();
//                     ack.setToAddresses(new List<String>{acc.Account_Email__c});
//                     ack.setSubject('CRM Form Document Sent to Different Email Address');
//                     ack.setPlainTextBody(
//                         'Hello ' + acc.Name + ',\n\n' +
//                         'A CRM Form document was sent to this email address:\n\n' +
//                         email.ToAddress + '\n\n' +
//                         'If this was not intended, please notify us.\n\n' +
//                         'Regards,\nCRM Team'
//                     );
//                     ackEmails.add(ack);
//                     System.debug('Acknowledgment queued for: ' + acc.Account_Email__c);
//                 } else {
//                     System.debug('✅ Same email - no action needed');
//                 }
                
//             } catch (Exception e) {
//                 System.debug('Error getting Account: ' + e.getMessage());
//                 continue;
//             }
//         }
        
//         // 7. Send acknowledgment emails
//         if (!ackEmails.isEmpty()) {
//             Messaging.sendEmail(ackEmails);
//             System.debug('✅ Sent ' + ackEmails.size() + ' acknowledgment emails');
//         } else {
//             System.debug('No acknowledgment emails to send');
//         }

//     } catch (Exception ex) {
//         System.debug('Error: ' + ex.getMessage() + '\n' + ex.getStackTraceString());
//     }
// }


    public static void validateAttendanceForOutgoingEmails(List<EmailMessage> newEmails) {
        try {
            // Run only if there is at least one outgoing email in this batch
            Boolean hasOutgoing = false;
            for (EmailMessage em : newEmails) {
                if (!em.Incoming) { // outgoing
                    hasOutgoing = true;
                    break;
                }
            }
            if (!hasOutgoing) return;

            Id currentUserId = UserInfo.getUserId();

            // Check Email Message Bypass custom setting (hierarchy)
            Email_Message_Bypass__c bypassSetting = Email_Message_Bypass__c.getInstance(currentUserId);

            if (bypassSetting != null && bypassSetting.Bypass__c) {
                //System.debug('EmailMessage validation bypass is ENABLED for user ' + currentUserId);
                // If bypass is on, skip all further validation
                return;
            }

            // Get current user's profile name
            String profileName = [
                SELECT Profile.Name
                FROM User
                WHERE Id = :currentUserId
            ].Profile.Name;

            // Only enforce for CRM profiles
            if (!profileName.contains('CRM')) {
                return;
            }

            // Get today's attendance for this user
            List<Attendance__c> att = [
                SELECT Id, Day_In_Timestamp__c, Day_Out_Timestamp__c
                FROM Attendance__c
                WHERE CreatedDate = TODAY
                AND CreatedById = :currentUserId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            // Check for open break on that attendance
            List<Break__c> openBreaks = new List<Break__c>();
            if (!att.isEmpty()) {
                openBreaks = [
                    SELECT Id
                    FROM Break__c
                    WHERE Attendance__c = :att[0].Id
                    AND Break_End_Time__c = null
                    LIMIT 1
                ];
            }

            // Apply validation to each outgoing email
            for (EmailMessage em : newEmails) {
                if (!em.Incoming) {

                    if (att.isEmpty() || att[0].Day_Out_Timestamp__c != null) {
                        em.addError('You must be checked-in to send emails.');
                    } else if (!openBreaks.isEmpty()) {
                        em.addError('You are currently on a break. Please end your break to send emails.');
                    }

                    // if (!String.isBlank(em.Headers)) {
                    //     System.debug('Outgoing email has headers -> enforcing attendance validation. Headers: ' + em.Headers);

                    //     if (att.isEmpty() || att[0].Day_Out_Timestamp__c != null) {
                    //         em.addError('You must be checked-in to send emails.');
                    //     } else if (!openBreaks.isEmpty()) {
                    //         em.addError('You are currently on a break. Please end your break to send emails.');
                    //     }
                    // } else {
                    //     System.debug('Outgoing email has NO headers -> skipping attendance validation.');
                    // }
                }
            }
        } catch (Exception ex) {
           // System.debug('Error in validateAttendanceForOutgoingEmails: ' + ex.getMessage());
        }
    }


}