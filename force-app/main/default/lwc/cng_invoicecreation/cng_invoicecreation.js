import { LightningElement, track,api } from 'lwc';
import generateInvoice from '@salesforce/apex/CNG_ProfileCardController.generateInvoice';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import stationDetails from '@salesforce/apex/CNG_ProfileCardController.stationDetails';
import getBillingInfo from '@salesforce/apex/CNG_ProfileCardController.getBillingInfo';


export default class Cng_invoicecreation extends LightningElement {
    @track invoiceNumber;
    @track invoiceDate;
    @track billDuration;
    @track stationName;
@api recordId;
@track isModalOpen = false;
    @track billDurationOptions = [];

    connectedCallback() {
        // this.generateBiWeeklyOptions();
        this.loadBillingPeriods();
        this.stationDetailsFunc();
    }
    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
        this.handleClear();
    }

    loadBillingPeriods() {
        getBillingInfo({ stationId: this.recordId })
            .then(result => {
                if (!result) return;

                const cycle = result.billingCycle;

                // 🔥 normalize all existing invoice periods
                const usedPeriodKeys = new Set(
                    (result.existingBillingPeriods || []).map(p =>
                        this.normalizePeriod(p)
                    )
                );

                if (cycle === 'Monthly') {
                    this.generateMonthlyOptions(usedPeriodKeys);
                } else {
                    this.generateFortnightlyOptions(usedPeriodKeys);
                }
            })
            .catch(err => console.error(err));
    }


    generateMonthlyOptions(usedPeriodKeys) {
        const today = new Date();
        let options = [];

        for (let i = 0; i < 3; i++) {
            const d = new Date(today.getFullYear(), today.getMonth() - i, 1);
            const year = d.getFullYear();
            const month = d.getMonth() + 1;
            const lastDay = new Date(year, month, 0).getDate();
            const monthName = d.toLocaleString('default', { month: 'short' });

            const start = `01`;
            const end = String(lastDay).padStart(2, '0');
            const m = String(month).padStart(2, '0');

            const key = `${year}-${m}-${start}|${year}-${m}-${end}`;

            if (!usedPeriodKeys.has(key)) {
                options.push({
                    label: `1-${lastDay} ${monthName} ${year}`,
                    value: key
                });
            }
        }

        this.billDurationOptions = options;
    }


    normalizePeriod(periodStr) {
        const [start, end] = periodStr.split(' to ');
        const [sd, sm, sy] = start.split('-');
        const [ed, em, ey] = end.split('-');

        return `${sy}-${sm}-${sd}|${ey}-${em}-${ed}`;
    }


    generateFortnightlyOptions(usedPeriodKeys) {
        const today = new Date();
        let options = [];

        for (let i = 0; i < 3; i++) {
            const d = new Date(today.getFullYear(), today.getMonth() - i, 1);
            const year = d.getFullYear();
            const month = d.getMonth() + 1;
            const monthName = d.toLocaleString('default', { month: 'short' });
            const lastDay = new Date(year, month, 0).getDate();

            const segments = [
                { start: 1, end: 15 },
                { start: 16, end: lastDay }
            ];

            segments.forEach(seg => {
                const s = String(seg.start).padStart(2, '0');
                const e = String(seg.end).padStart(2, '0');
                const m = String(month).padStart(2, '0');

                const key = `${year}-${m}-${s}|${year}-${m}-${e}`;

                if (
                    new Date(year, month - 1, seg.start) <= today &&
                    !usedPeriodKeys.has(key)
                ) {
                    options.push({
                        label: `${seg.start}-${seg.end} ${monthName} ${year}`,
                        value: key
                    });
                }
            });
        }

        this.billDurationOptions = options.sort(
            (a, b) => new Date(b.value.split('|')[0]) - new Date(a.value.split('|')[0])
        );
    }





    generateBiWeeklyOptions() {
        const today = new Date();
        let options = [];

        // Current month & previous month
        const monthsToProcess = [
            new Date(today.getFullYear(), today.getMonth(), 1),
            new Date(today.getFullYear(), today.getMonth() - 1, 1)
        ];

        monthsToProcess.forEach(monthDate => {
            options.push(...this.getValidBiWeeklyRanges(monthDate, today));
        });

        // 🔥 Latest segment first
        options.sort((a, b) => new Date(b.startDate) - new Date(a.startDate));

        // Remove helper field before assigning
        this.billDurationOptions = options.map(opt => ({
            label: opt.label,
            value: opt.value
        }));
    }

    getValidBiWeeklyRanges(monthDate, today) {
        const year = monthDate.getFullYear();
        const month = monthDate.getMonth();
        const monthName = monthDate.toLocaleString('default', { month: 'short' });

        const lastDay = new Date(year, month + 1, 0).getDate();

        const segments = [
            {
                start: new Date(year, month, 1),
                end: new Date(year, month, 16),
                label: `1-16 ${monthName} ${year}`,
                value: `${year}-${month + 1}-01|${year}-${month + 1}-16`
            },
            {
                start: new Date(year, month, 17),
                end: new Date(year, month, lastDay),
                label: `17-${lastDay} ${monthName} ${year}`,
                value: `${year}-${month + 1}-17|${year}-${month + 1}-${lastDay}`
            }
        ];

        // ✅ Only current & past segments
        return segments
            .filter(seg => seg.start <= today)
            .map(seg => ({
                label: seg.label,
                value: seg.value,
                startDate: seg.start
            }));
    }

    handleChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }
    stationDetailsFunc(){
         stationDetails({stationId:this.recordId
        })
        .then(result => {
           this.stationName=result;
        }
) .catch(error => {
            console.error(error.body.message);
      });
    }

    handleSubmit() {
        const formattedBillDuration = this.formatDateRange(this.billDuration);
        generateInvoice({
            invoiceNumber: this.invoiceNumber,
            invoiceDate: this.invoiceDate,
            billDuration: formattedBillDuration,
            stationId:this.recordId
        })
        .then(result => {
            console.log(result);
            this.dispatchEvent(
    new ShowToastEvent({
        title: 'Success',
        message: 'Invoice generated successfully',
        variant: 'success'
    })
);
window.location.reload();
        })
        .catch(error => {
            console.error(error.body.message);
            this.dispatchEvent(
    new ShowToastEvent({
        title: 'Error',
        message: error.body?.message || 'Something went wrong',
        variant: 'error'
    })
);

        });
    }
    handleClear(){
        this.invoiceNumber='';
        this.invoiceDate='';
        this.billDuration='';
    }
    formatDateRange(dateRange) {
    if (!dateRange) return null;

    const [start, end] = dateRange.split('|');

    return `${this.formatDate(start)} to ${this.formatDate(end)}`;
}

formatDate(dateStr) {
    const date = new Date(dateStr);
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();

    return `${day}-${month}-${year}`;
}

}