import { LightningElement, api, wire, track } from 'lwc';
import getAccountDetails from '@salesforce/apex/AccountDetailsController.getAccountDetails';
import dealerImage from "@salesforce/resourceUrl/dealerImage";
import blackCircle from '@salesforce/resourceUrl/blackCircle';
import { NavigationMixin } from 'lightning/navigation';

export default class SideBarComp extends NavigationMixin(LightningElement) {

     dearlerImageUrl = dealerImage;
    @api recordId;
    @track account;
    @track device ;
    @track idnumber ;
    @track servicecontract;
    @track securitydeposit;
    @track snowflake = blackCircle;
    @track status;

    get connectionName() {
        return this.account?.Premise__r?.Connection_Name__c || 'N/A';
    }
    get requestamount() {
        return this.securitydeposit?.Req_Amount__c || '0';
    }
    get premisename(){
        return this.account.Premise_Name__c|| 'N/A';
    }
    get hasValidIdNumber() {
    return this.idnumber?.Id != null;
}
 get hasValidIdPremise() {
    return this.account?.Premise__c != null;
} 
get hasValidIdDevice() {
    return this.device?.Id != null;
}
get hasValidIdConnection() {
    return this.account?.Premise__r?.Connection__r?.Id !== undefined && this.account?.Premise__r?.Connection__r?.Id !== null;
}
get hasValidServiceContract() {
    return this.account?.Service_Contract__r?.Id != null;
}



   get status() {
    const to = this.account?.Installation_Valid_To__c;
    const today = new Date();
 
    if (!to || new Date(to) > today) {
        return 'Inactive';
    }
    return 'Active';
}

    @wire(getAccountDetails, { accrcaseId: '$recordId' })
    wiredAccount({ error, data }) {
          console.log('data',data);
        if (data) {
            console.log('data',data);
            this.account = data.account || {};
            this.securitydeposit=data.securitydeposit || '';
            this.device = data.device || '';
            this.idnumber = data.idnumber||{};
            this.status=data.status||'';
            this.servicecontract = data.servicecontract || '';
         //  console.log('connection',this.account.Premise__r.Connection__r.Id);
           console.log('servicecontract',this.servicecontract.Id);
            console.log('accounts',JSON.stringify(this.account));
             console.log(JSON.stringify('this.securitydeposit',this.securitydeposit));
              console.log(JSON.stringify('this.devices',this.devices));
             console.log(JSON.stringify('this.idnumber',this.idnumber));
        } else {
            this.account = undefined;
            this.devices = [];
            this.securitydeposit=undefined;
        }
    }
     
navigateToRecord(event) {
    const recordId = event.currentTarget.dataset.id;
    const objectApiName = event.currentTarget.dataset.object;

    console.log('Navigating to record:', recordId, 'of object:', objectApiName);

    if (recordId && objectApiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName,
                actionName: 'view'
            }
        });
    } else {
        console.warn('Navigation skipped: Missing ID or Object Name');
    }
}

}