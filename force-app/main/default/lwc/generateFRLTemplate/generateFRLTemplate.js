import { LightningElement, api, track } from 'lwc';
import getTemplateById from '@salesforce/apex/FRLTemplatesController.getTemplateById';
import generatePDF from '@salesforce/apex/FRLTemplatesController.generatePDF';
import getCaseAccountInfo from '@salesforce/apex/FRLPDFController.getCaseAccountInfo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import insertTemplateData from '@salesforce/apex/FRLTemplatesController.insertTemplateData';
import PdfPreviewModal from 'c/pdfPreviewModal';

export default class FrlTemplateGenerator extends LightningElement {
    @api recordId;
    @track selectedTemplateId;
    @track templateSubject = '';
    @track richTextValue = '';
    @track templateBodyFromServer = '';
    @track selectedFontSize = '13px';

    fontSizeOptions = [

        { label: '8px', value: '8px' },

        { label: '10px', value: '10px' },

        { label: '12px', value: '12px' },

        { label: '13px', value: '13px' },

        { label: '14px', value: '14px' },

        { label: '16px', value: '16px' },

        { label: '18px', value: '18px' },

        { label: '20px', value: '20px' },

        { label: '24px', value: '24px' },

        { label: '28px', value: '28px' },

        { label: '32px', value: '32px' }

    ];

    caseAccountInfo = null;

    connectedCallback() {
        if (this.recordId) {
            this.loadCaseAccountInfo();
        }
    }

    loadCaseAccountInfo() {
        getCaseAccountInfo({ caseId: this.recordId })
            .then(data => {
                this.caseAccountInfo = data;
                console.log(' this.caseAccountInfo ',JSON.stringify( this.caseAccountInfo ));
                // Build full message if template body already fetched
                if (this.templateBodyFromServer) {
                    this.buildFullMessageContent(this.templateBodyFromServer);
                }
            })
            .catch(error => {
                console.error('Error loading Case and Account info:', error);
                this.showToast('Error', 'Could not load Case and Account info.', 'error');
            });
    }

    handleFRLTemplate(event) {
        const record = event.detail;

        if (record) {
            this.selectedTemplateId = record.Id;
            console.log('Selected Template ID:', this.selectedTemplateId);

            getTemplateById({ templateId: this.selectedTemplateId })
                .then(result => {
                    console.log('Template Name:', result.Name || '');
                    console.log('Template Body:', result.Body__c || '');
                    this.templateSubject = result.Name || '';
                    this.templateBodyFromServer = result.Body__c || '';

                    if (this.caseAccountInfo && !this.richTextValue) {
                        this.buildFullMessageContent(this.templateBodyFromServer);
                    }
                })
                .catch(error => {
                    console.error('Error fetching template body:', JSON.stringify(error));
                    this.showToast('Error', 'Could not fetch template body.', 'error');
                });
        } else {
            this.selectedTemplateId = null;
            this.templateSubject = '';
            this.richTextValue = '';
        }
    }

    handleNoTemplate() {
        this.selectedTemplateId = null;
        this.templateSubject = '';
        this.richTextValue = '';
    }

