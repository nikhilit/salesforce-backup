import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';

import getAppointmentsByStatus from '@salesforce/apex/RtAppointmentListViewController.getAppointmentsByStatus';
import getWorkOrderIdFromSA from '@salesforce/apex/RtAppointmentListViewController.getWorkOrderIdFromSA';

export default class RtAppointmentListView extends NavigationMixin(LightningElement) {
        
    appointmentGroups = [];
    @track error;
    @track flag = true;
    @track isLoading = false;
    @api selectedType; 

    _selectedStatus;
    @api
    get selectedStatus() {
        return this._selectedStatus;
    }
    set selectedStatus(value) {
        this._selectedStatus = value;
        if (this.secondPage) {
            this.fetchAppointments();
        } 
    }

    @api secondPage;
    @track openAcc360 = false;
    @track selectedServiceAppointmentId;
    @track groupSelected = false;
    
    searchToggle = false;

    // Reactive property for UI rendering
    @track displayFollowUpGroup = [];

    connectedCallback() {

        this.fetchAppointments();
        console.log('========this.selectedStatus======>>>>', this.selectedStatus);
        console.log('========this.selectedType======>>>>', this.selectedType);
    }

    disconnectedCallback() {
        clearInterval(this.pollingInterval);
    }

    handleSearch() {
        this.searchToggle = !this.searchToggle;
    }

    handleBack() {
        this.secondPage = false;
        this.openMainPage = true;

        const event = new CustomEvent('childevent', {
            detail: {
                secondPage: this.secondPage,
                openMainPage: this.openMainPage
            }
        });
        this.dispatchEvent(event);
    }


    handleBuildingClick(event) {
        const buildingName = event.currentTarget.dataset.building;
    }

    get hasAppointments() {
        return this.appointmentGroups && this.appointmentGroups.length > 0;
    }
    
    @track locationGroup = [];
    allLocationGroup = [];
    @track roadGroup = [];
    allRoadGroup = [];
    @track buildingGroup = [];
    @track appointmentGroup = [];

    showLocation = false;
    showRoad = false;
    showBuilding = false;
    showAppointment = false;

    @track followUpGroup = [];
    @track selectedFollowUpRemark = '';

    @track showFollowUpRemarks = false;
    @track showFollowUpAppointments = false;

    @track randomVisitAppointments = [];
    @track allRandomVisitAppointments = [];
    @track showRandomVisits = false;

    @track directVisitAppointments = [];
    @track allDirectVisitAppointments = [];
    @track showDirectVisits = false;

    @track isLoading = true;
    @track error;

    type = 'Follow Up';
    status = 'total';

    headerLabels = {
        location: 'Locations',
        road: 'Roads',
        building: 'Premises',
        appointment: 'Appointments'
    };

    icons = {
        location: '📍',
        road: '🌃',
        building: '🏢'
    };

    filteredFollowUpGroup = [];

