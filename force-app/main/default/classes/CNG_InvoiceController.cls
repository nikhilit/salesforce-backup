public with sharing class CNG_InvoiceController {

   public static String formatIndianDecimal(Decimal amount) {
    String s = String.valueOf(amount.setScale(2));
    List<String> parts = s.split('\\.');
    String num = parts[0];
    String dec = parts.size() > 1 ? parts[1] : '00';

    String last3 = num.substring(Math.max(0, num.length() - 3));
    String rest = num.substring(0, Math.max(0, num.length() - 3));

    if (rest.length() > 0) {
        rest = rest.replaceAll('(\\d)(?=(\\d{2})+$)', '$1,');
        return rest + ',' + last3 + '.' + dec;
    }
    return last3 + '.' + dec;
}
public static String formatIndianNumber(Decimal amount) {
    if (amount == null) return '0';

    Long num = amount.setScale(0, RoundingMode.HALF_UP).longValue();
    String strNum = String.valueOf(num);

    String last3 = strNum.substring(Math.max(0, strNum.length() - 3));
    String rest = strNum.substring(0, Math.max(0, strNum.length() - 3));

    if (rest.length() > 0) {
        // Insert commas every 2 digits from right in the rest part
        rest = rest.replaceAll('(\\d)(?=(\\d{2})+$)', '$1,');
        return rest + ',' + last3;
    }
    return last3;
}

    public Invoice__c invoice { get; private set; }
    public List<Invoice_Line_Item__c> lineItems { get; private set; }

    // This will store HSN → aggregated values
    public List<HSNWrapper> hsnGroups { get; private set; }

    public CNG_InvoiceController(ApexPages.StandardController sc) {

        invoice = [
            SELECT Id, Name, CreatedDate,
                   Consignee__c, Buyer__c,
                   Work_Order_No__c, Vendor_Code__c,
                   Station__c, Station__r.Name,Station__r.GST_No__c,Station__r.BillingStreet,Station__r.BillingCity,Station__r.BillingState,Station__r.BillingPostalCode,Station__r.BillingCountry,
                   Billing_Period__c,
                   Taxable_Amount__c,
                   CGST__c, CGST_Amount__c,
                   SGST__c, SGST_Amount__c,
                   Total_Tax_Amount__c,
                   Total_Quantity__c,
                   Total_Amount__c,
                   Round_Off__c
            FROM Invoice__c
            WHERE Id = :sc.getId()
        ];

       lineItems = [
    SELECT Amount__c,
           Description_of_Services__c,
           HSN_SAC__c,
           Quantity__c,
           Rate__c,
           Invoice__r.CGST__c,
           CGST_Amount__c,
           Invoice__r.SGST__c,
           SGST_Amount__c,
           Invoice__r.Total_Tax_Amount__c
    FROM Invoice_Line_Item__c
    WHERE Invoice__c = :sc.getId()
    ORDER BY CreatedDate
];

        aggregateLineItems();
    }

    // =========================
    // Aggregate by HSN
    // =========================
    private void aggregateLineItems() {
        Map<String, HSNWrapper> mapHSN = new Map<String, HSNWrapper>();

        for (Invoice_Line_Item__c item : lineItems) {
            String hsn = item.HSN_SAC__c != null ? item.HSN_SAC__c : 'Unknown';
            if (!mapHSN.containsKey(hsn)) {
                mapHSN.put(hsn, new HSNWrapper(hsn));
            }
            mapHSN.get(hsn).addItem(item);
        }

        hsnGroups = new List<HSNWrapper>();
        hsnGroups.addAll(mapHSN.values());
    }
    

    // =========================
    // HSN Wrapper Class
    // =========================
    public class HSNWrapper {
        public String hsnCode { get; set; }
        public Decimal taxableAmount { get; set; }
        public String formattedTaxableAmount {get;set;}
        public Decimal cgstRate { get; set; }
        public Decimal cgstAmount { get; set; }
        public Decimal sgstRate { get; set; }
        public Decimal sgstAmount { get; set; }
        public Decimal totalTax { get; set; }

        public HSNWrapper(String hsn) {
            hsnCode = hsn;
            taxableAmount = 0;
            formattedTaxableAmount='';
            cgstRate = 0;
            cgstAmount = 0;
            sgstRate = 0;
            sgstAmount = 0;
            totalTax = 0;
        }

        public void addItem(Invoice_Line_Item__c item) {
            taxableAmount += item.Amount__c != null ? item.Amount__c : 0;
            // Assuming CGST/SGST rates same for invoice lines (otherwise store per line)
            cgstRate = item.Invoice__r.CGST__c != null ? item.Invoice__r.CGST__c : 0;
            cgstAmount += item.CGST_Amount__c != null ? item.CGST_Amount__c : 0;
            sgstRate = item.Invoice__r.SGST__c != null ? item.Invoice__r.SGST__c : 0;
            sgstAmount += item.SGST_Amount__c != null ? item.SGST_Amount__c : 0;
            totalTax += item.Invoice__r.Total_Tax_Amount__c != null ? item.Invoice__r.Total_Tax_Amount__c : 0;
            formattedTaxableAmount=formatIndianDecimal(taxableAmount);
        }
    }

    // =========================
    // Amount in Words
    // =========================
    public String amountInWords {
        get { return convertToWords(invoice.Total_Tax_Amount__c); }
    }

    public String formattedTaxableAmount{
         get { return formatIndianDecimal(invoice.Taxable_Amount__c); }
    }

     public String formattedTotalQuantity{
         get { return formatIndianNumber(invoice.Total_Quantity__c); }
    }
    
     public String formattedTotalAmount{
         get { return formatIndianNumber(invoice.Total_Amount__c); }
    }
    
    
    public String totalAmount {
        get { return convertToWords(invoice.Total_Amount__c); }
    }

    private static String convertToWords(Decimal amount) {
        if (amount == null || amount == 0) return 'Zero Rupees Only';

        Long rupees = amount.longValue();
        Integer paise = Integer.valueOf(((amount - rupees) * 100).round());

        String words = convert(rupees) + ' Rupees';
        if (paise > 0) words += ' and ' + convert(paise) + ' Paise';
        return words + ' Only';
    }

    private static String convert(Long num) {
        String[] unit = new String[]{
            '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
            'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
            'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
        };
        String[] tens = new String[]{
            '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
            'Sixty', 'Seventy', 'Eighty', 'Ninety'
        };
        if (num < 20) return unit[num.intValue()];
        if (num < 100) return tens[(Integer)(num / 10)] + ((Math.mod(num, 10) > 0) ? ' ' + unit[Math.mod(num, 10).intValue()] : '');
        if (num < 1000) return unit[(Integer)(num / 100)] + ' Hundred ' + convert(Math.mod(num, 100));
        if (num < 100000) return convert(num / 1000) + ' Thousand ' + convert(Math.mod(num, 1000));
        if (num < 10000000) return convert(num / 100000) + ' Lakh ' + convert(Math.mod(num, 100000));
        return convert(num / 10000000) + ' Crore ' + convert(Math.mod(num, 10000000));
    }
}