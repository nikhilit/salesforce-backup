/**
* @File Name : BusinessHourHelper .cls
* @Description : whether the incoming email arrived within 48 business hours
* @Author : Shruthi S D
* @Last Modified By :
* @Last Modified On : April 3, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 3, 2025 |   | Initial Version
**/
public class BusinessHoursHelper {
    public static Boolean checkWithinBusinessHours(Datetime outgoingTime, Datetime incomingTime, BusinessHours bh) {

        if (bh == null) {
            return false; // Default to outside business hours if not set up
        }

        // Calculate the difference in business hours
        Long businessDiff = BusinessHours.diff(bh.Id, outgoingTime, incomingTime);

      //  Convert milliseconds to hours
        Decimal hoursDiff = businessDiff / (1000 * 60 * 60);

        return hoursDiff <= Decimal.valueof(System.label.Email_Thread_Difference);
    }
}