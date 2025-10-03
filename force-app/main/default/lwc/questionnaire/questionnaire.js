import { LightningElement, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USER_CONTACT_ID from '@salesforce/schema/User.ContactId';
import getQuestions from '@salesforce/apex/QuestionnaireController.getQuestions';
import hasCompletedQuestionnaire from '@salesforce/apex/QuestionnaireController.hasCompletedQuestionnaire';
import submitQuestionnaire from '@salesforce/apex/QuestionnaireController.submitQuestionnaire';
import getPreviousSessions from '@salesforce/apex/QuestionnaireController.getPreviousSessions';

export default class Questionnaire extends LightningElement {
    @track currentQuestionIndex = 0;
    @track answers = {};
    @track showQuestionnaire = false;
    @track questions = [];
    @track loading = true;
    @track error;
    @track questionnaireCompleted = false;
    @track previousSessions = [];
    @track showPreviousSessions = false;
    contactId;

    // Wire the User record to get ContactId
    @wire(getRecord, { 
        recordId: USER_ID, 
        fields: [USER_CONTACT_ID] 
    })
    userRecord;

    get shouldShowStartButton() {
        console.log('shouldShowStartButton called:', {
            showQuestionnaire: this.showQuestionnaire,
            showPreviousSessions: this.showPreviousSessions
        });
        return !this.showQuestionnaire && !this.showPreviousSessions;
    }

    get currentQuestionIndexPlusOne() {
        return this.currentQuestionIndex + 1;
    }

    get currentQuestion() {
        console.log('currentQuestion called:', {
            questionsLength: this.questions.length,
            currentQuestionIndex: this.currentQuestionIndex
        });
        
        if (this.questions.length > 0 && this.currentQuestionIndex < this.questions.length) {
            const question = this.questions[this.currentQuestionIndex];
            console.log('Returning current question:', question);
            return question;
        }
        console.log('No current question found');
        return null;
    }

    get isLastQuestion() {
        return this.currentQuestionIndex === this.questions.length - 1;
    }

    get progressPercentage() {
        if (this.questions.length === 0) return 0;
        return ((this.currentQuestionIndex + 1) / this.questions.length) * 100;
    }

    get progressBarStyle() {
        return `width: ${this.progressPercentage}%`;
    }

    // Get the current question id
    get currentQuestionId() {
      return this.currentQuestion ? this.currentQuestion.id : null;
    }

    // Get saved answer (null means nothing selected → no default)
    get currentAnswer() {
      const qid = this.currentQuestionId;
      if (!qid) return null;
      const ans = this.answers[qid];
      
      console.log('currentAnswer getter called:', {
        questionId: qid,
        answer: ans,
        answerType: typeof ans,
        isArray: Array.isArray(ans)
      });
      
      // For single-select components, return the string value
      if (Array.isArray(ans)) {
        return ans.length > 0 ? ans[0] : null; // Return first value for single-select
      }
      return ans ?? null;
    }

    // For multi-select groups (expects an array)
    get currentAnswerArray() {
      const qid = this.currentQuestionId;
      if (!qid) return [];
      const ans = this.answers[qid];
      return Array.isArray(ans) ? ans : [];
    }

    // Map current question options to radio/checkbox group format
    get currentOptions() {
      const q = this.currentQuestion;
      if (!q || !q.options) return [];
      return q.options.map(o => ({ label: o.text, value: o.value }));
    }

    // Yes/No fallback if options not provided by Apex
    get yesNoOptions() {
      const q = this.currentQuestion;
      if (q && q.options && q.options.length) {
        return q.options.map(o => ({ label: o.text, value: o.value }));
      }
      return [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
      ];
    }

    // Single handler for radio-group and checkbox-group
    handleGroupChange(event) {
      const qid = this.currentQuestionId;
      if (!qid) return;
      
      console.log('handleGroupChange called:', {
        questionId: qid,
        questionText: this.currentQuestion?.text,
        value: event.detail.value,
        valueType: typeof event.detail.value
      });
      
      // For radio-group: detail.value is a string
      // For checkbox-group: detail.value is an array
      this.answers[qid] = event.detail.value;
      
      console.log('Updated answers object:', this.answers);
      
      if (this.error) this.clearError();
    }

    connectedCallback() {
        console.log('Questionnaire component connected');
        this.loadQuestions();
    }

    renderedCallback() {
        // Set contactId when user record is loaded
        if (this.userRecord.data && !this.contactId) {
            this.contactId = getFieldValue(this.userRecord.data, USER_CONTACT_ID);
            console.log('Contact ID set:', this.contactId);
            this.loadPreviousSessions();
        }
    }

    async loadQuestions() {
        console.log('loadQuestions called');
        try {
            this.loading = true;
            console.log('Calling getQuestions Apex method...');
            
            this.questions = await getQuestions();
            console.log('Questions loaded from Apex:', this.questions);
            console.log('Questions array length:', this.questions.length);
            console.log('First question details:', this.questions[0]);
            
            if (!this.questions || this.questions.length === 0) {
                console.warn('No questions returned from Apex');
                this.error = 'No questions found. Please contact your administrator.';
                this.loading = false;
                return;
            }
            
            // Add question type flags for template rendering
            this.questions = this.questions.map(question => {
                const mappedQuestion = {
                    ...question,
                    isMultipleChoice: question.type === 'Multiple Choice',
                    isMultipleSelect: question.type === 'Multiple Select',
                    isText: question.type === 'Text',
                    isScale: question.type === 'Scale',
                    isYesNo: question.type === 'Yes/No'
                };
                console.log('Mapped question:', mappedQuestion);
                return mappedQuestion;
            });
            
            console.log('Final questions array:', this.questions);
            console.log('Final questions array length:', this.questions.length);
            this.loading = false;
        } catch (error) {
            console.error('Error loading questions:', error);
            this.error = error.body?.message || error.message || 'Failed to load questions';
            this.loading = false;
        }
    }

    async loadPreviousSessions() {
        if (this.contactId) {
            try {
                console.log('Loading previous sessions for contact:', this.contactId);
                this.previousSessions = await getPreviousSessions({ contactId: this.contactId });
                console.log('Previous sessions loaded:', this.previousSessions);
            } catch (error) {
                console.error('Error loading previous sessions:', error);
            }
        }
    }

    handleStartQuestionnaire() {
        console.log('Start Assessment button clicked');
        console.log('Current state before starting:', {
            questions: this.questions,
            questionsLength: this.questions.length,
            loading: this.loading,
            error: this.error,
            showQuestionnaire: this.showQuestionnaire
        });
        
        this.showQuestionnaire = true;
        this.currentQuestionIndex = 0;
        this.answers = {}; // Reset answers for new session
        
        console.log('State after starting questionnaire:', {
            showQuestionnaire: this.showQuestionnaire,
            currentQuestionIndex: this.currentQuestionIndex,
            answers: this.answers,
            questionsLength: this.questions.length
        });
        
        // Force a re-render
        this.template.querySelector('.questionnaire-container')?.classList.add('force-update');
    }

    handleViewPreviousSessions() {
        console.log('View Previous Sessions button clicked');
        this.showPreviousSessions = true;
    }

    handleBackToHome() {
        console.log('Back to Home button clicked');
        this.showQuestionnaire = false;
        this.showPreviousSessions = false;
        this.currentQuestionIndex = 0;
        this.answers = {};
    }

    // Fix the getter to return the actual answer value, not the function
    get getCurrentAnswer() {
        const questionId = this.currentQuestion?.id;
        if (!questionId) return '';
        
        const answer = this.answers[questionId];
        if (Array.isArray(answer)) {
            return answer.join(', ');
        }
        return answer || '';
    }

    // Add a computed property to check if there's a previous answer
    get hasPreviousAnswer() {
        const questionId = this.currentQuestion?.id;
        if (!questionId) return false;
        
        const answer = this.answers[questionId];
        return answer && (Array.isArray(answer) ? answer.length > 0 : answer.trim() !== '');
    }

    // (Deprecated helpers removed) Selection state is now managed by group components via value binding

    handleAnswerChange(event) {
        // Handles non-group inputs (text/slider). Checkbox/Radio are managed by handleGroupChange.
        const questionId = this.currentQuestion?.id;
        if (!questionId) return;
        const answer = event.target.value;
        this.answers[questionId] = answer;
        if (this.error) this.clearError();
        console.log('Updated answers (text/scale):', { questionId, answer, answers: this.answers });
    }

    handleNext() {
        console.log('Next button clicked, current index:', this.currentQuestionIndex);
        
        // Validate current question before proceeding
        if (!this.validateCurrentQuestion()) {
            return;
        }
        
        if (this.currentQuestionIndex < this.questions.length - 1) {
            this.currentQuestionIndex++;
            console.log('Moved to next question, new index:', this.currentQuestionIndex);
        }
    }

    handlePrevious() {
        console.log('Previous button clicked, current index:', this.currentQuestionIndex);
        if (this.currentQuestionIndex > 0) {
            this.currentQuestionIndex--;
            console.log('Moved to previous question, new index:', this.currentQuestionIndex);
        }
    }

    validateCurrentQuestion() {
        const currentQuestion = this.currentQuestion;
        const questionId = currentQuestion.id;
        const answer = this.answers[questionId];
        
        console.log('Validating question:', {
            questionId: questionId,
            questionText: currentQuestion.text,
            answer: answer,
            questionType: currentQuestion.type
        });
        
        // Check if question is answered
        if (!answer || (Array.isArray(answer) && answer.length === 0) || answer === '') {
            this.showError(`Please answer the question: "${currentQuestion.text}"`);
            return false;
        }
        
        // Additional validation for specific question types
        if (currentQuestion.isText && answer.trim().length < 3) {
            this.showError(`Please provide a more detailed answer for: "${currentQuestion.text}"`);
            return false;
        }
        
        // Clear any existing error
        this.clearError();
        return true;
    }

    showError(message) {
        this.error = message;
        console.log('Validation error:', message);
        
        // Scroll to top to show error
        this.template.querySelector('.questionnaire-container')?.scrollIntoView({ behavior: 'smooth' });
    }

    clearError() {
        this.error = null;
    }

    async handleSubmit() {
        console.log('handleSubmit called');
        console.log('Submit button clicked');
        //console.log('Submitting answers:', this.answers);
        console.log('Submitting answers:', JSON.stringify(this.answers));
        console.log('Submitting answers (dir):');
        console.dir(this.answers);
        console.log('Submitting answers (spread):', { ...this.answers });
        
        // Validate all questions before submission
        if (!this.validateAllQuestions()) {
            return;
        }
        
        try {
            this.loading = true;

            const sessionId = await submitQuestionnaire({ 
                contactId: this.contactId, 
                answers: this.answers 
            });
            
            console.log('Questionnaire submitted successfully, session ID:', sessionId);
            
            this.showQuestionnaire = false;
            this.loading = false;
            
            // Refresh previous sessions
            await this.loadPreviousSessions();
            
            // Show success message
            this.dispatchEvent(new CustomEvent('questionnairecompleted', {
                detail: { 
                    message: 'Assessment completed successfully!',
                    sessionId: sessionId
                }
            }));
            
        } catch (error) {
            console.error('Error submitting questionnaire:', error);
            this.error = error.body?.message || error.message;
            this.loading = false;
        }
    }

    validateAllQuestions() {
        console.log('Validating all questions...');
        
        for (let i = 0; i < this.questions.length; i++) {
            const question = this.questions[i];
            const questionId = question.id;
            const answer = this.answers[questionId];
            
            if (!answer || (Array.isArray(answer) && answer.length === 0) || answer === '') {
                // Navigate to the unanswered question
                this.currentQuestionIndex = i;
                this.showError(`Please answer question ${i + 1}: "${question.text}"`);
                return false;
            }
            
            // Additional validation for text questions
            if (question.isText && answer.trim().length < 3) {
                this.currentQuestionIndex = i;
                this.showError(`Please provide a more detailed answer for question ${i + 1}: "${question.text}"`);
                return false;
            }
        }
        
        this.clearError();
        return true;
    }
}