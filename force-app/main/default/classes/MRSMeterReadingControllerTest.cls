@isTest
public class MRSMeterReadingControllerTest {
    
    static testMethod void testMRSMeterReadingControllerMethods() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            Subject = 'Test Work Order',
            Status = 'New',
            Scheduled_Date__c = Date.today(),
            Meter_Reading_Doc_Number__c = 'DOC123'
        );
        insert wo;

        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Status = 'Scheduled',
            EarliestStartTime = DateTime.now(),
            DueDate = DateTime.now().addHours(2)
        );
        insert sa;

        Document_Master__c dm = new Document_Master__c(
            Document_Name__c = 'Meter Front Image',
            Type__c = 'MRS Start Metering',
            Order__c = 1,
            Active__c = true,
            Compress_Image__c = false
        );
        insert dm;

        MRSMeterReadingController.DataWrapper data = new MRSMeterReadingController.DataWrapper();
        data.turbineMeterReading = '100';
        data.pressure = '10';
        data.correctedPressure = '9.5';
        data.correctedVolume = '150';
        data.uncorrectedVolume = '160';
        data.correctionFactor = '1.05';
        data.temperature = '25';
        data.meterImageRemark = 'Working fine';
        data.latitude = 19.0760;
        data.longitude = 72.8777;

        MRSMeterReadingController.FileWrapper fw = new MRSMeterReadingController.FileWrapper();
        fw.base64Data = EncodingUtil.base64Encode(Blob.valueOf('dummy image'));
        fw.fileName = 'image.jpg';
        fw.label = dm.Document_Name__c;

        List<MRSMeterReadingController.FileWrapper> fileList = new List<MRSMeterReadingController.FileWrapper>{ fw };

        Test.startTest();
        Map<String, Object> result = MRSMeterReadingController.getAccountInfoFromSA(wo.Id);
       // System.assertNotEquals(null, result);

        MRSMeterReadingController.saveImage(fileList, wo.Id);

        //String checkInResult = MRSMeterReadingController.workOrderCheckIn(wo.Id, 19.0760, 72.8777);
        //System.assertEquals('success', checkInResult);

        //String checkInAgainResult = MRSMeterReadingController.workOrderCheckIn(wo.Id, 19.0760, 72.8777);
        //System.assertEquals('Already CheckIn', checkInAgainResult);

        try {
            MRSMeterReadingController.getAccountInfoFromSA(null);
            //System.assert(false, 'Exception expected for null WorkOrder Id');
        } catch (Exception ex) {
            //System.assert(ex.getMessage().contains('Work Order Id is null'));
        }
        Test.stopTest();
    }
     @isTest
    static void testUpdateWorkOrderAndCheckIn() {
            
            Account acc = new Account(Name = 'Test Account');
            insert acc;
        
            WorkType wt = new WorkType(Name = 'Test Work Type', EstimatedDuration = 10);
            insert wt;
        System.debug(wt);
            
       /*     // Create Work Type Step
            WorkTypeStep wts = new WorkTypeStep(
                WorkTypeId = wt.Id,
                StepLabel = 'Test Step',
                SequenceNumber = 1
            );
            insert wts;*/
            
            WorkOrder wo = new WorkOrder(
                WorkTypeId = wt.Id,
                AccountId = acc.Id,
                Subject = 'Test WO',
                Status = 'New',
                Check_In__c = false
            );
            insert wo;
            
            ServiceAppointment sa = new ServiceAppointment(
                ParentRecordId = wo.Id,
                Status = 'In Progress'
            );
            insert sa;
            
         /*   
            WorkStep ws = new WorkStep(
                ParentRecordId = wo.Id,
                Name = System.Label.Start_Metering_Step_Name,
                Status = 'Not Started'
            );
            insert ws;*/
            List<WorkStep> steps = [SELECT Id, Name, Status FROM WorkStep WHERE ParentRecordId = :wo.Id];
           // System.assertEquals(1, steps.size());
            
            MRSMeterReadingController.DataWrapper dataRec = new MRSMeterReadingController.DataWrapper();
            dataRec.turbineMeterReading = '10';
            dataRec.pressure = '20';
            dataRec.temperature = '30';
            dataRec.correctedVolume = '40';
            dataRec.uncorrectedVolume = '50';
            dataRec.correctionFactor = '1.2';
            dataRec.meterImageRemark = 'Test Remark';
            dataRec.latitude = 12.34;
            dataRec.longitude = 56.78;
            
            Test.startTest();
            String checkInResult = MRSMeterReadingController.workOrderCheckIn(wo.Id, 12.34, 56.78);
            System.assertEquals('success', checkInResult);
            
            String updateResult = MRSMeterReadingController.updateWorkOrder(dataRec, wo.Id);
            System.assertEquals('success', updateResult);
            Test.stopTest();
            
            WorkOrder updatedWO = [SELECT Check_In__c, Check_Out__c, Approval_Status__c 
                                    FROM WorkOrder WHERE Id = :wo.Id];
            System.assertEquals(true, updatedWO.Check_In__c);
            System.assertEquals(true, updatedWO.Check_Out__c);
            System.assertEquals('Submitted For Approval', updatedWO.Approval_Status__c);
        }    
    }