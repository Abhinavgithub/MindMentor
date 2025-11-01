import { LightningElement } from 'lwc';
import ToastContainer from 'lightning/toastContainer';
import Toast from 'lightning/toast';
import getQuestions from '@salesforce/apex/QuestionnaireController.getQuestions';
import getSession from '@salesforce/apex/QuestionnaireController.getSession';
import createUserResponse from '@salesforce/apex/QuestionnaireController.createUserResponse';
import getSessionResponses from '@salesforce/apex/QuestionnaireController.getSessionResponses';
import completeSession from '@salesforce/apex/QuestionnaireController.completeSession';
import Id from '@salesforce/user/Id';
export default class Questionnaire extends LightningElement {
    userId = Id; // Property to hold the user's ID
    loadAssessment = false;
    questions = [];
    currentQuestionIndex = 0;
    selectedAnswers = {};
    currentSessionId = null;
    currentSelectedAnswer = null;
    renderVersion = 0; // used with key to force re-render on navigation

    connectedCallback() {
        const toastContainer = ToastContainer.instance();
        toastContainer.maxToasts = 5;
        toastContainer.toastPosition = 'bottom-center';
    }
    
    //Getter to return the current question object for the template
    get currentQuestion() {
        return this.questions.length > 0 ? this.questions[this.currentQuestionIndex] : null;
    }

    // Getter to determine if the "Previous" button should be disabled
    get isFirstQuestion() {
        return this.currentQuestionIndex === 0;
    }

    // Getter to determine if the "Next" or "Submit" button should be shown
    get isLastQuestion() {
        return this.currentQuestionIndex === this.questions.length - 1;
    }

    // Unique key to force radio-group re-render per question change
    get radioKey() {
        const qId = this.currentQuestion ? this.currentQuestion.Id : 'none';
        return `${qId}-${this.renderVersion}`;
    }

    async startAssesment() {
        this.userId = '005gK000003Tnq1QAC'; //for testing purpose only, do not delete this line
        console.log('Start Assesment Clicked');
        console.log('Current User ID:', this.userId);
        this.loadAssessment = true;

        try {
            // Call Apex method to get session details
            const sessionResult = await getSession({ userId: this.userId });
            console.log('Session result: ', sessionResult);
            this.currentSessionId = sessionResult?.sessionId || null;
            console.log('Session started: ', this.currentSessionId);
        } catch (error) {
            const msg = error?.body?.message || error?.message || JSON.stringify(error);
            console.error('Error starting session: ', msg);
        }

        try {
            // Call Apex method to get questions
            const questionsResult = await getQuestions();
            console.log('Questions fetched: ', questionsResult);
            
            // The result from Apex is likely a JSON string, so we need to parse it first.
            const parsedResult = JSON.parse(questionsResult);
            console.log('No of questions: ', parsedResult.length);
            this.questions = parsedResult.map(q => {
                // Map options to the format required by lightning-radio-group
                const options = q.Options.map(opt => ({
                    label: opt.OptionText,
                    value: opt.Id
                }));
                console.log('Options: ', options);
                const combinedLabel = `${q.Order}. ${q.QuestionText}`;
                // Return a new object with the original question data and the formatted options
                console.log('Mapped Question: ', { ...q, options, combinedLabel });
                return { ...q, options, combinedLabel };
            });
        } catch (error) {
            console.error('Error fetching questions: ', error.message);
        }

        // Prefetch any existing responses for this session and hydrate local cache
        try {
            if (this.currentSessionId) {
                const responsesResult = await getSessionResponses({ sessionId: this.currentSessionId });
                console.log('Session responses fetched: ', responsesResult);
                const responseMap = responsesResult ? JSON.parse(responsesResult) : {};
                // selectedAnswers is a map keyed by QuestionId -> SelectedOptionId
                this.selectedAnswers = responseMap || {};
            }
        } catch (error) {
            const msg = error?.body?.message || error?.message || JSON.stringify(error);
            console.error('Error fetching session responses: ', msg);
        }

        // Sync initial selection for the first question
        this.syncCurrentSelectionFromCache();

        console.log('loadAssessment: ', this.loadAssessment);
    }

    handleOptionChange(event) {
        const questionId = event.target.name;
        const selectedValue = event.target.value;
        // update cache and current value
        this.selectedAnswers[questionId] = selectedValue;
        this.currentSelectedAnswer = selectedValue;

        console.log('Selected Answers: ', JSON.stringify(this.selectedAnswers));
        console.log('Question ID: ', questionId, ' Selected Value: ', selectedValue);
        console.log('Answer for current question: ', this.selectedAnswers[this.currentQuestion.Id]);
    }

