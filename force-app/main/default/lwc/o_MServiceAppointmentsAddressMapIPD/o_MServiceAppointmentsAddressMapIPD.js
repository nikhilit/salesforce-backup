/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 19-05-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   18-05-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { LightningElement, track, api, wire } from 'lwc';
import getAppointmentsByStatus from '@salesforce/apex/O_MServiceAppointmentsAddressMapContrIPD.getAppointmentsByStatus';
import { NavigationMixin } from 'lightning/navigation';
import getWorkOrderIdFromSA from '@salesforce/apex/O_MServiceAppointmentsAddressMapContrIPD.getWorkOrderIdFromSA';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import FORM_FACTOR from '@salesforce/client/formFactor';


export default class O_MServiceAppointmentsAddressMap extends NavigationMixin(LightningElement) {
    @track appointmentGroups = [];
    @track error;
    @track flag = true;
    @track isLoading = false;
    @api selectedStatus;
    @api selectedType;
    @api openMainPage;
    @api showDashboard;
    @api secondPage;
    @track openAcc360 = false;
    @track selectedServiceAppointmentId;
    @track groupSelected = false;
    wiredAppointmentsResult;

    searchToggle = false;

    connectedCallback() {
        console.log('openMainPage2:', this.openMainPage);
        console.log('showDashboard2:', this.showDashboard);
        this.refreshAppointments();
        //this.secondPage = true;
        this.showAppointmentScreen = true;

        // this.pollingInterval = setInterval(() => {
        //     if (this.wiredAppointmentsResult) {
        //         refreshApex(this.wiredAppointmentsResult);
        //     }
        // }, 2000);
    }

    disconnectedCallback() {
        clearInterval(this.pollingInterval);
    }

    handleSearch() {
        this.searchToggle = !this.searchToggle;
    }

    handleBacktoaddress() {
    console.log('Back clicked');

    this.showAppointmentScreen = false;
    this.flag = true;
    this.appointmentsList = [];
    this.appointmentGroups = this.appointmentGroups.map(group => ({
        ...group,
        isExpanded: false
    }));

    // Notify parent
    const event = new CustomEvent('childevent', {
        detail: {
            showDashboard: true,
            openMainPage: true
        }
    });
    this.dispatchEvent(event);
}



    handleBack() {
        //this.secondPage = false;
        this.showDashboard = true;
        this.openMainPage = true;
        this.refreshAppointments();

        const event = new CustomEvent('childevent', {
            detail: {
                //secondPage: this.secondPage,
                showDashboard: this.showDashboard,
                openMainPage: this.openMainPage
            }
        });
        this.dispatchEvent(event);
    }


    handleBuildingClick(event) {
        const buildingName = event.currentTarget.dataset.building;
        console.log('Building clicked:', buildingName);
    }

    get hasAppointments() {
        return this.appointmentGroups && this.appointmentGroups.length > 0;
    }

    @wire(getAppointmentsByStatus, { status: '$selectedStatus',type:'$selectedType' })
    wiredAppointments(result) {

        this.wiredAppointmentsResult = result;
        const { data, error } = result;

        this.isLoading = true;
        if (data) {
            console.log('Wired result from Apex:', JSON.stringify(data));
            this.processData(data);
            this.error = null;
        } else if (error) {
            console.error('Wired error fetching appointments:', error);
            this.error = error.body ? error.body.message : error.message;
            this.appointmentGroups = [];
        }
        // this.isLoading = false;
    }

    refreshAppointments() {
        this.isLoading = true;
        refreshApex(this.wiredAppointmentsResult)
            .finally(() => {
                this.isLoading = false;
            });
    }

    appointmentResult=[];
    processData(result) {
        this.isLoading = true;
        const groups = [];
        console.log('result : ' + JSON.stringify(result));
        var data = result.groupedAppointments;
        var count = JSON.parse(JSON.stringify(result.groupedAppointmentCounts));
        for (let building in data) {
            const appointments = data[building];
            const buildingStreet = appointments.length > 0 ? appointments[0].buildingStreet : '';

            // Process each appointment to add statusClass based on visitStatus
            const processedAppointments = appointments.map(appt => {
                let statusClass = 'appt-status slds-badge';  // Default class

                if (appt.visitStatus === 'Success') {
                    statusClass += ' success-badge';  // Green for Success
                } else if (appt.visitStatus === 'Unsuccessful') {
                    statusClass += ' unsuccessful-badge';  // Red for Unsuccessful
                }

                return {
                    ...appt,  // Spread the original appointment data
                    statusClass  // Add the statusClass to each appointment
                };
            });

            // Now assign the processedAppointments array to the group
            this.statusMap = count;
            count[building].forEach(status => {
                status.cssStyle = 'background-color:' + status.cardColor + ';';
            });
            groups.push({
                buildingName: building,
                buildingStreet: buildingStreet,
                appointments: processedAppointments,  // Use processed appointments here
                isExpanded: false,
                statusSection: false,
                statusCounts: count[building]
            });
        }

        this.appointmentResult = result.groupedAppointments;
        console.log('this.appointmentResult ::'+JSON.stringify(this.appointmentResult ));
        this.showAppointmentScreen=true;
        this.allAppointments = JSON.parse(JSON.stringify(groups));
        this.appointmentGroups = groups;
        this.appointmentResult=result.listServiceApp;
        this.isLoading = false;
    }
    allAppointments = [];
    statusMap;

