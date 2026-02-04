import { api, LightningElement, track } from 'lwc';
export default class RTCamerUploadcomp extends LightningElement {
        @api 
        set imageList(value) {
            this.steps = value;
        }
    
        get imageList() {
            return this.steps;
        }
    
        @api disabled=false;
        @track steps = [];
    
        handleImageUpload(event) {
            console.log('handleImageUpload');
            const stepId = Number(event.target.dataset.id);
            const file = event.target.files[0];
    
            if (file) {
                console.log('handleImageUpload file', file);
                const reader = new FileReader();
                reader.onload = () => {
                    const updatedSteps = this.steps.map(step => {
                        if (step.id === stepId) {
                            return {
                                ...step,
                                uploaded: true,
                                previewUrl: reader.result,
                                fileName: file.name,
                                base64Data: reader.result.split(',')[1]
                            };
                        }
                        return step;
                    });
                    this.steps = updatedSteps;
                    this.handleReturn();
                };
                reader.readAsDataURL(file);
            }
        }
    
        removeImage(event) {
            console.log('removeImage');
            const stepId = Number(event.target.dataset.id);
            this.steps = this.steps.map(step => {
                if (step.id === stepId) {
                    return { ...step, uploaded: false, previewUrl: '' };
                }
                return step;
            });
            this.handleReturn();
        }
    
        handleReturn() {
            const valueSelectedEvent = new CustomEvent("change", {
                detail: { steps: this.steps },
            });
            this.dispatchEvent(valueSelectedEvent);
    
        }
}