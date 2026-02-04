import { LightningElement, api } from 'lwc';

export default class MovieTile extends LightningElement {
    @api movie; // Movie object passed from parent
    @api selectedMovieId; // ID of the selected movie

    clickHandler() {
        // Emit the imdbID as part of the event detail
        const event = new CustomEvent('selectmovie', {
            detail: this.movie.imdbID
        });
        this.dispatchEvent(event);
    }

    get tileSelected() {
        // Dynamically set CSS class based on selection
        return this.selectedMovieId === this.movie.imdbID ? 'tile selected' : 'tile';
    }
}