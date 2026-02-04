import { LightningElement } from 'lwc';

export default class MealHunter extends LightningElement {

    searchResults;
    async mealSearchHandler(event)
    {
        let searchMeal = event.detail;
        console.log('search',searchMeal);


        let response = await fetch(`https://www.themealdb.com/api/json/v1/1/search.php?s=${searchMeal}`);
        let data = await response.json();
        console.log('data',data.meals);
        this.searchResults = data.meals;
    }
}