    fetchAppointments() {
        // Start loading and clear previous data
        this.isLoading = true;
        this.error = undefined;
            

        //console.log('=======this.selectedStatus=====>', this.selectedStatus);
        //console.log('=======this.selectedType=====>', this.selectedType);

        getAppointmentsByStatus({ status: this.selectedStatus, type: this.selectedType })
        .then((result) => {

            console.log('=== result ===', JSON.stringify(result));
            
            if (this.selectedType === 'Follow Up') {

                if (result && result.length > 0) {
                    // Flatten all appointments under each Follow-Up remark
                    const followUpGroup = result.map(lg => {
                        let allAppointments = [];
                        lg.roads.forEach(rg => {
                            rg.buildings.forEach(bg => {
                                allAppointments = allAppointments.concat(bg.appointments);
                            });
                        });

                        return {
                            name: lg.name,
                            count: allAppointments.length,
                            appointments: allAppointments
                        };
                    });

                    // Apply formatting logic
                    const processedFollowUpGroups = followUpGroup.map(group => {
                        const processedAppointments = group.appointments.map(appt => {
                            let statusClass = 'appt-status slds-badge';

                            if (appt.visitStatus === 'Success') {
                                statusClass += ' success-badge';
                            } else if (appt.visitStatus === 'Unsuccessful') {
                                statusClass += ' unsuccessful-badge';
                            }

                            return {
                                ...appt,
                                statusClass,
                                formattedSchedEndDate: appt.SchedEndTime
                                    ? new Date(appt.SchedEndTime).toLocaleDateString('en-IN', {
                                        day: '2-digit',
                                        month: 'short',
                                        year: 'numeric',
                                    })
                                    : '',
                                formattedDueAmount:
                                    appt.DueAmount != null && appt.DueAmount !== ''
                                        ? 'Due: ₹' + appt.DueAmount
                                        : 'No Dues',
                            };
                        });
 
                        return {
                            ...group,
                            appointments: processedAppointments
                        };
                    });

                    this.followUpGroup = processedFollowUpGroups;

                    // Initialize when data loads
                    this.filteredFollowUpGroup = JSON.parse(JSON.stringify(this.followUpGroup));

                    //console.log('=======this.followUpGroup=====>', JSON.stringify(this.followUpGroup));
                }else{
                    this.followUpGroup = [];
                }

                this.headerLabels = {
                    followUp: 'Follow-Up Remarks'
                };
                this.icons = {
                    followUp: '🗒️'
                };

                this.showFollowUpRemarks = true;
                this.showLocation = false;

            } else if (this.selectedType === 'Random') {

                if (result && result.length > 0) {
                    // Flatten and filter only Random Visit appointments
                    let randomAppointments = [];
                    result.forEach(loc => {
                        loc.roads.forEach(road => {
                            road.buildings.forEach(building => {
                                building.appointments.forEach(appt => {

                                    console.log('=== appt ===', JSON.stringify(appt));

                                    if (appt.isRandomVisit) {
                                        let statusClass = 'appt-status slds-badge';
                                        if (appt.visitStatus === 'Success') {
                                            statusClass += ' success-badge';
                                        } else if (appt.visitStatus === 'Unsuccessful') {
                                            statusClass += ' unsuccessful-badge';
                                        }

                                        randomAppointments.push({
                                            ...appt,
                                            statusClass,
                                            formattedSchedEndDate: appt.SchedEndTime
                                                ? new Date(appt.SchedEndTime).toLocaleDateString('en-IN', {
                                                    day: '2-digit',
                                                    month: 'short',
                                                    year: 'numeric',
                                                })
                                                : '',
                                            formattedDueAmount:
                                                appt.DueAmount != null && appt.DueAmount !== ''
                                                    ? 'Due: ₹' + appt.DueAmount
                                                    : 'No Dues',
                                        });
                                    }
                                });
                            });
                        });
                    });

                    this.randomVisitAppointments = randomAppointments;
                    this.allRandomVisitAppointments = JSON.parse(JSON.stringify(randomAppointments));
                    console.log('=== Random Visit Appointments ===', JSON.stringify(this.randomVisitAppointments));
                } else {
                    this.randomVisitAppointments = [];
                }

                this.headerLabels = {
                    randomVisit: 'Random Visits'
                };
                this.icons = {
                    randomVisit: '🎯'
                };

                // Toggle visibility
                this.showFollowUpRemarks = false;
                this.showFollowUpAppointments = false;
                this.showLocation = false;
                this.showRandomVisits = true;

            } else if (this.selectedType === 'Direct') {

                console.log('=== result _ Direct ===', JSON.stringify(result));

                if (result && result.length > 0) {
                    // Flatten and filter only Direct Payment appointments
                    let directAppointments = [];
                    result.forEach(loc => {
                        loc.roads.forEach(road => {
                            road.buildings.forEach(building => {
                                building.appointments.forEach(appt => {

                                    console.log('=== appt ===', JSON.stringify(appt));

                                    if (appt.isDirectPayment) {
                                        let statusClass = 'appt-status slds-badge';
                                        if (appt.visitStatus === 'Success') {
                                            statusClass += ' success-badge';
                                        } else if (appt.visitStatus === 'Unsuccessful') {
                                            statusClass += ' unsuccessful-badge';
                                        }

                                        directAppointments.push({
                                            ...appt,
                                            statusClass,
                                            formattedSchedEndDate: appt.SchedEndTime
                                                ? new Date(appt.SchedEndTime).toLocaleDateString('en-IN', {
                                                    day: '2-digit',
                                                    month: 'short',
                                                    year: 'numeric',
                                                })
                                                : '',
                                            formattedDueAmount:
                                                appt.DueAmount != null && appt.DueAmount !== ''
                                                    ? 'Due: ₹' + appt.DueAmount
                                                    : 'No Dues',
                                        });
                                    }
                                });
                            });
                        });
                    });

                    this.directVisitAppointments = directAppointments;
                    this.allDirectVisitAppointments = JSON.parse(JSON.stringify(directAppointments));
                    console.log('=== Direct Visit Appointments ===', JSON.stringify(this.directVisitAppointments));
                } else {
                    this.directVisitAppointments = [];
                }

                this.headerLabels = {
                    directVisit: 'Direct Payment'
                };
                this.icons = {
                    directVisit: '🎯'
                };

                // Toggle visibility
                this.showFollowUpRemarks = false;
                this.showFollowUpAppointments = false;
                this.showLocation = false;
                this.showDirectVisits = true;

            } else {

                if (result && result.length > 0) {
                    // Normal grouping logic
                    // this.locationGroup = result;
                    // this.allLocationGroup = JSON.parse(JSON.stringify(result));
                    // this.error = undefined;


                    result.forEach(loc => {
                        let locationCount = 0; // count for total appointments under this location

                        loc.roads.forEach(road => {
                            let roadCount = 0; // count for total appointments under this road

                            road.buildings.forEach(building => {
                                // Keep only non-direct-payment appointments
                                building.appointments = building.appointments.filter(appt => !appt.isDirectPayment);

                                // Update building-level count
                                building.count = building.appointments.length;

                                // Add to road total
                                roadCount += building.count;
                            });

                            // Remove buildings with no appointments
                            road.buildings = road.buildings.filter(building => building.appointments.length > 0);

                            // Update road-level count
                            road.count = roadCount;

                            // Add to location total
                            locationCount += road.count;
                        });

                        // Remove roads with no buildings
                        loc.roads = loc.roads.filter(road => road.buildings.length > 0);

                        // Update location-level count
                        loc.count = locationCount;
                    });

                    // Remove locations with no valid roads
                    result = result.filter(loc => loc.roads.length > 0);

                    // Assign to tracked vars
                    this.locationGroup = result;
                    this.allLocationGroup = JSON.parse(JSON.stringify(result));
                    this.error = undefined;
                
                }else {
                    this.locationGroup = [];
                }

                this.headerLabels = {
                    location: 'Locations',
                    road: 'Roads',
                    building: 'Premises',
                    appointment: 'Appointments'
                };
                this.icons = {
                    location: '📍',
                    road: '🌃',
                    building: '🏢'
                };

                this.showLocation = true;
                this.showRoad = false;
                this.showBuilding = false;
                this.showAppointment = false;                    
            }

            this.isLoading = false;
        })
        .catch((error) => {
            console.error('Error fetching appointments:', error);
            this.error =
                error?.body?.message ||
                error?.message ||
                'Unknown error occurred while fetching appointments.';
            this.isLoading = false;
        });

    }

