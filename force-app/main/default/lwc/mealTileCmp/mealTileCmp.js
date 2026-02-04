import { LightningElement, api } from 'lwc';

export default class MealTileCmp extends LightningElement {
    @api meal;

    // Dispatches the 'recepie' event with the meal ID
    recepieHandler() {
        const myCustomEvent = new CustomEvent('recepie', {
            detail: this.meal.idMeal, // Sending only the ID
        });
        this.dispatchEvent(myCustomEvent);
    }
}