/**
 * @description       : 
 * @author            : Neeraj dalal Appstrail
 * @group             : 
 * @last modified on  : 19-05-2025
 * @last modified by  : Neeraj dalal, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   16-05-2025   Neeraj dalal, Appstrail   Initial Version
**/
import { LightningElement, track, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getUserRec from '@salesforce/apex/O_MAutoHomePageComponentController.getUserName';
import getTBTWorkOrder from '@salesforce/apex/O_MAutoHomePageComponentController.getTBTWorkOrder';
import getKPIs from '@salesforce/apex/O_MDashboardContr.getKPIs';
import getCountByMetadataMatch from '@salesforce/apex/O_MDashboardContr.getCountByMetadataMatch';

import { NavigationMixin } from 'lightning/navigation';


/* ================= Offline (GraphQL) ================= */
import { gql, graphql,  refreshGraphQL } from 'lightning/uiGraphQLApi';
import USER_ID from '@salesforce/user/Id';

const GET_SERVICE_APPOINTMENTS = gql`
query getAssignedForOM($userId: ID!) {
  uiapi {
    query {
      AssignedResource(
        where: { ServiceResource: { RelatedRecordId: { eq: $userId } } }
        first: 2000
      ) {
        edges {
          node {
            Id
            ServiceAppointment {
              Id
              Status { value }
              Appointment_Type__c { value }
              Visit_Status__c { value }
              ParentRecord {
                __typename
                ... on WorkOrder {
                  Id
                  RecordType {
                    DeveloperName { value }
                  }
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

const GET_METADATA_CONFIG = gql`
query omConfig($departmentType: Picklist!) {
  uiapi {
    query {
      Metering_Dashboard_Config__mdt(
        where: { Active__c: { eq: true }, Department__c: { eq: $departmentType } }
        first: 200
      ) {
        edges {
          node {
            Id
            Label__c { value }
            Field_Api_Name__c { value }
            Values__c { value }
            Order__c { value }
            Card_Color__c { value }
            Icon_URL__c { value }
            Department__c { value }
          }
        }
      }
    }
  }
}
`;

const GET_TBT_WORKORDER = gql`
query getTBTStatus($userId: ID!) {
  uiapi {
    query {
      WorkOrder(
        where: {
          OwnerId: { eq: $userId }
          RecordType: {
            DeveloperName: { eq: "TBT" }
          }
        }
        first: 1
      ) {
        edges {
          node {
            Id
            Approval_Status__c {
              value
            }
          }
        }
      }
    }
  }
}
`;

export default class O_mmobileHomeRiserComp extends NavigationMixin(LightningElement) {
  /* --------- state --------- */
  @track userName = '';
  @track currentDate = '';
  @track currentTime = '';
  @track greeting = '';
  @track openMainPage = true;
  @track showDashboard = true;
  @track secondPage = false;
  @track showComponent3 = false;
  error;
  @track selectedStatus = '';
  wiredKpiResult;
  @track showChild = false;
  @track callPrent = false;
  @track showSpinner = false;
  @track isCheckedIn = false;
  @track showDropdown = false;
  @track isDisabled = false;
  @track attendanceStatus = '';
  @track showSubmitButton = false;
  @track attendanceMarked = false;
  @track selectedType;
  showAppointmentScreen;

  @track load=false;

  @track kpisResult = [];
  @track kpis = {};

  @track isOnline = navigator.onLine;
  @track refreshKey = 'init';
  departmentType = 'O&M';

  intervalId;
  autoRefreshTimer;
  recursion = false;

  @track showRejectedUploadTBT=false;

  /* ================= LIFECYCLE ================= */
  connectedCallback() {
    window.addEventListener('online', this.handleOnline);
    window.addEventListener('offline', this.handleOffline);
    this.isOnline = navigator.onLine;
    this.init();
          // this.getTBTWorkOrder();

  }

  disconnectedCallback() {
    clearInterval(this.autoRefreshTimer);
    clearInterval(this.intervalId);
    this.recursion = true;
    window.removeEventListener('online', this.handleOnline);
    window.removeEventListener('offline', this.handleOffline);
  }

  renderedCallback() {
    if (this.recursion) {
      this.init();
      this.recursion = false;
    }
    this.setCardColor();
  }

  /* ================= INIT & UI ================= */
  init() {
    this.cardDetails();
    if (this.isOnline) {
      this.getKPIData();

    } else {
      this.refreshKey = String(Date.now());
      this.showSpinner = true;
    }
  }

  cardDetails() {
    this.platform = FORM_FACTOR === 'Large' ? 'desktop' : 'mobile';
    this.updateTime();
    this.intervalId = setInterval(() => {
      this.updateTime();
    }, 30000);

    // throttled from 2000ms
    this.autoRefreshTimer = setInterval(() => {
      this.refreshDashboardData();
    }, 30000);
  }

  setCardColor() {
    this.kpisResult.forEach((item) => {
      const elm = this.template.querySelector('[data-card="' + item.label + '"]');
      if (elm) {
        elm.style = 'background-color:' + item.cardColor + ';';
      }
    });
  }

  updateTime() {
    const now = new Date();
    this.currentDate = now.toLocaleDateString(undefined, {
      weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
    });
    this.currentTime = now.toLocaleTimeString(undefined, {
      hour: '2-digit', minute: '2-digit'
    });
    this.setGreeting();
  }

  setGreeting() {
    const hour = new Date().getHours();
    const name = this.userName || 'User';
    if (hour < 12) {
      this.greeting = `Good Morning, ${name}`;
    } else if (hour < 17) {
      this.greeting = `Good Afternoon, ${name}`;
    } else {
      this.greeting = `Good Evening, ${name}`;
    }
  }

  /* ================= EVENTS ================= */
  handleOnline = () => {
    this.isOnline = true;
    this.showToast('Back Online', 'Switching to live data.', 'success');
    this.refreshDashboardData();
  };

  handleOffline = () => {
    this.isOnline = false;
    this.showToast('Offline Mode', 'Showing cached data from device.', 'info');
    this.refreshDashboardData();
  };

  handleGetStarted() {
    this.showDashboard = true;
  }

  get disabledClass() {
    return this.isCheckedIn ? '' : 'disabled-dashboard';
  }

  handleShowComponent3(event) {
    if (event.detail) {
      this.openMainPage = event.detail.openMainPage;
    }
  }

  handleNavigateHome() {
    this.secondPage = false;
    this.showDashboard = true;
    this.openMainPage = true;
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  /* ================= APEX (ONLINE) ================= */
  @wire(getUserRec)
  wiredUser({ error, data }) {
    if (data) {
      this.userName = data.userName;
      this.setGreeting();
    }
  }

 @wire(getKPIs)
  wiredKpis(result) {
    this.wiredKpiResult = result;
    if (this.isOnline) {         
      this.getKPIData();
      
    }
    const { data, error } = result;
    if (data && this.isOnline) { 
      this.kpis = data;
    } else if (error && this.isOnline) {
      this.error = error;
    }
  }


  getKPIData() {
  if (!this.isOnline) return;  // hard block offline
  return getCountByMetadataMatch()
    .then((result) => {
      this.kpisResult = result || [];
    })
    .catch(() => {
      // softer message; but won't execute offline due to guard above
      this.showToast('Error', 'Online data unavailable.', 'warning');
    });
}


  refreshDashboardData() {
    if (this.isOnline) {
      if (this.wiredKpiResult) {
        refreshApex(this.wiredKpiResult);
      }
    } else {
      this.refreshKey = String(Date.now());
    }
  }

  /* ================= NAV / CLICK ================= */
  onTotalClick() {
    this.selectedType = null;
    this.togglePage('total', null);
  }

  selectedType = 'All';
  onCardCLick(event) {
    const action = event.currentTarget.dataset.card;
    this.selectedType = 'All';
    switch (action) {
      case 'Unattempted':
        this.togglePage('unattempted', null);
        break;
      case 'Completed':
        this.togglePage('completed', null);
        break;
      case 'Incomplete':
        this.togglePage('incomplete', null);
        break;
      default:
        break;
    }
  }

  togglePage(status, appointmentType = null) {
    this.showSpinner = true;
    this.selectedType = appointmentType;

    this.showAppointmentScreen = true;
    this.selectedStatus = status;
    this.showChild = true;
    this.showDashboard = false;
    this.secondPage = true;
    this.openMainPage = false;

    setTimeout(() => {
      this.showSpinner = false;
    }, 1000);
  }

  handleChildEvent(event) {
    this.showAppointmentScreen = false;
    this.secondPage = event.detail.secondPage;
    this.showDashboard = event.detail.showDashboard;
    this.showChild = false;
    this.openMainPage = event.detail.openMainPage;
    this.callPrent = true;
    this.selectedType = 'All';
  }

  /* ================= OFFLINE (GraphQL) ================= */
  @track configList = [];
  @track serviceAppointments = [];
  _kpiBuilt = false;

  get configVariables() {
    return { departmentType: this.departmentType, refreshKey: this.refreshKey };
  }
  get apptVariables() {
    return { userId: USER_ID, refreshKey: this.refreshKey };
  }
  get configQuery() { return GET_METADATA_CONFIG; }
  get apptQuery() { return GET_SERVICE_APPOINTMENTS; }

  // MDT (O&M)
  @wire(graphql, { query: '$configQuery', variables: '$configVariables' })
  wiredConfigs({ data, error }) {
    if (this.isOnline) return;
    if (data) {
      const nodes = data?.uiapi?.query?.Metering_Dashboard_Config__mdt?.edges || [];
      this.configList = nodes.map(({ node }) => ({
        id: node.Id,
        label: node.Label__c?.value,
        fieldApiName: node.Field_Api_Name__c?.value, 
        values: (node.Values__c?.value || '')
          .split(',')
          .map((v) => v.trim().toLowerCase())
          .filter(Boolean),
        order: node.Order__c?.value,
        cardColor: node.Card_Color__c?.value,
        iconUrl: node.Icon_URL__c?.value,
        department: node.Department__c?.value
      }));
      this.tryBuildOfflineKPIs();
    }
  }

  // AssignedResource -> ServiceAppointment (O&M only)
  @wire(graphql, { query: '$apptQuery', variables: '$apptVariables' })
  wiredAppointments({ data, error }) {
    if (this.isOnline) return;
    if (data) {
      const edges = data?.uiapi?.query?.AssignedResource?.edges || [];
      const list = [];
      edges.forEach(({ node }) => {
        const sa = node?.ServiceAppointment;
        if (!sa) return;
        const rt = sa?.ParentRecord?.RecordType?.DeveloperName?.value;
        if (rt === 'MGL_O_M') {
          list.push({
            Id: sa.Id,
            Status: sa.Status?.value,
            Appointment_Type__c: sa.Appointment_Type__c?.value,
            Visit_Status__c: sa.Visit_Status__c?.value
          });
        }
      });
      this.serviceAppointments = list;
      this.tryBuildOfflineKPIs();
    }
  }

  tryBuildOfflineKPIs() {
    if (this.isOnline) return;
    if (this.configList.length === 0 || this.serviceAppointments.length === 0) return;

    this.showSpinner = true;
    const normalize = (val) => (val ? String(val).trim().toLowerCase() : '');

    const results = this.configList
      .map((meta) => {
        const field = meta.fieldApiName;
        const values = (meta.values || []).map((v) => normalize(v));

        const matched = this.serviceAppointments.filter((sa) => {
          let rawValue;
          if (field === 'Status') rawValue = sa.Status; else
          if (field === 'Visit_Status__c') rawValue = sa.Visit_Status__c; else
          if (field === 'Appointment_Type__c') rawValue = sa.Appointment_Type__c; else
            rawValue = sa[field];
          const candidate = normalize(rawValue);
          return values.includes(candidate);
        });

        return {
          label: meta.label,
          cardColor: meta.cardColor,
          iconUrl: meta.iconUrl,
          count: matched.length,
          listServiceAppointments: matched,
          order: meta.order
        };
      })
      .sort((a, b) => (a.order || 0) - (b.order || 0));

    this.kpisResult = results;
    this.kpis = this.buildOfflineSummary(this.serviceAppointments);
    this.showSpinner = false;
  }

  buildOfflineSummary(list) {
    const out = { total: 0, completed: 0, incomplete: 0, unattempted: 0 };
    if (!Array.isArray(list)) return out;

    const completed = new Set(['Completed']);
    const incomplete = new Set(['Cannot Complete', 'In Progress']);
    const unattempted = new Set(['Scheduled', 'None', 'Dispatched']);

    list.forEach((sa) => {
      out.total += 1;
      const st = sa?.Status || '';
      if (completed.has(st)) out.completed += 1; else
      if (incomplete.has(st)) out.incomplete += 1; else
      if (unattempted.has(st)) out.unattempted += 1;
    });
    return out;
  }

  @track tbtStatus = 'Upload TBT'; 
  @track tbtrecordid='';  
    wiredTbtResult;                   

  /*  @wire(getuploadtbt)
    wiredTbt(response) {
        this.wiredTbtResult = response;
        const { data, error } = response;

        if (data && data.length > 0) {
        
        this.tbtStatus = data[0].Approval_Status__c;
        this.tbtrecordid=data[0].Id;

        console.log('Geting workorder id for tbt::', this.tbtrecordid);
        if(this.tbtStatus == null || this.tbtStatus === 'Pending'){
            this.tbtStatus = 'Upload TBT';
        }
        if(this.tbtStatus === 'Rejected'){

          this.showRejectedUploadTBT=true;
           // this.tbtStatus = 'Upload TBT';

        }
        
      } else if (data && data.length === 0) {
   
        this.tbtStatus = 'Upload TBT';
    } else if (error) {
        console.error('Error in upload tbt o_mmobilehomerisercomp::',error);
        this.tbtStatus = 'Upload TBT';
    }
    } */

    getTBTWorkOrder(){

      getTBTWorkOrder()
      .then(result => {

        console.log('Get TBT Record Details ::', result);
 
    //  this.tbtStatus = 'Approval Status :' + result.Approval_Status__c;

    this.tbtStatus = `Approval Status : ${result.Approval_Status__c}`;

      console.log('tbtStatus ::', this.tbtStatus);
        this.tbtrecordid=result.Id;

      if(this.tbtStatus == null || this.tbtStatus === 'Pending'){
            this.tbtStatus = 'Upload TBT';
        }
        if(this.tbtStatus === 'Rejected'){

          this.showRejectedUploadTBT=true;
           // this.tbtStatus = 'Upload TBT';

        }
      })
      .catch(error => {

        console.log('Geting error for tbt record');
      })
    }

    handleuploadtbtdo() {
        console.log('Upload TBT');

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.tbtrecordid,
                objectApiName: 'WorkOrder',
                actionName: 'view'
            }
        });
    }

        handlerefreshtbtdo(event) {
          console.log('handlerefreshtbtdo::');

        
            event.stopPropagation(); 
              if (this.wiredTbtResult) {
        refreshApex(this.wiredTbtResult);
              }
    }

    wiredTBTWorkOrderResult;

 @wire(graphql, {
        query: GET_TBT_WORKORDER,
        variables: {
            userId: USER_ID
        }
    })
    wiredWorkOrder(result) {

      console.log('wiredWorkOrderTBT::');
        this.wiredTBTWorkOrderResult = result; 

        const { data, errors } = result;

        if (data) {
            const edges = data.uiapi.query.WorkOrder.edges;
            if (edges.length > 0) {
                const wo = edges[0].node;
                this.tbtrecordid = wo.Id;
                console.log('approval status:::',wo.Approval_Status__c.value);
                if(wo.Approval_Status__c.value !='Pending'){
                this.tbtStatus =  'Approval Status : ' + ' ' +  wo.Approval_Status__c.value;
                }
                else if (wo.Approval_Status__c.value == null || wo.Approval_Status__c.value === 'Pending'){
                  this.tbtStatus = 'Upload TBT';
                }else{
                  this.tbtStatus=wo.Approval_Status__c.value;
                }
              
            }
         
            console.log(' this.tbtStatus :::', this.tbtStatus );
            console.log(' this.tbtrecordid::::', this.tbtrecordid);

        } else if (errors) {
            console.error(errors);
        }
    }

    handletbtRefresh(event) {

         console.log('before true showspinner::', this.showSpinner);

  this.showSpinner = true;

 
        console.log('showspinner::', this.showSpinner);
      console.log('refresh::');
      event.stopPropagation(); 
        if (this.wiredTBTWorkOrderResult) {
          console.log('inside if::');
              refreshGraphQL(this.wiredTBTWorkOrderResult);
        }
           console.log('handletbtRefresh::');

           setTimeout(() => {
      this.showSpinner = false;
    }, 500);
 // }
    }

    


}