    resetSearchContext() {
        this.currentSearchValue = '';
    }

    toggleLoc(event) {
        this.isLoading = true;

        const locationName = event.currentTarget.dataset.location;
        const searchValue = this.currentSearchValue ? this.currentSearchValue.toLowerCase() : '';

        // Always restore full list first
        this.locationGroup = JSON.parse(JSON.stringify(this.allLocationGroup));

        // Find the selected location
        const selectedLocation = this.locationGroup.find(group => group.name === locationName);
        if (!selectedLocation) {
            this.isLoading = false;
            return;
        }

        let roadGroup = selectedLocation.roads || [];

        // ✅ Apply search filter again within the selected location
        if (searchValue) {
            roadGroup = roadGroup
                .map(road => {
                    const filteredBuildings = (road.buildings || [])
                        .map(building => {
                            const filteredAppointments = (building.appointments || []).filter(app => {
                                return (
                                    (app.bpNumber && app.bpNumber.toLowerCase().includes(searchValue)) ||
                                    (app.caNumber && app.caNumber.toLowerCase().includes(searchValue)) ||
                                    (app.location && app.location.toLowerCase().includes(searchValue)) ||
                                    (app.customerName && app.customerName.toLowerCase().includes(searchValue)) ||
                                    (app.buildingName && app.buildingName.toLowerCase().includes(searchValue)) ||
                                    (app.roadName && app.roadName.toLowerCase().includes(searchValue))
                                );
                            });

                            if (filteredAppointments.length > 0) {
                                return { ...building, appointments: filteredAppointments };
                            }
                            return null;
                        })
                        .filter(b => b !== null);

                    if (filteredBuildings.length > 0) {
                        return { ...road, buildings: filteredBuildings };
                    }
                    return null;
                })
                .filter(r => r !== null);
        }

        // Set road group data
        this.roadGroup = roadGroup;
        this.allRoadGroup = JSON.parse(JSON.stringify(roadGroup));

        // Switch tabs
        this.showLocation = false;
        this.showRoad = true;
        this.showBuilding = false;
        this.showAppointment = false;
        this.isLoading = false;
    }

