/**
 * @description       : A utility class to check create access for specific Salesforce objects.
 *                      This class provides static methods to verify if the current user has create access
 *                      to the MM_Response_Session__c object.
 *                      If access is insufficient, an AuraHandledException is thrown with a relevant message.
 * @name              : CheckObjectCreateAccess
 * @author            : Abhinav Singh
 * @group             : MindMentor
 * @last modified on  : 12-11-2025
 * @last modified by  : Abhinav Singh
**/
public with sharing class CheckObjectCreateAccess {
    /**
     * @description Checks if the current user has create access to the MM_Response_Session__c object.
     *              Throws an AuraHandledException if access is insufficient.
     */
    public static void checkSessionCreateAccess() {
        if (!Schema.sObjectType.MM_Response_Session__c.isCreateable()) {
                    throw new AuraHandledException('Insufficient access to create MM_Response_Session__c object.');
                }
    }

    /**
     * @description Checks if the current user has create access to the MM_User_Response__c object.
     *              Throws an AuraHandledException if access is insufficient.
     */
    public static void checkUserResponseCreateAccess() {
        if (!Schema.sObjectType.MM_User_Response__c.isCreateable()) {
                    throw new AuraHandledException('Insufficient access to create MM_User_Response__c object.');
                }
    }

    /**
     * @description Checks if the current user has create access to the MM_User_Response_Options__c object.
     *              Throws an AuraHandledException if access is insufficient.
     */
    public static void checkUserResponseOptionsCreateAccess() {
        if (!Schema.sObjectType.MM_User_Response_Options__c.isCreateable()) {
                    throw new AuraHandledException('Insufficient access to create MM_User_Response_Options__c object.');
                }
    }
}