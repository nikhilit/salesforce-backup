public class addmultipleContactsController {
    @AuraEnabled 
        public static ResponseWrapper saveMultipleContacts(list<Contact> conlist){
            system.debug('Debug Conlist  ' +conlist);
            ResponseWrapper response = new ResponseWrapper();
            try{
                system.debug('Check the deatils--');
                insert conlist;
                system.debug('Conlist to be inserted' +conlist);
                response.isSuccess = true;
                
            }catch(Exception e){
                response.isSuccess = false;
                response.message = e.getMessage();
            }
            return response;
        }
        public class ResponseWrapper{
            @AuraEnabled
            public boolean isSuccess{get;set;}
            @AuraEnabled
            public string message{get;set;}
        }
    }