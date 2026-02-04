// workOrderList.js
import { LightningElement, wire, api } from 'lwc';
import getWorkOrdersByMetadata from '@salesforce/apex/WorkOrderController.getWorkOrdersByMetadata';
import getUserInfo from '@salesforce/apex/WorkOrderController.getUserInfo';

export default class WorkOrderList extends LightningElement {
  @api listViewName = 'Default_Work_Order_List'; // Can be overridden via component attribute

  workOrders = [];
  columns = [];
  isLoading = true;
  errorMessage = '';
  sortedBy;
  sortDirection = 'asc';

  get hasRecords() {
    return this.workOrders && this.workOrders.length > 0;
  }

  connectedCallback() {
    this.loadWorkOrders();
  }

  async loadWorkOrders() {
    try {
      this.isLoading = true;
      this.errorMessage = '';

      // Get user information
      const userInfo = await getUserInfo();
      console.log('User Info:', userInfo);

      // Fetch work orders and columns from metadata
      const result = await getWorkOrdersByMetadata({
        listViewName: this.listViewName,
        userId: userInfo.Id,
        profileName: userInfo.ProfileName,
        roleName: userInfo.RoleName
      });

      console.log('Result:', result);

      if (result.success) {
        this.workOrders = result.data;
        this.columns = result.columns;
        console.log('Work Orders:', this.workOrders);
        console.log('Columns:', this.columns);
      } else {
        this.errorMessage = result.message || 'Failed to load Work Orders';
        this.workOrders = [];
        this.columns = [];
      }
    } catch (error) {
      console.error('Error:', error);
      this.errorMessage = `Error: ${error.body?.message || error.message}`;
      this.workOrders = [];
      this.columns = [];
    } finally {
      this.isLoading = false;
    }
  }

  handleSort(event) {
    const { fieldName, sortDirection } = event.detail;
    this.sortedBy = fieldName;
    this.sortDirection = sortDirection;

    // Sort data
    const parseData = JSON.parse(JSON.stringify(this.workOrders));
    
    let keyValue = (a) => a[fieldName];
    if (fieldName === 'CreatedDate') {
      keyValue = (a) => new Date(a[fieldName]);
    }

    let isReverse = sortDirection === 'asc' ? 1 : -1;

    parseData.sort((x, y) => {
      x = keyValue(x) ? keyValue(x) : '';
      y = keyValue(y) ? keyValue(y) : '';
      return isReverse * ((x > y) - (y > x));
    });

    this.workOrders = parseData;
  }
}