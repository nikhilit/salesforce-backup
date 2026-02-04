/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 07-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   07-11-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { LightningElement, api, track } from 'lwc';
export default class WorkOrderbulkUploadComponent extends LightningElement {
	@api recordIds;
	vfUrl

	options = [
		{ label: 'Joint Ticket PDF', value: 'jointTicketPDF' },
		{ label: 'Live Reading PDF', value: 'liveReadingPDF' },
	];
	@track defaultValue='jointTicketPDF';

	get getURL(){
		const idsParam = encodeURIComponent(this.recordIds.join(','));
		if(this.defaultValue === 'jointTicketPDF'){
			return `/apex/BulkUploadJointPDF?ids=${idsParam}`;
		}else{
			return `/apex/BulkUploadLivePDF?ids=${idsParam}`;
		}
	}

	handleChange(event){
		var value=event.target.value;
		this.defaultValue=value;
	}

	connectedCallback() {
		//const idsOnly = this.recordIds.map(r => typeof r === 'string' ? r : r.Id);
		const idsParam = encodeURIComponent(this.recordIds.join(','));
		this.vfUrl = `/apex/BulkUploadJointPDF?ids=${idsParam}`;
	}
}