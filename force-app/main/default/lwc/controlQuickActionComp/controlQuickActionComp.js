import { LightningElement, track, wire } from 'lwc';
import getUserProfileName from '@salesforce/apex/UserProfileController.getUserProfileName';
import hasPermission from '@salesforce/customPermission/My_ListViewAction';

export default class ControlQuickActionComp extends LightningElement {
    @track showButton = true;

    @wire(getUserProfileName)
    wiredProfile({ error, data }) {
        if (data) {
            if (data === 'System Administrator' || !hasPermission) {
                this.showButton = false;
            }
        } else if (error) {
            console.error(error);
        }
    }
}