/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 24-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   24-11-2025   Kartik Patkar, Appstrail   Initial Version
**/
public with sharing class ExcelExportService {

    @AuraEnabled(cacheable=false)
    public static String generateXlsx(List<Map<String, Object>> records, 
                                      Map<String, String> excelFields, 
                                      List<String> imageFields) 
    {
        try {
            // STEP 1 — Worksheet builder
            ExcelWorksheetBuilder sheet = new ExcelWorksheetBuilder();
            
            // STEP 2 — Image helper
            ExcelImageHelper imageHelper = new ExcelImageHelper();

            // STEP 3 — Header row (text)
            List<String> headerLabels = new List<String>();
            for (String apiName : excelFields.keySet()) {
                headerLabels.add(excelFields.get(apiName));
            }
            sheet.addRow(headerLabels);

            // STEP 4 — Build each row
            Integer rowIndex = 2;

            for (Map<String, Object> record : records) {
                
                List<String> textRow = new List<String>();
                Map<Integer, Integer> imageAnchors = new Map<Integer, Integer>();

                Integer colIndex = 1;

                for (String apiName : excelFields.keySet()) {
                    Object raw = record.get(apiName);
                    String val = raw == null ? '' : String.valueOf(raw);

                    if (imageFields.contains(apiName)) {
                        // Extract ContentVersion Id from your HTML <img> or URL format
                        String cvId = extractContentVersionId(val);
                        if (cvId != null) {
                            // This method must call your Apex method for base64 fetch
                            String base64 = fetchImageBase64(cvId);

                            if (base64 != null) {
                                Integer imgId = imageHelper.addImage(base64);
                                imageAnchors.put(colIndex, imgId);
                                textRow.add(''); // placeholder cell
                            }
                        } else {
                            textRow.add('');
                        }
                    } else {
                        textRow.add(val);
                    }

                    colIndex++;
                }

                // Add the row
                sheet.addRow(textRow);

                // Add image anchors
                for (Integer imgCol : imageAnchors.keySet()) {
                    Integer imgId = imageAnchors.get(imgCol);
                    sheet.addImageAnchor(rowIndex, imgCol - 1, imgId);  
                }

                rowIndex++;
            }

            // STEP 5 — Construct XLSX parts
            SimpleZipWriter zip = new SimpleZipWriter();

            // ---------------------
            // Required XLSX files
            // ---------------------
            zip.addFile('[Content_Types].xml',
                Blob.valueOf(ExcelWorkbookBuilder.getContentTypesXml()));

            zip.addFile('docProps/core.xml',
                Blob.valueOf(ExcelWorkbookBuilder.getCoreXml()));

            zip.addFile('docProps/app.xml',
                Blob.valueOf(ExcelWorkbookBuilder.getAppXml()));

            // Workbook + rels
            zip.addFile('xl/workbook.xml',
                Blob.valueOf(ExcelWorkbookBuilder.getWorkbookXml()));

            zip.addFile('xl/_rels/workbook.xml.rels',
                Blob.valueOf(ExcelWorkbookBuilder.getWorkbookRelsXml()));

            // Sheet XML
            zip.addFile('xl/worksheets/sheet1.xml',
                Blob.valueOf(sheet.buildSheetXml()));

            // Drawing XML
            zip.addFile('xl/drawings/drawing1.xml',
                Blob.valueOf(sheet.buildDrawingXml()));

            // Drawing relationships
            zip.addFile('xl/drawings/_rels/drawing1.xml.rels',
                Blob.valueOf(imageHelper.buildRelsXml()));

            // Images
            for (Integer imgId : imageHelper.imageMap.keySet()) {
                zip.addFile(
                    'xl/media/image' + imgId + '.png',
                    imageHelper.imageMap.get(imgId)
                );
            }

            // STEP 6 — Generate ZIP (XLSX)
            Blob xlsxBlob = zip.finish();

            // Convert to Base64 to send to LWC
            return EncodingUtil.base64Encode(xlsxBlob);

        } catch (Exception ex) {
            throw new AuraHandledException('Excel Export Error: ' + ex.getMessage());
        }
    }

    // ------------------------------
    // Helper: Extract ContentVersion Id
    // ------------------------------
    public static String extractContentVersionId(String input) {
        if (String.isBlank(input)) return null;

        // Example: match "ContentVersionId=068XXXXXXXXXXXX"
        Pattern p = Pattern.compile('([0-9A-Za-z]{15,18})');
        Matcher m = p.matcher(input);

        if (m.find()) {
            return m.group(1);
        }
        return null;
    }

    // ------------------------------
    // Helper: Fetch Base64 of image
    // Replace this with your existing Apex image fetch
    // ------------------------------
    public static String fetchImageBase64(String contentVersionId) {
        // Call your existing method
        List<String> results = MeteringWorkOrderListViewController.getContentVersionsBase64(new List<String>{ contentVersionId },1);
        return results.isEmpty() ? null : results[0];
    }
}