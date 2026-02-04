import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NextBestActionCard extends NavigationMixin(LightningElement) {
    @api recordId; // This automatically gets populated on record page

    handleActionClick(event) {
        const action = event.currentTarget.dataset.name;
        console.log('Action clicked:', action);
    }

openAccountDisplay() {
    if (!this.recordId) {
        console.error('No recordId available for navigation');
        return;
    }

    this[NavigationMixin.Navigate]({
        type: 'standard__navItemPage',
        attributes: {
            apiName: 'Account_Display' // Make sure this matches your Lightning App Page Tab
        },
        state: {
            c__accountId: this.recordId // <== MUST BE EXACTLY `accountId`
        }
    }, true); // true = open in new tab
}

}