    buildFullMessageContent(templateBody) {
        
        if (!this.caseAccountInfo) {
            this.richTextValue = templateBody;
            return;
        }


        const acc = this.caseAccountInfo.account || {};
        // Inspect full payload the safe way
        console.log('FULL caseAccountInfo:', JSON.stringify(this.caseAccountInfo));
        console.log('ACC keys:', Object.keys(acc), 'ACC raw:', acc);

        const todayDate = this.caseAccountInfo.todayDate || '';
        const caseNumber = this.caseAccountInfo.caseNumber || '';
        const ownerType = this.caseAccountInfo.ownerType || '';

        let bpOrLeadLabel = 'Business Partner Number (BP)';
        if (ownerType === 'lead') {
            bpOrLeadLabel = 'Lead Number';
        }

        console.log("Building Full Message Content with Body");

        if (this.templateSubject === 'Refund Template') {
        const refHeader = `
<table style="width: 100%; margin-top: 10px; font-size: 13px;">
        <tr>
            <td style="text-align: left;"><strong>Ref No: MGL/CRM/${caseNumber}</strong></td>
            <td style="text-align: right;"><strong>Date: ${todayDate}</strong></td>
        </tr>
    </table>
`;



        const toAddressParts = [];
        this.formattedCreatedDate = this.formatDate(this.caseAccountInfo.createdate);
        toAddressParts.push('To,<br/>');
        toAddressParts.push(`<strong> ${acc.Person_Title__c || ''} ${acc.Name || 'Customer'}</strong><br/>`);
        if (acc.Flat__c) toAddressParts.push(`Flat No: ${acc.Flat__c}<br/>`);
        if (acc.Room__c) toAddressParts.push(`Floor No: ${acc.Room__c}<br/>`);
        if (acc.Supplement__c) toAddressParts.push(`Wing: ${acc.Supplement__c}<br/>`);
        if (acc.Building_Name_Conn__c) toAddressParts.push(`Building: ${acc.Building_Name_Conn__c}<br/>`);
        const streetLines = [acc.Street__c, acc.Street_Line_3__c].filter(Boolean).join(', ');
        const streetLines1 = [acc.Street_Line_4__c, acc.Street_Line_5__c].filter(Boolean).join(', ');
        if (streetLines) toAddressParts.push(`${streetLines}<br/>`);
        if (acc.Other_City__c || acc.City__c || acc.Postal_Code__c) {
            toAddressParts.push(`${acc.Other_City__c || ''} ${acc.City__c || ''} ${acc.Postal_Code__c || ''}<br/>`);
        }
        if (acc.Phone) toAddressParts.push(`Tel: ${acc.Phone}<br/>`);
        if (acc.Secondary_Telephone__c) toAddressParts.push(`Mob: ${acc.Secondary_Telephone__c}<br/>`);
        toAddressParts.push(`<strong>Sub: ${this.caseAccountInfo.casetype || ''}</strong><br/>`);

        console.log('🔍 ACC DATA:', JSON.parse(JSON.stringify(acc)));
        console.log('🔍 acc.ownerType:', acc.ownerType);


        if (acc.BP_Number__c) toAddressParts.push(`${bpOrLeadLabel}: ${acc.BP_Number__c}<br/>`);
        toAddressParts.push(`Case / Docket Number: ${caseNumber}`);
        const toAddress = `<div style="margin: 10px 0 0 0;">${toAddressParts.join('')}</div>`;

        // ✅ WRAP everything in a proper <div> container
        const refundContent = `
<div style="font-size: 14px; line-height: 1.3; font-family: 'Times New Roman', Times, serif;">
    ${refHeader}
    <div style="margin-top: 10px;">
        To,<br/>
        <strong>${acc.Person_Title__c || ''} ${acc.Name || 'Customer'}</strong><br/>
        ${acc.Room__c ? `Flat No: ${acc.Room__c},` : ''}
        ${acc.Floor__c ? `Floor No: ${acc.Floor__c},` : ''}
        ${acc.Supplement__c ? `Wing: ${acc.Supplement__c},<br/>` : '<br/>'} <!-- add line break if no supplement -->
        ${acc.Building_Name_Conn__c ? `Building: ${acc.Building_Name_Conn__c},<br/>` : ''}
        ${streetLines ? `${streetLines},<br/> ` : '<br/>'}
        ${streetLines1 ? `${streetLines1},<br/> ` : ''}
${acc.Other_City__c || acc.District__c || acc.City__c || acc.Postal_Code__c
    ? `${acc.Other_City__c ? acc.Other_City__c + ', ' : ''}${acc.District__c ? acc.District__c + ', ' : ''}${acc.City__c ? acc.City__c + ' - ' : ''}${acc.Postal_Code__c || ''}<br/>`
    : '<br/>'}      <div style="margin-top: 10px;">
        ${acc.Phone || acc.Secondary_Telephone__c 
            ? `${acc.Secondary_Telephone__c || ''} <br/> ${acc.Phone || ''}` 
            : `<br/> <br/>`}
        </div>
        <div style="margin-top: 10px;">
        Encl: Refund Cheque<br/>
       </div>
        <div style="margin-top: 10px;">
        <strong>Sub: Refund of PNG Charges</strong><br/>
       </div>
       <div style="margin-top: 10px;">
        <strong>
            ${acc.BP_Number__c ? `${bpOrLeadLabel}: ${acc.BP_Number__c}<br/>` : ''}
            Case Number: ${caseNumber}
        </strong>
        </div>
    </div>

    <div style="line-height: 1.3; margin-top: 10px; font-size: 14px;">
        <p>Dear Sir / Madam,</p>
        
    </div>

</div>

<div style="font-family: 'Times New Roman', Times, serif;">
    ${templateBody}
</div>
`;

        this.richTextValue = refundContent;
        
        requestAnimationFrame(() => {
            const container = this.template.querySelector('[data-id="messageEditor"]');
            if (container) {
                container.innerHTML = refundContent;
            }
        });

        // ❗ very important: do NOT fall through to old template
        return;
    }

            

        const refHeader = `
    <table style="width: 100%; margin-top: 10px; font-size: 13px;">
        <tr>
            <td style="text-align: left;"><strong>Ref No: MGL/CRM/</strong></td>
            <td style="text-align: right;"><strong>Date: ${todayDate}</strong></td>
        </tr>
    </table>
`;



        const toAddressParts = [];
        this.formattedCreatedDate = this.formatDate(this.caseAccountInfo.createdate);
        
        toAddressParts.push('To,<br/>');
        toAddressParts.push(`<strong> ${acc.Person_Title__c || ''} ${acc.Name || 'Customer'}</strong><br/>`);
        if (acc.Flat__c) toAddressParts.push(`Flat No: ${acc.Flat__c}<br/>`);
        if (acc.Room__c) toAddressParts.push(`Floor No: ${acc.Room__c}<br/>`);
        if (acc.Supplement__c) toAddressParts.push(`Wing: ${acc.Supplement__c}<br/>`);
        if (acc.Building_Name_Conn__c) toAddressParts.push(`Building: ${acc.Building_Name_Conn__c}<br/>`);

        const streetLines = [acc.Street__c, acc.Street_Line_3__c].filter(Boolean).join(', ');
        const streetLines1 = [acc.Street_Line_4__c, acc.Street_Line_5__c].filter(Boolean).join(', ');
        if (streetLines) toAddressParts.push(`${streetLines}<br/>`);
        if (acc.Other_City__c || acc.City__c || acc.Postal_Code__c) {
            toAddressParts.push(`${acc.Other_City__c || ''} ${acc.City__c || ''} ${acc.Postal_Code__c || ''}<br/>`);
        }
        
        if (acc.Phone) toAddressParts.push(`Tel: ${acc.Phone}<br/>`);
        if (acc.Secondary_Telephone__c) toAddressParts.push(`Mob: ${acc.Secondary_Telephone__c}<br/>`);
        toAddressParts.push(`<strong>Sub: ${this.caseAccountInfo.casetype || ''}</strong><br/>`);

        console.log('🔍 ACC DATA:', JSON.parse(JSON.stringify(acc)));
        console.log('🔍 acc.ownerType:', acc.ownerType);

        if (acc.BP_Number__c) toAddressParts.push(`${bpOrLeadLabel}: ${acc.BP_Number__c}<br/>`);
        toAddressParts.push(`Case / Docket Number: ${caseNumber}`);
        const toAddress = `<div style="margin: 10px 0 0 0;">${toAddressParts.join('')}</div>`;

        

        // ✅ WRAP everything in a proper <div> container
        const fullContent = `
<div style="font-size: 14px; line-height: 1.3; font-family: 'Times New Roman', Times, serif;">
    ${refHeader}
    <div style="margin-top: 10px;">
        To,<br/>
        <strong>${acc.Person_Title__c || ''} ${acc.Name || 'Customer'}</strong><br/>
        ${acc.Room__c ? `Flat No: ${acc.Room__c},` : ''}
        ${acc.Floor__c ? `Floor No: ${acc.Floor__c},` : ''}
        ${acc.Supplement__c ? `Wing: ${acc.Supplement__c},<br/>` : '<br/>'} <!-- add line break if no supplement -->
        ${acc.Building_Name_Conn__c ? `Building: ${acc.Building_Name_Conn__c},<br/>` : ''}
        ${streetLines ? `${streetLines},<br/> ` : '<br/>'}
        ${streetLines1 ? `${streetLines1},<br/> ` : ''}
${acc.Other_City__c || acc.District__c || acc.City__c || acc.Postal_Code__c
    ? `${acc.Other_City__c ? acc.Other_City__c + ', ' : ''}${acc.District__c ? acc.District__c + ', ' : ''}${acc.City__c ? acc.City__c + ' - ' : ''}${acc.Postal_Code__c || ''}<br/>`
    : '<br/>'}      <div style="margin-top: 10px;">
        ${acc.Phone || acc.Secondary_Telephone__c 
            ? `Tel: ${acc.Secondary_Telephone__c || ''} <br/> Mob: ${acc.Phone || ''}` 
            : `Tel: <br/> Mob: <br/>`}
        </div>
        
        <div style="margin-top: 10px;">
        <strong>Sub: ${this.caseAccountInfo.casetype || ''}</strong><br/>
       </div>
       <div style="margin-top: 10px;">
        <strong>
            ${acc.BP_Number__c ? `${bpOrLeadLabel}: ${acc.BP_Number__c}<br/>` : ''}
            Case / Docket Number: ${caseNumber}
        </strong>
        </div>
    </div>

    <div style="line-height: 1.3; margin-top: 10px; font-size: 14px;">
        <p>Dear Sir / Madam,</p>
        <p>This is in response to your letter received on ${this.formattedCreatedDate}, on the above mentioned subject.</p>
    </div>

</div>

<div style="font-family: 'Times New Roman', Times, serif;">
    ${templateBody}
</div>
`;

        this.richTextValue = fullContent;
        
        requestAnimationFrame(() => {
            const container = this.template.querySelector('[data-id="messageEditor"]');
            if (container) {
                container.innerHTML = fullContent;
            }
        });
    }

