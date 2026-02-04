import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';

// --- ONLINE APEX IMPORTS ---
import getAppointmentsByStatus from '@salesforce/apex/RtAppointmentListViewController.getAppointmentsByStatus';
import getWorkOrderIdFromSA from '@salesforce/apex/RtAppointmentListViewController.getWorkOrderIdFromSA';

// --- OFFLINE GRAPHQL IMPORTS ---
import { gql, graphql } from 'lightning/uiGraphQLApi';
import userId from '@salesforce/user/Id';

// --- GRAPHQL QUERY ---
const GET_OFFLINE_DATA = gql`
  query getOfflineAppointments($userId: ID!) {
    uiapi {
      query {
        AssignedResource(
          where: { ServiceResource: { RelatedRecordId: { eq: $userId } } }
          first: 1000
        ) {
          edges {
            node {
              Id
              ServiceAppointment {
                Id
                Status { value }
                Subject { value }
                SchedStartTime { value }
                SchedEndTime { value }
                Schedule_Start_Date__c { value }
                Schedule_End_Date__c { value }
                Appointment_Type__c { value }
                Meter_Number__c { value }
                Visit_Status__c { value }
                Due_Amount__c { value }
                Random_Visit_Date__c { value }
                Follow_Up_Visit_Date__c { value }
                DisplaySpecificRangeVisits__c { value }
                
                Account {
                  Id
                  Name { value }
                  BP_Number__c { value }
                  CA_Number__c { value }
                  # Building_Name__c { value } -- Commented out to prevent FieldUndefined Error
                  Street__c { value }
                  Street_Line_2__c { value }
                  Street_Line_3__c { value }
                  Street_Line_5__c { value }
                  Road_name__c { value }
                  Location__c { value }
                  Other_City__c { value }
                  Room__c { value }
                  Floor__c { value }
                  Wing__c { value }
                  Colony__c { value }
                }

                ParentRecord {
                  ... on WorkOrder {
                    Id
                    RecordType { DeveloperName { value } }
                    Payment_Mode__c { value }
                    Status { value }
                    Due_Amount__c { value }
                    Amount_Received__c { value }
                    Follow_up_Date__c { value }
                    Follow_up_Remarks__c { value }
                    
                    Building_Name__c { value }
                    New_Flat__c { value }
                    New_Floor__c { value }
                    New_Wing__c { value }
                    New_Plot__c { value }
                    New_Road_Name__c { value }
                    New_Landmark__c { value }
                    New_Colony__c { value }
                    New_Location__c { value }
                    City__c { value }
                    DISTRICT__c { value }
                    
                    Customer_BP_Number__c { value }
                    CA_Number__c { value }
                    Customer_Name__c { value }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
`;

