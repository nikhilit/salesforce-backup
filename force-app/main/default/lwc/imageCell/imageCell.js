import { LightningElement, api } from 'lwc';
export default class ImageCell extends LightningElement {

    @api value;

    get hasImage() {
        return this.value && this.value.trim() !== '';
    }

    handleClick(event) {
        event.stopPropagation(); // prevent row selection override
        if (!this.hasImage) return;

        console.log('🔹 Cell template handler fired::' + this.value);
        this.dispatchEvent(new CustomEvent('imageclick', {
            detail: { value: this.value },
            bubbles: true,
            composed: true
        }));
    }

    hideOnError(event) {
        event.target.style.display = 'none';
    }
}