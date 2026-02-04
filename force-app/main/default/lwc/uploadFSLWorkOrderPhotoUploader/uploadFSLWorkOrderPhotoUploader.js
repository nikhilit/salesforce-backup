import { LightningElement, api, track } from 'lwc';
import uploadPhoto from '@salesforce/apex/FSLWorkOrderPhotoUploader.uploadPhoto';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
 
const MAX_BYTES = 1 * 1024 * 1024; // ~1 MB
const MIN_QUALITY = 0.30;
const START_QUALITY = 0.70;
const MAX_WIDTH = 1200;
 
export default class UploadFSLWorkOrderPhotoUploader extends LightningElement {
    @api recordId;
    @track files = [];
    @track isOnline = navigator.onLine;
 
    connectedCallback() {
        // Load saved files from localStorage
        this.loadFiles();
 
        // restore online/offline
        this.isOnline = navigator.onLine;
 
        // Bind handlers
        this.boundOnlineHandler = this.handleOnline.bind(this);
        this.boundOfflineHandler = this.handleOffline.bind(this);
        window.addEventListener('online', this.boundOnlineHandler);
        window.addEventListener('offline', this.boundOfflineHandler);
 
        // Fallback polling
        this.pollInterval = setInterval(() => {
            const nowOnline = navigator.onLine;
            if (nowOnline && !this.isOnline) {
                this.handleOnline();
            } else if (!nowOnline && this.isOnline) {
                this.handleOffline();
            }
        }, 4000);
 
        // After loading saved files, immediately trigger upload for pending files if online
        if (this.isOnline) {
            this.uploadPendingFiles();
        }
    }
 
    disconnectedCallback() {
        window.removeEventListener('online', this.boundOnlineHandler);
        window.removeEventListener('offline', this.boundOfflineHandler);
        clearInterval(this.pollInterval);
    }
 
    get storageKey() {
        return `woOfflinePhotos_${this.recordId}`;
    }
 
    openFilePicker() {
        const input = this.template.querySelector('input[data-source="gallery"]')
                   || this.template.querySelector('input[type="file"]');
        if (input) input.click();
    }
 
    loadFiles() {
        try {
            const saved = localStorage.getItem(this.storageKey);
            if (saved) {
                let parsed = JSON.parse(saved);
 
                // Normalize each file so we don’t lose them
                parsed = parsed.map(f => {
                    if (!f.uploaded) {
                        f.status = 'Pending';
                        f.progress = 0;
                    }
                    return f;
                });
 
                this.files = parsed;
                this.saveToLocal(); // keep storage updated
            } else {
                this.files = [];
            }
        } catch (e) {
            console.warn('Could not load offline files', e);
            this.files = [];
        }
    }
 
    saveToLocal() {
        try {
            localStorage.setItem(this.storageKey, JSON.stringify(this.files));
        } catch (e) {
            console.error('Saving to localStorage failed', e);
        }
    }
 
    handleOnline() {
        this.isOnline = true;
        this.uploadPendingFiles();
    }
 
    handleOffline() {
        this.isOnline = false;
    }
 