    toggleRoad(event) {
        this.isLoading = true;

        const roadName = event.currentTarget.dataset.road;
        const searchValue = this.currentSearchValue ? this.currentSearchValue.toLowerCase() : '';

        // Reset full road data
        this.roadGroup = JSON.parse(JSON.stringify(this.allRoadGroup));

        // Find selected road
        const selectedRoad = this.roadGroup.find(group => group.name === roadName);
        if (!selectedRoad) {
            this.isLoading = false;
            return;
        }

        let buildingGroup = selectedRoad.buildings || [];

        // ✅ Apply search filter within this road (if search active)
        if (searchValue) {
            buildingGroup = buildingGroup
                .map(building => {
                    const filteredAppointments = (building.appointments || []).filter(app => {
                        return (
                            (app.bpNumber && app.bpNumber.toLowerCase().includes(searchValue)) ||
                            (app.caNumber && app.caNumber.toLowerCase().includes(searchValue)) ||
                            (app.location && app.location.toLowerCase().includes(searchValue)) ||
                            (app.customerName && app.customerName.toString().toLowerCase().includes(searchValue)) ||
                            (app.buildingName && app.buildingName.toLowerCase().includes(searchValue)) ||
                            (app.roadName && app.roadName.toLowerCase().includes(searchValue))
                        );
                    });

                    if (filteredAppointments.length > 0) {
                        return { ...building, appointments: filteredAppointments };
                    }
                    return null;
                })
                .filter(b => b !== null);
        }

        // Set filtered data
        this.buildingGroup = buildingGroup;
        this.allBuildingGroup = JSON.parse(JSON.stringify(buildingGroup));

        // Switch tab view
        this.showLocation = false;
        this.showRoad = false;
        this.showBuilding = true;
        this.showAppointment = false;
        this.isLoading = false;
    }

