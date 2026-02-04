import { LightningElement, api, track } from 'lwc';
import uploadWithStatus from '@salesforce/apex/WorkOrderPhotoUploader.uploadWithStatus';
import { loadScript } from 'lightning/platformResourceLoader';
import localforageLib from '@salesforce/resourceUrl/localforage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const DB_KEY = 'photoQueue';

export default class WorkOrderPhotoCapture extends LightningElement {
    @api recordId;
    videoElement;
    canvasElement;
    stream;

    @track photoList = [];
    @track statusValue = '';
    statusOptions = [
        { label: 'Completed', value: 'Completed' },
        { label: 'In Progress', value: 'In Progress' },
        { label: 'Pending', value: 'Pending' }
    ];

    connectedCallback() {
        loadScript(this, localforageLib).then(() => {
            this.initLocalForage();
        }).catch(error => {
            console.error('localforage load error:', error);
        });
    }

    renderedCallback() {
        if (!this.videoElement && this.template.querySelector('video')) {
            this.videoElement = this.template.querySelector('video');
            this.canvasElement = this.template.querySelector('canvas');
            this.initCamera();
        }
    }

    async initCamera() {
        try {
            this.stream = await navigator.mediaDevices.getUserMedia({ video: true });
            this.videoElement.srcObject = this.stream;
            this.videoElement.play();
        } catch (e) {
            console.error('Camera access failed:', e);
        }
    }

    capturePhoto() {
        const context = this.canvasElement.getContext('2d');
        this.canvasElement.width = this.videoElement.videoWidth;
        this.canvasElement.height = this.videoElement.videoHeight;
        context.drawImage(this.videoElement, 0, 0);

        const base64 = this.canvasElement.toDataURL('image/png');

        const photo = {
            name: `photo_${Date.now()}.png`,
            content: base64,
            workOrderId: this.recordId,
            uploaded: false,
            statusValue: this.statusValue
        };

        localforage.getItem(DB_KEY).then(queue => {
            queue = queue || [];
            queue.push(photo);
            return localforage.setItem(DB_KEY, queue);
        }).then(() => {
            this.photoList = [...this.photoList, photo];
        }).catch(err => console.error('LocalForage error:', err));
    }

    handleStatusChange(event) {
        this.statusValue = event.detail.value;
    }

    handleManualSync() {
        this.syncPhotos();
    }

    async syncPhotos() {
        const queue = (await localforage.getItem(DB_KEY)) || [];
        const updatedQueue = [];
        let successCount = 0;
        let errorCount = 0;

        for (let photo of queue) {
            if (photo.uploaded) {
                updatedQueue.push(photo);
                continue;
            }

            try {
                await uploadWithStatus({
                    workOrderId: photo.workOrderId,
                    fileName: photo.name,
                    base64Data: photo.content,
                    statusValue: photo.statusValue
                });
                photo.uploaded = true;
                successCount++;
                updatedQueue.push(photo);
            } catch (e) {
                console.error('Upload failed:', photo.name, e.message);
                errorCount++;
                updatedQueue.push(photo);
            }
        }

        await localforage.setItem(DB_KEY, updatedQueue);
        this.photoList = updatedQueue.filter(p => p.workOrderId === this.recordId && !p.uploaded);

        this.dispatchEvent(new ShowToastEvent({
            title: 'Sync Result',
            message: `${successCount} uploaded, ${errorCount} failed.`,
            variant: errorCount > 0 ? 'warning' : 'success'
        }));
    }

    initLocalForage() {
        this.loadQueuedPhotos();
        setInterval(this.syncPhotos.bind(this), 120000);
        window.addEventListener('online', this.syncPhotos.bind(this));
    }

    async loadQueuedPhotos() {
        const queue = (await localforage.getItem(DB_KEY)) || [];
        this.photoList = queue.filter(p => p.workOrderId === this.recordId && !p.uploaded);
    }

    disconnectedCallback() {
        if (this.stream) {
            this.stream.getTracks().forEach(track => track.stop());
        }
    }
}