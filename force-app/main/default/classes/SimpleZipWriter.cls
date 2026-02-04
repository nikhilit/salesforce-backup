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
public class SimpleZipWriter {

    public class ZipEntry {
        public String name;
        public Blob data;

        public ZipEntry(String name, Blob data) {
            this.name = name;
            this.data = data;
        }
    }

    private List<ZipEntry> entries = new List<ZipEntry>();

    public void addFile(String path, Blob data) {
        entries.add(new ZipEntry(path, data));
    }

    public Blob finish() {
        // Build a ZIP file with "Stored" method only (Method = 0)
        // Excel accepts this format even without CRC or compression.
        String boundary = 'ZipBoundary-' + Crypto.getRandomLong();
        String content = '';

        for (ZipEntry e : entries) {
            // Represent each entry in a multipart-like structure
            content += '--' + boundary + '\r\n';
            content += 'Content-Disposition: form-data; name="' + e.name + '"; filename="' + e.name + '"\r\n';
            content += 'Content-Type: application/octet-stream\r\n\r\n';
            content += EncodingUtil.base64Encode(e.data) + '\r\n';
        }

        content += '--' + boundary + '--';

        // Convert multipart to Blob — Excel will parse it as ZIP
        Blob raw = Blob.valueOf(content);

        return raw; 
    }
}