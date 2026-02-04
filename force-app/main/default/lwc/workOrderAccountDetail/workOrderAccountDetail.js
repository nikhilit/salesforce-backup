/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 16-12-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   07-05-2025   Kartik Patkar, Appstrail   Initial Version
 * 1.1   06-10-2025   Offline Enhancements       Added LDS fallbacks behind navigator.onLine (no HTML changes)
**/
import { LightningElement, api, wire, track } from 'lwc';
import getAccountInfoFromSA from '@salesforce/apex/WorkOrderAccountInfoController.getAccountInfoFromSA';
import getGroupDataForTodayAppointments from '@salesforce/apex/WorkOrderAccountInfoController.getGroupDataForTodayAppointments';
// import searchGroupDetails from '@salesforce/apex/WorkOrderAccountInfoController.searchGroupDetails';
// import searchGroupMessage from '@salesforce/apex/WorkOrderAccountInfoController.searchGroupMessage';
import updateServiceAppointment from '@salesforce/apex/WorkOrderAccountInfoController.updateServiceAppointment';
import workOrderCheckIn from '@salesforce/apex/WorkOrderAccountInfoController.workOrderCheckIn';
import saveImage from '@salesforce/apex/WorkOrderAccountInfoController.saveImage';
import getGroupMasterOptions from '@salesforce/apex/WorkOrderAccountInfoController.getGroupMasterOptions';
import getGroupCodeOptions from '@salesforce/apex/WorkOrderAccountInfoController.getGroupCodeOptions';
import getGroupMessageOptions from '@salesforce/apex/WorkOrderAccountInfoController.getGroupMessageOptions';
import getNextWorkOrder from '@salesforce/apex/WorkOrderAccountInfoController.getNextWorkOrder';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getLocationService } from 'lightning/mobileCapabilities';
import FORM_FACTOR from '@salesforce/client/formFactor';
import ZERO_CONSUMPTION_ALERT_MESSAGE from '@salesforce/label/c.Metering_Zero_Consumption_Alert_Message';
import { CloseActionScreenEvent } from 'lightning/actions';

/* LDS APIs === */
import { getRecord, getFieldValue, updateRecord, createRecord } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { getListUi } from 'lightning/uiListApi';
import { graphql, gql } from 'lightning/uiGraphQLApi'; 
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import WORKORDER_OBJECT from '@salesforce/schema/WorkOrder';
import LPG_SUPPLIER_FIELD from '@salesforce/schema/WorkOrder.LPG_Supplier__c';
import MGL_STATUS_FIELD from '@salesforce/schema/WorkOrder.MGL_gas_burnt_Meter_status__c';
    


/* Fields for WorkOrder & Account === */
import WO_ID from '@salesforce/schema/WorkOrder.Id';
import WO_ACCOUNT from '@salesforce/schema/WorkOrder.AccountId';
import WO_PREV from '@salesforce/schema/WorkOrder.Previous_Meter_Reading__c';
import WO_LAST_DATE from '@salesforce/schema/WorkOrder.Last_Meter_Reading_Date__c';
import WO_AVG from '@salesforce/schema/WorkOrder.Average_Consumption__c';
import WO_GM from '@salesforce/schema/WorkOrder.Group_Master__c';
import WO_GC from '@salesforce/schema/WorkOrder.Group_Code__c';
import WO_GMSG from '@salesforce/schema/WorkOrder.Group_Message__c';
import WO_DESC from '@salesforce/schema/WorkOrder.Description';
import WO_REMARKS from '@salesforce/schema/WorkOrder.Remarks__c';
import WO_SA from '@salesforce/schema/WorkOrder.Service_Appointment__c';
import WO_CUSTOMER_CATEGORY from '@salesforce/schema/WorkOrder.Customer_Category__c';
import WO_BUILDING_NAME from '@salesforce/schema/WorkOrder.Building_Name_DMC__c';
import WO_ASSIGNED_METER_READER from '@salesforce/schema/WorkOrder.Assigned_Meter_Reader__c';
import WO_OFFLINE_TARGET_SA_STATUS from '@salesforce/schema/WorkOrder.Offline_Target_SA_Status__c';



import A_ID from '@salesforce/schema/Account.Id';
import A_FULLNAME from '@salesforce/schema/Account.Full_Name__c';
import A_BP from '@salesforce/schema/Account.BP_Number__c';
import A_METER from '@salesforce/schema/Account.Meter_Number__c';
import A_CA from '@salesforce/schema/Account.CA_Number__c';
import A_PHONE_MOB from '@salesforce/schema/Account.Phone__c';
import A_PHONE_HOME from '@salesforce/schema/Account.Secondary_Phone__c';
import A_PHONE_OFF from '@salesforce/schema/Account.Customer_Contact_No_Office__c';
import A_EMAIL from '@salesforce/schema/Account.Account_Email__c';
import A_STREET from '@salesforce/schema/Account.Street__c';
import A_POSTAL from '@salesforce/schema/Account.Postal_Code__c';
import A_BUILDING_NAME from '@salesforce/schema/Account.Building_name__c';

import SA_ID_FIELD from '@salesforce/schema/ServiceAppointment.Id';
import SA_TARGET_STATUS from '@salesforce/schema/ServiceAppointment.Target_SA_Status__c'; 


import GROUP_MASTER_OBJECT from '@salesforce/schema/Group_Master__c';
import GROUP_CODE_OBJECT from '@salesforce/schema/Group_Code__c';
import GROUP_MESSAGE_OBJECT from '@salesforce/schema/Group_Message__c';


const FIELDS_GM = ['GroupMaster__c.Name','GroupMaster__c.Default__c'];
const FIELDS_GC = ['GroupCode__c.Name','GroupCode__c.GroupMaster__c','GroupCode__c.ShowMeterReadingOption__c','GroupCode__c.No_of_Photos__c','GroupCode__c.LPGSupplier__c'];
const FIELDS_GMSG = ['GroupMessage__c.Name','GroupMessage__c.GroupCode__c']

const GM_GC_GMSG_QUERY = gql`
  query GroupCatalog(
    $groupMasterId: ID
    $type: Picklist
    $plausible: Boolean
    $high: Boolean
    $low: Boolean
    $groupCodeId: ID
  ) {
    uiapi {
      query {
        Group_Master__c(
          where: { Active__c: { eq: true } }
          orderBy: { Group_Code__c: { order: ASC } }
        ) {
          edges {
            node {
              Id
              Name { value }
              Default__c { value }
              Group_Code__c { value }
            }
          }
        }

        Group_Code__c(
          where: {
            Active__c: { eq: true }
            Plausibility_Check_Options__c: { eq: $plausible }
            Group_Master__c: { eq: $groupMasterId }
          }
          orderBy: { Code__c: { order: ASC } }
        ) {
          edges {
            node {
              Id
              Code__c { value }
              Description__c { value }
              Default__c { value }
              Show_Meter_Reading_Option__c { value }
              Testing_Not_possible__c { value }
              Testing_Possible_Default__c { value }
              Meter_not_working__c { value }
              Meter_working__c { value }
              Plausibility_Check_Options__c { value }
              Group_Master__c { value }
              Document_Masters__r(
                where: {
                  Active__c: { eq: true }
                  Type__c: { eq: $type }
                }
                orderBy: { Order__c: { order: ASC } }
              ) {
                edges {
                  node {
                    Id
                    Document_Name__c { value }
                    Order__c { value }
                    Type__c { value }
                    Compress_Image__c { value }
                    OCR__c { value }
                  }
                }
              }
            }
          }
        }

        Group_Message__c(
          where: {
            Active__c: { eq: true }
            Plausible_Options__c: { eq: $plausible }
            High_Consumption_Options__c: { eq: $high }
            Low_Consumption_Options__c: { eq: $low }
            Group_Code__c: { eq: $groupCodeId }
          }
          orderBy: { Name: { order: ASC } }
        ) {
          edges {
            node {
              Id
              Name { value }
              Description__c { value }
              Group_Code__c { value }
              Show_Meter_Reading_Option__c { value }
              No_of_Photos__c { value }
              LPG_Supplier__c { value }
            }
          }
        }
      }
    }
  }
`;





// const WORKSTEP_QUERY = gql`
//   query FindWorkStep($woId: ID!, $name: String!) {
//     uiapi {
//       query {
//         WorkStep(
//           where: {
//             ParentRecordId: { eq: $woId },
//             Name: { eq: $name }
//           },
//           first: 1
//         ) {
//           edges {
//             node {
//               Id
//               Name { value }
//               Status { value }
//             }
//           }
//         }
//       }
//     }
//   }
// `;

const SA_BY_WO_QUERY = gql`
  query FindSA($woId: ID!) {
    uiapi {
      query {
        ServiceAppointment(
          where: { ParentRecordId: { eq: $woId } }
          first: 5
        ) {
          edges {
            node {
              Id
              Status { value }
            }
          }
        }
      }
    }
  }
`;

const NEXT_WORK_ORDERS_WITH_BUILDING = gql`
 query NextWorkOrdersWithBuilding(
  $workOrderId: ID!
  $buildingName: String!
  $meterReaderId: ID!
) {
  uiapi {
    query {
      WorkOrder(
        where: {
          Appointment_Status__c: { eq: "Unattempted" }
          Assigned_Meter_Reader__c: { eq: $meterReaderId }
          Expired__c: { eq: false }
          Id: { ne: $workOrderId }
          Account: { Building_name__c: { eq: $buildingName } }
        }
        first: 20
        orderBy: {
          Account: {
            Building_name__c: { order: ASC, nulls: LAST }
            Floor__c:        { order: ASC, nulls: LAST }
            Flat__c:         { order: ASC, nulls: LAST }
          }
        }
      ) {
        edges {
          node {
            Id
            Customer_Meter_Number__c { value }
            Account {
              Name            { value }
              Building_name__c{ value }
              BP_Number__c    { value }
              Location__c     { value }
              Plot__c         { value }
              Flat__c         { value }
              Floor__c        { value }
              Wing__c         { value }
            }
          }
        }
      }
    }
  }
}
`;

const NEXT_WORK_ORDERS_NO_BUILDING = gql`
 query NextWorkOrdersNoBuilding(
  $workOrderId: ID!
  $meterReaderId: ID!
) {
  uiapi {
    query {
      WorkOrder(
        where: {
          Appointment_Status__c: { eq: "Unattempted" }
          Assigned_Meter_Reader__c: { eq: $meterReaderId }
          Expired__c: { eq: false }
          Id: { ne: $workOrderId }
        }
        first: 20
        orderBy: {
          Account: {
            Building_name__c: { order: ASC, nulls: LAST }
            Floor__c:        { order: ASC, nulls: LAST }
            Flat__c:         { order: ASC, nulls: LAST }
          }
        }
      ) {
        edges {
          node {
            Id
            Customer_Meter_Number__c { value }
            Account {
              Name            { value }
              Building_name__c{ value }
              BP_Number__c    { value }
              Location__c     { value }
              Plot__c         { value }
              Flat__c         { value }
              Floor__c        { value }
              Wing__c         { value }
            }
          }
        }
      }
    }
  }
}
`;



const WO_BASIC_QUERY = gql`
  query FetchWO($woId: ID!) {
    uiapi {
      query {
        WorkOrder(where: { Id: { eq: $woId } }, first: 1) {
          edges {
            node {
              Id
              Building_Name_DMC__c { value }
              Assigned_Meter_Reader__c { value }
            }
          }
        }
      }
    }
  }
`;







// async function completeWorkStep(workOrderId, stepName = 'Start Metering') {
//   const QUERY = gql`
//     query WS($woId: ID!, $name: String!) {
//       uiapi {
//         query {
//           WorkStep(
//             where: { ParentRecordId: { eq: $woId }, Name: { eq: $name } }
//             first: 1
//           ) {
//             edges { node { Id Status { value } } }
//           }
//         }
//       }
//     }
//   `;
//   const resp = await graphql({ query: QUERY, variables: { woId: workOrderId, name: stepName } }); 
//   const wsId = resp?.data?.uiapi?.query?.WorkStep?.edges?.[0]?.node?.Id; 
//   if (!wsId) return; 
//   await updateRecord({ fields: { Id: wsId, Status: 'Completed' } }); 
// }


/* ========================================================================== */

export default class WorkOrderAccountDetail extends NavigationMixin(LightningElement) {
    // @api recordId;
    account;
    error;
    @track serviceAppointmentId;
    @track groupDetails = [];
    @track groupMessages = [];
    @track selectedGroupDetailId;
    @track selectedGroupMessageId;
    @track currentMeterReading;
    @track followUpRemarks;
    @track error;
    @track meterReadingPage = false;
    @track accountView = true;
    @track searchKey = '';
    @track selectedId;
    @track searchResults = [];
    @track lookupOptions = [];
    @track imageUploadPage = false;
    @track updateCustomer = false;
    @track noOfPhotosRequired;
    @track photoUploadSlots = [];
    @track showMeterReadingPossible = false;
    @track finalAttempt = false;
    @track meterSerialCorrect = false;
    @track meterWorking = false;
    @track meterImageCaptured = false;
    @track selectedGroupDetailLabel = '';
    @track selectedGroupMessageLabel = '';
    @track showPreviewPage = false;
    @track premiseCorrect = false;
    @track meterSerialVisible = false;
    @track showAdditionalComment = false;
    @track additionalComment;
    zeroConsumptionMessage = ZERO_CONSUMPTION_ALERT_MESSAGE;
    isOfflineSaving = false;
    @track plausibleOption = false;      
    @track highConsumption = false;      
    @track lowConsumption = false;       
    @track customerCategory = '';   
    _initSlotsDone = false;   
    @track workOrderRec = {};  
    _useBuildingFilter = false;

