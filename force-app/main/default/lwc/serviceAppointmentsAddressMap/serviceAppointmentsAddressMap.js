/**
 * @description       : Original online behavior preserved, optional offline fallback via GraphQL+LDS
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 01-12-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   18-05-2025   Kartik Patkar, Appstrail   Initial Version
 * 1.1   13-10-2025   Appstrail                  Safe offline fallback (no online changes)
**/
import { LightningElement, track, api, wire } from 'lwc';
import getAppointmentsByStatus from '@salesforce/apex/serviceAppointmentsAddressMapController.getAppointmentsByStatus';
import getAppointments from '@salesforce/apex/serviceAppointmentsAddressMapController.getAppointments';
import { NavigationMixin } from 'lightning/navigation';
import getWorkOrderIdFromSA from '@salesforce/apex/serviceAppointmentsAddressMapController.getWorkOrderIdFromSA';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { getRecord } from 'lightning/uiRecordApi';

// GraphQL (offline only)
import { gql, graphql } from 'lightning/uiGraphQLApi';
import userId from '@salesforce/user/Id';

// Keep original fields for LDS nav
const FIELDS = ['ServiceAppointment.ParentRecordId'];

// Toggle to enable offline fallback without touching online
const ENABLE_OFFLINE = true;

// Minimal uiapi query to mirror Apex WHERE and wrapper fields
const GQL_OFFLINE = gql`
  query OfflineAppointments($userId: ID!) {
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
                Subject { value }
                SchedStartTime { value }
                SchedEndTime { value }
                Schedule_Start_Date__c { value }
                Schedule_End_Date__c { value }
                Indirect_Reading_Received__c { value }
                Appointment_Type__c { value }
                Customer_Name__c { value }
                BP_Number__c { value }
                Meter_Number__c { value }
                Account {
                  Id
                  Name { value }
                  Building_name__c { value }
                  City__c { value }
                  Postal_Code__c { value }
                  Street__c { value }
                  Colony__c { value }
                  Wing__c { value }
                  Floor__c { value }
                  Flat__c { value }
                  Road_name__c { value }
                  Landmark__c { value }
                  Phone__c { value }
                  Customer_Contact_no__c { value }
                  PersonHomePhone { value }
                  Secondary_Telephone__c { value }
                  Secondary_Phone__c { value }
                  Location__c { value }
                  Zone__c { value }
                  Representative_Company__c { value }
                  Plot__c { value }
                }
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
        ServiceResource(where: { RelatedRecordId: { eq: $userId } }, first: 1) {
          edges {
            node {
              Customer_Category__c { value }
            }
          }
        }
        Metering_Dashboard_Config__mdt(
          where: { Active__c: { eq: true }, Department__c: { eq: "Metering" } }
          orderBy: { Order__c: { order: ASC } }
          first: 200
        ) {
          edges {
            node {
              Label__c { value }
              Field_Api_Name__c { value }
              Values__c { value }
              Card_Color__c { value }
              Icon_URL__c { value }
              Order__c { value }
            }
          }
        }
      }
    }
  }
`;

// Offline fallback for Metering_Dashboard_Config__mdt
const OFFLINE_META_DEFAULT = [
  { label: 'Completed', fieldApiName: 'Status', valuesCsv: 'Completed', cardColor: '#2ECC71', iconUrl: '' },
  { label: 'Unattempted', fieldApiName: 'Status', valuesCsv: 'None,Scheduled,Dispatched,In Progress', cardColor: '#3498DB', iconUrl: '' },
  { label: 'Incomplete', fieldApiName: 'Status', valuesCsv: 'Cannot Complete', cardColor: '#E74C3C', iconUrl: '' },
  { label: 'Total', fieldApiName: 'Status', valuesCsv: 'Canceled,Cancelled,Completed,Cannot Complete,In Progress,Dispatched,Scheduled,None', cardColor: '#9B59B6', iconUrl: '' }
];


export default class ServiceAppointmentsAddressMap extends NavigationMixin(LightningElement) {
  @track appointmentGroups = [];
  @track error;
  @track flag = true;
  @track isLoading = false;

  @track openAcc360 = false;
  @track selectedServiceAppointmentId;
  @track groupSelected = false;
  wiredAppointmentsResult;

  _selectedStatus;
  _selectedType;
  _openMainPage;
  _showDashboard;
  _secondPage;

  @api
  get selectedStatus() { return this._selectedStatus; }
  set selectedStatus(value) { this._selectedStatus = value; }

  @api
  get selectedType() { return this._selectedType; }
    set selectedType(value) {
    this._selectedType = value;
    this.getAppointments();
    }

  @api
  get openMainPage() { return this._openMainPage; }
  set openMainPage(value) { this._openMainPage = value; }

