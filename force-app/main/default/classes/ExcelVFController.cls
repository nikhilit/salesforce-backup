/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 16-10-2025
 * @last modified by  : Kartik Patkar Appstrail 
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   16-10-2025   Kartik Patkar, Appstrail   Initial Version
**/
public with sharing class ExcelVFController {
    public Blob excelBlob { get; set; }

    public ExcelVFController() {
        String cacheKey = ApexPages.currentPage().getParameters().get('cacheKey');
        String base64Excel = ExcelCacheController.getData(cacheKey);
        excelBlob = EncodingUtil.base64Decode(base64Excel);
    }
}