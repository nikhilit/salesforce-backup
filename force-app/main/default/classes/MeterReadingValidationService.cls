public class MeterReadingValidationService {
    public static void validateClosingReading(Id dpID) {
        Dispenser_Point__c dp = [
            SELECT Closing_Reading__c, SCADA_Closing_Reading__c
            FROM Dispenser_Point__c
            WHERE Id = :dpID
            LIMIT 1
        ];

        Decimal closing = dp.Closing_Reading__c;
        Decimal scada = dp.SCADA_Closing_Reading__c;

        Boolean discrepancy = closing < scada;
        Decimal finalValue = discrepancy ? closing : scada;

        dp.Discrepancy_Flag__c = discrepancy;
        dp.Closing_Reading__c = finalValue;

        update dp;
    }
}