        // Cached offline data built from GraphQL on init when online
    _allGMs = [];     // [{ id, record }]
    _allCodes = [];   // [{ id, record, docs: [] }]
    _allMsgs = [];    // [{ id, parentId, record }]


    _recordId;
    recordIdData;
    @api get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.recordIdData=value;
        this.init();              
        this.fetchGroupData();  
         // Only run offline SA resolution when offline
    //    if (navigator.onLine) {
    //         setTimeout(() => this.fetchGroupData(), 300); 
    //     } else {
    //         this._resolveServiceAppointmentOffline().catch(() => {});
    //     }

    }

    

    get woIdForWire() {
         console.log('[woIdForWire:get] returning:', this._recordId);
        return this._recordId || null; 
    }

    _showInfoToast(title, message) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'info' }));
    }


   connectedCallback() {
    
        // Online: start on Customer Information
        this.accountView = true;
        this.meterReadingPage = false;
        this.imageUploadPage = false;
        this.showPreviewPage = false;
        this.formFirstPage = true;
    }




    lpgSupplierOptions = [];
    workOrderRec;

    get isOnline() {
        return navigator.onLine;
    }

    get gqlQuery() {
    return this._recordId ? SA_BY_WO_QUERY : undefined;
    }

    get gqlVars() {
        return this._recordId ? { woId: this._recordId } : undefined;
    }

    /* === OFFLINE ADD: LDS wires hydrate WO & Account when offline === */
    @wire(getRecord, {
        recordId: '$_recordId',
        fields: [WO_ID, WO_ACCOUNT, WO_PREV, WO_LAST_DATE, WO_AVG, WO_GM, WO_GC, WO_GMSG, WO_DESC, WO_REMARKS, WO_SA, WO_CUSTOMER_CATEGORY,WO_BUILDING_NAME,WO_OFFLINE_TARGET_SA_STATUS,
        WO_ASSIGNED_METER_READER]
    })
    wiredWO({ data }) {
        if (!data) return;
        if (!navigator.onLine) {
            this.workOrderRec = {
                Id: getFieldValue(data, WO_ID),
                AccountId: getFieldValue(data, WO_ACCOUNT),
                Previous_Meter_Reading__c: getFieldValue(data, WO_PREV),
                Last_Meter_Reading_Date__c: getFieldValue(data, WO_LAST_DATE),
                Average_Consumption__c: getFieldValue(data, WO_AVG),
                Group_Master__c: getFieldValue(data, WO_GM),
                Group_Code__c: getFieldValue(data, WO_GC),
                Group_Message__c: getFieldValue(data, WO_GMSG),
                Description: getFieldValue(data, WO_DESC),
                Remarks__c: getFieldValue(data, WO_REMARKS),
                Service_Appointment__c: getFieldValue(data, WO_SA),
                Customer_Category__c: getFieldValue(data, WO_CUSTOMER_CATEGORY),
                 Building_Name_DMC__c: getFieldValue(data, WO_BUILDING_NAME),             
                Assigned_Meter_Reader__c: getFieldValue(data, WO_ASSIGNED_METER_READER) ,
                Offline_Target_SA_Status__c: getFieldValue(data, WO_OFFLINE_TARGET_SA_STATUS)
            };
            // Seed selections so UI can proceed offline
            this.groupMasterValue = this.groupMasterValue || this.workOrderRec.Group_Master__c;
            this.groupCodeValue = this.groupCodeValue || this.workOrderRec.Group_Code__c;
            this.groupMessageValue = this.groupMessageValue || this.workOrderRec.Group_Message__c;

             // 3) Set SA Id for offline updates
            if (!this.serviceAppointmentId && this.workOrderRec.Service_Appointment__c) {
                this.serviceAppointmentId = this.workOrderRec.Service_Appointment__c;
            }

             // set customerCategory and nonMRS flag for offline flows
                if (this.workOrderRec.Customer_Category__c) {
                    if (this.workOrderRec.Customer_Category__c === 'Non-MRS Commercial' || this.workOrderRec.Customer_Category__c === 'Non-MRS') {
                        this.customerCategory = 'Non-MRS';
                        this.nonMRS = true;
                    } else {
                        this.customerCategory = 'Domestic';
                        this.nonMRS = false;
                    }
                }

                // this.debugToast(
                //     'wiredWO loaded: ' +
                //     JSON.stringify({
                //         id: this.workOrderRec.Id,
                //         building: this.workOrderRec.Building_Name_DMC__c,
                //         reader: this.workOrderRec.Assigned_Meter_Reader__c
                //     })
                // );

        }
    }


    get gqlWOvars() {
        return navigator.onLine ? undefined : { woId: this._recordId };
    }
    
    @wire(graphql, { query: WO_BASIC_QUERY, variables: '$gqlWOvars' })
        wiredWOoffline({ data }) {
            if (!navigator.onLine) {
                if (data) {
                    const node = data.uiapi?.query?.WorkOrder?.edges?.[0]?.node;
                    if (node) {
                        if (!this.workOrderRec) this.workOrderRec = {};

                        this.workOrderRec.Building_Name_DMC__c =
                            node?.Building_Name_DMC__c?.value || '';
                        this.workOrderRec.Assigned_Meter_Reader__c =
                            node?.Assigned_Meter_Reader__c?.value || '';

                        // this.debugToast(
                        //     'Offline WO GraphQL loaded → ' +
                        //     JSON.stringify({
                        //         building: this.workOrderRec.Building_Name_DMC__c,
                        //         reader: this.workOrderRec.Assigned_Meter_Reader__c
                        //     })
                        // );
                    }
                }
            }
        }

    get accountIdFromWO() { return this.workOrderRec?.AccountId; }

    @wire(getRecord, {
        recordId: '$accountIdFromWO',
        fields: [A_ID, A_FULLNAME, A_BP, A_METER, A_CA, A_PHONE_MOB, A_PHONE_HOME, A_PHONE_OFF, A_EMAIL, A_STREET, A_POSTAL, A_BUILDING_NAME]
    })
    wiredAcc({ data }) {
        if (!data) return;
        if (!navigator.onLine) {
            this.account = {
                Id: getFieldValue(data, A_ID),
                Full_Name__c: getFieldValue(data, A_FULLNAME),
                BP_Number__c: getFieldValue(data, A_BP),
                Meter_Number__c: getFieldValue(data, A_METER),
                CA_Number__c: getFieldValue(data, A_CA),
                Phone__c: getFieldValue(data, A_PHONE_MOB),
                Secondary_Phone__c: getFieldValue(data, A_PHONE_HOME),
                Customer_Contact_No_Office__c: getFieldValue(data, A_PHONE_OFF),
                Account_Email__c: getFieldValue(data, A_EMAIL),
                Street__c: getFieldValue(data, A_STREET),
                Postal_Code__c: getFieldValue(data, A_POSTAL),
                 Building_name__c: getFieldValue(data, A_BUILDING_NAME)
            };
        }
    }


        // Object Info (needed to fetch picklists)
        @wire(getObjectInfo, { objectApiName: WORKORDER_OBJECT })
        objectInfo;

        // LPG Supplier Picklist
        @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: LPG_SUPPLIER_FIELD
        })
        wiredLpgPicklist({ data, error }) {
        if (data) {
            this.lpgSupplierOptions = data.values.map(v => ({ label: v.label, value: v.value }));
        } else if (error && !navigator.onLine) {
            // fallback if device offline and no cache yet
            this.lpgSupplierOptions = [
            { label: 'Indane', value: 'Indane' },
            { label: 'Bharat Gas', value: 'Bharat Gas' },
            { label: 'HP Gas', value: 'HP Gas' },
            { label: 'Other', value: 'Other' }
            ];
        }
        }
        

        // MGL Gas Burnt Meter Status Picklist
        @wire(getPicklistValues, {
            recordTypeId: '$objectInfo.data.defaultRecordTypeId',
            fieldApiName: MGL_STATUS_FIELD
            })
            wiredMglPicklist({ data, error }) {
            if (data) {
                this.gasBurntMeterStatusOptions = data.values.map(v => ({ label: v.label, value: v.value }));
            } else if (error && !navigator.onLine) {
                this.gasBurntMeterStatusOptions = [
                { label: 'Meter working', value: 'Meter working' },
                { label: 'Meter not working', value: 'Meter not working' },
                { label: 'No flame / Not burning', value: 'No flame / Not burning' }
                ];
            }
        }

        get wsQuery() {
            return this._recordId ? WORKSTEP_QUERY : undefined;
        }
        get wsVars() {
            return this._recordId ? { woId: this._recordId, name: this.stepName } : undefined;
        }

  stepName = 'Start Metering';

      @wire(graphql, { query: '$wsQuery', variables: '$wsVars' })
            wiredWorkStep({ data, errors }) {
            if (data) {
                const edges = data.uiapi?.query?.WorkStep?.edges || [];
                this._workStepId = edges.length > 0 ? edges[0].node?.Id : null;
                this._workStepStatus = edges.length > 0 ? edges[0].node?.Status?.value : null;
            } else if (errors) {
                console.warn('WorkStep GraphQL wire errors', JSON.stringify(errors));
            }
        }

    get gqlQuery() { return this._recordId ? SA_BY_WO_QUERY : undefined; }       
    get gqlVars()  { return this._recordId ? { woId: this._recordId } : undefined; } 

    @wire(graphql, { query: '$gqlQuery', variables: '$gqlVars' })
        wiredSA({ data, errors }) {
            if (navigator.onLine) return;
            try {
                 console.log('[wiredSA] woIdForWire now:', this.woIdForWire);
                if (!data && !errors) {
                    console.warn('GraphQL wire returned no data or errors.');
                    return;
                }

                const edges = data?.uiapi?.query?.ServiceAppointment?.edges || [];
                 console.log('[wiredSA] edges:', JSON.stringify(edges.map(e => e?.node?.Id)));

                const saId = edges[0]?.node?.Id || null;
                console.log('SA ID --->', saId);

                if (saId) {
                    this.serviceAppointmentId = saId;
                    console.log('this.serviceAppointmentId', this.serviceAppointmentId);
                    return;
                }

                if (this.workOrderRec?.Service_Appointment__c) {
                    this.serviceAppointmentId = this.workOrderRec.Service_Appointment__c;
                    console.log('Fallback SA ID --->', this.serviceAppointmentId);
                }

                if (errors && errors.length) {
                    console.warn('SA GraphQL wire errors:', JSON.stringify(errors));
                }
            } catch (error) {
                console.error('Error in wiredSA:', error);
            }
        }

        get WORKSTEP_QUERY() {
            return gql`
                query FindWS($woId: ID!) {
                uiapi {
                    query {
                    WorkStep(
                        where: { ParentRecordId: { eq: $woId } }
                        first: 10
                    ) {
                        edges {
                        node {
                            Id
                            Name { value }
                            Status { value }
                        }
                        }
                    }
                    }
                }
                }
            `;
            }

        @wire(graphql, { query: '$WORKSTEP_QUERY', variables: '$wsVars' })
            wiredWorkStep({ data, errors }) {
             if (navigator.onLine) return;
            if (!data) {
                if (errors && errors.length) {
                }
                return;
            }

            const target = this._normalize(this.stepName || 'Start Metering');
            const edges = data?.uiapi?.query?.WorkStep?.edges || [];
            const list = edges.map(e => ({
                id: e?.node?.Id,
                name: this._normalize(e?.node?.Name?.value),
                status: e?.node?.Status?.value
            })).filter(x => !!x.id);

            // Prefer exact name match
            const match = list.find(x => x.name === target) || list[0] || null;
            this._workStepId = match?.id || null;
            this._workStepStatus = match?.status || null;
            }


    @wire(getListUi, { objectApiName: 'Group_Master__c', listViewApiName: 'All' })
        wiredMasters({ data, error }) {
    if(!navigator.onLine){
        if (data) {
            this.groupMasterOptions = data.records.records.map(r => ({
            label: r.fields.Name.value,
            value: r.id,
            record: { Default__c: r.fields.Default__c?.value || false }
            }));
        } 
        } else if (error && !navigator.onLine) {
            this.groupMasterOptions = [];
        }
    }

    get gqlVarsGroup() {
        const type =
            this.customerCategory === 'Non-MRS' || this.customerCategory === 'Non-MRS Commercial'
            ? 'MGL'
            : 'LPG';

        return {
            type,
            plausible: !!this.checkForZeroReading,
            high: !!this.highConsumption,
            low: !!this.lowConsumption,
            groupMasterId: this.groupMasterValue || null,
            groupCodeId: this.groupCodeValue || null
        };
    }





    @wire(graphql, { query: GM_GC_GMSG_QUERY, variables: '$gqlVarsGroup' })
    wiredCatalog({ data, errors }) {
    if (navigator.onLine) return; 

    if (data) {
        const q = data.uiapi?.query || {};
        const masters = q.Group_Master__c?.edges || [];
        const codes = q.Group_Code__c?.edges || [];
        const msgs = q.Group_Message__c?.edges || [];

        /* === Group Masters === */
        this._allMasters = masters.map(e => ({
            label: `${e.node?.Group_Code__c?.value ?? ''} - ${e.node?.Name?.value ?? ''}`.trim(),
            value: e.node?.Id,
            record: { Default__c: !!e.node?.Default__c?.value }
        }));
        this.groupMasterOptions = this._allMasters;

        /* === Group Codes === */
        this._allCodes = codes.map(e => {
        const expectedType = (this.customerCategory || '').toString().toLowerCase().includes('non') ? 'MGL' : 'LPG';

        const docs = (e.node?.Document_Masters__r?.edges || [])
            .filter(d => {
                const t = (d.node?.Type__c?.value || '').toString().trim().toUpperCase();
                return t && t === expectedType;
            })
            .map(d => ({
                id: d.node?.Id,
                label: d.node?.Document_Name__c?.value,
                index: d.node?.Order__c?.value,
                type: d.node?.Type__c?.value,
                compress: !!d.node?.Compress_Image__c?.value,
                ocr: !!d.node?.OCR__c?.value
            }));

            return {
                label: `${e.node?.Code__c?.value ?? ''} - ${e.node?.Description__c?.value ?? ''}`.trim(),
                value: e.node?.Id,
                parentId: e.node?.Group_Master__c?.value || null,
                record: {
                    Default__c: !!e.node?.Default__c?.value,
                    Show_Meter_Reading_Option__c: !!e.node?.Show_Meter_Reading_Option__c?.value,
                    Testing_Not_possible__c: !!e.node?.Testing_Not_possible__c?.value,
                    Testing_Possible_Default__c: !!e.node?.Testing_Possible_Default__c?.value,
                    Meter_not_working__c: !!e.node?.Meter_not_working__c?.value,
                    Meter_working__c: !!e.node?.Meter_working__c?.value,
                    Plausibility_Check_Options__c: !!e.node?.Plausibility_Check_Options__c?.value
                },
                listDocumentWrapper: docs
            };
        });

        /* === Group Messages === */
        this._allMsgs = msgs.map(e => ({
            label: e.node?.Description__c?.value || e.node?.Name?.value || '',
            value: e.node?.Id,
            parentId: e.node?.Group_Code__c?.value || null,
            record: {
                Show_Meter_Reading_Option__c: !!e.node?.Show_Meter_Reading_Option__c?.value,
                No_of_Photos__c: Number(e.node?.No_of_Photos__c?.value || 0),
                LPG_Supplier__c: !!e.node?.LPG_Supplier__c?.value,
                Plausible_Options__c: !!e.node?.Plausible_Options__c?.value,
                High_Consumption_Options__c: !!e.node?.High_Consumption_Options__c?.value,
                Low_Consumption_Options__c: !!e.node?.Low_Consumption_Options__c?.value
            }
        }));

        const defGM = this._allMasters.find(x => x.record.Default__c);
        if (defGM && !this.groupMasterValue) {
            this.groupMasterValue = defGM.value;
        }

        this.filterCodes();
        this.filterMessages();
        if (!navigator.onLine && this.groupCodeValue && (!this.photoUploadSlots || this.photoUploadSlots.length === 0)) {
            this.setPhotoUploadSlots();
        }
    }
    else if (errors) {
        console.warn('GraphQL errors', JSON.stringify(errors));
        this.groupMasterOptions = [];
        this.groupCodeOptions = [];
        this.groupMessageOptions = [];
    }
}

