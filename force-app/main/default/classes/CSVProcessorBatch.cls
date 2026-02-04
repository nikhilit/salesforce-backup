global class CSVProcessorBatch implements Database.Batchable<String>, Database.Stateful, Database.RaisesPlatformEvents {
    private Id stagingId;
    private List<String> csvLines;
    private Integer processedCount = 0;
    private Integer failedCount = 0;
    private List<Failed_Staging__c> failedRecords = new List<Failed_Staging__c>();
    private List<String> headers;

    // Constructor
    global CSVProcessorBatch(Id stagingId) {
        this.stagingId = stagingId;
    }

    // Start: Read and split CSV into lines
    global Iterable<String> start(Database.BatchableContext bc) {
        // Validate stagingId
        if (String.isBlank(stagingId)) {
            throw new IllegalArgumentException('Staging ID is null or empty');
        }

        // Query Staging__c record
        List<Staging__c> stagingRecords = [SELECT Id, File_Id__c FROM Staging__c WHERE Id = :stagingId LIMIT 1];
        if (stagingRecords.isEmpty()) {
            throw new QueryException('No Staging__c record found for ID: ' + stagingId);
        }
        Staging__c staging = stagingRecords[0];

        // Validate File_Id__c
        if (String.isBlank(staging.File_Id__c)) {
            throw new IllegalArgumentException('File_Id__c is null or empty on Staging__c record: ' + stagingId);
        }

        // Query ContentVersion and validate FileType
        List<ContentVersion> cvRecords = [SELECT VersionData, FileType, Title FROM ContentVersion WHERE ContentDocumentId = :staging.File_Id__c AND IsLatest = true LIMIT 1];
        if (cvRecords.isEmpty()) {
            throw new QueryException('No ContentVersion found for ContentDocumentId: ' + staging.File_Id__c);
        }
        ContentVersion cv = cvRecords[0];

        // Validate FileType
        if (cv.FileType != 'CSV') {
            throw new IllegalArgumentException('Invalid file type: ' + cv.FileType + '. Expected a plain text CSV file for: ' + cv.Title + '. Convert the Excel file to CSV UTF-8 format using Excel (Save As > CSV UTF-8) or a text editor and re-upload.');
        }

        // Process CSV with encoding handling
        Blob csvBlob = cv.VersionData;
        String csvContent;
        try {
            csvContent = csvBlob.toString(); // Attempt UTF-8
        } catch (Exception e) {
            System.debug('UTF-8 decoding failed: ' + e.getMessage());
            String hexOutput = EncodingUtil.convertToHex(csvBlob).substring(0, 100); // Log first 100 chars
            throw new IllegalArgumentException('Invalid CSV encoding. Expected UTF-8, but got error: ' + e.getMessage() + '. First 100 chars (hex): ' + hexOutput);
        }

        csvLines = csvContent.split('\n');
        if (!csvLines.isEmpty()) {
            headers = parseHeaders(csvLines[0]);
            csvLines.remove(0); // Remove header row
        } else {
            throw new IllegalArgumentException('CSV file is empty or contains no valid lines');
        }
        return csvLines;
    }

    // Execute: Process batch of lines (100 records per batch)
    global void execute(Database.BatchableContext bc, List<String> scope) {
        List<WorkOrder> workOrders = new List<WorkOrder>();
        List<ServiceAppointment> serviceAppts = new List<ServiceAppointment>();
        
        for (String line : scope) {
            if (String.isBlank(line)) continue;
            Map<String, String> rowData;
            try {
                rowData = parseCSVLine(line, headers);
                if (rowData.isEmpty()) continue; // Skip failed parse
            } catch (Exception e) {
                // Error already logged in parseCSVLine
                continue;
            }
            
            try {
                // Validate required fields
                if (String.isBlank(rowData.get('Subject')) || String.isBlank(rowData.get('Status'))) {
                    throw new IllegalArgumentException('Missing required WorkOrder fields: Subject or Status');
                }
                if (String.isBlank(rowData.get('SA_Status'))) {
                    throw new IllegalArgumentException('Missing required ServiceAppointment field: SA_Status');
                }

                // Create WorkOrder
                WorkOrder wo = new WorkOrder(
                    Subject = rowData.get('Subject'),
                    Status = rowData.get('Status')
                    // Add more fields as needed, e.g.:
                    // Priority = rowData.get('Priority'),
                    // AccountId = rowData.get('AccountId')
                );
                workOrders.add(wo);
                
                // Create linked ServiceAppointment
                ServiceAppointment sa = new ServiceAppointment(
                    Custom_Appointment_Number__c = rowData.get('AppointmentNumber'), // Use custom field
                    Status = rowData.get('SA_Status')
                    // Add more fields, e.g.:
                    // SchedStartTime = DateTime.valueOf(rowData.get('SchedStartTime')),
                    // SchedEndTime = DateTime.valueOf(rowData.get('SchedEndTime'))
                );
                serviceAppts.add(sa);
                
            } catch (Exception e) {
                // Log failure for retry
                Failed_Staging__c failed = new Failed_Staging__c(
                    Staging__c = stagingId,
                    Error_Message__c = e.getMessage(),
                    Failed_Data__c = line.substring(0, Math.min(line.length(), 255))
                );
                failedRecords.add(failed);
                failedCount++;
                continue;
            }
        }
        
        // Bulk insert with partial success
        if (!workOrders.isEmpty()) {
            List<Database.SaveResult> woResults = Database.insert(workOrders, false);
            for (Integer i = 0; i < woResults.size(); i++) {
                if (!woResults[i].isSuccess()) {
                    for (Database.Error err : woResults[i].getErrors()) {
                        System.debug('WorkOrder Error: ' + err.getMessage());
                        // Log to Failed_Staging__c for retry
                        Failed_Staging__c failed = new Failed_Staging__c(
                            Staging__c = stagingId,
                            Error_Message__c = err.getMessage(),
                            Failed_Data__c = scope[i].substring(0, Math.min(scope[i].length(), 255))
                        );
                        failedRecords.add(failed);
                        failedCount++;
                    }
                } else {
                    // Link ServiceAppointment to successful WorkOrder
                    serviceAppts[i].work_order__c = woResults[i].getId();
                }
            }
            
            // Insert ServiceAppointments
            if (!serviceAppts.isEmpty()) {
                List<Database.SaveResult> saResults = Database.insert(serviceAppts, false);
                for (Database.SaveResult saResult : saResults) {
                    if (!saResult.isSuccess()) {
                        for (Database.Error err : saResult.getErrors()) {
                            System.debug('ServiceAppointment Error: ' + err.getMessage());
                            failedCount++;
                        }
                    }
                }
            }
            processedCount += workOrders.size();
        }
    }

    // Finish: Update status, insert failed records, send email
    global void finish(Database.BatchableContext bc) {
        // Insert failed records for retry
        if (!failedRecords.isEmpty()) {
            insert failedRecords;
            // Optional: Chain retry batch
            // Database.executeBatch(new RetryBatch(stagingId), 100);
        }
        
        // Update Staging status
        Staging__c staging = new Staging__c(
            Id = stagingId,
            Status__c = (failedCount > 0 ? 'Completed with Errors' : 'Completed')
        );
        update staging;
        
        // Send summary email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject('CSV Upload Summary');
        mail.setToAddresses(new String[] {UserInfo.getUserEmail()});
        mail.setPlainTextBody('Processed: ' + processedCount + ' records\nFailed: ' + failedCount + ' records\nSee Failed_Staging__c for retry details.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }

    // Helper: Parse CSV line into map
    private Map<String, String> parseCSVLine(String line, List<String> headers) {
        Map<String, String> row = new Map<String, String>();
        List<String> values = new List<String>();
        
        try {
            // Replace newlines within fields to prevent splitting issues
            line = line.replace('\r\n', ' ').replace('\n', ' ').trim();
            values = parseCSVLineRobust(line);
            
            // Ensure correct number of fields
            if (values.size() != headers.size()) {
                System.debug('Warning: Line has ' + values.size() + ' fields, expected ' + headers.size() + ': ' + line.substring(0, Math.min(line.length(), 100)));
                throw new IllegalArgumentException('Incorrect number of fields in CSV line');
            }
            
            for (Integer j = 0; j < headers.size() && j < values.size(); j++) {
                row.put(headers[j], values[j].replace('"', '').trim());
            }
        } catch (Exception e) {
            // Log parsing error to Failed_Staging__c
            Failed_Staging__c failed = new Failed_Staging__c(
                Staging__c = stagingId,
                Error_Message__c = 'Parsing error: ' + e.getMessage(),
                Failed_Data__c = line.substring(0, Math.min(line.length(), 255))
            );
            failedRecords.add(failed);
            failedCount++;
            return row; // Return empty row to skip this line
        }
        return row;
    }

    // Helper: Robust CSV line parser
    private List<String> parseCSVLineRobust(String line) {
        List<String> fields = new List<String>();
        Boolean inQuotes = false;
        String field = '';
        
        for (Integer i = 0; i < line.length(); i++) {
            String ch = line.substring(i, i + 1);
            if (ch == '"') {
                inQuotes = !inQuotes;
                field += ch;
            } else if (ch == ',' && !inQuotes) {
                fields.add(field);
                field = '';
            } else {
                field += ch;
            }
            // Prevent excessive string growth
            if (field.length() > 10000) {
                throw new IllegalArgumentException('Field too long in CSV line');
            }
        }
        fields.add(field); // Add last field
        return fields;
    }

    // Helper: Parse headers
    private List<String> parseHeaders(String headerLine) {
        List<String> headers = new List<String>();
        Map<String, String> headerMap = parseCSVLine(headerLine, new List<String>());
        for (String h : headerMap.keySet()) {
            headers.add(h);
        }
        return headers;
    }
}