import { LightningElement } from 'lwc';

export default class MealSearch extends LightningElement {
    searchMeal
    changeHandler(event)
    {
        this.searchMeal = event.target.value;
    }

    clickHandler(event)
    {
        let myCustomEvent = new CustomEvent('searchmeal',{
            detail : this.searchMeal
        })
        this.dispatchEvent(myCustomEvent)
    }
}