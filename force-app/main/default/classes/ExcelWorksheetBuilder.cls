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
public class ExcelWorksheetBuilder {
    
    private List<String> rowXmlList = new List<String>();
    public List<String> drawingXmlList = new List<String>();
    private Integer currentRow = 1;
    
    // Add a row of text-only cells
    public void addRow(List<String> cellValues) {
        String rowXml = '<row r="' + currentRow + '">';
        Integer colIndex = 1;
        
        for (String cell : cellValues) {
            String ref = getCellRef(currentRow, colIndex);
            rowXml += '<c r="' + ref + '" t="inlineStr"><is><t>'
                + escape(cell)
                + '</t></is></c>';
            colIndex++;
        }
        
        rowXml += '</row>';
        rowXmlList.add(rowXml);
        currentRow++;
    }
    
    // Add a placeholder cell for image usage
    public void addEmptyRow(Integer colIndex) {
        String ref = getCellRef(currentRow, colIndex);
        String rowXml = '<row r="' + currentRow + '"><c r="' + ref + '"/></row>';
        rowXmlList.add(rowXml);
        currentRow++;
    }
    
    // Build sheet XML
    public String buildSheetXml() {
        return '<?xml version="1.0" encoding="UTF-8"?>'
            + '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
            +           'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
            + '<sheetData>'
            + String.join(rowXmlList, '')
            + '</sheetData>'
            + '</worksheet>';
    }
    
    // Build drawing XML for images
    public String buildDrawingXml() {
        String xml = '<?xml version="1.0" encoding="UTF-8"?>'
            + '<xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" '
            +            'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">';
        
        for (String d : drawingXmlList) {
            xml += d;
        }
        
        xml += '</xdr:wsDr>';
        return xml;
    }
    
    // Add anchor for image (auto-sized)
    public void addImageAnchor(Integer rowIndex, Integer colIndex, Integer imageId) {
        String xml =
            '<xdr:twoCellAnchor>'
            +     '<xdr:from>'
            +         '<xdr:col>' + colIndex + '</xdr:col>'
            +         '<xdr:colOff>0</xdr:colOff>'
            +         '<xdr:row>' + rowIndex + '</xdr:row>'
            +         '<xdr:rowOff>0</xdr:rowOff>'
            +     '</xdr:from>'
            +     '<xdr:to>'
            +         '<xdr:col>' + (colIndex + 1) + '</xdr:col>'
            +         '<xdr:colOff>0</xdr:colOff>'
            +         '<xdr:row>' + (rowIndex + 1) + '</xdr:row>'
            +         '<xdr:rowOff>0</xdr:rowOff>'
            +     '</xdr:to>'
            +     '<xdr:pic>'
            +         '<xdr:nvPicPr>'
            +             '<xdr:cNvPr id="' + imageId + '" name="Image' + imageId + '"/>'
            +             '<xdr:cNvPicPr/>'
            +         '</xdr:nvPicPr>'
            +         '<xdr:blipFill>'
            +             '<a:blip r:embed="rId' + imageId + '"/>'
            +             '<a:stretch><a:fillRect/></a:stretch>'
            +         '</xdr:blipFill>'
            +         '<xdr:spPr>'
            +             '<a:xfrm/>'
            +             '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>'
            +         '</xdr:spPr>'
            +     '</xdr:pic>'
            +     '<xdr:clientData/>'
            + '</xdr:twoCellAnchor>';
        
        drawingXmlList.add(xml);
    }
    
    // Escape XML characters
    private String escape(String input) {
        if (input == null) return '';
        input = input.replace('&', '&amp;');
        input = input.replace('<', '&lt;');
        input = input.replace('>', '&gt;');
        return input;
    }
    
    // Convert (row, col) to Excel cell reference like A1, B2, AA15
    private String getCellRef(Integer row, Integer col) {
        return getColumnName(col) + row;
    }
    
    // Convert 1 → A, 2 → B, … 26 → Z, 27 → AA, etc.
    private String getColumnName(Integer colNum) {
        String result = '';
        Integer num = colNum;
        
        while (num > 0) {
            Integer mod = Math.mod(num - 1, 26);
            
            Integer ascii = 65 + mod;  // A = 65
            String letter = String.fromCharArray(new List<Integer>{ ascii });
            
            result = letter + result;
            num = (num - mod - 1) / 26;
        }
        
        return result;
    }
}