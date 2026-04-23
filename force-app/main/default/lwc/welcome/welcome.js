import { LightningElement, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';

const FIELDS = ['User.Name', 'User.Email', 'User.FullPhotoUrl'];   

export default class Welcome extends NavigationMixin(LightningElement) {
    userName;
    userEmail;
    userAvatar;

    @wire(getRecord, { recordId: USER_ID, fields: FIELDS })
    userRecord({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
            this.userEmail = data.fields.Email.value;
            this.userAvatar = data.fields.FullPhotoUrl.value;
        } else if (error) {
            this.userName = 'User';
            this.userEmail = '';
            this.userAvatar = '';
        }
    }

    // Personalized welcome message
    get personalizedMessage() {
        return this.userName
            ? `Welcome back, ${this.userName}!`
            : 'Welcome to Mind Mentor!';
    }

    // App introduction
    get appIntroduction() {
        return {
            title: 'Your Mental Wellness Companion',
            description: 'Mind Mentor is your personal mental health and wellness companion, designed to help you track your mood, practice mindfulness, and develop healthy habits. Whether you\'re looking to reduce stress, improve your mental clarity, or simply maintain a positive mindset, Mind Mentor provides the tools and guidance you need on your wellness journey.',
            features: [
                { label: 'Mood tracking and journaling',              icon: 'utility:edit' },
                { label: 'Guided meditation and breathing exercises', icon: 'utility:heart' },
                { label: 'Personalized wellness insights',            icon: 'utility:trending' },
                { label: 'Goal setting and progress monitoring',      icon: 'utility:target' },
                { label: 'Community support and resources',           icon: 'utility:groups' }
            ]
        };
    }

    handleGetStarted() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/questionnaire'
            }
        });
    }

    connectedCallback() {}
}