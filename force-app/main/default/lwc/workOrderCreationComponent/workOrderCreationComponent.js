/**
 * @description       : Full parity version with offline fallback via GraphQL wire adapters + LDS
 * @author            : Appstrail (generated with ChatGPT)
 * @last modified on  : 03-02-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   08-07-2025   Team                       Initial Version
 * 1.1   16-10-2025   Appstrail                  Added Offline GraphQL + LDS fallback (no online changes)
**/

import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';

// ===== ONLINE APEX (unchanged) =====
import getComponentData from '@salesforce/apex/WorkOrderCreationController.getComponentData';
import createWorkOrder from '@salesforce/apex/WorkOrderCreationController.createWorkOrder';

// ===== LDS / GraphQL =====
import { createRecord, updateRecord  } from 'lightning/uiRecordApi';
import { graphql, gql } from 'lightning/uiGraphQLApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { refreshGraphQL } from 'lightning/uiGraphQLApi';


// WorkOrder schema
import WORKORDER_OBJECT from '@salesforce/schema/WorkOrder';
import WO_ACCOUNT from '@salesforce/schema/WorkOrder.AccountId';
import WO_STATUS from '@salesforce/schema/WorkOrder.Status';
import WO_SUBJECT from '@salesforce/schema/WorkOrder.Subject';
import WO_TYPE from '@salesforce/schema/WorkOrder.Work_Order_Type__c';
import WO_ASSIGNED from '@salesforce/schema/WorkOrder.Assigned_Meter_Reader__c';
import WO_AGENCY from '@salesforce/schema/WorkOrder.Metering_Agency__c';
import WO_START from '@salesforce/schema/WorkOrder.StartDate';
import WO_END from '@salesforce/schema/WorkOrder.EndDate';
import WO_SCHED from '@salesforce/schema/WorkOrder.Scheduled_Date__c';
import WO_RTYPE from '@salesforce/schema/WorkOrder.RecordTypeId';

// Other objects created offline
// AssignedResource has no schema import in uiRecordApi; we can pass apiName: 'AssignedResource'

// User
import USER_ID from '@salesforce/user/Id';

import CNG_OPTION_VALUE from '@salesforce/label/c.Customer_Category_CNG_Value';

/* ==========================================================
   GraphQL WIRED QUERIES (read only)
   ========================================================== */

// 1) Init: hydrate ServiceTerritoryMember (agent/agency & category) and Accounts cache
// const OFFLINE_INIT_QUERY = gql`
//   query OfflineWorkOrderInit($userId: ID!) {
//     uiapi {
//       query {
//         ServiceTerritoryMember(
//           where: { ServiceResource: { RelatedRecordId: { eq: $userId } } }
//           first: 1
//         ) {
//           edges {
//             node {
//               Id
//               ServiceResourceId { value }
//               ServiceResource {
//                 Name { value }
//                 Customer_Category__c { value }
//                 RelatedRecordId { value } 
//               }
//               ServiceTerritory {
//                 Id
//                 Name { value }
//               }
//             }
//           }
//         }

//         Account(first: 1000) {
//           edges {
//             node {
//               Id
//               Name { value }
//               BP_Number__c { value }
//               AMR_Name__c { value }
//               Meter_Number__c { value }
//               Location__c { value }
//               Zone__c { value }
//               Representative_Company__c { value }
//               Category__c { value }
//               City__c { value }               
//               Postal_Code__c { value }        
//               Building_name__c { value }      
//               Road_name__c { value }          
//             }
//           }
//         }
//       }
//     }
//   }
// `;

const OFFLINE_INIT_QUERY = gql`
  query OfflineWorkOrderInit($userId: ID!) {
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
                    Id
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

        Account(first: 1000, orderBy: { Name: { order: ASC } }) {
          edges {
            node {
              Id
              Name { value }
              BP_Number__c { value }
              AMR_Name__c { value }
              Meter_Number__c { value }
              Location__c { value }
              Zone__c { value }
              Representative_Company__c { value }
              Category__c { value }
              City__c { value }
              Postal_Code__c { value }
              Building_name__c { value }
              Road_name__c { value }
            }
          }
        }
      }
    }
  }
`;





