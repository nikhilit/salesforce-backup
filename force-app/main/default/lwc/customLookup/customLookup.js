import { LightningElement, wire } from 'lwc';
import searchRecords from "@salesforce/apex/CustomLookupController.searchRecords";
const DELAY = 300;

export default class CustomLookup extends LightningElement
{
    apiName = "Account";
    searchValue;
    objectLabel = "Account";
    iconName = "standard:account";
    delayTimeout;
    selectedRecord = {
        selectedId: "",
        selectedName: ""
    };
    displayOptions = false;

    get isRecordSelected()
    {
        return this.selectedRecord.selectedId === "" ? false : true;
    }

    @wire(searchRecords, 
        {
            objectApiName : "$apiName",
            searchKey : "$searchValue"
        })
        outputs;

    changeHandler(event)
    {
        window.clearTimeout(this.delayTimeout);
        let enteredValue = event.target.value;
        // debouncing - do not update the reactive property as long as this function is being called withi
        this.delayTimeout = setTimeout(() => {
            this.searchValue = enteredValue;
            this.displayOptions = true;
        }, DELAY);
    }

    clickHandler(event)
    {
        let selectedId = event.currentTarget.dataset.item;
        console.log("selectedId", selectedId);
        let outputRecord = this.outputs.data.find((currItem) => currItem.Id === selectedId);
        this.selectedRecord = {
            selectedId: outputRecord.Id,
            selectedName: outputRecord.Name
        };
        this.sendSelection();
        this.displayOptions = false;
    }

    removalSelectionHandler(event)
    {
        this.selectedRecord = {
            selectedId: "",
            selectedName: ""
        };
        this.sendSelection();
        this.displayOptions = false;
    }

    sendSelection()
    {
        let mySelectionEvent = new CustomEvent("selectrec", {
            detail: this.selectedRecord.selectedId
        });

        this.dispatchEvent(mySelectionEvent);
    }
}