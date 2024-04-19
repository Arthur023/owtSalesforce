/**
 * Created by arthurvandevelde on 14/04/2024.
 */

public with sharing class ErrorLog {
    public static Error_Log__c createErrorLog(String errorClass, String errorContext, Integer lineNumber,String errorType, String errorMessage){
        Error_Log__c newErrorLog = new Error_Log__c(
                Error_Class__c = errorClass,
                Error_Context__c = errorContext,
                Error_Line_Number__c = lineNumber,
                Error_Type__c = errorType,
                Error_Message__c = errorMessage
        );
        return newErrorLog;
    }
}