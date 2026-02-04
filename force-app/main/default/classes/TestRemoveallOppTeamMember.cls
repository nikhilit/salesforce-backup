@isTest
public class TestRemoveallOppTeamMember {
    
    @testSetup
    static void setupData() {
        // Create some test Opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        
        Opportunity opp1 = new Opportunity(Name = 'Opportunity 1', StageName = 'Prospecting', CloseDate = Date.today());
        Opportunity opp2 = new Opportunity(Name = 'Opportunity 2', StageName = 'Negotiation/Review', CloseDate = Date.today());
        oppList.add(opp1);
        oppList.add(opp2);
        
        insert oppList;
        
        // Create Opportunity Team Members for the Opportunities
        OpportunityTeamMember teamMember1 = new OpportunityTeamMember(OpportunityId = opp1.Id, UserId = UserInfo.getUserId());
        OpportunityTeamMember teamMember2 = new OpportunityTeamMember(OpportunityId = opp2.Id, UserId = UserInfo.getUserId());
        
        insert teamMember1;
        insert teamMember2;
    }
    
    @isTest
    static void testRemoveTeamMemberPositive() {

        List<Opportunity> oppList = [SELECT Id, StageName, Name FROM Opportunity WHERE Name IN ('Opportunity 1', 'Opportunity 2')];
        
        for (Opportunity opp : oppList) {
            if (opp.Name == 'Opportunity 1') {
                opp.StageName = 'Closed Lost'; // Update this opportunity to 'Closed Lost'
            }
        }
        Test.startTest();
        update oppList; // This should trigger the method and remove the team members
        Test.stopTest();
        
        
        List<OpportunityTeamMember> teamMembers = [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId = :oppList[0].Id];
        System.assertEquals(0, teamMembers.size(), 'Team members for Closed Lost Opportunity should be deleted');
    }
    
    @isTest
    static void testRemoveTeamMemberNegative() {

        List<Opportunity> oppList = [SELECT Id, StageName, Name FROM Opportunity WHERE Name IN ('Opportunity 1', 'Opportunity 2')];

        for (Opportunity opp : oppList) {
            opp.StageName = 'Prospecting'; // Keep the stage as something else
        }
        
        Test.startTest();
        update oppList; // This update should not remove the team members
        Test.stopTest();
       
        List<OpportunityTeamMember> teamMembers = [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId = :oppList[1].Id];
        System.assertNotEquals(0, teamMembers.size(), 'Team members should not be deleted if stage is not Closed Lost');
    }
}
/*@isTest
public class OpportunityTriggerHandlerTest {
    @isTest
    static void OpportunityTriggerHandler()
    {
        Account acc = new Account();
        acc.Name ='Test';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name='Test1';
        opp.StageName= 'Prospecting';
        opp.CloseDate=System.today();
        insert opp;
        
        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.Opportunityid=opp.id;
        otm.UserId= userinfo.getuserid();
        insert otm;
        
        opp.stageName ='Closed Lost';
        update opp;
        Test.startTest();
        OpportunityTriggerHandler.OpportunityTriggerHandler();
    }
    
}*/