/**
 * @description       : Input as Error logger Parames And return Instance Of Error logger object
 * @author            : Bala Preethika
 * @group             : Appstrail
 * @last modified on  : 07-07-2025
 * @last modified by  : Bala Preethika J
 * Modifications Log
 * Ver   Date         Author           Modification        
 * 1.0   12-12-2023   Bala Preethika J    Initial Version
**/
public class Error_LoggerClass {
 /* * @description : Input as Error logger Parames And return Instance Of Error logger object
    * @author      : Bala Preethika J  | 12-12-2023
    * @return      : Error_Logger__c
    * @param       : 	String className, 
                        String methodName,
                        String ParentId,
                        String expType, 
                        String expErrorMessage, 
                        Integer lineNumber,
						Boolean isCRM
    **/
    public static Error_Logger__c createErrorLogger(String className, 
                                                    String methodName,
                                                    String ParentId,
                                                    String expType, 
                                                    String expErrorMessage, 
                                                    Integer lineNumber,
                                                   Boolean IsCRM) {
                                                        
        Error_Logger__c ObjError = New Error_Logger__c();
        ObjError.Class_Name__c = className;
        ObjError.Method_Name__c = methodName;
        ObjError.Exception_Type__c = expType;
        ObjError.Error_Message__c = expErrorMessage;
        ObjError.Line_Number__c = String.valueOf(lineNumber);
        ObjError.Parent_Id__c= ParentId; 
        ObjError.Is_CRM__c=IsCRM;
        return ObjError;
    }
}