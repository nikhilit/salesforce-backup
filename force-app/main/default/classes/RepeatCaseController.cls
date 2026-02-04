public without sharing class RepeatCaseController {
    
    // Add this method to convert picklist label to API value
    private static String getPicklistApiValue(String objectName, String fieldName, String label) {
        try {
            Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
            Schema.DescribeSObjectResult objDescribe = sObjType.getDescribe();
            Schema.DescribeFieldResult fieldResult = objDescribe.fields.getMap().get(fieldName).getDescribe();
            
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                if (entry.getLabel() == label) {
                    return entry.getValue();
                }
            }
            return label; // Fallback to original label if not found
        } catch (Exception e) {
            return label; // Fallback to original label
        }
    }
    
    @AuraEnabled
    public static Id handleRepeatCase(
        Id currentCaseId, 
        String internalComment, 
        String origin, 
        String contactedBy, 
        String relationshipToOwner, 
        String contactDirection,
        String callReceivedFrom
        ) {
        try {

            // Validate input
            if (currentCaseId == null) {
                throw new AuraHandledException('Case Id cannot be null');
            }

            // Get the current case record
            Case currentCase = [
                SELECT Id, Subject, Child_Case_Count__c, ContactId, AccountId, IsClosed
                FROM Case
                WHERE Id = :currentCaseId
                LIMIT 1
            ];

            // Check if case is closed
            if (currentCase.IsClosed) {
                throw new AuraHandledException('Cannot create repeat case for a closed case.');
            }

            // Convert origin label to API value for Repeat_Origin__c
            String repeatOriginApiValue = getPicklistApiValue('Repeat_Case__c', 'Repeat_Origin__c', origin);

            // Convert contact direction label to API value for Contact_Directions__c
            String contactDirectionApiValue = getPicklistApiValue('Repeat_Case__c', 'Contact_Directions__c', contactDirection);

            // Update child case count
            currentCase.Child_Case_Count__c = (currentCase.Child_Case_Count__c != null)
                ? currentCase.Child_Case_Count__c + 1
                : 1;
            currentCase.Latest_Repeat_Origin__c = origin;
            currentCase.Latest_Repeat_Remark__c = internalComment;
            currentCase.Latest_Repeat_Date__c = Date.today();
            currentCase.Latest_Repeat_Time__c = System.now().time();
            
            update currentCase;

            // Create Repeat Case record - Use the API values for both fields
            Repeat_Case__c repeat = new Repeat_Case__c();
            repeat.Case__c = currentCase.Id;
            repeat.Repeat_Remarks__c = internalComment;
            repeat.Repeat_Origin__c = repeatOriginApiValue; // Use API value, not label
            repeat.Contact_Directions__c = contactDirectionApiValue; // Use API value, not label
            repeat.Contacted_By__c = contactedBy;
            repeat.Relationship_to_the_Owner__c = relationshipToOwner;
            repeat.Call_Received_From__c = callReceivedFrom; 
            
            insert repeat;

            
            return repeat.Id;
            
        } catch (DmlException e) {
            String errorMessage = 'Failed to create repeat case: ' + e.getDmlMessage(0);
            throw new AuraHandledException(errorMessage);
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to create repeat case: ' + e.getMessage());
        }
    }

    // Get the ACTUAL picklist values for Repeat_Case__c.Repeat_Origin__c
    @AuraEnabled(cacheable=true)
    public static List<String> getRepeatOriginPicklistValues() {
        List<String> values = new List<String>();
        try {
            Schema.DescribeFieldResult fieldResult = Repeat_Case__c.Repeat_Origin__c.getDescribe();
            
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                if (entry.isActive()) {
                    values.add(entry.getLabel()); // Return labels for display
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load origin options: ' + e.getMessage());
        }
        return values;
    }

    // Get the ACTUAL picklist values for Repeat_Case__c.Contact_Directions__c
    @AuraEnabled(cacheable=true)
    public static List<String> getContactDirectionPicklistValues() {
        List<String> values = new List<String>();
        try {
            Schema.DescribeFieldResult fieldResult = Repeat_Case__c.Contact_Directions__c.getDescribe();
            
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                if (entry.isActive()) {
                    values.add(entry.getLabel()); // Return labels for display
                }
            }
        } catch (Exception e) {
            // Fallback to Case Contact Direction values if there's an error
            return getCaseContactDirectionPicklistValues();
        }
        return values;
    }

    // Fallback method to get Case Contact Direction values
    private static List<String> getCaseContactDirectionPicklistValues() {
        List<String> values = new List<String>();
        try {
            Schema.DescribeFieldResult fieldResult = Case.Contact_Directions__c.getDescribe();
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                if (entry.isActive()) {
                    values.add(entry.getLabel());
                }
            }
        } catch (Exception e) {
            // Silent fail - return empty list
        }
        return values;
    }

    // Debug method to compare both picklists for Contact Direction
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> debugContactDirectionPicklists() {
        Map<String, Object> result = new Map<String, Object>();
        
        // Get Case Contact Direction values
        List<String> caseContactDirectionValues = new List<String>();
        try {
            Schema.DescribeFieldResult caseFieldResult = Case.Contact_Directions__c.getDescribe();
            for (Schema.PicklistEntry entry : caseFieldResult.getPicklistValues()) {
                if (entry.isActive()) {
                    caseContactDirectionValues.add(entry.getLabel());
                }
            }
            result.put('caseContactDirection', caseContactDirectionValues);
        } catch (Exception e) {
            result.put('caseContactDirectionError', e.getMessage());
        }
        
        // Get Repeat Case Contact Direction values
        List<String> repeatContactDirectionValues = new List<String>();
        try {
            Schema.DescribeFieldResult repeatFieldResult = Repeat_Case__c.Contact_Directions__c.getDescribe();
            for (Schema.PicklistEntry entry : repeatFieldResult.getPicklistValues()) {
                if (entry.isActive()) {
                    repeatContactDirectionValues.add(entry.getLabel());
                }
            }
            result.put('repeatContactDirection', repeatContactDirectionValues);
        } catch (Exception e) {
            result.put('repeatContactDirectionError', e.getMessage());
        }
        
        return result;
    }

    // Method to get both labels and API values for debugging
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRepeatPicklistDetails() {
        Map<String, Object> result = new Map<String, Object>();
        
        // Repeat Origin details
        List<Map<String, String>> repeatOriginDetails = new List<Map<String, String>>();
        try {
            Schema.DescribeFieldResult originFieldResult = Repeat_Case__c.Repeat_Origin__c.getDescribe();
            for (Schema.PicklistEntry entry : originFieldResult.getPicklistValues()) {
                if (entry.isActive()) {
                    Map<String, String> detail = new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue(),
                        'apiValue' => entry.getValue()
                    };
                    repeatOriginDetails.add(detail);
                }
            }
            result.put('repeatOriginDetails', repeatOriginDetails);
        } catch (Exception e) {
            result.put('repeatOriginError', e.getMessage());
        }
        
        // Contact Direction details
        List<Map<String, String>> contactDirectionDetails = new List<Map<String, String>>();
        try {
            Schema.DescribeFieldResult contactFieldResult = Repeat_Case__c.Contact_Directions__c.getDescribe();
            for (Schema.PicklistEntry entry : contactFieldResult.getPicklistValues()) {
                if (entry.isActive()) {
                    Map<String, String> detail = new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue(),
                        'apiValue' => entry.getValue()
                    };
                    contactDirectionDetails.add(detail);
                }
            }
            result.put('contactDirectionDetails', contactDirectionDetails);
        } catch (Exception e) {
            result.put('contactDirectionError', e.getMessage());
        }
        
        return result;
    }
}