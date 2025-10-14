/**
 * @description       : A utility class to check update access for specific Salesforce objects.
 *                      This class provides static methods to verify if the current user has update access
 *                      to the MM_Response_Session__c object.
 *                      If access is insufficient, an AuraHandledException is thrown with a relevant message.
 * @name              : CheckObjectUpdateAccess
 * @author            : Abhinav Singh
 * @group             : MindMentor
 * @last modified on  : 10-11-2025
 * @last modified by  : Abhinav Singh
**/
public with sharing class CheckObjectUpdateAccess {
    /**
     * @description Checks if the current user has update access to the MM_Response_Session__c object.
     *              Throws an AuraHandledException if access is insufficient.
     */
    public static void checkResponseUpdateAccess() {
        if (!Schema.sObjectType.MM_Response_Session__c.isUpdateable()) {
            throw new AuraHandledException('Insufficient access to update MM_Response_Session__c object.');
        }
    }
}