  @api
  get showDashboard() { return this._showDashboard; }
  set showDashboard(value) { this._showDashboard = value; }

  @api
  get secondPage() { return this._secondPage; }
  set secondPage(value) { this._secondPage = value; }

  searchToggle = false;

  connectedCallback() {
    if(navigator.onLine){
        this.getAppointments();
    }
  }
  disconnectedCallback() { 
    this.appointmentGroups = []; 
  }

  get hasAppointments() {
    return (this.appointmentGroups && this.appointmentGroups.length > 0)
        || (this.appointmentsList && this.appointmentsList.length > 0);
  }
  get gqlVars() {
    return {
      userId,
      statusKey: (this.selectedStatus || '').trim().toLowerCase(),
      typeKey: (this.selectedType || 'All').trim(),
      refreshKey: this.gqlRefreshKey || 0 
    };
  }

  cngCategory = false;
  customerCategory;
  @track debugBanner = ''; 

    isTrulyOffline() {
    try {
        const n = window.navigator;
        const noConn = (n?.connection && n.connection.effectiveType === 'none');
        return !n.onLine || noConn;
    } catch(e) {
        return false;
    }
    }


  // ORIGINAL ONLINE FLOW (unchanged)
  // @api
  // getAppointments() {
  //   this.isLoading = true;

  //   // Always use Apex when online to preserve behavior
  //   if (navigator.onLine || !ENABLE_OFFLINE) {
  //     getAppointments({ status: this.selectedStatus, type: this.selectedType })
  //       .then(result => {
  //         this.customerCategory = result.customerCategory;
  //         this.appointmentGroups = [];
  //         if (this.customerCategory === 'CNG/LNG') this.cngCategory = true;

  //         if (this.customerCategory === 'MRS' || this.customerCategory === 'CNG/LNG') {
  //           this.showAppointmentScreen = true;
  //           this.flag = false;
  //           this.appointmentsList = result.appointmentList;
  //           this.statusMap = result.groupedAppointmentCounts;

  //           Object.keys(this.statusMap || {}).forEach(building => {
  //             const statusItems = this.statusMap[building] || [];
  //             statusItems.forEach(item1 => {
  //               (item1.listServiceAppointments || []).forEach(item2 => {
  //                 this.appointmentsList.forEach(appointment => {
  //                   if (appointment.id === item2.Id) {
  //                     appointment.label = item1.label;
  //                     appointment.cssStyle = 'background-color:' + item1.cardColor + ';';
  //                   }
  //                 });
  //               });
  //             });
  //           });

  //           this.appointmentsListMain = JSON.parse(JSON.stringify(this.appointmentsList));
  //         } else {
  //           this.processData(result);
  //         }
  //         this.error = null;
  //       })
  //       .catch(error => {
  //         // Preserve original error handling
  //         // eslint-disable-next-line no-console
  //         console.error('Error getting Appointments:' + JSON.stringify(error));
  //         this.error = error;
  //         this.appointmentGroups = [];
  //       })
  //       .finally(() => { this.isLoading = false; });

  //     return;
  //   }

  // }


    @api
getAppointments() {
  this.isLoading = true; // 🔹 show spinner immediately

  if (navigator.onLine || !ENABLE_OFFLINE) {
    setTimeout(() => {
      getAppointments({ status: this.selectedStatus, type: this.selectedType })
        .then(result => {
          this.customerCategory = result.customerCategory;
          this.appointmentGroups = [];

          if (this.customerCategory === 'CNG/LNG') this.cngCategory = true;

          if (this.customerCategory === 'MRS' || this.customerCategory === 'CNG/LNG') {
            this.showAppointmentScreen = true;
            this.flag = false;
            this.appointmentsList = result.appointmentList;
            this.statusMap = result.groupedAppointmentCounts;

            Object.keys(this.statusMap || {}).forEach(building => {
              const statusItems = this.statusMap[building] || [];
              statusItems.forEach(item1 => {
                (item1.listServiceAppointments || []).forEach(item2 => {
                  this.appointmentsList.forEach(appointment => {
                    if (appointment.id === item2.Id) {
                      appointment.label = item1.label;
                      appointment.cssStyle = 'background-color:' + item1.cardColor + ';';
                    }
                  });
                });
              });
            });

            this.appointmentsListMain = JSON.parse(JSON.stringify(this.appointmentsList));
          } else {
            this.processData(result);
          }
          this.error = null;
        })
        .catch(error => {
          console.error('Error getting Appointments:' + JSON.stringify(error));
          this.error = error;
          this.appointmentGroups = [];
        })
        .finally(() => {
          this.isLoading = false; 
        });
    }, 3000); 

    return;
  }

}