// 2) Resolve ServiceAppointment created by WOFLOW for a given WorkOrder (to attach AssignedResource)
const SA_BY_WO_QUERY = gql`
  query FindSA($woId: ID!) {
    uiapi {
      query {
        ServiceAppointment(where: { ParentRecordId: { eq: $woId } }, first: 1) {
          edges {
            node { Id Status { value } }
          }
        }
      }
    }
  }
`;

  const SA_FIELDS_QUERY = gql`
  query SAFields($saId: ID!) {
    uiapi {
      query {
        ServiceAppointment(where: { Id: { eq: $saId } }, first: 1) {
          edges {
            node {
              Id
              SchedStartTime { value }
              SchedEndTime { value }
              Schedule_Start_Date__c { value }
              Schedule_End_Date__c { value }
              Appointment_Type__c { value }
            }
          }
        }
      }
    }
  }
`;

export default class WorkOrderCreationComponent extends NavigationMixin(LightningElement) {
  // ====== STATE ======
  isLoading = true;
  error;

  // Pagination properties
  @track displayedAccounts = [];
  @track filteredAccounts = [];
  allAccounts = [];
  pageSize = 15;
  currentPage = 0;
  isLoadingMore = false;
  hasMore = false;
  
  selectedAccount;

  agentDetails; // { agentId, agentName, agencyId, agencyName, customerCategory }

  showModal = false; 
  showCNGModal = false; 
  searchToggle = false;

  @track filters = { location: '', zone: '', representativeCompany: '', search: '' };
  @track allLocationOptions = [];
  @track allZoneOptions = [];
  @track allRepCompanyOptions = [];
  @track locationOptions = [];
  @track zoneOptions = [];
  @track representativeCompanyOptions = [];

  // Computed property for accountList
  get accountList() {
    return this.displayedAccounts;
  }

  loadMoreAccounts() {
    const start = this.currentPage * this.pageSize;
    const end = start + this.pageSize;
    const nextBatch = this.filteredAccounts.slice(start, end);
    
    if (nextBatch.length > 0) {
      this.displayedAccounts = [...this.displayedAccounts, ...nextBatch];
      this.currentPage++;
      this.hasMore = end < this.filteredAccounts.length;
    } else {
      this.hasMore = false;
    }
    
    // Reset loading flag after data is loaded
    this.isLoadingMore = false;
  }

  handleScroll(event) {
    // Prevent continuous loading
    if (this.isLoadingMore || !this.hasMore) {
      return;
    }
    
    const scrollTop = event.target.scrollTop;
    const scrollHeight = event.target.scrollHeight;
    const offsetHeight = event.target.offsetHeight;
    const bottomDistance = scrollHeight - (scrollTop + offsetHeight);
    
    // Trigger when within 50px of bottom (works better on mobile)
    if (bottomDistance < 50) {
      this.isLoadingMore = true;
      this.loadMoreAccounts();
    }
  }

  // ====== ONLINE DATA FLOW (unchanged) ======
  @wire(getComponentData)
  wiredData(result) {
    const { data, error } = result || {};
    if (!navigator.onLine) return; // online-only block

    this.isLoading = true;
    if (data) {
      this.allAccounts = data.accountList || [];
      this.agentDetails = data.agentDetails || null;
      this.filteredAccounts = [...this.allAccounts];
      
      // Initialize pagination
      this.currentPage = 0;
      this.displayedAccounts = [];
      this.loadMoreAccounts();

      if (this.agentDetails?.customerCategory === CNG_OPTION_VALUE) {
        this.showCNGModal = true;
        this.allLocationOptions = data.locationsList || [];
        this.allZoneOptions = data.zonesList || [];
        this.allRepCompanyOptions = data.representativeCompaniesList || [];
        this.updateDropdownOptions();
      }
      this.error = null;
    } else if (error) {
      this.error = error.body?.message || error.message;
    }
    this.isLoading = false;
  }

  // @wire(graphql, { query: OFFLINE_INIT_QUERY, variables: { userId: USER_ID } })
  // offlineInitData({ data, errors }) {
  //   if (navigator.onLine) return; 

