import { LightningElement, wire } from 'lwc';
import getReports from '@salesforce/apex/DailyTrackingRealtimeController.getReports';
import getReport from '@salesforce/apex/DailyTrackingRealtimeController.getReport';
import getReportIdByName from '@salesforce/apex/DailyTrackingRealtimeController.getReportIdByName';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DailyTrackingRealtime extends NavigationMixin(LightningElement) {

    reports = [];
    selectedReport;
    reportData;
    refreshInterval;
    error;
    isLoading = false;

    // Mapping of report display names to Salesforce report names
    reportMapping = {
        // Opening Reports
        'Email + Web - Opening': 'Opening Cases(Email + Web)',
        'MGL Connect - Opening': 'Opening Cases(MGL Connect)',
        'Critical Cases - Opening': 'Opening Cases(Critical Cases)',
        'Email FRL - Opening': 'Opening Email FRL Report',
        'Letter FRL - Opening': 'Opening Letter FRL Report',
        'Letter - Opening': 'Opening Letters Report',
        
        // Old Received Reports (only for back office)
        'Email + Web - Old Received': 'Old Received Cases(Email + Web)',
        'MGL Connect - Old Received': 'Old Received Cases(MGL Connect)',
        'Critical Cases - Old Received': 'Old Received Cases(Critical)',
        
        // New Received Reports (only for back office)
        'Email + Web - New Received': 'New Received Cases(Email + Web)',
        'MGL Connect - New Received': 'New Received Cases(MGL Connect)',
        'Critical Cases - New Received': 'New Received Cases(Critical)',
        
        // CR Received Reports (only for back office)
        'Email + Web - CR Received': 'CR Received (Email + Web) Report',
        'MGL Connect - CR Received': 'CR Received (MGL Connect) Report',
        'Critical Cases - CR Received': 'CR Received (Critical) Report',
        
        // Done Categorized Reports
        'Email + Web - Done Categorized': 'Done Categorized (Email + Web)',
        'MGL Connect - Done Categorized': 'Done Categorized (MGL Connect)',
        'Critical Cases - Done Categorized': 'Done Categorized (Critical)',
        'Email FRL - Done': 'Done Email FRL Report',
        'Letter FRL - Done': 'Done Letter FRL Report',
        'Letter - Done': 'Done Letters Report',
        
        // Done CR Reports (only for back office)
        'Email + Web - Done CR': 'Done CR Cases (Email + Web)',
        'MGL Connect - Done CR': 'Done CR Cases (MGL Connect)',
        'Critical Cases - Done CR': 'Done CR Cases (Critical)',

        
        // Pending Reports
        'Email + Web - Pending': 'Pending Report (Email + Web)',
        'MGL Connect - Pending': 'Pending Report (MGL Connect)',
        'Critical Cases - Pending': 'Pending Report (Critical)',
        'Email FRL - Pending': 'Pending Email FRL Report',
        'Letter FRL - Pending': 'Pending Letter FRL Report',
        'Letter - Pending': 'Pending Letters Report',
        
        // Received Reports (for simple reports)
        'Email FRL - Received': 'Received Email FRL Report',
        'Letter FRL - Received': 'Received Letter FRL Report',
        'Letter - Received': 'Received Letters Report'
    };

    @wire(getReports)
    wiredReports({ data, error }) {
        if (data) {
            this.reports = data;
        } else if (error) {
            this.error = error;
            console.error('Error loading reports:', error);
        }
    }

    handleSelect(event) {
        this.selectedReport = event.target.label;
        this.isLoading = true;
        this.loadData();

        // Set up auto-refresh every 2 seconds
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
        
        this.refreshInterval = setInterval(() => {
            this.loadData();
        }, 2000);
    }

    loadData() {
        getReport({ reportName: this.selectedReport })
            .then(result => {
                if (result) {
                    this.reportData = result;
                    this.isLoading = false;
                }
            })
            .catch(error => {
                this.error = error;
                this.isLoading = false;
                console.error('Error loading report:', error);
            });
    }

    handleBack() {
        clearInterval(this.refreshInterval);
        this.selectedReport = null;
        this.reportData = null;
        this.error = null;
        this.isLoading = false;
    }

    // Handle cell click to navigate to report
    async handleCellClick(event) {
        const cellType = event.currentTarget.dataset.type;
        const reportType = this.selectedReport;
        
        console.log('Cell clicked:', cellType);
        console.log('Current report type:', reportType);
        
        // Special handling for "Done Categorized" and "Done CR" cells
        let reportKey;
        
        if (cellType === 'Done Categorized') {
            // For "Done Categorized", we need to map it correctly
            reportKey = `${reportType} - Done Categorized`;
        } else if (cellType === 'Done CR') {
            // For "Done CR", we need to map it correctly
            reportKey = `${reportType} - Done CR`;
        } else if (cellType === 'Received' && ['Email FRL', 'Letter FRL', 'Letter'].includes(reportType)) {
            // For simple reports
            reportKey = `${reportType} - Received`;
        } else if (cellType === 'Done' && ['Email FRL', 'Letter FRL', 'Letter'].includes(reportType)) {
            // For simple reports
            reportKey = `${reportType} - Done`;
        } else {
            // For other cells
            reportKey = `${reportType} - ${cellType}`;
        }
        
        console.log('Constructed report key:', reportKey);
        
        const reportName = this.reportMapping[reportKey];
        console.log('Mapped report name:', reportName);
        
        if (reportName) {
            await this.navigateToReportByName(reportName);
        } else {
            console.warn(`No report found for key: ${reportKey}`);
            this.showToast('Error', `Report not found for ${cellType}`, 'error');
        }
    }

    // Navigate to report by name
    async navigateToReportByName(reportName) {
        try {
            // Get report ID from Apex
            const reportId = await getReportIdByName({ reportName: reportName });
            
            if (reportId) {
                this.navigateToReportById(reportId);
            } else {
                console.error(`Report not found: ${reportName}`);
                this.showToast('Error', `Report "${reportName}" not found`, 'error');
            }
        } catch (error) {
            console.error('Error navigating to report:', error);
            this.showToast('Error', 'Failed to navigate to report', 'error');
        }
    }

    // Navigate to report by ID
    navigateToReportById(reportId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: reportId,
                actionName: 'view'
            }
        });
    }

    // Alternative: Use simple URL navigation (works in most cases)
    navigateToReportSimple(reportId) {
        window.open(`/lightning/r/Report/${reportId}/view`, '_blank');
    }

    // Show toast message
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }

    // Getters for template
    get hasData() {
        return !this.isLoading && this.reportData;
    }

    get currentReportData() {
        // Return report data or default values
        if (this.reportData) {
            return {
                opening: this.reportData.opening || 0,
                oldReceived: this.reportData.oldReceived || 0,
                newReceived: this.reportData.newReceived || 0,
                crReceived: this.reportData.crReceived || 0,
                doneCategorized: this.reportData.doneCategorized || 0,
                doneCR: this.reportData.doneCR || 0,
                totalDone: this.reportData.totalDone || 0,
                received: this.reportData.received || 0,
                pending: this.reportData.pending || 0
            };
        }
        return {
            opening: 0,
            oldReceived: 0,
            newReceived: 0,
            crReceived: 0,
            doneCategorized: 0,
            doneCR: 0,
            totalDone: 0,
            received: 0,
            pending: 0
        };
    }

    get showBackOfficeColumns() {
        return ['Email + Web', 'MGL Connect', 'Critical Cases'].includes(this.selectedReport);
    }

    get showSimpleColumns() {
        return ['Email FRL', 'Letter FRL', 'Letter'].includes(this.selectedReport);
    }

    // Cleanup interval on component destruction
    disconnectedCallback() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
    }
}