import { LightningElement, wire } from 'lwc';
// Import message service features required for publishing and the message channel
import { publish, MessageContext } from 'lightning/messageService';
import MOVIE_CHANNEL from '@salesforce/messageChannel/movieChannel__c';
const DELAY = 300;

export default class MovieSearch extends LightningElement {
    selectedType = '';
    selectedSearch = '';
    loading = false;
    selectedPageNo = '1';
    delayTimeout;
    searchresult = [];
    selectedMovie = '';

    @wire(MessageContext)
    messageContext;

    get typeoptions() {
        return [
            { label: 'None', value: '' },
            { label: 'Movie', value: 'movie' },
            { label: 'Series', value: 'series' },
            { label: 'Episode', value: 'episode' },
        ];
    }

    handleChange(event) {
        let { name, value } = event.target;
        this.loading = true;

        if (name === 'type') {
            this.selectedType = value;
        } else if (name === 'search') {
            this.selectedSearch = value;
        } else if (name === 'pageno') {
            this.selectedPageNo = value;
        }

        clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.searchMovie();
        }, DELAY);
    }

    async searchMovie() {
        try {
            const url = `https://www.omdbapi.com/?s=${this.selectedSearch}&type=${this.selectedType}&page=${this.selectedPageNo}&apikey=8f7c5421`;
            const res = await fetch(url);
            const data = await res.json();

            this.loading = false;

            if (data.Response === 'True') {
                this.searchresult = data.Search;
            } else {
                this.searchresult = [];
            }
        } catch (error) {
            console.error('Error fetching movie data:', error);
            this.loading = false;
            this.searchresult = [];
        }
    }

    movieSelectedHandler(event) {
        this.selectedMovie = event.detail; // Update the selected movie ID
        const payload = { movieId: event.detail }; // Use event.detail directly, which contains imdbID
    
        // Publish the message with the correct movieId
        publish(this.messageContext, MOVIE_CHANNEL, payload);
    }
    
    get displaySearchResult() {
        return this.searchresult.length > 0;
    }
}