  //   if (data) {
  //     try {
  //       const stmNode = data.uiapi?.query?.ServiceTerritoryMember?.edges?.[0]?.node;
  //           if (stmNode) {
  //           this.agentDetails = {
  //               agentId: stmNode.ServiceResourceId?.value,
  //               agentName: stmNode.ServiceResource?.Name?.value,
  //               agencyId: stmNode.ServiceTerritory?.Id,
  //               agencyName: stmNode.ServiceTerritory?.Name?.value,
  //               customerCategory: stmNode.ServiceResource?.Customer_Category__c?.value,
  //               resourceUserId: stmNode.ServiceResource?.RelatedRecordId?.value
  //           };
  //           }       
  //        const agentCat = (this.agentDetails?.customerCategory || '').toLowerCase();
  //         const cngCat = (CNG_OPTION_VALUE || '').toLowerCase();
  //         if (agentCat === cngCat) {
  //           this.showCNGModal = true;
  //            this.showToast('Debug', `CNG modal TRUE  (Category: ${this.agentDetails?.customerCategory})`, 'success');
  //         }else {
  //           this.showToast('Debug', `CNG modal FALSE  (Category: ${this.agentDetails?.customerCategory})`, 'warning');
  //       }

        

  //       const accEdges = data.uiapi?.query?.Account?.edges || [];
  //       this.allAccounts = accEdges.map(e => ({
  //           accountId: e.node?.Id,
  //           accountName: e.node?.Name?.value,
  //           BP_Number: e.node?.BP_Number__c?.value,
  //           AMR_Name: e.node?.AMR_Name__c?.value,
  //           Meter_Number: e.node?.Meter_Number__c?.value,
  //           Location: e.node?.Location__c?.value,
  //           Zone: e.node?.Zone__c?.value,
  //           Representative_Company: e.node?.Representative_Company__c?.value,
  //           Category: e.node?.Category__c?.value
  //           }));

  //      const category = this.agentDetails?.customerCategory || null;
  //       this.accountList = [...this.allAccounts];

  //       if (category) {
  //         const catLower = category.toLowerCase().trim();
  //         const filtered = this.allAccounts.filter(
  //           a => a.Category && a.Category.toLowerCase().trim().includes(catLower)
  //         );
  //         if (filtered.length > 0) {
  //           this.accountList = filtered;
  //         }
  //       }

  //       this.updateDropdownOptions();
  //     } catch (e) {
  //       console.warn('Offline GraphQL parse error:', e?.message);
  //     }
  //   } else if (errors) {
  //     // eslint-disable-next-line no-console
  //     console.warn('GraphQL wire errors (offline):', JSON.stringify(errors));
  //   }
  //   this.isLoading = false;
  // }

    // @wire(graphql, { query: OFFLINE_INIT_QUERY, variables: { userId: USER_ID } })
    // offlineInitData({ data, errors }) {
    //   if (navigator.onLine) return; 
    //   try {
    //     if (data) {
    //       const srNode = data.uiapi?.query?.ServiceResource?.edges?.[0]?.node;
    //       // if (!srNode) {
    //       //   this.showToast('Debug ', 'No ServiceResource node found in offline cache.', 'error');
    //       //   return;
    //       // }

    //       // Extract ServiceResource info
    //       const srId = srNode.Id;
    //       const srName = srNode.Name?.value;
    //       const srCategory = srNode.Customer_Category__c?.value;
    //       const srUserId = srNode.RelatedRecordId?.value;

    //       // Extract first linked ServiceTerritory (if any)
    //       const stNode = srNode.ServiceTerritories?.edges?.[0]?.node?.ServiceTerritory || {};
    //       const stId = stNode.Id || null;
    //       const stName = stNode.Name?.value || null;

    //       // Build agentDetails structure
    //       this.agentDetails = {
    //         agentId: srId,
    //         agentName: srName,
    //         agencyId: stId,
    //         agencyName: stName,
    //         customerCategory: srCategory,
    //         resourceUserId: srUserId
    //       };

