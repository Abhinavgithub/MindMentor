import { LightningElement } from 'lwc';
import getQuestions from '@salesforce/apex/QuestionnaireController.getQuestions';
import getSession from '@salesforce/apex/QuestionnaireController.getSession';
import Id from '@salesforce/user/Id';
export default class Questionnaire extends LightningElement {
    userId = Id; // Property to hold the user's ID
    loadAssessment = false;
    questions = [];
    currentQuestionIndex = 0;
    selectedAnswers = {};
    currentSessionId = null;

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

    startAssesment(){
        this.userId = '005gK000003Tnq1QAC';//for testing purpose only, remove later
        console.log('Start Assesment Clicked');
        console.log('Current User ID:', this.userId);
        this.loadAssessment = true;

        // Call Apex method to get session details
        getSession({ userId: this.userId })
            .then((result) => {
                console.log('Session result: ', result);
                this.currentSessionId = result?.sessionId || null;
                console.log('Session started: ', this.currentSessionId);
            })
            .catch((error) => {
                const msg = error?.body?.message || error?.message || JSON.stringify(error);
                console.error('Error starting session: ', msg);
            });
       

        getQuestions()
            .then((result) => {
                console.log('Questions fetched: ', result);
                // The result from Apex is likely a JSON string, so we need to parse it first.
                const parsedResult = JSON.parse(result);
                console.log('No of questions: ',  parsedResult.length);
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
            })
            .catch((error) => {
                console.error('Error fetching questions: ', error.message);
            });
        console.log('loadAssessment: ', this.loadAssessment);
    }

    handleOptionChange(event) {
        const questionId = event.target.name;
        const selectedValue = event.target.value;
        this.selectedAnswers[questionId] = selectedValue;
        console.log('Selected Answers: ', this.selectedAnswers);
    }

    handlePrevious() {
        if (this.currentQuestionIndex > 0) {
            this.currentQuestionIndex--;
        }
    }

    handleNext() {
        if (this.currentQuestionIndex < this.questions.length - 1) {
            this.currentQuestionIndex++;
        }
    }

    handleSubmit() {
        // Implement your submission logic here
        console.log('Submitting answers:', JSON.stringify(this.selectedAnswers));
        // For example, you could call an Apex method to save the answers
    }
}
