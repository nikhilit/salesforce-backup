import { LightningElement,api } from 'lwc';
export default class WorkOrderbulkUploadLiveComponent extends LightningElement {
 @api recordIds;
 vfUrl
 connectedCallback() {
        const idsOnly = this.recordIds.map(r => typeof r === 'string' ? r : r.Id);
        const idsParam = encodeURIComponent(idsOnly.join(','));
        this.vfUrl = `/apex/BulkUploadLivePDF?ids=${idsParam}`;
 }
}