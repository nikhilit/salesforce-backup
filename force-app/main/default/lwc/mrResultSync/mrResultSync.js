import { LightningElement, api, wire, track } from 'lwc';
import fetchSAPData from '@salesforce/apex/MRResultCallout.fetchSAPData';
import updateMRResult from '@salesforce/apex/MRResultCallout.updateMRResult';
import getDeviceNumber from '@salesforce/apex/MRResultCallout.getInstallationNumber';
import createMRResult from '@salesforce/apex/MRResultCallout.createMRResult'
import plausibilityCheckLogic from '@salesforce/apex/MeterReadingPlausibilityCheckHelper.plausibilityCheckLogic';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, MessageContext } from 'lightning/messageService';
import MR_RESULT from '@salesforce/messageChannel/mrresult__c';

const BP_FIELD = 'Account.BP_Number__c';

export default class MrResultSync extends LightningElement {
    @api recordId;
    bpId;
    @track sapData = [];
    statusMessage;
    @track errmsg = undefined;
    error;
    isLoading = false;
    @track device;
    @track error;

    // For new row
    @track showNewRow = false;
    @track newRow = {
        reading: '',
    };

    @wire(getRecord, { recordId: '$recordId', fields: [BP_FIELD] })
    wiredAccount({ error, data }) {
        if (data) {
            const bpId = data.fields.BP_Number__c.value;
            this.fetchDevice(bpId);
        } else if (error) {
            this.error = error.body?.message || error.message;
            console.error('Error fetching Account:', error);
        }
    }
    @wire(MessageContext)
messageContext;

    fetchDevice(bpId) {
        getDeviceNumber({ bpNumber: bpId })
            .then(result => {
                this.device = result;
                console.log(' this.device ',this.device);
                this.callSAP();
            })
            .catch(err => {
                this.error = err.body?.message || err.message;
                console.error('Error fetching Device:', err);
            });
    }

    // Show New Row
    handleNew() {
        this.showNewRow = true;
        this.newRow = { reading: ''};
    }

    // Capture input for new row
    handleNewInputChange(event) {
        const field = event.target.dataset.field;
        this.newRow = { ...this.newRow, [field]: event.target.value };
    }

    // Proper date parsing for DD/MM/YYYY format
    parseDate(dateString) {
        if (!dateString) return new Date();
        try {
            const parts = dateString.split('/');
            if (parts.length === 3) {
                // DD/MM/YYYY format
                return new Date(parseInt(parts[2]), parseInt(parts[1]) - 1, parseInt(parts[0]));
            }
            // Fallback for other formats
            return new Date(dateString);
        } catch (e) {
            console.error('Date parsing error:', e);
            return new Date();
        }
    }

