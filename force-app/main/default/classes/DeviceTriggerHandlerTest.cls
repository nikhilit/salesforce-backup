@isTest
public class DeviceTriggerHandlerTest {

    @isTest
    static void testInsertAndUpdateDevice() {
        Device__c dev = new Device__c(
            Device_Code__c = 'DEV001',
            Installation_Number__c = 'INST001'
        );
        insert dev;

        Device__c insertedDev = [
            SELECT Name, To_be_processed__c, Device_Code__c, Installation_Number__c
            FROM Device__c
            WHERE Id = :dev.Id
        ];
        insertedDev.Installation_Number__c = 'INST002';
        insertedDev.Device_Code__c = 'DEV002';
        update insertedDev;
    }
}