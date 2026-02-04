/**
* @File Name : SendPdfToCunstomerController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 26, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 26, 2025 |   | Initial Version
**/

public class SendPdfToCunstomerController {
	 @AuraEnabled(cacheable=true)
    public static List<Billing__c> getBillingsByAccount(Id accountId) {
		System.debug('accountId::'+accountId);
        return [
            SELECT Id,
                   Print_Doc_Number__c,
                   Billing_Doc_Number__c,
                   Invoice_Number__c,
                   Bill_Date__c,
                   Period_From__c,
                   Period_To__c,
                   Due_Amount__c,
                   Due_Date__c,
                   Document_Date__c,
                   Posting_Date__c
            FROM Billing__c
            WHERE Account__c = :accountId
             ORDER BY Print_Doc_Number__c DESC
        ];
    }
	@AuraEnabled
public static String savePdfFile(String billPrintNumber) {
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint(System.label.Get_BIll_PDF + EncodingUtil.urlEncode(billPrintNumber, 'UTF-8'));
    request.setMethod('GET');
    request.setTimeout(120000);

    HttpResponse response = http.send(request);
    System.debug('📌 PDF API Status: ' + response.getStatus() + ' body length=' + response.getBody().length());

    if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
        try {
            String base64Data = response.getBody();

            ContentVersion cv = new ContentVersion();
            cv.Title = 'Bill_' + billPrintNumber;
            cv.PathOnClient = 'Bill_' + billPrintNumber + '.pdf';
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            insert cv;

            ContentVersion insertedCV = [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :cv.Id
            ];

            // Reuse or create distribution
            List<ContentDistribution> existingDist = [
                SELECT Id, DistributionPublicUrl 
                FROM ContentDistribution 
                WHERE ContentVersionId = :insertedCV.Id
                LIMIT 1
            ];

            if (!existingDist.isEmpty()) {
                System.debug('📌 Returning existing public URL: ' + existingDist[0].DistributionPublicUrl);
                return existingDist[0].DistributionPublicUrl;
            }

            ContentDistribution dist = new ContentDistribution();
            dist.Name = 'Bill_' + billPrintNumber;
            dist.ContentVersionId = insertedCV.Id;
            dist.PreferencesAllowOriginalDownload = true;
            dist.PreferencesAllowPDFDownload = true;
            dist.PreferencesAllowViewInBrowser = true;
            insert dist;

            System.debug('📌 Returning new public URL: ' + dist.DistributionPublicUrl);
            return dist.DistributionPublicUrl;

        } catch (Exception e) {
            System.debug('❌ ERROR creating file: ' + e.getMessage());
            throw new AuraHandledException('Error creating PDF file: ' + e.getMessage());
        }
    } else {
        throw new AuraHandledException('Failed to fetch PDF: ' + response.getStatus() + ' ' + response.getBody());
    }
}
  @AuraEnabled
public static String savePdfFiles(List<String> billPrintNumbers,String phoneNumber,String accName,String preference,String workOrderId) {
    List<String> pdfUrls = new List<String>();
    String resultPdf='';
    for (String billPrintNumber : billPrintNumbers) {
        String fileTitle = 'Bill_' + billPrintNumber;

        // --- 1. Check if the file already exists ---
        ContentVersion cvToDistribute;
        List<ContentVersion> existingVersions = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Title = :fileTitle AND IsLatest = true
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (!existingVersions.isEmpty()) {
            cvToDistribute = existingVersions[0];
        } else {
            // --- 2. Fetch PDF from external service ---
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.label.Get_BIll_PDF + EncodingUtil.urlEncode(billPrintNumber, 'UTF-8'));
            request.setMethod('GET');
            request.setTimeout(120000);

            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                String base64Data = response.getBody();
                system.debug('base64Data::'+base64Data);
                ContentVersion newCv = new ContentVersion();
                newCv.Title = fileTitle;
                newCv.PathOnClient = fileTitle + '.pdf';
                newCv.VersionData = EncodingUtil.base64Decode(base64Data);
                insert newCv;

                cvToDistribute = [SELECT Id, ContentDocumentId 
                                  FROM ContentVersion 
                                  WHERE Id = :newCv.Id];
            } else {
                throw new AuraHandledException('Failed to fetch PDF for ' + billPrintNumber + ': ' + response.getStatus());
            }
        }

        // --- 3. Check for existing PUBLIC LINK ---
        List<ContentDistribution> existingDistributions = [
            SELECT DistributionPublicUrl, ExpiryDate 
            FROM ContentDistribution 
            WHERE ContentVersionId = :cvToDistribute.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        String pdfUrl;
        if (!existingDistributions.isEmpty() && 
            (existingDistributions[0].ExpiryDate == null || existingDistributions[0].ExpiryDate > System.now())) {
            pdfUrl = existingDistributions[0].DistributionPublicUrl;
        } else {
            // --- 4. Create a new public link ---
            ContentDistribution newDist = new ContentDistribution();
            newDist.Name = fileTitle;
            newDist.ContentVersionId = cvToDistribute.Id;
            newDist.PreferencesAllowOriginalDownload = true;
            newDist.PreferencesAllowPDFDownload = true;
            newDist.PreferencesAllowViewInBrowser = true;
            insert newDist;

            ContentDistribution result = [
                SELECT DistributionPublicUrl 
                FROM ContentDistribution 
                WHERE Id = :newDist.Id
            ];
            pdfUrl = result.DistributionPublicUrl;
        }
       

        // Add this file's URL to the list
        pdfUrls.add(pdfUrl);
         if(preference=='SMS'){
             resultPdf=sendSms(accName,phoneNumber,pdfUrls,workOrderId);
             system.debug('resultPdf::'+resultPdf);
        }
    }
   
    return resultPdf;
}
        Public static  String sendSms(String accName,String phoneNumber,List<String> pdfUrls,String workOrderId){
                Map<String, String> mergeFields = new Map<String, String>();
            String pdfLink=String.join(pdfUrls, ',');
            mergeFields.put('Name', accName);    
            String message = pdfLink;
    
             String result=SmsApiHelper.sendSMS(
                phoneNumber,
                message,
                '1007230413927918639',
                workOrderId
  
            );
            return result;
    // Return as a comma-separated string
        }
@AuraEnabled(cacheable=true)
    public static List<String> getPreferencePicklistValues() {
        List<String> values = new List<String>();

        // Describe the field
        Schema.DescribeFieldResult fieldResult = Account.preferance__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            values.add(entry.getValue());
        }
        return values;
    }
}