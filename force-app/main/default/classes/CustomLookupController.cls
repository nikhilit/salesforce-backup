/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 22-07-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   10-11-2022   Kartik Patkar, Appstrail   Initial Version
**/
public without sharing class CustomLookupController {
    
    @AuraEnabled(cacheable=true)
    public static List<RecordWrapper> search(String searchTerm, string myObject, String filter, String searchFieldName) {
        String myQuery = null;
        if(filter != null && filter != ''){
            if(searchTerm == null || searchTerm == ''){
                myQuery = 'SELECT Id, '+searchFieldName+' FROM '+myObject+' WHERE '+filter+' ORDER BY '+searchFieldName+' ASC LIMIT 5';
            }
            else {
                myQuery = 'SELECT Id, '+searchFieldName+' FROM '+myObject+' WHERE '+searchFieldName+' LIKE  \'%' + searchTerm + '%\' AND '+filter+' LIMIT 5';
                System.debug('query::'+myQuery);
            }
        }
        else {
            if(searchTerm == null || searchTerm == ''){
                myQuery = 'SELECT Id, '+searchFieldName+' FROM '+myObject+' ORDER BY '+searchFieldName+' ASC LIMIT 5';
            }
            else {
                myQuery = 'SELECT Id, '+searchFieldName+' FROM '+myObject+' WHERE '+searchFieldName+' LIKE  \'%' + searchTerm + '%\' LIMIT  5';
            }
        }
        System.debug('query::'+myQuery);
        List<sObject> lookUpList = database.query(myQuery);
        List<RecordWrapper> recordWrapperList = new List<RecordWrapper>();
        for(SObject record : lookUpList){
            recordWrapperList.add(new RecordWrapper(record,searchFieldName));
        }
        //List<sObject>)
        return recordWrapperList;
    }

    public class RecordWrapper{
        @AuraEnabled public String Name{set;get;}
        @AuraEnabled public String Id{set;get;}

        public RecordWrapper(){
            this.Name = '';
            this.Id = '';
        }
        public RecordWrapper(sObject record,String searchFieldName){
            this.Name = (String)record.get(searchFieldName);
            this.Id = (String)record.get('Id');
        }
    }
}