/**
 * @description Controller for managing MindMentor questionnaire sessions and responses.
 */
public without sharing class QuestionnaireController {
    final static STRING IN_PROGRESS = 'In Progress';
    final static STRING MAX_QUESTIONS = '5';

    /**
     * @description Starts the assessment and returns the session Id if the assessment is in progress and not completed.
     * Checks user and session object access, retrieves the current user's contact Id, finds the latest in-progress session,
     * and determines if the session should continue or be marked as completed.
     * @return The Id of the in-progress MM_Response_Session__c if available and not completed, otherwise null.
     * @throws AuraHandledException if access is insufficient or another error occurs.
     */
    @AuraEnabled(cacheable=false)
    public static ResponseSessionDTO startAssessment(){
        try {
            CheckObjectReadAccess.checkUserAccess();
            String contactId = getContactId();
            CheckObjectReadAccess.checkSessionAccess();
            MM_Response_Session__c respSession = getLatestInProgressSession(contactId);
            return handleSession(respSession);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Retrieves the ContactId of the current user.
     * @return The ContactId of the current user.
     */
    private static String getContactId() {
        CheckObjectReadAccess.checkUserAccess();
        return [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
    }

    /**
     * @description Retrieves the latest in-progress MM_Response_Session__c for the given contact Id.
     * @param contactId The ContactId to query sessions for.
     * @return The latest in-progress MM_Response_Session__c, or null if none found.
     */
    private static MM_Response_Session__c getLatestInProgressSession(String contactId) {
        CheckObjectReadAccess.checkSessionAccess();
        List<MM_Response_Session__c> sessions = [
            SELECT Id, MM_Status__c
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
     * @return The session Id if assessment is still in progress, otherwise null.
     */
    private static ResponseSessionDTO handleSession(MM_Response_Session__c respSession) {
        if (respSession == null) {
            return null;
        }
        CheckObjectReadAccess.checkUserResponseAccess();
        List<MM_User_Response__c> userResponse = [
            SELECT Id FROM MM_User_Response__c
            WHERE MM_Response_Session__c = :respSession.Id
            ORDER BY CreatedDate DESC
        ];
        Integer maxQuestions = Integer.valueOf(MAX_QUESTIONS);
        if (userResponse.isEmpty()) {
            return handleNewSession(createResponseSession(respSession.MM_User__c), null);
        }

        if (userResponse.size() < maxQuestions){
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
    public Class ResponseSessionDTO{
        public String sessionId;
        public String answeredQuestionsCount;
        public String totalQuestionsCount;
        public String nextQuestionId;
        public String status;
    }

    private static ResponseSessionDTO handleNewSession(MM_Response_Session__c newSession, List<MM_User_Response__c> lastResponse) {
        ResponseSessionDTO dto = new ResponseSessionDTO();
        dto.sessionId = newSession.Id;
        dto.answeredQuestionsCount = '0';
        dto.totalQuestionsCount = MAX_QUESTIONS;
        dto.nextQuestionId = (lastResponse!=null && lastResponse.size()>0) ? lastResponse[lastResponse.size() - 1].MM_Question__r.Id : null;
        dto.status = newSession.MM_Status__c;
        return dto;
    }
}