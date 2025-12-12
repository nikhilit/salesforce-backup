import { LightningElement, wire } from 'lwc';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import MOVIE_CHANNEL from '@salesforce/messageChannel/movieChannel__c';

export default class MovieDetail extends LightningElement {
    movieId; // Stores the selected movie ID
    subscription = null; // Keeps track of the subscription to the LMS
    loadComponent = false; // Flag to indicate if the component is loaded
    MovieDetails={};

    @wire(MessageContext)
    messageContext;

    // Subscribe to the LMS channel when the component is connected
    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    // Unsubscribe from the LMS channel when the component is disconnected
    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    // Method to subscribe to the message channel
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                MOVIE_CHANNEL,
                (message) => this.handleMessage(message)
            );
        }
    }

    // Method to unsubscribe from the message channel
    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    // Handle messages received via the LMS
    handleMessage(message) {
        this.movieId = message.movieId; // Set the movie ID from the message
        console.log('Received Movie ID:', this.movieId); // Log the received ID
        this.fetchMovieDetails(this.movieId);
    }


    handleMessage(message) {
        this.movieId = message.movieId; // Set the movie ID from the message
        console.log('Received Movie ID:', this.movieId); // Log the received ID
        this.fetchMovieDetails(this.movieId); // Pass movieId as a parameter
    }
    
    async fetchMovieDetails(movieId) {
        const url = `https://www.omdbapi.com/?i=${movieId}&plot=full&apikey=8f7c5421`;
        try {
            const res = await fetch(url);
            const data = await res.json();
            console.log("Movie Details", data); // Log the fetched movie details
            this.loadComponent = true;
            this.MovieDetails = data;
        } catch (error) {
            console.error("Error fetching movie details:", error);
        }
    }
    
}