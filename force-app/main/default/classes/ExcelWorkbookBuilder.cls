/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 24-11-2025
 * @last modified by  : Kartik Patkar Appstrail 
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   24-11-2025   Kartik Patkar, Appstrail   Initial Version
**/
public class ExcelWorkbookBuilder {

    public static String getContentTypesXml() {
        return '<?xml version="1.0" encoding="UTF-8"?>'
        + '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        +    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        +    '<Default Extension="xml" ContentType="application/xml"/>'
        +    '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        +    '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        +    '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
        +    '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>'
        + '</Types>';
    }

    public static String getWorkbookXml() {
        return '<?xml version="1.0" encoding="UTF-8"?>'
        + '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
        +           ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        +    '<sheets>'
        +        '<sheet name="Sheet1" sheetId="1" r:id="rId1"/>'
        +    '</sheets>'
        + '</workbook>';
    }

    public static String getWorkbookRelsXml() {
        return '<?xml version="1.0" encoding="UTF-8"?>'
        + '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        +   '<Relationship Id="rId1" '
        +       'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
        +       'Target="worksheets/sheet1.xml"/>'
        + '</Relationships>';
    }

    public static String getCoreXml() {
        return '<?xml version="1.0" encoding="UTF-8"?>'
        + '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"'
        +                      ' xmlns:dc="http://purl.org/dc/elements/1.1/"'
        +                      ' xmlns:dcterms="http://purl.org/dc/terms/"'
        +                      ' xmlns:dcmitype="http://purl.org/dc/dcmitype/"'
        +                      ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
        +     '<dc:title>Export</dc:title>'
        +     '<dc:creator>Salesforce LWC Export</dc:creator>'
        +     '<cp:lastModifiedBy>Apex</cp:lastModifiedBy>'
        +     '<dcterms:created xsi:type="dcterms:W3CDTF">' + Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + '</dcterms:created>'
        + '</cp:coreProperties>';
    }

    public static String getAppXml() {
        return '<?xml version="1.0" encoding="UTF-8"?>'
        + '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"'
        +             ' xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">'
        +    '<Application>Salesforce Apex Export</Application>'
        +    '<DocSecurity>0</DocSecurity>'
        +    '<ScaleCrop>false</ScaleCrop>'
        +    '<HeadingPairs>'
        +         '<vt:vector size="2" baseType="variant">'
        +             '<vt:variant><vt:lpstr>Worksheets</vt:lpstr></vt:variant>'
        +             '<vt:variant><vt:i4>1</vt:i4></vt:variant>'
        +         '</vt:vector>'
        +    '</HeadingPairs>'
        +    '<TitlesOfParts>'
        +         '<vt:vector size="1" baseType="lpstr">'
        +             '<vt:lpstr>Sheet1</vt:lpstr>'
        +         '</vt:vector>'
        +    '</TitlesOfParts>'
        + '</Properties>';
    }
}