    //       // Category-based CNG logic
    //       const agentCat = (srCategory || '').toLowerCase().trim();
    //       const cngCat = (CNG_OPTION_VALUE || '').toLowerCase().trim();
    //       if (agentCat.includes('cng') || agentCat === cngCat) {
    //         this.showCNGModal = true;
    //         //this.showToast('Debug ', `CNG modal TRUE — Category: ${srCategory}`, 'success');
    //       } else {
    //         this.showCNGModal = false;
    //         //this.showToast('Debug ', `CNG modal FALSE — Category: ${srCategory}`, 'warning');
    //       }

    //       // Map Account list (offline cached)
    //       const accEdges = data.uiapi?.query?.Account?.edges || [];
    //       this.allAccounts = accEdges.map(e => ({
    //         accountId: e.node?.Id,
    //         accountName: e.node?.Name?.value,
    //         BP_Number: e.node?.BP_Number__c?.value,
    //         AMR_Name: e.node?.AMR_Name__c?.value,
    //         Meter_Number: e.node?.Meter_Number__c?.value,
    //         Location: e.node?.Location__c?.value,
    //         Zone: e.node?.Zone__c?.value,
    //         Representative_Company: e.node?.Representative_Company__c?.value,
    //         Category: e.node?.Category__c?.value
    //       }));

    //       this.accountList = [...this.allAccounts];
    //       this.updateDropdownOptions();

    //       //this.showToast('Debug ', 'Offline data initialized successfully!', 'success');
    //     } else if (errors) {
    //       //this.showToast('Debug ', `GraphQL wire errors: ${JSON.stringify(errors)}`, 'error');
    //     }
    //   } catch (e) {
    //     this.showToast('Debug ', `Exception: ${e.message}`, 'error');
    //   } finally {
    //     this.isLoading = false;
    //   }
    // }

    @wire(graphql, { query: OFFLINE_INIT_QUERY, variables: { userId: USER_ID } })
  offlineInitData({ data, errors }) {
    if (navigator.onLine) return; 
    try {
      if (data) {
        const srNode = data.uiapi?.query?.ServiceResource?.edges?.[0]?.node;
        if (!srNode) {
          this.showToast('Error', 'No ServiceResource found in offline cache.', 'error');
          this.isLoading = false;
          return;
        }

        // Extract ServiceResource details
        const srCategory = srNode.Customer_Category__c?.value;
        const agentCat = (srCategory || '').toLowerCase().trim();
        const cngCat = (CNG_OPTION_VALUE || '').toLowerCase().trim();

        const stNode = srNode.ServiceTerritories?.edges?.[0]?.node?.ServiceTerritory || {};
        this.agentDetails = {
          agentId: srNode.Id,
          agentName: srNode.Name?.value,
          agencyId: stNode.Id,
          agencyName: stNode.Name?.value,
          customerCategory: srCategory,
          resourceUserId: srNode.RelatedRecordId?.value
        };

        // Confirm category via toast
        // this.showToast('Category Detected', `Agent Category: ${srCategory || 'Unknown'}`, 'info');

        // Determine if it's CNG
        this.showCNGModal = agentCat.includes('cng') || agentCat === cngCat;

        // Map offline accounts
        const accEdges = data.uiapi?.query?.Account?.edges || [];
        const allAccounts = accEdges.map(e => ({
          accountId: e.node?.Id,
          accountName: e.node?.Name?.value,
          BP_Number: e.node?.BP_Number__c?.value,
          AMR_Name: e.node?.AMR_Name__c?.value,
          Meter_Number: e.node?.Meter_Number__c?.value,
          Location: e.node?.Location__c?.value,
          Zone: e.node?.Zone__c?.value,
          Representative_Company: e.node?.Representative_Company__c?.value,
          Category: e.node?.Category__c?.value
        }));

        // Apply same Category filter as online Apex
        let filteredAccounts = allAccounts;
        if (srCategory) {
          const cat = (srCategory || '').toLowerCase();
          filteredAccounts = allAccounts.filter(acc => {
            const accCat = (acc.Category || '').toLowerCase();
            // Match if either side contains CNG or LPG (covers "CNG", "CNG/LPG", etc.)
            return (
              accCat.includes(cat) || cat.includes(accCat) ||
              (cat.includes('cng') && accCat.includes('cng')) ||
              (cat.includes('lpg') && accCat.includes('lpg'))
            );
          });
        }

        // Fallback if no match
        this.allAccounts = filteredAccounts.length ? filteredAccounts : allAccounts;
        this.filteredAccounts = [...this.allAccounts];
        
        // Initialize pagination
        this.currentPage = 0;
        this.displayedAccounts = [];
        this.loadMoreAccounts();

        // Refresh dropdowns
        this.updateDropdownOptions();

        // Optional: show count confirmation
        // this.showToast(
        //   'Offline Accounts Loaded',
        //   `Loaded ${this.accountList.length} accounts for category: ${srCategory || 'Unknown'}`,
        //   'success'
        // );

      } else if (errors) {
        this.showToast('Error', `GraphQL wire errors: ${JSON.stringify(errors)}`, 'error');
      }
    } catch (e) {
      this.showToast('Error', e?.message || 'Offline init failed.', 'error');
    } finally {
      this.isLoading = false;
    }
  }





