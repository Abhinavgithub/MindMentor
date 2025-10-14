import { LightningElement } from 'lwc';

export default class Questionnaire extends LightningElement {
    
    loadAssessment = false;

    startAssesment(){
        console.log('Start Assesment Clicked');
        this.loadAssessment = true;
        console.log('loadAssessment: ', this.loadAssessment);
    }
}