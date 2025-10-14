import { LightningElement } from 'lwc';

export default class Questionnaire extends LightningElement {
    // Minimal component per requirements: display-only header, description, and button.
    startAssesment(){
        console.log('Start Assesment Clicked');    
    }
}