  // ====== WorkOrder Object Info (for RecordType resolution offline) ======
  @wire(getObjectInfo, { objectApiName: WORKORDER_OBJECT })
  objectInfo;

  get _meteringRecordTypeId() {
    // Try to match by developer name first; fall back to defaultRecordTypeId
    const infos = this.objectInfo?.data?.recordTypeInfos;
    if (infos) {
      // recordTypeInfos is an object keyed by Id; iterate values
      const list = Object.values(infos);
      const metering = list.find(rt => (rt?.developerName === 'MGL_Metering' || rt?.developerName === 'Metering'));
      if (metering?.recordTypeId) return metering.recordTypeId;
      if (this.objectInfo?.data?.defaultRecordTypeId) return this.objectInfo.data.defaultRecordTypeId;
    }
    return null;
  }

  /* ==========================================================
     Search / Filter UI (parity with online)
     ========================================================== */
  handleSearchToggle() {
    this.searchToggle = !this.searchToggle;
    const listSection = this.template.querySelector('.custom-section');
    if (listSection) {
      listSection.style.height = this.searchToggle ? (this.showCNGModal ? '60vh' : '80vh') : '90vh';
    }
  }

  getFormattedOptions(list, field) {
    const vals = [...new Set(list.map(i => i[field]).filter(Boolean))];
    const formatted = vals.map(v => ({ label: v, value: v }));
    return [{ label: '--None--', value: '' }, ...formatted];
  }

  updateDropdownOptions() {
    let base = [...this.allAccounts];
    if (this.filters.location) base = base.filter(a => a.Location === this.filters.location);
    if (this.filters.zone) base = base.filter(a => a.Zone === this.filters.zone);
    if (this.filters.representativeCompany) base = base.filter(a => a.Representative_Company === this.filters.representativeCompany);

    this.locationOptions = this.getFormattedOptions(base, 'Location');
    this.zoneOptions = this.getFormattedOptions(base, 'Zone');
    this.representativeCompanyOptions = this.getFormattedOptions(base, 'Representative_Company');
  }

  filterGroups(event) {
    const fieldName = event.currentTarget.dataset.fieldName;
    const value = event.detail?.value || '';
    this.filters[fieldName] = (value === '--None--') ? '' : value;
    this.updateDropdownOptions();

    // Start with all accounts
    let filtered = [...this.allAccounts];
    
    // Apply search filter first (across all fields)
    if (this.filters.search) {
      const q = this.filters.search.toLowerCase();
      filtered = filtered.filter(g => (
        (g.accountName && g.accountName.toLowerCase().includes(q)) ||
        (g.BP_Number && g.BP_Number.toLowerCase().includes(q)) ||
        (g.AMR_Name && g.AMR_Name.toLowerCase().includes(q)) ||
        (g.Meter_Number && g.Meter_Number.toLowerCase().includes(q)) ||
        (g.Location && g.Location.toLowerCase().includes(q)) ||
        (g.Zone && g.Zone.toLowerCase().includes(q)) ||
        (g.Representative_Company && g.Representative_Company.toLowerCase().includes(q))
      ));
    }
    
    // Then apply dropdown filters to narrow results
    if (this.filters.location) filtered = filtered.filter(a => a.Location === this.filters.location);
    if (this.filters.zone) filtered = filtered.filter(a => a.Zone === this.filters.zone);
    if (this.filters.representativeCompany) filtered = filtered.filter(a => a.Representative_Company === this.filters.representativeCompany);

    // Reset pagination with filtered results
    this.filteredAccounts = filtered;
    this.currentPage = 0;
    this.displayedAccounts = [];
    this.loadMoreAccounts();
  }

