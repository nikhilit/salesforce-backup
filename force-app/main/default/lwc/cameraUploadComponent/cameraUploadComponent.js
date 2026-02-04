/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 22-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   20-05-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { api, LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningAlert from 'lightning/alert';
import FORM_FACTOR from '@salesforce/client/formFactor';
export default class CameraUploadComponent extends LightningElement {

    @api disabled = false;

    @api lowQuality = false; // When true, optimizes for smaller file size; when false, captures high-res images

    @track steps = [];
    @track showCamera = false;
    @track cameraLoading = false;
    currentStepId = null;

    cameraStream = null;
    pictureTaken = false;
    capturedBase64 = '';
    rotationAngle = 0; // Track rotation for preview
    isSaving = false; // Track save operation
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

    desktop = true;
    connectedCallback() {
        if (FORM_FACTOR === 'Large') {
            this.desktop = true;
        } else {
            this.desktop = false;
        }
        const ua = navigator.userAgent;
        this.isIOS = /iPad|iPhone|iPod/.test(ua) && !window.MSStream;
        // window.addEventListener('orientationchange', () => {
        //     console.log('Orientation changed:', window.orientation);
        // });
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
        this.rotationAngle = 0;
        this.cameraLoading = true;
        this.cameraErrorMessage = null;
        this.currentZoom = 1;
        this.retryAttempts = 0; // Reset retry counter
        
        // Stop any existing camera stream first
        this.stopCamera();
        
        this.showCamera = true;
        this.showModel(this.showCamera);
        
        // Wait for DOM to render before starting camera
        setTimeout(() => this.startCamera(), 500);
    }

    showModel(show) {
        var modelDOM = this.template.querySelector('.camera-wrapper');
        if (show) {
            if (this.desktop) {
                modelDOM.classList.add('slds-fade-in-open');
            } else {
                modelDOM.classList.add('show-camera-page');
                modelDOM.classList.remove('hide-camera-page');
            }
        } else {
            if (this.desktop) {
                modelDOM.classList.remove('slds-fade-in-open');
            } else {
                modelDOM.classList.remove('show-camera-page');
                modelDOM.classList.add('hide-camera-page');
            }
        }
    }

    cameraErrorMessage;
    startCamera() {
        this.cameraErrorMessage = null;
        const video = this.template.querySelector('.camera-view');

        // Validate video element exists
        if (!video) {
            console.error('Video element not found in DOM');
            this.cameraErrorMessage = 'Camera interface not ready. Please try again.';
            this.cameraLoading = false;
            setTimeout(() => this.retryCamera(), 1000);
            return;
        }

        if (this.cameraStream) {
            video.srcObject = this.cameraStream;
            video.play().then(() => {
                this.cameraLoading = false;
            }).catch(err => {
                console.error('Video play error:', err);
                this.cameraLoading = false;
            });
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
                    ideal: this.frontCamera ? "user" : "environment"
                },
                width: { ideal: this.lowQuality ? 1920 : 3264 },  // Optimized (Full HD) or high-res (8MP)
                height: { ideal: this.lowQuality ? 1440 : 2448 }, // Maintains 4:3 aspect ratio
                aspectRatio: { ideal: 4 / 3 }, // Photo mode aspect ratio
            },  // back camera
            audio: false
        };

        navigator.mediaDevices.getUserMedia(constraints)
            .then(stream => {
                this.cameraStream = stream;
                video.srcObject = stream;

                // Ensure video plays and handle loading state
                video.play()
                    .then(() => {
                        this.cameraLoading = false;
                        console.log('Camera started successfully');
                    })
                    .catch(playErr => {
                        console.error('Video play failed:', playErr);
                        this.cameraLoading = false;
                        this.cameraErrorMessage = 'Failed to start camera preview. Please try again.';
                    });

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
                console.warn('Camera with ideal constraints failed, trying basic constraints', err);
                
                // Fallback 1: Try with basic facingMode (required instead of ideal)
                const fallbackConstraints = {
                    video: {
                        facingMode: this.frontCamera ? "user" : "environment"
                    },
                    audio: false
                };
                
                navigator.mediaDevices.getUserMedia(fallbackConstraints)
                    .then(fallbackStream => {
                        this.cameraStream = fallbackStream;
                        video.srcObject = fallbackStream;
                        
                        const [track] = fallbackStream.getVideoTracks();
                        this.cameraTrack = track;
                        const capabilities = track.getCapabilities();
                        
                        // Setup basic features for fallback camera
                        if (capabilities.zoom) {
                            this.minZoom = capabilities.zoom.min;
                            this.maxZoom = capabilities.zoom.max;
                            this.currentZoom = capabilities.zoom.min;
                        } else {
                            this.minZoom = 1;
                            this.maxZoom = 3;
                            this.currentZoom = 1;
                        }
                        
                        this.torchSupported = capabilities.torch || false;
                        this.flashOn = false;
                        
                        video.play()
                            .then(() => {
                                this.cameraLoading = false;
                                console.log('Fallback camera started successfully');
                            })
                            .catch(playErr => {
                                console.error('Fallback video play failed:', playErr);
                                this.cameraLoading = false;
                                this.cameraErrorMessage = 'Failed to start camera preview.';
                            });
                    })
                    .catch(error => {
                        console.error("Camera access failed:", error);
                        this.cameraLoading = false;
                        
                        if (error.name === 'NotAllowedError' || error.name === 'PermissionDeniedError') {
                            this.cameraErrorMessage = 'Camera permission denied. Please allow camera access in browser settings.';
                        } else if (error.name === 'NotFoundError' || error.name === 'DevicesNotFoundError') {
                            this.cameraErrorMessage = 'No camera found on this device.';
                        } else if (error.name === 'NotReadableError' || error.name === 'TrackStartError') {
                            this.cameraErrorMessage = 'Camera is already in use by another application. Please close other apps and retry.';
                        } else {
                            this.cameraErrorMessage = 'Unable to access camera. Please try again.';
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

    retryAttempts = 0;
    maxRetries = 3;

    retryCamera() {
        if (this.retryAttempts < this.maxRetries) {
            this.retryAttempts++;
            console.log(`Retrying camera (attempt ${this.retryAttempts}/${this.maxRetries})`);
            
            // Stop any existing stream before retry
            this.stopCamera();
            
            this.cameraLoading = true;
            this.cameraErrorMessage = null;
            
            // Increase delay with each retry
            const delay = 500 * this.retryAttempts;
            setTimeout(() => this.startCamera(), delay);
        } else {
            this.cameraErrorMessage = 'Unable to start camera after multiple attempts. Please close and try again.';
            this.cameraLoading = false;
            this.retryAttempts = 0;
        }
    }

    // takePicture() {
    //     const video = this.template.querySelector('.camera-view');
    //     const canvas = this.template.querySelector('.camera-canvas');

    //     canvas.width = video.videoWidth;
    //     canvas.height = video.videoHeight;
    //     const ctx = canvas.getContext('2d');
    //     ctx.drawImage(video, 0, 0);

    //     this.capturedBase64 = canvas.toDataURL('image/jpeg');
    //     this.pictureTaken = true;
    // }

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


    //     takePicture() {
    //     const video = this.template.querySelector('.camera-view');
    //     const canvas = this.template.querySelector('.camera-canvas');
    //     const context = canvas.getContext('2d');

    //     const scale = this.currentZoom || 1;
    //     let vw = video.videoWidth;
    //     let vh = video.videoHeight;

    //     // Force portrait output
    //     if (vw > vh) {
    //         // Landscape → rotate to portrait
    //         canvas.width = vh;
    //         canvas.height = vw;

    //         context.save();
    //         context.translate(canvas.width / 2, canvas.height / 2);
    //         context.rotate(-90 * Math.PI / 180);

    //         if (this.cameraTrack && this.cameraTrack.getCapabilities()?.zoom) {
    //             context.drawImage(video, -vw / 2, -vh / 2, vw, vh);
    //         } else {
    //             const scaledWidth = vw / scale;
    //             const scaledHeight = vh / scale;
    //             const dx = (vw - scaledWidth) / 2;
    //             const dy = (vh - scaledHeight) / 2;

    //             context.drawImage(
    //                 video,
    //                 dx, dy, scaledWidth, scaledHeight,
    //                 -vw / 2, -vh / 2, vw, vh
    //             );
    //         }
    //         context.restore();
    //     } else {
    //         // Already portrait → draw normally
    //         canvas.width = vw;
    //         canvas.height = vh;
    //         context.drawImage(video, 0, 0, vw, vh);
    //     }

    //     this.capturedBase64 = canvas.toDataURL('image/jpeg', 0.8);
    //     this.pictureTaken = true;
    // }

    getDeviceOrientation() {
        if (window.matchMedia("(orientation: portrait)").matches) {
            return 'portrait';
        } else if (window.matchMedia("(orientation: landscape)").matches) {
            return 'landscape';
        }
        return 'unknown';
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

    @track angleDisplay = 0;
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
        // try {
        //     if (window.screen.orientation && typeof window.screen.orientation.angle === 'number') {
        //         angle = window.screen.orientation.angle;
        //     } else if (window.matchMedia('(orientation: landscape)').matches) {
        //         angle = 90; // assume landscape-left
        //     }
        // } catch (e) {
        //     // no orientation API support, default portrait
        //     angle = 0;
        // }

        // Normalize for iOS Safari which doesn’t use the angle field
        // if (angle === -90) angle = 270;

        // --- Set canvas based on orientation ---
        if (angle === 90 || angle === 270) {
            canvas.width = vh;
            canvas.height = vw;
        } else {
            canvas.width = vw;
            canvas.height = vh;
        }
        this.angleDisplay = angle;

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
        // Use optimized quality (0.7) or high quality (0.9) based on setting
        const quality = this.lowQuality ? 0.7 : 0.9;
        this.capturedBase64 = canvas.toDataURL('image/jpeg', quality);
        this.pictureTaken = true;
    }

    retakePicture() {
        this.pictureTaken = false;
        this.capturedBase64 = '';
        this.rotationAngle = 0;
        setTimeout(() => this.startCamera(), 300);
    }

    rotateImage() {
        this.rotationAngle = (this.rotationAngle + 90) % 360;
        console.log('Rotate button clicked, new angle:', this.rotationAngle);
    }

    get imageRotationStyle() {
        return `transform: rotate(${this.rotationAngle}deg); transition: transform 0.3s ease;`;
    }

    get desktopImageStyle() {
        return `width: 100%; height: auto; transform: rotate(${this.rotationAngle}deg); transition: transform 0.3s ease;`;
    }

    applyRotationToImage() {
        console.log('=== APPLY ROTATION START ===');

        return new Promise((resolve, reject) => {
            const canvas = this.template.querySelector('.camera-canvas');

            if (!canvas) {
                console.error('Canvas element not found!');
                resolve(this.capturedBase64);
                return;
            }

            console.log('Canvas found, loading image...');
            const img = new Image();

            img.onload = () => {
                console.log(`Image loaded: ${img.width}x${img.height}`);

                try {
                    const ctx = canvas.getContext('2d');
                    const vw = img.width;
                    const vh = img.height;

                    // Set canvas dimensions based on rotation (same as takePicture)
                    if (this.rotationAngle === 90 || this.rotationAngle === 270) {
                        canvas.width = vh;
                        canvas.height = vw;
                        console.log(`Canvas swapped: ${canvas.width}x${canvas.height}`);
                    } else {
                        canvas.width = vw;
                        canvas.height = vh;
                        console.log(`Canvas normal: ${canvas.width}x${canvas.height}`);
                    }

                    // Clear and prepare canvas
                    ctx.clearRect(0, 0, canvas.width, canvas.height);
                    ctx.save();

                    // Apply rotation transformation (same logic as takePicture)
                    switch (this.rotationAngle) {
                        case 90:
                            ctx.translate(canvas.width, 0);
                            ctx.rotate((90 * Math.PI) / 180);
                            break;
                        case 180:
                            ctx.translate(canvas.width, canvas.height);
                            ctx.rotate(Math.PI);
                            break;
                        case 270:
                            ctx.translate(0, canvas.height);
                            ctx.rotate((270 * Math.PI) / 180);
                            break;
                        default:
                            break;
                    }

                    // Draw the image
                    ctx.drawImage(img, 0, 0, vw, vh);
                    ctx.restore();

                    console.log('Generating rotated base64...');
                    const quality = this.lowQuality ? 0.7 : 0.9;
                    const rotatedBase64 = canvas.toDataURL('image/jpeg', quality);

                    console.log(`New base64 length: ${rotatedBase64.length}`);
                    console.log('=== ROTATION COMPLETE ===');
                    resolve(rotatedBase64);
                } catch (error) {
                    console.error(`Error during rotation: ${error.message}`);
                    reject(error);
                }
            };

            img.onerror = (error) => {
                console.error('Image failed to load');
                resolve(this.capturedBase64);
            };

            img.src = this.capturedBase64;
        });
    }

    async savePicture() {
        try {
            this.isSaving = true;
            const fileName = 'camera-image.jpg';

            console.log('=== SAVE START ===');
            console.log(`Rotation angle: ${this.rotationAngle}°`);
            console.log(`Original base64 (first 100 chars): ${this.capturedBase64?.substring(0, 100)}`);
            console.log(`Original base64 length: ${this.capturedBase64?.length}`);

            // Apply rotation to get final image
            const finalBase64 = await this.applyRotationToImage();
            console.log(`After rotation base64 (first 100 chars): ${finalBase64?.substring(0, 100)}`);
            console.log(`After rotation base64 length: ${finalBase64?.length}`);
            console.log(`Base64 changed: ${this.capturedBase64 !== finalBase64}`);
            console.log('Updating step with image...');

            this.updateStepWithImage(this.currentStepId, finalBase64, fileName);
            console.log('Image saved successfully!');

            this.closeCamera();
            this.isSaving = false;
        } catch (error) {
            console.error('Error saving picture:', error);
            this.isSaving = false;
            this.showToastMessage('Error', 'Failed to save image. Please try again.', 'error');
        }
    }

    closeCamera() {
        // this.stopCamera();
        this.showCamera = false;
        this.showModel(this.showCamera);
        this.capturedBase64 = '';
        this.pictureTaken = false;
        this.rotationAngle = 0;
        this.currentStepId = null;
        this.cameraLoading = false;
        this.retryAttempts = 0;
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
        // await LightningAlert.open({
        //     message: message,
        //     theme: variant,
        //     label: title,
        // });
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

    async toggleCamera() {
        try {
            // Stop current camera stream if active
            this.stopCamera();

            // Flip camera mode
            this.frontCamera = !this.frontCamera;
            this.cameraLoading = true;

            // Restart camera with the new facing mode
            await this.startCamera();

            // Optional: give user feedback
            // this.showToastMessage(
            //     'Camera Switched',
            //     this.frontCamera ? 'Front camera activated' : 'Back camera activated',
            //     'info',
            //     'pester'
            // );
        } catch (error) {
            console.error('Error toggling camera:', error);
            this.showToastMessage('Error', 'Unable to switch camera', 'error');
        }
    }

}