import { LightningElement } from 'lwc';
import reverseGeocode from '@salesforce/apex/GeoService.reverseGeocode';

export default class GeoServiceLWC extends LightningElement {
    lat;
    lng;
    address;

    handleLatChange(event) {
        this.lat = event.target.value;
    }

    handleLngChange(event) {
        this.lng = event.target.value;
    }

    handleSubmit() {
        console.log('lat: ',this.lat);
        console.log('lng: ',this.lng);
        reverseGeocode({ lat: parseFloat(this.lat), lng: parseFloat(this.lng) })
            .then(result => {
                this.address = result;
                console.log('address',this.address);
            })
            .catch(error => {
                console.error(error);
                this.address = 'Error fetching address';
            });
    }
}