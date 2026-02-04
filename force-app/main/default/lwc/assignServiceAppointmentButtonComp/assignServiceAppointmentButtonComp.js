import { LightningElement,track } from 'lwc';
export default class AssignServiceAppointmentButtonComp extends LightningElement {


@track showAssignToAgentButton=true;

@track showAssignAgentDetails=false;

handleCallAssignServiceComp(){

 this.showAssignAgentDetails=true;
    this.showAssignToAgentButton=false;

}

handleCancel(){

    this.showAssignAgentDetails=false;
    this.showAssignToAgentButton=true;
}
}