export default class RtAppointmentListViewClone extends NavigationMixin(LightningElement) {

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
            this.handleDataLoad();
        }
    }

    @api secondPage;
    @track openAcc360 = false;
    @track selectedServiceAppointmentId;
    @track groupSelected = false;

    searchToggle = false;

    // Connectivity State
    @track isOnline = navigator.onLine;
    @track refreshKey = 0;

    @track displayFollowUpGroup = [];
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

    // =================================================================
    // LIFECYCLE
    // =================================================================

    connectedCallback() {
        window.addEventListener('online', this.handleNetworkChange);
        window.addEventListener('offline', this.handleNetworkChange);
        this.handleDataLoad();
        console.log('========this.selectedStatus======>>>>', this.selectedStatus);
        console.log('========this.selectedType======>>>>', this.selectedType);
    }

    disconnectedCallback() {
        window.removeEventListener('online', this.handleNetworkChange);
        window.removeEventListener('offline', this.handleNetworkChange);
    }

    handleNetworkChange = () => {
        this.isOnline = navigator.onLine;
        this.handleDataLoad();
    }

    handleDataLoad() {
        if (this.isOnline) {
            this.fetchAppointments();
        } else {
            this.refreshKey++; // Trigger GraphQL refresh
        }
    }

    // =================================================================
    // DEBUG HELPER
    // =================================================================
    debugToast(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'info',
                mode: 'dismissable'
            })
        );
    }

    // =================================================================
    // ONLINE LOGIC (APEX)
    // =================================================================

    fetchAppointments() {
        this.isLoading = true;
        this.error = undefined;

        if (!this.isOnline) return;

        getAppointmentsByStatus({ status: this.selectedStatus, type: this.selectedType })
            .then((result) => {
                console.log('=== result ===', JSON.stringify(result));
                this.processData(result);
                this.isLoading = false;
            })
            .catch((error) => {
                console.error('Error fetching appointments:', error);
                this.error = error?.body?.message || error?.message;
                this.isLoading = false;
            });
    }

    // =================================================================
    // OFFLINE LOGIC (GRAPHQL)
    // =================================================================

    get dataVars() {
        return { userId, refreshKey: String(this.refreshKey) };
    }

    @wire(graphql, { query: GET_OFFLINE_DATA, variables: '$dataVars' })
    wiredOfflineData({ errors, data }) {
        if (this.isOnline) return;

        if (data) {
            this.isLoading = true;
            this.processOfflineData(data);
            this.isLoading = false;
        } else if (errors) {
            console.error('GraphQL Error:', errors);
            this.debugToast('GraphQL Error', 'Failed to load offline data.');
            this.error = 'Failed to load offline data';
        }
    }

    processOfflineData(data) {
        const edges = data?.uiapi?.query?.AssignedResource?.edges || [];

        // --- helper: normalize Date/DateTime to YYYY-MM-DD ---
        const toYmd = (val) => {
            if (!val) return null;
            if (typeof val === 'string' && val.length >= 10) return val.substring(0, 10);
            const d = new Date(val);
            return isNaN(d.getTime()) ? null : d.toISOString().substring(0, 10);
        };

        const today = new Date().toLocaleDateString('en-CA'); // Fix for Local Time

        // Debug Counters
        let debug = { total: 0, passed: 0, failRT: 0, failDate: 0, failFlag: 0 };

        // 1. Filter Raw Data (Logic from Apex parity)
        let filteredWrappers = edges.map(e => e.node.ServiceAppointment).filter(sa => {
            debug.total++;
            if (!sa) return false;
            const parent = sa.ParentRecord;

            // Record Type
            const rtDevName = parent?.RecordType?.DeveloperName?.value;
            if (rtDevName && rtDevName !== 'MGL_R_T') {
                debug.failRT++;
                return false;
            }

            // Date Range
            const start = toYmd(sa.Schedule_Start_Date__c?.value) || toYmd(sa.SchedStartTime?.value);
            const end = toYmd(sa.Schedule_End_Date__c?.value) || toYmd(sa.SchedEndTime?.value);

            if (!start || !end || start > today || end < today) {
                debug.failDate++;
                return false;
            }

            // Flags
            if (sa.DisplaySpecificRangeVisits__c?.value === false) {
                debug.failFlag++;
                return false;
            }
            if (sa.Follow_Up_Visit_Date__c?.value) {
                debug.failFlag++;
                return false;
            }

            // Status Filtering
            const status = sa.Status?.value;
            const targetStatus = (this.selectedStatus || '').toLowerCase();
            const isCompleted = status === 'Completed';
            const isIncomplete = status === 'Cannot Complete';
            const isUnattempted = ['None', 'Scheduled', 'In Progress', 'Dispatched'].includes(status);

            if (targetStatus === 'completed' && !isCompleted) return false;
            if (targetStatus === 'incomplete' && !isIncomplete) return false;
            if (targetStatus === 'unattempted' && !isUnattempted) return false;

            debug.passed++;
            return true;
        }).map(sa => this.createWrapperFromGraphQL(sa));

        // SHOW DEBUG TOAST
        this.debugToast('Child Offline', `Total: ${debug.total}, Passed: ${debug.passed}, DateFail: ${debug.failDate}, RTFail: ${debug.failRT}`);

        // 2. Secondary Filtering based on 'type'
        let resultData = [];

        if (this.selectedType === 'Follow Up') {
            const followUps = filteredWrappers.filter(w => w.appointmentType === 'Follow Up');
            const grouped = {};
            followUps.forEach(w => {
                const remark = w.followUpRemarks || 'No Remarks';
                if (!grouped[remark]) grouped[remark] = [];
                grouped[remark].push(w);
            });
            resultData = Object.keys(grouped).map(remark => ({
                name: remark,
                count: grouped[remark].length,
                roads: [{
                    name: 'Follow Ups',
                    buildings: [{
                        name: remark,
                        appointments: grouped[remark],
                        count: grouped[remark].length
                    }]
                }]
            }));

        } else if (this.selectedType === 'Random') {
            resultData = filteredWrappers.filter(w => w.isRandomVisit);
            resultData = this.groupDataHierarchy(resultData);

        } else if (this.selectedType === 'Direct') {
            resultData = filteredWrappers.filter(w => w.isDirectPayment);
            resultData = this.groupDataHierarchy(resultData);

        } else {
            // Exclude FollowUp, Random, Direct
            resultData = filteredWrappers.filter(w =>
                w.appointmentType !== 'Follow Up' &&
                !w.isRandomVisit &&
                !w.isDirectPayment
            );
            resultData = this.groupDataHierarchy(resultData);
        }

        this.processData(resultData);
    }

    // Helper: Convert Flat List to Hierarchy
    groupDataHierarchy(wrappers) {
        const locMap = {};

        wrappers.forEach(w => {
            const loc = w.location || 'Unknown Location';
            const road = w.roadName || 'Unknown Road';
            const bldg = w.buildingName || 'Unknown Building';

            if (!locMap[loc]) locMap[loc] = {};
            if (!locMap[loc][road]) locMap[loc][road] = {};
            if (!locMap[loc][road][bldg]) locMap[loc][road][bldg] = [];

            locMap[loc][road][bldg].push(w);
        });

        // Convert Maps to Arrays (Location -> Road -> Building)
        return Object.keys(locMap).map(locName => {
            const roadsObj = locMap[locName];
            const roadsArr = Object.keys(roadsObj).map(roadName => {
                const bldgsObj = roadsObj[roadName];
                const bldgsArr = Object.keys(bldgsObj).map(bldgName => ({
                    name: bldgName,
                    appointments: bldgsObj[bldgName],
                    count: bldgsObj[bldgName].length
                }));
                return {
                    name: roadName,
                    buildings: bldgsArr,
                    count: bldgsArr.reduce((sum, b) => sum + b.count, 0)
                };
            });
            return {
                name: locName,
                roads: roadsArr,
                count: roadsArr.reduce((sum, r) => sum + r.count, 0)
            };
        });
    }

    // Helper: Wrapper Factory
    createWrapperFromGraphQL(sa) {
        const parent = sa.ParentRecord || {};
        const acc = sa.Account || {};
        const v = (field) => field?.value || '';

        // Address Fallbacks
        const buildingName = v(parent.Building_Name__c) || 'Unknown';
        const roadName = v(parent.New_Road_Name__c) || v(acc.Street_Line_5__c) || 'Unknown Road';
        const location = v(parent.New_Location__c) || v(acc.Other_City__c) || 'Unknown Location';

        const addressParts = [
            buildingName,
            v(parent.New_Flat__c) || v(acc.Room__c),
            v(parent.New_Floor__c) || v(acc.Floor__c),
            v(parent.New_Wing__c) || v(acc.Wing__c),
            v(parent.New_Plot__c),
            roadName,
            v(parent.New_Landmark__c) || v(acc.Street_Line_3__c),
            v(parent.New_Colony__c) || v(acc.Colony__c),
            location,
            v(parent.City__c),
            v(parent.DISTRICT__c)
        ].filter(p => p && p.trim() !== '');

        const woStatus = v(parent.Status);
        const payMode = v(parent.Payment_Mode__c);
        const apptType = v(sa.Appointment_Type__c) || 'Scheduled';
        const schedEnd = (woStatus === 'Follow Up' && v(parent.Follow_up_Date__c))
            ? v(parent.Follow_up_Date__c)
            : v(sa.SchedEndTime);

        // *** FIX: Strict Empty Check for Random ***
        const randomDate = v(sa.Random_Visit_Date__c);
        // Correct check: Is Not Empty String OR Type is Random
        const isRandom = (randomDate !== '') || (apptType === 'Random');

        return {
            id: sa.Id,
            // ** STORE WORK ORDER ID FOR OFFLINE NAVIGATION **
            workOrderId: parent.Id,
            subject: v(sa.Subject),
            bpNumber: v(parent.Customer_BP_Number__c) || v(acc.BP_Number__c),
            caNumber: v(parent.CA_Number__c) || v(acc.CA_Number__c),
            customerName: v(parent.Customer_Name__c) || v(acc.Name),
            meterNumber: v(sa.Meter_Number__c),
            accountName: v(acc.Name),
            DueAmount: v(sa.Due_Amount__c) || v(parent.Due_Amount__c),
            status: v(sa.Status),
            visitStatus: v(sa.Visit_Status__c),
            SchedEndTime: schedEnd,
            location: location,
            buildingName: buildingName,
            roadName: roadName,
            DetailAccountSummary: addressParts.join(', ') || 'No address available',
            appointmentType: apptType,
            isRandomVisit: isRandom,
            isDirectPayment: woStatus === 'Completed' && payMode === 'Directly Paid by Customer',
            followUpRemarks: v(parent.Follow_up_Remarks__c)
        };
    }

    // =================================================================
    // SHARED PROCESSING LOGIC
    // =================================================================

    processData(result) {
        if (this.selectedType === 'Follow Up') {

            if (result && result.length > 0) {
                const followUpGroup = result.map(lg => {
                    let allAppointments = [];
                    // Handle hierarchy or flat list
                    if (lg.roads && lg.roads.length > 0) {
                        lg.roads.forEach(rg => {
                            rg.buildings.forEach(bg => {
                                allAppointments = allAppointments.concat(bg.appointments);
                            });
                        });
                    } else if (lg.appointments) {
                        allAppointments = lg.appointments;
                    }

                    return {
                        name: lg.name,
                        count: allAppointments.length,
                        appointments: allAppointments
                    };
                });

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
                this.filteredFollowUpGroup = JSON.parse(JSON.stringify(this.followUpGroup));
            } else {
                this.followUpGroup = [];
            }

            this.headerLabels = {
                followUp: 'Follow-Up Remarks'
            };
            this.icons = {
                followUp: '🗒️'
            };

            this.showFollowUpRemarks = true;
            this.showFollowUpAppointments = false; // Reset
            this.showLocation = false;
            this.showRandomVisits = false;
            this.showDirectVisits = false;

        } else if (this.selectedType === 'Random') {

            if (result && result.length > 0) {
                let randomAppointments = [];
                result.forEach(loc => {
                    loc.roads.forEach(road => {
                        road.buildings.forEach(building => {
                            building.appointments.forEach(appt => {
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
            this.showDirectVisits = false;

        } else if (this.selectedType === 'Direct') {

            if (result && result.length > 0) {
                let directAppointments = [];
                result.forEach(loc => {
                    loc.roads.forEach(road => {
                        road.buildings.forEach(building => {
                            building.appointments.forEach(appt => {
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
            } else {
                this.directVisitAppointments = [];
            }

            this.headerLabels = {
                directVisit: 'Direct Payment'
            };
            this.icons = {
                directVisit: '🎯'
            };

            this.showFollowUpRemarks = false;
            this.showFollowUpAppointments = false;
            this.showLocation = false;
            this.showDirectVisits = true;
            this.showRandomVisits = false;

        } else {

            if (result && result.length > 0) {
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

            } else {
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
            this.showFollowUpRemarks = false;
            this.showRandomVisits = false;
            this.showDirectVisits = false;
        }
    }

    // =================================================================
    // UI HANDLERS
    // =================================================================

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

    resetSearchContext() {
        this.currentSearchValue = '';
    }

    toggleLoc(event) {
        this.isLoading = true;

        const locationName = event.currentTarget.dataset.location;
        const searchValue = this.currentSearchValue ? this.currentSearchValue.toLowerCase() : '';

        this.locationGroup = JSON.parse(JSON.stringify(this.allLocationGroup));

        // Find the selected location
        const selectedLocation = this.locationGroup.find(group => group.name === locationName);
        if (!selectedLocation) {
            this.isLoading = false;
            return;
        }

        let roadGroup = selectedLocation.roads || [];

        //  Apply search filter again within the selected location
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

        this.buildingGroup = JSON.parse(JSON.stringify(this.allBuildingGroup));
        const temp = this.buildingGroup[0]['statusCounts'];

        // Step 1: Apply label/status logic
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

    // --- NAVIGATION HANDLER (UPDATED FOR OFFLINE) ---
    handleAppointmentClick(event) {
        this.isLoading = false;
        const serviceAppointmentId = event.currentTarget.dataset.id;

        // 1. OFFLINE LOGIC
        if (!this.isOnline) {
            // Find the clicked appointment in local data
            let foundAppt = null;

            // Collect all possible appointments from current view state
            const allSources = [
                ...this.appointmentGroup,
                ...this.randomVisitAppointments,
                ...this.directVisitAppointments
            ];

            // Also check nested FollowUps if needed
            this.followUpGroup.forEach(g => {
                if (g.appointments) allSources.push(...g.appointments);
            });

            foundAppt = allSources.find(a => a.id === serviceAppointmentId);

            if (foundAppt && foundAppt.workOrderId) {
                this.navigateToWorkOrderInFSL(foundAppt.workOrderId);
            } else {
                this.showToast('Error', 'Cannot find Work Order ID offline.', 'error');
            }
            return;
        }

        // 2. ONLINE LOGIC (Existing Apex Call)
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