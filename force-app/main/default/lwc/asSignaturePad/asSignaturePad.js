import { LightningElement, api } from 'lwc';

export default class AsSignaturePad extends LightningElement {
    canvas;
    ctx;
    drawing = false;
    hasDrawn = false;

    renderedCallback() {
        if (!this.canvas) {
            this.canvas = this.template.querySelector('canvas');
            this.canvas.width = 400;
            this.canvas.height = 200;
            this.ctx = this.canvas.getContext('2d');
            this.ctx.strokeStyle = 'black';
            this.ctx.lineWidth = 2;

            this.canvas.addEventListener('mousedown', this.startDraw.bind(this));
            this.canvas.addEventListener('mouseup', this.endDraw.bind(this));
            this.canvas.addEventListener('mouseout', this.endDraw.bind(this));
            this.canvas.addEventListener('mousemove', this.draw.bind(this));
            this.canvas.addEventListener('touchstart', this.startDraw.bind(this));
            this.canvas.addEventListener('touchend', this.endDraw.bind(this));
            this.canvas.addEventListener('touchmove', this.drawTouch.bind(this));
        }
    }

    startDraw(e) {
        this.drawing = true;
        this.hasDrawn = true;
        this.ctx.beginPath();
        this.ctx.moveTo(this.getX(e), this.getY(e));
    }

    endDraw() {
        this.drawing = false;
    }

    draw(e) {
        if (!this.drawing) return;
        this.ctx.lineTo(this.getX(e), this.getY(e));
        this.ctx.stroke();
    }

    drawTouch(e) {
        e.preventDefault();
        const touch = e.touches[0];
        this.draw({ clientX: touch.clientX, clientY: touch.clientY });
    }

    getX(e) {
        return e.clientX - this.canvas.getBoundingClientRect().left;
    }

    getY(e) {
        return e.clientY - this.canvas.getBoundingClientRect().top;
    }

    handleClear() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        this.hasDrawn = false;
    }

    @api getSignatureBase64() {
        return this.canvas.toDataURL('image/png').split(',')[1]; // return base64 (no prefix)
    }

    @api isEmpty() {
        return !this.hasDrawn;
    }
}