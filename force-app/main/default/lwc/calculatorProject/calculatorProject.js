import { LightningElement, track } from 'lwc';

export default class CalculatorProject extends LightningElement {
    @track numberOne = "";
    @track numberTwo = "";
    @track result = 0;

    // Handlers for input changes
    handleNumberChangeOne(event) {
        this.numberOne = event.target.value;
    }

    handleNumberChangeTwo(event) {
        this.numberTwo = event.target.value;
    }

    // Calculation Handlers
    handleAddition() {
        this.result = this.calculate('add');
    }

    handleSubtraction() {
        this.result = this.calculate('sub');
    }

    handleMultiplication() {
        this.result = this.calculate('mul');
    }

    handleDivision() {
        this.result = this.calculate('div');
    }

    // Core calculation logic
    calculate(operation) {
        const num1 = parseFloat(this.numberOne);
        const num2 = parseFloat(this.numberTwo);

        // Simple validation
        if (isNaN(num1) || isNaN(num2)) {
            return 'Please enter valid numbers';
        }

        switch (operation) {
            case 'add':
                return num1 + num2;
            case 'sub':
                return num1 - num2;
            case 'mul':
                return num1 * num2;
            case 'div':
                return num2 !== 0 ? (num1 / num2).toFixed(2) : 'Cannot divide by 0';
            default:
                return 0;
        }
    }
}


// import { LightningElement, track} from 'lwc';

// export default class CalculatorProject extends LightningElement {
// @track numberone="";
// @track numbertwo="";
// @track result=0;

// changeHandlerNumberOne(event) {
//     this.numberone = event.target.value;
// }

// changeHandlerNumberTwo(event) {
//     this.numbertwo = event.target.value;
// }


//     addHandler(event) {
//     this.result = parseInt(this.numberone) + parseInt(this.numbertwo);
//     }
//     subHandler(event) {
//     this.result = parseInt(this.numberone) - parseInt(this.numbertwo);
//     }
//     mulHandler(event) {
//     this.result = parseInt(this.numberone) * parseInt(this.numbertwo);
//         }
//     divHandler(event) {
//     this.result = parseInt(this.numberone) / parseInt(this.numbertwo);
// }
// changeHandler(event){
// let{name, value}=event.targer;
// if(name==="number1"){
//     this.numberone = value;
// }
// else if(name==="number2"){
//     this.numbertwo = value;
// }
// }
// calculateInput(event){
// let labelelement = event.target.label;
// if(labelelement==="add")
// {
//     this.result = parseInt(this.numberone) + parseInt(this.numbertwo);
// }
// else if(labelelement==="sub")
// {
//     this.result = parseInt(this.numberone) - parseInt(this.numbertwo);
// }
// else if(labelelement==="mul")
// {
// this.result = parseInt(this.numberone) * parseInt(this.numbertwo);
// }

// else if(labelelement==="div")
// {
// this.result = parseInt(this.numberone) / parseInt(this.numbertwo);
// }
// }