    filterGroups(event) {
        var value = event.detail.value;
        this.appointmentGroups = [];
        if (value && value != '') {
            this.appointmentGroups = this.allAppointments.filter(group => {
                const searchValue = value.toLowerCase();
                return (
                    (group.buildingName && group.buildingName.toLowerCase().includes(searchValue)) ||
                    (group.buildingStreet && group.buildingStreet.toLowerCase().includes(searchValue))
                );
            });
        } else {
            this.appointmentGroups = this.allAppointments;
        }
    }

    toggleGroup(event) {
        // event.stopPropagation();
        const buildingName = event.currentTarget.dataset.building;
        this.appointmentGroups = this.appointmentGroups.map(group => {
            if (group.buildingName === buildingName) {
                return { ...group, expanded: !group.expanded };
            }
            return group;
        });
    }

    toggleSubCountSection(event) {
        event.stopPropagation();
        var value = event.currentTarget.dataset.building;
        this.appointmentGroups.forEach(item => {
            if (item.buildingName == value) {
                item.statusSection = !item.statusSection;
            } else {
                item.statusSection = false;
            }
        })
    }

    showAppointmentScreen = true;
    @track appointmentsList = [];
    appointmentsListMain = [];
    toggleBuilding(event) {
        this.isLoading = true;
        this.groupSelected = true;
        console.log('before toggleBuilding this.flag1>>>>' + this.flag);
        this.flag = false;
        console.log('this.flag1>>>>' + this.flag);
        const buildingName = event.currentTarget.dataset.building;
        this.appointmentsList = [];
        this.appointmentsListMain = [];
        this.appointmentGroups = this.appointmentGroups.map(group => {
            if (group.buildingName === buildingName) {
                this.appointmentsList = group.appointments;
                return { ...group, isExpanded: !group.isExpanded };
            }
            return group;
        });

        console.log('this.statusMap:::' + JSON.stringify(this.statusMap));
        console.log('buildingName:::' + buildingName);
        var temp = this.statusMap[buildingName];
        console.log('temp>>>' + JSON.stringify(temp));
        this.appointmentsList.forEach(item => {
            if (temp) {
                temp.forEach(item1 => {
                    if (item1.listServiceAppointments) {
                        item1.listServiceAppointments.forEach(item2 => {
                            if (item.id == item2.Id) {
                                item.cssStyle = 'background-color:' + item1.cardColor + ';';
                                item.label = item1.label;
                            }
                        })
                    }
                })
            }
        })

        console.log('Toggling group >>>>', JSON.stringify(this.appointmentsList, null, 2));
        this.appointmentsListMain = JSON.parse(JSON.stringify(this.appointmentsList));
        this.isLoading = false;

    }

    appointmentSearchToggle = false;
    handleAppointmentSearch() {
        this.appointmentSearchToggle = !this.appointmentSearchToggle;
    }

    filterAppointmentSearch(event) {
        var value = event.detail.value;
        this.appointmentsList = [];
        if (value && value != '') {
            this.appointmentsList = this.appointmentsListMain.filter(group => {
                const searchValue = value.toLowerCase();
                return (
                    (group.accountName && group.accountName.toLowerCase().includes(searchValue)) ||
                    (group.DetailAccountSummary && group.DetailAccountSummary.toLowerCase().includes(searchValue))
                );
            });
        } else {
            this.appointmentsList = this.appointmentsListMain;
        }
    }


    handleAppointmentClick(event) {
        this.isLoading = false;
        const serviceAppointmentId = event.currentTarget.dataset.id;

        getWorkOrderIdFromSA({ serviceAppointmentId })
            .then(workOrderId => {
                if (workOrderId) {
                    this.navigateToWorkOrderInFSL(workOrderId);
                } else {
                    this.showToast(
                        'Missing Work Order',
                        `No Work Order is associated with this Service Appointment.\nServiceAppointmentId: ${serviceAppointmentId}`,
                        'warning'
                    );
                    console.error('No Work Order ID found.');
                }
            })
            .catch(error => {
                this.showToast(
                    'Error',
                    'An error occurred while fetching the Work Order.',
                    'error'
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }


    navigateToWorkOrderInFSL(workOrderId) {
        if (FORM_FACTOR == 'Large') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: workOrderId,
                    actionName: 'view',
                },
            });
        } else {

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `com.salesforce.fieldservice://v1/sObject/${workOrderId}/overview`
                }
            });
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode: 'dismissable'
            })
        );
    }
}