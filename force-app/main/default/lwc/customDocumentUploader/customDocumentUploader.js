import { LightningElement, api, wire } from 'lwc';
import getCaseDocuments from '@salesforce/apex/CustomDocumentUploadController.getCaseDocuments';
import getPreviewUrl from '@salesforce/apex/CustomDocumentUploadController.getPreviewUrl';

export default class CustomDocumentUploader extends LightningElement {
    @api recordId;

    documents = [];
    currentDocument;
    previewUrl;
    showPreviewModal = false;
    rotation = 0;
    contentDimensions = { width: 0, height: 0 };
    naturalDimensions = { width: 0, height: 0 };

    /* ================= WIRE ================= */
    @wire(getCaseDocuments, { caseId: '$recordId' })
    wiredDocs({ data, error }) {
        if (data) {
            console.log('✅ Documents loaded:', data.length);
            this.documents = data;
        }
        if (error) {
            console.error('❌ Apex error →', error);
        }
    }

    /* ================= GETTERS ================= */
    get hasDocuments() {
        return this.documents.length > 0;
    }

    get fileExt() {
        return this.currentDocument?.FileExtension?.toLowerCase();
    }

    get isImage() {
        return ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'].includes(this.fileExt);
    }

    get currentDocumentTitle() {
        return this.currentDocument?.Title || 'Document Preview';
    }

    get isRotatedState() {
        return this.rotation === 90 || this.rotation === 270;
    }

    // Scroll container style
    get scrollContainerStyle() {
        if (this.isRotatedState) {
            return `
                display: flex;
                align-items: center;
                justify-content: center;
                padding: 40px;
            `;
        }
        return '';
    }

    // Content container style (rotates everything)
    get contentContainerStyle() {
        let width = '100%';
        let height = '100%';
        
        // For rotated state, swap dimensions if we have natural dimensions
        if (this.isRotatedState && this.naturalDimensions.width && this.naturalDimensions.height) {
            if (this.isImage) {
                // For images, use natural dimensions swapped
                width = `${this.naturalDimensions.height}px`;
                height = `${this.naturalDimensions.width}px`;
            } else {
                // For PDFs/iframes, use larger dimensions
                width = '1200px';
                height = '900px';
            }
        }
        
        return `
            transform: rotate(${this.rotation}deg);
            transform-origin: center center;
            transition: transform 0.3s ease;
            width: ${width};
            height: ${height};
            display: flex;
            align-items: center;
            justify-content: center;
            background: white;
            box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        `;
    }

    // Content style (images and iframes)
    get contentStyle() {
        let style = '';
        
        if (this.isImage) {
            // Image styling
            if (this.isRotatedState) {
                // For rotated images, swap dimensions
                style = `
                    max-width: 100%;
                    max-height: 100%;
                    width: auto;
                    height: auto;
                    object-fit: contain;
                `;
            } else {
                style = `
                    max-width: 100%;
                    max-height: 100%;
                    width: auto;
                    height: auto;
                    object-fit: contain;
                `;
            }
        } else {
            // PDF/iframe styling
            if (this.isRotatedState) {
                // For rotated PDFs, we need to handle dimensions differently
                style = `
                    width: 100%;
                    height: 100%;
                    border: none;
                    background: white;
                    transform: rotate(0deg); /* Don't rotate iframe content */
                `;
            } else {
                style = `
                    width: 100%;
                    height: 100%;
                    border: none;
                    background: white;
                `;
            }
        }
        
        return style;
    }

    /* ================= ACTIONS ================= */
    openPreview(event) {
        const docId = event.currentTarget.dataset.id;
        console.log('🖱 Clicked:', docId);

        this.currentDocument = this.documents.find(
            d => d.ContentDocumentId === docId
        );

        console.log('📄 Selected doc →', this.currentDocument);
        if (!this.currentDocument) return;

        this.rotation = 0;
        this.naturalDimensions = { width: 0, height: 0 };

        getPreviewUrl({
            contentVersionId: this.currentDocument.LatestPublishedVersionId,
            fileExtension: this.currentDocument.FileExtension
        })
        .then(url => {
            console.log('🔗 Preview URL →', url);
            this.previewUrl = url;
            this.showPreviewModal = true;
            
            // Reset after modal opens
            setTimeout(() => this.resetScroll(), 300);
        })
        .catch(err => {
            console.error('❌ Preview error →', err);
            const baseUrl = window.location.origin;
            this.previewUrl = baseUrl + 
                '/sfc/servlet.shepherd/version/download/' + 
                this.currentDocument.LatestPublishedVersionId;
            this.showPreviewModal = true;
            
            setTimeout(() => this.resetScroll(), 300);
        });
    }

    closePreview() {
        this.showPreviewModal = false;
        this.previewUrl = null;
        this.currentDocument = null;
        this.rotation = 0;
        this.naturalDimensions = { width: 0, height: 0 };
    }

    rotateLeft() {
        this.rotation = (this.rotation - 90 + 360) % 360;
        this.handleRotation();
    }

    rotateRight() {
        this.rotation = (this.rotation + 90) % 360;
        this.handleRotation();
    }

    handleRotation() {
        // Force re-render
        const tempUrl = this.previewUrl;
        this.previewUrl = null;
        setTimeout(() => {
            this.previewUrl = tempUrl;
            this.resetScroll();
        }, 10);
    }

    // Handle image load to get natural dimensions
    handleImageLoad(event) {
        const img = event.target;
        this.naturalDimensions = {
            width: img.naturalWidth,
            height: img.naturalHeight
        };
        console.log('📏 Image natural dimensions:', this.naturalDimensions);
        this.resetScroll();
    }

    // Handle iframe load
    handleIframeLoad() {
        console.log('📄 Iframe loaded');
        // For PDFs, we don't have natural dimensions, so use defaults
        if (!this.isImage) {
            this.naturalDimensions = { width: 800, height: 600 }; // Default PDF size
        }
        this.resetScroll();
    }

    resetScroll() {
        setTimeout(() => {
            const scrollContainer = this.template.querySelector('.scrollable-outer');
            if (scrollContainer) {
                // Reset scroll
                scrollContainer.scrollTop = 0;
                scrollContainer.scrollLeft = 0;
                
                // Center content if rotated
                if (this.isRotatedState) {
                    setTimeout(() => {
                        const containerWidth = scrollContainer.clientWidth;
                        const containerHeight = scrollContainer.clientHeight;
                        const contentWidth = scrollContainer.scrollWidth;
                        const contentHeight = scrollContainer.scrollHeight;
                        
                        scrollContainer.scrollLeft = Math.max(0, (contentWidth - containerWidth) / 2);
                        scrollContainer.scrollTop = Math.max(0, (contentHeight - containerHeight) / 2);
                    }, 100);
                }
            }
        }, 150);
    }
}