    // GraphQL wire (offline only)
// @wire(graphql, { query: GQL_OFFLINE, variables: '$gqlVars' })
// wiredOffline(result) {
//   // Guard: only act when offline to avoid touching online behavior
//   const offline = (typeof window !== 'undefined') ? !window.navigator.onLine : false;
//   if (!offline) return;

//   const { data, errors } = result || {};
//   if (errors && errors.length) {
//     return;
//   }
//   if (!data) {
//     // Still loading from cache
//     return;
//   }

//   this.isLoading = true;

//   try {
//     const ui = data?.uiapi?.query || null;
//     if (!ui) {
//       this.renderNoData();
//       return;
//     }

//     // Category branch
//     const cat = ui.ServiceResource?.edges?.[0]?.node?.Customer_Category__c?.value || null;
//     this.customerCategory = cat;
//     this.cngCategory = cat === 'CNG/LNG';

//     // Raw SAs
//     const assignedEdges = ui.AssignedResource?.edges || [];

//     const allSA = assignedEdges.map(e => e?.node?.ServiceAppointment).filter(Boolean);

//     // Filters (parity with Apex)
//     const todayStr = new Date().toISOString().split('T')[0];
//     const normStatus = (this.selectedStatus || '').trim().toLowerCase();
//     const normType = (this.selectedType || 'All').trim();
//     const typeMode = normType === 'Ad-hoc' ? 'Ad-Hoc' : normType;

//     const completed = new Set(['Completed']);
//     const incomplete = new Set(['Cannot Complete']);
//     const unattempted = new Set(['None', 'Scheduled', 'In Progress', 'Dispatched']);
//     const totalStatuses = new Set(['Canceled','Cancelled','Completed','Cannot Complete','In Progress','Dispatched','Scheduled','None']);
//     const allStatuses = totalStatuses;

//     let targetStatuses = allStatuses;
//     if (normStatus === 'completed') targetStatuses = completed;
//     else if (normStatus === 'incomplete') targetStatuses = incomplete;
//     else if (normStatus === 'unattempted') targetStatuses = unattempted;
//     else if (normStatus === 'total') targetStatuses = totalStatuses;

//     const typeOk = (v) => {
//       const t = (v || '').trim();
//       if (typeMode === 'Ad-Hoc') return t === 'Ad-Hoc';
//       if (typeMode === 'Scheduled') return t === 'Scheduled' || t === 'Standard';
//       return t === 'Scheduled' || t === 'Standard' || t === 'Ad-Hoc';
//     };

//     const acceptedWO = (rt) => {
//       const dev = rt?.DeveloperName?.value;
//       return dev ? dev === 'MGL_Metering' : true; // relaxed if not cached
//     };

//     const inWindow = (s, e) => s && e && (s <= todayStr && todayStr <= e);

//     // Stepwise debug
//     const step1 = allSA.filter(sa => targetStatuses.has(sa?.Status?.value));

//     const step2 = step1.filter(sa => acceptedWO(sa?.ParentRecord?.RecordType));

//     const step3 = step2.filter(sa => sa?.SchedStartTime?.value && sa?.SchedEndTime?.value);

//     const step4 = step3.filter(sa => inWindow(sa?.Schedule_Start_Date__c?.value, sa?.Schedule_End_Date__c?.value));

//     const filtered = step4.filter(sa => typeOk(sa?.Appointment_Type__c?.value));

//     // Build wrappers
//     const wrappers = filtered.map(sa => this.buildSAWrapper(sa));

//     // Metadata counts
//     const meta = (ui.Metering_Dashboard_Config__mdt?.edges || []).map(e => ({
//       label: e.node.Label__c?.value,
//       fieldApiName: e.node.Field_Api_Name__c?.value,
//       valuesCsv: e.node.Values__c?.value,
//       order: e.node.Order__c?.value,
//       cardColor: e.node.Card_Color__c?.value,
//       iconUrl: e.node.Icon_URL__c?.value
//     }));

//     if (this.customerCategory === 'MRS' || this.customerCategory === 'CNG/LNG') {
//       // Flat list
//       this.showAppointmentScreen = true;
//       this.flag = false;
//       this.appointmentsList = wrappers;

//       const byBuilding = this.computeByBuildingCounts(filtered, meta);
//       Object.keys(byBuilding).forEach(b => {
//         (byBuilding[b] || []).forEach(dw => {
//           (dw.listServiceAppointments || []).forEach(item => {
//             this.appointmentsList.forEach(a => {
//               if (a.id === item.Id) {
//                 a.label = dw.label;
//                 a.cssStyle = 'background-color:' + (dw.cardColor || '') + ';';
//               }
//             });
//           });
//         });
//       });

//       this.appointmentsListMain = JSON.parse(JSON.stringify(this.appointmentsList));
//       this.appointmentGroups = [];
//     } else {
//       // Grouped
//       const grouped = {};
//       const rawByBuilding = {};
//       wrappers.forEach(w => {
//         const key = w.buildingName && w.buildingName.trim() !== '' ? w.buildingName : 'Others';
//         if (!grouped[key]) grouped[key] = [];
//         grouped[key].push(w);
//         const raw = filtered.find(x => x.Id === w.id);
//         if (!rawByBuilding[key]) rawByBuilding[key] = [];
//         if (raw) rawByBuilding[key].push(raw);
//       });

//       const byBuilding = {};
//       Object.keys(rawByBuilding).forEach(b => {
//         byBuilding[b] = this.computeByBuildingCounts(rawByBuilding[b], meta);
//       });

//       const groups = [];
//       Object.keys(grouped).forEach(building => {
//         const appts = grouped[building];
//         const buildingStreet = appts.length > 0 ? appts[0].buildingStreet : '';
//         const processed = appts.map(a => {
//           let statusClass = 'appt-status slds-badge';
//           if (a.visitStatus === 'Success') statusClass += ' success-badge';
//           else if (a.visitStatus === 'Unsuccessful') statusClass += ' unsuccessful-badge';
//           return { ...a, statusClass };
//         });
//         const counts = (byBuilding[building] || []).map(s => ({ ...s, cssStyle: 'background-color:' + (s.cardColor || '') + ';' }));
//         groups.push({
//           buildingName: building,
//           buildingStreet,
//           appointments: processed,
//           isExpanded: false,
//           statusSection: false,
//           statusCounts: counts
//         });
//       });

//       this.allAppointments = JSON.parse(JSON.stringify(groups));
//       this.appointmentGroups = groups;
//       this.flag = true;
//       this.showAppointmentScreen = false;
//     }
//   } catch(ex) {
//     this.debugToast('Wire exception', (ex?.message || JSON.stringify(ex)).slice(0,120));
//     this.renderNoData();
//   } finally {
//     this.isLoading = false;
//   }
// }

handleSearch() {
        this.searchToggle = !this.searchToggle;
    }

