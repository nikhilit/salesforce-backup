import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTodayAttendance from '@salesforce/apex/AgentAttendanceController.getTodayAttendance';
import getBlockPicklistValues from '@salesforce/apex/AgentAttendanceController.getBlockPicklistValues';
import getUserName from '@salesforce/apex/AgentAttendanceController.getCurrentUserName';
import handleAttendance from '@salesforce/apex/AgentAttendanceController.handleAttendance';

export default class AttendanceManagementComponent extends LightningElement {
    @track userName = '';
    @track formattedDateTime = '';
    @track blockOptions = [];
    @track selectedBlock = null;

    // Consolidated state management
    @track state = {
        checkInTime: null,
        checkOutTime: null,
        dayInLat: null,
        dayInLong: null,
        dayOutLat: null,
        dayOutLong: null,
        showCheckInButton: true,
        showCheckOutButton: false,
        attendanceCompleted: false,
        isLoading: false
    };

    connectedCallback() {
        this.setFormattedDateTime();
        this.fetchBlockOptions();
        this.fetchUserName();
        this.loadAttendanceData();
    }

    get isBlockDisabled() {
        // Disable when:
        // 1. Already checked in (check-out button visible)
        // 2. Attendance completed for the day
        // 3. No block options available
        console.loh("inside the isblock");
        return this.state.showCheckOutButton || 
               this.state.attendanceCompleted || 
               this.blockOptions.length === 0;
    }

    get comboboxValue() {
        return this.selectedBlock;
    }

    setFormattedDateTime() {
        const now = new Date();
        this.formattedDateTime = now.toLocaleString('en-US', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }).replace(/(\d+)\/(\d+)\/(\d+)/, '$3-$1-$2');
    }

    fetchUserName() {
        getUserName()
            .then(name => {
                this.userName = name;
            })
            .catch(error => {
                console.error('Error fetching user name:', error);
            });
    }

    fetchBlockOptions() {
        getBlockPicklistValues()
            .then(data => {
                this.blockOptions = data.map(item => ({
                    label: item,
                    value: item
                }));
            })
            .catch(error => {
                console.error('Error loading block options:', error);
                this.showToast('Error', 'Failed to load location options', 'error');
            });
    }

    loadAttendanceData() {
        this.state.isLoading = true;
        getTodayAttendance()
            .then(record => {
                if (record) {
                    const newState = {...this.state};
                    
                    if (record.Day_In_Timestamp__c) {
                        this.state.checkInTime = new Date(record.Day_In_Timestamp__c).toLocaleString();
                        this.selectedBlock = record.Block__c;
                        newState.showCheckInButton = false;
                        newState.showCheckOutButton = true;
                    }

                    if (record.Day_Out_Timestamp__c) {
                        this.state.checkOutTime = new Date(record.Day_Out_Timestamp__c).toLocaleString();
                        newState.showCheckInButton = true;
                        newState.showCheckOutButton = false;
                        newState.attendanceCompleted = true;
                    }

                    this.state.dayInLat = record.Day_In_Lat__c;
                    this.state.dayInLong = record.Day_In_Long__c;
                    this.state.dayOutLat = record.Day_Out_Lat__c;
                    this.state.dayOutLong = record.Day_Out_Long__c;
                    
                    this.state = {...newState};
                }
            })
            .catch(error => {
                console.error('Error loading attendance:', error);
                this.showToast('Error', 'Failed to load attendance data', 'error');
            })
            .finally(() => {
                this.state.isLoading = false;
            });
    }

    handleBlockChange(event) {
        this.selectedBlock = event.detail.value;
    }

    async handleCheckIn() {
        if (!this.selectedBlock) {
            this.showToast('Error', 'Please select a location before checking in', 'error');
            return;
        }

        try {
            this.state.isLoading = true;
            const location = await this.getLocation();
            const now = new Date();
            
            await handleAttendance({
                actionType: 'Check-In',
                block: this.selectedBlock,
                timestamp: now.toISOString(),
                dayInLat: location.latitude,
                dayInLong: location.longitude,
                dayOutLat: null,
                dayOutLong: null
            });

            // Update state immutably
            this.state = {
                ...this.state,
                checkInTime: now.toLocaleString(),
                dayInLat: location.latitude,
                dayInLong: location.longitude,
                showCheckInButton: false,
                showCheckOutButton: true,
                attendanceCompleted: false,
                isLoading: false
            };
this.isBlockDisabled=true;
            this.showToast('Success', 'Checked in successfully at ' + this.selectedBlock, 'success');
        } catch (error) {
            console.error('Check-in error:', error);
            this.showToast('Error', error.body?.message || error.message || 'Check-in failed', 'error');
            this.state.isLoading = false;
        }
    }

    async handleCheckOut() {
        try {
            this.state.isLoading = true;
            const location = await this.getLocation();
            const now = new Date();
            
            await handleAttendance({
                actionType: 'Check-Out',
                //block: this.selectedBlock,
                timestamp: now.toISOString(),
                dayInLat: null,
                dayInLong: null,
                dayOutLat: location.latitude,
                dayOutLong: location.longitude
            });

            // Update state immutably
            this.state = {
                ...this.state,
                checkOutTime: now.toLocaleString(),
                dayOutLat: location.latitude,
                dayOutLong: location.longitude,
                showCheckInButton: true,
                showCheckOutButton: false,
                attendanceCompleted: true,
                isLoading: false
            };

            this.showToast('Success', 'Checked out successfully from ' + this.selectedBlock, 'success');
        } catch (error) {
            console.error('Check-out error:', error);
            this.showToast('Error', error.body?.message || error.message || 'Check-out failed', 'error');
            this.state.isLoading = false;
        }
    }

    getLocation() {
        return new Promise((resolve, reject) => {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    position => resolve({
                        latitude: position.coords.latitude,
                        longitude: position.coords.longitude
                    }),
                    error => reject(new Error(
                        error.code === error.PERMISSION_DENIED 
                            ? 'Location access denied by user' 
                            : 'Failed to get location'
                    ))
                );
            } else {
                reject(new Error('Geolocation not supported'));
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
            mode: 'dismissable'
        }));
    }
}