import { LightningElement, wire, track, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import generateRefundLetter from '@salesforce/apex/CaseController.generateRefundLetter';
import { CloseActionScreenEvent } from 'lightning/actions';

// ✅ Case & Account Fields
const CASE_FIELDS = [
    'Case.CaseNumber',
    'Case.AccountId',
    'Case.Refund_Amount__c',
    'Case.Department_Responded_On__c',
    'Case.Cheque_Number__c',
    'Case.Bank_Name__c'
];

const ACCOUNT_FIELDS = [
    'Account.Name',
    'Account.Flat__c',
    'Account.Floor__c',
    'Account.Building_Name_Conn__c',
    'Account.District__c',
    'Account.Other_City__c',
    'Account.Street__c',
    'Account.Street_Line_2__c',
    'Account.Street_Line_3__c',
    'Account.Street_Line_4__c',
    'Account.Street_Line_5__c',
    'Account.City__c',
    'Account.Postal_Code__c',
    'Account.Phone',
    'Account.Secondary_Telephone__c',
    'Account.BP_Number__c',
    'Account.Full_Name__c',
    'Account.Room__c',
    'Account.Person_Title__c',
    'Account.Supplement__c'
];

export default class GenerateRefundFRL extends LightningElement {
    @api recordId;
    @api objectApiName;

    @track form = {};
    @track createdCaseId;
    @track caseDetail = {};
    @track accountdetail = {};

    caseAccountId;
    isCaseLoaded = false;
    isAccountLoaded = false;

    // ✅ Load Case
    @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
    wiredCase({ data, error }) {
        if (data) {
            this.caseDetail = {
                Id: data.id,
                CaseNumber: data.fields.CaseNumber.value,
                Refund_Amount__c: data.fields.Refund_Amount__c?.value,
            Department_Responded_On__c: data.fields.Department_Responded_On__c?.value,
            Cheque_Number__c: data.fields.Cheque_Number__c?.value,
            Bank_Name__c: data.fields.Bank_Name__c?.value

            };

            this.createdCaseId = data.id;
            this.caseAccountId = data.fields.AccountId?.value;
            this.isCaseLoaded = true;

            this.tryGenerateLetter();
        } else if (error) {
            console.error('Error loading Case', JSON.stringify(error));
        }
    }

    // ✅ Load Account using AccountId from Case
    @wire(getRecord, { recordId: '$caseAccountId', fields: ACCOUNT_FIELDS })
    wiredAccount({ data, error }) {
        if (data) {
            this.accountdetail = {
                Name: data.fields.Name?.value,
                Flat__c: data.fields.Flat__c?.value,
                Floor__c: data.fields.Floor__c?.value,
                Building_Name_Conn__c: data.fields.Building_Name_Conn__c?.value,
                Street__c: data.fields.Street__c?.value,
                Street_Line_2__c: data.fields.Street_Line_2__c?.value,
                Street_Line_3__c: data.fields.Street_Line_3__c?.value,
                Street_Line_4__c: data.fields.Street_Line_4__c?.value,
                Street_Line_5__c: data.fields.Street_Line_5__c?.value,
                City__c: data.fields.City__c?.value,
                Postal_Code__c: data.fields.Postal_Code__c?.value,
                Phone: data.fields.Phone?.value,
                Secondary_Telephone__c: data.fields.Secondary_Telephone__c?.value,
                BP_Number__c: data.fields.BP_Number__c?.value,
                Full_Name__c: data.fields.Full_Name__c?.value,
                Room__c: data.fields.Room__c?.value,
                Person_Title__c: data.fields.Person_Title__c?.value,
                District__c: data.fields.District__c?.value,
                Supplement__c: data.fields.Supplement__c?.value,
                Other_City__c: data.fields.Other_City__c?.value
            };

            this.isAccountLoaded = true;
            this.tryGenerateLetter();
        } else if (error) {
            console.error('Error loading Account', JSON.stringify(error));
        }
    }

    // ✅ Ensure both Case + Account are loaded
    tryGenerateLetter() {
        if (this.isCaseLoaded && this.isAccountLoaded) {
            this.generateLetter();
        }
    }

    // ✅ Generate PDF & Attach
    async generateLetter() {
        try {
            const cs = this.caseDetail || {};
            const acc = this.accountdetail || {};
            const today = new Date();

            const day = String(today.getDate()).padStart(2, '0');
            const month = String(today.getMonth() + 1).padStart(2, '0');
            const year = today.getFullYear();
            const dateValue = `${day}.${month}.${year}`;

            const fy = (today.getMonth() + 1) >= 4
                ? `${year}-${String(year + 1).slice(-2)}`
                : `${year - 1}-${String(year).slice(-2)}`;

            const templateBody = `
              <table style="width: 100%; margin-top: 10px;">
                <tr>
                    <td style="text-align: left;">
                        <strong>Ref No: MGL/CRM/${cs.CaseNumber}/${fy}</strong>
                    </td>
                    <td style="text-align: right;"><strong>Date: ${dateValue}</strong></td>
                </tr>
            </table>
            <div style="margin-top: 8px; line-height: 1.4;">
                To,<br/>
                <strong>${acc.Person_Title__c || ''} ${acc.Full_Name__c || 'Customer'}</strong><br/>
                ${acc.Room__c ? `Flat No: ${acc.Room__c}` : ''} 
                ${acc.Room__c && acc.Floor__c ? ', ' : ''}${acc.Floor__c ? `Floor No: ${acc.Floor__c}` : ''} 
                ${(acc.Room__c || acc.Floor__c) && acc.Supplement__c ? ', ' : ''}${acc.Supplement__c ? `Wing: ${acc.Supplement__c},<br/>` : acc.Room__c || acc.Floor__c ? '<br/>' : ''}
                
                ${acc.Building_Name_Conn__c ? `Building: ${acc.Building_Name_Conn__c},<br/>` : ''}
                ${acc.Street__c ? `${acc.Street__c},<br/>` : ''}
                ${acc.Street_Line_3__c ? `${acc.Street_Line_3__c},<br/>` : ''}
                ${acc.Street_Line_4__c ? `${acc.Street_Line_4__c},<br/>` : ''}
                ${acc.Street_Line_5__c ? `${acc.Street_Line_5__c},<br/>` : ''}
                ${acc.Other_City__c || acc.District__c || acc.City__c || acc.Postal_Code__c
                ? `${acc.Other_City__c ? acc.Other_City__c + ', ' : ''}${acc.District__c ? acc.District__c + ', ' : ''}${acc.City__c ? acc.City__c + ' - ' : ''}${acc.Postal_Code__c || ''}<br/>`
                : '<br/>'}

                <div style="margin-top: 10px;">
                    Tel: ${acc.Secondary_Telephone__c || '0'} <br/>
                    Mob: ${acc.Phone || '0'}<br/>
                    Encl: Refund Cheque
                </div>

                <div style="margin-top: 10px;">
                    <strong><u>Sub: Refund of PNG Charges</u></strong>
                </div>

                <div style="margin-top: 10px;">
                    ${acc.BP_Number__c ? `<strong>Business Partner Number (BP): ${acc.BP_Number__c}</strong><br/>` : ''}
                    ${cs.CaseNumber ? `<strong>Case Number: ${cs.CaseNumber}</strong>` : ''}
                </div>
                <div style="margin-top: 25px;">
                    Dear Sir/Madam,<br/>
                    <div style="margin-top: 10px;">
                    We appreciate your keenness to opt for our eco-friendly product. Your request for refund of deposit/charges paid towards PNG connection has been accepted.</div>
                    <div style="margin-top: 10px;">
As per our policy Rs. 750 has been deducted towards Application Charges.</div>
                    <div style="margin-top: 10px;">
Please find attached herewith cheque no. ${cs.Cheque_Number__c} dated on ${cs.Department_Responded_On__c} for Rs.${cs.Refund_Amount__c} drawn on ${cs.Bank_Name__c}.</div>
<div style="margin-top: 10px;">
You are requested to acknowledge the receipt of the same.</div>
<div style="margin-top: 10px;">
We look forward to our renewed association in future.</div>
                </div>
            </div>
            `;

            await generateRefundLetter({
                caseId: this.createdCaseId,
                objectType: this.objectApiName,
                templateBody
            });

            console.log('✅ PDF generated and attached successfully');

        } catch (error) {
            console.error('❌ PDF generation failed', JSON.stringify(error));
        }
                         this.dispatchEvent(new CloseActionScreenEvent());

    }
}