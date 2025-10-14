/**
 * @description       : A utility class to check read access for specific Salesforce objects.
 *                      This class provides static methods to verify if the current user has read access
 *                      to the User, MM_Response_Session__c, and MM_User_Response__c objects.
 *                      If access is insufficient, an AuraHandledException is thrown with a relevant message.
 * @name              : CheckObjectReadAccess
 * @author            : Abhinav Singh
 * @group             : MindMentor
 * @last modified on  : 10-11-2025
 * @last modified by  : Abhinav Singh
**/
public with sharing class CheckObjectReadAccess {
    /**
     * @description Checks if the current user has read access to the User object.
     */
    public static void checkUserAccess() {
        if (!Schema.sObjectType.User.isAccessible()) {
            throw new AuraHandledException('Insufficient access to User object.');
        }
    }

    /**
     * @description Checks if the current user has read access to the MM_Response_Session__c object.
     */
    public static void checkSessionAccess() {
        if (!Schema.sObjectType.MM_Response_Session__c.isAccessible()) {
            throw new AuraHandledException('Insufficient access to MM_Response_Session__c object.');
        }
    }

    /**
     * @description Checks if the current user has read access to the MM_User_Response__c object.
     */
    public static void checkUserResponseAccess() {
        if (!Schema.sObjectType.MM_User_Response__c.isAccessible()) {
            throw new AuraHandledException('Insufficient access to MM_User_Response__c object.');
        }
    }
}