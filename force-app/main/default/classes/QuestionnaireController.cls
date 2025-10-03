/**
 * @description       : 
 * @author            : Abhinav Singh
 * @group             : 
 * @last modified on  : 09-17-2025
 * @last modified by  : Abhinav Singh
**/
public without sharing class QuestionnaireController {
    
    @AuraEnabled(cacheable=true)
    public static List<QuestionWrapper> getQuestions() {
        List<QuestionWrapper> questions = new List<QuestionWrapper>();
        
        try {
            System.debug('Starting getQuestions method');
            System.debug('Current user: ' + UserInfo.getUserName());
            System.debug('Current user profile: ' + UserInfo.getProfileId());
            System.debug('Running in system context: ' + UserInfo.getUserType());
            
            // First, let's check if there are any questions at all
            Integer totalQuestions = [SELECT COUNT() FROM MM_Question__c];
            System.debug('Total questions in database: ' + totalQuestions);
            
            if (totalQuestions == 0) {
                System.debug('No questions found in MM_Question__c object');
                return questions;
            }
            
            // Let's also check what fields exist
            List<MM_Question__c> simpleQuestions = [SELECT Id, Name FROM MM_Question__c LIMIT 5];
            System.debug('Sample questions with basic fields: ' + simpleQuestions);
            
            // Now try the full query
            List<MM_Question__c> questionRecords = [
                SELECT Id, MM_QuestionText__c, MM_Type__c, MM_Order__c,
                       (SELECT Id, MM_Option_Text__c, MM_Score_Value__c, MM_Order__c 
                        FROM Question_Options__r 
                        ORDER BY MM_Order__c ASC)
                FROM MM_Question__c 
                ORDER BY MM_Order__c ASC
                limit 3
            ];
            
            System.debug('Found ' + questionRecords.size() + ' questions with full query');
            
            for (MM_Question__c question : questionRecords) {
                System.debug('Processing question ID: ' + question.Id);
                System.debug('Question text: ' + question.MM_QuestionText__c);
                System.debug('Question type: ' + question.MM_Type__c);
                System.debug('Question order: ' + question.MM_Order__c);
                
                QuestionWrapper qw = new QuestionWrapper();
                qw.id = question.Id;
                qw.text = question.MM_QuestionText__c;
                qw.type = question.MM_Type__c;
                qw.order = question.MM_Order__c != null ? String.valueOf(question.MM_Order__c) : '0';
                qw.options = new List<OptionWrapper>();
                
                // Add options for this question
                if (question.Question_Options__r != null && question.Question_Options__r.size() > 0) {
                    System.debug('Found ' + question.Question_Options__r.size() + ' options for question: ' + question.MM_QuestionText__c);
                    for (MM_Question_Option__c option : question.Question_Options__r) {
                        OptionWrapper ow = new OptionWrapper();
                        ow.id = option.Id;
                        ow.text = option.MM_Option_Text__c;
                        ow.value = option.MM_Score_Value__c != null ? String.valueOf(option.MM_Score_Value__c) : '';
                        ow.order = option.MM_Order__c != null ? String.valueOf(option.MM_Order__c) : '0';
                        qw.options.add(ow);
                    }
                } else {
                    System.debug('No options found for question: ' + question.MM_QuestionText__c);
                    
                    // Create default options for Yes/No questions
                    if (question.MM_Type__c == 'Yes/No') {
                        OptionWrapper yesOption = new OptionWrapper();
                        yesOption.id = 'yes_' + question.Id;
                        yesOption.text = 'Yes';
                        yesOption.value = 'Yes';
                        yesOption.order = '1';
                        qw.options.add(yesOption);
                        
                        OptionWrapper noOption = new OptionWrapper();
                        noOption.id = 'no_' + question.Id;
                        noOption.text = 'No';
                        noOption.value = 'No';
                        noOption.order = '2';
                        qw.options.add(noOption);
                        
                        System.debug('Added default Yes/No options for question: ' + question.MM_QuestionText__c);
                    }
                }
                
                // Determine question type for template rendering
                qw.isMultipleChoice = question.MM_Type__c == 'Multiple Choice';
                qw.isMultipleSelect = question.MM_Type__c == 'Multiple Select';
                qw.isText = question.MM_Type__c == 'Text';
                qw.isScale = question.MM_Type__c == 'Scale';
                qw.isYesNo = question.MM_Type__c == 'Yes/No';
                
                questions.add(qw);
                System.debug('Added question to list: ' + qw.text);
            }
            
            System.debug('Returning ' + questions.size() + ' questions');
            
        } catch (Exception e) {
            System.debug('Error in getQuestions: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            System.debug('Error stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error fetching questions: ' + e.getMessage());
        }
        
        return questions;
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean hasCompletedQuestionnaire(String contactId) {
        try {
            Contact contact = [
                SELECT MM_Last_Questionnaire_Attemped__c 
                FROM Contact 
                WHERE Id = :contactId 
                LIMIT 1
            ];
            return contact.MM_Last_Questionnaire_Attemped__c != null;
        } catch (Exception e) {
            throw new AuraHandledException('Error checking questionnaire status: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String submitQuestionnaire(String contactId, Map<String, String> answers) {
        try {
            // Create a new response session
            MM_Response_Session__c session = new MM_Response_Session__c(
                MM_User__c = contactId,
                MM_Start_Time__c = Datetime.now()
            );
            insert session;
            
            // Create user responses for each question
            List<MM_User_Response__c> userResponses = new List<MM_User_Response__c>();
            
            for (String questionId : answers.keySet()) {
                String answer = answers.get(questionId);
                
                MM_User_Response__c response = new MM_User_Response__c(
                    MM_Response_Session__c = session.Id,
                    MM_Question__c = questionId
                );
                
                // Determine if it's a text answer or option selection based on question type
                MM_Question__c question = [SELECT MM_Type__c FROM MM_Question__c WHERE Id = :questionId LIMIT 1];
                
                if (question.MM_Type__c == 'Text') {
                    response.MM_Answer_Text__c = answer;
                } else {
                    // For Multiple Choice and Scale questions, store the selected option
                    response.MM_Selected_Option__c = answer;
                }
                
                userResponses.add(response);
            }
            
            if (!userResponses.isEmpty()) {
                insert userResponses;
            }
            
            // Update the contact's last questionnaire attempted date
            Contact contact = new Contact(
                Id = contactId,
                MM_Last_Questionnaire_Attemped__c = Datetime.now()
            );
            update contact;
            return session.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error submitting questionnaire: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<SessionWrapper> getPreviousSessions(String contactId) {
        List<SessionWrapper> sessions = new List<SessionWrapper>();
        
        try {
            List<MM_Response_Session__c> sessionRecords = [
                SELECT Id, CreatedDate, LastModifiedDate,
                       (SELECT Id, MM_Question__c, MM_Answer_Text__c, MM_Selected_Option__c 
                        FROM User_Responses__r)
                FROM MM_Response_Session__c 
                WHERE MM_User__c = :contactId 
                ORDER BY CreatedDate DESC
            ];
            
            for (MM_Response_Session__c session : sessionRecords) {
                SessionWrapper sw = new SessionWrapper();
                sw.id = session.Id;
                sw.startTime = session.CreatedDate;
                sw.endTime = session.LastModifiedDate;
                sw.status = 'Completed';
                sw.responseCount = session.User_Responses__r != null ? session.User_Responses__r.size() : 0;
                sessions.add(sw);
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching previous sessions: ' + e.getMessage());
        }
        
        return sessions;
    }
    
    @AuraEnabled(cacheable=true)
    public static String testAccess() {
        try {
            Integer count = [SELECT COUNT() FROM MM_Question__c];
            return 'Success! Found ' + count + ' questions. User: ' + UserInfo.getUserName();
        } catch (Exception e) {
            return 'Error: ' + e.getMessage() + ' at line ' + e.getLineNumber();
        }
    }
    
    // Wrapper classes for data transfer
    public class QuestionWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String text;
        @AuraEnabled public String type;
        @AuraEnabled public String order;
        @AuraEnabled public List<OptionWrapper> options;
        @AuraEnabled public Boolean isMultipleChoice;
        @AuraEnabled public Boolean isMultipleSelect;
        @AuraEnabled public Boolean isText;
        @AuraEnabled public Boolean isScale;
        @AuraEnabled public Boolean isYesNo;
    }
    
    public class OptionWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String text;
        @AuraEnabled public String value;
        @AuraEnabled public String order;
    }
    
    public class SessionWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public Datetime startTime;
        @AuraEnabled public Datetime endTime;
        @AuraEnabled public String status;
        @AuraEnabled public Integer responseCount;
    }
}