  /* ==========================================================
     Selection & Modal
     ========================================================== */
  handleSelectAccount(event) {
    const selectedAccountId = event.currentTarget.dataset.id;
    const found = (this.displayedAccounts || []).find(a => a.accountId === selectedAccountId);
    if (found) {
      this.selectedAccount = found;
      this.showModal = true;
    }
  }

  closeModel() {
    this.showModal = false;
    this.selectedAccount = null;
  }

  /* ==========================================================
     Create Work Order (online unchanged; offline via LDS)
     ========================================================== */
  async handleCreateWorkOrder() {
    this.isLoading = true;

    if (!this.selectedAccount) {
      this.showToast('Error', 'No account selected for Work Order creation.', 'error');
      this.isLoading = false;
      return;
    }

    if (navigator.onLine) {
      // === ONLINE: preserve existing Apex behavior exactly ===
      createWorkOrder({ selectedAccount: this.selectedAccount, agentDetails: this.agentDetails })
        .then(result => {
          if (result === 'appointment created') {
            this.showToast('Error', 'You already have an appointment created for this customer today.', 'error');
          } else {
            this.showToast('Success', 'Work Order created successfully!', 'success');
            this.navigateToWorkOrder(result);
            this.closeModel();
          }
          this.isLoading = false;
        })
        .catch(error => {
          const msg = error?.body?.message || error?.message || 'An unknown error occurred.';
          this.showToast('Error', msg, 'error');
          this.isLoading = false;
        });
      return;
    }

    // === OFFLINE: LDS create with parity fields ===
    try {
      const nowIso = new Date().toISOString();
      const fields = {};
      fields[WO_ACCOUNT.fieldApiName] = this.selectedAccount.accountId;
      fields[WO_SUBJECT.fieldApiName] = `Metering for ${this.selectedAccount.accountName}`;
      fields[WO_STATUS.fieldApiName] = 'New';
      fields[WO_TYPE.fieldApiName] = 'Standard';
      fields[WO_ASSIGNED.fieldApiName] = this.agentDetails?.agentId || null;
      fields[WO_AGENCY.fieldApiName] = this.agentDetails?.agencyId || null;
      fields[WO_SCHED.fieldApiName] = new Date().toISOString();
      fields['ServiceTerritoryId'] = this.agentDetails?.agencyId || null;
      fields['OwnerId'] = this.agentDetails?.resourceUserId;
      fields[WO_START.fieldApiName] = nowIso;
      fields[WO_END.fieldApiName] = nowIso;
      if (this._meteringRecordTypeId) fields[WO_RTYPE.fieldApiName] = this._meteringRecordTypeId;

      const woInput = { apiName: WORKORDER_OBJECT.objectApiName, fields };
      const wo = await createRecord(woInput);
      const woId = wo.id;

      // Create dummy ServiceAppointment offline to mirror WOFLOW
      const today = new Date();
      const schedStart = new Date(today.setHours(9, 0, 0, 0));
      const schedEnd = new Date(today.setHours(17, 0, 0, 0));

      const saInput = {
        apiName: 'ServiceAppointment',
        fields: {
          ParentRecordId: woId,
          Status: 'None',
          SchedStartTime: schedStart.toISOString(),
          SchedEndTime: schedEnd.toISOString(),
          Appointment_Type__c: 'New'
        }
      };
      const sa = await createRecord(saInput);
      const saId = sa.id;

      // Create AssignedResource offline
      const arInput = {
        apiName: 'AssignedResource',
        fields: {
          ServiceAppointmentId: saId,
          ServiceResourceId: this.agentDetails?.agentId
        }
      };
      await createRecord(arInput);

      this.showToast('Success', 'Work Order queued for sync (offline).', 'success');
      this.navigateToWorkOrder(woId);
      this.closeModel();
    } catch (e) {
      this.showToast('Error', e?.message || 'Offline Work Order creation failed.', 'error');
    } finally {
      this.isLoading = false;
    }

  }

