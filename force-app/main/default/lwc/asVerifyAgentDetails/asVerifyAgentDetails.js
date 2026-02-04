import { LightningElement, api, wire } from 'lwc';
import getAgentDetails from '@salesforce/apex/AS_VerifyAgentDetailsHandler.getAgentDetails';
import MGL_Logo from '@salesforce/resourceUrl/MGL_Logo';

export default class AsVerifyAgentDetails extends LightningElement {
    @api recordId;
    agentName;
    fields = [];
    logoUrl = MGL_Logo;

    @wire(getAgentDetails, { userId: '$recordId' })
    wiredAgent({ data, error }) {
        if (data) {
            this.agentName = data.name;
            this.fields = data.fields;
        } else if (error) {
            console.error('Error loading agent details:', error);
        }
    }

    get backgroundStyle() {
        return `background-image: url(${this.logoUrl});
                background-size: inherit;
                background-repeat: no-repeat;
                background-position: center;`;
    }
}