  handleReconnect() {
    if (navigator.onLine) {
      // Wait for Field Service sync (2-3 s)
      this.getAppointments();
    }
  }

  @wire(graphql, { query: GQL_OFFLINE, variables: '$gqlVars' })
wiredOffline(result) {
  const offline = (typeof window !== 'undefined') ? !window.navigator.onLine : false;
  if (!offline) {
    // If we just came online, fetch Apex fresh to update cached data
    this.getAppointments();
    return;
  }

  // Reset transient UI and start spinner
  this.isLoading = true;
  this.appointmentGroups = [];
  this.appointmentsList = [];
  this.appointmentsListMain = [];
  this.showAppointmentScreen = false;
  this.flag = true;

  const { data, errors } = result || {};
  if (errors && errors.length) {
    this.isLoading = false;
    return;
  }
  if (!data) {
    setTimeout(() => { if (this.isLoading) this.isLoading = false; }, 1500);
    return;
  }

  try {
    const ui = data?.uiapi?.query || null;
    if (!ui) {
      this.renderNoData();
      this.isLoading = false;
      return;
    }

    const cat = ui.ServiceResource?.edges?.[0]?.node?.Customer_Category__c?.value || null;
    this.customerCategory = cat;
    this.cngCategory = cat === 'CNG/LNG';

    const assignedEdges = ui.AssignedResource?.edges || [];
    const allSA = assignedEdges.map(e => e?.node?.ServiceAppointment).filter(Boolean);

    // Snapshot tab filters to avoid races
    const snapshotStatus = (this.selectedStatus || '').trim().toLowerCase();
    const snapshotType = (this.selectedType || 'All').trim();
    const typeMode = snapshotType === 'Ad-hoc' ? 'Ad-Hoc' : snapshotType;

    const completed = new Set(['Completed']);
    const incomplete = new Set(['Cannot Complete']);
    const unattempted = new Set(['None', 'Scheduled', 'In Progress', 'Dispatched']);
    const totalStatuses = new Set(['Canceled','Cancelled','Completed','Cannot Complete','In Progress','Dispatched','Scheduled','None']);
    const allStatuses = totalStatuses;

    let targetStatuses = allStatuses;
    if (snapshotStatus === 'completed') targetStatuses = completed;
    else if (snapshotStatus === 'incomplete') targetStatuses = incomplete;
    else if (snapshotStatus === 'unattempted') targetStatuses = unattempted;
    else if (snapshotStatus === 'total') targetStatuses = totalStatuses;

    const typeOk = (v) => {
      const t = (v || '').trim();
      if (typeMode === 'Ad-Hoc') return t === 'Ad-Hoc';
      if (typeMode === 'Scheduled') return t === 'Scheduled' || t === 'Standard';
      return t === 'Scheduled' || t === 'Standard' || t === 'Ad-Hoc';
    };

    const acceptedWO = (rt) => {
      const dev = rt?.DeveloperName?.value;
      return dev ? dev === 'MGL_Metering' : true;
    };

    const todayStr = new Date().toISOString().split('T')[0];
    const inWindow = (s, e) => s && e && (s <= todayStr && todayStr <= e);

      const step1 = allSA.filter(sa => targetStatuses.has(sa?.Status?.value));
      const step2 = step1.filter(sa => acceptedWO(sa?.ParentRecord?.RecordType));
      const step3 = step2.filter(sa => sa?.SchedStartTime?.value && sa?.SchedEndTime?.value);
      const step4 = step3.filter(sa => {
        const irr = sa?.Indirect_Reading_Received__c?.value;
        const irrBool = (irr === true) || (String(irr).toLowerCase() === 'true');
        return !irrBool; 
      });

      // in-window & type filter
      const step5 = step4.filter(sa => inWindow(sa?.Schedule_Start_Date__c?.value, sa?.Schedule_End_Date__c?.value));
    const filteredRaw = step5.filter(sa => typeOk(sa?.Appointment_Type__c?.value));

    const wrappers = filteredRaw.map(sa => this.buildSAWrapper(sa));

    let meta = (ui.Metering_Dashboard_Config__mdt?.edges || []).map(e => ({
        label: e.node.Label__c?.value,
        fieldApiName: e.node.Field_Api_Name__c?.value,
        valuesCsv: e.node.Values__c?.value,
        order: e.node.Order__c?.value,
        cardColor: e.node.Card_Color__c?.value,
        iconUrl: e.node.Icon_URL__c?.value
      }));

      // use built-in defaults when MDT not cached
      if (!meta.length) {
        console.warn('Using offline default metadata for status badges');
        meta = OFFLINE_META_DEFAULT;
      }


    // Helper: ensure each row has a visible label and cssStyle; fallback to raw SA.Status
    const ensureRowLabel = (rows, countsByBuildingAll) => {
      const countsAll = countsByBuildingAll || { '': [] };
      const allDwells = Object.values(countsAll).flat();
      return rows.map(r => {
        let lbl;
        let style;
        // Try per-building match first (if building-level counts provided)
        allDwells.forEach(dw => {
          (dw.listServiceAppointments || []).forEach(item => {
            if (item.Id === r.id) {
              lbl = dw.label;
              style = 'background-color:' + (dw.cardColor || '') + ';';
            }
          });
        });
        // Fallback to raw status if no metadata hit
        if (!lbl && r.status) {
          lbl = r.status;
          // Provide a readable default style if none was set
          if (!style) {
            // simple status-to-color fallback
            const s = r.status.toLowerCase();
            let color = '#3498DB'; 
            if (s === 'completed') color = '#2ECC71';
            else if (s === 'cannot complete' || s === 'incomplete') color = '#E74C3C';
            else if (s === 'canceled' || s === 'cancelled') color = '#9B59B6';
            style = 'background-color:' + color + ';';
          }
        }
        // Ensure text is readable when custom bg is applied
        if (style && !/color:/i.test(style)) {
          style = style + 'color:#fff;';
        }
        return { ...r, label: lbl, cssStyle: style };
      });
    };

    // 3) Flat list (MRS/CNG) branch
    if (this.customerCategory === 'MRS' || this.customerCategory === 'CNG/LNG') {
      this.showAppointmentScreen = true;
      this.flag = false;
      this.appointmentsList = wrappers;

      // Build one synthetic bucket of counts so ensureRowLabel can find matches
      const countsAll = { '': this.computeByBuildingCounts(filteredRaw, meta) };
      this.appointmentsList = ensureRowLabel(this.appointmentsList, countsAll);

      // Force LWC re-render and keep the original mirror list
      this.appointmentsList = this.appointmentsList.map(a => ({ ...a }));
      this.appointmentsListMain = JSON.parse(JSON.stringify(this.appointmentsList));
      this.appointmentGroups = [];
      this.isLoading = false;
      return;
    }

    // 4) Grouped view
    const grouped = {};
    const rawByBuilding = {};
    wrappers.forEach(w => {
      const key = w.buildingName && w.buildingName.trim() !== '' ? w.buildingName : 'Others';
      if (!grouped[key]) grouped[key] = [];
      grouped[key].push(w);
      const raw = filteredRaw.find(x => x.Id === w.id);
      if (!rawByBuilding[key]) rawByBuilding[key] = [];
      if (raw) rawByBuilding[key].push(raw);
    });

    // Per-building counts using metadata
    const byBuilding = {};
    Object.keys(rawByBuilding).forEach(b => {
      byBuilding[b] = this.computeByBuildingCounts(rawByBuilding[b], meta);
    });

    // Build groups and propagate labels to each row
    const groups = [];
    Object.keys(grouped).forEach(building => {
      const appts = grouped[building];
      const buildingStreet = appts.length > 0 ? appts[0].buildingStreet : '';

      // Existing statusClass
      const processed = appts.map(a => {
        let statusClass = 'appt-status slds-badge';
        if (a.visitStatus === 'Success') statusClass += ' success-badge';
        else if (a.visitStatus === 'Unsuccessful') statusClass += ' unsuccessful-badge';
        return { ...a, statusClass };
      });

      // Inject label/cssStyle into each row; fallback to raw status if no match
      const processedWithLabels = ensureRowLabel(processed, { [building]: byBuilding[building] || [] });

      const counts = (byBuilding[building] || []).map(s => ({
        ...s,
        cssStyle: 'background-color:' + (s.cardColor || '') + ';color:#fff;'
      }));

      groups.push({
        buildingName: building,
        buildingStreet,
        appointments: processedWithLabels,
        isExpanded: false,
        statusSection: false,
        statusCounts: counts
      });
    });

    // Commit groups
    this.allAppointments = JSON.parse(JSON.stringify(groups));
    this.appointmentGroups = groups;
    this.flag = true;
    this.showAppointmentScreen = false;
    this.isLoading = false;
      } catch (ex) {
        this.renderNoData();
        this.isLoading = false;
      }
    }


