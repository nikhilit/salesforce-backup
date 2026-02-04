/**
* @File Name : CSVBulkChunkIterable.cls
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

public class CSVBulkChunkIterable implements Iterable<String> {
    private Id contentVersionId;
    private Integer chunkSize;

    public CSVBulkChunkIterable(Id contentVersionId, Integer chunkSize) {
        this.contentVersionId = contentVersionId;
        this.chunkSize = chunkSize;
    }

    public Iterator<String> iterator() {
        return new CSVBulkChunkIterator(contentVersionId, chunkSize);
    }
}