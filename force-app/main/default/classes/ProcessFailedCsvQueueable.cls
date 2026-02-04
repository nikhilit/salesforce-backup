public class ProcessFailedCsvQueueable implements Queueable {
    
    private String csv;
    private Id recordId;
    
    // ✅ CLASS-LEVEL MAP
    private static final Map<String, String> FIELD_LABEL_MAP = new Map<String, String>{
        'CONNECTION_OBJ__c'            => 'CONNECTION OBJ',
        'Customer_BP_Number__c'        => 'PARTNER',
        'CA_Number__c'                 => 'CA',
        'Customer_Name__c'             => 'FIRST_NAME',
        'Building_Name__c'             => 'BLDG_NAME',
        'New_Flat__c'                  => 'FLAT_NO',
        'New_Floor__c'                 => 'FLOOR_NO',
        'New_Wing__c'                  => 'Wing',
        'New_Plot__c'                  => 'PLOT_NO',
        'New_Road_Name__c'             => 'ROAD_NAME',
        'New_Landmark__c'              => 'LAND MARK',
        'New_Colony__c'                => 'COLONY',
        'New_Location__c'              => 'LOCATION',
        'City__c'                      => 'CITY',
        'DISTRICT__c'                  => 'DISTRICT',
        'New_Mobile_Number__c'         => 'MOB_NO',
        'Email_ID__c'                  => 'EMAIL_ID',
        'Meter_No_SR__c'               => 'METER_NO',
        'Postal_Code__c'               => 'POSTAL CODE',
        'Due_Amount__c'                => 'TOTAL',
        'B4DUE__c'                     => 'B4DUE',
        'NOTDUE__c'                    => 'NOTDUE',
        'X0_30__c'                     => '0-30',
        'X31_60__c'                    => '31-60',
        'X61_90__c'                    => '61-90',
        'X91_180__c'                   => '91-180',
        'X181_365__c'                  => '181-365',
        'X1_2YR__c'                    => '1-2YR',
        'X2_3YR__c'                    => '2-3YR',
        'GR3YR__c'                     => 'GR3YR',
        'Agency_Name__c'               => 'Agency',
        'Agent_ID__c'                  => 'Agent',
        'WorkTypeId'                   => 'WorkType Name',
        'StartDate'                    => 'StartDate',
        'EndDate'                      => 'EndDate',
        'Batch_lot__c'                 => 'Batch lot',
        'Disconnection_Notice_No__c'   => 'Disconnection Notice No',
        'Disconnection_Notice_Date__c' => 'Disconnection Notice Date'
    };
    
    public ProcessFailedCsvQueueable(String csvBody, Id recId) {
        this.csv = csvBody;
        this.recordId = recId;
    }
    
    public void execute(QueueableContext qc) {
        
        Blob inputBlob = Blob.valueOf(csv);
        System.debug('CSV size MB: ' + (inputBlob.size() / (1024 * 1024)));
        
        Boolean inQuotes = false;
        Boolean headerProcessed = false;
        
        List<Integer> keepIndexes = new List<Integer>();
        List<String> newHeaders = new List<String>();
        
        String currentRow = '';
        String outputCsv = '';
        
        for (Integer i = 0; i < csv.length(); i++) {
            String c = csv.substring(i, i + 1);
            
            if (c == '"') {
                inQuotes = !inQuotes;
                currentRow += c;
            }
            else if ((c == '\n' || c == '\r') && !inQuotes) {
                
                if (!String.isBlank(currentRow)) {
                    outputCsv = processRow(
                        currentRow,
                    headerProcessed,
                    keepIndexes,
                    newHeaders,
                    outputCsv
                        );
                    headerProcessed = true;
                }
                
                currentRow = '';
                
                if (c == '\r' && i + 1 < csv.length() && csv.substring(i + 1, i + 2) == '\n') {
                    i++;
                }
            }
            else {
                currentRow += c;
            }
        }
        
        if (!String.isBlank(currentRow)) {
            outputCsv = processRow(
                currentRow,
            headerProcessed,
            keepIndexes,
            newHeaders,
            outputCsv
                );
        }
        
        Blob outputBlob = Blob.valueOf(outputCsv);
        
        ContentVersion cv = new ContentVersion(
            Title = 'Bulk_Failed_Results_' + Datetime.now().format('yyyyMMdd_HHmmss'),
        PathOnClient = 'failed_results.csv',
        VersionData = outputBlob,
        FirstPublishLocationId = recordId
            );
        insert cv;
    }
    
    // ================= ROW PROCESSOR =================
    private static String processRow(
        String row,
    Boolean headerProcessed,
    List<Integer> keepIndexes,
    List<String> newHeaders,
    String outputCsv
    ) {
        List<String> cols = parseCsvRow(row);
        
        if (!headerProcessed) {
            for (Integer i = 0; i < cols.size(); i++) {
                String h = cols[i].replace('"', '').trim();
                if (h == 'sf__Error') {
                    keepIndexes.add(i);
                    newHeaders.add('Error');
                }
                else if (FIELD_LABEL_MAP.containsKey(h)) {
                    keepIndexes.add(i);
                    newHeaders.add(FIELD_LABEL_MAP.get(h));
                }
            }
            return outputCsv + String.join(newHeaders, ',') + '\n';
        }
        
        List<String> filtered = new List<String>();
        for (Integer idx : keepIndexes) {
            filtered.add(idx < cols.size() ? cols[idx] : '');
        }
        
        return outputCsv + String.join(filtered, ',') + '\n';
    }
    
    // ================= CSV COLUMN PARSER =================
    private static List<String> parseCsvRow(String row) {
        List<String> cols = new List<String>();
        Boolean inQuotes = false;
        String current = '';
        
        for (Integer i = 0; i < row.length(); i++) {
            String c = row.substring(i, i + 1);
            if (c == '"') {
                inQuotes = !inQuotes;
            }
            else if (c == ',' && !inQuotes) {
                cols.add(current);
                current = '';
            }
            else {
                current += c;
            }
        }
        cols.add(current);
        return cols;
    }
}