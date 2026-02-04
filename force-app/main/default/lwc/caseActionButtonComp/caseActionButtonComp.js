/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 27-10-2025
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


export default class CaseActionButtonComp    extends LightningElement {
  @api reactiveValue=[];
  idsList = [];

  disableRecSelectionBtn = false;
  isButtonView = true;

 showCreateWorkOrderComp=false;
 showBDCreateWorkOrderComp=false;

  ipdDMCAICUsers=false;
  bdAICUsers=false;

  // afterSalesAICUsers=false;
  // showCreateWorkOrderAfterSalesComp=false;

 
  
 

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
           console.log ('Profile Name::' + profileName );

       
        //   || profileName =='O&M AIC Rubber Hose' || profileName =='RubberHose AIC'
          
          if((profileName == 'System Administrator'
           || profileName =='AIC (O&M- IPD)' || profileName =='O&M AIC IPD'
          || profileName =='Escalation SPOC' || profileName 
          || profileName =='AIC (O&M- AfterSalesService)') && profileName !='AIC Building Demolition'
           ){

           

          this.ipdDMCAICUsers=true;
        }
        if (profileName =='AIC Building Demolition'){
        
         this.bdAICUsers=true;
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

 
// O&M
  showCreateWorkOrder(){
    this.showCreateWorkOrderComp = true;
    this.isButtonView = false;

  }
 //BD
  showBDCreateWorkOrder(){
    this.showBDCreateWorkOrderComp = true;
    this.isButtonView = false;
  }

  //   showCreateAfterSalesWorkOrder(){
  //   this.showCreateWorkOrderAfterSalesComp = true;
  //   this.isButtonView = false;

  // }
 
}