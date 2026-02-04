@isTest
public class CreateWorkOrderFromCaseContrTest {
    
    
   
    // Utility to create a test User with given Profile Name
  //  private static User createUser(String profileName) {
  
    @testSetup
    static void setupdata(){
        Profile p = [SELECT Id,Name FROM Profile WHERE Name LIKE '%Standard%' LIMIT 1];
        
        User u = new User(
            Alias = 'testusr',
            Email = 'testuser' + Math.random() + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'testuser' + Math.random() + '@test.com'
        );
        insert u;
       // return u;
    }

    @isTest
    static void testGetlstWorkType_IPD() {
        // Create WorkType
       
        
         WorkType wt = new WorkType(Name='Individual Permanent Disconnection', EstimatedDuration=60);
        insert wt;

        // Run as User with profile "AIC (O&M- IPD)" (make sure this profile exists in org)
      //  User u = createUser('AIC (O&M- IPD)');
      
        User u = [Select id from User limit 1];
        //System.runAs(u) {
            Test.startTest();
            List<WorkType> result = CreateWorkOrderFromCaseContr.getlstWorkType();
            Test.stopTest();

           
      //  }
    }

    @isTest
    static void testGetlstWorkType_RubberHose() {
        // Create WorkType
       
         WorkType wt = new WorkType(Name='Rubber Hose Replacement', EstimatedDuration=60);
        insert wt;
        
      //   User u = [Select id from User limit 1];
        
            CreateWorkOrderFromCaseContr.testScenario = 'IPD';

        
        

        // Run as User with profile "RubberHose AIC"
      //  User u = createUser('RubberHose AIC');
       // System.runAs(u) {
            Test.startTest();
            List<WorkType> result = CreateWorkOrderFromCaseContr.getlstWorkType();
            Test.stopTest();

           
      //  }
    }

     @isTest
    static void testGetlstWorkType_AfterSales() {
        // Create WorkType
       
         WorkType wt = new WorkType(Name='After sales Service', EstimatedDuration=60);
        insert wt;
        
      //   User u = [Select id from User limit 1];
        
            CreateWorkOrderFromCaseContr.testScenario = 'IPD';

        
        

            Test.startTest();
            List<WorkType> result = CreateWorkOrderFromCaseContr.getlstWorkType();
            Test.stopTest();

           
     
    }

    @isTest
    static void testAssignWorkTypeToWorkOrder() {
        // Create WorkType
        WorkType wt = new WorkType(Name = 'Test WorkType',EstimatedDuration=60);
        insert wt;
        

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Case
        Case cs = new Case(
            AccountId = acc.Id,
            Remarks__c = 'Test Remark',
            Origin = 'Phone',
            Status = 'New'
        );
        insert cs;

        // Call method
        List<String> caseIds = new List<String>{cs.Id};
        Test.startTest();
        String result = CreateWorkOrderFromCaseContr.assignWorkTypeToWorkOrder(caseIds, wt.Id);
        Test.stopTest();


       
    }


    
    

}