/**
 * @description       : 
 * @author            : Shashank.shekhar@appstrail.com
 * @group             : 
 * @last modified on  : 04-24-2025
 * @last modified by  : Shashank.shekhar@appstrail.com
**/
public with sharing class autoHomePageComponentController {
    
    @AuraEnabled
    public static UserWrapper getUserName() {
        User userRec = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
        UserWrapper wrap = new UserWrapper();
        wrap.userName = userRec.Name;
        return wrap;
    }

    public class UserWrapper{
        @AuraEnabled public string userName{get;set;}
    }
}