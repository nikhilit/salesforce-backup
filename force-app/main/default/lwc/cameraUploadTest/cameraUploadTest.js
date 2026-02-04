/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 19-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   23-10-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { api, LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getImageURL from '@salesforce/apex/CameraUploadTestController.getImageURL';

export default class CameraUploadTest extends LightningElement {

    @api recordId='0WOfs000001A0THGA0';
    @api permissionId;
    @api enableToast = false;
    @api enableImageSync = false;
    @api enableAction = false;
    @api fileExtensions; // e.g., '.jpg,.png,.pdf'

    @track url;

    connectedCallback() {
        getImageURL({albumId:this.recordId})
            .then(result => {
                this.url = result;
                console.log('Upload Token:', this.url);
            })
            .catch(error => {
                console.error('Error:', error);
                this.url = null;
            });
    }

    token='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhZTZmYzA4Zi0xNWJhLTRkZDgtOGFiZC0zYzJiZmM3ZDMyZGIiLCJpYXQiOjE3NjM1NTczMjEsInVzZXJfaWQiOiIwMDVIejAwMDAwNkFuMmtJQUMiLCJlbWFpbCI6ImthcnRpay5wYXRrYXJAYXBwc3RyYWlsLmNvbSIsImFsYnVtX2lkIjoiMFdPZnMwMDAwMDFBMFRIR0EwIiwibmFtZSI6IiJ9._fjr1GZtL8tobgYVZox5ZRKXskkD0qVEYSiqpx6cn1E';
    handleTakePhoto() {
        const url = `sharinpix://upload?token=${this.token}`;
        window.location.href = url;
    }


    filename = '';
    fileModifiedTime = null;
    currentTime = null;
    fileData = null;
    handleFileChange(event) {
        this.filename 
        const file = event.target.files[0];
        if (!file) return;

        const now = new Date();
        const modifiedTime = new Date(file.lastModified);
        const diffSeconds = Math.floor((now - modifiedTime) / 1000);
        this.fileModifiedTime = modifiedTime.toISOString();
        this.filename = file.name;
        this.currentTime = now.toISOString();
        this.fileData = JSON.stringify(file);
        console.log('Selected File:', file);
        if (diffSeconds > 10 || file.size < 50000) {
            this.showToastMessage('Invalid Image', 'Please capture a fresh photo.', 'error');
            event.target.value = '';
        }

        // If image is older than 5 seconds → probably from gallery
        if (diffSeconds > 5) {
            this.showToastMessage(
                'Invalid Image',
                'Please capture image using camera (not from gallery).',
                'error'
            );
            event.target.value = ''; // reset file input
            return;
        }else{
            this.showToastMessage(
                'Valid Image',
                'Image captured using camera.',
                'success'
            );
        }

        // ✅ Continue with upload logic
        const reader = new FileReader();
        reader.onload = () => {
            this.fileData = {
                filename: file.name,
                base64: reader.result.split(',')[1],
                contentType: file.type
            };
            console.log('Valid photo captured:', this.fileData);
        };
        reader.readAsDataURL(file);
    }

    /**
     * This function creates a new ShowToastEvent, sets the title, message, variant, and mode, and then
     * dispatches the event
     * @param title - The title of the toast message.
     * @param message - The message you want to display in the toast.
     * @param variant - The type of toast message. Valid values are error, warning, success, and info.
     * @param mode - This is the mode of the toast. It can be either 'dismissable','pester' or 'sticky'.
     */
    showToastMessage(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}