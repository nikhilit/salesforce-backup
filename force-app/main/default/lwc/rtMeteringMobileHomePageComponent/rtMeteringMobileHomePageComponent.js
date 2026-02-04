/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 03-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   16-05-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { LightningElement, track, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import MY_RESOURCE_NAME from '@salesforce/resourceUrl/MGL_Logo';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getUserRec from '@salesforce/apex/autoHomePageComponentController.getUserName';
import getKPIs from '@salesforce/apex/MeterReaderDashboardController.getKPIs';
import getCountByMetadataMatch from '@salesforce/apex/MeterReaderDashboardController.getCountByStatus';
import getUserDetails from '@salesforce/apex/WorkOrderCreationController.getUserDetails';
// Added by rishi
import { getRecord } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import { gql, graphql } from 'lightning/uiGraphQLApi';
const GET_ASSIGNED_RESOURCES = gql`
query getAssignedResources($userId: ID!) {
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
              SchedStartTime { value }
              SchedEndTime { value }
              Schedule_Start_Date__c { value }
              Schedule_End_Date__c { value }
              Appointment_Type__c { value }
              ParentRecord {
                ... on WorkOrder {
                  Id
                  RecordType { DeveloperName { value } }
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
query getConfigs($departmentType: Picklist!) {
  uiapi {
    query {
      Metering_Dashboard_Config__mdt(
        where: { 
          Active__c: { eq: true }, 
          Department__c: { eq: $departmentType }
        }, 
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
            Active__c { value }
          }
        }
      }
    }
  }
}
`;

const DEVELOPER_NAME_FILTER = 'MGL_Metering';

const GET_SERVICE_APPOINTMENTS = gql`
query getAssignedResources($userId: ID!) {
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
              SchedStartTime { value }
              SchedEndTime { value }
              Schedule_Start_Date__c { value }
              Schedule_End_Date__c { value }
              Indirect_Reading_Received__c { value }
              ParentRecord {
                ... on WorkOrder {
                  Id
                  RecordType { DeveloperName { value } }
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

const GET_SERVICE_RESOURCE = gql`
  query getServiceResource($userId: ID!) {
    uiapi {
      query {
        ServiceResource(
          where: { RelatedRecordId: { eq: $userId } }
          first: 1
        ) {
          edges {
            node {
              Id
              Name { value }
              Customer_Category__c { value }
              RelatedRecordId { value }
              ServiceTerritories {
                edges {
                  node {
                    ServiceTerritory {
                      Id
                      Name { value }
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


const GET_METER_SCHEDULES = gql`
  query getMeterSchedules($serviceResourceId: ID!) {
    uiapi {
      query {
        Meter_Reading_Schedule__c(
          where: {
            Agent__c: { eq: $serviceResourceId }
          }
          first: 50
        ) {
          edges {
            node {
              Id
              Meter_Reading_Start_Date__c { value }
              Meter_Reading_Completion_Date__c { value }
              Active__c { value }
            }
          }
        }
      }
    }
  }
`;


export default class rtMeteringMobileHomePageComponent extends LightningElement {
    mglLogo=MY_RESOURCE_NAME;
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
    @track refreshKey = true;
     @track isOnline = navigator.onLine;
     refreshKey;

    // showMessage=true;

    @api type='Metering';

    connectedCallback() {
       this.isOnline = navigator.onLine;
        this.init();
        this._onAppointmentsUpdated = () => {
        this.refreshKey = !this.refreshKey;
        this.handleRefresh();
      };
      window.addEventListener('metering:appointments-updated', this._onAppointmentsUpdated);
    }

    // disconnectedCallback() {
    //     // this.recursion=true;
    // }

    renderedCallback() {
        if (this.recursion) {
            this.init();
            this.recursion = false;
        }
        this.setCardColor();
    }

    kip;
    init() {
        this.showSpinner  = true;
        this.updateTime();
        this.cardDetails();
        if(this.isOnline){
            this.getUserDetailsFunc(); 
          this.getKPIData();
        }      
    }

     handleRefresh() {
      this._kpiReady = false;
        if (this.isOnline) {
            refreshApex(this.wiredKpiResult);
            refreshApex(this.MetadataMatch);
            this.init();
             this.showToast('Success', 'The Dashboard Refreshed successfully.', 'success')
        } else {
            this.refreshKey = !this.refreshKey; // triggers GraphQL refresh
            this.showToast('Success', 'The Dashboard Refreshed successfully.', 'success')
        }
    }



    setCardColor() {
        this.kpisResult.forEach(item => {
            var elm = this.template.querySelector('[data-card="' + item.label + '"]');
            if (elm) {
                elm.style = 'background-color:' + item.cardColor + ';';
            }
        })
    }

    @track kpisResult = [];

    getKPIData() {
      if (!this.isOnline) return; // skip when offline
        this.kpisResult = [];
        getCountByMetadataMatch({ type: this.type })
            .then(result => {
                this.kpisResult = result;
                console.log('kpisResult:' + JSON.stringify(this.kpisResult));
            })
            .catch(error => {
                console.log('error:' + JSON.stringify(error));
                this.showToast('Error', 'Something went wrong.', 'error')
            });
    }

   // Commented by rishi
    MetadataMatch;
    @wire(getCountByMetadataMatch,{type:'$type'})
    CountByMetadataMatch(result) {
      if (!this.isOnline) return; // skip when offline
        this.MetadataMatch = result;
        const { data, error } = result;
        if (data) {
            this.kpisResult = data;
            refreshApex(this.wiredUserDetailsResult);
        } else if (error) {
            this.error = error;
        }
    } 
    // Rishi added changes start        
  @track configList = [];
  @track serviceAppointments = [];
 
   
  // Step 1: Fetch custom metadata config records
  //departmentType = 'Metering'; 
  @track _kpiReady = false;

  // get departmentType() {
  //   return this.type === 'MRS Metering' ? 'MRS Metering' : 'Metering';
  // }

  get departmentType() {
    const cat = (this.userDetails?.agentDetails?.customerCategory || '').toLowerCase();
    if (cat.includes('mrs') || cat.includes('cng') || cat.includes('lng')) return 'MRS Metering';
    return 'Metering';
  }

 @wire(graphql, { 
  query: GET_METADATA_CONFIG, 
  variables: '$configVariables'})
  wiredConfigs({ error, data }) {
    if (this.isOnline) return; // skip when online
    if (data && !this.isOnline) {
      //this.showToast('GraphQL', `Configs refreshed `, 'success');
      this.configList = data.uiapi.query.Metering_Dashboard_Config__mdt.edges.map(edge => {
        return {
          Id: edge.node.Id,
          label: edge.node.Label__c.value,
          fieldApiName: edge.node.Field_Api_Name__c.value,
          values: (edge.node.Values__c.value || '') ? edge.node.Values__c.value.split(',').map(v => v.trim()) : [],
          order: edge.node.Order__c.value,
          cardColor: edge.node.Card_Color__c.value,
          iconUrl: edge.node.Icon_URL__c.value,
          department: edge.node.Department__c.value,
          active: edge.node.Active__c.value
        };
      });
      const userCat = this.userDetails?.agentDetails?.customerCategory || 'Unknown';
      const deptQueried = this.departmentType || 'Not set';
      const deptList = [...new Set(this.configList.map(c => c.department))];

      // this.showToast(
      //   'Debug – Metadata Check',
      //   `Customer Category: ${userCat}\nQueried Department: ${deptQueried}\nFetched ${this.configList.length} configs.\nDepartments Found: ${deptList.join(', ') || 'None'}`,
      //   'info'
      // );
      this.checkAndGenerateKPIs();
    } else if (error) {
      this.error = error;
      this.showToast('GraphQL', `Config refresh error: ${error.body?.message || error}`, 'error');
    }
  }

  get configVariables() {
  return { departmentType: this.departmentType, refreshKey: this.refreshKey  };
}

  // Step 2: Fetch Service Appointment data
  get variables() {
    return { userId, refreshKey: this.refreshKey };
  }

  @wire(graphql, { query: GET_SERVICE_APPOINTMENTS, variables: '$variables' })
  wiredAppointments({ error, data }) {
    if (this.isOnline) return; // skip when offline
    this.showSpinner = true;
    if (data && !this.isOnline) {
      
      this.serviceAppointments = (data?.uiapi?.query?.AssignedResource?.edges || [])
        .map(edge => edge.node.ServiceAppointment)
        .filter(Boolean)
        .filter(sa => {
          // Only for correct record type and valid schedule dates/times
          const today = new Date().toISOString().split('T')[0];
          const recordType = sa?.ParentRecord?.RecordType?.DeveloperName?.value;
          const start = sa?.Schedule_Start_Date__c?.value;
          const end = sa?.Schedule_End_Date__c?.value;
          const timeOk = sa?.SchedStartTime?.value && sa?.SchedEndTime?.value;
          const indirectOk = sa.Indirect_Reading_Received__c?.value === 'false' || sa.Indirect_Reading_Received__c?.value === false;
          if (!indirectOk) return false;
          return (
            recordType === DEVELOPER_NAME_FILTER &&
            timeOk &&
            start <= today &&
            end >= today
          );
        });
        //this.showToast('GraphQL', `Appointments refreshed`, 'info');
        this.showSpinner = false;
      this.checkAndGenerateKPIs();
    } else if (error) {
      this.error = error;
      this.showToast('GraphQL', `Appointments refresh error: ${error.body?.message || error}`, 'error');
    }
  }

  checkAndGenerateKPIs() {
      // Wait until both datasets have data
      if (
      this.configList.length > 0 &&
      this.serviceAppointments.length > 0 &&  !this._kpiReady
    ) 
      this._kpiReady = true; 
      this.generateKPIs();
      //this.showToast('Dashboard', `KPI recalculated`, 'success');
    }
  

  // Step 3: Generate KPI/grouping stats on data load/refresh
  // generateKPIs() {
  //   if (!this.configList.length || !this.serviceAppointments.length) {
  //     this.kpisResult = [];
  //     return;
  //   }
  //   const results = this.configList.map(meta => {
  //     const fieldName = meta.fieldApiName;
  //     const values = meta.values.map(v => String(v).toLowerCase());
  //     const label = meta.label;
  //     const cardColor = meta.cardColor;
  //     const iconUrl = meta.iconUrl;
  //     const order = meta.order;

  //     const matchingSA = this.serviceAppointments.filter(sa => {
  //       const value = sa[fieldName]?.value;
  //       if (!value) return false;
  //       // Special logic for Status + Appt Type
  //       if (
  //         fieldName === 'Status' &&
  //         sa.Appointment_Type__c?.value !== 'Scheduled' &&
  //         sa.Appointment_Type__c?.value !== 'Standard'
  //       ) {
  //         return false;
  //       }
  //       return values.includes(String(value).toLowerCase());
  //     });
  //     return {
  //       label,
  //       cardColor,
  //       iconUrl,
  //       count: matchingSA.length,
  //       listServiceAppointments: matchingSA,
  //       order 
  //     };
  //   }).sort((a, b) => a.order - b.order);
  //   this.kpisResult = results;
  // }

    generateKPIs() {
        //  Skip if no metadata at all
        if (!this.configList.length) {
          this.kpisResult = [];
          return;
        }

        // Ensure we always have an array, even if no appointments
        const appointments = this.serviceAppointments || [];

        //  Build KPI cards for all metadata configs
        const results = this.configList.map(meta => {
          const fieldName = meta.fieldApiName;
          const values = (meta.values || []).map(v => String(v).toLowerCase());
          const label = meta.label;
          const cardColor = meta.cardColor;
          const iconUrl = meta.iconUrl;
          const order = parseInt(meta.order, 10) || 0;

          //  Even if no matching records, we still return the card
          const matchingSA = appointments.filter(sa => {
            const value = sa[fieldName]?.value;
            if (!value) return false;

            // Match only relevant appointments
            if (
              fieldName === 'Status' &&
              sa.Appointment_Type__c?.value !== 'Scheduled' &&
              sa.Appointment_Type__c?.value !== 'Standard'
            ) {
              return false;
            }
            return values.includes(String(value).toLowerCase());
          });

          //  Always return the KPI card, even if count = 0
          return {
            label,
            cardColor,
            iconUrl,
            count: matchingSA.length, // “0” if none match
            listServiceAppointments: matchingSA,
            order
          };
        });

        // Sort and assign
        this.kpisResult = results.sort((a, b) => a.order - b.order);

        // Optional: Confirmation toast
        // this.showToast(
        //   'Dashboard',
        //   `KPI recalculated (Offline) – ${this.kpisResult.length} cards loaded`,
        //   'success'
        // );
    }


    // Rishi added changes end

    mrsCategory = false;
    wiredUserDetailsResult;
    // @wire(getUserDetails)
    // wiredUserDetails(result) {
    //   if (!this.isOnline) return; // skip when offline
    //     console.log('wiredUserDetails');
    //     this.wiredUserDetailsResult=result;
    //     if (result.data) {
    //         console.log(' wiredUserDetails data:'+JSON.stringify(result.data));
    //         var { data, error } = result;
    //         if(data.agentDetails.customerCategory == 'MRS'){
    //             this.mrsCategory = true;
    //         }else{
    //             if(data.data){
    //                 if(data.data.showAlert){
    //                     this.showAlert = true;
    //                     this.lastDate=data.data.lastDate;
    //                 }
    //             }
    //         }
    //     }else if (error) {
    //         this.error = error;
    //     }
    // }

    @track lastDate;
    getUserDetailsFunc(){
      if (!this.isOnline) return; // skip when offline
        this.showSpinner  = true;
        getUserDetails()
            .then(result => {
                this.userDetails = result;
                console.log('userDetails:' + JSON.stringify(this.userDetails));
                if(result.agentDetails.customerCategory == 'MRS' || result.agentDetails.customerCategory == 'CNG/LNG'){
                    this.mrsCategory = true;
                    this.showAlert = false;
                }else{
                    if(result.data){
                        this.lastDate=result.data.lastDate;
                        if(this.lastDate && result.data.showAlert){
                            this.showAlert = true;
                        }
                    }
                }
                this.showSpinner  = false;
            })
            .catch(error => {
                console.error('Error getting User Details:', JSON.stringify(error));
                 this.showToast('Error Ocurred', JSON.stringify(error), 'error');
                this.showSpinner  = false;
            })
    }
    // Rishi added changes start
   @track userDetails = {};

  // @wire(graphql, { query: GET_SERVICE_RESOURCE, variables: { userId }})
  // wiredServiceResource({ error, data }) {
  //   if (this.isOnline) return; // skip when online
  //   if (data && !this.isOnline) {
  //     const stmEdge = data.uiapi.query.ServiceTerritoryMember?.edges?.[0];
  //     //this.showToast('Data', 'Service Teritorry Data.'+ JSON.stringify(stmEdge), 'info');

  //     const resource = stmEdge.node.ServiceResource;
  //     const territory = stmEdge.node.ServiceTerritory;
  //     const customerCategory = resource.Customer_Category__c?.value || '';

  //     this.userDetails = {
  //       agentDetails: {
  //         agentId: resource.Id,
  //         agentName: resource.Name?.value,
  //         agencyId: territory.Id,
  //         agencyName: territory.Name?.value,
  //         customerCategory
  //       }
  //     };

  //     if (customerCategory === 'MRS' || customerCategory === 'CNG/LNG') {
  //       this.mrsCategory = true;
  //       this.showAlert = false;
  //       this.showSpinner = false;
  //     } else {
  //       // Only trigger Meter Reading Schedule query if not MRS/CNG/LNG
  //       this.serviceResourceId = resource.Id;
  //     }
  //   } else if (error) {
  //     console.error('GraphQL error:', JSON.stringify(error));
  //     this.showSpinner = false;
  //   }
  // }

    @wire(graphql, { query: GET_SERVICE_RESOURCE, variables: { userId } })
    wiredServiceResource({ error, data }) {
      if (this.isOnline) return; // run only offline
      if (data && !this.isOnline) {
        const srNode = data.uiapi?.query?.ServiceResource?.edges?.[0]?.node;
        if (!srNode) {
          //this.showToast('Debug ', 'No ServiceResource node found in offline cache.', 'error');
          this.showSpinner = false;
          return;
        }

        const srId = srNode.Id;
        if (srId) {
              //this.showToast('Debug', `ServiceResourceId set: ${srId}`, 'success');
              this.serviceResourceId = srId;
              this.refreshKey = !this.refreshKey;
          }
        const srName = srNode.Name?.value;
        const srCategory = srNode.Customer_Category__c?.value || '';
        const srUserId = srNode.RelatedRecordId?.value;
        const stNode = srNode.ServiceTerritories?.edges?.[0]?.node?.ServiceTerritory || {};
        const stId = stNode.Id || null;
        const stName = stNode.Name?.value || null;

        this.userDetails = {
          agentDetails: {
            agentId: srId,
            agentName: srName,
            agencyId: stId,
            agencyName: stName,
            customerCategory: srCategory,
            resourceUserId: srUserId
          }
          
        };

        //  this.showToast(
        //         'Debug – ServiceResource',
        //         `ServiceResource Category: ${srNode.Customer_Category__c?.value || 'Not Found'}`,
        //         'info'
        //       );

        // Category check (parity-safe)
        const cat = (srCategory || '').toLowerCase().trim();
        if (cat === 'mrs' || cat.includes('cng') || cat === 'cng' || cat === 'cng/lng') {
          this.mrsCategory = true;
          this.showAlert = false;
        } else {
          // Load Meter Reading Schedules only for non-MRS
          this.serviceResourceId = srId;
        }
       
        this.showSpinner = false;
      } else if (error) {
        console.error('GraphQL error:', JSON.stringify(error));
        this.showToast('Error', 'Failed to load Service Resource (offline)', 'error');
        this.showSpinner = false;
      }
    }



  // Step 2: Wire Meter Reading Schedules when serviceResourceId is available
  @track serviceResourceId;

   get serviceResourceIdVariable() {
    return { serviceResourceId: this.serviceResourceId, refreshKey: this.refreshKey };
   }

  // @wire(graphql, { query: GET_METER_SCHEDULES, variables: '$serviceResourceIdVariable'})
  // wiredMeterSchedules({ error, data }) {
  //   if (!this.serviceResourceId) return; // Only run if ID exists
  //   if (this.isOnline) return; // skip when online
  //   if (data && !this.isOnline) {
  //     const mrsEdges = data.uiapi.query.Meter_Reading_Schedule__c?.edges || [];
  //     const today = new Date().toISOString().split('T')[0];

  //     const matchingMRS = mrsEdges.find(edge => {
  //       const startDate = edge.node.Meter_Reading_Start_Date__c?.value;
  //       const endDate = edge.node.Meter_Reading_Completion_Date__c?.value;
  //       if (!startDate || !endDate) return false;
  //       return startDate <= today && endDate >= today;
  //     });
  //     if (matchingMRS) {
  //       const dateStr = matchingMRS.node.Meter_Reading_Completion_Date__c.value; // 'YYYY-MM-DD'
  //       const [year, month, day] = dateStr.split('-').map(Number);

  //      // JS months are 0-based
  //       const compDate = new Date(year, month - 1, day, 19, 30, 0, 0); 
  //       const today = new Date();
  //      today.setHours(0, 0, 0, 0); // strip hours, minutes, seconds
  //      const compDateOnly = new Date(compDate);
  //      compDateOnly.setHours(0, 0, 0, 0); // strip hours, minutes, seconds
  //      this.showAlert = compDateOnly.getTime() === today.getTime(); 
  //     } else {
  //       this.lastDate = null;
  //       this.showAlert = false;
  //     }
  //     this.showSpinner = false;
  //   } else if (error) {
  //     console.error('GraphQL error:', JSON.stringify(error));
  //     this.showSpinner = false;
  //   }
  // }


    @wire(graphql, { query: GET_METER_SCHEDULES, variables: '$serviceResourceIdVariable'})
  wiredMeterSchedules({ error, data }) {
      //this.showToast('Debug', `MeterSchedule wire triggered. ID=${this.serviceResourceId || 'undefined'}`, 'info');

      if (!this.serviceResourceId) {
          //this.showToast('Debug', 'No serviceResourceId yet — skipping MeterSchedule query', 'warning');
          return;
      }
      if (this.isOnline) {
          //this.showToast('Debug', 'Currently online — skipping GraphQL MeterSchedule wire', 'warning');
          return;
      }

      if (data && !this.isOnline) {
          //this.showToast('Debug', `GraphQL data received for MeterSchedule`, 'success');

          const mrsEdges = data.uiapi.query.Meter_Reading_Schedule__c?.edges || [];
          //this.showToast('Debug', `Total MRS records: ${mrsEdges.length}`, 'info');
            mrsEdges.forEach(edge => {
              const s = edge.node.Meter_Reading_Start_Date__c?.value;
              const e = edge.node.Meter_Reading_Completion_Date__c?.value;
              const todayIso = new Date().toISOString();
              //this.showToast('Debug', `start=${s} end=${e} today=${todayIso}`, 'info');
            });
          const today = new Date().toISOString().split('T')[0];
         const matchingMRS = mrsEdges.find(edge => {
          const startRaw = edge.node.Meter_Reading_Start_Date__c?.value;
          const endRaw = edge.node.Meter_Reading_Completion_Date__c?.value;
          if (!startRaw || !endRaw) return false;

          const startDate = startRaw.split('T')[0];
          const endDate = endRaw.split('T')[0];
          const todayDate = new Date().toISOString().split('T')[0];

          return startDate <= todayDate && endDate >= todayDate;
        });

          if (matchingMRS) {
              const dateStr = matchingMRS.node.Meter_Reading_Completion_Date__c.value;
              const [year, month, day] = dateStr.split('-').map(Number);
              const compDate = new Date(year, month - 1, day, 19, 30, 0, 0);
              const todayDate = new Date(); todayDate.setHours(0, 0, 0, 0);
              const compDateOnly = new Date(compDate); compDateOnly.setHours(0, 0, 0, 0);
              this.lastDate = compDate;
              this.showAlert = compDateOnly.getTime() >= todayDate.getTime();
              //this.showToast('Debug', `Matching schedule found. Completion Date=${dateStr}`, 'success');
              this.showSpinner = false;
              Promise.resolve().then(() => this.showAlert = this.showAlert);
          }
        else {
              //this.showToast('Debug', 'No matching MRS found for today', 'warning');
              this.lastDate = null;
              this.showAlert = false;
          }
          this.showSpinner = false;
      } else if (error) {
          //this.showToast('Debug', `GraphQL error in MeterSchedule: ${JSON.stringify(error)}`, 'error');
          this.showSpinner = false;
      }
  }

    // Rishi added changes end

    cardDetails() {
        this.platform = FORM_FACTOR === 'Large' ? 'desktop' : 'mobile';
        console.log('openMainPage', this.openMainPage);
        console.log('showDashboard: ', this.showDashboard);

        this.updateTime();
        this.intervalId = setInterval(() => {
            this.updateTime();
        }, 30000);

        this.autoRefreshTimer = setInterval(() => {
           if (this.isOnline) this.refreshDashboardData();
          }, 60000);
    }

    resetUI() {
        this.attendanceMarked = true;
        this.isCheckedIn = false;
        this.showDropdown = false;
        this.showSubmitButton = false;
        this.isDisabled = true;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleNavigateHome() {
        this.secondPage = false;
        this.showDashboard = true;
        this.openMainPage = true;
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

    showAlert=false;
    // Commented by rishi
    @wire(getUserRec)
    wiredUser({ error, data }) {
      if (!this.isOnline) return; // skip when offline
        if (data) {
            console.log('wiredUser data:', data);
            this.userName = data.userName;
            this.setGreeting();
        } else if (error) {
            console.error('Error fetching user:', error);
        }
    }

 // Rishi added changes start
 @wire(getRecord, { recordId: userId, fields: [NAME_FIELD] })
    userRecord({ error, data }) {
      if (this.isOnline) return; // skip when online
        if (data && !this.isOnline) {
            this.userName = data.fields.Name.value;
            this.setGreeting();
        } else if (error) {
            // Handle error here as needed
            this.userName = undefined;
        }
    }
 // Rishi added changes end

 // Rishi added changes start

   @track kpis = { total: 0, completed: 0, incomplete: 0, unattempted: 0 };
    developerNameFilter = 'MGL_Metering';

    get variables() {
        return { userId: userId };
    }

    @wire(graphql, { query: GET_ASSIGNED_RESOURCES, variables: '$variables' })
    wiredAssignedResources({ error, data }) {
      if (this.isOnline) return; // skip when online
        if (error) {
            console.error('GraphQL error', error);
            this.showSpinner  = false;
            return;
        }

        if (data && !this.isOnline) {
            const today = new Date().toISOString().split('T')[0];

            // Flatten all ServiceAppointments
            const allAppointments = data?.uiapi?.query?.AssignedResource?.edges
                ?.map(e => e.node?.ServiceAppointment)
                ?.filter(Boolean) || [];

            // Filter appointments client-side and compute KPIs in one pass
            const kpiTotals = allAppointments.reduce((acc, sa) => {
                const rtMatch = sa?.ParentRecord?.RecordType?.DeveloperName?.value === this.developerNameFilter;
                const hasSchedTimes = sa?.SchedStartTime?.value && sa?.SchedEndTime?.value;
                const dateRangeValid = sa?.Schedule_Start_Date__c?.value <= today &&
                                       sa?.Schedule_End_Date__c?.value >= today;

                if (rtMatch && hasSchedTimes && dateRangeValid) {
                    acc.total++;
                    const status = sa.Status?.value;
                    if (status === 'Completed') acc.completed++;
                    else if (status === 'Cannot Complete') acc.incomplete++;
                    else acc.unattempted++;
                }

                return acc;
            }, { total: 0, completed: 0, incomplete: 0, unattempted: 0 });

            this.kpis = kpiTotals;
        }
    }

 // Rishi added changes end 

 // Commented by rishi
    // @track kpis = {};
    @wire(getKPIs)
    wiredKpis(result) {
      if (!this.isOnline) return; // skip when offline
        this.wiredKpiResult = result;
        const { data, error } = result;
        if (data && this.isOnline) {
            this.kpis = data;
        } else if (error) {
            this.error = error;
        }
    }

    refreshDashboardData() {
              if (this.isOnline) {
        refreshApex(this.wiredKpiResult);
        refreshApex(this.MetadataMatch);
      } else {
        this.refreshKey = !this.refreshKey; // triggers GraphQL @wire updates
      }
    }

    recursion = false;
    disconnectedCallback() {
        clearInterval(this.autoRefreshTimer);
        clearInterval(this.kip);
        this.recursion = true;
          window.removeEventListener('metering:appointments-updated', this._onAppointmentsUpdated);

    }

    onTotalClick() {
        //if (!this.isCheckedIn) return;
        this.togglePage('total');
        this.selectedType = 'All'
    }

    selectedType = 'All'
    onCardCLick(event) {
        var action = event.currentTarget.dataset.card;
        this.selectedType = 'All'
        switch (action) {
            case 'Unattempted':
                this.selectedType = 'Scheduled';
                this.togglePage('unattempted');
                break;
            case 'Completed':
                this.selectedType = 'Scheduled';
                this.togglePage('completed');
                break;
            case 'Incomplete':
                this.selectedType = 'Scheduled';
                this.togglePage('incomplete');
                break;
            case 'Random':
                this.selectedType = 'Ad-hoc';
                this.togglePage('total');
                break;
            default:
                break;
        }
    }

    togglePage(status) {
        this.showSpinner = true;
        this.selectedStatus = status;
        this.showChild = true;
        this.showDashboard = false;
        this.secondPage = true;
        this.openMainPage = false;
        // var dom=this.template.querySelector('c-service-appointments-address-map');
        // if (dom) {
        //     dom.getAppointments();
        // }
        setTimeout(() => {
            this.showSpinner = false;
        }, 1000);
    }

    handleChildEvent(event) {
        this.secondPage = event.detail.secondPage;
        this.showDashboard = event.detail.showDashboard;
        this.openMainPage = event.detail.openMainPage;
        this.callPrent = true;
        this.selectedType = null;
        this.selectedStatus = null;
    }

    showCreationPage = false;
    handleNew(){
        this.showCreationPage=true;
        this.showDashboard = false;
        this.openMainPage = false;
    }

    handleBackToMainPage(){
        this.showCreationPage=false;
        this.showDashboard = true;
        this.openMainPage = true;
    }
}