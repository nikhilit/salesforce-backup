public with sharing class OfflineFileUploaderController {
    @AuraEnabled
    public static Id uploadFile(Id recordId, String fileName, String base64Data, String mimeType) {
        if (String.isBlank(recordId)) throw new AuraHandledException('Record Id is required.');
        if (String.isBlank(base64Data)) throw new AuraHandledException('File data is missing.');
        if (base64Data.length() > 37000000) throw new AuraHandledException('File exceeds 37 MB limit.');

        ContentVersion cv = new ContentVersion(
            Title = fileName,
            PathOnClient = fileName,
            VersionData = EncodingUtil.base64Decode(base64Data),
            FirstPublishLocationId = recordId
        );
        insert cv;
        return cv.Id;
    }
}