    handleEditableChange(event) {
        this.richTextValue = event.target.innerHTML; // updates richTextValue as user edits
    }

    handleRichTextChange(event) {
        this.richTextValue = event.detail.value;
        // Don't rebuild message content here!
    }

    // Handle font size change
    handleFontSizeChange(event) {
        this.selectedFontSize = event.detail.value;
        this.applyFontSize(this.selectedFontSize);
    }

    handleGeneratePDF() {
        if (!this.selectedTemplateId) {
            this.showToast('Error', 'Please select a template before generating PDF.', 'error');
            return;
        }

        const filledBody = this.richTextValue || '';
        insertTemplateData({
            templateBody: filledBody,
        })
        .then((result) => { // 'result' is the ID of the new FRL_Template_Data__c record
            // Successfully inserted the data, now generate the PDF using the ID
            return generatePDF({
                caseId: this.recordId,
                dataId: result,
                templateName: this.templateSubject
            });
        })
        .then(() => {
            // PDF generation succeeded
            this.showToast('Success', 'PDF generated and attached to Case.', 'success');
            this.closeQuickAction();
        })
        .catch(error => {
            // Handle any error from either insertTemplateData or generatePDF
            console.error('Error in process:', error);
            this.showToast('Error', 'Something went wrong while generating the PDF. See console for details.', 'error');
        });
    }
    async handlePreview() {
    if (!this.selectedTemplateId) {
        this.showToast('Error', 'Please select a template before previewing.', 'error');
        return;
    }

    const filledBody = this.richTextValue || '';

    try {
        const dataId = await insertTemplateData({ templateBody: filledBody });

        const vfPageName = this.templateSubject === 'Refund Template'
            ? 'FRL_PDFGeneratorPageV2'
            : 'FRL_PDFGeneratorPage';

        const previewUrl =
            `/apex/${vfPageName}?caseId=${this.recordId}` +
            `&dataId=${dataId}` +
            `&subject=${encodeURIComponent(this.templateSubject)}`;

        // Open modal
        await PdfPreviewModal.open({
            size: 'large',
            description: 'PDF Preview',
            previewUrl: previewUrl
        });

    } catch (error) {
        console.error('Preview error:', error);
        this.showToast('Error', 'Unable to generate preview.', 'error');
    }
}



    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
            mode: 'dismissable'
        }));
    }

    closeQuickAction() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const dateObj = new Date(dateString);
        const day = String(dateObj.getDate()).padStart(2, '0');
        const month = String(dateObj.getMonth() + 1).padStart(2, '0');
        const year = dateObj.getFullYear();
        return `${day}.${month}.${year}`;
    }

    // ---------------------------
    // 🔥 Bold / Italic / Underline Formatting
    // ---------------------------

    applyBold() {
        document.execCommand('bold', false, null);
        this.updateEditorValue();
    }

    applyItalic() {
        document.execCommand('italic', false, null);
        this.updateEditorValue();
    }

    applyUnderline() {
        document.execCommand('underline', false, null);
        this.updateEditorValue();
    }

    // ---------------------------
    // 🆕 Times New Roman Font Style
    // ---------------------------
    applyTimesNewRoman() {
        // Apply font family to selected text or current typing position
        document.execCommand('fontName', false, 'Times New Roman');
        this.updateEditorValue();
    }
    // Utility to sync editor content
    updateEditorValue() {
        const editor = this.template.querySelector('[data-id="messageEditor"]');
        if (editor) {
            this.richTextValue = editor.innerHTML;
        }
    }
}