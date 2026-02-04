import { LightningElement, api } from 'lwc';

export default class PlaySoundComponent extends LightningElement {
    @api soundName;

    get soundSource() {
        return `/resource/${this.soundName}`;
    }
}