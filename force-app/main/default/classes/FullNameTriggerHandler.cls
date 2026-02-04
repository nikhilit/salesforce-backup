public class FullNameTriggerHandler {
    Public static void populateFullName(List<Account> accList)
    {
        for(Account acc : accList)
        {
            acc.Full_Name__c =acc.First_Name__c + ' ' + acc.Last_Name__c;
        }
    }
}