public with sharing class WorkOrderLocationController {
    @AuraEnabled
    public static void updateCheckInLocation(Id workOrderId, Decimal latitude, Decimal longitude) {
        if (workOrderId == null || latitude == null || longitude == null)
            throw new AuraHandledException('Invalid data received.');

        WorkOrder wo = new WorkOrder(
            Id = workOrderId,
            Check_In_Location__Latitude__s = latitude,
            Check_In_Location__Longitude__s = longitude
        );
        update wo;
    }

    @AuraEnabled
    public static void updateCheckOutLocation(Id workOrderId, Decimal latitude, Decimal longitude) {
        if (workOrderId == null || latitude == null || longitude == null)
            throw new AuraHandledException('Invalid data received.');

        WorkOrder wo = new WorkOrder(
            Id = workOrderId,
            Check_Out_Location__Latitude__s = latitude,
            Check_Out_Location__Longitude__s = longitude
        );
        update wo;
    }
}