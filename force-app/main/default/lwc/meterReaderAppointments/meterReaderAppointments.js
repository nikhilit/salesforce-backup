import { LightningElement, track, wire } from 'lwc';
import { getListUi } from 'lightning/uiListApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import SERVICE_APPOINTMENT_OBJECT from '@salesforce/schema/ServiceAppointment';
import STATUS_FIELD from '@salesforce/schema/ServiceAppointment.Status';
import SCHEDULED_START from '@salesforce/schema/ServiceAppointment.SchedStartTime';
import SCHEDULED_END from '@salesforce/schema/ServiceAppointment.SchedEndTime';
// import PARENT_WORKORDER from '@salesforce/schema/ServiceAppointment.ParentRecordId';
import CUSTOMER_NAME from '@salesforce/schema/ServiceAppointment.Customer_Name__c';
import CUSTOMER_ADDRESS from '@salesforce/schema/ServiceAppointment.Customer_Address__c';
// import ASSIGNED_METER_READER from '@salesforce/schema/ServiceAppointment.Assigned_Meter_Reader__r';

import getAppointments from '@salesforce/apex/MeterReaderAppointmentController.getTodaysAppointmentsForUser';
import userId from '@salesforce/user/Id';

const TODAY = new Date().toISOString().split('T')[0];

export default class MeterReaderAppointments extends LightningElement {
  @track appointments = [];
  @track error;
  wiredResult;
  isLoading;

  // @wire(getListUi, {
  //   objectApiName: SERVICE_APPOINTMENT_OBJECT,
  //   listViewApiName: 'All_ServiceAppointments',
  //   sortBy: [],
  //   pageSize: 100
  // })
  // listViewHandler({ data, error }) {
  //   // this.showToast('Error geting list', TODAY, 'error');
  //   console.log("My todays list ", data);
  //   console.log("My todays list error", error);
  //   if (data) {
  //     const today = new Date().toISOString().split('T')[0];
  //     const records = data.records.records;
  //     this.appointments = records
  //       .map(record => {
  //         const status = record.fields[STATUS_FIELD.fieldApiName].value || '';
  //         const start = record.fields[SCHEDULED_START.fieldApiName].value || '';
  //         const end = record.fields[SCHEDULED_END.fieldApiName]?.value || '';
  //         const customerName = record.fields[CUSTOMER_NAME.fieldApiName]?.value || 'N/A';
  //         const customerAddress = record.fields[CUSTOMER_ADDRESS.fieldApiName]?.value || 'Address N/A';
  //         // const assignedMeterReader = record.fields[ASSIGNED_METER_READER.fieldApiName]?.value.fields.Id.value || '';
  //         // const assignedMeterReader = record.fields[ASSIGNED_METER_READER.fieldApiName]?.displayValue || '';
  //         // const parentName = record.fields[PARENT_WORKORDER.fieldApiName]?.displayValue || 'Customer';

  //         const startDate = start ? new Date(start).toISOString().split('T')[0] : '';
  //         if (startDate !== today) return null;

  //         // Derive custom status
  //         let visitStatus = 'Planned';
  //         if (status === 'Completed') {
  //           visitStatus = 'Completed';
  //         } else if (status === 'In Progress') {
  //           visitStatus = 'In Progress';
  //         }

  //         return {
  //           Id: record.id,
  //           CustomerName: customerName,
  //           Address: customerAddress,
  //           StartTime: new Date(start).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
  //           EndTime: end ? new Date(end).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '-',
  //           VisitStatus: visitStatus
  //         };
  //       })
  //       .filter(item => item !== null);
  //   } else if (error) {
  //     this.error = error.body.message || JSON.stringify(error);
  //     this.showToast('Error geting list', error.body.message, 'error');
  //   }
  // }

  @wire(getAppointments, { userId: userId })
  wiredAppointments(result) {
    this.isLoading = true;
    this.wiredResult = result;

    const { data, error } = result;
    if (data) {
      this.appointments = data.map(record => {
        let visitStatus = 'Planned';
        if (record.Status === 'Completed') visitStatus = 'Completed';
        else if (record.Status === 'In Progress') visitStatus = 'In Progress';
          
        return {
          Id: record.Id,
          CustomerName: record.Customer_Name__c || 'N/A',
          Address: record.Customer_Address__c || 'Address N/A',
          StartTime: new Date(record.SchedStartTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          EndTime: record.SchedEndTime ? new Date(record.SchedEndTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '-',
          VisitStatus: visitStatus
        };
      });
      this.isLoading = false;
    } else if (error) {
      this.isLoading = false;
      this.showToast('Error geting todays visits', JSON.stringify(error), 'error');
      this.error = error.body.message || JSON.stringify(error);
    }
  }

  handleRefresh() {
      this.isLoading = true;
    if (this.wiredResult) {
      refreshApex(this.wiredResult);
      this.isLoading = false;
    }
  }

  connectedCallback() {
    this.isLoading = true;
    this.handleRefresh();
    this.isLoading = false;
  }
  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

}