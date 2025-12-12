import { LightningElement, api } from 'lwc';

export default class LoadMealResults extends LightningElement {
    @api mealResult = []; // Array of meals passed from parent
    selectedMeal; // Stores the selected meal details
    showModal = false; // Controls modal visibility

    // Getter to check if meals exist
    get checkMeals() {
        return Array.isArray(this.mealResult) && this.mealResult.length > 0;
    }

    // Handles the recipe event triggered from meal-tile component
    recepieHandler(event) {
        const selectedMealId = event.detail; // Ensure this matches the event detail sent
        console.log('Selected Meal ID:', selectedMealId);

        // Find the selected meal in the mealResult array
        this.selectedMeal = this.mealResult.find(
            (meal) => meal.idMeal === selectedMealId
        );
        console.log('Selected Meal:', this.selectedMeal);

        // Display the modal
        this.showModal = true;
    }

    // Closes the modal when triggered
    closeHandler() {
        this.showModal = false;
    }
}