  // Offline SA resolution via GraphQL wire (no imperative graphql)
  @track _woId;
    @track _assignedCreated = false;
    @track _refreshedOnce = false;
  get _saVars() {
    return this._woId ? { woId: this._woId } : undefined;
  }


@track _assignedCreated = false;

@wire(graphql, { query: SA_BY_WO_QUERY, variables: '$_saVars' })
wiredSA({ data, errors }) {
  if (navigator.onLine) return;
  if (!this._woId) return;

  if (data) {
    const saEdges = data.uiapi?.query?.ServiceAppointment?.edges || [];
    if (saEdges.length === 0) return;

    const saId = saEdges[0]?.node?.Id;
    this._saId = saId;

    if (saId && !this._assignedCreated && this.agentDetails?.agentId) {
      createRecord({
        apiName: 'AssignedResource',
        fields: {
          ServiceAppointmentId: saId,
          ServiceResourceId: this.agentDetails.agentId
        }
      })
      .then(() => {
        this._assignedCreated = true;
        if (!this._refreshedOnce) {
          window.dispatchEvent(new CustomEvent('metering:appointments-updated'));
          this._refreshedOnce = true;
        }
        this.showToast('Success', 'Assigned Resource linked successfully (offline)', 'success');
      })
      .catch((err) => {
        this.showToast('Error', err?.body?.message || 'Failed to create Assigned Resource offline', 'error');
      });
    }
  } else if (errors) {
    // optional log
  }
}


  @track _saId;   // set when SA_BY_WO_QUERY finds the child SA
get _saFieldVars() {
  return this._saId ? { saId: this._saId } : undefined;
}
@wire(graphql, { query: SA_FIELDS_QUERY, variables: '$_saFieldVars' })
wiredSaFields({ data, errors }) {
  if (navigator.onLine) return;
  if (!this._saId || this._assignedCreated === false) return;


  if (data) {
    const node = data.uiapi?.query?.ServiceAppointment?.edges?.[0]?.node;
    if (!node) return;

    const needTimes = !(node.SchedStartTime?.value) || !(node.SchedEndTime?.value);
    const needDates = !(node.Schedule_Start_Date__c?.value) || !(node.Schedule_End_Date__c?.value);
    const needType = !(node.Appointment_Type__c?.value);

    if (needTimes || needDates || needType) {
      const today = new Date();
      const y = today.getFullYear();
      const m = String(today.getMonth() + 1).padStart(2, '0');
      const d = String(today.getDate()).padStart(2, '0');
      const dateStr = `${y}-${m}-${d}`;
      const start = new Date(today); start.setHours(9, 0, 0, 0);
      const end = new Date(today); end.setHours(17, 0, 0, 0);

      updateRecord({
        fields: Object.assign(
          { Id: this._saId },
          needTimes ? { SchedStartTime: start.toISOString(), SchedEndTime: end.toISOString() } : {},
          needDates ? { Schedule_Start_Date__c: dateStr, Schedule_End_Date__c: dateStr } : {},
          needType ? { Appointment_Type__c: 'Scheduled' } : {}
        )
      })
      .then(() => {
         refreshGraphQL().catch(() => {});
            if (!this._refreshedOnce) {
              window.dispatchEvent(new CustomEvent('metering:appointments-updated'));
              this._refreshedOnce = true;
            }
      })
      .catch(e => {
        this.showToast('Error', e?.body?.message || 'Failed to set schedule fields offline', 'error');
      });
    }
  } else if (errors) {
    // optional log
  }
}




  /* ==========================================================
     Navigation & Utilities
     ========================================================== */
  navigateToWorkOrder(recordId) {
    if (!recordId) return;
    if(!navigator.onLine) return;
    if (FORM_FACTOR === 'Large') {
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: { recordId, actionName: 'view' }
      });
    } else {
      // Field Service Mobile deep link
      this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: { url: `com.salesforce.fieldservice://v1/sObject/${recordId}/overview` }
      });
    }
  }

  showToast(title, message, variant, mode) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode }));
  }
}