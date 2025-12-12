import { LightningElement } from 'lwc';

export default class ToDoApplication extends LightningElement {
    taskname = "";
    taskdate = null;
    incompletetask = [];
    completetask = [];

    changeHandler(event) {
        let { name, value } = event.target;
        if (name === "taskname") {
            this.taskname = value;
        } else if (name === "taskdate") {
            this.taskdate = value;
        }
    }

    resetHandler() {
        this.taskname = "";
        this.taskdate = null;
    }

    addTaskHandler() {
        //if task end is missing , yhen populate todays dats as end date
        if (!this.taskdate) {
            this.taskdate = new Date().toISOString().slice(0, 10); // Set today's date if not provided
        }

        if (this.validateTask()) {
            this.incompletetask = [...this.incompletetask, {
                taskname: this.taskname,
                taskdate: this.taskdate
            }];
            this.resetHandler();
            let sortedArray = this.sortTask(this.incompletetask);
            this.incompletetask = [...sortedArray];
            console.log("this.incompletetask", this.incompletetask);
        } else {
            alert("Task is not valid");
        }
    }

    validateTask() {
        let isValid = true;
        let element = this.template.querySelector(".taskname");
         //condition 1--- check if task is empty
         //conditio 2 -- if task name is not empty then check for duplicate

        if (!this.taskname) {
            //check if the task is empty
            isValid = false;
        } else {
            //if find method, will find an item in array it will return task item
            //if not found it will return undefined
            let taskItem = this.incompletetask.find(currItem => currItem.taskname === this.taskname && currItem.taskdate === this.taskdate);
            if (taskItem) {
                isValid = false;
                element.setCustomValidity("Task is already available");
            }
        }

        if (isValid) {
            element.setCustomValidity("");
        }

        element.reportValidity();
        return isValid;
    }

    sortTask(inputArr) {
        let sortedArray = inputArr.sort((a, b) => {
            const dateA = new Date(a.taskdate);
            const dateB = new Date(b.taskdate);
            return dateA - dateB;
        });
        return sortedArray;
    }

    removalHandler(event) {
        let index = event.target.name;
        this.incompletetask.splice(index, 1); // splice is use to remove the item from array
        let sortedArray = this.sortTask(this.incompletetask);
        this.incompletetask = [...sortedArray];
        console.log("this.incompletetask", this.incompletetask);
    }

    completetaskHandler(event) {
        // remove the netry from incomplete item
        let index = event.target.name;
        this.refreshData(index);
    }

    dragStartHandler(event) {
        // Set the task index in the drag event data (task being dragged)
        event.dataTransfer.setData("taskIndex", event.target.dataset.item);
    }

    allowDrop(event) {
        // Prevent default to allow drop event
        event.preventDefault();
    }

    dropElmentHandler(event) {
        // Get the task index from the drag event data
        let taskIndex = event.dataTransfer.getData("taskIndex");

        // Check if task index is valid
        if (taskIndex !== null && taskIndex !== undefined) {
            // Move the task to the completed list by refreshing the data
            this.refreshData(taskIndex);
        }
    }

    refreshData(index) {
        let removeItem = this.incompletetask.splice(index, 1); 
        let sortedArray = this.sortTask(this.incompletetask);
        this.incompletetask = [...sortedArray];
        this.completetask = [...this.completetask, removeItem[0]];
    }


}