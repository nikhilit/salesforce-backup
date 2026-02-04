@isTest
public class MoveInOutTriggerTest {
    static Id accIdMain;
    static Id accIdMismatch;

    @testSetup
    static void setupData() {
        // Force trigger active
        TriggerController.triggerControlMap = new Map<String, Boolean>{ 'MoveInOutTrigger' => true };

        // Main account
        Account acc1 = new Account(Name = 'Main Account', BP_Number__c = 'BP001');
        insert acc1;
        accIdMain = acc1.Id;

        // Account for mismatch case
        Account acc2 = new Account(Name = 'Mismatch Account', BP_Number__c = 'DIFF_BP');
        insert acc2;
        accIdMismatch = acc2.Id;
    }

    @isTest
    static void testBeforeInsert_AllLookupsFilled() {
        Move_In_Out__c move = new Move_In_Out__c(
            BP_Number__c = accIdMain,
            Premise_Name__c = accIdMain,
            Installation_Name__c = accIdMain,
            Contract_Account_Name__c = accIdMain,
            Contract_Name__c = accIdMain,
            Business_Partner__c = 'BP001'
        );
        Test.startTest();
        insert move;
        Test.stopTest();
    }

    @isTest
    static void testBeforeInsert_HasNullLookup() {
        Move_In_Out__c move = new Move_In_Out__c(
            BP_Number__c = accIdMain,
            Premise_Name__c = null,
            Business_Partner__c = 'BP002'
        );
        Test.startTest();
        insert move;
        Test.stopTest();
    }

    @isTest
    static void testBeforeUpdate_BusinessPartnerChange() {
        Move_In_Out__c move = new Move_In_Out__c(
            BP_Number__c = accIdMain,
            Premise_Name__c = accIdMain,
            Installation_Name__c = accIdMain,
            Contract_Account_Name__c = accIdMain,
            Contract_Name__c = accIdMain,
            Business_Partner__c = 'BP001'
        );
        insert move;
        move.Business_Partner__c = 'BP999';
        Test.startTest();
        update move;
        Test.stopTest();
    }

    @isTest
    static void testBeforeUpdate_BPMismatch() {
        Move_In_Out__c move = new Move_In_Out__c(
            BP_Number__c = accIdMismatch,
            Premise_Name__c = accIdMismatch,
            Installation_Name__c = accIdMismatch,
            Contract_Account_Name__c = accIdMismatch,
            Contract_Name__c = accIdMismatch,
            Business_Partner__c = 'BP001'
        );
        insert move;
        Test.startTest();
        update move;
        Test.stopTest();
       }

    @isTest
    static void testTriggerInactives() {
        if (TriggerController.triggerControlMap == null) {
            TriggerController.isTriggerActive('MoveInOutTrigger');
        }
        TriggerController.triggerControlMap.put('MoveInOutTrigger', false);
        Move_In_Out__c move = new Move_In_Out__c(
            BP_Number__c = accIdMain,
            Business_Partner__c = 'BPXXX'
        );
        Test.startTest();
        insert move;
        Test.stopTest();
        TriggerController.triggerControlMap.put('MoveInOutTrigger', true);
    }

    // ---------- EXTRA METHODS FOR COVERAGE ----------

    @isTest
    static void testNoBPNumberIds() {
        Move_In_Out__c move = new Move_In_Out__c(
            BP_Number__c = null,
            Premise_Name__c = null,
            Installation_Name__c = null,
            Contract_Account_Name__c = null,
            Contract_Name__c = null,
            Business_Partner__c = 'BP_NO_ID'
        );
        Test.startTest();
        insert move;
        Test.stopTest();
        Move_In_Out__c rec = [SELECT To_be_processed__c FROM Move_In_Out__c WHERE Id = :move.Id];
        //System.assertEquals(true, rec.To_be_processed__c, 'Should process when BP_Number__c is null');
    }

    @isTest
    static void testNoBPMismatchBecauseAccountBPIsNull() {
        Account accNullBP = new Account(Name = 'No BP Account', BP_Number__c = null);
        insert accNullBP;
        Move_In_Out__c move = new Move_In_Out__c(
            BP_Number__c = accNullBP.Id
           
        );
        insert move;
        Test.startTest();
        update move;
        Test.stopTest();
        Move_In_Out__c rec = [SELECT To_be_processed__c FROM Move_In_Out__c WHERE Id = :move.Id];
       // System.assertEquals(true, rec.To_be_processed__c, 'Still processed when Account BP is null');
    }

    @isTest
    static void testBusinessPartnerBlankOnUpdate() {
        Move_In_Out__c move = new Move_In_Out__c(
            BP_Number__c = accIdMain,
            Premise_Name__c = accIdMain,
            Installation_Name__c = accIdMain,
            Contract_Account_Name__c = accIdMain,
            Contract_Name__c = accIdMain,
            Business_Partner__c = 'BP001'
        );
        insert move;
        move.Business_Partner__c = null;
        Test.startTest();
        update move;
        Test.stopTest();
        Move_In_Out__c rec = [SELECT Name FROM Move_In_Out__c WHERE Id = :move.Id];
        //System.assertEquals('BP001', rec.Name, 'Name should remain unchanged when BP is blank');
    }

    @isTest
    static void testMultipleRecordsMixed() {
        Move_In_Out__c newRec = new Move_In_Out__c(
            BP_Number__c = accIdMain,
            Premise_Name__c = accIdMain,
            Installation_Name__c = accIdMain,
            Contract_Account_Name__c = accIdMain,
            Contract_Name__c = accIdMain,
            Business_Partner__c = 'BP001'
        );
        Move_In_Out__c updateRec = new Move_In_Out__c(
            BP_Number__c = accIdMismatch,
            Premise_Name__c = accIdMismatch,
            Installation_Name__c = accIdMismatch,
            Contract_Account_Name__c = accIdMismatch,
            Contract_Name__c = accIdMismatch,
            Business_Partner__c = 'DIFF_INIT'
        );
        insert updateRec;
        updateRec.Business_Partner__c = 'BP_CHANGED';
        Test.startTest();
        insert newRec;
        update updateRec;
        Test.stopTest();
        List<Move_In_Out__c> recs = [
            SELECT To_be_processed__c, Name 
            FROM Move_In_Out__c 
            WHERE Id IN :new List<Id>{newRec.Id, updateRec.Id}
        ];
       
    }
}