  renderNoData() {
    this.appointmentGroups = [];
    this.appointmentsList = [];
    this.showAppointmentScreen = this.customerCategory === 'MRS' || this.customerCategory === 'CNG/LNG';
  }

  // Build a wrapper like Apex
  buildSAWrapper(sa) {
    const acc = sa.Account;
    const g = (x) => (x && x.value) || null;
    const buildingName = g(acc?.Building_name__c);
    const buildingStreet = this.buildFullAddress(
      buildingName,
      g(acc?.Landmark__c),
      g(acc?.Road_name__c),
      g(acc?.Location__c),
      g(acc?.City__c),
      g(acc?.Postal_Code__c)
    );
    return {
      id: sa.Id,
      subject: g(sa.Subject),
      meterNumber: g(sa.Meter_Number__c),
      accountName: g(acc?.Name),
      status: g(sa.Status),
      visitStatus: null,
      schedStartTime: g(sa.SchedStartTime),
      buildingName,
      buildingStreet,
      DetailAccountSummary: this.formatAddress(
        g(acc?.Street__c),
        g(acc?.Wing__c),
        g(acc?.Colony__c),
        g(acc?.Floor__c),
        g(acc?.Flat__c),
        g(acc?.Plot__c)
      ),
      appointmentType: g(sa.Appointment_Type__c) || 'Scheduled',
      customerName: g(sa.Customer_Name__c),
      BPNumber: g(sa.BP_Number__c),
      phone: g(acc?.Phone__c),
      customerContactNo: g(acc?.Customer_Contact_no__c),
      personHomePhone: g(acc?.PersonHomePhone),
      secondaryTelephone: g(acc?.Secondary_Telephone__c),
      secondaryPhone: g(acc?.Secondary_Phone__c),
      location: g(acc?.Location__c),
      zone: g(acc?.Zone__c),
      representativeCompany: g(acc?.Representative_Company__c),
      plot: g(acc?.Plot__c),
      flat: g(acc?.Flat__c),
      floor: g(acc?.Floor__c),
      wing: g(acc?.Wing__c)
    };
  }

