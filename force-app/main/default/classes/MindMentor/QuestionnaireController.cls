/**
 * @description Controller for managing MindMentor questionnaire sessions and responses.
 * Uses USER_MODE for all database operations to enforce CRUD, FLS, and sharing rules.
 */
public with sharing class QuestionnaireController {
  final static String IN_PROGRESS = 'In Progress';
  final static String COMPLETED = 'Completed';
  final static Integer MAX_QUESTIONS = Integer.valueOf(
    System.Label.MM_Max_Questions
  );

  /**
   * @description creates a new MM_User_Response_Options__c records with the provided details.
   * @param sessionId The Id of the MM_Response_Session__c.
   * @param questionId The Id of the MM_Question__c.
   * @param answerId The Id of the MM_Answer_Option__c.
   * @return The Ids of the MM_User_Response_Options__c record created.
   * @throws AuraHandledException if access is insufficient or another error occurs.
   */
  @AuraEnabled(cacheable=false)
  public static string createUserResponseforMultiSelect(
    String sessionId,
    String questionId,
    String answerId
  ) {
    try {
      String userResponseOptionIds = '';
      List<MM_User_Response_Options__c> userResponseOptionsList = new List<MM_User_Response_Options__c>();

      // Query existing responses with USER_MODE
      Map<String, Object> bindVars = new Map<String, Object>{
        'sessionId' => sessionId,
        'questionId' => questionId
      };
      List<MM_User_Response_Options__c> existingResponses = Database.queryWithBinds(
        'SELECT Id FROM MM_User_Response_Options__c WHERE MM_Response_Session__c = :sessionId AND MM_Question__c = :questionId',
        bindVars,
        AccessLevel.USER_MODE
      );

      try {
        if (!existingResponses.isEmpty()) {
          // Delete existing responses with USER_MODE
          System.debug(
            'Deleting existing responses: ' + existingResponses.size()
          );
          Database.delete(existingResponses, AccessLevel.USER_MODE);
        }
      } catch (Exception e) {
        System.debug('Error deleting existing responses: ' + e.getMessage());
        throw new AuraHandledException(
          'Unable to delete existing responses: ' + e.getMessage()
        );
      }

      // Insert new responses for the multi-select question
      List<String> answerIds = answerId.split(',');

      for (String ansId : answerIds) {
        MM_User_Response_Options__c userResponseOption = new MM_User_Response_Options__c(
          MM_Response_Session__c = sessionId,
          MM_Question__c = questionId,
          MM_Question_Option__c = isValidSalesforceId(ansId) ? (Id) ansId : null
        );
        userResponseOptionsList.add(userResponseOption);
      }

      // Insert with USER_MODE
      Database.insert(userResponseOptionsList, AccessLevel.USER_MODE);

      for (MM_User_Response_Options__c uro : userResponseOptionsList) {
        System.debug('Inserted User Response Option Id: ' + uro.Id);
        userResponseOptionIds += uro.Id + ',';
      }
      return userResponseOptionIds;
    } catch (Exception e) {
      System.debug(
        'Error creating Multiple Select user response: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Unable to create Multiple Select User Response ' + e.getMessage()
      );
    }
  }

  /**
   * @description creates a new MM_User_Response__c record with the provided details.
   * @param sessionId The Id of the MM_Response_Session__c.
   * @param questionId The Id of the MM_Question__c.
   * @param answerId The Id of the MM_Answer_Option__c.
   * @param answerText The text answer provided by the user.
   * @return The Id of the MM_User_Response__c record created.
   * @throws AuraHandledException if access is insufficient or another error occurs.
   */
  @AuraEnabled(cacheable=false)
  public static String createUserResponse(
    Id sessionId,
    Id questionId,
    String answerId,
    String answerText,
    String questionType
  ) {
    try {
      if (questionType == 'Multiple Select') {
        return createUserResponseforMultiSelect(
          sessionId,
          questionId,
          answerId
        );
      }

      // Query existing responses with USER_MODE
      Map<String, Object> bindVars = new Map<String, Object>{
        'sessionId' => sessionId,
        'questionId' => questionId
      };
      List<MM_User_Response__c> existingResponses = Database.queryWithBinds(
        'SELECT Id FROM MM_User_Response__c WHERE MM_Response_Session__c = :sessionId AND MM_Question__c = :questionId',
        bindVars,
        AccessLevel.USER_MODE
      );

      if (!existingResponses.isEmpty()) {
        MM_User_Response__c existingResponse = existingResponses[0];
        existingResponse.MM_Selected_Option__c = isValidSalesforceId(answerId)
          ? (Id) answerId
          : null;
        existingResponse.MM_Answer_Text__c = isValidSalesforceId(answerId)
          ? null
          : (String) answerId;

        // Update with USER_MODE
        Database.update(existingResponse, AccessLevel.USER_MODE);
        return existingResponse.Id;
      }

      MM_User_Response__c userResponse = new MM_User_Response__c(
        MM_Response_Session__c = sessionId,
        MM_Question__c = questionId,
        MM_Selected_Option__c = isValidSalesforceId(answerId)
          ? (Id) answerId
          : null,
        MM_Answer_Text__c = isValidSalesforceId(answerId)
          ? null
          : (String) answerId
      );

      // Insert with USER_MODE
      Database.insert(userResponse, AccessLevel.USER_MODE);
      return userResponse.Id;
    } catch (Exception e) {
      System.debug('Error creating user response: ' + e.getMessage());
      throw new AuraHandledException(
        'Unable to create User Response: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Starts the assessment and returns the session Id if the assessment is in progress and not completed.
   * Checks user and session object access, retrieves the current user's contact Id, finds the latest in-progress session,
   * and determines if the session should continue or be marked as completed.
   * @return The Id of the in-progress MM_Response_Session__c if available and not completed, otherwise null.
   * @throws AuraHandledException if access is insufficient or another error occurs.
   */
  @AuraEnabled(cacheable=false)
  public static ResponseSessionDTO getSession(Id userId) {
    try {
      String contactId = getContactId(userId);
      System.debug('Contact Id: ' + contactId);
      MM_Response_Session__c respSession = getLatestInProgressSession(
        contactId
      );
      System.debug('Response Session: ' + respSession);
      return handleSession(respSession, contactId);
    } catch (Exception e) {
      System.debug('Error retrieving active session: ' + e.getMessage());
      throw new AuraHandledException(
        'Unable to retrieve active Session: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Retrieves questions and their options from the Question object and MM_Question_Option__c,
   * and returns the question text and options as a JSON string.
   * @return A JSON string containing a list of questions and their options.
   * @throws AuraHandledException if access is insufficient or another error occurs.
   */
  @AuraEnabled(cacheable=false)
  public static string getQuestions() {
    try {
      //Get Questions from active questionnaires
      // Query questions with USER_MODE
      List<MM_Question__c> questions = Database.query(
        'SELECT Id, MM_QuestionText__c, MM_Type__c, MM_Order__c, MM_Category__c, MM_Weight__c, MM_Section__c, MM_Crisis_Flag__c, MM_Immediate_Intervention__c, ' +
          '       (SELECT Id, MM_Option_Text__c FROM Question_Options__r) ' +
          'FROM MM_Question__c ' +
          'WHERE MM_Questionnaire__r.MM_Is_Active__c = true ' +
          'ORDER BY MM_Order__c ' +
          'LIMIT :MAX_QUESTIONS',
        AccessLevel.USER_MODE
      );

      List<Map<String, Object>> questionList = new List<Map<String, Object>>();
      for (MM_Question__c q : questions) {
        Map<String, Object> questionMap = new Map<String, Object>();
        questionMap.put('Id', q.Id);
        questionMap.put('QuestionText', q.MM_QuestionText__c);
        questionMap.put('Type', q.MM_Type__c);
        questionMap.put('Order', q.MM_Order__c);
        List<Map<String, String>> optionsList = new List<Map<String, String>>();
        for (MM_Question_Option__c opt : q.Question_Options__r) {
          Map<String, String> optionMap = new Map<String, String>();
          optionMap.put('Id', opt.Id);
          optionMap.put('OptionText', opt.MM_Option_Text__c);
          optionsList.add(optionMap);
        }
        questionMap.put('Options', optionsList);
        questionList.add(questionMap);
      }
      return JSON.serialize(questionList);
    } catch (Exception e) {
      System.debug('Error retrieving questions: ' + e.getMessage());
      throw new AuraHandledException(
        'Unable to retrieve Questions: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Bulk fetch of existing user responses for a given session.
   * Returns a JSON string of a map: { questionId -> selectedOptionId }.
   * @param sessionId The Id of the MM_Response_Session__c.
   */
  @AuraEnabled(cacheable=true)
  public static String getSessionResponses(Id sessionId) {
    try {
      // Guard
      if (sessionId == null) {
        return JSON.serialize(new Map<Id, Id>());
      }

      // Query existing responses with USER_MODE
      Map<String, Object> bindVars = new Map<String, Object>{
        'sessionId' => sessionId
      };
      List<MM_User_Response__c> responses = Database.queryWithBinds(
        'SELECT Id, MM_Question__c, MM_Selected_Option__c FROM MM_User_Response__c WHERE MM_Response_Session__c = :sessionId',
        bindVars,
        AccessLevel.USER_MODE
      );

      // Build map QuestionId -> SelectedOptionId
      Map<Id, Id> result = new Map<Id, Id>();
      for (MM_User_Response__c r : responses) {
        if (r.MM_Question__c != null) {
          result.put(r.MM_Question__c, r.MM_Selected_Option__c);
        }
      }
      return JSON.serialize(result);
    } catch (Exception e) {
      System.debug('Error retrieving session responses: ' + e.getMessage());
      throw new AuraHandledException(
        'Unable to retrieve Session Responses: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Retrieves the ContactId of the current user.
   * @param userId The Id of the user whose ContactId is to be retrieved.
   * @return The ContactId of the current user.
   */
  private static Id getContactId(Id userId) {
    // Query the User record with USER_MODE
    Map<String, Object> bindVars = new Map<String, Object>{
      'userId' => userId
    };
    List<User> users = Database.queryWithBinds(
      'SELECT ContactId FROM User WHERE Id = :userId LIMIT 1',
      bindVars,
      AccessLevel.USER_MODE
    );
    // Return the Contact ID (null if user is not associated with a contact)
    return users.isEmpty() ? null : users[0].ContactId;
  }

  /**
   * @description Retrieves the latest in-progress MM_Response_Session__c for the given contact Id.
   * @param contactId The ContactId to query sessions for.
   * @return The latest in-progress MM_Response_Session__c, or null if none found.
   */
  private static MM_Response_Session__c getLatestInProgressSession(
    String contactId
  ) {
    Map<String, Object> bindVars = new Map<String, Object>{
      'contactId' => contactId,
      'status' => IN_PROGRESS
    };
    List<MM_Response_Session__c> sessions = Database.queryWithBinds(
      'SELECT Id, MM_Status__c, MM_User__c FROM MM_Response_Session__c WHERE MM_User__c = :contactId AND MM_Status__c = :status ORDER BY CreatedDate DESC LIMIT 1',
      bindVars,
      AccessLevel.USER_MODE
    );
    return sessions.isEmpty() ? null : sessions[0];
  }

  /**
   * @description Handles the logic for an in-progress session: returns the session Id if not completed,
   * or marks the session as completed if the max number of questions is reached.
   * @param respSession The in-progress MM_Response_Session__c.
   * @param contactId The ContactId associated with the session.
   * @return The session Id if assessment is still in progress, otherwise null.
   */
  private static ResponseSessionDTO handleSession(
    MM_Response_Session__c respSession,
    String contactId
  ) {
    if (respSession == null) {
      return handleNewSession(createResponseSession(contactId), null);
    }

    // Query user responses with USER_MODE
    Map<String, Object> bindVars = new Map<String, Object>{
      'sessionId' => respSession.Id
    };
    List<MM_User_Response__c> userResponse = Database.queryWithBinds(
      'SELECT Id, MM_Question__r.Id FROM MM_User_Response__c WHERE MM_Response_Session__c = :sessionId ORDER BY CreatedDate DESC',
      bindVars,
      AccessLevel.USER_MODE
    );

    if (userResponse.size() < MAX_QUESTIONS) {
      return handleNewSession(respSession, userResponse);
    }

    respSession.MM_Status__c = COMPLETED;
    respSession.MM_End_Time__c = System.now();

    // Update with USER_MODE
    Database.update(respSession, AccessLevel.USER_MODE);

    return handleNewSession(
      createResponseSession(respSession.MM_User__c),
      null
    );
  }

  // Create new Response Session record
  private static MM_Response_Session__c createResponseSession(
    String contactId
  ) {
    MM_Response_Session__c newSession = new MM_Response_Session__c(
      MM_User__c = contactId,
      MM_Status__c = IN_PROGRESS,
      MM_Start_Time__c = System.now()
    );

    // Insert with USER_MODE
    Database.insert(newSession, AccessLevel.USER_MODE);
    return newSession;
  }

  public static Boolean isValidSalesforceId(String possibleId) {
    // 1. Basic Length Check (Optional, but good for quick exit)
    if (
      possibleId == null ||
      (possibleId.length() != 15 &&
      possibleId.length() != 18)
    ) {
      return false;
    }

    // 2. Try-Catch for Full Validation
    try {
      // Attempt to assign the String to an Id variable.
      // Apex will throw a System.StringException if the format is invalid.
      Id recordId = possibleId;
      // If the assignment succeeds, it's a valid ID format.
      return true;
    } catch (System.StringException e) {
      // Catches the exception thrown for an invalid Id format.
      return false;
    }
  }

  /**
   * @description Data Transfer Object for returning session details to the client.
   */
  public class ResponseSessionDTO {
    @AuraEnabled
    public String sessionId;
    @AuraEnabled
    public String answeredQuestionsCount;
    @AuraEnabled
    public String totalQuestionsCount;
    @AuraEnabled
    public String nextQuestionId;
    @AuraEnabled
    public String status;
  }

  private static ResponseSessionDTO handleNewSession(
    MM_Response_Session__c newSession,
    List<MM_User_Response__c> lastResponse
  ) {
    ResponseSessionDTO dto = new ResponseSessionDTO();
    dto.sessionId = newSession.Id;
    dto.answeredQuestionsCount = (lastResponse != null &&
      lastResponse.size() > 0)
      ? String.valueOf(lastResponse.size())
      : '0';
    dto.totalQuestionsCount = String.valueOf(MAX_QUESTIONS);
    dto.nextQuestionId = (lastResponse != null &&
      lastResponse.size() > 0)
      ? lastResponse[lastResponse.size() - 1].MM_Question__r.Id
      : null;
    dto.status = newSession.MM_Status__c;
    return dto;
  }

  /**
   * @description Completes a response session by setting status to 'Completed' and MM_End_Time__c to now.
   * @param sessionId The Id of the MM_Response_Session__c to complete.
   * @return The Id of the completed session.
   * @throws AuraHandledException if access is insufficient or another error occurs.
   */
  @AuraEnabled
  public static Id completeSession(Id sessionId) {
    try {
      if (sessionId == null) {
        throw new AuraHandledException('Session Id is required.');
      }

      // Query session with USER_MODE
      Map<String, Object> bindVars = new Map<String, Object>{
        'sessionId' => sessionId
      };
      List<MM_Response_Session__c> sessions = Database.queryWithBinds(
        'SELECT Id, MM_Status__c FROM MM_Response_Session__c WHERE Id = :sessionId LIMIT 1',
        bindVars,
        AccessLevel.USER_MODE
      );

      if (sessions.isEmpty()) {
        throw new AuraHandledException('Session not found.');
      }

      MM_Response_Session__c sess = sessions[0];

      // Idempotent completion
      if (sess.MM_Status__c != COMPLETED) {
        sess.MM_Status__c = COMPLETED;
        sess.MM_End_Time__c = System.now();

        // Update with USER_MODE
        Database.update(sess, AccessLevel.USER_MODE);
      }
      return sess.Id;
    } catch (Exception e) {
      System.debug('Error completing session: ' + e.getMessage());
      throw new AuraHandledException(
        'Unable to complete Session: ' + e.getMessage()
      );
    }
  }
}