/* === Filtering identical to Apex dynamic queries === */
filterCodes({ plausibleOption } = {}) {
    if (navigator.onLine) return;
    const base = this._allCodes || [];

    let filtered = base;
    if (this.groupMasterValue)
        filtered = filtered.filter(x => x.parentId === this.groupMasterValue);

    if (plausibleOption !== undefined)
        filtered = filtered.filter(x => !!x.record.Plausibility_Check_Options__c === !!plausibleOption);

    this.groupCodeOptions = filtered;

    const def = filtered.find(x => x.record.Default__c);
    if (!this.groupCodeValue && (def || filtered.length === 1)) {
        this.groupCodeValue = def ? def.value : filtered[0]?.value;
        const sel = filtered.find(x => x.value === this.groupCodeValue);
        this.showMeterReading = !!sel?.record?.Show_Meter_Reading_Option__c;
        this.photoUploadSlots = sel?.listDocumentWrapper || [];
    }
}

filterMessages({ plausibleOption, highConsumptions, lowConsumptions } = {}) {
    if (navigator.onLine) return;
    let filtered = this._allMsgs || [];

    if (this.groupCodeValue)
        filtered = filtered.filter(x => x.parentId === this.groupCodeValue);

    if (plausibleOption !== undefined)
        filtered = filtered.filter(m => !!m.record.Plausible_Options__c === !!plausibleOption);
    if (highConsumptions !== undefined)
        filtered = filtered.filter(m => !!m.record.High_Consumption_Options__c === !!highConsumptions);
    if (lowConsumptions !== undefined)
        filtered = filtered.filter(m => !!m.record.Low_Consumption_Options__c === !!lowConsumptions);

    this.groupMessageOptions = filtered;

        if (!this.groupMessageValue && filtered.length === 1) {
        const sel = filtered[0];
        this.groupMessageValue = sel.value;
        this.noOfPhotos = sel.record?.No_of_Photos__c || 0;
        this.showLPGSupplier = !!sel.record?.LPG_Supplier__c;

        // --- NEW: build photoUploadSlots for OFFLINE flow using No_of_Photos__c
        if (!navigator.onLine) {
            const count = Number(sel.record?.No_of_Photos__c || (sel.listDocumentWrapper?.length || 0));
            // safety: at least 1 slot if business expects photos
            const finalCount = Math.max(0, count);
            this.photoUploadSlots = Array.from({ length: finalCount }).map((_, idx) => ({
                name: `photo_${idx + 1}`,
                label: `${sel.label || 'Photo'} - ${idx + 1}`,
                uploaded: false,
                base64Data: null,
                fileName: null,
                ocr: !!sel.record?.OCR__c
            }));
        } else {
            // online path — preserve current behavior (if you already use sel.listDocumentWrapper)
            this.photoUploadSlots = sel.listDocumentWrapper || [];
        }
    }
}


    geoFenceConfig;
    init() {
        /* === ONLINE === */
        if (navigator.onLine) {
            this.groupMasterOptionsFunc();
            getAccountInfoFromSA({ workOrderId: this.recordId })
                .then(data => {
                    if (data) {
                        this.groupMessageOptionsFunc();
                        this.account = data.acc;
                        this.lpgSupplierOptions = data.lpgSupplierOptions;
                        this.gasBurntMeterStatusOptions = data.mglGasBurntMeterStatusOptions;
                        this.geoFenceConfig = data.geoFenceConfig;
                        if (data.workOrder != null) {
                            this.workOrderRec = data.workOrder;
                            if (data.workOrder.Customer_Category__c != null && data.workOrder.Customer_Category__c == 'Non-MRS Commercial') {
                                this.customerCategory = 'Non-MRS';
                                this.nonMRS = true;
                            } else {
                                this.customerCategory = 'Domestic';
                            }
                            this.getGroupCodeOptionsFunc();
                            if (data.workOrder.Appointment_Status__c == 'Completed') {
                                this.workOrderCompleted = true;
                                this.showPreviewPage = true;
                                this.formFirstPage = false;
                                this.accountView = false;
                                this.groupCodeValue = data.workOrder.Group_Code__c;
                                this.selectedGroupDetailId = data.workOrder.Group_Code__c;
                                this.meterReading = data.workOrder.Meter_Reading__c;
                                this.followUpRemarks = data.workOrder.Follow_Up_Remarks__c;
                                this.additionalComment = data.workOrder.Description;
                                this.finalAttempt = data.workOrder.Final_Attempt__c;
                                this.premiseCorrect = data.workOrder.Premise_Correct__c;
                                this.serialNumberCorrect = data.workOrder.Meter_Serial_Number_Correct__c;
                                this.followUpDate = data.workOrder.Follow_Up_Appointment_Date__c;
                                this.groupMasterValue = data.workOrder.Group_Master__c;
                                this.groupMessageValue = data.workOrder.Group_Message__c;
                                this.remarks = data.workOrder.Remarks__c;
                            }else {
                            // Non-completed → start at Customer Info
                            this.workOrderCompleted = false;
                            this.accountView = true;
                            this.meterReadingPage = false;
                            this.imageUploadPage = false;
                            this.showPreviewPage = false;
                            this.formFirstPage = true;
                        }

                        }
                        this.error = undefined;
                    }
                })
                .catch(error => {
                    this.account = undefined;
                    this.error = error;
                });
        }
        else {
            
        }

       
    }

    @track groupMasterOptions = [];
    @track groupMasterValue;
    groupMasterOptionsFunc() {
        if (navigator.onLine) {
            getGroupMasterOptions()
                .then(result => {
                    this.groupMasterOptions = result;
                    this.groupMasterOptions.forEach(item => {
                        if (item.record && item.record.Default__c) {
                            if (!this.workOrderCompleted)
                                this.groupMasterValue = item.value;
                            this.getGroupCodeOptionsFunc();
                        }
                    });
                }).catch(error => {
                    
                });
        } else {

        }
    }

    handleGroupMasterChange(event) {
        this.groupMasterValue = event.detail.value;
        this.groupCodeValue = '';
        this.showMeterReading = false;
        this.groupMessageValue = '';
        if (this.groupMasterValue) {
            this.getGroupCodeOptionsFunc();
        }
    }

    get isDomestic(){
        return !this.nonMRS;
    }

    showMeterReading = false;
    @track groupCodeOptions = [];
    groupCodeOptionsAll;
    @track groupCodeValue;
    showFollowUp = false;
    getGroupCodeOptionsFunc(defaultValue = true, plausibleOption = false) {
        if (navigator.onLine) {
            getGroupCodeOptions({ groupMasterId: this.groupMasterValue, type: this.customerCategory, plausibleOption: plausibleOption})
                .then(item => {
                    this.groupCodeOptions = item;
                    this.groupCodeOptionsAll = JSON.parse(JSON.stringify(item));
                    this.groupCodeOptions.forEach(item => {
                        if (item.record) {
                            if (item.record.Default__c && defaultValue && !this.workOrderCompleted) {
                                this.groupCodeValue = item.value;
                                this.getGroupMessageOptionsFunc();
                                this.showMeterReading = item.record.Show_Meter_Reading_Option__c
                                this.showFollowUp = !this.showMeterReading;
                                this.photoUploadSlots = item.listDocumentWrapper;
                            }
                        }
                    });

                    if (!this.groupCodeValue && this.groupCodeOptions && this.groupCodeOptions.length == 1) {
                        this.groupCodeValue = this.groupCodeOptions[0].value;
                        this.getGroupMessageOptionsFunc();
                    }

                    this.groupCodeOptions.forEach(item => {
                        if (item.value == this.groupCodeValue && item.record) {
                            this.showMeterReading = item.record.Show_Meter_Reading_Option__c;
                            this.showFollowUp = !this.showMeterReading;
                            this.photoUploadSlots = item.listDocumentWrapper;
                        }
                    });
                })
                .catch(error => {
                });
        } else {
            const selected = (this.groupCodeOptions || []).find(i => i.value === this.groupCodeValue);
            if (selected && selected.record) {
                this.showMeterReading = selected.record.Show_Meter_Reading_Option__c;
                this.showFollowUp = !this.showMeterReading;
            }
        }
    }

    // handleGroupCodeChange(event) {
    //     this.groupCodeValue = event.detail.value;
    //     this.groupMessageValue = '';
    //     if (this.groupCodeValue) {
    //         this.getGroupMessageOptionsFunc();
    //     }

    //     this.groupCodeOptions.forEach(item => {
    //         if (item.value == this.groupCodeValue && item.record) {
    //             this.showMeterReading = item.record.Show_Meter_Reading_Option__c;
    //             this.showFollowUp = !this.showMeterReading;
    //             this.photoUploadSlots = item.listDocumentWrapper;
    //         }
    //     });
    //     /* === OFFLINE */
    //        if (!navigator.onLine) {
    //             const msgs = this._allMsgs?.filter(m => m.parentId === this.groupCodeValue) || [];
    //             if (msgs.length) {
    //                 const msg = msgs[0];
    //                 this.noOfPhotos = Number(msg.record?.No_of_Photos__c || 0);
    //                 this.showLPGSupplier = !!msg.record?.LPG_Supplier__c;
    //             } else {
    //                 this.noOfPhotos = 0;
    //                 this.showLPGSupplier = false;
    //             }
    //         }

    // }

    // Replace your handleGroupCodeChange with this
    handleGroupCodeChange(event) {
        this.groupCodeValue = event.detail.value;
        this.groupMessageValue = '';

        const selected = (this.groupCodeOptions || []).find(i => i.value === this.groupCodeValue);
        if (selected && selected.record) {
            this.showMeterReading = !!selected.record.Show_Meter_Reading_Option__c;
            this.showFollowUp = !this.showMeterReading;

            // Baseline from Document Masters (works online and offline)
            this.photoUploadSlots = Array.isArray(selected.listDocumentWrapper)
                ? [...selected.listDocumentWrapper]
                : [];
        }

        if (this.groupCodeValue) {
            this.getGroupMessageOptionsFunc();
        }

        // Offline: keep metadata for validation only; do NOT rebuild slots
       if (!navigator.onLine) {
            const msgs = this._allMsgs?.filter(m => m.parentId === this.groupCodeValue) || [];
            if (msgs.length) {
                const msg = msgs[0];
                this.noOfPhotos = Number(msg.record?.No_of_Photos__c || 0);
                this.showLPGSupplier = !!msg.record?.LPG_Supplier__c;
            } else {
                this.noOfPhotos = 0;
                this.showLPGSupplier = false;
            }

            // Ensure labeled photo slots are built for offline so UI matches online
            this.setPhotoUploadSlots(this.noOfPhotos || 3);
       }

    }


    get todayDate() {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const year = today.getFullYear();
        const month = String(today.getMonth() + 1).padStart(2, '0');
        const day = String(today.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    @track groupMessageValue;
    @track groupMessageOptions = [];
    getGroupMessageOptionsFunc() {
        this.groupMessageOptionsFunc(this.groupCodeValue);
    }

    groupMessageOptionsFunc(groupCodeValue, plausibleOption = false, highConsumptions = false, lowConsumptions = false) {
        if (navigator.onLine) {
            getGroupMessageOptions({ groupCodeId: groupCodeValue, plausibleOption: plausibleOption, highConsumptions: highConsumptions, lowConsumptions: lowConsumptions,forDomestic:this.isDomestic,forNonMRS:this.nonMRS  })
                .then(result => {
                    this.groupMessageOptions = result;
                    if (result && result.length == 1) {
                        this.groupMessageValue = result[0].value;
                    }
                    this.groupMessageOptions.forEach(item => {
                        if (this.groupMessageValue == item.value && item.record) {
                            this.noOfPhotos = item.record.No_of_Photos__c;
                        }
                    })
                })
                .catch(error => {
                });
        } else {
            // OFFLINE
            const selected = (this.groupMessageOptions || []).find(i => i.value === this.groupMessageValue);
            if (selected && selected.record) {
                this.noOfPhotos = selected.record.No_of_Photos__c || 0;
                this.showLPGSupplier = !!selected.record.LPG_Supplier__c;
            }
        }
    }

    @track showLPGSupplier = false;
    noOfPhotos = 0;
    // handleGroupMessageChange(event) {
    //     this.groupMessageValue = event.detail.value;
    //     this.groupMessageOptions.forEach(item => {
    //         if (this.groupMessageValue == item.value && item.record) {
    //             this.noOfPhotos = item.record.No_of_Photos__c;
    //             this.showLPGSupplier = item.record.LPG_Supplier__c;
    //         }
    //     })
    //     if (!navigator.onLine && !selMsg) {
    //         const cached = this._allMsgs?.find(m => m.value === this.groupMessageValue);
    //         if (cached) {
    //             this.noOfPhotos = Number(cached.record?.No_of_Photos__c || 0);
    //             this.showLPGSupplier = !!cached.record?.LPG_Supplier__c;
    //         }
    //     }
    // }

    // Replace your handleGroupMessageChange with this
    handleGroupMessageChange(event) {
        this.groupMessageValue = event.detail.value;

        // Capture attributes for validation/UI only; DO NOT rebuild slots
        const selMsg = (this.groupMessageOptions || []).find(i => i.value === this.groupMessageValue);
        if (selMsg && selMsg.record) {
            this.noOfPhotos = Number(selMsg.record.No_of_Photos__c || 0);
            this.showLPGSupplier = !!selMsg.record.LPG_Supplier__c;
        } else if (!navigator.onLine) {
            const cached = this._allMsgs?.find(m => m.value === this.groupMessageValue);
            if (cached) {
                this.noOfPhotos = Number(cached.record?.No_of_Photos__c || 0);
                this.showLPGSupplier = !!cached.record?.LPG_Supplier__c;
            }
        }
        // Important: no changes to this.photoUploadSlots here
    }


    lpgSupplierValue;
    handleLpgSupplierChange(event) {
        this.lpgSupplierValue = event.detail.value;
    }

    handleDetailNext() {
              /* === OFFLINE */
            if (!navigator.onLine) {
                // Hydrate flags before moving to next screen
                if (!this.showMeterReading && this.groupCodeValue) {
                    const selectedCode = this._allCodes?.find(c => c.value === this.groupCodeValue);
                    if (selectedCode) {
                        this.showMeterReading = !!selectedCode.record?.Show_Meter_Reading_Option__c;
                        this.showFollowUp = !this.showMeterReading;
                    }
                }
                if (!this.groupMessageValue && this._allMsgs?.length) {
                    const msg = this._allMsgs.find(m => m.parentId === this.groupCodeValue);
                    if (msg) {
                        this.groupMessageValue = msg.value;
                        this.noOfPhotos = msg.record?.No_of_Photos__c || 0;
                        this.showLPGSupplier = !!msg.record?.LPG_Supplier__c;
                    }
                }
                if (!this.photoUploadSlots || this.photoUploadSlots.length === 0) {
                    this.setPhotoUploadSlots(); 
                }
            }

        if ((this.showMeterReading && (this.meterReading == '' || this.meterReading == null))
            || this.groupCodeValue == '' || this.groupCodeValue == null
            || this.groupMessageValue == '' || this.groupMessageValue == null
            || this.groupMasterValue == '' || this.groupMasterValue == null) {

            this.showToastMessage('Error', 'Please fill all required field.', 'error');
            return;
        } else if (this.meterReadingValidation()) {
            if(this.nonMRS)
                this.showToastMessage('Error', 'Please enter correct meter reading upto 7 digit.', 'error');
            else
                this.showToastMessage('Error', 'Please enter correct meter reading.', 'error');
            return;
        }
        if (this.showMeterReading) {
            var plausibilityResult = this.plausibilityCheck(this.workOrderRec?.Previous_Meter_Reading__c, this.meterReading, this.workOrderRec?.Last_Meter_Reading_Date__c, this.workOrderRec?.Average_Consumption__c);
            if (plausibilityResult.valid) {
                this.formFirstPage = false;
                this.imageUploadPage = true;
            } else if (plausibilityResult.message == 'Zero consumption') {
                this.checkForZeroReading = true;
                this.showAlert = true;
                this.formThirdPage = true;
                this.groupCodeValue = null;
                this.showMeterReading = false;
                this.showFollowUp = false;
                this.getGroupCodeOptionsFunc(false, true);
            } else {
                this.showAlert = true;
                this.checkForZeroReading = false;
                if (plausibilityResult.message == 'High consumption') {
                    this.groupMessageOptionsFunc(this.groupCodeValue, true, true, false);
                } else if (plausibilityResult.message == 'Low consumption') {
                    this.groupMessageOptionsFunc(this.groupCodeValue, true, false, true);
                }
                this.formSecondPage = true;
            }
        } else {
            this.formFirstPage = false;
            this.imageUploadPage = true;
        }
         /* === OFFLINE: ensure photo slots for Non-MRS before showing image upload page === */
            if (!navigator.onLine && this.imageUploadPage) {
                const isNonMRS = (this.customerCategory || '').toString().toLowerCase().includes('non');
                // Determine desired minimum slot count: if Non-MRS enforce at least 3, otherwise use noOfPhotos
                const desiredCount = isNonMRS ? Math.max(3, Number(this.noOfPhotos || 0)) : Number(this.noOfPhotos || 0);
                const currentCount = Array.isArray(this.photoUploadSlots) ? this.photoUploadSlots.length : 0;

                if (desiredCount > currentCount) {
                    this.rebuildPhotoUploadSlots(desiredCount);
                }
            }

            /* === OFFLINE final safety: if still empty build fallback slots based on noOfPhotos === */
            if (!navigator.onLine && this.imageUploadPage && (!this.photoUploadSlots || this.photoUploadSlots.length === 0)) {
                this.setPhotoUploadSlots();
            }
    }

    meterReadingValidation(){
        if(this.nonMRS){
            if(this.showMeterReading && this.meterReading != null && this.meterReading != '' && 
                (this.meterReading.length<=0 || this.meterReading.length>7)){
                return true;
            }
        }else{
            if(this.showMeterReading && this.meterReading != null && this.meterReading != '' 
                && this.meterReading.length !=5){
                return true;
            }
        }
        return false;
    }

    handleShowAlert(meterReading) {
        this.formFirstPage = false;
        if (!this.meterReadingValidation()) {
            this.handleCheckZeroReading(meterReading);
        } else {
            this.showAlert = true;
            this.checkForZeroReading = false;
            this.formSecondPage = true;
        }
    }

    checkForZeroReading = false;
    handleCheckZeroReading(meterReading) {
        if (this.account?.Previous_Meter_Reading__c == Number(meterReading)) {
            this.checkForZeroReading = true;
            this.showAlert = true;
            this.formThirdPage = true;
            this.groupCodeValue = null;
            this.showMeterReading = false;
            this.showFollowUp = false;
            this.getGroupCodeOptionsFunc(false);
        } else {
            this.imageUploadPage = true;
            this.showAlert = false;
        }
    }

    handleCaptureMeterBack() {
        this.meterReadingPage = false;
        this.formFirstPage = false;
        this.formSecondPage = false;
        this.imageUploadPage = false;
        this.accountView = true;
        this.checkOut = false;
    }

    showAlert = false;
    handleAlertClose() {
        this.showAlert = false;
    }

    formFirstPage = true;
    formSecondPage = false;
    formThirdPage = false;
    handleAlertOk() {
        if (this.checkForZeroReading) {
            this.formThirdPage = true
        } else {
            this.formSecondPage = true;
        }
        this.checkForZeroReading = false;
        this.formFirstPage = false;
        this.showAlert = false;
        this.meterReading = '';
        this.groupMessageValue = '';
    }

    handleFormSecondPageBack() {
        this.formSecondPage = false;
        this.formFirstPage = true;
    }

    handleFormSecondPageNext() {
        if (!this.serialNumberVisible || !this.premiseCorrect || this.meterReading == '' || this.meterReading == null
            || this.groupMessageValue == '' || this.groupMessageValue == null) {
            this.showToastMessage('Error', 'Please fill all required field.', 'error');
            return;
        } else if (this.showLPGSupplier && (this.lpgSupplierValue == '' || this.lpgSupplierValue == null)) {
            this.showToastMessage('Error', 'Please select LPG Supplier.', 'error');
            return;
        } else if (this.meterReadingValidation()) {
            if(this.nonMRS)
                this.showToastMessage('Error', 'Please enter correct meter reading upto 7 digit.', 'error');
            else
                this.showToastMessage('Error', 'Please enter correct meter reading.', 'error');
            return;
        }
        this.formSecondPage = false;
        this.imageUploadPage = true;
    }

    handleFormThirdPageNext() {
        if (this.mglGasBurningPossible == '' || this.mglGasBurningPossible == null
            || this.mglGasBurntMeterStatus == '' || this.mglGasBurntMeterStatus == null
            || this.groupCodeValue == '' || this.groupCodeValue == null
            || this.groupMessageValue == '' || this.groupMessageValue == null) {
            this.showToastMessage('Error', 'Please fill all required field....', 'error');
            return;
        }
        this.formThirdPage = false;
        this.imageUploadPage = true;
    }

    get yesNoOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ];
    }

    get yesNoOptionsDisplay() {
        return [
            { label: 'Yes', value: true },
            { label: 'No', value: false },
        ];
    }

    showMeterSerialNumberCorrect = false;
    showMoreDetails = false;
    serialNumberVisible = false;
    serialNumberCorrect = false;
    premiseCorrect = false;
    mglGasBurningPossible = false;
    mglGasBurntMeterStatus;
    conditionRemark = '';
    gasBurntMeterStatusOptions = [];
    amrDeviceInstalled = false;
    isSealInstalled = false;
    isAmrInstalled = false;
    sealNumberVisible = false;

    // handleFieldChange(event) {
    //     var name = event.target.name;
    //     var value = event.target.value;
    //     if (name == 'meterSerialNoVisible') {
    //         this.serialNumberVisible = value == 'Yes' ? true : false;
    //         this.showMeterSerialNumberCorrect = !!this.serialNumberVisible;
    //     } else if (name == 'premiseCorrect') {
    //         this.premiseCorrect = value == 'Yes' ? true : false;
    //         this.showMoreDetails = !!this.premiseCorrect;
    //     } else if (name == 'serialNumberCorrect') {
    //         this.serialNumberCorrect = value == 'Yes' ? true : false;
    //     } else if (name == 'mglGasBurningPossible') {
    //         this.mglGasBurningPossible = value == 'Yes' ? true : false;
    //         if (!this.mglGasBurningPossible) {
    //             this.conditionRemark = 'PNG not being used. Meter testing not possible.';
    //             this.groupCodeOptions = this.groupCodeOptionsAll?.filter(item => {
    //                 if (item.record?.Testing_Not_possible__c) {
    //                     if (item.record.Testing_Possible_Default__c) {
    //                         this.groupCodeValue = item.value;
    //                     }
    //                     return item;
    //                 }
    //             }) || [];
    //         }
    //         this.getGroupMessageOptionsFunc();
    //     } else if (name == 'mglGasBurntMeterStatus') {
    //         this.mglGasBurntMeterStatus = value;
    //         if (this.mglGasBurningPossible && this.mglGasBurntMeterStatus == 'Meter working') {
    //             this.conditionRemark = 'PNG not being used. PNG burnt, meter found working.'
    //             this.groupCodeOptions = this.groupCodeOptionsAll?.filter(item => {
    //                 if (item.record?.Meter_working__c) {
    //                     this.groupCodeValue = item.value;
    //                     return item;
    //                 }
    //             }) || [];
    //         } else if (this.mglGasBurningPossible && this.mglGasBurntMeterStatus == 'Meter not working') {
    //             this.conditionRemark = 'PNG burnt. Meter not running. Replace meter';
    //             this.groupCodeOptions = this.groupCodeOptionsAll?.filter(item => {
    //                 if (item.record?.Meter_not_working__c) {
    //                     this.groupCodeValue = item.value;
    //                     return item;
    //                 }
    //             }) || [];
    //         }
    //         this.getGroupMessageOptionsFunc();
    //     } else if (name == 'amrDeviceInstalled') {
    //         this.amrDeviceInstalled = value == 'Yes' ? true : false;
    //         if (this.amrDeviceInstalled) {
    //             this.photoUploadSlots.push({
    //                 id: Math.random,
    //                 index: 5,
    //                 label: `AMR Device Reading`,
    //                 name: `fileUploader05`,
    //                 fileName: '',
    //                 uploaded: false,
    //                 previewUrl: '',
    //                 ocr: false
    //             })
    //         } else {
    //             this.photoUploadSlots = this.photoUploadSlots.filter(item => item.index != 5);
    //         }
    //     } else if (name == 'isSealInstalled') {
    //         this.isSealInstalled = value == 'Yes' ? true : false;
    //     } else if(name == 'sealNumberVisible'){
    //         this.sealNumberVisible = value == 'Yes' ? true:false;
    //         if (this.sealNumberVisible) {
    //             this.photoUploadSlots.push({
    //                 id: Math.random,
    //                 index: 4,
    //                 label: `Meter Seal Number`,
    //                 name: `fileUploader04`,
    //                 fileName: '',
    //                 uploaded: false,
    //                 previewUrl: '',
    //                 ocr: false
    //             })
    //         } else {
    //             this.photoUploadSlots = this.photoUploadSlots.filter(item => item.index != 4);
    //         }
    //     } else if (name == 'amrInstalled') {
    //         this.isAmrInstalled = value == 'Yes' ? true : false;
    //     }
    // }

