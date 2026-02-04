/**
* @File Name : CSVBulkChunkIterator.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 5, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 5, 2025 |   | Initial Version
**/
 
public class CSVBulkChunkIterator implements Iterator<String> {
    private List<String> chunks;
    private Integer currentIndex = 0;

    public CSVBulkChunkIterator(Id contentVersionId, Integer chunkSize) {
        chunks = new List<String>();
        ContentVersion cv = [SELECT VersionData FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
        String body = cv.VersionData.toString();
        List<String> lines = body.split('\\n');

        for (Integer i = 0; i < lines.size(); i += chunkSize) {
            Integer endIdx = Math.min(i + chunkSize, lines.size());

            List<String> part = new List<String>();
            for (Integer j = i; j < endIdx; j++) {
                part.add(lines[j]);
            }

            chunks.add(String.join(part, '\\n'));
        }
    }

    public Boolean hasNext() {
        return currentIndex < chunks.size();
    }

    public String next() {
        String chunk = chunks[currentIndex];
        currentIndex++;
        return chunk;
    }
}