    // Calculate average daily consumption from RECENT historical data only
calculateAverageDailyConsumption(sortedRows) {
    // Removed MR_TYPE filter - use all rows
    const allRows = sortedRows;
    
    if (allRows.length < 2) {
        console.log('Not enough historical data to calculate average daily consumption');
        return 0;
    }

    // USE ONLY RECENT PERIODS (latest 6 readings) instead of all historical data
    const recentRows = allRows.slice(0, 6);
    console.log('Using recent periods:', recentRows.length);
    
    let totalDailyConsumption = 0;
    let validPeriods = 0;

    // Calculate consumption between consecutive readings
    for (let i = 0; i < recentRows.length - 1; i++) {
        const currentRow = recentRows[i];
        const previousRow = recentRows[i + 1];
        
        // Parse readings
        const currentReading = parseFloat(currentRow.MR_READING.replace(/,/g, ''));
        const previousReading = parseFloat(previousRow.MR_READING.replace(/,/g, ''));
        
        // Parse dates CORRECTLY using our custom parser
        const currentDate = this.parseDate(currentRow.MR_DATE);
        const previousDate = this.parseDate(previousRow.MR_DATE);
        
        // Calculate days between readings
        const timeDiff = currentDate.getTime() - previousDate.getTime();
        const daysBetween = Math.max(1, timeDiff / (1000 * 3600 * 24)); // At least 1 day
        
        // Calculate consumption
        const consumption = currentReading - previousReading;
        
        if (consumption >= 0 && daysBetween > 0) {
            const dailyConsumption = consumption / daysBetween;
            totalDailyConsumption += dailyConsumption;
            validPeriods++;
            
            console.log(`Recent Period ${i+1}: ${previousReading} -> ${currentReading} = ${consumption} units over ${daysBetween} days = ${dailyConsumption.toFixed(2)} units/day`);
            console.log(`Date range: ${previousRow.MR_DATE} to ${currentRow.MR_DATE}`);
        }
    }

    const averageDailyConsumption = validPeriods > 0 ? totalDailyConsumption / validPeriods : 0;
    console.log(`Average Daily Consumption (Recent): ${averageDailyConsumption.toFixed(2)} units/day (from ${validPeriods} recent periods)`);
    
    return averageDailyConsumption;
}

// Save new row
handleNewSave() {
    const { reading } = this.newRow;

    // Validate input
    if (!reading || isNaN(reading)) {
        this.showToast('Error', 'Please enter a valid meter reading', 'error');
        return;
    }

    this.isLoading = true;

    console.log('🔍 === STARTING COMPLETE DEBUG ===');
    
    const sortedRows = [...this.sapData].sort(
        (a, b) => new Date(this.parseDate(b.MR_DATE)) - new Date(this.parseDate(a.MR_DATE))
    );
    const sortedRows1 = [...this.sapData]
    .filter(row => row.MR_TYPE === '01')
    .sort((a, b) => new Date(this.parseDate(b.MR_DATE)) - new Date(this.parseDate(a.MR_DATE)));
    
    const latestRow = sortedRows1[0];
    console.log('📊 Latest row found:', latestRow);

    if (!latestRow) {
        this.showToast('Error', 'No historical data found for plausibility check', 'error');
        this.isLoading = false;
        return;
    }

    const previousReading = latestRow && latestRow.MR_READING
        ? parseFloat(latestRow.MR_READING.replace(/,/g, ''))
        : 0;

    const lastReadingDate = latestRow && latestRow.MR_DATE 
        ? this.parseDate(latestRow.MR_DATE)
        : new Date();

    const now = new Date();
    const daysDiff = Math.max(1, Math.floor((now - lastReadingDate) / (1000 * 3600 * 24)));

    // Calculate AVERAGE DAILY CONSUMPTION (USING ONLY RECENT DATA)
    const averageDailyConsumption = this.calculateAverageDailyConsumption(sortedRows);

    console.log('🎯 === CRITICAL VALUES ===');
    console.log('Previous Reading:', previousReading);
    console.log('New Reading:', reading);
    console.log('Last Reading Date:', lastReadingDate);
    console.log('Current Date:', now);
    console.log('Days Difference:', daysDiff);
    console.log('Average Daily Consumption:', averageDailyConsumption);

    const actualConsumption = parseFloat(reading) - previousReading;

    console.log('⚖️ === VALIDATION CHECK ===');
    console.log('Actual consumption:', actualConsumption);

    // Convert date for Apex
    const apexDate = new Date(lastReadingDate.getFullYear(), lastReadingDate.getMonth(), lastReadingDate.getDate());

    console.log('📤 === VALUES SENT TO APEX ===');
    console.log('previousReading:', previousReading);
    console.log('currentReading:', parseFloat(reading));
    console.log('lastReadingDate:', apexDate);
    console.log('averageConsumption:', averageDailyConsumption);

    // Call Apex
    plausibilityCheckLogic({
        previousReading: previousReading,
        currentReading: parseFloat(reading),
        lastReadingDate: apexDate,
        averageConsumption: averageDailyConsumption
    })
    .then(checkResult => {
        console.log('📥 === APEX RESPONSE ===');
        console.log('Apex Result:', JSON.stringify(checkResult));
        console.log('Apex valid:', checkResult.valid);
        console.log('Apex message:', checkResult.message);
        console.log('Apex check:', checkResult.check);

        // MODIFIED VALIDATION: Block only negative, allow everything else with toast messages
        if (checkResult.valid === false) {
            // Check what type of validation failed
            if (checkResult.check === 'Negative') {
                // BLOCK negative consumption
                this.showToast('Validation Failed', checkResult.message, 'error');
                this.isLoading = false;
                return;
            } else if (checkResult.check === 'Zero' || checkResult.check === 'High' || checkResult.check === 'Low') {
                // ALLOW zero, high, and low consumption - show warning but proceed
                console.log('⚠️ ' + checkResult.check + ' consumption detected - ALLOWING to proceed');
                this.showToast('Validation Warning', checkResult.message  , 'warning');
                // Continue with save below
            } else {
                // For any other validation failures, block
                this.showToast('Validation Failed', checkResult.message, 'error');
                this.isLoading = false;
                return;
            }
        }

        console.log('✅ VALIDATION PASSED - PROCEEDING WITH SAVE');

        // Rest of your save logic...
        const options = {
            month: 'numeric',
            day: 'numeric',
            year: '2-digit',
            hour: 'numeric',
            minute: '2-digit',
            hour12: true
        };
        const actualMrDateTime = now.toLocaleString('en-GB', options).replace(',', '');
        const scheduledMrDate = now.toLocaleDateString('en-GB');

        return createMRResult({
            meterNumber: this.device,
            meterReadingDate: now.toISOString().split('T')[0],
            meterReading: reading,
            reason: '09',
            mrtype: '02',
            status: '1',
            actualReadingDate: now.toISOString().split('T')[0],
            scheduledMrDate: scheduledMrDate,
            actualMrDateTime: actualMrDateTime
        });
    })
    .then(result => {
        if (result) {
            this.showToast('Success', 'New Meter Reading saved', 'success');
            this.showNewRow = false;
            this.newRow = { reading: '' };
            this.callSAP();
        }
    })
    .catch(error => {
        this.showToast('Error', error.body?.message || error.message, 'error');
        console.error('Error:', error);
    })
    .finally(() => {
        this.isLoading = false;
    });
}