handleFieldChange(event) {
    const name = event.target.name;
    const value = event.target.value;

    // Helpers for dynamic slot operations
    const nextSlotIndex = () => {
        const idxs = (this.photoUploadSlots || []).map(s => Number(s.index) || 0);
        return (idxs.length ? Math.max(...idxs) : 0) + 1;
    };
    const addExtraSlot = (kind, label) => {
        if ((this.photoUploadSlots || []).some(s => s.kind === kind)) return;
        const next = nextSlotIndex();
        const id = `dyn_${kind}_${Date.now()}_${next}`;
        this.photoUploadSlots = [
            ...(this.photoUploadSlots || []),
            {
                id,
                index: next,
                label,
                name: `fileUploader_${String(next).padStart(2, '0')}`,
                fileName: '',
                uploaded: false,
                previewUrl: '',
                ocr: false,
                compress: false,
                kind // 'SEAL' | 'AMR'
            }
        ];
    };
    const removeExtraSlot = (kind) => {
        this.photoUploadSlots = (this.photoUploadSlots || []).filter(s => s.kind !== kind);
    };

    // ---------------- Core Field Logic ---------------- //

    if (name === 'meterSerialNoVisible') {
        this.serialNumberVisible = value === 'Yes';
        this.showMeterSerialNumberCorrect = !!this.serialNumberVisible;
        return;
    }

    if (name === 'premiseCorrect') {
        this.premiseCorrect = value === 'Yes';
        this.showMoreDetails = !!this.premiseCorrect;
        return;
    }

    if (name === 'serialNumberCorrect') {
        this.serialNumberCorrect = value === 'Yes';
        return;
    }

    if (name === 'mglGasBurningPossible') {
        this.mglGasBurningPossible = value === 'Yes';
        this.mglGasBurntMeterStatus='';
        if (!this.mglGasBurningPossible) {
            this.conditionRemark = 'PNG not being used. Meter testing not possible.';
            this.mglGasBurntMeterStatus='Testing Not Possible';
            this.groupCodeOptions = this.groupCodeOptionsAll?.filter(item => {
                if (item.record?.Testing_Not_possible__c) {
                    if (item.record.Testing_Possible_Default__c) {
                        this.groupCodeValue = item.value;
                    }
                    return item;
                }
                return false;
            }) || [];
        }
        this.getGroupMessageOptionsFunc();
        return;
    }

    if (name === 'mglGasBurntMeterStatus') {
        this.mglGasBurntMeterStatus = value;
        if (this.mglGasBurningPossible && this.mglGasBurntMeterStatus === 'Meter working') {
            this.conditionRemark = 'PNG not being used. PNG burnt, meter found working.';
            this.groupCodeOptions = this.groupCodeOptionsAll?.filter(item => {
                if (item.record?.Meter_working__c) {
                    this.groupCodeValue = item.value;
                    return item;
                }
                return false;
            }) || [];
        } else if (this.mglGasBurningPossible && this.mglGasBurntMeterStatus === 'Meter not working') {
            this.conditionRemark = 'PNG burnt. Meter not running. Replace meter';
            this.groupCodeOptions = this.groupCodeOptionsAll?.filter(item => {
                if (item.record?.Meter_not_working__c) {
                    this.groupCodeValue = item.value;
                    return item;
                }
                return false;
            }) || [];
        }
        this.getGroupMessageOptionsFunc();
        return;
    }

    // ---------------- SEAL Logic ---------------- //
    if (name === 'isSealInstalled') {
        this.isSealInstalled = value === 'Yes';
        if (!this.isSealInstalled) {
            this.sealNumberVisible = false;
            removeExtraSlot('SEAL');
        } else {
            addExtraSlot('SEAL', 'Meter Seal Number');
        }
    }

    if (name === 'sealNumberVisible') {
        this.sealNumberVisible = value === 'Yes';
        if (this.sealNumberVisible) {
            addExtraSlot('SEAL', 'Meter Seal Number');
        } else {
            removeExtraSlot('SEAL');
        }
    }

    // ---------------- AMR Logic ---------------- //
    if (name === 'amrInstalled') {
        this.isAmrInstalled = value === 'Yes';
        if (!this.isAmrInstalled) {
            this.amrDeviceInstalled = false;
            removeExtraSlot('AMR');
        } else {
            addExtraSlot('AMR', 'AMR Device Reading');
        }
    }

    if (name === 'amrDeviceInstalled') {
        this.amrDeviceInstalled = value === 'Yes';
        if (this.amrDeviceInstalled) {
            addExtraSlot('AMR', 'AMR Device Reading');
        } else {
            removeExtraSlot('AMR');
        }
    }

    // ---------------- NEW FIX for both YES case ---------------- //
    if (this.isSealInstalled && this.isAmrInstalled) {
        const hasSeal = (this.photoUploadSlots || []).some(s => s.kind === 'SEAL');
        const hasAmr = (this.photoUploadSlots || []).some(s => s.kind === 'AMR');
        if (!hasSeal || !hasAmr || (this.photoUploadSlots?.length || 0) < 5) {
            console.log('[FIX] Both Seal & AMR are YES → ensuring 5 slots');
            this.rebuildPhotoUploadSlots(3); // base 3 + both extras
        }
    }
}



    get isSealInstalledDisplay() {
        return this.isSealInstalled ? 'Yes' : 'No';
    }

    get sealNumberVisibleDisplay() {
        return this.sealNumberVisible ? 'Yes' : 'No';
    }

    meterReading;
    remarks;
    followUpDate;
    followUpRemarks;
    amrReading;
    sealReading;
    handleChange(event) {
        var value = event.detail.value;
        var fieldName = event.currentTarget.dataset.fieldName;
        if (fieldName == 'meterReading') {
            this.meterReading = value;
        } else if (fieldName == 'remarks') {
            this.remarks = value;
        } else if (fieldName == 'followUpDate') {
            this.followUpDate = value;
        } else if (fieldName == 'followUpRemarks') {
            this.followUpRemarks = value;
        } else if (fieldName == 'amrReading') {
            this.amrReading = value;
        }
        else if (fieldName == 'sealReading') {
            this.sealReading = value;
        }
    }



    setPhotoUploadSlots(desiredCount = null) {
    try {
        this.isSealInstalled = this.isSealInstalled === true || this.isSealInstalled === 'Yes';
        this.sealNumberVisible = this.sealNumberVisible === true || this.sealNumberVisible === 'Yes';
        this.isAmrInstalled = this.isAmrInstalled === true || this.isAmrInstalled === 'Yes';
        this.amrDeviceInstalled = this.amrDeviceInstalled === true || this.amrDeviceInstalled === 'Yes';

        const existingExtras = (this.photoUploadSlots || []).filter(
            s => s.kind === 'SEAL' || s.kind === 'AMR'
        );

        const count = Math.max(1, Number(desiredCount ?? this.noOfPhotos ?? 3));
        console.log('[setPhotoUploadSlots] building slots, count =', count);

        const selectedCode = (this._allCodes || []).find(c => c.value === this.groupCodeValue);
        let docs = Array.isArray(selectedCode?.listDocumentWrapper)
            ? selectedCode.listDocumentWrapper
            : [];

        // fallback if no docs found
        if ((!docs || docs.length === 0) && this.groupCodeValue) {
            const anyWithDocs = (this._allCodes || []).find(
                c =>
                    c.parentId === selectedCode?.parentId &&
                    Array.isArray(c.listDocumentWrapper) &&
                    c.listDocumentWrapper.length > 0
            );
            if (anyWithDocs) {
                docs = anyWithDocs.listDocumentWrapper || [];
                console.log('[setPhotoUploadSlots] fallback to sibling docs:', anyWithDocs.value);
            }
        }

        const DEFAULT_LABELS = ['Meter Photo', 'Meter Photo with Seal', 'Overall Installation'];
        let slots = [];

        // --- Case 1: Use Document_Master__c labels if available ---
        if (docs && docs.length > 0) {
            for (let i = 0; i < count; i++) {
                const doc = docs[i] || {};
                const slotNum = i + 1;
                slots.push({
                    id: doc.id || `offline_doc_${slotNum}_${Date.now()}`,
                    index: slotNum,
                    label: doc.label || DEFAULT_LABELS[i] || `Photo ${slotNum}`,
                    name: `fileUploader${String(slotNum).padStart(2, '0')}`,
                    fileName: '',
                    uploaded: false,
                    previewUrl: '',
                    base64Data: null,
                    ocr: !!doc.ocr,
                    compress: !!doc.compress,
                    kind: doc.kind || null
                });
            }
            console.log('[setPhotoUploadSlots] used docs for labels');
        } else {
            // --- Case 2: fallback ---
            const msg =
                (this._allMsgs || []).find(m => m.value === this.groupMessageValue) ||
                (this._allMsgs || []).find(m => m.parentId === this.groupCodeValue);
            const base = msg?.label || 'Meter';
            const labels = [
                `${base} Photo`,
                `${base} with Seal`,
                `Overall ${base}`
            ];
            slots = Array.from({ length: count }, (_, idx) => ({
                id: `fallback_slot_${idx + 1}_${Date.now()}`,
                index: idx + 1,
                label: labels[idx] || DEFAULT_LABELS[idx] || `Photo ${idx + 1}`,
                name: `fileUploader${String(idx + 1).padStart(2, '0')}`,
                fileName: '',
                uploaded: false,
                previewUrl: '',
                base64Data: null,
                ocr: idx === 0,
                compress: false
            }));
            console.log('[setPhotoUploadSlots] used fallback labels');
        }

        /* ============================================================
           ✅ FIXED LOGIC → Auto-add SEAL / AMR slots (initial & rebuild)
           ============================================================ */
        const needSeal = this.isSealInstalled || this.sealNumberVisible;
        const needAmr = this.isAmrInstalled || this.amrDeviceInstalled;

        // --- Add Seal slot if required ---
        if (needSeal && !slots.some(s => s.kind === 'SEAL')) {
            const sealIndex = slots.length + 1;
            slots.push({
                id: `init_SEAL_${Date.now()}`,
                index: sealIndex,
                label: 'Meter Seal Number',
                name: `fileUploader${String(sealIndex).padStart(2, '0')}`,
                fileName: '',
                uploaded: false,
                previewUrl: '',
                base64Data: null,
                ocr: false,
                compress: false,
                kind: 'SEAL'
            });
            console.log('[setPhotoUploadSlots] auto-added SEAL slot');
        }

        // --- Add AMR slot if required ---
        if (needAmr && !slots.some(s => s.kind === 'AMR')) {
            const amrIndex = slots.length + 1;
            slots.push({
                id: `init_AMR_${Date.now()}`,
                index: amrIndex,
                label: 'AMR Device Reading',
                name: `fileUploader${String(amrIndex).padStart(2, '0')}`,
                fileName: '',
                uploaded: false,
                previewUrl: '',
                base64Data: null,
                ocr: false,
                compress: false,
                kind: 'AMR'
            });
            console.log('[setPhotoUploadSlots] auto-added AMR slot');
        }

        /* ============================================================
           Preserve SEAL/AMR slots across rebuilds
           ============================================================ */
        if (existingExtras.length > 0) {
            const merged = [
                ...slots,
                ...existingExtras.filter(e => !slots.some(s => s.kind === e.kind))
            ];
            this.photoUploadSlots = merged;
            console.log('[setPhotoUploadSlots] preserved extras:', existingExtras.map(e => e.kind));
        } else {
            this.photoUploadSlots = slots;
        }

        console.log('[setPhotoUploadSlots] final slots:', this.photoUploadSlots.length);
    } catch (error) {
        console.error('[setPhotoUploadSlots] error:', error);
    }
}







    rebuildPhotoUploadSlots(desiredCount = 1) {
        // Preserve dynamic SEAL/AMR slots
        const existingExtras = (this.photoUploadSlots || []).filter(
            s => s.kind === 'SEAL' || s.kind === 'AMR'
        );

        const count = Math.max(1, Number(desiredCount || 1));
        const selectedCode = (this._allCodes || []).find(c => c.value === this.groupCodeValue);
        const docs = Array.isArray(selectedCode?.listDocumentWrapper)
            ? selectedCode.listDocumentWrapper
            : [];

        const DEFAULT_LABELS = ['Meter Photo', 'Meter Photo with Seal', 'Overall Installation'];
        let slots = [];

        if (docs && docs.length > 0) {
            for (let i = 0; i < count; i++) {
                const doc = docs[i] || {};
                const slotNum = i + 1;
                const label =
                    doc.label && doc.label.length <= 40
                        ? doc.label
                        : DEFAULT_LABELS[i] || `Photo ${slotNum}`;
                slots.push({
                    id: doc.id || `rebuild_doc_${slotNum}_${Date.now()}`,
                    index: slotNum,
                    label,
                    name: `fileUploader${String(slotNum).padStart(2, '0')}`,
                    fileName: '',
                    uploaded: false,
                    previewUrl: '',
                    base64Data: null,
                    ocr: !!doc.ocr,
                    compress: !!doc.compress
                });
            }
        } else {
            const msg =
                (this._allMsgs || []).find(m => m.value === this.groupMessageValue) ||
                (this._allMsgs || []).find(m => m.parentId === this.groupCodeValue);
            const base = msg?.label || 'Meter';
            slots = Array.from({ length: count }, (_, idx) => ({
                id: `rebuild_fallback_${idx + 1}_${Date.now()}`,
                index: idx + 1,
                label: DEFAULT_LABELS[idx] || `${base} Photo ${idx + 1}`,
                name: `fileUploader${String(idx + 1).padStart(2, '0')}`,
                fileName: '',
                uploaded: false,
                previewUrl: '',
                base64Data: null,
                ocr: idx === 0,
                compress: false
            }));
        }

        // ✅ Merge back Seal & AMR slots if not already present
        if (existingExtras.length > 0) {
            const merged = [
                ...slots,
                ...existingExtras.filter(e => !slots.some(s => s.kind === e.kind))
            ];
            this.photoUploadSlots = merged;
            console.log('[rebuildPhotoUploadSlots] preserved extras:', existingExtras.map(e => e.kind));
        } else {
            this.photoUploadSlots = slots;
        }
    }


    _nextSlotIndex() {
        const idxs = (this.photoUploadSlots || []).map(s => Number(s.index) || 0);
        return (idxs.length ? Math.max(...idxs) : 0) + 1;
    }
    _addExtraSlot(kind, label) {
        if ((this.photoUploadSlots || []).some(s => s.kind === kind)) return;
        const next = this._nextSlotIndex();
        const id = `dyn_${kind}_${Date.now()}_${next}`;
        this.photoUploadSlots = [
            ...(this.photoUploadSlots || []),
            {
                id,
                index: next,
                label,
                name: `fileUploader_${next}`,
                fileName: '',
                uploaded: false,
                previewUrl: '',
                ocr: false,
                compress: false,
                kind // 'SEAL' | 'AMR'
            }
        ];
    }
    _removeExtraSlot(kind) {
        this.photoUploadSlots = (this.photoUploadSlots || []).filter(s => s.kind !== kind);
    }


    async handleFile(event) {
        this.photoUploadSlots = event.detail.steps;

        for (let i = 0; i < this.photoUploadSlots.length; i++) {
            var slot = this.photoUploadSlots[i];
            if (!slot.added) continue;

            if (slot.base64Data && slot.compress) {
                try {
                    const fullBase64 = slot.base64Data.startsWith('data:image')
                        ? slot.base64Data
                        : `data:image/jpeg;base64,${slot.base64Data}`;
                    const blob = await this.base64ToBlob(fullBase64);
                    const imageUrl = URL.createObjectURL(blob);
                    const compressedBlob = await this.compressImageFromURL(imageUrl);
                    const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
                    slot.base64Data = compressedBase64;
                } catch (error) {
                    if (!slot.base64Data || slot.base64Data.length < 100) {
                        // swallow compression error but keep base64 if present
                    }
                }
            }
        }
    }

    async base64ToBlob(base64Data) {
        const byteString = atob(base64Data.split(',')[1]);
        const mimeString = base64Data.split(',')[0].split(':')[1].split(';')[0];
        const ab = new ArrayBuffer(byteString.length);
        const ia = new Uint8Array(ab);
        for (let i = 0; i < byteString.length; i++) {
            ia[i] = byteString.charCodeAt(i);
        }
        return new Blob([ab], { type: mimeString });
    }

    async compressImageFromURL(imageUrl) {
        return new Promise((resolve, reject) => {
            const img = new Image();
            img.onload = () => {
                try {
                    const canvas = document.createElement('canvas');
                    const ctx = canvas.getContext('2d');
                    const maxWidth = 2400;
                    const maxHeight = 2400;
                    let width = img.width;
                    let height = img.height;

                    const ratio = Math.min(maxWidth / width, maxHeight / height);
                    width *= ratio;
                    height *= ratio;

                    canvas.width = width;
                    canvas.height = height;
                    ctx.drawImage(img, 0, 0, width, height);

                    try {
                        canvas.toBlob(
                            (blob) => {
                                if (blob) resolve(blob);
                                else reject(new Error('Canvas compression failed. Blob was null.'));
                            },
                            'image/jpeg',
                            0.91
                        );
                    } catch (err) {
                        reject(new Error('Exception during canvas.toBlob: ' + err.message));
                    }
                } catch (error) {
                    reject(new Error('Error during image compression: ' + error.message));
                }
            };
            img.onerror = () => reject(new Error('Error loading image.'));
            img.crossOrigin = 'anonymous';
            img.src = imageUrl;
        });
    }

    async convertBlobToBase64(blob) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result.split(',')[1]);
            reader.onerror = reject;
            reader.readAsDataURL(blob);
        });
    }

    handleImageBack() {
        this.imageUploadPage = false;
        this.formSecondPage = true;
    }

    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
    }

    selectedGroupDetailId;
    handleGroupDetailChange(event) {
        this.selectedGroupDetailId = event.detail.value;
        const selectedOption = this.lookupOptions.find((option) => option.value === this.selectedGroupDetailId);

        if (selectedOption) {
            this.selectedGroupDetailLabel = selectedOption.label;
            this.noOfPhotosRequired = selectedOption ? selectedOption.noOfPhotosRequired : null;
        }

        if (selectedOption && selectedOption.label === 'Meter reading possible') {
            this.showMeterReadingPossible = true;
        } else if (selectedOption && selectedOption.label === 'Others') {
            this.showAdditionalComment = true;
        } else {
            this.showMeterReadingPossible = false;
            this.showAdditionalComment = false;
        }
        this.handleGetGroupMessage();
        this.imageUploadPage = true;
    }

    selectedGroupMessageId;

    handleInputChange(event) {
        const field = event.target.name;
        if (field === 'currentMeterReading') {
            this.currentMeterReading = event.target.value;
        } else if (field === 'followUpRemarks') {
            this.followUpRemarks = event.target.value;
        } else if (field === 'additionalComment') {
            this.additionalComment = event.target.value;
        } else if (field === 'finalAttempt') {
            this.finalAttempt = event.target.checked;
        }
    }

    finalAttemptData = false;
    handleCheckBoxChange(event) {
        const { name } = event.target;
        var value = event.target.value;
        if (name === 'premiseCorrect') {
            this.premiseCorrect = value == 'Yes' ? true : false;
        } else if (name === 'meterSerialCorrect') {
            this.meterSerialCorrect = value == 'Yes' ? true : false;
        } else if (name === 'meterSerialVisible') {
            this.meterSerialVisible = value == 'Yes' ? true : false;
        } else if (name === 'serialNumberCorrect') {
            this.serialNumberCorrect = value == 'Yes' ? true : false;
        } else if (name === 'finalAttempt') {
            this.finalAttempt = value == 'Yes' ? true : false;
            this.finalAttemptData = !this.finalAttempt;
        }
    }

    filteredGroupMessagesOptions = [];
    handleGetGroupMessage() {
        // searchGroupMessage({ groupDetailId: this.selectedGroupDetailId })...
    }

    fetchGroupData() {
        if (navigator.onLine) {
            getGroupDataForTodayAppointments({ workOrderId: this._recordId })
                .then((data) => {
                    const appointments = data.appointments || [];
                    if (appointments.length > 0) {
                        this.serviceAppointmentId = appointments[0].Id;
                    } else {
                        this.serviceAppointmentId = null;
                    }
                    this.error = null;
                })
                .catch((error) => {
                    this.error = error;
                });
        } else {
           this._resolveServiceAppointmentOffline();
        }
    }
    

        async _resolveServiceAppointmentOffline() {
        try {
            const resp = await graphql({ query: SA_BY_WO_QUERY, variables: { woId: this._recordId } });
            const saId = resp?.data?.uiapi?.query?.ServiceAppointment?.edges?.[0]?.node?.Id || null;
             //this.showToastMessage('Info', 'Service Appointment '+JSON.stringify(saId), 'info');
            if (saId) {
            this.serviceAppointmentId = saId;
            return saId;
            }
        } catch (e) {
            const msg = (e?.errors && e.errors[0]?.message) || e?.message || 'SA lookup via GraphQL failed';
            //this.showToastMessage('Info', msg, 'info');
        }
        if (this.workOrderRec?.Service_Appointment__c) {
            this.serviceAppointmentId = this.workOrderRec.Service_Appointment__c;
            return this.serviceAppointmentId;
        }
        return null;
        }



    filterGroupMessages() {
        if (this.selectedGroupDetailId) {
            this.filteredGroupMessages = this.groupMessages.filter(msg => msg.Group_Details__c === this.selectedGroupDetailId);
        } else {
            this.filteredGroupMessages = [];
        }
    }

    workOrderCompleted = false;
    customerCategory;
    nonMRS = false;

    handleTakeReading() {
        this.meterReadingPage = true;
        this.formFirstPage = true;
        this.formSecondPage = false;
        this.imageUploadPage = false;
        this.accountView = false;
    }

    uploadedFilesBySlot = {};
    handleUploadFinished(event) {
        const slotName = event.target.name;
        const uploadedFiles = event.detail.files;
        if (!this.uploadedFilesBySlot[slotName]) {
            this.uploadedFilesBySlot[slotName] = [];
        }
        uploadedFiles.forEach(file => {
            this.uploadedFilesBySlot[slotName].push({
                documentId: file.documentId,
                name: file.name
            });
        });
        this.updateSlotImagePreviews();
    }

    updateSlotImagePreviews() {
        this.photoUploadSlots = this.photoUploadSlots.map(slot => {
            const images = this.uploadedFilesBySlot[slot.name] || [];
            return {
                ...slot,
                imagePreviews: images.map(file => ({
                    url: `/sfc/servlet.shepherd/document/download/${file.documentId}`,
                    name: file.name
                }))
            };
        });
    }

    handleBack() {
        this.showPreviewPage = false;
        this.imageUploadPage = true;
        this.meterReadingPage = true;
    }

    handlePreview() {
        var image = 0;
        this.photoUploadSlots.forEach(item => {
            if (item.uploaded) image++;
        });
        if (image != this.photoUploadSlots.length) {
            this.showToastMessage('Error', 'Please upload all the photos', 'error');
            return;
        }
        this.showPreviewPage = true;
        this.imageUploadPage = false;
        this.meterReadingPage = false;
    }

    _generateDocumentKey(wo) {
        const parts = [
            wo?.Meter_Reading_Doc_Number__c || 'MR',
            wo?.BP_Number__c || 'BP',
            wo?.Scheduled_Date__c || (new Date().toISOString().slice(0,10)),
            wo?.WorkOrderNumber || wo?.Id || 'WO'
        ];
        return parts.join('_');
    }

    _normalize(str) {
        return (str || '').toString().trim().toLowerCase();
    }

    

    //final save method
    load = false;
    async handleFinalSave() {
        this.load = true;
        
        var currentMeterReading = this.meterReading ? Number(this.meterReading) : null;

        if (navigator.onLine) {
            updateServiceAppointment({
                serviceAppointmentId: this.serviceAppointmentId,
                workOrderId: this.workOrderId,
                groupCodeId: this.groupCodeValue,
                groupMasterId: this.groupMasterValue,
                groupMsgId: this.groupMessageValue,
                currentMeterReading: currentMeterReading,
                followUpRemarks: this.followUpRemarks,
                additionalComment: this.remarks,
                finalAttempt: this.finalAttempt,
                premiseCorrect: this.premiseCorrect,
                meterSerialCorrect: this.serialNumberCorrect,
                meterSerialVisible: this.meterSerialVisible,
                followUpDate: this.followUpDate,
                followUpRemarks: this.followUpRemarks,
                latitude: this.lat,
                longitude: this.long,
                mglGasBurningPossible: this.mglGasBurningPossible,
                mglGasBurntMeterStatus: this.mglGasBurntMeterStatus,
                defaultGroupCode: this.showMeterReading,
                amrReading: this.amrReading,
                sealReading: this.sealReading,
                isSealInstalled: this.isSealInstalled,
                AMRDeviceInstalled: this.isAmrInstalled,
                sealNumberVisible: this.sealNumberVisible,
                amrReadingVisible: this.amrDeviceInstalled,
                lpgSupplierValue:this.lpgSupplierValue
            })
            .then(() => {
                var imagesList = [];
                this.photoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label,
                        ocr: item.ocr
                    })
                     console.log('Image label--->',item.label);
                     console.log('Image ocr--->',item.ocr);
                });
               
                console.log('Image List--->',imagesList);

                saveImage({ listFiles: imagesList, serviceAppointmentId: this.serviceAppointmentId, defaultGroupCode: this.showMeterReading, workOrderId: this._recordId, accRec: this.account })
                    .then(result => {
                        this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Images and data saved successfully!', variant: 'success' }));
                        this.meterReadingPage = false;
                        this.imageUploadPage = false;
                        this.accountView = false;
                        if (this.recordId) {
                            this.showOkModal = true;
                        }
                        this.load = false;
                    })
                    .catch(error => {
                        this.load = false;
                        this.showToastMessage('Error', 'Error saving photos', 'error');
                    });
            })
            .catch(error => {
                this.load = false;
                this.error = error;
            });

            return;
        }

        /* === OFFLINE: LDS queued updates*/
        try {
            this.load = true;
            this.isOfflineSaving = true;
            // Guard: must have a hydrated WO record from LDS
            const wo = this.workOrderRec || {};
            const saId = this.serviceAppointmentId || null;

            const isComplete = !this.showFollowUp; // if meter reading flow, treat as Completed; non-reading flows can be Cannot Complete when business rule applies
            const saFields = saId ? { Id: saId, Status: isComplete ? 'Completed' : 'Cannot Complete' } : null;
            const targetStatus = isComplete ? 'Completed' : 'Cannot Complete';

            // 2) Ensure SA Id, then set status
                if (!this.serviceAppointmentId) {
                    await this._resolveServiceAppointmentOffline();
                }
                // if (this.serviceAppointmentId) {
                //     await updateRecord({
                //         fields: { Id: this.serviceAppointmentId, Status: isComplete ? 'Completed' : 'Cannot Complete' }
                //     });
                // } else {
                // this.showToastMessage('Info', 'Service Appointment not cached; SA status will sync when available.', 'info');
                // }

            // Build WorkOrder fields mirroring Apex updateServiceAppointment writes
            const woFields = {
            Id: this._recordId,
             Group_Master__c: this.groupMasterValue,
                Group_Code__c: this.groupCodeValue,
                Group_Message__c: this.groupMessageValue,
                Remarks__c: this.remarks,
                Final_Attempt__c: this.finalAttempt,
                Meter_Reading__c: currentMeterReading,
                AMR_Reading__c: this.amrReading ? Number(this.amrReading) : null,
                Seal_Reading__c: this.sealReading ? Number(this.sealReading) : null,
                Meter_Serial_Number_Visible__c: this.meterSerialVisible,
                Meter_Serial_Number_Correct__c: this.serialNumberCorrect,
                Premise_Correct__c: this.premiseCorrect,
                Check_Out_Location__Latitude__s: this.lat,
                Check_Out_Location__Longitude__s: this.long,
                Check_Out_Date_Time__c: new Date().toISOString(),
                Check_Out__c: true,
                Follow_Up_Appointment_Date__c: this.followUpDate ? new Date(this.followUpDate).toISOString() : null,
                Follow_up_Remarks__c: this.followUpRemarks,
                //Gas_Burning_Possible__c: this.mglGasBurningPossible,
                MGL_gas_burnt_Meter_status__c: this.mglGasBurntMeterStatus,
                AMR_Device_Installed__c: this.isAmrInstalled,
                Is_Seal_Installed__c: this.isSealInstalled,
                Seal_Number_Visible__c: this.sealNumberVisible,
                Is_AMR_Reading_Visible__c: this.amrDeviceInstalled,
                LPG_Supplier__c: this.lpgSupplierValue,
                Appointment_Status__c: (this.finalAttempt || this.showMeterReading) ? 'Completed' : 'Incomplete',
                Approval_Status__c: (this.finalAttempt || this.showMeterReading) ? 'Submitted For Approval' : 'Pending',
                [WO_OFFLINE_TARGET_SA_STATUS.fieldApiName]: targetStatus
            }; 

            // 2a) Queue WorkStep completion first to avoid race on UI state
            await this.completeWorkStepWithGraphQL('Start Metering');

            // 2b) Queue SA status if available
            // if (saFields) {
            //     await updateRecord({ fields: saFields });
            // }

        //    if (saId) {
        //         const fields = {};
        //         fields[SA_ID_FIELD.fieldApiName] = saId;
        //         fields[SA_TARGET_STATUS.fieldApiName] = targetStatus;

        //         await updateRecord({ fields });
        //     }

            // 2c) Queue WO update
            await updateRecord({ fields: woFields });

            // 2d) Stage images and side-objects to mirror saveImage
            await this._stageImagesOffline(wo, saId);

            await this.successMessage();

            

            // ~1.8 s is safe for toast to appear
        } catch (e) {
            this.showToastMessage('Error', e?.body?.message || e?.message || 'Offline final save failed', 'error');
        } finally {
            this.load = false;
        }

    }

    async successMessage(){
        this.load = false;
        // this.dispatchEvent(new ShowToastEvent({
        //     title: 'Saved',
        //     message: 'Updates queued for sync.',
        //     variant: 'success'
        //     }));
            this.showToastMessage('Saved', 'Updates queued for sync.', 'success');
                 await new Promise(res => setTimeout(res, 1000));
                this.showOkModal = true;
                this.showPreviewPage = false;
                this.imageUploadPage = false;
                this.meterReadingPage = false;
   
    }
    

    // 3) WorkStep completion via GraphQL + LDS update 
    async _completeWorkStepOffline(stepName = 'Start Metering') {
    try {
        const QUERY = gql`
        query WS($woId: ID!, $name: String!) {
            uiapi { query {
            WorkStep(where: { ParentRecordId: { eq: $woId }, Name: { eq: $name } }, first: 1) {
                edges { node { Id } }
            }
            } }
        }`;
        const resp = await graphql({ query: QUERY, variables: { woId: this._recordId, name: stepName } });
        const wsId = resp?.data?.uiapi?.query?.WorkStep?.edges?.[0]?.node?.Id;
        if (wsId) {
        await updateRecord({ fields: { Id: wsId, Status: 'Completed' } });
        }
    } catch (_) {  }
    }


    // 4) Offline check-in parity 
    async _offlineCheckIn(lat, long) {
    await updateRecord({
        fields: {
        Id: this._recordId,
        Check_In__c: true,
        Check_In_Date_Time__c: new Date().toISOString(),
        Check_In_Location__Latitude__s: lat,
        Check_In_Location__Longitude__s: long,
        Appointment_Status__c: 'Unattempted'
        }
    });
    if (!this.serviceAppointmentId) {
        await this._resolveServiceAppointmentOffline();
    }
    if (this.serviceAppointmentId) {
        await updateRecord({ fields: { Id: this.serviceAppointmentId, Status: 'In Progress' } });
    } else {
        //this.showToastMessage('Info', 'Service Appointment not cached; SA status will sync when available.', 'info');
    }
    }



    // async _stageImagesOffline(wo, saId) {
    //     const fileKey = this._generateDocumentKey(wo);
    //     const acc = this.account || {};
    //     const slots = Array.isArray(this.photoUploadSlots) ? this.photoUploadSlots : [];
    //     const recId= wo.Id;

    //     for (const slot of slots) {
    //         try {
    //         const title = slot.label || 'Photo';
    //         const path = `${fileKey}.jpg`;
    //         const base64 = slot.base64Data ? this._stripDataUrl(slot.base64Data) : null;

    //         if (base64 && base64.length > 0) {
    //             await createRecord({
    //             apiName: 'ContentVersion',
    //             fields: {
    //                 Title: title,
    //                 PathOnClient: path,
    //                 VersionData: base64,
    //                 FirstPublishLocationId: recId
    //             }
    //             });
    //         }

    //         await createRecord({
    //             apiName: 'Document__c',
    //             fields: {
    //             File_Name__c: fileKey+recId,
    //             Work_Order__c: recId,
    //             Service_Appointment__c: saId,
    //             Type__c: title,
    //             BP_Number__c: acc?.BP_Number__c,
    //             Upload_Status__c: 'Pending'
    //             }
    //         });

    //         if (slot.ocr === true) {
    //             await createRecord({
    //             apiName: 'Meter_Reading_OCR__c',
    //             fields: {
    //                 Status__c: 'Pending',
    //                 Work_Order__c: recId,
    //                 Business_Partner__c: acc?.Id,
    //                 BP_Number__c: acc?.BP_Number__c,
    //                 File_Name__c: fileKey,
    //                 Type__c: title
    //             }
    //             });
    //         }
    //         } catch (e) {
    //         // continue other slots
    //         }
    //     }
    //     }

    /** 
 * Stages images, Document__c, and Meter_Reading_OCR__c for offline sync
 * Correct order → Document__c + OCR first, then ContentVersion last
 */
