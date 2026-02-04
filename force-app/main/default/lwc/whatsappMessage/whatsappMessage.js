import { LightningElement, api, wire } from 'lwc';
import getContactDetails from '@salesforce/apex/WhatsAppController.getContactDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class WhatsappMessage extends LightningElement {
    @api recordId; // Record Id of the Contact
    contact = {}; // Holds contact details
    message = ''; // Holds the message entered by the user

    // Wire service to fetch contact details
    @wire(getContactDetails, { contactId: '$recordId' })
    wiredContact({ error, data }) {
        if (data) {
            this.contact = data;
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to fetch contact details',
                    variant: 'error'
                })
            );
        }
    }

    // Update the message as the user types
    handleMessageChange(event) {
        this.message = event.target.value;
    }

    // Handle the WhatsApp button click with confirmation before sending
    handleSendWhatsApp() {
        if (!this.contact.MobilePhone) {
            // Show error if mobile phone is missing
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'The contact does not have a mobile phone number.',
                    variant: 'error'
                })
            );
            return;
        }

        // Show a confirmation before sending the message
        const isConfirmed = confirm('Are you sure you want to send this message via WhatsApp?');
        if (!isConfirmed) {
            return; // Stop execution if the user cancels
        }

        // Build the WhatsApp URL
        const encodedMessage = encodeURIComponent(`Hello ${this.contact.Name}, ${this.message}`);
        const whatsappUrl = `https://wa.me/91${this.contact.MobilePhone}?text=${encodedMessage}`;

        // Open WhatsApp in a new tab
        window.open(whatsappUrl, '_blank');

        // Show a success notification
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Message sent successfully via WhatsApp.',
                variant: 'success',
            })
        );

        // Close the card by dispatching a custom event
        this.closeCard();
    }

    // Close the card
    closeCard() {
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
}