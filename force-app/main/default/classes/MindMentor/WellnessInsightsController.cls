/**
 * @description Controller for managing wellness insights in LWC.
 * Uses with sharing to enforce record-level security and sharing rules.
 * Uses USER_MODE for all database operations to enforce CRUD, FLS, and sharing rules.
 */
public with sharing class WellnessInsightsController {
  /**
   * @description Retrieves wellness insights for the current user's latest completed session.
   * @return JSON string containing wellness insights or null if no completed sessions exist
   * @throws AuraHandledException if access is insufficient or another error occurs
   */
  @AuraEnabled(cacheable=false)
  public static String getLatestWellnessInsights() {
    try {
      // Get current user's Contact ID
      Id userId = UserInfo.getUserId();
      Id contactId = getContactId(userId);

      if (contactId == null) {
        Logger.info('User is not associated with a Contact record');
        return null;
      }

      Logger.info('Fetching wellness insights for Contact: ' + contactId);

      // Query latest completed session
      MM_Response_Session__c latestSession = getLatestCompletedSession(
        contactId
      );

      if (latestSession == null) {
        Logger.info('No completed sessions found for Contact: ' + contactId);
        return null;
      }

      Logger.info(
        'Found completed session: ' +
          latestSession.Id +
          ' with score: ' +
          latestSession.MM_Total_Score__c
      );

      // Get insights from service
      String insights = WellnessInsightsService.getWellnessInsights(
        latestSession.Id
      );

      Logger.info('Successfully retrieved wellness insights');
      return insights;
    } catch (Exception e) {
      Logger.error(
        'Error retrieving wellness insights: ' +
          e.getMessage() +
          '\nStack Trace: ' +
          e.getStackTraceString()
      );
      throw new AuraHandledException(
        'Unable to retrieve wellness insights: ' + e.getMessage()
      );
    } finally {
      Logger.saveLog();
    }
  }

  /**
   * @description Retrieves the Contact ID associated with the given User ID.
   * @param userId The Id of the user whose ContactId is to be retrieved
   * @return The ContactId of the user, or null if not associated with a contact
   */
  private static Id getContactId(Id userId) {
    Map<String, Object> bindVars = new Map<String, Object>{
      'userId' => userId
    };

    List<User> users = Database.queryWithBinds(
      'SELECT ContactId FROM User WHERE Id = :userId LIMIT 1',
      bindVars,
      AccessLevel.USER_MODE
    );

    return users.isEmpty() ? null : users[0].ContactId;
  }

  /**
   * @description Retrieves the latest completed MM_Response_Session__c for the given contact.
   * @param contactId The ContactId to query sessions for
   * @return The latest completed MM_Response_Session__c, or null if none found
   */
  private static MM_Response_Session__c getLatestCompletedSession(
    Id contactId
  ) {
    Map<String, Object> bindVars = new Map<String, Object>{
      'contactId' => contactId,
      'status' => 'Completed'
    };

    List<MM_Response_Session__c> sessions = Database.queryWithBinds(
      'SELECT Id, MM_Total_Score__c, MM_Summary__c, MM_End_Time__c ' +
        'FROM MM_Response_Session__c ' +
        'WHERE MM_User__c = :contactId AND MM_Status__c = :status ' +
        'ORDER BY MM_End_Time__c DESC, CreatedDate DESC ' +
        'LIMIT 1',
      bindVars,
      AccessLevel.USER_MODE
    );

    return sessions.isEmpty() ? null : sessions[0];
  }
}
