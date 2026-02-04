import { LightningElement, api, track } from 'lwc';
import uploadFile from '@salesforce/apex/OfflineFileUploaderController.uploadFile';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const DB_NAME = 'OfflineFileDB';
const STORE_NAME = 'FilesQueue';
const DB_VERSION = 1;

export default class OfflineFileUploader extends LightningElement {
    @api recordId;
    @track uploadMessage = '';
    fileData;

    // Open/create IndexedDB
    openDB() {
        return new Promise((resolve, reject) => {
            const request = indexedDB.open(DB_NAME, DB_VERSION);
            request.onupgradeneeded = (event) => {
                const db = event.target.result;
                if (!db.objectStoreNames.contains(STORE_NAME)) {
                    db.createObjectStore(STORE_NAME, { keyPath: 'id', autoIncrement: true });
                }
            };
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    async saveToIndexedDB(file) {
        const db = await this.openDB();
        return new Promise((resolve, reject) => {
            const tx = db.transaction(STORE_NAME, 'readwrite');
            const store = tx.objectStore(STORE_NAME);
            store.add(file);
            tx.oncomplete = () => resolve();
            tx.onerror = () => reject(tx.error);
        });
    }

    async readAllFiles() {
        const db = await this.openDB();
        return new Promise((resolve, reject) => {
            const tx = db.transaction(STORE_NAME, 'readonly');
            const store = tx.objectStore(STORE_NAME);
            const request = store.getAll();
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    async removeFile(id) {
        const db = await this.openDB();
        return new Promise((resolve, reject) => {
            const tx = db.transaction(STORE_NAME, 'readwrite');
            const store = tx.objectStore(STORE_NAME);
            store.delete(id);
            tx.oncomplete = () => resolve();
            tx.onerror = () => reject(tx.error);
        });
    }

    handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = () => {
            const base64 = reader.result.split(',')[1];
            this.fileData = {
                recordId: this.recordId,
                fileName: file.name,
                base64Data: base64,
                mimeType: file.type
            };
        };
        reader.readAsDataURL(file);
    }

    async handleUpload() {
        if (!this.fileData) {
            this.showToast('Error', 'Please select a file first.', 'error');
            return;
        }

        try {
            // Save to IndexedDB immediately
            await this.saveToIndexedDB(this.fileData);

            // Fire-and-forget feedback
            this.uploadMessage = 'File queued for background upload.';
            this.showToast('Info', 'File queued. You can continue working.', 'info');

            // Clear selection
            this.fileData = null;

            // Trigger background upload asynchronously
            this.uploadQueuedFiles();

        } catch (err) {
            console.error('Error saving file offline', err);
            this.showToast('Error', 'Failed to queue file offline', 'error');
        }
    }

    async uploadQueuedFiles() {
        if (!navigator.onLine) return; // only upload when online

        const files = await this.readAllFiles();
        for (const file of files) {
            try {
                await uploadFile({
                    recordId: file.recordId,
                    fileName: file.fileName,
                    base64Data: file.base64Data,
                    mimeType: file.mimeType
                });
                await this.removeFile(file.id);
            } catch (err) {
                console.error('Background upload failed:', file.fileName, err);
            }
        }
    }

    connectedCallback() {
        // Retry background uploads when network comes back
        window.addEventListener('online', () => this.uploadQueuedFiles());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}