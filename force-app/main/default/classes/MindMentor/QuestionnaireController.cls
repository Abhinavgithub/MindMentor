/**
 * @description Controller for managing MindMentor questionnaire sessions and responses.
 */
public without sharing class QuestionnaireController {
    final static String IN_PROGRESS = 'In Progress';
    final static Integer MAX_QUESTIONS = 5;

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
    public static String createUserResponse(Id sessionId, Id questionId, Id answerId,String answerText){
        try {
            //add a SOQL query to check if the userResponse already exists for the given sessionId and questionId
            //if exists, then update the MM_Selected_Option__c on the existing record with new answerId
            //instead of inserting a new one
            CheckObjectReadAccess.checkUserResponseAccess();
            List<MM_User_Response__c> existingResponses = [SELECT Id FROM MM_User_Response__c WHERE MM_Response_Session__c = :sessionId AND MM_Question__c = :questionId];
            if(!existingResponses.isEmpty()){
                MM_User_Response__c existingResponse = existingResponses[0];
                existingResponse.MM_Selected_Option__c = answerId;
                CheckObjectUpdateAccess.checkUserResponseUpdateAccess();
                update existingResponse;
                return existingResponse.Id;
            }
            MM_User_Response__c userResponse = new MM_User_Response__c(
                MM_Response_Session__c = sessionId,
                MM_Question__c = questionId,
                MM_Selected_Option__c = answerId,
                MM_Answer_Text__c = answerText
            );
            CheckObjectCreateAccess.checkUserResponseCreateAccess();
            insert userResponse;
            return userResponse.Id;
        } catch (Exception e) {
            System.debug('Error creating user response: ' + e.getMessage());
            throw new AuraHandledException('Unable to create User Response: ' + e.getMessage());
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
    public static ResponseSessionDTO getSession(Id userId){
        try {
            CheckObjectReadAccess.checkUserAccess();
            String contactId = getContactId(userId);
            System.debug('Contact Id: ' + contactId);
            CheckObjectReadAccess.checkSessionAccess();
            MM_Response_Session__c respSession = getLatestInProgressSession(contactId);
            System.debug('Response Session: ' + respSession);
            return handleSession(respSession, contactId);
        } catch (Exception e) {
            System.debug('Error retrieving active session: ' + e.getMessage());
            throw new AuraHandledException('Unable to retrieve active Session: ' + e.getMessage());
        }
    }

    /**
     * @description Retrieves questions and their options from the Question object and MM_Question_Option__c,
     * and returns the question text and options as a JSON string.
     * @return A JSON string containing a list of questions and their options.
     * @throws AuraHandledException if access is insufficient or another error occurs.
     */
    @AuraEnabled(cacheable = false)
    public static string getQuestions(){
        try {
            CheckObjectReadAccess.checkQuestionAccess();
            CheckObjectReadAccess.checkQuestionOptionAccess();
            List<MM_Question__c> questions = [SELECT Id, MM_QuestionText__c, MM_Type__c, MM_Order__c, MM_Category__c, MM_Weight__c, MM_Section__c, MM_Crisis_Flag__c, MM_Immediate_Intervention__c, (SELECT Id, MM_Option_Text__c FROM Question_Options__r) FROM MM_Question__c ORDER BY MM_Order__c LIMIT 5];
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
            throw new AuraHandledException('Unable to retrieve Questions: ' + e.getMessage());
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
            // CRUD/FLS checks
            CheckObjectReadAccess.checkUserResponseAccess();

            // Guard
            if (sessionId == null) {
                return JSON.serialize(new Map<Id, Id>());
            }

            // Query existing responses for the session
            List<MM_User_Response__c> responses = [
                SELECT Id, MM_Question__c, MM_Selected_Option__c
                FROM MM_User_Response__c
                WHERE MM_Response_Session__c = :sessionId
            ];

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
            throw new AuraHandledException('Unable to retrieve Session Responses: ' + e.getMessage());
        }
    }

    /**
     * @description Retrieves the ContactId of the current user.
     * @param userId The Id of the user whose ContactId is to be retrieved.
     * @return The ContactId of the current user.
     */
    private static Id getContactId(Id userId) {
        // Query the User record to find the associated Contact ID
        CheckObjectReadAccess.checkUserAccess();
        User currentUser = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1];
        // Return the Contact ID
        // This will be null if the user is not associated with a contact
        return currentUser.ContactId;
    }

    /**
     * @description Retrieves the latest in-progress MM_Response_Session__c for the given contact Id.
     * @param contactId The ContactId to query sessions for.
     * @return The latest in-progress MM_Response_Session__c, or null if none found.
     */
    private static MM_Response_Session__c getLatestInProgressSession(String contactId) {
        CheckObjectReadAccess.checkSessionAccess();
        List<MM_Response_Session__c> sessions = [
            SELECT Id, MM_Status__c, MM_User__c
            FROM MM_Response_Session__c
            WHERE MM_User__c = :contactId AND MM_Status__c = :IN_PROGRESS
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return sessions.isEmpty() ? null : sessions[0];
    }

        /**
         * @description Handles the logic for an in-progress session: returns the session Id if not completed,
         * or marks the session as completed if the max number of questions is reached.
         * @param respSession The in-progress MM_Response_Session__c.
         * @param contactId The ContactId associated with the session.
         * @return The session Id if assessment is still in progress, otherwise null.
         */
        private static ResponseSessionDTO handleSession(MM_Response_Session__c respSession, String contactId) {
            if (respSession == null) {
                return handleNewSession(createResponseSession(contactId), null);
            }
            CheckObjectReadAccess.checkUserResponseAccess();
            List<MM_User_Response__c> userResponse = [
                SELECT Id, MM_Question__r.Id
                FROM MM_User_Response__c
                WHERE MM_Response_Session__c = :respSession.Id
                ORDER BY CreatedDate DESC
            ];

            if (userResponse.size() < MAX_QUESTIONS){
                return handleNewSession(respSession, userResponse);
            }

            respSession.MM_Status__c = 'Completed';
            CheckObjectUpdateAccess.checkResponseUpdateAccess();
            update respSession;

            return handleNewSession(createResponseSession(respSession.MM_User__c), null);
        }

    //Create new Response Session record
    private static MM_Response_Session__c createResponseSession(String contactId) {
        MM_Response_Session__c newSession = new MM_Response_Session__c(
            MM_User__c = contactId,
            MM_Status__c = IN_PROGRESS,
            MM_Start_Time__c = System.now()
        );
        CheckObjectCreateAccess.checkSessionCreateAccess();
        insert newSession;
        return newSession;
    }

    /**
     * @description Data Transfer Object for returning session details to the client.
     */
    public class ResponseSessionDTO{
        @AuraEnabled public String sessionId;
        @AuraEnabled public String answeredQuestionsCount;
        @AuraEnabled public String totalQuestionsCount;
        @AuraEnabled public String nextQuestionId;
        @AuraEnabled public String status;
    }

    private static ResponseSessionDTO handleNewSession(MM_Response_Session__c newSession, List<MM_User_Response__c> lastResponse) {
        ResponseSessionDTO dto = new ResponseSessionDTO();
        dto.sessionId = newSession.Id;
        dto.answeredQuestionsCount = (lastResponse != null && lastResponse.size() > 0) ? String.valueOf(lastResponse.size()) : '0';
        dto.totalQuestionsCount = String.valueOf(MAX_QUESTIONS);
        dto.nextQuestionId = (lastResponse != null && lastResponse.size() > 0) ? lastResponse[lastResponse.size() - 1].MM_Question__r.Id : null;
        dto.status = newSession.MM_Status__c;
        return dto;
    }
}
