import { LightningElement, api, wire, track } from 'lwc';

// ---  (For Online Mode) ---
import isAccountFlagged from '@salesforce/apex/AS_AccountValidationService.isAccountFlagged';
import isDomestic from '@salesforce/apex/AS_AccountValidationService.isDomestic';
import getTodayAttendance from '@salesforce/apex/AttendanceController.getTodayAttendance';

// --- New Offline Imports (LDS & GraphQL) ---
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { graphql, gql } from 'lightning/uiGraphQLApi';
import USER_ID from '@salesforce/user/Id';
import ACCOUNT_VALIDATION_LABEL from '@salesforce/label/c.AS_AccValidationAlert';

// --- Schema Imports for Offline Data ---
import WO_REMARKS from '@salesforce/schema/WorkOrder.Remarks__c';
import WO_RT_DEV_NAME from '@salesforce/schema/WorkOrder.Record_Type_Developer_Name__c';

export default class AccountValidatorClone extends LightningElement {
    @api workOrderId; 
    showToast = false;
    customLabel = ACCOUNT_VALIDATION_LABEL;
    message = '';
    isDomestic = false;
    
    // Track offline state
    currentUserId = USER_ID;
    
    // -----------------------------------------------------------------------
    // 1. LIFECYCLE & ONLINE LOGIC
    // -----------------------------------------------------------------------
    connectedCallback() {
        if (navigator.onLine) {
            this.getFlowDetails();
            this.getAttendanceData();
            // if(this.isDomestic) { this.validateAccountFlag(); }
        }
    }

    async getFlowDetails() {
        try {
            this.isDomestic = await isDomestic();
        } catch (error) {
            console.error('Apex call failed:', error);
        }
    }

    async validateAccountFlag() {
        try {
            const result = await isAccountFlagged({ workOrderId: this.workOrderId });
            console.log('------result-------->', JSON.stringify(result));
            if(result && result.Remarks__c){
                this.showToast = true;
                this.message = result.Remarks__c + ' ' + this.customLabel;
            }
        } catch (error) {
            console.error('Apex call failed:', error);
        }
    }

    async getAttendanceData() {
        try {
            const wrapper = await getTodayAttendance();
                        console.log('Attendance Wrapper',wrapper);

            if (wrapper && wrapper.attendance) {
                this.validateAttendanceRecord(wrapper.attendance);
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

    // -----------------------------------------------------------------------
    // 2. OFFLINE LOGIC (LDS & GraphQL)
    // -----------------------------------------------------------------------

    

    // A. Wire WorkOrder to check Account Flag Offline (Replaces isAccountFlagged)
    @wire(getRecord, { recordId: '$workOrderId', fields: [WO_REMARKS, WO_RT_DEV_NAME] })
    wiredWorkOrder({ error, data }) {
        if (!navigator.onLine && data) {
            const rtName = getFieldValue(data, WO_RT_DEV_NAME);
            const remarks = getFieldValue(data, WO_REMARKS);

            if (rtName === 'MGL_R_T' && remarks) {
                this.showToast = true;
                this.message = remarks + ' ' + this.customLabel;
            }
        }
    }

    get todayDateString() {
        return new Date().toISOString().split('T')[0];
    }

    get todayDateInput() {
        return { value: this.todayDateString };
    }

    get localDateYYYYMMDD() {
        const d = new Date();
        const yyyy = d.getFullYear();
        const mm = String(d.getMonth() + 1).padStart(2, '0');
        const dd = String(d.getDate()).padStart(2, '0');
        return `${yyyy}-${mm}-${dd}`;
    }

    // -----------------------------
    // Complete Offline GraphQL Wire
    // -----------------------------
    @wire(graphql, {
        query: gql`
            query fetchOfflineData($userId: ID!, $today: DateInput!) {
                uiapi {
                    query {
                        Attendance__c(
                            where: {
                                User__c: { eq: $userId }
                                Attendance_Date__c: { eq: $today }
                            }
                            first: 1
                        ) {
                            edges {
                                node {
                                    Id
                                    Status__c { value }
                                    Day_In_Timestamp__c { value }
                                    Day_Out_Timestamp__c { value }
                                    Attendance_Locked__c { value }
                                }
                            }
                        }

                        ServiceResource(
                            where: {
                                RelatedRecordId: { eq: $userId }
                                Service_Resource_Type__c: { in: ["Collection Agent", "I&C Agent"] }
                            }
                            first: 1
                        ) {
                            edges {
                                node {
                                    Id
                                    Service_Resource_Type__c { value }
                                }
                            }
                        }
                    }
                }
            }
        `,
       variables: {
            userId: USER_ID,
            today: {
                value: (() => {
                    const d = new Date();          // device local time
                    const y = d.getFullYear();
                    const m = String(d.getMonth() + 1).padStart(2, '0');
                    const day = String(d.getDate()).padStart(2, '0');
                    return `${y}-${m}-${day}`;     // YYYY-MM-DD
                })()
            }
        }
    })
    wiredGraphData({ errors, data }) {
        // Run ONLY in Offline mode
        if (navigator.onLine) return;

        if (errors) {
        const msg =
            errors?.[0]?.message ||
            errors?.[0]?.error?.[0]?.message ||
            JSON.stringify(errors);

        console.error('GraphQL Error (full):', JSON.stringify(errors));
        this.showToast = true;
        this.message = 'Offline GraphQL error: ' + msg;
        return;
    }

        if (!data?.uiapi?.query) return;

        // -----------------------------
        // 1) Domestic Check (ServiceResource)
        // -----------------------------
        const srEdges = data.uiapi.query.ServiceResource?.edges || [];
        if (srEdges.length > 0) {
            const type = srEdges[0].node?.Service_Resource_Type__c?.value;
            this.isDomestic = !!(type && type.includes('Collection Agent'));
        } else {
            this.isDomestic = false;
        }

        // -----------------------------
        // 2) Attendance Check
        // -----------------------------
        const attEdges = data.uiapi.query.Attendance__c?.edges || [];
        if (attEdges.length > 0) {
            const node = attEdges[0].node;

            const attendanceRecord = {
                Status__c: node?.Status__c?.value,
                Day_In_Timestamp__c: node?.Day_In_Timestamp__c?.value,
                Day_Out_Timestamp__c: node?.Day_Out_Timestamp__c?.value,
                Attendance_Locked__c: node?.Attendance_Locked__c?.value
            };

            this.validateAttendanceRecord(attendanceRecord);
        } else {
            this.showToast = true;
            this.message = 'Attendance record not found (Offline). Please mark attendance first.';
        }
    }

    // -----------------------------------------------------------------------
    // 3. SHARED VALIDATION LOGIC
    // -----------------------------------------------------------------------
    
    // Centralized validation for both Online (Apex) and Offline (GraphQL) records
    validateAttendanceRecord(record) {
        if (!record) return;

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
    }

    closeToast() {
        this.showToast = false;
    }
}