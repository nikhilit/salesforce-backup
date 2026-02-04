/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 15-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   16-06-2025   Kartik Patkar, Appstrail   Initial Version
**/
public with sharing class MeterReadingOCRTriggerHandler {

    public static void beforeInsert(List<Meter_Reading_OCR__c> newList){
        updateFileName(newList, null);
    }

    public static void beforeUpdate(List<Meter_Reading_OCR__c> newList, Map<Id, Meter_Reading_OCR__c> oldMap){
        updateFileName(newList, oldMap);
    }
    
    public static void afterInsert(List<Meter_Reading_OCR__c> newList){
        checkMeterReadingOCR(newList, null);
        updateOCRResultToWorkOrder(newList, null);
    }

    public static void afterUpdate(List<Meter_Reading_OCR__c> newList, Map<Id, Meter_Reading_OCR__c> oldMap){
        checkMeterReadingOCR(newList, oldMap);
        updateOCRResultToWorkOrder(newList, oldMap);
    }

    public static void updateFileName(List<Meter_Reading_OCR__c> newList, Map<Id, Meter_Reading_OCR__c> oldMap){
        Set<Id> meterReadingToUpdate=new Set<Id>();
        Set<Id> workOrderIds=new Set<Id>();
        for(Meter_Reading_OCR__c meterReadRec:newList){
            if(meterReadRec.Status__c=='Pending' && (oldMap==null || 
                (meterReadRec.Status__c!=oldMap.get(meterReadRec.Id).Status__c))){
                workOrderIds.add(meterReadRec.Work_Order__c);
                meterReadingToUpdate.add(meterReadRec.Id);
            }
        }

        if(workOrderIds.isEmpty()){
            return;
        }

        Map<Id, WorkOrder> mapWorkOrderIdWorkOrder=new Map<Id, WorkOrder>([SELECT Id, WorkOrderNumber, BP_Number__c, Meter_Reading_Doc_Number__c, Bill_Date__c 
                                                                    FROM WorkOrder WHERE Id IN:workOrderIds]);

        if(!meterReadingToUpdate.isEmpty()){
            for(Meter_Reading_OCR__c meterReadRec:newList){
                if(meterReadingToUpdate.contains(meterReadRec.Id)){
                    WorkOrder workOrderRecord = mapWorkOrderIdWorkOrder.get(meterReadRec.Work_Order__c);
                    String fileName = DocumentHelper.generateDocumentKey(
                        workOrderRecord.Meter_Reading_Doc_Number__c,
                        workOrderRecord.BP_Number__c,
                        workOrderRecord.Bill_Date__c,
                        workOrderRecord.WorkOrderNumber
                    );
                    meterReadRec.File_Name__c = fileName;
                }
            }

            // for(Meter_Reading_OCR__c meterReadRec:meterReadingToUpdate){
            //     WorkOrder workOrderRecord = mapWorkOrderIdWorkOrder.get(meterReadRec.Work_Order__c);
            //     String fileName = DocumentHelper.generateDocumentKey(
            //         workOrderRecord.Meter_Reading_Doc_Number__c,
            //         workOrderRecord.BP_Number__c,
            //         workOrderRecord.Bill_Date__c,
            //         workOrderRecord.WorkOrderNumber
            //     );
            //     meterReadRec.File_Name__c = fileName;
            // }
        }
    }

    public static void checkMeterReadingOCR(List<Meter_Reading_OCR__c> newList, Map<Id, Meter_Reading_OCR__c> oldMap){
        Set<Id> meterIds = new Set<Id>();
        for(Meter_Reading_OCR__c meterReadRec:newList){
            if(meterReadRec.Status__c=='Pending' && (oldMap==null || 
                (oldMap!=null && meterReadRec.Status__c!=oldMap.get(meterReadRec.Id).Status__c))){
                meterIds.add(meterReadRec.Id);
            }
        }

        if(!meterIds.isEmpty()){
            MeterReadingOCRApiHelper.checkOCRDocumentProcess(meterIds);
        }
    }   

    public static void updateOCRResultToWorkOrder(List<Meter_Reading_OCR__c> newList, Map<Id, Meter_Reading_OCR__c> oldMap){
        Set<String> setOCRStatus=new Set<String>{'Draft','Pending'};
        Map<Id,Meter_Reading_OCR__c> mapWorkOrderIdMeterReadingOCR=new Map<Id,Meter_Reading_OCR__c>();
        for(Meter_Reading_OCR__c meterReadRec:newList){
            if(!setOCRStatus.contains(meterReadRec.Status__c) && meterReadRec.Work_Order__c!=null && (oldMap==null || 
                (oldMap!=null && meterReadRec.Status__c!=oldMap.get(meterReadRec.Id).Status__c))){
                mapWorkOrderIdMeterReadingOCR.put(meterReadRec.Work_Order__c,meterReadRec);
            }
        }

        if(!mapWorkOrderIdMeterReadingOCR.keySet().isEmpty()){
            List<WorkOrder> listWorkOrderUpdate=new List<WorkOrder>();
            for(Meter_Reading_OCR__c meterReadRec:mapWorkOrderIdMeterReadingOCR.values()){
                WorkOrder workOrderRec=new WorkOrder();
                workOrderRec.Id=meterReadRec.Work_Order__c;
                workOrderRec.OCR_Meter_Number__c=meterReadRec.Meter_Number__c;
                workOrderRec.OCR_Meter_Reading__c=meterReadRec.Meter_Reading__c;
                workOrderRec.OCR_Remark__c=meterReadRec.Status__c;
                listWorkOrderUpdate.add(workOrderRec);
            }

            if(!listWorkOrderUpdate.isEmpty()){
                update listWorkOrderUpdate;
            }
        }
    }
}