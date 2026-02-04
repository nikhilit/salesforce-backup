/**
* @File Name : RTQRCodeService.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : June 26, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 26, 2025 |   | Initial Version
**/

public with sharing class RTQRCodeService {
@AuraEnabled
public static String generateQRCode() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('https://demo.ezetap.com/api/2.0/merchant/qrcode/generate');
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');

    String body = JSON.serialize(new Map<String, Object>{
        'username' => '8901009001',
        'appKey' => 'be80f1f7-5e92-4a93-acb1-65b53ebcb3b1',
        'amount' => 1040,
        'externalRefNumber' => 'merchant order number',
        'qrCodeType' => 'UPI',
        'qrCodeFormat' => 'STRING',
        'deviceSerial' => 'device123'
    });

    req.setBody(body);
    Http http = new Http();
    try {
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) result.get('qrCodeUri'); // ✅ this line must return only the string
        } else {
            throw new AuraHandledException('Callout failed. Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
        }
    } catch (Exception e) {
        throw new AuraHandledException('Exception: ' + e.getMessage());
    }
}

}