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
public class ExcelImageHelper {

    // Stores: imageId → binary Blob
    public Map<Integer, Blob> imageMap = new Map<Integer, Blob>();

    // Stores relationship XML entries
    public List<String> relList = new List<String>();

    private Integer nextImageId = 1;

    /**
     * Add a Base64 PNG and return its assigned relationship ID.
     * Example: rId2
     */
    public Integer addImage(String base64String) {
        if (String.isBlank(base64String)) {
            return null;
        }

        try {
            Blob pngBlob = EncodingUtil.base64Decode(base64String);

            Integer imageId = nextImageId;
            nextImageId++;

            imageMap.put(imageId, pngBlob);

            // Relationship entry for drawing1.xml.rels
            String rel =
                '<Relationship Id="rId' + imageId + '" ' +
                'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" ' +
                'Target="../media/image' + imageId + '.png"/>';

            relList.add(rel);

            return imageId;

        } catch (Exception ex) {
            System.debug('Image decode error: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * Return drawing relationships XML for: /xl/drawings/_rels/drawing1.xml.rels
     */
    public String buildRelsXml() {
        String xml =
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">';

        for (String r : relList) {
            xml += r;
        }

        xml += '</Relationships>';

        return xml;
    }
}