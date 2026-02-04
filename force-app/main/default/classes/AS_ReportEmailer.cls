public without sharing class AS_ReportEmailer {

	@InvocableMethod(label='Send Agency Reports')
    public static void sendAgencyReports(List<ReportEmailInput> inputs) {
        try {
            if (inputs == null || inputs.isEmpty()) return;

            // Assuming single input from Flow
            ReportEmailInput input = inputs[0];

            List<Id> reportIds     = input.agencyReportIds;
            List<String> toEmails  = input.agencyEmails;
            List<String> ccEmails  = input.adminEmails;

            // Validate sizes
            if (reportIds == null || toEmails == null || reportIds.size() != toEmails.size()) {
                System.debug('Mismatch in reportIds and toEmails size.');return;
            }

            // Loop through each agency
            for (Integer i = 0; i < reportIds.size(); i++) {
                Id reportId = reportIds[i];
                String toEmail = toEmails[i].trim();

                // Flatten CC emails for this agency
                String ccEmailStr = (i < ccEmails.size()) ? ccEmails[i] : null;
                List<String> ccList = (ccEmailStr != null) ? splitEmails(ccEmailStr) : new List<String>();

                String xlsData = '';

				if (Test.isRunningTest()) {
                    xlsData = 'Dummy XLS content';
                } else {
	                Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);xlsData = generateXlsFromReport(results);
                }

                // Insert ContentVersion
                ContentVersion cv = new ContentVersion(
                    Title = 'Daily Collections Report - ' + Date.today().format(),
                    PathOnClient = 'Daily Collections Report - ' + Date.today().format() + '.xls',
                    VersionData = Blob.valueOf(xlsData)
                );
                insert cv;

                // Send email
                sendEmail(new List<String>{ toEmail }, 'Daily Collections Report - ' + Date.today().format(),
                          'Dear Madam/Sir,\n\nPlease find enclosed herewith the Daily Collections report snapshot for the date: ' + Date.today().format() + '.\n\n(This is an auto-generated email through Collect360. Please do not reply to this ID.)',
                          cv.Id, ccList);
            }

        } catch (Exception e) {AS_ErrorLogger.log('AS_MultiAgencyReportEmailer', 'sendAgencyReports', e, '');}
    }

	// @InvocableMethod(label='Send Agency Reports')
    // public static void sendAgencyReports(List<ReportEmailInput> inputs) {
    //     try {
    //         if (inputs == null || inputs.isEmpty()) return;

    //         // Assuming single input from Flow with lists of equal size
    //         ReportEmailInput input = inputs[0];
    //         List<Id> reportIds     = input.agencyReportIds;
    //         List<String> toEmails  = input.agencyEmails;
    //         List<String> ccEmails  = input.adminEmails;

    //         if (reportIds == null || toEmails == null || reportIds.size() != toEmails.size()) {System.debug('Mismatch in reportIds and toEmails size.');return;}

    //         for (Integer i = 0; i < reportIds.size(); i++) {
    //             Id reportId = reportIds[i];
    //             String toEmail = toEmails[i].trim();

                
				
    //             String xlsData = '';
                    
    //             if (Test.isRunningTest()) {
    //                 xlsData = 'Dummy XLS content';
    //             } else {
    //                 // Run report
	//                 Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);xlsData = generateXlsFromReport(results);
    //             }
    //             // Convert to XLS
    //             //String xlsData = generateXlsFromReport(results);

    //             // Insert as ContentVersion
    //             ContentVersion cv = new ContentVersion(
    //                 Title = 'Daily Collections Report - ' + Date.today().format(),
    //                 PathOnClient = 'Daily Collections Report - ' + Date.today().format() + '.xls',
    //                 VersionData = Blob.valueOf(xlsData)
    //             );
    //             insert cv;

    //             // Build and send email
    //             Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    //             email.setToAddresses(new List<String>{ toEmail });
    //             if (ccEmails != null && !ccEmails.isEmpty()) email.setCcAddresses(ccEmails);
    //             email.setSubject('Daily Collections Report - ' + Date.today().format());
    //             email.setPlainTextBody(
	// 				'Dear Madam/Sir,\n\n'
	// 				+ 'Please find enclosed herewith the Daily Collections report snapshot for the date: ' + Date.today().format() + '.\n\n'
	// 				+ '(This is an auto-generated email through Collect360. Please do not reply to this ID.)');
    //             email.setEntityAttachments(new Id[]{ cv.Id });
    //             Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });
    //         }

    //     } catch (Exception e) {AS_ErrorLogger.log('AS_MultiAgencyReportEmailer', 'sendAgencyReports', e, '');}
    // }
 
    // Flow wrapper
    public class ReportEmailInput {
        @InvocableVariable(label='Agency Report IDs' required=true)
        public List<Id> agencyReportIds;

        @InvocableVariable(label='Agency Emails' required=true)
        public List<String> agencyEmails;

        @InvocableVariable(label='Admin Emails (CC)' required=true)
        public List<String> adminEmails;
    }

    // --- Helper to split email strings ---
	@TestVisible
    private static List<String> splitEmails(String emailStr) {
        List<String> emails = new List<String>();
        if (String.isBlank(emailStr)) return emails;
        for (String e : emailStr.replace(';', ',').split(',')) {
            String trimmed = e.trim();
            if (!String.isBlank(trimmed)) emails.add(trimmed);
        }
        return emails;
    }

	@TestVisible
    private static void sendEmail(List<String> toAddresses, String subject, String body, Id contentVersionId, List<String> ccAddresses) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddresses);
        if (ccAddresses != null && !ccAddresses.isEmpty()) email.setCcAddresses(ccAddresses);
        email.setSubject(subject);
        email.setPlainTextBody(body);
        email.setEntityAttachments(new Id[]{ contentVersionId });
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });
    }

	// @TestVisible
    // private static void sendEmail(List<String> toAddresses, String subject, String body, Id contentVersionId) {
	// 	Integer chunkSize = 150; // Salesforce limit per email
	// 	Integer totalSize = toAddresses.size();
		
	// 	for (Integer i = 0; i < totalSize; i += chunkSize) {
	// 		// Build chunk manually
	// 		List<String> chunk = new List<String>();
	// 		Integer endVar = Math.min(i + chunkSize, totalSize);
	// 		for (Integer j = i; j < endVar; j++) {
	// 			chunk.add(toAddresses[j]);
	// 		}

	// 		// Create and send the email
	// 		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	// 		mail.setToAddresses(chunk);
	// 		mail.setSubject(subject);
	// 		mail.setPlainTextBody(body);
	// 		mail.setEntityAttachments(new Id[]{ contentVersionId });
	// 		Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
	// 	}
	// }

	public static String generateXlsFromReport(Reports.ReportResults results) {
		if (results == null) return '';

		List<String> detailCols;        
		if (Test.isRunningTest()) {
			detailCols = new List<String>{'c1', 'c2'};
		} else {
			detailCols = results.getReportMetadata().getDetailColumns();            
		}

		Map<String, Object> columnInfo = new Map<String, Object>();
		if (results.getReportExtendedMetadata() != null &&
			results.getReportExtendedMetadata().getDetailColumnInfo() != null)
			columnInfo = results.getReportExtendedMetadata().getDetailColumnInfo();

		// ===== Collect WorkOrder and WorkType Ids =====
		Set<Id> workOrderIds = new Set<Id>();
		Set<Id> workTypeIds  = new Set<Id>();

		for (Reports.ReportFact fact : results.getFactMap().values()) {
			if (fact instanceof Reports.ReportFactWithDetails) {
				Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)fact;
				if (factDetails.getRows() != null) {
					for (Reports.ReportDetailRow row : factDetails.getRows()) {
						List<Reports.ReportDataCell> cells = row.getDataCells();
						if(detailCols.size() == cells.size()){
							for (Integer i = 0; i < cells.size(); i++) {
								Reports.ReportDataCell cell = cells[i];
								String colName = detailCols[i];

								if (cell.getValue() instanceof Id) {
									Id idVal = (Id)cell.getValue();
									if (colName == 'WorkOrder.Name') workOrderIds.add(idVal);
									else if (colName == 'WorkOrder.WorkType.Name') workTypeIds.add(idVal);
								}
							}
						}
					}
				}
			}
		}

		// ===== Query Names =====
		Map<Id, String> workOrderMap = new Map<Id, String>();
		Map<Id, String> workTypeMap  = new Map<Id, String>();

		if (!workOrderIds.isEmpty()) {
			for (WorkOrder wo : [SELECT Id, WorkOrderNumber, WorkType.Name FROM WorkOrder WHERE Id IN :workOrderIds]) {workOrderMap.put(wo.Id, wo.WorkOrderNumber);if (wo.WorkTypeId != null) workTypeMap.put(wo.WorkTypeId, wo.WorkType.Name);}
		}
		
		// ===== Build HTML =====
		String html = '<html><body><table border="1" cellspacing="0" cellpadding="4">';

		// Header row
		html += '<tr style="background-color:#f2f2f2;">';
		for (String col : detailCols) {
			String label = getFieldLabel(col, columnInfo);
			html += '<th>' + label.escapeHtml4() + '</th>';
		}
		html += '</tr>';

		// Data rows
		Reports.ReportFact factGeneric = results.getFactMap().get('T!T');
		if (factGeneric != null && factGeneric instanceof Reports.ReportFactWithDetails) {
			Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)factGeneric;
			if (factDetails.getRows() != null) {
				for (Reports.ReportDetailRow row : factDetails.getRows()) {
					html += '<tr>';
					List<Reports.ReportDataCell> cells = row.getDataCells();

					if(detailCols.size() == cells.size()){
						for (Integer i = 0; i < cells.size(); i++) {
							Reports.ReportDataCell cell = cells[i];
							Object val = cell.getValue();
							String colName = detailCols[i];
							String displayVal;

							if (val instanceof Reports.ReportCurrency) {
								displayVal = String.valueOf(((Reports.ReportCurrency)val).getAmount());
							} else if (val instanceof Id) {
								Id idVal = (Id)val;

								if (colName == 'WorkOrder.Name' && workOrderMap.containsKey(idVal)) {
									displayVal = workOrderMap.get(idVal);
								} else if (colName == 'WorkOrder.WorkType.Name' && workTypeMap.containsKey(idVal)) {
									displayVal = workTypeMap.get(idVal);
								} else {
									displayVal = String.valueOf(val);
								}
							} else {
								displayVal = val != null ? String.valueOf(val) : '';
							}

							html += '<td>' + displayVal.escapeHtml4() + '</td>';
						}
						html += '</tr>';
					}
				}
			}
		}

		html += '</table></body></html>';
		return html;
	}



	// Get field label (try metadata first, then fallback to describe)
	@TestVisible
	private static String getFieldLabel(String apiName, Map<String, Object> columnInfo) {
		// Step 1: Try from report metadata
		if (columnInfo != null && columnInfo.containsKey(apiName)) {
			Object infoObj = columnInfo.get(apiName);
			if (infoObj instanceof Map<String, Object>) {
				Map<String, Object> meta = (Map<String, Object>)infoObj;
				if (meta.containsKey('label')) {
					return String.valueOf(meta.get('label'));
				}
			}
		}

		// Step 2: Fallback — derive from API name (WorkOrder.Status → Status)
		try {
			if (apiName.contains('.')) {
				String[] parts = apiName.split('\\.');
				String objPrefix = parts[0];
				String fieldApi = parts[1].replace('__c', '');
				// Use describes dynamically
				Schema.SObjectType objType;
				if (Schema.getGlobalDescribe().containsKey(objPrefix))
					objType = Schema.getGlobalDescribe().get(objPrefix);
				else
					return fieldApi;
				
				Map<String, Schema.SObjectField> fields = objType.getDescribe().fields.getMap();
				if (fields.containsKey(parts[1])) {
					return fields.get(parts[1]).getDescribe().getLabel();
				}
				return fieldApi.capitalize();
			} else {
				return apiName;
			}
		} catch (Exception e) {AS_ErrorLogger.log('AS_MultiAgencyReportEmailer', 'getFieldLabel', e, '');return apiName;}
	}
}