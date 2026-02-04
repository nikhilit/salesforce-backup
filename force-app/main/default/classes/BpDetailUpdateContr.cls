/**
* @File Name : BpDetailUpdateContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 21, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 21, 2025 |   | Initial Version
**/

public without sharing class BpDetailUpdateContr {

	@AuraEnabled
	public static Account getAccountDetails(String recordId){

		try {

		Account acc = [Select Id,FirstName__c,LastName__c,BP_Number__c,Connection_Done_Or_Not__c,Meter_Shifted__c
                                 from Account Where Id=: recordId];

		return acc;
		
		}
		catch(Exception e){

			system.debug('error::'+ e.getLineNumber() + e.getMessage());
			return new Account();
		}

	}

    @AuraEnabled
public static AccountWrapper getAccountAndMaterialDetails(String recordId){

             AccountWrapper wrapper = new AccountWrapper();


    try {





Account accountDetails = [Select id,Meter_Shifted__c,Copper_MLC_Length__c,Meter_Number__c,Meter_Reading__c,Regulator_Make__c,
										Connection_Done_Or_Not__c,LeakageTestDone__c,GI_Length__c	
										 from Account Where Id=: recordId];
       


     List<Material_Consumption__c> materials = [
                SELECT Id,
                       Work_Order_Line_Item__c,Item_Code_Riser_Activity__c,Item_Description_Riser_Activity__c,
                       Quantity__c,Material_Row_Number__c
                FROM Material_Consumption__c
                WHERE Business_Partner__c = :recordId
            ];


 
                 


            wrapper.accountDetail = accountDetails;
            wrapper.materialConsumptions = materials;

    }

    catch(Exception e){

        wrapper.accountDetail = new Account();
         wrapper.materialConsumptions = new List<Material_Consumption__c>();

    }

        return  wrapper;

}

 public class AccountWrapper {
        @AuraEnabled public Account accountDetail { get; set; }
        @AuraEnabled public List<Material_Consumption__c> materialConsumptions { get; set; }
      //  @AuraEnabled public List<WorkOrderLineItem_Child__c> flatAndPlugDetails { get; set; }

    }

	@AuraEnabled
	public static void updateAccountDetails(String recordId,String worOrderId, String meterShifted,
												String meterNumber, String meterReading, String regulatorMake,
											String connectionDone, String leakageTestDone, String gILength,
											String copperlengthMLClength,List<FileWrapper> listFiles ){


		try {

			system.debug('update account detail method inside::'+ recordId);



			Account accUpdate = [Select id,Meter_Shifted__c,Copper_MLC_Length__c,Meter_Number__c,Meter_Reading__c,Regulator_Make__c,
										Connection_Done_Or_Not__c,LeakageTestDone__c,GI_Length__c,Copper_Length_MLC_Length__c,Attended_Date__c	
										 from Account Where Id=: recordId];


            WorkOrder woUpdate =[Select id,Meter_Shifted__c,Connection_Done__c from workorder where id=:worOrderId];


        Decimal meterShiftedCount = (woUpdate.Meter_Shifted__c == null) ? 0 : woUpdate.Meter_Shifted__c;
        Decimal connectionDoneCount = (woUpdate.Connection_Done__c == null) ? 0 : woUpdate.Connection_Done__c;

        system.debug('metershiftedcount ::'+ meterShiftedCount);
        system.debug('connectionDoneCount ::'+ connectionDoneCount);

            if(accUpdate.Meter_Shifted__c !='Yes' && meterShifted=='Yes'){

                system.debug('inside meter shifted not equal yes before but now yes');

                 meterShiftedCount += 1;

                woUpdate.Meter_Shifted__c =meterShiftedCount;
            }

              if(accUpdate.Meter_Shifted__c =='Yes' && meterShifted=='No'){

                system.debug('inside meter shifted equal yes before but now no');


                 meterShiftedCount -= 1;

                   if (meterShiftedCount < 0) {
                      meterShiftedCount = 0;
                 }

                woUpdate.Meter_Shifted__c =meterShiftedCount;
            }


              if(accUpdate.Connection_Done_Or_Not__c !='Yes' && connectionDone=='Yes'){

                system.debug('inside connection Done not equal yes before but now yes');

                 connectionDoneCount += 1;

                woUpdate.Connection_Done__c =connectionDoneCount;
            }

              if(accUpdate.Connection_Done_Or_Not__c =='Yes' && connectionDone=='No'){

                system.debug('inside connection Done equal yes before but now no');


                 connectionDoneCount -= 1;

                   if (connectionDoneCount < 0) {
                      connectionDoneCount = 0;
                 }

                woUpdate.Connection_Done__c =connectionDoneCount;
            }

            update woUpdate;

		accUpdate.Meter_Shifted__c = meterShifted;
		accUpdate.Copper_MLC_Length__c = copperlengthMLClength;
		accUpdate.Meter_Number__c = meterNumber;
		accUpdate.Attended_Date__c = System.TODAY();

		
		accUpdate.Meter_Reading__c = meterReading;
		accUpdate.Regulator_Make__c = regulatorMake;
		accUpdate.Connection_Done_Or_Not__c = connectionDone;

		accUpdate.LeakageTestDone__c = leakageTestDone;
		accUpdate.GI_Length__c = gILength;
	//(Already capturing)	accUpdate.Copper_Length_MLC_Length__c = copperlengthMLClength;

		update accUpdate;





			List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            for (FileWrapper fw : listFiles) {
                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName +'.jpg';
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                cv.Description ='BP Capture Image';
                contentVersions.add(cv);
            }
            
            insert contentVersions;
            
            // Map ContentVersion Id to ContentDocumentId
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :contentVersions
        ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
            }
            
            // Create ContentDocumentLinks to associate files with the given record
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
               // LinkedEntityId = recordId,
                  LinkedEntityId = worOrderId,

                ShareType = 'V', // View permission
                Visibility = 'AllUsers'
                    ));
            }
            
            insert links;

		}
		catch(Exception e){

			system.debug('error updating account details::'+ e.getLineNumber() + e.getMessage());
		}

	}

	 public class FileWrapper{
        @AuraEnabled public String base64Data{get;set;}
        @AuraEnabled public String fileName{get;set;}
        @AuraEnabled public String label{get;set;}
    }

    @AuraEnabled
    public static void materialConsumption(String recordId,  List<MaterialWrapper> materialList){


        try {

            system.debug('inside material consumption');

          List<Material_Consumption__c> lstMaterConsumption = new List<Material_Consumption__c>();

          List<Material_Consumption__c> lstMaterialConsumption = [Select id,Material_Row_Number__c from Material_Consumption__c Where Business_Partner__c =: recordId ];

        Set<string> uniqueRowNumber = new Set<String>();

        for(Material_Consumption__c matCons : lstMaterialConsumption){

            uniqueRowNumber.add(matCons.Material_Row_Number__c);
        }

        for (MaterialWrapper wrapper : materialList) {
            System.debug('Processing MaterialWrapper: ' + JSON.serializePretty(wrapper));

          if (!uniqueRowNumber.contains(String.valueOf(wrapper.rowNumber))) {
            
            Material_Consumption__c record = new Material_Consumption__c(
                Business_Partner__c	 = recordId,
                Item_Code_Riser_Activity__c = wrapper.itemCode,
                Item_Description_Riser_Activity__c = wrapper.itemDescription,
                Quantity__c	 = wrapper.quantity,
                 Material_Row_Number__c	= string.valueOf(wrapper.rowNumber)

            );
            lstMaterConsumption.add(record);
          }else {

            System.debug('Skipping rowNumber ' + wrapper.rowNumber + ' as it already exists.');

          }


         


        }

        if (!lstMaterConsumption.isEmpty()) {
            insert lstMaterConsumption;
            System.debug('Inserted Material Consumption records: ' + lstMaterConsumption);
        }

         List<Material_Consumption__c> existingRecords = [SELECT Id, Material_Row_Number__c 
                                                            FROM Material_Consumption__c 
                                                            WHERE Business_Partner__c = :recordId
                                                            ];

                Set<String> currentRowNumbers = new Set<String>();
                for (MaterialWrapper wrapperMaDe : materialList) {
                    currentRowNumbers.add(String.valueOf(wrapperMaDe.rowNumber));
                }

                Set<String> existingRowNumbers = new Set<String>();
                for (Material_Consumption__c mc : existingRecords) {
                    existingRowNumbers.add(mc.Material_Row_Number__c);
                }

                List<Material_Consumption__c> recordsToDelete = new List<Material_Consumption__c>();
                for (Material_Consumption__c mc : existingRecords) {
                    if (!currentRowNumbers.contains(mc.Material_Row_Number__c)) {
                        recordsToDelete.add(mc);
                    }
                }

                if (!recordsToDelete.isEmpty()) {
                    delete recordsToDelete;
                }

                 if (materialList == null || materialList.isEmpty()) {
        // List<Material__c> existingMaterials = [
        //     SELECT Id FROM Material__c WHERE WorkOrderLineItem__c = :recordId
        // ];
        if (!lstMaterialConsumption.isEmpty()) {
            delete lstMaterialConsumption;
        }
        
    }

        }

           catch(Exception e){

            system.debug('Error ::'+ e.getMessage() + ' ' + e.getLineNumber());
        }


    }

    public class MaterialWrapper {
               
        @AuraEnabled public Integer rowNumber{get;set;}

         @AuraEnabled public String itemCode{get;set;}
        @AuraEnabled public String itemDescription{get;set;}
        @AuraEnabled public Integer quantity{get;set;} 
    }

	  @AuraEnabled
    public static void generateAndAttachPdf(String worOrderId, String accId) {

        try{

      //  WorkOrder worOrder = [Select id,BP_Number__c from WorkOrder where id=: worOrderId];

        system.debug('WorkOrder id'+ worOrderId);

        system.debug('Account id'+ accId);

		Account acc = [Select id,BP_Number__c from Account where id=: accId];




        PageReference pdfPage = Page.riserReplacementCopperReportPage; //riserReplacementCopperReportPage means bp report genrated vf page

        system.debug('Pdfpage :'+ pdfPage);
        pdfPage.getParameters().put('workOrderId', worOrderId);
		pdfPage.getParameters().put('accountId', accId);

        Blob pdfBlob = pdfPage.getContentAsPDF();
        system.debug('pdfblob ::'+ pdfBlob);

        ContentVersion cv = new ContentVersion(
           // Title = 'Service Report' + ' ' + worOrder.BP_Number__c + '.pdf',
            Title = 'Copper Report' + ' ' + acc.BP_Number__c + '.pdf',

            PathOnClient = 'BP' + accId + '.pdf',
            VersionData = pdfBlob
        );
        insert cv;

        system.debug('Content version::'+ cv);

        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
           // LinkedEntityId = accId,
             LinkedEntityId = worOrderId,

            ShareType = 'V'
        );
        insert cdl;

        system.debug('cdl::'+ cdl);



        



       // return cd.Id;

        }
        catch(Exception e){

            system.debug('Error ::'+ e.getLineNumber() + e.getMessage());
           // return   null;
        }
    }
}