    async handlePrevious() {
        if (this.currentQuestionIndex > 0) {
            // Force clear current selection so lightning-radio-group fully re-renders
            this.currentSelectedAnswer = null;

            // Decrement index synchronously
            this.currentQuestionIndex--;

            // bump version to force re-render
            this.renderVersion++;

            // Wait for next frame to ensure DOM updated before hydration
            await this.nextFrame();
            this.syncCurrentSelectionFromCache();
        }
    }

    async handleNext() {
        console.log('Current Question Index: ', this.currentQuestionIndex);
        console.log('Current Question ID: ', this.currentQuestion?.Id);
        console.log('Selected Answers: ', JSON.stringify(this.selectedAnswers));
        console.log('answer for current question: ', this.currentQuestion ? this.selectedAnswers[this.currentQuestion.Id] : null);

        // Persist current selection for this question
        try {
            if (this.currentQuestion && this.selectedAnswers[this.currentQuestion.Id]) {
                const userAnswer = await createUserResponse({
                    sessionId: this.currentSessionId,
                    questionId: this.currentQuestion.Id,
                    answerId: this.selectedAnswers[this.currentQuestion.Id],
                    answerText: ''
                });
                console.log('User Answer saved: ', userAnswer);
            }
        } catch (error) {
            const msg = error?.body?.message || error?.message || JSON.stringify(error);
            console.error('Error saving user response: ', msg);
        }

        if (this.currentQuestionIndex < this.questions.length - 1) {
            // Clear before moving to force re-render of radio group
            this.currentSelectedAnswer = null;

            this.currentQuestionIndex++;

            // bump version to force re-render
            this.renderVersion++;

            // Wait for next frame to ensure DOM updated before hydration
            await this.nextFrame();
            this.syncCurrentSelectionFromCache();
        }
    }

    // Centralized toast helper to ensure DOM is stable in LWR before showing
    showToast(variant,title, message,mode = 'dismissable') {
        Toast.show({
           label: title,
           message: message,
           mode: mode,
           variant: variant,
           onclose: () => {
              // Do something after the toast is closed
           }
        }, this);
    }

    async handleSubmit() {
        console.log('Submitting answers:', JSON.stringify(this.selectedAnswers));

        // Guard: must have a session
        if (!this.currentSessionId) {
            console.error('No active session to complete.');
            this.showToast('error', 'Submission Failed', 'No active session to complete.', 'sticky');
            return;
        }

        // Persist last question response if selected (same as in handleNext)
        try {
            if (this.currentQuestion && this.selectedAnswers[this.currentQuestion.Id]) {
                const userAnswer = await createUserResponse({
                    sessionId: this.currentSessionId,
                    questionId: this.currentQuestion.Id,
                    answerId: this.selectedAnswers[this.currentQuestion.Id],
                    answerText: ''
                });
                console.log('Final User Answer saved: ', userAnswer);
            }
        } catch (error) {
            const msg = error?.body?.message || error?.message || JSON.stringify(error);
            console.error('Error saving final user response: ', msg);
            // surface error but continue to try completing session even if final save failed
            this.showToast('warning', 'Partial Save', `Final answer save issue: ${msg}`, 'dismissable');
        }

        // Complete the session (set status Completed and End Time = now)
        try {
            const result = await completeSession({ sessionId: this.currentSessionId });
            console.log('Session completed: ', result);

            // Show success toast BEFORE changing view/navigation to avoid teardown swallowing the toast
            this.showToast('success', 'Assessment Submitted', 'Your assessment has been submitted successfully.', 'dismissable');

            // Add a small delay to ensure toast displays before resetting state
            await new Promise(resolve => setTimeout(resolve, 300));

            // Now reset to landing view or navigate
            this.loadAssessment = false;
            this.currentQuestionIndex = 0;
            this.selectedAnswers = {};
            this.currentSessionId = null;
            this.currentSelectedAnswer = null;
            this.renderVersion++;
        } catch (error) {
            const msg = error?.body?.message || error?.message || JSON.stringify(error);
            console.error('Error completing session: ', msg);
            this.showToast('error', 'Submission Failed', msg, 'sticky');
        }
    }

    // Helper to hydrate the lightning-radio-group selection from cache for the current question
    syncCurrentSelectionFromCache() {
        const q = this.currentQuestion;
        // compute next value
        const nextValue = q ? this.selectedAnswers[q.Id] || null : null;

        // Set it to ensure lightning-radio-group reflects it after re-render
        this.currentSelectedAnswer = nextValue;

        console.log('Synced currentSelectedAnswer to: ', this.currentSelectedAnswer, ' for question: ', q?.Id);
    }

    // Await next browser paint to ensure DOM has re-rendered
    nextFrame() {
        return new Promise((resolve) => {
            // Use requestAnimationFrame when available, fallback to microtask
            if (typeof requestAnimationFrame === 'function') {
                requestAnimationFrame(() => resolve());
            } else {
                Promise.resolve().then(resolve);
            }
        });
    }
}