  formatAddress(street, wing, colony, floor, flat, plot) {
    const parts = [];
    if (plot) parts.push('Plot: ' + plot);
    if (wing) parts.push('Wing: ' + wing);
    if (floor) parts.push('Floor: ' + floor);
    if (flat) parts.push('Flat: ' + flat);
    return parts.length ? parts.join(', ') : 'No address available';
  }

  buildFullAddress(buildingName, landmark, roadName, location, city, postalCode) {
    const parts = [];
    if (landmark) parts.push(landmark?.trim());
    if (roadName) parts.push(roadName?.trim());
    if (location) parts.push(location?.trim());
    if (city) parts.push(city?.trim());
    let address = parts.join(', ');
    if (postalCode) address += ' -' + postalCode?.trim();
    return address;
  }

  // Metadata-driven counts per building (reuse row logic)
  computeByBuildingCounts(rawSAList, metaList) {
    const results = [];
    const getFieldValue = (sa, apiName) => {
      if (!apiName) return null;
      const parts = apiName.split('.');
      let node = sa;
      for (const p of parts) {
        if (!node) return null;
        if (p === 'Account') node = sa.Account; else node = node[p];
      }
      return (node && node.value) ? node.value : node || null;
    };

    (metaList || []).forEach(m => {
      const label = m.label || '';
      const api = m.fieldApiName || '';
      const csv = (m.valuesCsv || '').split(',').map(s => s.trim()).filter(Boolean);
      const color = m.cardColor || '';
      const icon = m.iconUrl || '';

      const matched = [];
      (rawSAList || []).forEach(sa => {
        const v = getFieldValue(sa, api);
        if (!csv.length) return;

        // Parity rule: if field is Status, only Scheduled/Standard should count
        const isStatusField = (api || '').split('.').pop() === 'Status';
        const appType = (sa.Appointment_Type__c && sa.Appointment_Type__c.value) || 'Scheduled';
        if (isStatusField && !(appType === 'Scheduled' || appType === 'Standard')) return;

        const hit = csv.some(x => (x.toLowerCase() === (v || '').toLowerCase()));
        if (hit) matched.push({ Id: sa.Id });
      });

      results.push({
        label,
        count: matched.length,
        cardColor: color,
        iconUrl: icon,
        listServiceAppointments: matched
      });
    });

    return results;
  }