    toggleBuild(event) {
        this.isLoading = true;

        const buildingName = event.currentTarget.dataset.building;
        const searchValue = this.currentSearchValue ? this.currentSearchValue.toLowerCase() : '';

        // Deep copy full building group
        this.buildingGroup = JSON.parse(JSON.stringify(this.allBuildingGroup));
        const temp = this.buildingGroup[0]['statusCounts'];

        // Step 1: Apply existing label/status logic
        this.buildingGroup.forEach(grp => {
            if (grp.appointments && grp.appointments.length > 0) {
                grp.appointments.forEach(item => {
                    if (temp) {
                        let matchFound = false;
                        temp.forEach(item1 => {
                            if (item1.listServiceAppointments && item1.listServiceAppointments.length > 0) {
                                item1.listServiceAppointments.forEach(item2 => {
                                    if (item.id === item2.Id) {
                                        item.label = item1.label;
                                        matchFound = true;
                                    }
                                });
                            }
                        });
                        if (!matchFound) {
                            item.label = 'Follow up';
                        }
                    }
                });
            }
        });

        // Step 2: Find the selected building
        const selectedBuilding = this.buildingGroup.find(group => group.name === buildingName);
        if (!selectedBuilding) {
            this.isLoading = false;
            return;
        }

        let appointments = selectedBuilding.appointments || [];

        // Step 3: Apply search filtering (if search active)
        if (searchValue) {
            appointments = appointments.filter(app => {
                return (
                    (app.bpNumber && app.bpNumber.toLowerCase().includes(searchValue)) ||
                    (app.caNumber && app.caNumber.toLowerCase().includes(searchValue)) ||
                    (app.location && app.location.toLowerCase().includes(searchValue)) ||
                    (app.customerName && app.customerName.toLowerCase().includes(searchValue)) ||
                    (app.buildingName && app.buildingName.toLowerCase().includes(searchValue)) ||
                    (app.roadName && app.roadName.toLowerCase().includes(searchValue))
                );
            });
        }

        // Step 4: Format & enrich appointments
        const processedAppointments = appointments.map(appt => {
            let statusClass = 'appt-status slds-badge';

            if (appt.visitStatus === 'Success') {
                statusClass += ' success-badge';
            } else if (appt.visitStatus === 'Unsuccessful') {
                statusClass += ' unsuccessful-badge';
            }

            return {
                ...appt,
                statusClass,
                formattedSchedEndDate: appt.SchedEndTime
                    ? new Date(appt.SchedEndTime).toLocaleDateString('en-IN', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric',
                    })
                    : '',
                formattedDueAmount:
                    appt.DueAmount != null && appt.DueAmount !== ''
                        ? 'Due: ₹' + appt.DueAmount
                        : 'No Dues',
            };
        });

        // Step 5: Set state
        this.appointmentGroup = processedAppointments;
        this.allAppointmentGroup = JSON.parse(JSON.stringify(this.appointmentGroup));

