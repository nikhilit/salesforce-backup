import { LightningElement, api } from 'lwc';

import isAccountFlagged from '@salesforce/apex/AS_AccountValidationService.isAccountFlagged';
import isDomestic from '@salesforce/apex/AS_AccountValidationService.isDomestic';
import getTodayAttendance from '@salesforce/apex/AttendanceController.getTodayAttendance';

import ACCOUNT_VALIDATION_LABEL from '@salesforce/label/c.AS_AccValidationAlert';

export default class AccountValidator extends LightningElement {
    @api workOrderId; 
    showToast = false;
    customLabel = ACCOUNT_VALIDATION_LABEL;
    message = '';
    isDomestic = false;
 
    connectedCallback() {

        this.getFlowDetails();

        this.getAttendanceData();
        
        // if(this.isDomestic){
        //     this.validateAccountFlag();
        // }else{
        //     this.getAttendanceData();
        //     this.validateAccountFlag();
        // }
    }

    async validateAccountFlag() {
        try {
            const result = await isAccountFlagged({ workOrderId: this.workOrderId });

            console.log('------result-------->', JSON.stringify(result));
            if(result.Remarks__c){
                this.showToast = true;
                this.message = result.Remarks__c + ' ' + this.customLabel;
            }
        } catch (error) {
            console.error('Apex call failed:', error);
        }
    }

    async getFlowDetails() {
        try {
            this.isDomestic = await isDomestic();
        } catch (error) {
            console.error('Apex call failed:', error);
        }
    }

    async getAttendanceData() {
        try {
            const wrapper = await getTodayAttendance();
            console.log('Attendance Wrapper',wrapper);

            if (wrapper && wrapper.attendance) {
                const record = wrapper.attendance;
                const hasMarkedIn = record.Status__c === 'Present' && record.Day_In_Timestamp__c;
                const hasMarkedOut = record.Day_Out_Timestamp__c;

                const now = new Date();
                const limitTime = new Date();
                limitTime.setHours(23, 30, 0); // 11:30 PM

                if (!hasMarkedIn) {
                    this.showToast = true;
                    this.message = 'You must mark attendance before starting a visit.';
                    return;
                }

                if (hasMarkedOut) {
                    this.showToast = true;
                    this.message = 'You have already checked out for the day. No further activities are allowed.';
                    return;
                }

                if (now > limitTime) {
                    this.showToast = true;
                    this.message = 'You cannot start an activity after 11:30 PM.';
                    return;
                }
            } else {
                this.showToast = true;
                this.message = 'Attendance record not found. Please mark attendance first.';
            }
        } catch (error) {
            console.error('Error fetching attendance data:', error);
            this.showToast = true;
            this.message = 'Error fetching attendance data. Please try again.';
        }
    }

    closeToast() {
        this.showToast = false;
    }
}