  // UI helpers and online code below remain unchanged
  filterGroups(event) {
    var value = event.detail.value;
    this.appointmentGroups = [];
    if (value && value != '') {
      this.appointmentGroups = this.allAppointments.filter(group => {
        const searchValue = value.toLowerCase();
        return (
          (group.buildingName && group.buildingName.toLowerCase().includes(searchValue)) ||
          (group.buildingStreet && group.buildingStreet.toLowerCase().includes(searchValue))
        );
      });
    } else {
      this.appointmentGroups = this.allAppointments;
    }
  }

  toggleGroup(event) {
    const buildingName = event.currentTarget.dataset.building;
    this.appointmentGroups = this.appointmentGroups.map(group => {
      if (group.buildingName === buildingName) {
        return { ...group, expanded: !group.expanded };
      }
      return group;
    });
  }

  toggleSubCountSection(event) {
    event.stopPropagation();
    var value = event.currentTarget.dataset.building;
    this.appointmentGroups.forEach(item => {
      if (item.buildingName == value) {
        item.statusSection = !item.statusSection;
      } else {
        item.statusSection = false;
      }
    })
  }

  showAppointmentScreen = false;
  @track appointmentsList = [];
  appointmentsListMain = [];
  toggleBuilding(event) {
    this.isLoading = true;
    this.groupSelected = true;
    this.flag = false;
    const buildingName = event.currentTarget.dataset.building;
    this.appointmentsList = [];
    this.appointmentsListMain = [];
    this.appointmentGroups = this.appointmentGroups.map(group => {
      if (group.buildingName === buildingName) {
        this.appointmentsList = group.appointments;
        this.showAppointmentScreen = true;
        return { ...group, isExpanded: !group.isExpanded };
      }
      return group;
    });

    var temp = this.statusMap?.[buildingName];
    this.appointmentsList.forEach(item => {
      if (temp) {
        temp.forEach(item1 => {
          if (item1.listServiceAppointments) {
            item1.listServiceAppointments.forEach(item2 => {
              if (item.id == item2.Id) {
                item.cssStyle = 'background-color:' + item1.cardColor + ';';
                item.label = item1.label;
              }
            })
          }
        })
      }
    })

    this.appointmentsListMain = JSON.parse(JSON.stringify(this.appointmentsList));
    this.isLoading = false;
  }

  appointmentSearchToggle = false;
  handleAppointmentSearch() {
    this.appointmentSearchToggle = !this.appointmentSearchToggle;
    var listSection = this.template.querySelector('.list-section');
    if (listSection) {
      if (this.appointmentSearchToggle) {
        listSection.style.height = '80vh';
        listSection.style.overflow = 'auto';
      } else {
        listSection.style.height = '90vh';
        listSection.style.overflow = 'auto';
      }
    }
  }

