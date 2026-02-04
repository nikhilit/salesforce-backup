/**
* @File Name : AS_VerifyAgentDetailsHandler.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 8, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 8, 2025 |   | Initial Version
**/
public without sharing class AS_VerifyAgentDetailsHandler {

    public class AgentFieldWrapper {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

    public class AgentDetailsWrapper {
        @AuraEnabled public String name;
        @AuraEnabled public List<AgentFieldWrapper> fields;
    }

    @AuraEnabled(cacheable=true)
    public static AgentDetailsWrapper getAgentDetails(Id userId) {

        List<MGL_Setting__mdt> fieldConfigs = [SELECT Supported_Fields__c 
                                                 FROM MGL_Setting__mdt 
                                                WHERE DeveloperName = 'AgentIdentificationFields'];

        List<String> fieldApiNames = new List<String>();

        for (MGL_Setting__mdt config : fieldConfigs) {
            if (String.isNotBlank(config.Supported_Fields__c)) {
                fieldApiNames.addAll(config.Supported_Fields__c.split(','));
            }
        }

        if (!fieldApiNames.contains('Id')) fieldApiNames.add('Id');
        if (!fieldApiNames.contains('Name')) fieldApiNames.add('Name');

        String soql = 'SELECT ' + String.join(fieldApiNames, ', ') +
                      ' FROM ServiceResource WHERE RelatedRecordId = :userId LIMIT 1';

        ServiceResource agent = (ServiceResource) Database.query(soql);

        AgentDetailsWrapper result = new AgentDetailsWrapper();
        result.name = agent.Name;
        result.fields = new List<AgentFieldWrapper>();

        for (String fieldPath : fieldApiNames) {
            if (fieldPath == 'Id' || fieldPath == 'Name') continue;

            AgentFieldWrapper wrapper = new AgentFieldWrapper();
            wrapper.apiName = fieldPath;
            wrapper.value = '';

            if(fieldPath.contains('.') && fieldPath == 'Agency__r.Name'){

                String[] parts = fieldPath.split('\\.');
                String relField = parts[0];  
                String relName = parts[1];  
            
                sObject parentObject = agent.getSObject(relField);
                wrapper.value = (String) parentObject.get(relName);   
                wrapper.label = 'Agency Name';
            }else{
                wrapper.value = String.valueOf(agent.get(fieldPath));
            }

            if (!fieldPath.contains('.')) {
                try {

                    String label = ServiceResource.SObjectType.getDescribe()
                                .fields.getMap().get(fieldPath).getDescribe().getLabel();
                    
                    wrapper.label = label;
                } catch (Exception e) {
                    wrapper.label = fieldPath.replace('__c', '').replace('__r', '').replace('_', ' ');
                }
            }
            result.fields.add(wrapper);
        }
        return result;
    }
}