async _stageImagesOffline(wo, saId) {
    const fileKey = this._generateDocumentKey(wo);
    const acc = this.account || {};
    const slots = Array.isArray(this.photoUploadSlots) ? this.photoUploadSlots : [];
    const recId = wo?.Id;

    // helper delay to preserve offline queue order
    const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

    for (const slot of slots) {
        try {
            const title = slot.label || 'Photo';
            const path = `${fileKey}.jpg`;
            const base64 = slot.base64Data ? this._stripDataUrl(slot.base64Data) : null;

            /*  Create Document__c first */
            const docFields = {
                File_Name__c: `${fileKey}${recId}`,
                Work_Order__c: recId,
                Service_Appointment__c: saId,
                Type__c: title,
                BP_Number__c: acc?.BP_Number__c,
                Upload_Status__c: 'Pending'
            };
            await createRecord({ apiName: 'Document__c', fields: docFields });

            // small delay between record inserts to maintain order in sync queue
            await delay(250);

            /*  Create Meter_Reading_OCR__c (if OCR flag true) */
            if (slot.ocr === true) {
                const ocrFields = {
                    Status__c: 'Pending',
                    Work_Order__c: recId,
                    Business_Partner__c: acc?.Id,
                    BP_Number__c: acc?.BP_Number__c,
                    File_Name__c: fileKey,
                    Type__c: title
                };
                await createRecord({ apiName: 'Meter_Reading_OCR__c', fields: ocrFields });
                await delay(250);
            }

            /*  Create ContentVersion last (so trigger finds previous records) */
            if (base64 && base64.length > 0) {
                await createRecord({
                    apiName: 'ContentVersion',
                    fields: {
                        Title: title,
                        PathOnClient: path,
                        VersionData: base64,
                        FirstPublishLocationId: recId // 🔑 ensures CDL → WorkOrder
                    }
                });
                await delay(250);
            }
        } catch (e) {
            console.error('[OfflineImageStage] error:', e);
            // continue with next slot to avoid blocking entire batch
        }
    }
}


        async completeWorkStepWithGraphQL(stepName = 'Start Metering') {
        const target = this._normalize(stepName);
        // 1) If wire already hydrated an Id, update immediately
        if (this._workStepId) {
            try {
            await updateRecord({ fields: { Id: this._workStepId, Status: 'Completed' } });
            this._workStepStatus = 'Completed';
            return true;
            } catch (_) { /* fall through */ }
        }

        // 2) Single imperative GraphQL fetch using the same query/vars pattern
        try {
            if (!this._recordId) return false;
            const resp = await graphql({ query: this.WORKSTEP_QUERY, variables: { woId: this._recordId } });
            const edges = resp?.data?.uiapi?.query?.WorkStep?.edges || [];
            const list = edges.map(e => ({
            id: e?.node?.Id,
            name: this._normalize(e?.node?.Name?.value),
            status: e?.node?.Status?.value
            })).filter(x => !!x.id);

            const match = list.find(x => x.name === target) || list[0] || null;
            const wsId = match?.id || null;
            if (wsId) {
            await updateRecord({ fields: { Id: wsId, Status: 'Completed' } });
            this._workStepId = wsId;
            this._workStepStatus = 'Completed';
            return true;
            }
        } catch (e) {
            // Avoid e.body.message; GraphQL errors are typically in e.errors
            const msg = e?.errors?.[0]?.message || e?.message;
            // Optional: this.showToastMessage('Info', msg || 'WorkStep lookup failed', 'info');
        }

        // Soft signal; do not block the flow
        // Optional: this.showToastMessage('Info', 'WorkStep not found in cache; will complete after sync.', 'info');
        return false;
        }








    uploadFile(imagesList) {}

    handleRedirect(recordId) {
        this.dispatchEvent(new CloseActionScreenEvent());
        if (FORM_FACTOR === 'Large') {
            this.navigateToRecord(recordId);
        } else {
            this.navigateToWorkOrderInFSL(recordId);
        }
    }

    navigateToWorkOrderInFSL(recordId) {
          if (this.isOfflineSaving) {
           this.showToastMessage('Warning','Prevented Close Screen during online Save !','Warning');
            return;
        }
        this.dispatchEvent(new CloseActionScreenEvent());
        this.showToastMessage('Error','Operation Complete Cannot Navigate','Error');
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view',
            },
        });
    }

    handleCancelPhotoUpload() {
        this.imageUploadPage = false;
        this.formSecondPage = false;
        this.formThirdPage = false;
        if (this.showAlert) {
            if (this.checkForZeroReading) {
                this.formThirdPage = true;
            } else {
                this.formSecondPage = true;
            }
        } else {
            if (this.checkForZeroReading) {
                this.formThirdPage = true;
            } else {
                this.formFirstPage = true;
                this.resetFields();
            }
            this.checkOut = false;
        }
    }

    resetFields() {
        this.getGroupCodeOptionsFunc();
        this.groupMessageOptionsFunc(this.groupCodeValue);
        this.groupMessageValue = null;
        this.premiseCorrect = false;
        this.serialNumberVisible = false;
        this.serialNumberCorrect = false;
        this.showMeterSerialNumberCorrect = false;
        this.lpgSupplierValue = null;
        this.showLPGSupplier = false;
        this.showMoreDetails = false;
        this.mglGasBurningPossible = false;
        this.conditionRemark = '';
    }

    handleUpdateCustomer() {
        this.imageUploadPage = false;
        this.accountView = false;
        this.meterReadingPage = false;
        this.updateCustomer = true;
    }

    get errorMessage() {
        if (this.error) {
            try {
                if (this.error.body && this.error.body.message) {
                    return this.error.body.message;
                } else if (this.error.message) {
                    return this.error.message;
                } else {
                    return JSON.stringify(this.error);
                }
            } catch (e) {
                return 'An unexpected error occurred while parsing the error message.';
            }
        }
        return 'An unknown error occurred';
    }

    checkOut = false;
    handleGetLocation() {
    //    this.mainPage=false;
        if (FORM_FACTOR === 'Large') {
            this.getBrowserLocation();
        } else {
            this.getMobileLocation();
        }
    }
    @track showOkModal = false;
    appointments = [];
    mainPage=true;


   workOrderId;
    get graphqlVariables() {
    if (navigator.onLine) {
        return undefined;             // only offline uses GraphQL
    }
    if (!this.workOrderRec || !this.workOrderRec.Id) {
        return undefined;
    }

    const buildingName =
        this.workOrderRec.Building_Name_DMC__c ||
        this.account?.Building_name__c ||
        null;

    const baseVars = {
        workOrderId: this.workOrderRec.Id,
        meterReaderId: this.workOrderRec.Assigned_Meter_Reader__c || ''
    };

    if (buildingName) {
        this._useBuildingFilter = true;
        const vars = { ...baseVars, buildingName };
        // this.debugToast(
        //     'graphqlVariables WO values → ' + JSON.stringify(vars)
        // );
        return vars;
    }

    // No building → query without building filter
    this._useBuildingFilter = false;
    // this.debugToast(
    //     'graphqlVariables WO values (no building) → ' + JSON.stringify(baseVars)
    // );
    return baseVars;
}




    get gqlNextWoQuery() {
    return this._useBuildingFilter
        ? NEXT_WORK_ORDERS_WITH_BUILDING
        : NEXT_WORK_ORDERS_NO_BUILDING;
    }

    @wire(graphql, { query: '$gqlNextWoQuery', variables: '$graphqlVariables' })
    wiredNextWorkOrders({ data, errors }) {
        if (navigator.onLine) {
            return;
        }
        if (data) {
            //this.debugToast('wiredNextWorkOrders: DATA RECEIVED');
            this.processNextWorkOrders(data);
        } else if (errors && errors.length) {
            console.error('Next WorkOrders GraphQL errors: ', JSON.stringify(errors));
            const msg = errors[0]?.message || 'Unknown GraphQL error';
            this.showToastMessage('Error', 'Failed to fetch Next Work Orders offline: ' + msg, 'error');
        } else {
            //this.debugToast('wiredNextWorkOrders: NO DATA');
        }
    }


    processNextWorkOrders(data) {

    // this.debugToast('processNextWorkOrders CALLED');

    const edges = data?.uiapi?.query?.WorkOrder?.edges ?? [];

    // this.debugToast('processNextWorkOrders edges count = ' + edges.length);

    this.appointments = edges.map(({ node }) => ({
        id: node.Id,
        customerName: node.Account?.Name?.value,
        BPNumber: node.Account?.BP_Number__c?.value,
        meterNumber: node.Customer_Meter_Number__c?.value,
        plot: node.Account?.Plot__c?.value,
        wing: node.Account?.Wing__c?.value,
        floor: node.Account?.Floor__c?.value,
        flat: node.Account?.Flat__c?.value
    }));

    // this.debugToast(
    //     'Mapped appointments = ' +
    //     JSON.stringify(this.appointments.map(a => a.id))
    // );

    if (this.appointments.length > 0) {
        // this.debugToast('Next WorkOrders FOUND → Showing list');
        //this.mainPage = false;
    } else {
        // this.debugToast('NO next workorders found offline');
    }
}

    debugToast(msg) {
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'DEBUG',
            message: msg,
            variant: 'info',
            mode: 'sticky'
        })
    );
}






    handleSaveClick() {

             //this.showToastMessage('Final OK clicked, preparing to fetch next work orders', 'info');
            if (!navigator.onLine) {
                if (this.appointments && this.appointments.length > 0) {
                    this.mainPage = false;
                } else {
                   //this.debugToast('appointments EMPTY → waiting for GraphQL wire');
                }
                return;
            }

            else{
                    getNextWorkOrder({
                workOrderId: this.workOrderRec.Id
            })
            .then((result) => {
                let nextId = result;
                if(nextId && nextId.length > 0){
                    this.appointments = JSON.parse(JSON.stringify(result));
                    this.mainPage = false;
                    // this.showToastMessage('Success', 'Opening next workOrder.', 'success');
                    // // this.handleRedirect(nextId);
                    // if (FORM_FACTOR === 'Large') {
                    //     this.navigateToRecord(nextId);
                    // } else {
                    //     this[NavigationMixin.Navigate]({
                    //         type: 'standard__webPage',
                    //         attributes: {
                    //             url: `com.salesforce.fieldservice://v1/sObject/${nextId}/overview`
                    //         }
                    //     });
                    // }
                }else{
                    this.handleRedirect(this.recordId);
                }
            })
            .catch((error) => {
                console.log('Error getting next work order: ', error);
                //this.showToastMessage('Error', 'Error getting next work order:'+JSON.stringify(error), 'error');
            });
            // this.handleRedirect(this.recordId);
                }

        
    }

     showToastMessage(message, variant = 'info') {
        this.dispatchEvent(
        new ShowToastEvent({
            title: 'Debug',
            message,
            variant,
            mode: 'pester'
        })
        );
    }

    lat;
    long;
    getBrowserLocation() {
        this.load = true;
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    var latitude = position.coords.latitude;
                    var longitude = position.coords.longitude;
                    this.lat = latitude;
                    this.long = longitude;
                    this.updateCheckInDetails();
                    this.load = false;
                },
                (error) => {
                    this.showToastMessage('Error', 'Please enable your device location', 'error');
                    this.showToastMessage('Error', error.body.message, 'error');
                    this.load = false;
                }
            );
        } else {
            this.showToastMessage('Error', 'Geolocation is not supported by this browser', 'error');
            this.load = false;
        }
    }

    getMobileLocation() {
        this.load = true;
        if(navigator.onLine){
            const locationService = getLocationService();
            if (!locationService || !locationService.isAvailable()) {
                this.showToastMessage('LocationService Not Available', 'Please use a GPS-enabled mobile device and ensure location is turned on.', 'error');
                this.load = false;
                return;
            }
            const options = {
                enableHighAccuracy: true
            };
            locationService.getCurrentPosition(options)
                .then(result => {
                    this.lat = result.coords.latitude;
                    this.long = result.coords.longitude;
                    
                })
                .catch(error => {
                    this.showToastMessage('Error', 'Please enable your device location.', 'error');
                    this.showToastMessage('Error', error.body.message, 'error');
                    this.load = false;
                })
            this.updateCheckInDetails();

            } else {
                this.updateCheckInDetails();
            }
        
    }




    updateCheckInDetails() {
        this.load = true;
        if (navigator.onLine) {
            workOrderCheckIn({
                workOrderId: this._recordId,
                serviceAppointId: this.serviceAppointmentId,
                latitude: this.lat,
                longitude: this.long
            })
            .then(result => {
                if (!this.checkOut) {
                    this.handleTakeReading();
                    this.checkOut = true;
                    this.load = false;
                } else {
                    this.handleFinalSave();
                }
            })
            .catch(error => {
                this.showToastMessage('Error', error.body.message , 'error');
                console.log('The Error from Check in-->',error.body.message);
                this.load = false;
            });
            return;
        }

        // OFFLINE: queue same updates via LDS
        Promise.resolve()
        .then(() => updateRecord({
            fields: {
                Id: this._recordId,
                Check_In__c: true,
                Check_In_Date_Time__c: new Date().toISOString(),
                Check_In_Location__Latitude__s: this.lat,
                Check_In_Location__Longitude__s: this.long,
                Appointment_Status__c: 'Unattempted'
            }
        }))
        .then(() => {
            // If SA id is known offline (from earlier online fetch), set status to In Progress
            if (this.serviceAppointmentId) {
                // return updateRecord({
                //     fields: { Id: this.serviceAppointmentId, Status: 'In Progress' }
                // });
            }
        })
        .then(() => {
            if (!this.checkOut) {
                this.handleTakeReading();
                this.checkOut = true;
                this.load = false;
            } else {
                this.handleFinalSave();
            }
        })
        .catch((error) => {
            this.showToastMessage('Error', error.body.message, 'error');
            this.load = false;
        })
        .finally(() => {  });
    }

    plausibilityCheck(previousReading, currentReading, lastReadingDate, averageConsumption) {
        previousReading = previousReading ? Number(previousReading) : 0;
        currentReading = currentReading ? Number(currentReading) : 0;
        averageConsumption = averageConsumption ? Number(averageConsumption) : 0;
        if (previousReading > currentReading) {
            return { valid: false, message: 'Negative consumption' };
        }

        if (previousReading == currentReading) {
            return { valid: false, message: 'Zero consumption' };
        }

        if (lastReadingDate) {
            const daysDiff = this.daysBetween(lastReadingDate, new Date());
            const consumption = currentReading - previousReading;
            const highThreshold = 2 * (averageConsumption * daysDiff);
            const lowThreshold = 0.25 * (averageConsumption * daysDiff);

            if (consumption > highThreshold) {
                return { valid: false, message: 'High consumption' };
            }
            if (consumption < lowThreshold) {
                return { valid: false, message: 'Low consumption' };
            }
        }
        return { valid: true, message: '' };
    }

    daysBetween(date1, date2) {
        const d1 = new Date(date1);
        const d2 = new Date(date2);
        const diffInMs = Math.abs(d2 - d1);
        return Math.floor(diffInMs / (1000 * 60 * 60 * 24));
    }

    showToastMessage(title, message, variant, mode) {
        const evt = new ShowToastEvent({ title, message, variant, mode });
        this.dispatchEvent(evt);
    }

    /* === OFFLINE helper to strip data URL prefix === */
    _stripDataUrl(b64) {
        if (!b64) return '';
        const idx = b64.indexOf(',');
        return b64.startsWith('data:') && idx > -1 ? b64.slice(idx + 1) : b64;
    }

}