  filterAppointmentSearch(event) {
    var value = event.detail.value;
    this.appointmentsList = [];
    if (value && value != '') {
      this.appointmentsList = this.appointmentsListMain.filter(group => {
        const searchValue = value.toLowerCase();
        return (
          (group.accountName && group.accountName.toLowerCase().includes(searchValue)) ||
          (group.DetailAccountSummary && group.DetailAccountSummary.toLowerCase().includes(searchValue)) ||
          (group.customerContactNo && String(group.customerContactNo).toLowerCase().includes(searchValue)) ||
          (group.phone && String(group.phone).toLowerCase().includes(searchValue)) ||
          (group.personHomePhone && String(group.personHomePhone).toLowerCase().includes(searchValue)) ||
          (group.secondaryTelephone && String(group.secondaryTelephone).toLowerCase().includes(searchValue)) ||
          (group.secondaryPhone && String(group.secondaryPhone).toLowerCase().includes(searchValue)) ||
          (group.meterNumber && String(group.meterNumber).toLowerCase().includes(searchValue))
        );
      });
    } else {
      this.appointmentsList = this.appointmentsListMain;
    }
  }

  // LDS nav (kept from your original)
  @track selectedAppointment;
  _serviceAppointmentIdForWire;
  get serviceAppointmentIdForWire() { return this._serviceAppointmentIdForWire; }

  @wire(getRecord, { recordId: '$serviceAppointmentIdForWire', fields: FIELDS })
  wiredServiceAppointment({ error, data }) {
    if (data) {
      const workOrderId = data.fields.ParentRecordId.value;
      if (workOrderId) {
        this.navigateToWorkOrderInFSL(workOrderId);
      } else {
        this.showToast('Missing Work Order', `No Work Order is associated with Service Appointment.`, 'warning');
      }
    } else if (error) {
      this.showToast('Error', 'Could not load Service Appointment record.', 'error');
      // eslint-disable-next-line no-console
      console.error(error);
    }
  }

  handleAppointmentClick(event) {
    this.isLoading = true;
    const serviceAppointmentId = event.currentTarget.dataset.id;
    this.selectedAppointment = this.appointmentsList.find(item => item.id === serviceAppointmentId);

    if (this.selectedAppointment && this.selectedAppointment.Status === 'Completed') {
      this.isLoading = false;
      return;
    }
    this._serviceAppointmentIdForWire = serviceAppointmentId;
    this.isLoading = false;
  }

  navigateToWorkOrderInFSL(workOrderId) {
    if (this.selectedStatus == 'completed') {
      return;
    }
    if (FORM_FACTOR == 'Large') {
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: { recordId: workOrderId, actionName: 'view' },
      });
    } else {
      this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: { url: `com.salesforce.fieldservice://v1/sObject/${workOrderId}/overview` }
      });
    }
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: 'dismissable' }));
  }

  // Your original processData unchanged
  processData(result) {
    this.isLoading = true;
    const groups = [];
    var data = result.groupedAppointments;
    var count = JSON.parse(JSON.stringify(result.groupedAppointmentCounts));
    for (let building in data) {
      const appointments = data[building];
      const buildingStreet = appointments.length > 0 ? appointments[0].buildingStreet : '';

      var processedAppointments = appointments.map(appt => {
        let statusClass = 'appt-status slds-badge';
        if (appt.visitStatus === 'Success') statusClass += ' success-badge';
        else if (appt.visitStatus === 'Unsuccessful') statusClass += ' unsuccessful-badge';
        return { ...appt, statusClass };
      });

      this.statusMap = count;
      (count[building] || []).forEach(status => {
        status.cssStyle = 'background-color:' + status.cardColor + ';';
      });
      groups.push({
        buildingName: building,
        buildingStreet: buildingStreet,
        appointments: processedAppointments,
        isExpanded: false,
        statusSection: false,
        statusCounts: count[building]
      });
    }

    this.allAppointments = JSON.parse(JSON.stringify(groups));
    this.appointmentGroups = groups;
    this.isLoading = false;
  }

  debugToast(label, value) {
  try {
    this.dispatchEvent(new ShowToastEvent({
      title: 'Offline Debug',
      message: `${label}: ${value}`,
      variant: 'info',
      mode: 'pester'
    }));
  } catch(e) {
    // no-op in environments without toast
  }
}


    handleBacktoaddress() {
        if(this.customerCategory == 'MRS' || this.customerCategory == 'CNG/LNG' ){
            this.handleBack();
        }else{
            console.log('handleBacktoaddress this.flag>>>>>' + this.flag);
            this.showAppointmentScreen = false;
            this.appointmentsList = [];
            this.flag = true;
            this.appointmentGroups = this.appointmentGroups.map(group => {
                return { ...group, isExpanded: false };
            });
            console.log('AFTER handleBacktoaddress this.flag>>>>>' + this.flag);

        }
    }


    handleBack() {
        this.secondPage = false;
        this.showDashboard = true;
        this.openMainPage = true;
        // this.refreshAppointments();
        this.appointmentGroups = [];

        const event = new CustomEvent('childevent', {
            detail: {
                secondPage: this.secondPage,
                showDashboard: this.showDashboard,
                openMainPage: this.openMainPage
            }
        });
        this.dispatchEvent(event);
    }

}