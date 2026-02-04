@IsTest
public class ReceivableControllerTest {

    // ---------- MOCK CLASS ----------
    private class SAPHttpMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        SAPHttpMock(Integer code, String bodyStr) {
            statusCode = code;
            body = bodyStr;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(body);
            res.setStatusCode(statusCode);
            return res;
        }
    }

    // ---------- HELPER: CREATE ACCOUNT ----------
    private static Account createTestAccount(String bpNumber) {
        Account acc = new Account(
            Name = 'Test Account',
            BP_Number__c = bpNumber
        );
        insert acc;
        return acc;
    }

    // ---------- TEST: fetchSAPDataReceivables SUCCESS ----------
    @IsTest
    static void testFetchSAPDataReceivables_Success() {
        Test.startTest();

        String mockBody = '{"statusMessage":"OK","bpId":"12345","sapData":[{"BUSPARTNER":"12345","CONT_ACCT":"CA001","DOC_NO":"DOC001","HTEXT":"Receivable","BUDAT":"2025-08-01","BLDAT":"2025-08-02","NET_DATE":"2025-08-15","AMOUNT":100.50,"CurrencyCode":"INR","GUID_R":"G001","NDATE":"2025-08-15"}]}';
        Test.setMock(HttpCalloutMock.class, new SAPHttpMock(200, mockBody));

        ReceivableController.SAP_Response resp = ReceivableController.fetchSAPDataReceivables('12345');

        // Access wrapper fields for coverage
        if (resp != null && resp.sapData != null && !resp.sapData.isEmpty()) {
            ReceivableController.SAP_Data sd = resp.sapData[0];
            System.debug(sd.BUSPARTNER);
            System.debug(sd.CONT_ACCT);
            System.debug(sd.DOC_NO);
            System.debug(sd.HTEXT);
            System.debug(sd.GUID_R);
            System.debug(sd.CurrencyCode);
            System.debug(sd.AMOUNT);
            System.debug(sd.NDATE);
            System.debug(sd.BUDAT);
            System.debug(sd.BLDAT);
            System.debug(sd.NET_DATE);
        }

        Test.stopTest();
    }

   
    // ---------- TEST: fetchSAPDataChronologies ----------
    @IsTest
    static void testFetchSAPDataChronologies() {
        Account acc = createTestAccount('BP123');

        String mockBody = '{' +
            '"salesforceStatus":"OK",' +
            '"bpId":"BP123",' +
            '"sapData":[{' +
                '"BUSPARTNER":"BP123",' +
                '"CONT_ACCT":"CA002",' +
                '"DOC_NO":"DOCX",' +
                '"GUID_C":"G002",' +
                '"HTEXT":"Check Lot",' +
                '"DEBIT":200,' +
                '"CREDIT":50,' +
                '"DOWN":300,' +
                '"CurrencyCode":"INR",' +
                '"BUDAT":"2025-08-01",' +
                '"BLDAT":"2025-08-02",' +
                '"NET_DATE":"2025-08-15",' +
                '"CHCKN":"CH001",' +
                '"ZSOP":"Z001",' +
                '"ZSOP_TEXT":"Special Operation",' +
                '"Z_CH_DATE":"2025-08-10",' +
                '"Z_CH_REC_DATE":"2025-08-12",' +
                '"Z_BANK_NAME":"Test Bank",' +
                '"AMOUNT":999.99,' +
                '"DDATE":"2025-08-20",' +
                '"PDATE":"2025-08-21",' +
                '"NDATE":"2025-08-22",' +
                '"RTEXT":"Receivable Text",' +
                '"MENGE":"10",' +
                '"MEINS":"EA",' +
                '"OFFSET_GPART":"OF123"' +
            '}]' +
        '}';

        Test.setMock(HttpCalloutMock.class, new SAPHttpMock(200, mockBody));

        Test.startTest();
        ReceivableController.ChronologyWrapper cw = ReceivableController.fetchSAPDataChronologies('BP123');
        if (cw != null && cw.sapData != null && !cw.sapData.isEmpty()) {
            ReceivableController.Chronology c = cw.sapData[0];
            System.debug(c.BUSPARTNER);
            System.debug(c.CONT_ACCT);
            System.debug(c.DOC_NO);
            System.debug(c.GUID_C);
            System.debug(c.HTEXT);
            System.debug(c.DEBIT);
            System.debug(c.CREDIT);
            System.debug(c.DOWN);
            System.debug(c.CURRENCYCODE);
            System.debug(c.BUDAT);
            
            System.debug(c.ZSOP);
            System.debug(c.ZSOP_TEXT);
            System.debug(c.Z_CH_DATE);
            System.debug(c.Z_CH_REC_DATE);
            System.debug(c.Z_BANK_NAME);
            System.debug(c.AMOUNT);
            System.debug(c.DDATE);
            System.debug(c.PDATE);
            System.debug(c.NDATE);
            System.debug(c.RTEXT);
            System.debug(c.MENGE);
            System.debug(c.MEINS);
            System.debug(c.OFFSET_GPART);
        }
        Test.stopTest();
    }


    // ---------- TEST: updateAccountBalances with Due > 0 ----------
    @IsTest
    static void testUpdateAccountBalances_PositiveDue() {
        Account acc = createTestAccount('BP1001');
        Test.startTest();
        ReceivableController.updateAccountBalances(
            'BP1001', 
            '100.50',
            '200.75',
            '300.25',
            '400.00',
            '2025-08-01'
        );
        Test.stopTest();
    }

    // ---------- TEST: updateAccountBalances with Due <= 0 ----------
    @IsTest
    static void testUpdateAccountBalances_NegativeDue() {
        Account acc = createTestAccount('BP1002');
        Test.startTest();
        ReceivableController.updateAccountBalances(
            'BP1002',
            '150.00',
            '-50.00',
            '200.00',
            '75.00',
            '2025-09-01'
        );
        Test.stopTest();
    }
}