        // Step 6: Switch tab view
        this.showLocation = false;
        this.showRoad = false;
        this.showBuilding = false;
        this.showAppointment = true;
        this.isLoading = false;
    }


    backToLocation() {
        this.resetSearchContext();
        this.showLocation = true;
        this.showRoad = false;
    }

    backToRoad() {
        this.resetSearchContext();
        this.showRoad = true;
        this.showBuilding = false;
    }

    backToBuilding() {
        this.resetSearchContext();
        this.showBuilding = true;
        this.showAppointment = false;
    }

    handleFollowUpClick(event) {
        const remark = event.currentTarget.dataset.remark;
        this.selectedFollowUpRemark = remark;

        // Find the group by remark
        const group = this.followUpGroup.find(g => g.name === remark);

        // Check if the group exists and has appointments
        if (group && group.appointments && group.appointments.length) {
            // Directly assign appointments
            this.appointmentGroup = group.appointments;

            // Update UI flags
            this.showFollowUpRemarks = false;
            this.showFollowUpAppointments = true;
        }
    }

    backToFollowUp() {

        this.currentSearchValue = '';
        this.filteredFollowUpGroup = JSON.parse(JSON.stringify(this.followUpGroup));

        this.showFollowUpRemarks = true;
        this.showFollowUpAppointments = false;

        this.selectedFollowUpRemark = null;
        this.appointmentGroup = [];
    }

    filterRandomVisits(event) {
        const searchValue = event.detail.value ? event.detail.value.toLowerCase() : '';
        //console.log('🔍 Random Visit Search:', searchValue);

        // If empty, reset full list
        if (!searchValue) {
            this.randomVisitAppointments = JSON.parse(JSON.stringify(this.allRandomVisitAppointments));
            return;
        }

        // Filter by customerName, bpNumber, or caNumber
        this.randomVisitAppointments = this.allRandomVisitAppointments.filter(appt => {
            return (
                (appt.customerName && appt.customerName.toLowerCase().includes(searchValue)) ||
                (appt.bpNumber && appt.bpNumber.toLowerCase().includes(searchValue)) ||
                (appt.caNumber && appt.caNumber.toLowerCase().includes(searchValue))
            );
        });
    }

    filterFollowUpRemarks(event) {
        const searchValue = event.detail.value ? event.detail.value.toLowerCase() : '';

        this.currentSearchValue = searchValue || '';

        if (!searchValue) {
            // Reset to full list
            this.filteredFollowUpGroup = JSON.parse(JSON.stringify(this.followUpGroup));
            return;
        }

        this.filteredFollowUpGroup = this.followUpGroup
            .map(group => {
                // Filter appointments inside this remark
                const matchedAppointments = group.appointments.filter(appt => {
                    return (
                        (appt.bpNumber && appt.bpNumber.toLowerCase().includes(searchValue)) ||
                        (appt.caNumber && appt.caNumber.toLowerCase().includes(searchValue)) ||
                        (appt.customerName && appt.customerName.toLowerCase().includes(searchValue)) ||
                        (appt.buildingName && appt.buildingName.toLowerCase().includes(searchValue)) ||
                        (appt.roadName && appt.roadName.toLowerCase().includes(searchValue)) ||
                        (appt.accountName && appt.accountName.toLowerCase().includes(searchValue)) ||
                        (appt.DueAmount && appt.DueAmount.toString().includes(searchValue)) ||
                        (appt.FollowUpRemarks__c && appt.FollowUpRemarks__c.toLowerCase().includes(searchValue))
                    );
                });

                // Include this group if either its name matches or appointments match
                if (group.name.toLowerCase().includes(searchValue) || matchedAppointments.length > 0) {
                    return {
                        ...group,
                        appointments: matchedAppointments.length > 0 ? matchedAppointments : group.appointments,
                        count: matchedAppointments.length > 0 ? matchedAppointments.length : group.appointments.length
                    };
                }
                return null;
            })
            .filter(item => item != null);
    }



    filterDataFollowUpAppt(event) {
        const value = event.detail.value ? event.detail.value.toLowerCase() : '';
        this.appointmentGroup = [];

        if (!this.selectedFollowUpRemark) {
            return;
        }

        // Find the selected Follow-Up group
        const group = this.followUpGroup.find(g => g.name === this.selectedFollowUpRemark);
        if (!group || !group.appointments) {
            return;
        }

        if (value && value !== '') {
            this.appointmentGroup = group.appointments.filter(app => {
                return (
                    (app.bpNumber && app.bpNumber.toLowerCase().includes(value)) ||
                    (app.caNumber && app.caNumber.toLowerCase().includes(value)) ||
                    (app.customerName && app.customerName.toString().toLowerCase().includes(value)) ||
                    (app.buildingName && app.buildingName.toLowerCase().includes(value)) ||
                    (app.roadName && app.roadName.toLowerCase().includes(value)) ||
                    (app.accountName && app.accountName.toLowerCase().includes(value)) ||
                    (app.DueAmount && app.DueAmount.toString().toLowerCase().includes(value)) ||
                    (app.FollowUpRemarks__c && app.FollowUpRemarks__c.toLowerCase().includes(value))
                );
            });
        } else {
            // If no search value, show all appointments under this remark
            this.appointmentGroup = group.appointments;
        }
    }

    toggleCountSection(event) {

        event.stopPropagation();

        var buildingName = event.currentTarget.dataset.building;
        var buildingGroup = JSON.parse(JSON.stringify(this.buildingGroup));

        buildingGroup.forEach(item => {
            if (item.name === buildingName) {
                item.statusSection = !item.statusSection;
            } else {
                item.statusSection = false;
            }
        });

        this.buildingGroup = buildingGroup;
    }

    filterDataLocation(event) {
        const value = event.detail.value ? event.detail.value.toLowerCase() : '';
        this.locationGroup = [];

        this.currentSearchValue = value;

        if (value && value !== '') {
            this.locationGroup = this.allLocationGroup
                .map(group => {
                    // filter roads
                    const filteredRoads = group.roads
                        .map(road => {
                            // filter buildings
                            const filteredBuildings = road.buildings
                                .map(building => {
                                    // filter appointments
                                    const filteredAppointments = building.appointments.filter(app => {
                                        return (
                                            (app.bpNumber && app.bpNumber.toLowerCase().includes(value)) ||
                                            (app.caNumber && app.caNumber.toLowerCase().includes(value)) ||
                                            (app.location && app.location.toLowerCase().includes(value)) ||
                                            (app.customerName && app.customerName.toString().toLowerCase().includes(value)) ||
                                            (app.buildingName && app.buildingName.toLowerCase().includes(value)) ||
                                            (app.roadName && app.roadName.toLowerCase().includes(value))
                                        );
                                    });

                                    if (filteredAppointments.length > 0) {
                                        return { ...building, appointments: filteredAppointments };
                                    }
                                    return null;
                                })
                                .filter(b => b !== null);

                            if (filteredBuildings.length > 0) {
                                return { ...road, buildings: filteredBuildings };
                            }
                            return null;
                        })
                        .filter(r => r !== null);

                    if (filteredRoads.length > 0) {
                        return { ...group, roads: filteredRoads };
                    }
                    return null;
                })
                .filter(g => g !== null);
        } else {
            this.locationGroup = this.allLocationGroup;
        }
    }

    filterDataRoad(event) {
        const value = event.detail.value ? event.detail.value.toLowerCase() : '';
        this.roadGroup = [];

        this.currentSearchValue = value;

        if (value && value !== '') {
            this.roadGroup = this.allRoadGroup
                .map(road => {
                    // filter buildings
                    const filteredBuildings = road.buildings
                        .map(building => {
                            // filter appointments
                            const filteredAppointments = building.appointments.filter(app => {
                                return (
                                    (app.bpNumber && app.bpNumber.toLowerCase().includes(value)) ||
                                    (app.caNumber && app.caNumber.toLowerCase().includes(value)) ||
                                    (app.customerName && app.customerName.toString().toLowerCase().includes(value)) ||
                                    (app.buildingName && app.buildingName.toLowerCase().includes(value)) ||
                                    (app.roadName && app.roadName.toLowerCase().includes(value))
                                );
                            });

                            if (filteredAppointments.length > 0) {
                                return { ...building, appointments: filteredAppointments };
                            }
                            return null;
                        })
                        .filter(b => b !== null);

                    if (filteredBuildings.length > 0) {
                        return { ...road, buildings: filteredBuildings };
                    }
                    return null;
                })
                .filter(r => r !== null);
        } else {
            this.roadGroup = this.allRoadGroup;
        }
    }

    filterDataBuilding(event) {
        const value = event.detail.value ? event.detail.value.toLowerCase() : '';
        this.buildingGroup = [];

        this.currentSearchValue = value;

        if (value && value !== '') {
            this.buildingGroup = this.allBuildingGroup
                .map(building => {
                    // filter appointments inside this building
                    const filteredAppointments = building.appointments.filter(app => {
                        return (
                            (app.bpNumber && app.bpNumber.toLowerCase().includes(value)) ||
                            (app.caNumber && app.caNumber.toLowerCase().includes(value)) ||
                            (app.customerName && app.customerName.toString().toLowerCase().includes(value)) ||
                            (app.buildingName && app.buildingName.toLowerCase().includes(value)) ||
                            (app.roadName && app.roadName.toLowerCase().includes(value))
                        );
                    });

                    if (filteredAppointments.length > 0) {
                        return { ...building, appointments: filteredAppointments };
                    }
                    return null;
                })
                .filter(b => b !== null);
        } else {
            this.buildingGroup = this.allBuildingGroup;
        }
    }


    filterDataAppt(event) {
        const value = event.detail.value ? event.detail.value.toLowerCase() : '';
        this.appointmentGroup = [];

        if (value && value !== '') {
            this.appointmentGroup = this.allAppointmentGroup.filter(app => {
                return (
                    (app.bpNumber && app.bpNumber.toLowerCase().includes(value)) ||
                    (app.caNumber && app.caNumber.toLowerCase().includes(value)) ||
                    (app.customerName && app.customerName.toString().toLowerCase().includes(value)) ||
                    (app.buildingName && app.buildingName.toLowerCase().includes(value)) ||
                    (app.roadName && app.roadName.toLowerCase().includes(value)) ||
                    (app.accountName && app.accountName.toLowerCase().includes(value)) ||
                    (app.DueAmount && app.DueAmount.toString().toLowerCase().includes(value))
                );
            });
        } else {
            this.appointmentGroup = this.allAppointmentGroup;
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
                }
            })
            .catch(error => {
                let errorMessage = 'An error occurred while fetching the Work Order.';
                if (error && error.body && error.body.message) {
                    errorMessage = error.body.message;
                } else if (error && error.message) {
                    errorMessage = error.message;
                }
                
                this.showToast(
                    'Error',
                    errorMessage,
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