/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 25-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   27-10-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { LightningElement,api,wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import USER_ID from '@salesforce/user/Id';

import USER_PROFILE_ID_FIELD from '@salesforce/schema/User.ProfileId';
import PROFILE_NAME_FIELD from '@salesforce/schema/Profile.Name';


export default class WorkOrderActionButtonComponent extends LightningElement {
  @api reactiveValue=[];
  idsList = [];

  disableRecSelectionBtn = false;
  isButtonView = true;

  isUploadRecordBtnSelected = false;
  isAssignAgencyBtnSelected = false;
  isBulkUploadBtnSelected = false;
  isWithdrawBtnSelected = false;
  isVisitEndDateBtnSelected = false;

  isMeteringUser = false;
  isRTUser = false;

  ipdDMCAICUsers=false;
  rubberhoseAicUser=false;
  rubberhoseContractor=false;
  aftersalesusers=false;
  afterSalesAicUser=false;
  ipdDMCContractorUsers=false;

  mrAicUser=false;
  showAssignAgencyAgentMR=false;

  omBulkAICWorkorderCloser=false;
  omBulkAgencyAgent=false;
  omAfBulkAICWorkorderCloser=false;
  showAsOMCaseCSVUploaderComp = false;
  showAsOMWorkAgencyAgentUploaderComp=false;
  
  omaicusers=false;
    omaicusersMR=false;
    omaaicusersAFS=false;
showAICApprovalMRComp=false;
  omrhUser=false;
  showAssignServiceAppointmentComp =false;
  showContractorApprovalComp=false;
  showAICApprovalComp=false;
  showAICApprovalAfsComp=false;
  showAssignContractorComp=false;
  showAICWorkOrderCloseComp=false;
  showAICWorkOrderWithdraw=false;
  showAsssignagencyagent=false;
  showAsssignagencyagentAfs=false;
  profileName;
  profileId;
  
  // Wire service #1: Fetch the current user's ProfileId
  @wire(getRecord, { recordId: USER_ID, fields: [USER_PROFILE_ID_FIELD] })
  wiredUser({ error, data }) {
      if (data) {
          this.profileId = data.fields.ProfileId.value;
      } else if (error) {
          console.error('Error fetching User ProfileId:', error);
      }
  }

  @wire(getRecord, { recordId: '$profileId', fields: [PROFILE_NAME_FIELD] })
  wiredProfile({ error, data }) {
      if (data) {
          
          const profileName = data.fields.Name.value;
        
        if(profileName == 'AIC I&C' || profileName == 'AIC R&T' || profileName == 'System Administrator'){
          this.isRTUser = true;
        }
        if(profileName == 'AIC (Metering)' || profileName == 'System Administrator'){
          this.isMeteringUser = true;
        }

       // assign to agent aic
         if(profileName == 'System Administrator' || profileName =='Supervisor (O&M)' || profileName =='Supervisor (O&M- IPD)' 
            || profileName =='Supervisor (O&M- AfterSalesService)' || profileName=='Supervisor (O&M- Meter Replacement)' || profileName=='O&M Rubber Hose Supervisor'
            || profileName == 'Supervisor (O&M-I&CCommercialMaintenance)'
            ){

          this.ipdDMCAICUsers=true;
        } 

          if(profileName == 'RubberHose AIC' || profileName == 'System Administrator' ){

          this.rubberhoseAicUser=true;
        } 

         if(profileName == 'System Administrator' || profileName =='AIC (O&M- AfterSalesService)'){

          this.omBulkAgencyAgent=true;
        } 
        if(profileName == 'System Administrator' || profileName =='AIC (O&M- IPD)' || profileName =='O&M AIC IPD' 
              || profileName == 'O&M AIC Rubber Hose' ){

          this.omBulkAICWorkorderCloser=true;
        } 

         if(profileName == 'System Administrator' || profileName =='AIC (O&M- AfterSalesService)'){

          this.omAfBulkAICWorkorderCloser=true;
        } 


        if(profileName == 'System Administrator' || profileName=='O&M Rubber Hose Supervisor'  ){
          this.rubberhoseContractor=true;
        }
         if(profileName == 'System Administrator' || profileName=='AIC (O&M- AfterSalesService)'  || profileName=='Supervisor (O&M- AfterSalesService)'  ){
          this.aftersalesusers=true;
        }
         if(profileName=='AIC (O&M- Meter Replacement)'){
          this.mrAicUser=true;
        }
         if(profileName == 'AIC (O&M- AfterSalesService)' || profileName == 'System Administrator' ){

          this.afterSalesAicUser=true;
        } 
        // supervisor contractor approval
         if(profileName == 'System Administrator' || profileName =='Supervisor (O&M- AfterSalesService)' 
            || profileName =='Supervisor (O&M- Meter Replacement)'){

          this.ipdDMCContractorUsers=true;
        } 
        // o&m profile commented
        /*
         profileName =='Riser AIC' || profileName =='O&M AIC Riser Activity'
            || profileName =='Escalation SPOC' || profileName =='AIC (O&M- Domestic Meter Checking)'
           || profileName =='AIC (O&M- IPD)' || profileName =='	O&M AIC IPD'
          || profileName =='O&M AIC Rubber Hose' || profileName =='RubberHose AIC' || profileName =='AIC (O&M- IPD)' || profileName =='O&M AIC IPD'

        */
          if(profileName == 'System Administrator'
           || profileName =='AIC (O&M- IPD)' || profileName =='O&M AIC IPD'
          || profileName =='O&M AIC Rubber Hose' 
          // || profileName =='RubberHose AIC'
          || profileName =='Riser AIC' || profileName =='O&M AIC Riser Activity' 
          || profileName == 'AIC (O&M- I&CCommercialMaintenance)' || profileName =='AIC Building Demolition'   ){

          this.omaicusers=true;
        }
        if(profileName == 'System Administrator' || profileName =='AIC (O&M- AfterSalesService)'
          
           ){

          this.omaaicusersAFS=true;
        }
         if(profileName == 'System Administrator' ||  profileName =='RubberHose AIC' || profileName =='AIC (O&M- AfterSalesService)'
          
           ){

          this.omrhUser=true;
        }
          if( profileName =='AIC (O&M- Meter Replacement)'){
            

          this.omaicusersMR=true;
        }
      } else if (error) {
          console.error('Error fetching Profile Name:', error);
      }
  }

  connectedCallback() {
      if (this.reactiveValue.length > 0 && Array.isArray(this.reactiveValue)) {
        this.idsList = this.reactiveValue;
      }
      else if(this.reactiveValue.length == 0){
          this.disableRecSelectionBtn = true;
      }
  }

  showUploadRecordBtn(){
    this.isUploadRecordBtnSelected = true;
    this.isButtonView = false;
  }

  showAssignAgencyBtn(){
    this.isAssignAgencyBtnSelected = true;
    this.isButtonView = false;
  }

  showWithdrawBtn(){
    this.isWithdrawBtnSelected = true;
    this.isButtonView = false;
  }

  showVisitEndDateBtn(){
    this.isVisitEndDateBtnSelected = true;
    this.isButtonView = false;
  }

  showBulkUploadPdfBtn(){
    this.isBulkUploadBtnSelected = true;
    this.isButtonView = false;
  }

  isApprovalBtnSelected = false;
  showApprovalBtn(){
    this.isApprovalBtnSelected = true;
    this.isButtonView = false;
  }

  isSendEmailBtnSelected = false;
  showSendEmailBtn(){
    this.isSendEmailBtnSelected = true;
    this.isButtonView = false;
  }

  isReAssignMeterReaderSelected = false;
  showReAssignMeterReader(){
    this.isReAssignMeterReaderSelected = true;
    this.isButtonView = false;
  }


// O&M
  showAssignToAgentButton(){
    this.showAssignServiceAppointmentComp = true;
    this.isButtonView = false;

  }
  showAssignToContractorButton(){
     this.showAssignContractorComp = true;
    this.isButtonView = false;
  }
   showContractorApprovalButton(){
     this.showContractorApprovalComp = true;
     this.isButtonView = false;

   }
  showAICApprovalButton(){
    this.showAICApprovalComp = true;
    this.isButtonView = false;

  }
  showAICApprovalAfsButton(){
    this.showAICApprovalAfsComp = true;
    this.isButtonView = false;

  }
  
  showAICApprovalMRButton(){
    this.showAICApprovalMRComp = true;
    this.isButtonView = false;

  }
  showomBulkAICWorkorderCloserComp(){
    this.showAsOMCaseCSVUploaderComp = true;
    this.isButtonView = false;

  }
showomBulkOMWorkAgencyAgentComp(){
    this.showAsOMWorkAgencyAgentUploaderComp = true;
    this.isButtonView = false;

  }
   showomAfBulkAICWorkorderCloserComp(){
    this.showAsOMWorkOrderCSVUploaderComp = true;
    this.isButtonView = false;

  }


  showAICWorkOrderCloseButton(){
     this.showAICWorkOrderCloseComp = true;
    this.isButtonView = false;
  }
    handleshowAICWorkOrderWithdraw(){
    console.log('withdraw allocation for rubberhose::');
     this.showAICWorkOrderWithdraw = true;
    this.isButtonView = false;
  }

  handleassignagencyagent(){
    console.log('handleassignagencyagent::');
    this.showAsssignagencyagent=true;
     this.isButtonView = false;
  }
  handleassignagencyagentafs(){
    console.log('handleassignagencyagentafs::');
    this.showAsssignagencyagentAfs=true;
     this.isButtonView = false;
  }

   handleMRAICAgencyAgentChange(){
    console.log('handleMRAICAgencyAgentChange::');
    this.showAssignAgencyAgentMR=true;
     this.isButtonView = false;
  }
}