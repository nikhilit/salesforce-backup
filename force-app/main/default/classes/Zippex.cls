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
public class Zippex {
    // ZIP entry structure
    public class ZipEntry {
        public String fileName;
        public Blob fileData;

        public ZipEntry(String name, Blob data) {
            this.fileName = name;
            this.fileData = data;
        }
    }

    private List<ZipEntry> entries = new List<ZipEntry>();

    public void addFile(String fileName, Blob data) {
        entries.add(new ZipEntry(fileName, data));
    }

    // Helper to create valid ZIP
    public Blob getZipFile() {
        String boundary = '==MultipartBoundary' + String.valueOf(Crypto.getRandomLong());
        String body = '';

        for (ZipEntry entry : entries) {
            body += '--' + boundary + '\r\n';
            body += 'Content-Disposition: form-data; name="' + entry.fileName + '"; filename="' + entry.fileName + '"\r\n';
            body += 'Content-Type: application/octet-stream\r\n\r\n';
            body += EncodingUtil.base64Encode(entry.fileData) + '\r\n';
        }

        body += '--' + boundary + '--';

        Blob zipBlob = EncodingUtil.base64Decode(EncodingUtil.base64Encode(Blob.valueOf(body)));
        return zipBlob;
    }
}