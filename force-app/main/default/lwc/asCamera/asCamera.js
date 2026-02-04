/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 12-09-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   20-05-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { api, LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
export default class CameraUploadComponent extends LightningElement {

    @api disabled = false;

    @track steps = [];
    @track showCamera = false;
    currentStepId = null;

    cameraStream = null;
    pictureTaken = false;
    capturedBase64 = '';
    cameraTrack = null;
   // Zoom
    zoomSupported = false;
    minZoom = 1;
    maxZoom = 1;
    currentZoom = 1;
    zoomStep = 0.2; 


    torchSupported = false;
    flashOn = false;

   @api frontCamera = false;


    @api
    set imageList(value) {
        this.steps = JSON.parse(JSON.stringify(value));
        this.steps.forEach(step => step.added = false);
    }

    get imageList() {
        return this.steps;
    }

    desktop=true;
    connectedCallback() {
        if(FORM_FACTOR === 'Large') {
            this.desktop=true;
        } else {
            this.desktop=false;
        }
        const ua = navigator.userAgent;
        this.isIOS = /iPad|iPhone|iPod/.test(ua) && !window.MSStream;

        this.handleOrientationChange = this.handleOrientationChange.bind(this);

        // Check for permission (iOS 13+ requires explicit approval)
        if (typeof DeviceOrientationEvent !== 'undefined' &&
            typeof DeviceOrientationEvent.requestPermission === 'function') {
            DeviceOrientationEvent.requestPermission()
                .then((response) => {
                    if (response === 'granted') {
                        window.addEventListener('deviceorientation', this.handleOrientationChange);
                    }
                })
                .catch((err) => {
                    console.warn('Orientation permission denied', err);
                });
        } else {
            // Android or older iOS
            window.addEventListener('deviceorientation', this.handleOrientationChange);
        }
    }

    disconnectedCallback() {
        this.stopCamera();
        window.removeEventListener('deviceorientation', this.handleOrientationChange);
    }

    // ========== CAMERA ==========
    openCamera(event) {
        this.currentStepId = event.currentTarget.dataset.id;
        this.pictureTaken = false;
        this.capturedBase64 = '';
        this.showCamera = true;
        this.showModel(this.showCamera);
        setTimeout(() => this.startCamera(), 300);
    }

    showModel(show) {
        var modelDOM = this.template.querySelector('.camera-wrapper');
        if (show) {
            if(this.desktop) {
                modelDOM.classList.add('slds-fade-in-open');
            }else{
                modelDOM.classList.add('show-camera-page');
                modelDOM.classList.remove('hide-camera-page');
            } 
        } else {
            if(this.desktop) {
                modelDOM.classList.remove('slds-fade-in-open');
            }else{
                modelDOM.classList.remove('show-camera-page');
                modelDOM.classList.add('hide-camera-page');
            }
        }
    }

    cameraErrorMessage;
    startCamera() {
        this.cameraErrorMessage = null;
        const video = this.template.querySelector('.camera-view');
        if (this.cameraStream) {
            video.srcObject = this.cameraStream;
            video.play();
            return;
        }
        // Check for camera support
        const isCameraSupported =
            navigator.mediaDevices &&
            typeof navigator.mediaDevices.getUserMedia === 'function';

        if (!isCameraSupported) {
            console.error('Camera not supported on this device/browser');
            return;
        }

        const constraints = {
            video: { 
                facingMode: { 
                    ideal: this.frontCamera?"user":"environment" 
                },
                width: { ideal: 1920 },
                height: { ideal: 1080 }
                // width: { ideal: 3840 },  // Request up to 4K if supported
                // height: { ideal: 2160 },
                // frameRate: { ideal: 30 } 
            }, // back camera
            audio: false
        };

        navigator.mediaDevices.getUserMedia(constraints)
            .then(stream => {
                this.cameraStream = stream;
                video.srcObject = stream;
                video.play();
                const [track] = stream.getVideoTracks();
                this.cameraTrack = track;
                const capabilities = track.getCapabilities();

                // Setup zoom if supported
                if (capabilities.zoom) {
                    this.minZoom = capabilities.zoom.min;
                    this.maxZoom = capabilities.zoom.max;
                    this.currentZoom = capabilities.zoom.min;

                    // Apply initial native zoom
                    this.cameraTrack.applyConstraints({ advanced: [{ zoom: this.currentZoom }] })
                        .catch(error => console.warn('Failed to apply initial native zoom:', error));
                } else {
                    // fallback zoom
                    this.minZoom = 1;
                    this.maxZoom = 3;
                    this.currentZoom = 1;

                    const video = this.template.querySelector('.camera-view');
                    if (video) {
                        video.style.transform = `scale(1)`; // initialize
                    }
                }


                // Setup torch (flash) supported flag
                this.torchSupported = capabilities.torch || false;
                this.flashOn = false;
            })
            .catch(err => {
                console.warn('Back camera failed, trying default', err);
                navigator.mediaDevices.getUserMedia({ video: true, audio: false })
                .then(fallbackStream => {
                    this.cameraStream = fallbackStream;
                    video.srcObject = fallbackStream;
                    video.play();
                })
                .catch(error => {
                    console.error("Camera access failed:", error);
                    if (error.name === 'NotAllowedError' || error.name === 'PermissionDeniedError') {
                        this.showToastMessage('Error', 'Camera permission was denied. Please allow camera access.', 'error');
                        this.cameraErrorMessage = 'Camera permission was denied. Please allow camera access in browser settings.';
                    } else {
                        this.showToastMessage('Error', 'Unable to access the camera. Please try again or check your device permissions.', 'error');
                        this.cameraErrorMessage = 'Unable to access the camera. Please try again or check your device permissions.';
                    }   
                });
            });
    }


    stopCamera() {
        if (this.cameraStream) {
            this.cameraStream.getTracks().forEach(track => track.stop());
            this.cameraStream = null;
        }
    }

    handleOrientationChange(event) {
    // ✅ Ignore tilting noise by using thresholds
    let gamma = event.gamma;  // left/right tilt
    let beta = event.beta;    // forward/back tilt

    // ✅ If beta tilt is large (phone tilted upward), DO NOT CHANGE orientation
    if (Math.abs(beta) > 60) {
        return;  // ignore orientation change when user tilts phone upward/downward
    }

    let angle = 0; // default to last angle

    // ✅ Detect true rotation only (ignore tilt)
    if (gamma > 45) {
        angle = 90;
    } else if (gamma < -45) {
        angle = 270;
    } else {
        angle = 0;
    }
    this.angleDisplay = angle;
}

    @track angleDisplay=0;
    async takePicture() {
        const video = this.template.querySelector('.camera-view');
        const canvas = this.template.querySelector('.camera-canvas');
        const context = canvas.getContext('2d');
        if (!video || !canvas) return;

        const vw = video.videoWidth;
        const vh = video.videoHeight;
        const scale = this.currentZoom || 1;

        // --- Modern orientation detection ---
        let angle = this.angleDisplay;
        
        // --- Set canvas based on orientation ---
        if (angle === 90 || angle === 270) {
            canvas.width = vh;
            canvas.height = vw;
        } else {
            canvas.width = vw;
            canvas.height = vh;
        }
        this.angleDisplay=angle;

        context.save();

        // --- Apply rotation ---
        switch (angle) {
            case 90:
                context.translate(canvas.width, 0);
                context.rotate((90 * Math.PI) / 180);
                break;
            case 180:
                context.translate(canvas.width, canvas.height);
                context.rotate(Math.PI);
                break;
            case 270:
                context.translate(0, canvas.height);
                context.rotate((270 * Math.PI) / 180);
                break;
            default:
                break;
        }

        // --- Mirror if front camera ---
        if (this.frontCamera) {
            context.translate(canvas.width, 0);
            context.scale(-1, 1);
        }

        // --- Draw the image ---
        if (this.cameraTrack && this.cameraTrack.getCapabilities?.().zoom) {
            context.drawImage(video, 0, 0, vw, vh);
        } else {
            const scaledWidth = vw / scale;
            const scaledHeight = vh / scale;
            const dx = (vw - scaledWidth) / 2;
            const dy = (vh - scaledHeight) / 2;
            context.drawImage(video, dx, dy, scaledWidth, scaledHeight, 0, 0, vw, vh);
        }

        context.restore();
        this.capturedBase64 = canvas.toDataURL('image/jpeg', 0.9);
        this.pictureTaken = true;
    }

    // takePicture() {
    //     const video = this.template.querySelector('.camera-view');
    //     const canvas = this.template.querySelector('.camera-canvas');
    //     const context = canvas.getContext('2d');

    //     const scale = this.currentZoom || 1;

    //     canvas.width = video.videoWidth;
    //     canvas.height = video.videoHeight;

    //     // Clear canvas
    //     context.clearRect(0, 0, canvas.width, canvas.height);

    //     if (this.cameraTrack && this.cameraTrack.getCapabilities()?.zoom) {
    //         // Native zoom – draw normally
    //         context.drawImage(video, 0, 0, canvas.width, canvas.height);
    //     } else {
    //         // CSS zoom fallback – simulate zoomed capture
    //         const scaledWidth = canvas.width / scale;
    //         const scaledHeight = canvas.height / scale;
    //         const dx = (canvas.width - scaledWidth) / 2;
    //         const dy = (canvas.height - scaledHeight) / 2;

    //         context.drawImage(
    //             video,
    //             dx, dy, scaledWidth, scaledHeight,
    //             0, 0, canvas.width, canvas.height
    //         );
    //     }

    //     this.capturedBase64 = canvas.toDataURL('image/jpeg',1.0);
    //     this.pictureTaken = true;
    // }


    retakePicture() {
        this.pictureTaken = false;
        this.capturedBase64 = '';
        setTimeout(() => this.startCamera(), 300);
    }

    savePicture() {
        const fileName = 'camera-image.jpg';
        this.updateStepWithImage(this.currentStepId, this.capturedBase64, fileName);
        this.closeCamera();
    }

    closeCamera() {
        // this.stopCamera();
        this.showCamera = false;
        this.showModel(this.showCamera);
        this.capturedBase64 = '';
        this.pictureTaken = false;
        this.currentStepId = null;
    }

    updateStepWithImage(stepId, base64, fileName = 'camera-image.jpg') {
        console.log('base64:::' + base64);
        console.log('fileName:::' + fileName);
        console.log('stepId:::' + stepId + ':::' + typeof stepId);
        // console.log('this.steps:::' + JSON.stringify(this.steps));

        this.steps = this.steps.map(step => {
            console.log('step.id:::' + step.id + ':::typeof step.id:::' + typeof step.id);
            if (String(step.id) === String(stepId)) {
                return {
                    ...step,
                    uploaded: true,
                    previewUrl: base64,
                    fileName: fileName,
                    base64Data: base64.split(',')[1],
                    added: true
                };
            }
            return step;
        });
        this.handleReturn();
    }

    // ========== IMAGE REMOVE ==========
    removeImage(event) {
        const stepId = event.target.dataset.id;
        if (this.disabled) return;

        this.steps = this.steps.map(step => {
            if (String(step.id) === String(stepId)) {
                return { ...step, uploaded: false, previewUrl: '', base64Data: '' };
            }
            return step;
        });
        this.handleReturn();
    }

    handleReturn() {
        // console.log('this.steps:::' + JSON.stringify(this.steps));
        this.dispatchEvent(new CustomEvent("change", {
            detail: { steps: this.steps },
        }));
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

    handleZoomChange(event) {
        const zoomValue = parseFloat(event.target.value);
        this.currentZoom = zoomValue;

        if (this.cameraTrack) {
            this.cameraTrack.getCapabilities?.(); // Just to be safe
            const capabilities = this.cameraTrack.getCapabilities();

            if (capabilities && capabilities.zoom) {
                // Native zoom supported
                this.cameraTrack.applyConstraints({ advanced: [{ zoom: zoomValue }] })
                    .catch(error => {
                        console.error('Native zoom failed:', error);
                    });
            } else {
                // Fallback to CSS zoom
                const video = this.template.querySelector('.camera-view');
                if (video) {
                    video.style.transform = `scale(${zoomValue})`;
                }
            }
        }
    }

    zoomIn() {
        if (this.currentZoom + this.zoomStep <= this.maxZoom) {
            this.currentZoom = parseFloat((this.currentZoom + this.zoomStep).toFixed(1));
            this.applyZoom();
        }
    }

    zoomOut() {
        if (this.currentZoom - this.zoomStep >= this.minZoom) {
            this.currentZoom = parseFloat((this.currentZoom - this.zoomStep).toFixed(1));
            this.applyZoom();
        }
    }

    applyZoom() {
        if (this.cameraTrack && this.cameraTrack.getCapabilities?.().zoom) {
            // Native zoom
            this.cameraTrack.applyConstraints({ advanced: [{ zoom: this.currentZoom }] })
                .catch(error => console.error('Native zoom failed:', error));
        } else {
            // Fallback: CSS zoom
            const video = this.template.querySelector('.camera-view');
            if (video) {
                video.style.transform = `scale(${this.currentZoom})`;
            }
        }
    }

    get zoomDisplay() {
        return this.currentZoom ? `${this.currentZoom.toFixed(1)}x` : '1.0x';
    }



    flashOn = false;

    toggleFlash() {
        if (!this.cameraTrack || !this.torchSupported) return;

        this.flashOn = !this.flashOn;
        this.cameraTrack.applyConstraints({ advanced: [{ torch: this.flashOn }] })
            .catch(error => {
                console.error('Torch toggle failed', error);
                this.flashOn = !this.flashOn; 
            });
    }

    get flashLabel() {
        return this.flashOn ? 'Flash On' : 'Flash Off';
    }

    get isFlashButtonDisabled() {
        return !this.torchSupported;
    }

    get flashIconName() {
        return this.flashOn ? 'standard:custom_notification' : 'utility:fallback';
    }




}