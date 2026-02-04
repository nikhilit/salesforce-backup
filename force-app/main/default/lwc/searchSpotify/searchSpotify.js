import { LightningElement } from 'lwc';
import searchWithSpotify from '@salesforce/apex/SpotifyIntegration.searchWithSpotify';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SearchSpotify extends LightningElement {
    searchTracker;
    displyResult = false;
    trackData = '';
    trackUrl = '';
    artistNames = '';

    changeHandler(event) {
        this.searchTracker = event.target.value;
    }

    async searchHandler() {
        let isValid = this.validateInput();
        if (isValid) {
            try {
                let responseString = await searchWithSpotify({
                    trackName: this.searchTracker
                });

                let response = JSON.parse(responseString);

                // Validate the API response structure
                if (response.tracks && response.tracks.items && response.tracks.items.length > 0) {
                    const track = response.tracks.items[0];
                    this.trackData = track || 'Unknown Track';
                    // this.trackUrl = track.external_urls?.spotify || 'No URL Available';
                    this.trackUrl = this.trackData.album.images[0].url || 'No Image Available';
                    this.artistNames = track.artists.map((artist) => artist.name).join(', ') || 'Unknown Artists';
                    this.displyResult = true;
                } else {
                    this.showToast('No Results', 'No track data found for the given search term.', 'warning');
                    this.displyResult = false;
                }

                console.log('Response:', response);
            } catch (error) {
                console.error(error);
                this.showToast('Error', 'Something went wrong', 'error');
            }
        }
    }

    validateInput() {
        let isValid = true;
        let elements = this.template.querySelectorAll("lightning-input");
        elements.forEach((element) => {
            if (!element.checkValidity()) {
                element.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    renderedCallback(){
        this.template
        .querySelector('lightning-input')
        .addEventListener('keydown', (event)=>{
           //alert('Key: '+ event.key + ', Code: ' + event.code);
           if(event.key === 'Enter'){
               this.searchHandler();
           }
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    get artistNames() {
        if (this.trackData.artists) {
            return this.trackData.artists.map(artist => artist.name).join(', ');
        }
        return 'No Artists Found';
    }
}