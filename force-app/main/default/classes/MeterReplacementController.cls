public without sharing class MeterReplacementController {

    ////////////////////////////////////////////////////////////////////////////////
    // ORIGINAL (commented) - simpler getWorkOrderDetails kept for reference
    ////////////////////////////////////////////////////////////////////////////////
    /*
    // @AuraEnabled(cacheable=true)
    // public static WorkOrderWrapper getWorkOrderDetails(String workOrderId) {
    //     System.debug('>> OLD getWorkOrderDetails START. workOrderId=' + workOrderId);
    //     try {
    //         System.debug('OLD: About to query WorkOrder for id: ' + workOrderId);
    //         WorkOrder wo = [
    //             SELECT Id, Meter_Counter_Status__c, Meter_Counter_Remarks__c, Gas_Type__c,
    //                    MCV_Status__c, BP_Number__c, Inlet_Outlet_Reversal_Needed__c,
    //                    Reversal_Correction_Details__c, Is_The_Customer_Available_Meter_Repl__c
    //             FROM WorkOrder
    //             WHERE Id = :workOrderId
    //             LIMIT 1
    //         ];
    //         System.debug('OLD WorkOrder fetched: Id=' + (wo != null ? wo.Id : 'null') + ', BP_Number=' + wo.BP_Number__c);
    //
    //         Account acc = [
    //             SELECT Previous_Meter_Reading__c
    //             FROM Account
    //             WHERE BP_Number__c = :wo.BP_Number__c
    //             LIMIT 1
    //         ];
    //         System.debug('OLD Account fetched, previous reading: ' + (acc != null ? acc.Previous_Meter_Reading__c : 'null'));
    //
    //         System.debug('<< OLD getWorkOrderDetails END.');
    //         return new WorkOrderWrapper(wo, acc.Previous_Meter_Reading__c);
    //     } catch (Exception e) {
    //         System.debug('OLD Error in getWorkOrderDetails: ' + e.getMessage());
    //         System.debug('OLD Exception stack: ' + e.getStackTraceString());
    //         return null;
    //     }
    // }
    */

    ////////////////////////////////////////////////////////////////////////////////
    // getWorkOrderDetails (active)
    ////////////////////////////////////////////////////////////////////////////////
    @AuraEnabled(cacheable=true)
    public static WorkOrderWrapper getWorkOrderDetails(String workOrderId) {
        System.debug('>> getWorkOrderDetails START. workOrderId=' + workOrderId);
        try {
            System.debug('About to query WorkOrder for id: ' + workOrderId);
            WorkOrder wo = [
                SELECT Id, Meter_Counter_Status__c,Old_Meter_Number__c, Meter_Counter_Remarks__c,Gas_Type__c,
                       MCV_Status__c, BP_Number__c, Inlet_Outlet_Reversal_Needed__c,
                       Reversal_Correction_Details__c, Is_The_Customer_Available_Meter_Repl__c
                FROM WorkOrder
                WHERE Id = :workOrderId
                LIMIT 1
            ];
            System.debug('WorkOrder fetched: Id=' + (wo != null ? wo.Id : 'null') + ', BP_Number=' + wo.BP_Number__c);

            Account acc;
            Decimal prevReading;
            try {
                System.debug('Attempting Account lookup by BP_Number: ' + wo.BP_Number__c);
                List<Account> accList = [SELECT Previous_Meter_Reading__c FROM Account WHERE BP_Number__c = :wo.BP_Number__c LIMIT 1];
                System.debug('Account query returned size: ' + accList.size());
                if (!accList.isEmpty()) {
                    acc = accList[0];
                    prevReading = acc.Previous_Meter_Reading__c;
                    System.debug('Previous meter reading found: ' + prevReading);
                } else {
                    System.debug('No Account matched BP_Number: ' + wo.BP_Number__c);
                }
            } catch (Exception exAcc) {
                System.debug('ERROR: Account lookup issue in getWorkOrderDetails: ' + exAcc.getMessage());
                System.debug('Account lookup exception stack: ' + exAcc.getStackTraceString());
            }

            // Prepare wrapper with existing WO + previous meter reading
            WorkOrderWrapper wrapper = new WorkOrderWrapper(wo, prevReading);
            System.debug('Wrapper prepared with WO and previousReading=' + prevReading);

            // NEW: attempt to fetch related ServiceAppointment (visit-specific fields)
            try {
                System.debug('Attempting ServiceAppointment lookup for WorkOrder: ' + wo.Id);
                List<ServiceAppointment> saList = [
                    SELECT Id, Meter_Unsafe__c, Meter_Inaccessible__c, Customer_Ready_To_Shift__c,
                           Alternate_Phone__c, Correct_Address__c
                    FROM ServiceAppointment
                    WHERE Work_Order__c = :wo.Id
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                System.debug('ServiceAppointment query returned size: ' + saList.size());
                if (!saList.isEmpty()) {
                    ServiceAppointment sa = saList[0];
                    wrapper.serviceAppointmentId = sa.Id;
                    wrapper.saMeterUnsafe = sa.Meter_Unsafe__c;
                    wrapper.saMeterInaccessible = sa.Meter_Inaccessible__c;
                    wrapper.saCustomerReadyToShift = sa.Customer_Ready_To_Shift__c;
                    wrapper.saAlternatePhone = sa.Alternate_Phone__c;
                    wrapper.saCorrectAddress = sa.Correct_Address__c;
                    System.debug('Attached ServiceAppointment to wrapper: ' + sa.Id);
                } else {
                    System.debug('No ServiceAppointment found for WorkOrder: ' + wo.Id);
                }
            } catch (Exception exSA) {
                System.debug('ERROR: ServiceAppointment lookup issue in getWorkOrderDetails: ' + exSA.getMessage());
                System.debug('ServiceAppointment lookup exception stack: ' + exSA.getStackTraceString());
                // do not fail - wrapper will still contain WO and previousReading
            }

            System.debug('<< getWorkOrderDetails END. returning wrapper for WO=' + wo.Id);
            return wrapper;
        } catch (Exception e) {
            System.debug('ERROR in getWorkOrderDetails: ' + e.getMessage());
            System.debug('Exception stack: ' + e.getStackTraceString());
            return null;
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // WorkOrderWrapper
    ////////////////////////////////////////////////////////////////////////////////
    public class WorkOrderWrapper {
        @AuraEnabled public WorkOrder workOrder{get;set;}
        @AuraEnabled public Decimal previousMeterReading{get;set;}
        @AuraEnabled public String isCustomerAvailable { get; set; }

        // NEW: service appointment related fields to support technician UI
        @AuraEnabled public Id serviceAppointmentId { get; set; }
        @AuraEnabled public Boolean saMeterUnsafe { get; set; }
        @AuraEnabled public Boolean saMeterInaccessible { get; set; }
        @AuraEnabled public Boolean saCustomerReadyToShift { get; set; }
        @AuraEnabled public String saAlternatePhone { get; set; }
        @AuraEnabled public String saCorrectAddress { get; set; }

        public WorkOrderWrapper(WorkOrder wo, Decimal prev) {
            System.debug('WorkOrderWrapper constructor called. WO Id=' + (wo != null ? wo.Id : 'null') + ', prevReading=' + prev);
            this.workOrder = wo;
            this.previousMeterReading = prev;
            try {
                this.isCustomerAvailable = wo.Is_The_Customer_Available_Meter_Repl__c;
            } catch (Exception e) {
                System.debug('WorkOrderWrapper: could not set isCustomerAvailable: ' + e.getMessage());
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // ORIGINAL (commented) - old parameter-heavy saveMeterReplDetails (kept for reference)
    ////////////////////////////////////////////////////////////////////////////////
    /*
    // @AuraEnabled
    // public static void saveMeterReplDetails(
    //     Id recordId,
    //     List<PhotoWrapper> listFiles, // Retained for method signature compatibility
    //     String newMeter,
    //     String oldMeter,
    //     String mcvStatus,
    //     String meterCounterStatus,
    //     String meterRemarks,
    //     String gasType,
    //     String inletOutletReversalNeeded,
    //     String reversalCorrectionDetails,
    //     String isCustomerAvailable,
    //     String leakageObserved,
    //     String leakageLocation,
    //     String rubberHoseConcealed,
    //     String isMeterReplaced,
    //      // NEW PARAMETERS: ServiceAppointment update values (optional)
    //     Id serviceAppointmentId,
    //     Boolean meterUnsafe,
    //     Boolean meterInaccessible,
    //     Boolean customerReadyToShift,
    //     String alternatePhone,
    //     String correctAddress
    // ) {
    //     System.debug('OLD Updating WorkOrder fields only (no photo upload) for record: ' + recordId);
    //
    //     // Fetch WorkOrder
    //     WorkOrder wo = [
    //         SELECT Id,
    //                MCV_Status__c,
    //                Meter_Counter_Status__c,
    //                Meter_Counter_Remarks__c,
    //                Gas_Type__c,
    //                Inlet_Outlet_Reversal_Needed__c,
    //                Reversal_Correction_Details__c,
    //                Is_The_Customer_Available_Meter_Repl__c,
    //                Leakage_Observed__c,
    //                Leakage_Location__c,
    //             //   Rubber_Hose_Concealed__c,
    //                Previous_Meter_Reading__c,
    //                New_Meter_Reading__c,
    //                Meter_replaced__c
    //         FROM WorkOrder
    //         WHERE Id = :recordId
    //         LIMIT 1
    //     ];
    //     System.debug('OLD Fetched WorkOrder: ' + (wo != null ? wo.Id : 'null'));
    //
    //     // Update fields
    //     wo.MCV_Status__c = mcvStatus;
    //     wo.Meter_Counter_Status__c = meterCounterStatus;
    //     wo.Meter_Counter_Remarks__c = meterRemarks;
    //     wo.Gas_Type__c = gasType;
    //     wo.Inlet_Outlet_Reversal_Needed__c = inletOutletReversalNeeded;
    //     wo.Reversal_Correction_Details__c = reversalCorrectionDetails;
    //     wo.Is_The_Customer_Available_Meter_Repl__c = isCustomerAvailable;
    //     wo.Leakage_Observed__c = leakageObserved;
    //     wo.Leakage_Location__c = leakageLocation;
    //    // wo.Rubber_Hose_Concealed__c = rubberHoseConcealed;
    //     wo.New_Meter_Reading__c = newMeter;
    //     wo.Previous_Meter_Reading__c = oldMeter;
    //     wo.Meter_replaced__c = isMeterReplaced == 'Yes';
    //
    //     update wo;
    //     System.debug('OLD WorkOrder updated successfully: ' + wo.Id);
    //
    //          // NEW: Update ServiceAppointment (visit-specific fields) if SA Id provided
    //         if (serviceAppointmentId != null) {
    //             try {
    //                 ServiceAppointment saToUpdate = new ServiceAppointment(
    //                     Id = serviceAppointmentId,
    //                     Meter_Unsafe__c = meterUnsafe,
    //                     Meter_Inaccessible__c = meterInaccessible,
    //                     Customer_Ready_To_Shift__c = customerReadyToShift,
    //                     Alternate_Phone__c = alternatePhone,
    //                     Correct_Address__c = correctAddress
    //                 );
    //                 update saToUpdate;
    //                 System.debug('OLD ServiceAppointment updated successfully: ' + serviceAppointmentId);
    //             } catch (Exception exSAUpdate) {
    //                 System.debug('OLD Failed to update ServiceAppointment [' + serviceAppointmentId + ']: ' + exSAUpdate.getMessage());
    //             }
    //         }
    // }
    */

    ////////////////////////////////////////////////////////////////////////////////
    // saveMeterReplDetails (active, payload-based)
    ////////////////////////////////////////////////////////////////////////////////
    @AuraEnabled
    public static void saveMeterReplDetails(
        MeterReplPayload payload, List<PhotoWrapper> listFiles
    ) {
        System.debug('>> saveMeterReplDetails START. payload.recordId=' + (payload != null ? String.valueOf(payload.recordId) : 'null'));
        System.debug('Payload summary: ' + (payload != null ? JSON.serializePretty(payload) : 'null'));
        System.debug('Files count: ' + (listFiles != null ? listFiles.size() : 0));

         if (payload == null || payload.recordId == null) {
                System.debug('Invalid payload or missing recordId. Throwing AuraHandledException.');
                throw new AuraHandledException('Invalid payload or missing recordId.');
            }

            // Fetch WorkOrder with fields present in your list
            System.debug('Querying WorkOrder with Id: ' + payload.recordId);
            WorkOrder wo = [
                SELECT Id,
                       Old_Meter_Number__c,
                       New_Meter_Number__c,
                       Previous_Meter_Reading__c,
                       Old_Meter_Reading__c,
                       New_Meter_Reading__c,
                       Meter_replaced__c,
                       Meter_already_replaced__c,
                       Meter_not_replaced__c,
                       Leakage_Observed__c,
                       Leakage_Location__c,
                       MCV_Status__c,
                       First_Reading_of_the_gas_detector__c,
                       Inlet_Outlet_Reversal_Needed__c,
                       Reversal_Correction_Details__c,
                       Disconnection_Required__c,
                       Disconnection_from_Outside_Remark__c,
                       MCV_Plugging_Required__c,
                       MCV_Plugging_Remark__c,
                       Meter_Counter_Status__c,
                       Meter_Counter_Remarks__c,
                       Add_Meter_Sound__c,
                       Old_Meter_Rusted__c,
                       Counter_defective_smokey__c,
                       Meter_Faulty__c,
                       Meter_Not_Running__c,
                       Rubber_Hose_Condition__c,
                       Final_Remark__c,
                       BP_Number__c,
                       Gas_Type__c,
                       RIV_closed_checkbox__c,
                       Case_Remark__c
                FROM WorkOrder
                WHERE Id = :payload.recordId
                LIMIT 1
            ];
            System.debug('Fetched WorkOrder: ' + (wo != null ? wo.Id : 'null'));

            // Map payload -> WO fields (use direct assignments for fields we know exist)
            try { wo.Old_Meter_Number__c = payload.previousMeterNumber; System.debug('Set Old_Meter_Number__c=' + payload.previousMeterNumber);} catch(Exception e) { System.debug('Missing Old_Meter_Number__c: ' + e.getMessage()); }
            try { wo.New_Meter_Number__c = payload.newMeterNumber; System.debug('Set New_Meter_Number__c=' + payload.newMeterNumber);} catch(Exception e) { System.debug('Missing New_Meter_Number__c: ' + e.getMessage());}
            try { wo.Previous_Meter_Reading__c = payload.previousMeterReading; System.debug('Set Previous_Meter_Reading__c=' + payload.previousMeterReading);} catch(Exception e) { System.debug('Missing Previous_Meter_Reading__c: ' + e.getMessage());}
            try { wo.Old_Meter_Reading__c = payload.oldMeterReadingCaptured; System.debug('Set Old_Meter_Reading__c=' + payload.oldMeterReadingCaptured);} catch(Exception e) { System.debug('Missing Old_Meter_Reading__c: ' + e.getMessage());}
            try { wo.New_Meter_Reading__c = payload.newMeterReading; System.debug('Set New_Meter_Reading__c=' + payload.newMeterReading);} catch(Exception e) { System.debug('Missing New_Meter_Reading__c: ' + e.getMessage()); }

            // replaced flags
            try { wo.Meter_replaced__c = (payload.meterAlreadyReplaced == true); System.debug('Set Meter_replaced__c=' + wo.Meter_replaced__c);} catch(Exception e) { System.debug('Error setting Meter_replaced__c: ' + e.getMessage()); }
            try { wo.Meter_already_replaced__c = payload.meterAlreadyReplaced; System.debug('Set Meter_already_replaced__c=' + payload.meterAlreadyReplaced);} catch(Exception e) { System.debug('Error setting Meter_already_replaced__c: ' + e.getMessage());}
            try { wo.Meter_not_replaced__c = payload.meterNotReplaced; System.debug('Set Meter_not_replaced__c=' + payload.meterNotReplaced);} catch(Exception e) { System.debug('Error setting Meter_not_replaced__c: ' + e.getMessage());}
            // storage location (optional)
            try { /* wo.Storage_Location__c = payload.storageLocation; */ System.debug('storageLocation=' + payload.storageLocation);} catch(Exception e) { System.debug('Error setting storageLocation: ' + e.getMessage());}

            // gas/leakage/mcv
            try { wo.Leakage_Observed__c = payload.gasLeakageObserved; System.debug('Set Leakage_Observed__c=' + payload.gasLeakageObserved);} catch(Exception e) { System.debug('Error setting Leakage_Observed__c: ' + e.getMessage());}
            try { wo.Leakage_Location__c = payload.leakageLocation; System.debug('Set Leakage_Location__c=' + payload.leakageLocation);} catch(Exception e) { System.debug('Error setting Leakage_Location__c: ' + e.getMessage());}
            try { wo.MCV_Status__c = payload.mcvStatus; System.debug('Set MCV_Status__c=' + payload.mcvStatus);} catch(Exception e) { System.debug('Error setting MCV_Status__c: ' + e.getMessage());}
            try { wo.First_Reading_of_the_gas_detector__c = payload.gasDetectorReading; System.debug('Set First_Reading_of_the_gas_detector__c=' + payload.gasDetectorReading);} catch(Exception e) { System.debug('Error setting gas detector reading: ' + e.getMessage());}
            try { wo.RIV_closed_checkbox__c = payload.rivClosed; System.debug('Set RIV_closed_checkbox__c=' + payload.rivClosed);} catch(Exception e) { System.debug('Error setting RIV_closed_checkbox__c: ' + e.getMessage());}

            // try to store leakageCaseNumber into a known WorkOrder field if available
            try {
                wo.Case_Remark__c = payload.leakageCaseNumber;
                System.debug('Set Case_Remark__c=' + payload.leakageCaseNumber);
            } catch(Exception e) {
                System.debug('Could not set Case_Remark__c: ' + e.getMessage());
            }

            // inlet/outlet rectification
            try { wo.Inlet_Outlet_Reversal_Needed__c = payload.inletOutletReversalNeeded; System.debug('Set Inlet_Outlet_Reversal_Needed__c=' + payload.inletOutletReversalNeeded);} catch(Exception e) { System.debug('Error setting Inlet_Outlet_Reversal_Needed__c: ' + e.getMessage());}
            try { wo.Reversal_Correction_Details__c = payload.rectificationRemark; System.debug('Set Reversal_Correction_Details__c=' + payload.rectificationRemark);} catch(Exception e) { System.debug('Error setting Reversal_Correction_Details__c: ' + e.getMessage());}

            // disconnection / mcv
            try { wo.Disconnection_Required__c = payload.disconnectionRequired; System.debug('Set Disconnection_Required__c=' + payload.disconnectionRequired);} catch(Exception e) { System.debug('Error setting Disconnection_Required__c: ' + e.getMessage());}
            try { wo.Disconnection_from_Outside_Remark__c = payload.disconnectionRemark; System.debug('Set Disconnection_from_Outside_Remark__c=' + payload.disconnectionRemark);} catch(Exception e) { System.debug('Error setting Disconnection_from_Outside_Remark__c: ' + e.getMessage());}
            try { wo.MCV_Plugging_Required__c = payload.mcvPluggingRequired; System.debug('Set MCV_Plugging_Required__c=' + payload.mcvPluggingRequired);} catch(Exception e) { System.debug('Error setting MCV_Plugging_Required__c: ' + e.getMessage());}
            try { wo.MCV_Plugging_Remark__c = payload.mcvPluggingRemark; System.debug('Set MCV_Plugging_Remark__c=' + payload.mcvPluggingRemark);} catch(Exception e) { System.debug('Error setting MCV_Plugging_Remark__c: ' + e.getMessage());}

            // meter counter status/remarks
            try { 
                String computedCounterStatus = payload.meterSound ? 'Meter sound flagged' : payload.meterNotRunning ? 'Not running' : payload.meterFaulty ? 'Faulty' : payload.meterCounterStatus;
                //wo.Meter_Counter_Status__c = computedCounterStatus;
                System.debug('Set Meter_Counter_Status__c=' + computedCounterStatus);
            } catch(Exception e) { System.debug('Error setting Meter_Counter_Status__c: ' + e.getMessage()); }
            try { wo.Meter_Counter_Remarks__c = payload.meterCounterRemarks; System.debug('Set Meter_Counter_Remarks__c=' + payload.meterCounterRemarks);} catch(Exception e) { System.debug('Error setting Meter_Counter_Remarks__c: ' + e.getMessage()); }

            // other flags (safe set)
            try { wo.Add_Meter_Sound__c = payload.meterSound; System.debug('Set Add_Meter_Sound__c=' + payload.meterSound);} catch(Exception e) { System.debug('Error setting Add_Meter_Sound__c: ' + e.getMessage()); }
            try { wo.Old_Meter_Rusted__c = payload.oldMeterRusted; System.debug('Set Old_Meter_Rusted__c=' + payload.oldMeterRusted);} catch(Exception e) { System.debug('Error setting Old_Meter_Rusted__c: ' + e.getMessage());}
            try { wo.Counter_defective_smokey__c = payload.counterDefectiveSmoke; System.debug('Set Counter_defective_smokey__c=' + payload.counterDefectiveSmoke);} catch(Exception e) { System.debug('Error setting Counter_defective_smokey__c: ' + e.getMessage());}
            try { wo.Meter_Faulty__c = payload.meterFaulty; System.debug('Set Meter_Faulty__c=' + payload.meterFaulty);} catch(Exception e) { System.debug('Error setting Meter_Faulty__c: ' + e.getMessage());}
            try { wo.Meter_Not_Running__c = payload.meterNotRunning; System.debug('Set Meter_Not_Running__c=' + payload.meterNotRunning);} catch(Exception e) { System.debug('Error setting Meter_Not_Running__c: ' + e.getMessage());}
            try { wo.Rubber_Hose_Condition__c = payload.rubberHoseCondition; System.debug('Set Rubber_Hose_Condition__c=' + payload.rubberHoseCondition);} catch(Exception e) { System.debug('Error setting Rubber_Hose_Condition__c: ' + e.getMessage());}
            try { wo.Gas_Type__c = payload.gasType; System.debug('Set Rubber_Hose_Condition__c=' + payload.gasType);} catch(Exception e) { System.debug('Error setting gasType: ' + e.getMessage());}
            try { wo.Final_Remark__c = payload.finalRemark; System.debug('Set Final_Remark__c=' + payload.finalRemark);} catch(Exception e) { System.debug('Error setting Final_Remark__c: ' + e.getMessage()); }

            // update WorkOrder
            try {
                System.debug('About to update WorkOrder: ' + wo.Id);
                update wo;
                System.debug('WorkOrder updated successfully: ' + wo.Id);
            } catch (Exception dmlEx) {
                System.debug('ERROR updating WorkOrder: ' + dmlEx.getMessage());
                System.debug('Stack: ' + dmlEx.getStackTraceString());
                throw new AuraHandledException('Failed to update WorkOrder: ' + dmlEx.getMessage());
            }

            // Update ServiceAppointment if provided (you said SA update required)
            if (payload.serviceAppointmentId != null) {
                System.debug('ServiceAppointment update requested. SA Id=' + payload.serviceAppointmentId);
                try {
                    ServiceAppointment saToUpdate = new ServiceAppointment(
                        Id = payload.serviceAppointmentId,
                        Meter_Unsafe__c = payload.meterUnsafe,
                        Meter_Inaccessible__c = payload.meterInaccessible,
                        Customer_Ready_To_Shift__c = payload.customerReadyToShift,
                        Alternate_Phone__c = payload.alternatePhone,
                        Correct_Address__c = payload.correctAddress
                    );

                    // If you store tenant info on SA, attempt to set them (non-fatal if fields missing)
                    try { saToUpdate.put('Tenant_Name__c', payload.tenantName); System.debug('Set Tenant_Name__c on SA=' + payload.tenantName);} catch(Exception ex) { System.debug('Tenant_Name__c not present on SA object: ' + ex.getMessage()); }
                    try { saToUpdate.put('Tenant_Mobile__c', payload.tenantMobile); System.debug('Set Tenant_Mobile__c on SA=' + payload.tenantMobile);} catch(Exception ex) { System.debug('Tenant_Mobile__c not present on SA object: ' + ex.getMessage()); }

                    System.debug('About to update ServiceAppointment: ' + payload.serviceAppointmentId);
                    update saToUpdate;
                    System.debug('ServiceAppointment updated successfully: ' + payload.serviceAppointmentId);
                } catch(Exception exSA) {
                    System.debug('ServiceAppointment update failed: ' + exSA.getMessage());
                    System.debug('ServiceAppointment update exception stack: ' + exSA.getStackTraceString());
                    // swallow intentionally to keep original WO update behaviour intact
                }
            } else {
                System.debug('No ServiceAppointment update requested.');
            }

        System.debug('<< saveMeterReplDetails END for recordId=' + payload.recordId);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // PhotoWrapper
    ////////////////////////////////////////////////////////////////////////////////
    public class PhotoWrapper {
        @AuraEnabled public Integer id { get; set; }
        @AuraEnabled public Integer index { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public Boolean uploaded { get; set; }
        @AuraEnabled public String previewUrl { get; set; }
        @AuraEnabled public String base64Data { get; set; }
        @AuraEnabled public String fileBody { get; set; }
        @AuraEnabled public String fileType { get; set; }
    }

     // ---------- Payload wrapper to avoid parameter limit ----------
    public class MeterReplPayload {
        @AuraEnabled public Id recordId { get; set; }

        // meter numbers & readings
        @AuraEnabled public String previousMeterNumber { get; set; } // Old_Meter_Number__c
        @AuraEnabled public String previousMeterReading { get; set; } // Previous_Meter_Reading__c / Old_Meter_Reading__c
        @AuraEnabled public String newMeterNumber { get; set; } // New_Meter_Number__c
        @AuraEnabled public String newMeterReading { get; set; } // New_Meter_Reading__c
        @AuraEnabled public String oldMeterReadingCaptured { get; set; } // Old_Meter_Reading__c
        @AuraEnabled public String meterCounterStatus { get; set; } 
        @AuraEnabled public String meterCounterRemarks { get; set; }

        // replacement flags & storage
        @AuraEnabled public Boolean meterAlreadyReplaced { get; set; } // Meter_already_replaced__c / Meter_replaced__c
        @AuraEnabled public Boolean meterNotReplaced { get; set; } // Meter_not_replaced__c
        @AuraEnabled public String storageLocation { get; set; } // Storage_Location__c (if you have)

        // leak / gas / MCV
        @AuraEnabled public String gasLeakageObserved { get; set; } // Gas_Leakage_Observed__c / Leakage_Observed__c
        @AuraEnabled public String leakageLocation { get; set; } // Leakage_Location__c
        @AuraEnabled public String leakageCaseNumber { get; set; } // map to Case_Remark__c / custom if available
        @AuraEnabled public String mcvStatus { get; set; } // MCV_Status__c
        @AuraEnabled public Boolean rivClosed { get; set; } // RIV_closed_checkbox__c / RIV_Closed__c
        @AuraEnabled public String gasDetectorReading { get; set; } // First_Reading_of_the_gas_detector__c

        // inlet/outlet rectification
        @AuraEnabled public String inletOutletReversalNeeded { get; set; } // Inlet_Outlet_Reversal_Needed__c
        @AuraEnabled public Boolean oldMeterWorkingAfterRectification { get; set; } // Rectification result checkbox - Rectification_Done_On_Site_And_Old_Meter__c maybe
        @AuraEnabled public String rectificationRemark { get; set; } // Rectification dropdown chosen value

        // conditions + remarks
        @AuraEnabled public Boolean meterSound { get; set; } // Add_Meter_Sound__c
        @AuraEnabled public String meterSoundRemarks { get; set; } // (use Meter_Image_Remark__c or Meter_Counter_Remarks__c)
        @AuraEnabled public Boolean oldMeterRusted { get; set; } // Old_Meter_Rusted__c
        @AuraEnabled public String oldMeterRustedRemarks { get; set; }
        @AuraEnabled public Boolean counterDefectiveSmoke { get; set; } // Counter_defective_smokey__c
        @AuraEnabled public String counterDefectiveRemarks { get; set; }
        @AuraEnabled public Boolean meterFaulty { get; set; } // Meter_Faulty__c
        @AuraEnabled public String meterFaultyRemarks { get; set; }
        @AuraEnabled public Boolean meterNotRunning { get; set; } // Meter_Not_Running__c
        @AuraEnabled public String meterNotRunningRemarks { get; set; }

        // Disconnection / MCV
        @AuraEnabled public Boolean disconnectionRequired { get; set; } // Disconnection_Required__c
        @AuraEnabled public String disconnectionRemark { get; set; } // Disconnection_Remark__c
        @AuraEnabled public Boolean mcvPluggingRequired { get; set; } // MCV_Plugging_Required__c
        @AuraEnabled public String mcvPluggingRemark { get; set; } // MCV_Plugging_Remark__c

        // Unsafe / Inaccessible (SA fields)
        @AuraEnabled public Boolean meterUnsafe { get; set; } // SA: Meter_Unsafe__c
        @AuraEnabled public String meterUnsafeRemarks { get; set; } // (store in SA or WO if needed)
        @AuraEnabled public Boolean meterUnsafeReadyToShift { get; set; }

        @AuraEnabled public Boolean meterInaccessible { get; set; } // SA: Meter_Inaccessible__c
        @AuraEnabled public String meterInaccessibleRemarks { get; set; }
        @AuraEnabled public Boolean meterInaccessibleReadyToShift { get; set; }

        // ServiceAppointment
        @AuraEnabled public Id serviceAppointmentId { get; set; }
        @AuraEnabled public Boolean customerReadyToShift { get; set; }
        @AuraEnabled public String alternatePhone { get; set; } // SA: Alternate_Phone__c
        @AuraEnabled public String correctAddress { get; set; } // SA: Correct_Address__c

        // tenant / occupant
        @AuraEnabled public String occupantType { get; set; } // Customer | Tenant
        @AuraEnabled public String tenantName { get; set; } // Customer_Name__c / Tenant fields if present
        @AuraEnabled public String tenantMobile { get; set; }
        @AuraEnabled public String gasType { get; set; }

        // other misc
        @AuraEnabled public String rubberHoseCondition { get; set; } // Rubber_Hose_Condition__c
        @AuraEnabled public String finalRemark { get; set; } // Final_Remark__c
    }

    ////////////////////////////////////////////////////////////////////////////////
    // savePhotoUploadsReversal
    ////////////////////////////////////////////////////////////////////////////////
    @AuraEnabled
    public static String savePhotoUploadsReversal(Id recordId, List<PhotoWrapper> listFiles) {
        System.debug('>> savePhotoUploadsReversal START. Record Id: ' + recordId);
        System.debug('Total Files Received: ' + (listFiles != null ? listFiles.size() : 0));
        System.debug('Received Files: ' + JSON.serializePretty(listFiles));

        try {
            List<ContentVersion> contentVersions = new List<ContentVersion>();

            for (PhotoWrapper file : listFiles) {
                System.debug('Processing file wrapper: index=' + file.index + ', fileName=' + file.fileName + ', label=' + file.label);
                if (String.isNotBlank(file.base64Data) && String.isNotBlank(file.fileName)) {
                    // Create ContentVersion
                    ContentVersion cv = new ContentVersion();
                    cv.Title = file.label != null ? file.label : file.fileName;
                    cv.PathOnClient = '/' + file.fileName;
                    cv.VersionData = EncodingUtil.base64Decode(file.base64Data);
                    contentVersions.add(cv);
                    System.debug('Prepared ContentVersion for: ' + file.fileName);
                } else {
                    System.debug('Skipping file due to missing data: ' + file.fileName);
                }
            }

            if (contentVersions.isEmpty()) {
                System.debug('No valid content versions to insert. Exiting.');
                return 'No valid files to upload.';
            }

            System.debug('Inserting ContentVersions count: ' + contentVersions.size());
            insert contentVersions;
            System.debug('Inserted ContentVersion records count: ' + contentVersions.size());

            // Map to ContentDocument
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
                System.debug('Mapped ContentVersion ' + cv.Id + ' -> Document ' + cv.ContentDocumentId);
            }

            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                    LinkedEntityId = recordId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
                System.debug('Prepared ContentDocumentLink for document: ' + versionToDocMap.get(versionId));
            }

            insert links;
            System.debug('Linked documents to WorkOrder: ' + recordId);

            return 'SUCCESS';

        } catch (Exception e) {
            System.debug('ERROR during photo upload (Reversal): ' + e.getMessage() + ' at line ' + e.getLineNumber());
            System.debug('Exception stack: ' + e.getStackTraceString());
            return 'ERROR: ' + e.getMessage();
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // savePhotoUploadsLPG
    ////////////////////////////////////////////////////////////////////////////////
    @AuraEnabled
    public static String savePhotoUploadsLPG(Id recordId, List<PhotoWrapper> listFiles) {
        System.debug('>> savePhotoUploadsLPG START. Record Id: ' + recordId);
        System.debug('Total Files Received: ' + (listFiles != null ? listFiles.size() : 0));

        try {
            List<ContentVersion> contentVersions = new List<ContentVersion>();

            for (PhotoWrapper file : listFiles) {
                System.debug('Processing LPG file wrapper: fileName=' + file.fileName + ', label=' + file.label);
                if (String.isNotBlank(file.base64Data) && String.isNotBlank(file.fileName)) {
                    ContentVersion cv = new ContentVersion();
                    cv.Title = file.label;
                    cv.PathOnClient = '/' + file.fileName;
                    cv.VersionData = EncodingUtil.base64Decode(file.base64Data);
                    contentVersions.add(cv);
                    System.debug('Added ContentVersion for: ' + file.label);
                } else {
                    System.debug('Skipping file due to missing base64Data or fileName: ' + file.fileName);
                }
            }

            if (contentVersions.isEmpty()) {
                System.debug('No valid files to insert. Exiting early.');
                return 'No valid files to upload.';
            }

            System.debug('Inserting ContentVersions count: ' + contentVersions.size());
            insert contentVersions;
            System.debug('Inserted ContentVersions successfully.');

            // Map ContentVersion Id to ContentDocumentId
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE Id IN :contentVersions
            ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
                System.debug('Mapped ContentVersion ' + cv.Id + ' to Document ' + cv.ContentDocumentId);
            }

            // Create ContentDocumentLinks
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                    LinkedEntityId = recordId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
                System.debug('Prepared ContentDocumentLink for doc: ' + versionToDocMap.get(versionId));
            }

            insert links;
            System.debug('Linked documents to record: ' + recordId);

            return 'SUCCESS';

        } catch (Exception e) {
            System.debug('ERROR saving photos (LPG): ' + e.getMessage() + ' at line ' + e.getLineNumber());
            System.debug('Exception stack: ' + e.getStackTraceString());
            return 'ERROR: ' + e.getMessage();
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // updateWorkStepStatus
    ////////////////////////////////////////////////////////////////////////////////
    public static void updateWorkStepStatus(Id workOrderId, String name) {
        System.debug('>> updateWorkStepStatus START. workOrderId=' + workOrderId + ', stepName=' + name);
        try {
            List<WorkStep> steps = [
                SELECT Id, Status
                FROM WorkStep
                WHERE ParentRecordId = :workOrderId
                AND Name = :name
                LIMIT 1
            ];
            System.debug('WorkStep query returned size: ' + steps.size());

            if (!steps.isEmpty()) {
                WorkStep ws = steps[0];
                System.debug('Updating WorkStep Id=' + ws.Id + ' from Status=' + ws.Status + ' to Completed');
                ws.Status = 'Completed';
                update ws;
                System.debug('Updated WorkStep status to Completed for step: ' + name);
            } else {
                System.debug('No matching WorkStep found to update for: ' + name);
            }
        } catch (Exception e) {
            System.debug('ERROR in updateWorkStepStatus: ' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());
        }
        System.debug('<< updateWorkStepStatus END for workOrderId=' + workOrderId);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // savePhotoUploadsMeter
    ////////////////////////////////////////////////////////////////////////////////
    @AuraEnabled
    public static String savePhotoUploadsMeter(Id recordId, List<PhotoWrapper> listFiles) {
        System.debug('>> savePhotoUploadsMeter START. Record Id: ' + recordId);
        System.debug('Total Files Received: ' + (listFiles != null ? listFiles.size() : 0));

        try {
            List<ContentVersion> contentVersions = new List<ContentVersion>();

            for (PhotoWrapper file : listFiles) {
                System.debug('Processing meter file wrapper: fileName=' + file.fileName + ', label=' + file.label);
                if (String.isNotBlank(file.base64Data) && String.isNotBlank(file.fileName)) {
                    ContentVersion cv = new ContentVersion();
                    cv.Title = file.label != null ? file.label : file.fileName;
                    cv.PathOnClient = '/' + file.fileName;
                    cv.VersionData = EncodingUtil.base64Decode(file.base64Data);
                    contentVersions.add(cv);
                    System.debug('Added ContentVersion for: ' + file.fileName);
                } else {
                    System.debug('Skipping file due to missing data: ' + file.fileName);
                }
            }

            if (contentVersions.isEmpty()) {
                System.debug('No valid files to upload for meter. Exiting.');
                return 'No valid files to upload.';
            }

            System.debug('Inserting ContentVersion records count: ' + contentVersions.size());
            insert contentVersions;
            System.debug('Inserted ContentVersion records: ' + contentVersions.size());

            // Map to ContentDocument
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
                System.debug('Mapped CV ' + cv.Id + ' -> Doc ' + cv.ContentDocumentId);
            }

            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                    LinkedEntityId = recordId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
                System.debug('Prepared ContentDocumentLink for doc: ' + versionToDocMap.get(versionId));
            }

            insert links;
            System.debug('Linked documents to WorkOrder: ' + recordId);

            return 'SUCCESS';

        } catch (Exception e) {
            System.debug('ERROR during photo upload (Meter): ' + e.getMessage() + ' at line ' + e.getLineNumber());
            System.debug('Exception stack: ' + e.getStackTraceString());
            return 'ERROR: ' + e.getMessage();
        }
    }

    /*
    ////////////////////////////////////////////////////////////////////////////////
    // ORIGINAL (commented) - saveUnsafeLetterDocument kept for reference
    ////////////////////////////////////////////////////////////////////////////////
    // @AuraEnabled
    // public static void saveUnsafeLetterDocument(Id workOrderId, Id contentDocumentId) {
    //     System.debug('Inside unsafe document (OLD):::' + workOrderId + ' docId=' + contentDocumentId);
    //     try {
    //         Document__c doc = new Document__c();
    //         doc.Work_Order__c = workOrderId;
    //         doc.Content_Document_Id_Meter_Repl__c = contentDocumentId;
    //         doc.Document_Type_Meter_Repl__c = 'Unsafe Letter';
    //         insert doc;
    //         System.debug('OLD Document__c inserted Id=' + doc.Id);
    //     } catch (Exception e) {
    //         System.debug('OLD Error creating Document__c: ' + e.getMessage());
    //         throw new AuraHandledException('Failed to save Unsafe Letter document metadata.');
    //     }
    // }
    */

    ////////////////////////////////////////////////////////////////////////////////
    // savePhotoUploadsFinal
    ////////////////////////////////////////////////////////////////////////////////
    @AuraEnabled
    public static String savePhotoUploadsFinal(Id recordId, List<PhotoWrapper> listFiles) {
        System.debug('>> savePhotoUploadsFinal START. Record Id: ' + recordId);
        System.debug('Total Files Received: ' + (listFiles != null ? listFiles.size() : 0));

        try {
            List<ContentVersion> contentVersions = new List<ContentVersion>();

            for (PhotoWrapper file : listFiles) {
                System.debug('Processing final file wrapper: fileName=' + file.fileName + ', label=' + file.label);
                if (String.isNotBlank(file.base64Data) && String.isNotBlank(file.fileName)) {
                    ContentVersion cv = new ContentVersion();
                    cv.Title = file.label != null ? file.label : file.fileName;
                    cv.PathOnClient = '/' + file.fileName;
                    cv.VersionData = EncodingUtil.base64Decode(file.base64Data);
                    contentVersions.add(cv);
                    System.debug('Added ContentVersion for: ' + file.fileName);
                } else {
                    System.debug('Skipping file due to missing data: ' + file.fileName);
                }
            }

            if (contentVersions.isEmpty()) {
                System.debug('No valid files to upload for final. Exiting.');
                return 'No valid files to upload.';
            }

            System.debug('Inserting ContentVersion records count: ' + contentVersions.size());
            insert contentVersions;
            System.debug('Inserted ContentVersion records: ' + contentVersions.size());

            // Map to ContentDocument
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
                System.debug('Mapped CV ' + cv.Id + ' -> Doc ' + cv.ContentDocumentId);
            }

            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                    LinkedEntityId = recordId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
                System.debug('Prepared ContentDocumentLink for doc: ' + versionToDocMap.get(versionId));
            }

            insert links;
            System.debug('Linked documents to WorkOrder: ' + recordId);

            return 'SUCCESS';

        } catch (Exception e) {
            System.debug('ERROR during photo upload (Final): ' + e.getMessage() + ' at line ' + e.getLineNumber());
            System.debug('Exception stack: ' + e.getStackTraceString());
            return 'ERROR: ' + e.getMessage();
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // saveFinalRemark
    ////////////////////////////////////////////////////////////////////////////////
    @AuraEnabled
    public static void saveFinalRemark(String workOrderId, String remark) {
        System.debug('>> saveFinalRemark START. workOrderId=' + workOrderId + ', remark=' + remark);
        try {
            WorkOrder wo = [SELECT Id, Final_Remark__c FROM WorkOrder WHERE Id = :workOrderId];
            System.debug('Fetched WO for final remark: ' + wo.Id + ', currentFinalRemark=' + wo.Final_Remark__c);
            wo.Final_Remark__c = remark;
            update wo;
            System.debug('Updated Final_Remark__c on WorkOrder: ' + workOrderId);

            updateWorkStepStatus(workOrderId, 'Data Captures Detail');

        } catch(Exception e) {
            System.debug('ERROR in saveFinalRemark: Line=' + e.getLineNumber() + ' Msg=' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());
            // do not rethrow, keep behavior same as before
        }
        System.debug('<< saveFinalRemark END for workOrderId=' + workOrderId);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // createCRMCaseAndReturnBP
    ////////////////////////////////////////////////////////////////////////////////
    @AuraEnabled
    public static String createCRMCaseAndReturnBP(String workOrderId) {
        System.debug('>> createCRMCaseAndReturnBP START. workOrderId=' + workOrderId);
        try {
            WorkOrder wo = [SELECT Id, AccountId, BP_Number__c FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
            System.debug('Fetched WorkOrder: ' + wo.Id + ', AccountId=' + wo.AccountId + ', BP=' + wo.BP_Number__c);

            Case c = new Case(
                Subject = 'Gas Leakage Detected during Meter Replacement',
                Origin = 'Field Visit',
                Status = 'New',
                AccountId = wo.AccountId,
                Work_Order__c = wo.Id,
                Description = 'Gas leakage observed. Please investigate.'
            );
            System.debug('About to insert Case with Subject=' + c.Subject + ' for AccountId=' + c.AccountId);
            insert c;
            System.debug('Inserted Case Id=' + c.Id);

            System.debug('<< createCRMCaseAndReturnBP END. returning BP=' + wo.BP_Number__c);
            return wo.BP_Number__c;
        } catch (Exception e) {
            System.debug('ERROR in createCRMCaseAndReturnBP: ' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());
            throw new AuraHandledException('Failed to create case: ' + e.getMessage());
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // uploadFileUnsafeLetter
    ////////////////////////////////////////////////////////////////////////////////
    @AuraEnabled
    public static void uploadFileUnsafeLetter(String fileName, string base64Data, String recordId) {
        System.debug('>> uploadFileUnsafeLetter START. fileName=' + fileName + ', recordId=' + recordId);
        System.debug('base64Data length=' + (base64Data != null ? String.valueOf(base64Data.length()) : 'null'));
        try {
            Blob fileBlob = EncodingUtil.base64Decode(base64Data);
            System.debug('Decoded blob length: ' + (fileBlob != null ? String.valueOf(fileBlob.size()) : 'null'));

            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = fileBlob;
            System.debug('About to insert ContentVersion: Title=' + cv.Title + ', PathOnClient=' + cv.PathOnClient);
            insert cv;
            System.debug('Inserted ContentVersion Id=' + cv.Id);

            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
            System.debug('Resolved ContentDocumentId=' + contentDocumentId);
            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = contentDocumentId;
            link.LinkedEntityId =  recordId; 
            link.ShareType = 'I';
            System.debug('About to insert ContentDocumentLink for ContentDocumentId=' + contentDocumentId + ' LinkedEntityId=' + recordId);
            insert link;            
            System.debug('Inserted ContentDocumentLink Id=' + link.Id);

            Document__c doc = new Document__c();
            doc.Work_Order__c = recordId;
            doc.Content_Document_Id_Meter_Repl__c = link.ContentDocumentId;
            doc.Document_Type_Meter_Repl__c = 'Unsafe Letter';
            System.debug('About to insert Document__c for WO=' + recordId + ' with ContentDocumentId=' + link.ContentDocumentId);
            insert doc;
            System.debug('Inserted Document__c Id=' + doc.Id);

        } catch(Exception e) {
            System.debug('ERROR in uploadFileUnsafeLetter: ' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());
            throw new AuraHandledException('Failed to upload unsafe letter: ' + e.getMessage());
        }
        System.debug('<< uploadFileUnsafeLetter END for recordId=' + recordId);
    }

}