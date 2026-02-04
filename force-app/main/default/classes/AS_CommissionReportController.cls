public without sharing class AS_CommissionReportController {

    public class ReportResponse {
        @AuraEnabled public String fileName;
        @AuraEnabled public String base64Data;
    }
 
    @AuraEnabled(cacheable=false)
    public static ReportResponse generateCommissionReport(
        Date startDate, 
        Date endDate, 
        String batchLot, 
        String fileContent // optional base64 encoded CSV/XML file with BP Numbers
    ) {
        ReportResponse resp = new ReportResponse();
        try {
            // ================== VALIDATION ==================
            if ((startDate == null || endDate == null) && String.isBlank(batchLot) && String.isBlank(fileContent)) {
                throw new AuraHandledException('Provide either Start Date & End Date OR Batch Lot No. OR upload BP file.');
            }
            if (startDate != null && endDate != null && endDate < startDate) {
                throw new AuraHandledException('End Date must be same or after Start Date.');
            }

            // ================== LOAD METADATA ==================
            List<Commission_Report__mdt> mdtsGlobal = [
                SELECT DeveloperName, Category__c, Percentage__c
                FROM Commission_Report__mdt
            ];
            System.debug('===== mdtsGlobal ===== ' + mdtsGlobal);

            String goCollectFlowLabel = System.Label.AS_GoCollectFlowLabel;
            List<String> lstGoCollectWorkType = goCollectFlowLabel.split(',');

            // ================== PARSE UPLOADED FILE ==================
            Set<String> bpNumbersFromFile = new Set<String>();
            if (!String.isBlank(fileContent)) {
                try {
                    // Decode Base64 content
                    String decoded = EncodingUtil.base64Decode(fileContent).toString();
                    // Simple CSV parsing: one BP Number per line
                    List<String> lines = decoded.split('\n');
                    for (String line : lines) {
                        String bp = line.trim();
                        if (!String.isBlank(bp)) bpNumbersFromFile.add(bp);
                    }
                } catch (Exception exFile) {
                    AS_ErrorLogger.log('AS_CommissionReportController', 'generateCommissionReport_fileParse', exFile, null);
                    throw new AuraHandledException('Failed to parse uploaded file: ' + exFile.getMessage());
                }
            }

            // ================== QUERY WORKORDERS ==================
            Map<Id, WorkOrder> uniqueWos = new Map<Id, WorkOrder>();
            List<WorkOrder> wos;

            if (!String.isBlank(batchLot)) {

                wos = [SELECT Id, RecordType.DeveloperName, Agency_Name_Formula__c, Batch_lot__c, Amount_Received__c, Due_Amount__c,
                            B4DUE__c, NOTDUE__c, X0_30__c, X31_60__c, X61_90__c, X91_180__c, X181_365__c, X1_2YR__c, X2_3YR__c, GR3YR__c,
                            WorkOrderNumber, Customer_BP_Number__c
                    FROM WorkOrder
                    WHERE RecordType.DeveloperName = 'MGL_R_T'
                    AND Batch_lot__c = :batchLot
                    AND Due_Amount__c != null AND Amount_Received__c != null
                    AND WorkType.Name IN :lstGoCollectWorkType];

            } else if (startDate != null && endDate != null) {
                Datetime startDT = Datetime.newInstance(startDate, Time.newInstance(0,0,0,0));
                DateTime endDT = DateTime.newInstance(endDate, Time.newInstance(23,59,59,999));

                wos = [SELECT Id, RecordType.DeveloperName, Agency_Name_Formula__c, Batch_lot__c, Amount_Received__c, Due_Amount__c,
                            B4DUE__c, NOTDUE__c, X0_30__c, X31_60__c, X61_90__c, X91_180__c, X181_365__c, X1_2YR__c, X2_3YR__c, GR3YR__c,
                            WorkOrderNumber, Customer_BP_Number__c
                    FROM WorkOrder
                    WHERE RecordType.DeveloperName = 'MGL_R_T'
                    AND StartDate >= :startDT AND EndDate <= :endDT
                    AND Agency_Name_Formula__c != null
                    AND Due_Amount__c != null AND Amount_Received__c != null
                    AND WorkType.Name IN :lstGoCollectWorkType];
            }

            // Add queried WorkOrders to map for uniqueness
            if (wos != null) {
                for (WorkOrder w : wos) uniqueWos.put(w.Id, w);
            }

            System.debug('===== bpNumbersFromFile ===== ' + bpNumbersFromFile);

            // Query WorkOrders from BP Numbers if provided
            if (!bpNumbersFromFile.isEmpty()) {

                List<WorkOrder> wosFromBP = [SELECT Id, RecordType.DeveloperName, Agency_Name_Formula__c, Batch_lot__c, Amount_Received__c, Due_Amount__c,
                                                    B4DUE__c, NOTDUE__c, X0_30__c, X31_60__c, X61_90__c, X91_180__c, X181_365__c, X1_2YR__c, X2_3YR__c, GR3YR__c,
                                                    WorkOrderNumber, Customer_BP_Number__c
                                            FROM WorkOrder
                                            WHERE RecordType.DeveloperName = 'MGL_R_T'
                                            AND Customer_BP_Number__c IN :bpNumbersFromFile
                                            AND Due_Amount__c != null AND Amount_Received__c != null
                                            AND WorkType.Name IN :lstGoCollectWorkType];

                for (WorkOrder w : wosFromBP) uniqueWos.put(w.Id, w);

            }

            // Final unique WorkOrders list
            List<WorkOrder> finalWos = new List<WorkOrder>(uniqueWos.values());
            System.debug('===== finalWos ===== ' + finalWos);

            // categories and map
            List<String> categories = new List<String>{
                'B4Due & Not Due','0 - 90 days','91 - 180 days','181 - 365 days','Above 366 Days'
            };

            Map<String, Map<String, Decimal>> agencyCategorySums = new Map<String, Map<String, Decimal>>();

            for (WorkOrder w : finalWos) {
                try {

                    String agency = w.Agency_Name_Formula__c == null ? 'UNKNOWN' : w.Agency_Name_Formula__c;

                    if (!agencyCategorySums.containsKey(agency)) {
                        Map<String, Decimal> init = new Map<String, Decimal>();
                        for (String c : categories) init.put(c, 0);
                        agencyCategorySums.put(agency, init);
                    }

                    Map<String, Decimal> sums = agencyCategorySums.get(agency);

                    Decimal amtRec = safeDec(w.Amount_Received__c); //2186
                    Decimal due = safeDec(w.Due_Amount__c); //2186

                    Decimal b4 = safeDec(w.B4DUE__c); //0
                    Decimal notDue = safeDec(w.NOTDUE__c); //1116
                    Decimal x0 = safeDec(w.X0_30__c);
                    Decimal x31 = safeDec(w.X31_60__c);
                    Decimal x61 = safeDec(w.X61_90__c); //1070
                    Decimal x91 = safeDec(w.X91_180__c);
                    Decimal x181 = safeDec(w.X181_365__c);
                    Decimal x1_2 = safeDec(w.X1_2YR__c);
                    Decimal x2_3 = safeDec(w.X2_3YR__c);
                    Decimal gr3 = safeDec(w.GR3YR__c);

                    AgencyCollectionAllocator alloc = new AgencyCollectionAllocator(
                        amtRec, due, b4, notDue, x0, x31, x61, x91, x181, x1_2, x2_3, gr3
                    );
                    alloc.allocateAndProduceBuckets();

                    sums.put('B4Due & Not Due', sums.get('B4Due & Not Due') + nonNeg(alloc.cB4NotDue));
                    sums.put('0 - 90 days', sums.get('0 - 90 days') + nonNeg(alloc.c0_90));
                    sums.put('91 - 180 days', sums.get('91 - 180 days') + nonNeg(alloc.c91_180));
                    sums.put('181 - 365 days', sums.get('181 - 365 days') + nonNeg(alloc.c181_365));
                    sums.put('Above 366 Days', sums.get('Above 366 Days') + nonNeg(alloc.cAbove366));

                } catch (Exception exInner) {
                    AS_ErrorLogger.log('AS_CommissionReportController',
                        'generateCommissionReport_processingWorkOrder', exInner, w.Id);
                }
            }

            // ------------- SpreadsheetML -------------
            List<String> xml = new List<String>();

            xml.add('<?xml version="1.0"?>');
            xml.add('<?mso-application progid="Excel.Sheet"?>');
            xml.add('<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" '
                   +'xmlns:o="urn:schemas-microsoft-com:office:office" '
                   +'xmlns:x="urn:schemas-microsoft-com:office:excel" '
                   +'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">');

            // Styles
            xml.add('<Styles>');
            xml.add('<Style ss:ID="AllBorder"><Borders>'
                    + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
                    + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
                    + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
                    + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
                    + '</Borders></Style>');
            xml.add('<Style ss:ID="Pad" ss:Parent="AllBorder"><Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1" ss:Indent="1"/></Style>');
            xml.add('<Style ss:ID="Hdr" ss:Parent="Pad"><Font ss:Bold="0" ss:Size="12"/></Style>');
            xml.add('<Style ss:ID="HdrBold" ss:Parent="Hdr"><Font ss:Bold="1" ss:Size="12"/></Style>');
            xml.add('<Style ss:ID="OrangeHdr" ss:Parent="Pad"><Font ss:Bold="1"/><Interior ss:Color="#efa983" ss:Pattern="Solid"/></Style>');
            xml.add('<Style ss:ID="Right" ss:Parent="Pad"><Alignment ss:Horizontal="Right" ss:WrapText="1"/></Style>');
            xml.add('<Style ss:ID="Tot" ss:Parent="Pad"><Font ss:Bold="1"/><Interior ss:Color="#efa983" ss:Pattern="Solid"/></Style>');
            xml.add('</Styles>');

            xml.add('<Worksheet ss:Name="Commission Report">');
            xml.add('<Table>');

            xml.add('<Column ss:AutoFitWidth="1"/>'); 
            xml.add('<Column ss:Width="200"/>');      

            List<String> agencies = new List<String>(agencyCategorySums.keySet());
            agencies.sort();

            for (Integer i=0;i<agencies.size();i++) {
                xml.add('<Column ss:Width="100"/>');
                xml.add('<Column ss:Width="80"/>');
                xml.add('<Column ss:Width="100"/>');
            }

            xml.add('<Column ss:Width="100"/>');
            xml.add('<Column ss:Width="80"/>');
            xml.add('<Column ss:Width="100"/>');

            Integer mergeAcross = 2 + agencies.size()*3;

            xml.add('<Row ss:Height="24">');
            xml.add('<Cell ss:MergeAcross="'+mergeAcross+'" ss:StyleID="HdrBold"><Data ss:Type="String">&#160;&#160;Mahanagar Gas Limited&#160;&#160;</Data></Cell>');
            xml.add('</Row>');

            xml.add('<Row ss:Height="20">');
            xml.add('<Cell ss:MergeAcross="'+mergeAcross+'" ss:StyleID="Hdr"><Data ss:Type="String">&#160;&#160;Calculation of Agency Commission&#160;&#160;</Data></Cell>');
            xml.add('</Row>');

            String periodLabel = 
                (startDate!=null && endDate!=null) ?
                'Collection Period ' + startDate.format() + ' to ' + endDate.format() :
                'Batch Lot : ' + batchLot;

            xml.add('<Row ss:Height="20">');
            xml.add('<Cell ss:MergeAcross="'+mergeAcross+'" ss:StyleID="HdrBold"><Data ss:Type="String">&#160;&#160;'+escapeXml(periodLabel)+'&#160;&#160;</Data></Cell>');
            xml.add('</Row>');

            xml.add('<Row ss:Height="8"/>');

            xml.add('<Row ss:Height="22">');
            xml.add('<Cell ss:StyleID="OrangeHdr"><Data ss:Type="String">&#160;&#160;Sr.No.&#160;&#160;</Data></Cell>');
            xml.add('<Cell ss:StyleID="OrangeHdr"><Data ss:Type="String">&#160;&#160;Collection SORs as per SAP&#160;&#160;</Data></Cell>');
            for (String ag : agencies)
                xml.add('<Cell ss:MergeAcross="2" ss:StyleID="OrangeHdr"><Data ss:Type="String">&#160;&#160;'+escapeXml(ag)+'&#160;&#160;</Data></Cell>');
            xml.add('<Cell ss:MergeAcross="2" ss:StyleID="OrangeHdr"><Data ss:Type="String">&#160;&#160;Total&#160;&#160;</Data></Cell>');
            xml.add('</Row>');

            xml.add('<Row ss:Height="20">');
            xml.add('<Cell ss:StyleID="OrangeHdr"/>');
            xml.add('<Cell ss:StyleID="OrangeHdr"/>');
            for (String ag : agencies) {
                xml.add('<Cell ss:StyleID="OrangeHdr"><Data ss:Type="String">&#160;&#160;Amt Collected&#160;&#160;</Data></Cell>');
                xml.add('<Cell ss:StyleID="OrangeHdr"><Data ss:Type="String">&#160;&#160;Comm %&#160;&#160;</Data></Cell>');
                xml.add('<Cell ss:StyleID="OrangeHdr"><Data ss:Type="String">&#160;&#160;Comm Amt&#160;&#160;</Data></Cell>');
            }
            xml.add('<Cell ss:StyleID="OrangeHdr"><Data ss:Type="String">&#160;&#160;Amt Collected&#160;&#160;</Data></Cell>');
            xml.add('<Cell ss:StyleID="OrangeHdr"><Data ss:Type="String">&#160;&#160;Comm %&#160;&#160;</Data></Cell>');
            xml.add('<Cell ss:StyleID="OrangeHdr"><Data ss:Type="String">&#160;&#160;Comm Amt&#160;&#160;</Data></Cell>');
            xml.add('</Row>');

            Map<String, Decimal> grandAmtPerCategory = new Map<String, Decimal>();
            Map<String, Decimal> grandCommPerCategory = new Map<String, Decimal>();
            for (String cat : categories) {
                grandAmtPerCategory.put(cat, 0);
                grandCommPerCategory.put(cat, 0);
            }

            for (Integer rowIdx=0; rowIdx<categories.size(); rowIdx++) {
                String cat = categories[rowIdx];
                xml.add('<Row>');
                xml.add('<Cell ss:StyleID="Pad"><Data ss:Type="Number">'+String.valueOf(rowIdx+1)+'</Data></Cell>');
                xml.add('<Cell ss:StyleID="Pad"><Data ss:Type="String">&#160;&#160;'+escapeXml(cat)+'&#160;&#160;</Data></Cell>');

                Decimal totalAmtThisRow = 0;
                Decimal totalCommThisRow = 0;

                Decimal commonPct = 0;
                for (Commission_Report__mdt m : mdtsGlobal)
                    if (m.Category__c == cat) { commonPct = safeDec(m.Percentage__c); break; }

                for (String ag : agencies) {
                    Map<String, Decimal> sums = agencyCategorySums.get(ag);
                    Decimal amt = sums.get(cat);
                    totalAmtThisRow += amt;

                    Decimal commAmt = (amt * commonPct) / 100;
                    totalCommThisRow += commAmt;

                    grandAmtPerCategory.put(cat, grandAmtPerCategory.get(cat) + amt);
                    grandCommPerCategory.put(cat, grandCommPerCategory.get(cat) + commAmt);

                    xml.add('<Cell ss:StyleID="Right"><Data ss:Type="String">&#160;&#160;'+escapeXml(formatForXmlNumber(amt))+'&#160;&#160;</Data></Cell>');
                    xml.add('<Cell ss:StyleID="Right"><Data ss:Type="String">&#160;&#160;'+escapeXml(formatForXmlNumber(commonPct))+'&#160;&#160;</Data></Cell>');
                    xml.add('<Cell ss:StyleID="Right"><Data ss:Type="String">&#160;&#160;'+escapeXml(formatForXmlNumber(commAmt))+'&#160;&#160;</Data></Cell>');
                }

                xml.add('<Cell ss:StyleID="Right"><Data ss:Type="String">&#160;&#160;'+escapeXml(formatForXmlNumber(totalAmtThisRow))+'&#160;&#160;</Data></Cell>');
                xml.add('<Cell ss:StyleID="Right"><Data ss:Type="String">&#160;&#160;'+escapeXml(formatForXmlNumber(commonPct))+'&#160;&#160;</Data></Cell>');
                xml.add('<Cell ss:StyleID="Right"><Data ss:Type="String">&#160;&#160;'+escapeXml(formatForXmlNumber(totalCommThisRow))+'&#160;&#160;</Data></Cell>');
                xml.add('</Row>');
            }

            List<Decimal> agencyAmtTotals = new List<Decimal>();
            List<Decimal> agencyCommTotals = new List<Decimal>();

            for (String ag : agencies) {
                Decimal aTot = 0, cTot = 0;
                Map<String, Decimal> sums = agencyCategorySums.get(ag);
                for (String cat : categories) {
                    Decimal amt = sums.get(cat);
                    aTot += amt;

                    Decimal pct = 0;
                    for (Commission_Report__mdt m : mdtsGlobal)
                        if (m.Category__c == cat) { pct = safeDec(m.Percentage__c); break; }

                    cTot += (amt * pct) / 100;
                }
                agencyAmtTotals.add(aTot);
                agencyCommTotals.add(cTot);
            }

            Decimal grandAmt = 0;
            Decimal grandComm = 0;
            for (Decimal d : agencyAmtTotals) grandAmt += d;
            for (Decimal d : agencyCommTotals) grandComm += d;

            xml.add('<Row ss:Height="20">');
            xml.add('<Cell ss:StyleID="Tot"/>');
            xml.add('<Cell ss:StyleID="Tot"><Data ss:Type="String">&#160;&#160;Total (A)&#160;&#160;</Data></Cell>');

            for (Integer i=0;i<agencies.size();i++) {
                Decimal aVal = agencyAmtTotals[i];
                Decimal cVal = agencyCommTotals[i];
                Decimal pctVal = (aVal == 0) ? 0 : (cVal / aVal * 100);

                xml.add('<Cell ss:StyleID="Tot"><Data ss:Type="String">&#160;&#160;'+escapeXml(formatForXmlNumber(aVal))+'&#160;&#160;</Data></Cell>');
                xml.add('<Cell ss:StyleID="Tot"/>');
                xml.add('<Cell ss:StyleID="Tot"><Data ss:Type="String">&#160;&#160;'+escapeXml(formatForXmlNumber(cVal))+'&#160;&#160;</Data></Cell>');
            }

            xml.add('<Cell ss:StyleID="Tot"><Data ss:Type="String">&#160;&#160;'+escapeXml(formatForXmlNumber(grandAmt))+'&#160;&#160;</Data></Cell>');
            xml.add('<Cell ss:StyleID="Tot"/>');
            xml.add('<Cell ss:StyleID="Tot"><Data ss:Type="String">&#160;&#160;'+escapeXml(formatForXmlNumber(grandComm))+'&#160;&#160;</Data></Cell>');
            xml.add('</Row>');

            xml.add('</Table>');
            xml.add('</Worksheet>');
            xml.add('</Workbook>');

            Blob b = Blob.valueOf(String.join(xml, ''));
            resp.base64Data = EncodingUtil.base64Encode(b);
            resp.fileName = 'Commission_Report_' + Date.today().format() + '.xls';
            return resp;

        } catch (Exception ex) {
            AS_ErrorLogger.log('AS_CommissionReportController','generateCommissionReport', ex, null);
            throw new AuraHandledException('Failed to generate report: ' + ex.getMessage());
        }
    }

    // ----------------- AgencyCollectionAllocator -----------------
    private class AgencyCollectionAllocator {
        public Decimal amtRec;
        public Decimal due;

        public Decimal b4;
        public Decimal notDue;
        public Decimal x0;
        public Decimal x31;
        public Decimal x61;
        public Decimal x91;
        public Decimal x181;
        public Decimal x1_2;
        public Decimal x2_3;
        public Decimal gr3;

        public Decimal cB4NotDue = 0;
        public Decimal c0_90 = 0;
        public Decimal c91_180 = 0;
        public Decimal c181_365 = 0;
        public Decimal cAbove366 = 0;

        private Decimal balance = 0;

        public AgencyCollectionAllocator(
            Decimal amtRec, Decimal due, Decimal b4, Decimal notDue, Decimal x0, Decimal x31,
            Decimal x61, Decimal x91, Decimal x181, Decimal x1_2, Decimal x2_3, Decimal gr3
        ) {
            this.amtRec = safeDec(amtRec); //2186
            this.due = safeDec(due); //2186
            this.b4 = safeDec(b4);
            this.notDue = safeDec(notDue); //1116
            this.x0 = safeDec(x0);
            this.x31 = safeDec(x31);
            this.x61 = safeDec(x61); //1070
            this.x91 = safeDec(x91);
            this.x181 = safeDec(x181);
            this.x1_2 = safeDec(x1_2);
            this.x2_3 = safeDec(x2_3);
            this.gr3 = safeDec(gr3);
        }

        public void allocateAndProduceBuckets() {
            try {
                if (amtRec == 0) return;

                if (amtRec == due) {
                    balance = amtRec;
                    applyBucket(b4, 'B4');
                    applyBucket(notDue, 'B4');
                    applyBucket(x0, '0_90');
                    applyBucket(x31, '0_90');
                    applyBucket(x61, '0_90');
                    applyBucket(x91, '91_180');
                    applyBucket(x181, '181_365');
                    applyBucket(x1_2, 'Above366');
                    applyBucket(x2_3, 'Above366');
                    applyBucket(gr3, 'Above366');

                } else if (amtRec > due) {
                    cB4NotDue = amtRec - due;
                    balance = due;

                    applyBucket(b4, 'B4');
                    applyBucket(notDue, 'B4');
                    applyBucket(x0, '0_90');
                    applyBucket(x31, '0_90');
                    applyBucket(x61, '0_90');
                    applyBucket(x91, '91_180');
                    applyBucket(x181, '181_365');
                    applyBucket(x1_2, 'Above366');
                    applyBucket(x2_3, 'Above366');
                    applyBucket(gr3, 'Above366');

                } else {
                    balance = amtRec;
                    applyBucket(b4, 'B4');
                    applyBucket(notDue, 'B4');
                    applyBucket(x0, '0_90');
                    applyBucket(x31, '0_90');
                    applyBucket(x61, '0_90');
                    applyBucket(x91, '91_180');
                    applyBucket(x181, '181_365');
                    applyBucket(x1_2, 'Above366');
                    applyBucket(x2_3, 'Above366');
                    applyBucket(gr3, 'Above366');
                }

            } catch (Exception ex) {
                AS_ErrorLogger.log('AS_CommissionReportController',
                    'AgencyCollectionAllocator_allocateAndProduceBuckets', ex, null);
            }
        }

        private void applyBucket(Decimal bucketValue, String bucketName) {
            if (balance <= 0) return;
            Decimal toApply = bucketValue > balance ? balance : bucketValue;
            balance -= toApply;

            switch on bucketName {
                when 'B4'       { cB4NotDue += toApply; }
                when '0_90'     { c0_90 += toApply; }
                when '91_180'   { c91_180 += toApply; }
                when '181_365'  { c181_365 += toApply; }
                when 'Above366' { cAbove366 += toApply; }
                when else       {}
            }
        }
    }

    // ----------------- UTILITIES -----------------
    private static Decimal safeDec(Object o) {
        if (o == null) return 0;
        if (o instanceof Decimal) return (Decimal)o;
        if (o instanceof Double) return Decimal.valueOf(String.valueOf((Double)o));
        if (o instanceof Integer) return Decimal.valueOf((Integer)o);
        try { return Decimal.valueOf(String.valueOf(o)); }
        catch (Exception e) { return 0; }
    }

    private static Decimal nonNeg(Decimal d) {
        return (d == null || d < 0) ? 0 : d;
    }

    private static String escapeXml(String s) {
        if (s == null) return '';
        return s.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')
                .replace('"','&quot;').replace('\'','&apos;');
    }

    private static String formatForXmlNumber(Decimal d) {
        if (d == null) return '0';
        try { return String.valueOf(d.setScale(2)); }
        catch (Exception e) { return String.valueOf(d); }
    }
}