    callSAP() {
        this.isLoading = true;
        this.error = undefined;

        fetchSAPData({ device: this.device })
            .then(result => {
                console.log('SAP raw result:', JSON.stringify(result));
                this.statusMessage = result.statusMessage;

                const rows = result.sapData || [];
                this.sapData = rows.map(row => ({
                    ...row,
                    key: row.DEVICE + '_' + row.MR_DATE,
                    editKey: row.DEVICE + '_' + row.MR_DATE + '_edit',
                    showEdit: false,
                    editDate: row.MR_DATE,
                    editReading: row.MR_READING,
                    formattedTime: this.formatTime(row.ACTUAL_MR_TIME)
                }));
                publish(this.messageContext, MR_RESULT, {
    message: 'MR data refreshed',
    bpnumber: this.recordId
});


            })
            .catch(error => {
                this.error = error.body?.message || error.message;
                console.error('SAP Callout Error:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    formatTime(time) {
        if (!time) return '';
        const str = time.toString().padStart(4, '0');
        return `${str.substring(0,2)}:${str.substring(2,4)}`;
    }

    handleRefresh() {
        this.callSAP();
    }

    handleInputChange(event) {
        const recordId = event.target.dataset.id;
        const label = event.target.label;
        const value = event.target.value;

        this.sapData = this.sapData.map(row => {
            if (row.FIELD_NAME === recordId) {
                if (label === 'Meter Reading Date') row.editDate = value;
                if (label === 'Meter Reading') row.editReading = value;
                if (label === 'Remarks') row.editRemarks = value;
            }
            return row;
        });
    }

    handleSave(event) {
        const recordKey = event.currentTarget.dataset.id;
        const record = this.sapData.find(r => r.key === recordKey);

        if (!record.editDate || !record.editReading) {
            this.showToast('Error', 'Please provide Meter Reading Date and Meter Reading', 'error');
            return;
        }

        this.isLoading = true;

        updateMRResult({
            meterNumber: record.DEVICE,
            meterReadingDate: record.editDate,
            meterReading: record.editReading,
            remarks: record.editRemarks
        })
            .then(result => {
                this.showToast('Success', 'Meter reading updated successfully', 'success');
                console.log('Update Result:', result);

                this.sapData = this.sapData.map(row => {
                    if (row.key === recordKey) {
                        row.showEdit = false;
                        row.MR_DATE = record.editDate;
                        row.MR_READING = record.editReading;
                    }
                    return row;
                });
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || error.message, 'error');
                console.error('Update Error:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}