    async handleFileChange(event) {
        // Allow multiple file selection
        const selectedFiles = Array.from(event.target.files || []);
        if (!selectedFiles.length) return;
 
        for (const file of selectedFiles) {
            try {
                const dataUrl = await this.readFileAsDataURL(file);
                const mime = this.detectMimeType(dataUrl) || file.type || 'image/jpeg';
 
                // --- compression variables ---
                let compressedDataUrl = dataUrl;
                let quality = START_QUALITY;
                let maxWidth = MAX_WIDTH;
                let base64 = this.getBase64FromDataUrl(compressedDataUrl);
                let byteCount = this.base64ToBytes(base64);
 
                // Keep compressing until we’re below MAX_BYTES or quality hits MIN_QUALITY
               while (byteCount > MAX_BYTES && quality >= MIN_QUALITY) {
    compressedDataUrl = await this.compressDataUrl(
        compressedDataUrl,   // ✅ use last compressed version
        mime,
        maxWidth,
        quality
    );
    base64 = this.getBase64FromDataUrl(compressedDataUrl);
    byteCount = this.base64ToBytes(base64);
    quality -= 0.10; // smaller step for smoother compression
    maxWidth = Math.max(800, Math.floor(maxWidth * 0.85)); // gradually reduce width
}
 
                // --- Build file metadata ---
                const ext = this.getExtensionFromMime(mime);
                const fileName = `Photo_${Date.now()}.${ext}`;
 
                const newFile = {
                    name: fileName,
                    base64: base64,
                    previewUrl: compressedDataUrl,
                    status: this.isOnline ? 'Uploading' : 'Pending',
                    progress: this.isOnline ? 10 : 0,
                    uploaded: false,
                    timestamp: Date.now() + Math.random(), // ensure uniqueness
                    workOrderId: this.recordId
                };
 
                this.files = [...this.files, newFile];
                this.saveToLocal();
 
                // if online, upload immediately
                if (this.isOnline) {
                    const idx = this.files.findIndex(f => f.timestamp === newFile.timestamp);
                    if (idx >= 0) this.uploadFile(idx);
                }
            } catch (err) {
                console.error('File processing failed', err);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Could not process the image.',
                    variant: 'error'
                }));
            }
        }
 
        // reset input so selecting the same file again triggers change
        event.target.value = '';
    }
 
    readFileAsDataURL(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onerror = () => reject(new Error('FileReader failed'));
            reader.onload = () => resolve(reader.result);
            reader.readAsDataURL(file);
        });
    }
 
    detectMimeType(dataUrl) {
        if (!dataUrl) return null;
        const match = dataUrl.match(/^data:(image\/[a-zA-Z]+);base64,/);
        return match ? match[1] : null;
    }
 
    getExtensionFromMime(mime) {
        if (!mime) return 'jpg';
        if (mime.includes('png')) return 'png';
        if (mime.includes('jpeg') || mime.includes('jpg')) return 'jpg';
        if (mime.includes('webp')) return 'webp';
        return 'jpg';
    }
 
    compressDataUrl(dataUrl, mime, maxWidth, quality) {
        return new Promise((resolve, reject) => {
            const img = new Image();
            img.onload = () => {
                let { width, height } = img;
                if (width > maxWidth) {
                    const scale = maxWidth / width;
                    width = Math.round(width * scale);
                    height = Math.round(height * scale);
                }
                const canvas = document.createElement('canvas');
                canvas.width = width;
                canvas.height = height;
                const ctx = canvas.getContext('2d');
                ctx.drawImage(img, 0, 0, width, height);
                try {
                    const out = canvas.toDataURL(mime || 'image/jpeg', quality);
                    resolve(out);
                } catch (err) {
                    reject(err);
                }
            };
            img.onerror = reject;
            img.src = dataUrl;
        });
    }
 
    getBase64FromDataUrl(dataUrl) {
        return dataUrl.split(',')[1];
    }
 
    base64ToBytes(base64) {
        if (!base64) return 0;
        const padding = (base64.endsWith('==')) ? 2 : (base64.endsWith('=') ? 1 : 0);
        return Math.round((base64.length * 3) / 4) - padding;
    }
 
    async uploadFile(index) {
        const fileObj = this.files[index];
        if (!fileObj) return;
 
        this.files[index].status = 'Uploading';
        this.files[index].progress = Math.max(this.files[index].progress || 0, 20);
        this.files = [...this.files];
 
        try {
            await uploadPhoto({
                workOrderId: fileObj.workOrderId,
                fileName: fileObj.name,
                base64Data: fileObj.base64
            });
 
            this.files[index].uploaded = true;
            this.files[index].status = 'Uploaded';
            this.files[index].progress = 100;
            this.files = [...this.files];
            this.saveToLocal();
 
            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Uploaded',
                message: `${fileObj.name} uploaded successfully`,
                variant: 'success'
            }));
        } catch (err) {
            console.error('Upload failed', err);
            this.files[index].status = 'Pending';
            this.files[index].progress = 0;
            this.files[index].uploaded = false;
            this.files = [...this.files];
            this.saveToLocal();
 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Upload Failed',
                message: err?.body?.message || err?.message || 'Upload failed',
                variant: 'error'
            }));
        }
    }
 
    async uploadPendingFiles() {
        for (let i = 0; i < this.files.length; i++) {
            const f = this.files[i];
            if (!f.uploaded && (f.status === 'Pending' || f.status === 'Retry')) {
                if (!navigator.onLine) {
                    this.isOnline = false;
                    break;
                }
                await new Promise((res) => setTimeout(res, 300));
                await this.uploadFile(i);
            }
        }
    }
 
    handleRetry(event) {
        const idx = event.currentTarget.dataset.index;
        if (idx != null) {
            this.isOnline = navigator.onLine;
            if (this.isOnline) this.uploadFile(parseInt(idx, 10));
            else {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Offline',
                    message: 'Device is offline — will upload when online',
                    variant: 'info'
                }));
            }
        }
    }
 
    handleRemove(event) {
        const idx = event.currentTarget.dataset.index;
        if (idx != null) {
            const i = parseInt(idx, 10);
            this.files.splice(i, 1);
            this.files = [...this.files];
            this.saveToLocal();
        }
    }
}