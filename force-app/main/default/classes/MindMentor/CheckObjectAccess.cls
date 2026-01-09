/**
 * @description       : A utility class to check access for specific Salesforce objects.
 *                      This class provides static methods to verify if the current user has read access
 *                      to the User, MM_Response_Session__c, and MM_User_Response__c objects.
 *                      If access is insufficient, an AuraHandledException is thrown with a relevant message.
 * @author            : Abhinav Singh
 * @group             : MindMentor
 * @last modified on  : 01-09-2026
 * @last modified by  : Abhinav Singh
**/
public with sharing class CheckObjectAccess {
    /**
     * @description Checks if the current user has access to the User object.
     */
    public static void checkUserAccess() {
        if (!Schema.sObjectType.User.isAccessible() && !Schema.sObjectType.User.isCreateable() && !Schema.sObjectType.User.isUpdateable() && !Schema.sObjectType.User.isDeletable() && !Schema.sObjectType.User.isSearchable()) {
            throw new AuraHandledException('Insufficient access to User object.');
        }
    }

    /**
     * @description Checks if the current user has access to the MM_Response_Session__c object.
     */
    public static void checkSessionAccess() {
        if (!Schema.sObjectType.MM_Response_Session__c.isAccessible() && !Schema.sObjectType.MM_Response_Session__c.isCreateable() && !Schema.sObjectType.MM_Response_Session__c.isUpdateable() && !Schema.sObjectType.MM_Response_Session__c.isDeletable() && !Schema.sObjectType.MM_Response_Session__c.isSearchable()) {
            throw new AuraHandledException('Insufficient access to MM_Response_Session__c object.');
        }
    }

    /**
     * @description Checks if the current user has access to the MM_User_Response__c object.
     */
    public static void checkUserResponseAccess() {
        if (!Schema.sObjectType.MM_User_Response__c.isAccessible() && !Schema.sObjectType.MM_User_Response__c.isCreateable() && !Schema.sObjectType.MM_User_Response__c.isUpdateable() && !Schema.sObjectType.MM_User_Response__c.isDeletable() && !Schema.sObjectType.MM_User_Response__c.isSearchable()) {
            throw new AuraHandledException('Insufficient access to MM_User_Response__c object.');
        }
    }
    /**
     * @description Checks if the current user has access to the MM_Question__c object.
     */
    public static void checkQuestionAccess() {
        if (!Schema.sObjectType.MM_Question__c.isAccessible() && !Schema.sObjectType.MM_Question__c.isCreateable() && !Schema.sObjectType.MM_Question__c.isUpdateable() && !Schema.sObjectType.MM_Question__c.isDeletable() && !Schema.sObjectType.MM_Question__c.isSearchable()){
            throw new AuraHandledException('Insufficient access to MM_Question__c object.');
        }
    }

    /**
     * @description Checks if the current user has access to the MM_Question_Option__c object.
     */
    public static void checkQuestionOptionAccess() {
        if (!Schema.sObjectType.MM_Question_Option__c.isAccessible() && !Schema.sObjectType.MM_Question_Option__c.isCreateable() && !Schema.sObjectType.MM_Question_Option__c.isUpdateable() && !Schema.sObjectType.MM_Question_Option__c.isDeletable() && !Schema.sObjectType.MM_Question_Option__c.isSearchable() ){
            throw new AuraHandledException('Insufficient access to MM_Question_Option__c object.');
        }
    }

    /**
     * @description Checks if the current user has access to the MM_User_Response_Options__c object.
     */
    public static void checkUserResponseOptionsAccess() {
        if (!Schema.sObjectType.MM_User_Response_Options__c.isAccessible() && !Schema.sObjectType.MM_User_Response_Options__c.isCreateable() && !Schema.sObjectType.MM_User_Response_Options__c.isUpdateable() && !Schema.sObjectType.MM_User_Response_Options__c.isDeletable() && !Schema.sObjectType.MM_User_Response_Options__c.isSearchable() ){
            throw new AuraHandledException('Insufficient access to MM_User_Response_Options__c object.');
        }
    }
}