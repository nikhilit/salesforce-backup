import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getLocationService } from 'lightning/mobileCapabilities';
import updateCheckInLocation from '@salesforce/apex/WorkOrderLocationController.updateCheckInLocation';
import updateCheckOutLocation from '@salesforce/apex/WorkOrderLocationController.updateCheckOutLocation';

export default class CheckInLocation extends LightningElement {
    @api recordId;
    myLocationService;
    currentLocation;
    locationButtonDisabled = false;
    requestInProgress = false;
    locationFetched = false;

    connectedCallback() {
        this.myLocationService = getLocationService();
        if (!this.myLocationService || !this.myLocationService.isAvailable()) {
            this.locationButtonDisabled = true;
            console.warn('Location service not available — works only in Salesforce mobile app.');
        }
    }

    handleGetCurrentLocationClick() {
        this.currentLocation = null;
        this.locationFetched = false;

        if (this.myLocationService && this.myLocationService.isAvailable()) {
            this.requestInProgress = true;

            this.myLocationService
                .getCurrentPosition({ enableHighAccuracy: true })
                .then((result) => {
                    console.log('GPS Result:', JSON.stringify(result));
                    this.currentLocation = result;
                    this.locationFetched = true;
                    this.showToast('Location Detected', 'Location determined successfully.', 'success');
                })
                .catch((error) => {
                    console.error('Error fetching location:', JSON.stringify(error));
                    this.showToast('Location Error', JSON.stringify(error), 'error');
                })
                .finally(() => {
                    this.requestInProgress = false;
                });
        } else {
            this.showToast('Not Available', 'Try again from a mobile device with GPS.', 'error');
        }
    }

    handleCheckIn() {
        if (!this.locationFetched) {
            this.showToast('No Location', 'Please detect location first.', 'warning');
            return;
        }

        const { latitude, longitude } = this.currentLocation.coords;
        console.log('Saving Check-In:', latitude, longitude);

        updateCheckInLocation({ workOrderId: this.recordId, latitude, longitude })
            .then(() => this.showToast('Check-In Success', 'Location saved successfully.', 'success'))
            .catch((err) => this.showToast('Error', err.body?.message || JSON.stringify(err), 'error'));
    }

    handleCheckOut() {
        if (!this.locationFetched) {
            this.showToast('No Location', 'Please detect location first.', 'warning');
            return;
        }

        const { latitude, longitude } = this.currentLocation.coords;
        console.log('Saving Check-Out:', latitude, longitude);

        updateCheckOutLocation({ workOrderId: this.recordId, latitude, longitude })
            .then(() => this.showToast('Check-Out Success', 'Location saved successfully.', 'success'))
            .catch((err) => this.showToast('Error', err.body?.message || JSON.stringify(err), 'error'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get currentLocationAsString() {
        return this.currentLocation
            ? `Lat: ${this.currentLocation.coords.latitude}, Long: ${this.currentLocation.coords.longitude}`
            : '';
    }

    get currentLocationAsMarker() {
        return this.currentLocation
            ? [
                  {
                      location: {
                          Latitude: this.currentLocation.coords.latitude,
                          Longitude: this.currentLocation.coords.longitude,
                      },
                      title: 'My Location',
                  },
              ]
            : [];
    }
}