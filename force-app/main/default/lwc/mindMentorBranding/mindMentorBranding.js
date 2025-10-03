import { LightningElement } from 'lwc';
import MINDMENTOR_LOGO from '@salesforce/resourceUrl/MindMentorLogo';

export default class MindMentorHeader extends LightningElement {
    get logoUrl() {
        console.log('MINDMENTOR_LOGO', MINDMENTOR_LOGO);
        return MINDMENTOR_LOGO;
    }
}