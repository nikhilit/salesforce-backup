public class DeviceTriggerHandler {

    public static void markDevicesToBeProcessed(List<Device__c> newList, Map<Id, Device__c> oldMap) {
        for (Device__c device : newList) {
            Boolean isNew = (oldMap == null || !oldMap.containsKey(device.Id));
            Boolean installationChanged = false;
            Boolean deviceNumberChanged = false;

            if (!isNew) {
                Device__c oldDevice = oldMap.get(device.Id);
                installationChanged = device.Installation_Number__c != oldDevice.Installation_Number__c ;
                deviceNumberChanged = device.Device_Code__c != oldDevice.Device_Code__c;
            }

            if (isNew || installationChanged) {
                device.To_be_processed__c = true;
            }

            if (isNew || deviceNumberChanged) {
                if (device.Device_Code__c != null) {
                    device.Name = device.Device_Code__c;
                }
            }
        }
    }
}